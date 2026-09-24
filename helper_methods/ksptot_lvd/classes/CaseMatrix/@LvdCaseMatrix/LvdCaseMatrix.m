classdef LvdCaseMatrix < matlab.mixin.SetGet
    %LvdCaseMatrix A set of cases generated from one mission, and the machine
    %that runs them.
    %
    %   Two dispatch strategies live here, because a trade study and a
    %   dispersion run want opposite things:
    %
    %   Optimize mode runs one case at a time per worker, each one warm
    %   started from the nearest already-converged case and persisted to its
    %   own .mat file.  Cases are therefore NOT independent -- the queue
    %   exists so a later case can inherit an earlier case's solution -- and a
    %   parallel pool is required.
    %
    %   Propagate-only mode has no such coupling: every case is an
    %   independent propagation of the same template.  It broadcasts the
    %   template once through a parallel.pool.Constant and dispatches chunks
    %   of cases, which keeps the per-case overhead near zero at Monte Carlo
    %   sample counts, and it falls back to running serially when there is no
    %   pool rather than refusing to run at all.

    properties
        lvdData LvdData
        current_save_location(1,:) char

        tasks(1,:) LvdCaseMatrixTask
        maxNumAttempts(1,1) double = 2;

        runCanceled(1,1) logical = false;

        %The definition this matrix's tasks were generated from.  Empty for
        %the legacy plugin-variable-only entry point.
        setup LvdSweepSetup

        runName(1,:) char = 'Sweep';

        %Populated by runAllTasks; also what gets written to disk.
        results LvdSweepResults
    end

    events
        TaskCreated
    end

    methods
        function obj = LvdCaseMatrix(lvdData, current_save_location)
            arguments
                lvdData(1,1) LvdData
                current_save_location(1,:) char
            end

            obj.lvdData = lvdData;
            obj.current_save_location = current_save_location;
        end

        function createTasksFromSetup(obj, setup)
            %createTasksFromSetup Generates one task per case of a sweep or
            %Monte Carlo definition.
            arguments
                obj(1,1) LvdCaseMatrix
                setup(1,1) LvdSweepSetup
            end

            obj.setup = setup;
            obj.maxNumAttempts = setup.maxNumAttempts;
            obj.tasks = LvdCaseMatrixTask.empty(1,0);

            %Baselines are captured off the pristine template, once, before
            %any case runs.  A multiplier knob that captured its baseline
            %from an already-scaled mission would compound.
            setup.captureBaselines(obj.lvdData);

            X = setup.generateInputMatrix();

            if(isempty(X))
                return;
            end

            %Optimize mode warm starts each case from the nearest converged
            %one, so running the cases nearest the template's own design
            %point first gives every later case a good starting guess.
            %Propagate-only cases are independent, so their order is the
            %sampler's -- which keeps case N the same case on every rerun of
            %a given seed.
            if(setup.runMode == LvdCaseMatrixRunModeEnum.Optimize)
                order = LvdCaseMatrix.orderNearestFirst(X, obj.getCurrentParamValues(setup));
            else
                order = (1:height(X))';
            end

            numDigits = floor(log10(abs(max(numel(order), 1)))) + 1;

            for(i=1:numel(order)) %#ok<*NO4LP>
                lvdFilePath = fullfile(obj.current_save_location, sprintf('Case_%0*u.mat', numDigits, i));

                task = LvdCaseMatrixTask(obj, setup.params, X(order(i), :), ...
                                         LvdCaseMatrixTask.empty(1,0), lvdFilePath);

                task.responses = setup.responses;
                task.runMode = setup.runMode;
                task.writeGaTimeSeries = setup.writeGaTimeSeries;

                %Optimize mode has no choice: the warm start and the retry
                %path both read the case file back off disk.
                task.persistCaseFile = setup.persistCaseFiles || ...
                                       setup.runMode == LvdCaseMatrixRunModeEnum.Optimize;

                obj.tasks(i) = task;

                notify(obj, 'TaskCreated', LvdCaseMatrixTaskGenerationEvtData(task, i, numel(order)));
            end
        end

        function createAllTaskParamCombos(obj, paramsAndRanges)
            %createAllTaskParamCombos LEGACY.  Full factorial over a set of
            %plugin variables, each with an explicit list of values.
            %
            %   Superseded by createTasksFromSetup, which does this for any
            %   kind of parameter and any sampling scheme.  Kept because it is
            %   a much shorter road for a caller that already has plugin
            %   variables and ranges in hand, and because case matrices built
            %   by the old window are defined this way.
            warning('off','stats:pdist2:ZeroInverseWeights');

            usedPluginVars = [paramsAndRanges{:,1}];
            paramRanges = paramsAndRanges(:,2);

            A = LvdSweepSampler.cartesianProduct(paramRanges(:)');

            pluginVars = obj.lvdData.pluginVars.getPluginVarsArray();
            bool = false(1, numel(pluginVars));
            for(i=1:length(pluginVars))
                bool(i) = any(pluginVars(i) == usedPluginVars);
            end

            currentPluginValues = obj.lvdData.pluginVars.getPluginVarValues();
            currentPluginValues = currentPluginValues(bool);

            Idx = LvdCaseMatrix.orderNearestFirst(A, currentPluginValues(:)');

            sweptVars = pluginVars(bool);
            params = LvdSweepPluginVarParameter.empty(1,0);
            for(j=1:length(sweptVars))
                params(j) = LvdSweepPluginVarParameter(sweptVars(j));
            end

            numDigits = floor(log10(abs(max(Idx)))) + 1;
            for(i=1:length(Idx))
                lvdFilePath = fullfile(obj.current_save_location, sprintf('Case_%0*u.mat', numDigits, i));

                prereqTask = LvdCaseMatrixTask.empty(1,0);

                obj.tasks(i) = LvdCaseMatrixTask(obj, params, A(Idx(i), :), prereqTask, lvdFilePath, bool);

                s = LvdCaseMatrixTaskGenerationEvtData(obj.tasks(i), i, length(Idx));
                notify(obj, 'TaskCreated', s);
            end

            warning('on','stats:pdist2:ZeroInverseWeights');
        end

        function runMode = getRunMode(obj)
            if(isempty(obj.setup))
                runMode = LvdCaseMatrixRunModeEnum.Optimize;
            else
                runMode = obj.setup.runMode;
            end
        end

        function runAllTasks(obj, progressFcn)
            %runAllTasks Runs every task and collects the results.
            %
            %   progressFcn(struct) is called on the CLIENT for every
            %reported optimizer iteration in Optimize mode, with fields
            %taskId/iter/fval/viol/optim.  It drives live displays (the
            %status tables); pass [] for none.  Propagate-only cases have
            %no iterations and never report.
            arguments
                obj(1,1) LvdCaseMatrix
                progressFcn = [];
            end

            obj.runCanceled = false;

            if(isempty(obj.tasks))
                return;
            end

            d = datetime();
            xlsFile = fullfile(obj.current_save_location, sprintf('LVD_Case_Matrix_Run_%s.xlsx', datestr(d, 'yyyymmdd_HHMMSS'))); %#ok<DATST>

            if(obj.anyTaskWritesGaTimeSeries())
                %Excel will not accept a sheet written out of order, so every
                %per-case sheet has to exist before the first worker returns.
                writematrix([], xlsFile, 'WriteMode','overwritesheet', 'Sheet','Case Index');

                for(i=1:length(obj.tasks))
                    [~,name,~] = fileparts(obj.tasks(i).lvdFilePath);
                    writematrix([], xlsFile, 'WriteMode','overwritesheet', 'Sheet',name);
                end
            end

            if(obj.getRunMode() == LvdCaseMatrixRunModeEnum.PropagateOnly)
                obj.runAllTasksPropagateOnly(xlsFile);
            else
                obj.runAllTasksOptimize(xlsFile, progressFcn);
            end

            obj.tasks.clearLvdDataCache();

            obj.results = obj.collectResults();

            if(obj.anyTaskWritesGaTimeSeries())
                obj.writeCaseIndexSheet(xlsFile);
            end

            obj.writeResultsFiles();
        end

        function runAllTasksOptimize(obj, xlsFile, progressFcn)
            %runAllTasksOptimize One case per worker, warm started from the
            %nearest converged case, with a retry budget.
            %
            %   progressFcn(struct) streams live iteration reports to the
            %client through a DataQueue; [] records task fields only.
            arguments
                obj(1,1) LvdCaseMatrix
                xlsFile(1,:) char
                progressFcn = [];
            end

            pp = gcp('nocreate');
            if(isempty(pp))
                error('LvdCaseMatrix:noParallelPool', ...
                      'No parallel pool established.  A parallel pool is required to optimize each case of a case matrix.  Use propagate-only mode to run without one.');
            end

            %One queue for the whole run; messages carry their task id so
            %the client can route them.  The queue travels to the workers
            %as a direct parfeval argument (the supported pattern) -- never
            %nested inside a serialized task.
            progressQueue = parallel.pool.DataQueue;
            if(not(isempty(progressFcn)))
                progressQueue.afterEach(progressFcn);
            end

            fcn = @(nextTask) LvdCaseMatrix.runTaskWithProgress(nextTask, xlsFile, progressQueue);

            F = parallel.FevalFuture.empty(1,0);
            while(not(obj.runCanceled) && obj.keepLoopingOverJobs())
                nextTask = obj.getNextUnRunTask();

                if(not(isempty(nextTask)) && obj.getNumOfRunningJobs() < pp.NumWorkers)
                    nextTask.setTaskStatusAsRunning();
                    numOutputs = 3;
                    fToRun = parfeval(pp,fcn,numOutputs,nextTask);

                    fH = @(runStatus,message,task) LvdCaseMatrix.processTaskOutputs(fToRun, runStatus,message,task);
                    F(end+1) = afterEach(fToRun,fH,0); %#ok<AGROW>
                else
                    pause(0.5); %process button clicks
                end
            end
        end

        function runAllTasksPropagateOnly(obj, xlsFile)
            %runAllTasksPropagateOnly Independent cases, dispatched in chunks
            %against one broadcast copy of the template.
            pp = gcp('nocreate');

            templateBytes = getByteStreamFromArray(obj.lvdData);

            if(isempty(pp))
                obj.runChunksSerially(templateBytes, xlsFile);
                return;
            end

            %Roughly four chunks per worker: few enough that the per-chunk
            %overhead is amortized, many enough that one slow case cannot
            %leave a worker idle at the end of the run.
            chunkSize = max(1, ceil(numel(obj.tasks)/(4*pp.NumWorkers)));

            templateConst = parallel.pool.Constant(templateBytes);

            F = parallel.FevalFuture.empty(1,0);
            starts = 1:chunkSize:numel(obj.tasks);

            for(i=1:numel(starts))
                if(obj.runCanceled)
                    break;
                end

                inds = starts(i):min(starts(i)+chunkSize-1, numel(obj.tasks));

                dispatch = LvdCaseMatrixTask.empty(1,0);
                for(k=1:numel(inds))
                    obj.tasks(inds(k)).setTaskStatusAsRunning();
                    dispatch(k) = obj.tasks(inds(k)).makeDetachedCopy();
                end

                fToRun = parfeval(pp, @LvdCaseMatrix.runTaskChunk, 1, templateConst, dispatch, xlsFile);

                F(end+1) = afterEach(fToRun, @(doneTasks) obj.mergeChunkResults(doneTasks), 0); %#ok<AGROW>
            end

            %Wait for the queue to drain, staying responsive to the cancel
            %button, which cancels the futures out from under us.
            while(not(obj.runCanceled) && any([obj.tasks.status] == LvdCaseMatrixTaskStatusEnum.Running))
                pause(0.25);
                drawnow('limitrate');
            end
        end

        function runChunksSerially(obj, templateBytes, xlsFile)
            %runChunksSerially The no-pool fallback.  One case at a time in
            %this process, which is exactly what a small survey wants and
            %what the original case matrix refused to do at all.
            for(i=1:numel(obj.tasks))
                if(obj.runCanceled)
                    break;
                end

                task = obj.tasks(i);
                task.setTaskStatusAsRunning();
                drawnow('limitrate');

                done = LvdCaseMatrix.runTaskChunk(templateBytes, task.makeDetachedCopy(), xlsFile);

                obj.mergeChunkResults(done);
                drawnow('limitrate');
            end
        end

        function mergeChunkResults(obj, doneTasks)
            %mergeChunkResults Copies what a worker harvested back onto the
            %client's own task objects, matched by id.  The worker had a
            %serialized copy, so nothing it wrote is visible here otherwise.
            arguments
                obj(1,1) LvdCaseMatrix
                doneTasks(1,:) LvdCaseMatrixTask
            end

            ids = [obj.tasks.id];

            for(i=1:numel(doneTasks))
                done = doneTasks(i);

                ind = find(ids == done.id, 1, 'first');
                if(isempty(ind))
                    continue;
                end

                task = obj.tasks(ind);

                task.responseValues = done.responseValues;
                task.responseUnits = done.responseUnits;
                task.responseMessages = done.responseMessages;
                task.taskOutputData = done.taskOutputData;
                task.taskOutputXlsFile = done.taskOutputXlsFile;

                task.optExitflag = done.optExitflag;
                task.optFval = done.optFval;
                task.optMaxViol = done.optMaxViol;
                task.optIters = done.optIters;
                task.optOptim = done.optOptim;

                task.status = done.status;
                task.taskOutputMessage = done.taskOutputMessage;

                if(not(isempty(done.taskOutputData)) && not(isempty(done.taskOutputXlsFile)))
                    [~,name,~] = fileparts(task.lvdFilePath);
                    try
                        writecell(done.taskOutputData, done.taskOutputXlsFile, 'WriteMode','overwritesheet', 'Sheet',name, 'UseExcel',false);
                    catch ME
                        disp(ME.message);
                    end
                end
            end
        end

        function results = collectResults(obj)
            %collectResults The run's inputs, outputs and provenance, with no
            %mission objects attached.
            results = LvdSweepResults();

            results.runName = obj.runName;
            results.inputs = obj.tasks.getArrayOfParamValues();
            results.outputs = obj.tasks.getArrayOfResponseValues();
            results.statuses = [obj.tasks.status];
            results.messages = {obj.tasks.taskOutputMessage};
            results.caseFilePaths = {obj.tasks.lvdFilePath};

            %Optimize-mode summary columns.  NaN throughout in
            %propagate-only mode, where nothing optimizes.
            results.objectiveValues = [obj.tasks.optFval]';
            results.exitflags = [obj.tasks.optExitflag]';

            results.runMode = obj.getRunMode();

            if(not(isempty(obj.setup)))
                results.paramLabels = obj.setup.getParameterLabels();
                results.responseLabels = obj.setup.getResponseLabels();
                results.samplingMode = obj.setup.samplingMode;
                results.seed = obj.setup.seed;
            else
                results.paramLabels = obj.getLegacyParamLabels();
                results.responseLabels = {};
            end

            %Units are a property of the response, but only a case that
            %actually evaluated one knows what came back, so take the first
            %non-empty answer across the run.
            results.responseUnits = repmat({''}, 1, width(results.outputs));
            for(i=1:numel(obj.tasks))
                units = obj.tasks(i).responseUnits;

                for(j=1:min(numel(units), numel(results.responseUnits)))
                    if(isempty(results.responseUnits{j}))
                        results.responseUnits{j} = units{j};
                    end
                end
            end

            results.timestamp = now(); %#ok<TNOW1>

            try
                results.ksptotVer = getKSPTOTVersionNumStr();
            catch
                results.ksptotVer = '';
            end
        end

        function writeResultsFiles(obj)
            %writeResultsFiles The .mat / .xlsx / .csv the setup asked for.
            if(isempty(obj.setup) || isempty(obj.results))
                return;
            end

            base = fullfile(obj.current_save_location, ...
                            matlab.lang.makeValidName(obj.runName));

            if(obj.setup.writeMat)
                obj.tryWrite(@() obj.results.writeMat([base '_results.mat']));
            end

            if(obj.setup.writeXlsx)
                obj.tryWrite(@() obj.results.writeExcel([base '_results.xlsx']));
            end

            if(obj.setup.writeCsv)
                obj.tryWrite(@() obj.results.writeCsv([base '_results.csv']));
            end
        end

        function applyProgressMessage(obj, s)
            %applyProgressMessage Routes one live iteration report onto its
            %task's fields (client side; fired by the run's DataQueue).
            arguments
                obj(1,1) LvdCaseMatrix
                s(1,1) struct
            end

            ids = [obj.tasks.id];
            ind = find(ids == s.taskId, 1, 'first');

            if(isempty(ind))
                return;
            end

            obj.tasks(ind).recordProgress(s.iter, s.fval, s.viol);
        end

        function task = getNextUnRunTask(obj)
            statuses = [obj.tasks.status];

            task = LvdCaseMatrixTask.empty(1,0);
            if(not(obj.areAllJobsDone()))
                ind = find(statuses == LvdCaseMatrixTaskStatusEnum.NotRun,Inf,'first');

                if(not(isempty(ind)))
                    for(i=1:length(ind))
                        task = obj.tasks(ind(i));
                        if(task.areAllPreReqsSatisfied())
                            break;
                        else
                            task = LvdCaseMatrixTask.empty(1,0);
                        end
                    end
                else
                    task = LvdCaseMatrixTask.empty(1,0);
                end
            end

            if(isempty(task) && obj.beenThroughFullCycle()) %TODO this needs to be changed so it only triggers when the code has gone through a full cycle first
                failedTasks = obj.getFailedJobsThatCanBeRerun();

                if(not(isempty(failedTasks)))
                    numAttempts = [failedTasks.numAttempts];
                    [~,I] = min(numAttempts);
                    task = failedTasks(I);

                    try
                        obj.updateFailedTaskWithFitXVector(task);
                    catch ME
                        disp(ME.message);
                        if(not(isempty(ME.stack)))
                            disp(ME.stack(1));
                        end
                    end
                end
            end
        end

        function tf = areThereUnrunTasks(obj)
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];
            tf = any(statuses == LvdCaseMatrixTaskStatusEnum.NotRun | ...
                     (statuses == LvdCaseMatrixTaskStatusEnum.Failed & numRuns < obj.maxNumAttempts));
        end

        function tf = areAllJobsDone(obj)
            statuses = [obj.tasks.status];
            tf = all(statuses == LvdCaseMatrixTaskStatusEnum.Completed | ...
                     statuses == LvdCaseMatrixTaskStatusEnum.Failed);
        end

        function tf = beenThroughFullCycle(obj)
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];

            tf = all((statuses == LvdCaseMatrixTaskStatusEnum.Completed | statuses == LvdCaseMatrixTaskStatusEnum.Failed) & numRuns >= 1 | ...
                      statuses == LvdCaseMatrixTaskStatusEnum.Running & numRuns >= 2);
        end

        function tf = keepLoopingOverJobs(obj)
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];

            bool = statuses == LvdCaseMatrixTaskStatusEnum.NotRun | ...
                   statuses == LvdCaseMatrixTaskStatusEnum.Running | ...
                   (statuses == LvdCaseMatrixTaskStatusEnum.Failed & numRuns < obj.maxNumAttempts);
            tf = any(bool);
        end

        function failedTasks = getFailedJobsThatCanBeRerun(obj)
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];

            bool = (statuses == LvdCaseMatrixTaskStatusEnum.Failed & numRuns < obj.maxNumAttempts);
            if(any(bool))
                failedTasks = obj.tasks(bool);
            else
                failedTasks = LvdCaseMatrixTask.empty(1,0);
            end
        end

        function updateFailedTaskWithFitXVector(obj, failedTask)
            %updateFailedTaskWithFitXVector Seeds a retry with an x-vector
            %interpolated from the cases that did converge, so a second
            %attempt starts somewhere plausible instead of back at the
            %template.
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];
            bool = (statuses == LvdCaseMatrixTaskStatusEnum.Failed & numRuns < obj.maxNumAttempts);

            successfulTasks = obj.tasks(~bool);
            successfulTasks = setdiff(successfulTasks, failedTask);

            sX = [];
            sP = [];
            for(i=1:length(successfulTasks))
                %One mission read per contributing case, and released again
                %straight away: holding every converged case's mission at
                %once is what makes a large sweep run out of memory.
                subLvdData = successfulTasks(i).loadLvdData();
                subX = subLvdData.optimizer.vars.getTotalScaledXVector();
                successfulTasks(i).clearLvdDataCache();

                if(any(isnan(subX)) || any(not(isfinite(subX))))
                    continue;
                end

                sX(end+1,:) = subX; %#ok<AGROW>
                sP(end+1,:) = successfulTasks(i).getArrayOfParamValues(); %#ok<AGROW>
            end

            fP = failedTask.getArrayOfParamValues();

            if(width(sP) <= 2)
                fX = [];
                for(i=1:width(sX))
                    fitobject = fit(sP,sX(:,i),'cubicinterp');
                    fX(i) = fitobject(fP); %#ok<AGROW>
                end

            else
                fX = [];
                for(i=1:width(sX))
                    p = polyfitn(sP,sX(:,i),2);
                    fX(i) = polyvaln(p,fP); %#ok<AGROW>
                end
            end

            fX(fX >=  1) =  1 - 1E-8;
            fX(fX <= -1) = -1 + 1E-8;

            failedLvdData = failedTask.loadLvdData();
            failedLvdData.optimizer.vars.updateObjsWithScaledVarValues(fX);
            failedTask.saveLvdData(failedLvdData);
            failedTask.clearLvdDataCache();
        end

        function cnt = getNumOfRunningJobs(obj)
            statuses = [obj.tasks.status];
            cnt = sum(statuses == LvdCaseMatrixTaskStatusEnum.Running);
        end

        function [nearestTaskLvdData, nearestTask] = getNearestCompletedTaskLvdDataToTask(obj, task)
            bool = [obj.tasks.status] ==  LvdCaseMatrixTaskStatusEnum.Completed;
            if(all(bool == false))
                nearestTaskLvdData = getArrayFromByteStream(getByteStreamFromArray(obj.lvdData));
                nearestTask = LvdCaseMatrixTask.empty(1,0);

            else
                nearestTask = LvdCaseMatrixTask.empty(1,0);
                nearestTaskLvdData = getArrayFromByteStream(getByteStreamFromArray(obj.lvdData));

                A = obj.tasks.getArrayOfParamValues();
                Ai = task.getArrayOfParamValues();

                Idx = LvdCaseMatrix.orderNearestFirst(A, Ai);

                for(i=1:length(Idx))
                    subTask = obj.tasks(Idx(i));
                    if(subTask.status == LvdCaseMatrixTaskStatusEnum.Completed)
                        nearestTask = subTask;
                        nearestTaskLvdData = getArrayFromByteStream(getByteStreamFromArray(subTask.loadLvdData()));
                        subTask.clearLvdDataCache();

                        break;
                    end
                end
            end
        end

        function data = getUITableData(obj)
            %getUITableData One row per case for the run-status tables: the
            %case number, the applied parameter values, the live/final
            %optimize summary (NaN outside Optimize mode), and the status.
            data = {};
            for(i=1:length(obj.tasks))
                task = obj.tasks(i);

                values = task.getArrayOfParamValues();
                status = task.status.name;
                message = task.taskOutputMessage;

                valuesC = num2cell(values);
                optC = num2cell([task.optIters, task.optFval, task.optMaxViol]);

                if(isnan(task.optOptim))
                    optimStr = '';
                else
                    optimStr = sprintf('%.3g', task.optOptim);
                end

                if(isnan(task.optExitflag))
                    exitStr = '';
                else
                    exitStr = LvdSweepResults.exitStatusTag(task.optExitflag);
                end

                data(end+1, :) = horzcat({i}, valuesC, optC, {optimStr}, {exitStr}, {status, message}); %#ok<AGROW>
            end
        end

        function header = getStatusTableColumns(obj)
            %getStatusTableColumns Headers matching getUITableData: Case,
            %one per swept parameter, the optimize summary, status/message.
            if(not(isempty(obj.setup)))
                paramLabels = obj.setup.getParameterLabels();
            else
                paramLabels = obj.getLegacyParamLabels();
            end

            header = horzcat({'Case'}, paramLabels, ...
                {'Iter', 'Objective', 'Max Viol', 'Optimality', 'Exit', 'Status', 'Message'});
        end

        function cancelRun(obj)
            obj.runCanceled = true;
            drawnow;

            pp = gcp('nocreate');

            if(not(isempty(pp)))
                cancelAll(pp.FevalQueue);
            end
            drawnow;

            for(i=1:length(obj.tasks))
                task = obj.tasks(i);
                if(task.status == LvdCaseMatrixTaskStatusEnum.Running)
                    task.status = LvdCaseMatrixTaskStatusEnum.Canceled;
                    task.taskOutputMessage = 'Canceled';
                end
            end
        end
    end

    methods(Access=private)
        function tf = anyTaskWritesGaTimeSeries(obj)
            tf = any([obj.tasks.writeGaTimeSeries]);
        end

        function values = getCurrentParamValues(~, setup)
            %getCurrentParamValues Where the template mission sits in the
            %swept design space, which is where the nearest-first ordering
            %starts from.
            values = NaN(1, numel(setup.params));

            for(i=1:numel(setup.params))
                try
                    values(i) = setup.params(i).getCurrentValue();
                catch
                    values(i) = NaN;
                end
            end
        end

        function labels = getLegacyParamLabels(obj)
            labels = {};

            if(isempty(obj.tasks))
                return;
            end

            params = obj.tasks(1).params;
            labels = cell(1, numel(params));

            for(i=1:numel(params))
                labels{i} = params(i).getFullLabel();
            end
        end

        function writeCaseIndexSheet(obj, xlsFile)
            sheetHeader = "Case";

            paramLabels = obj.getLegacyParamLabels();
            if(not(isempty(obj.setup)))
                paramLabels = obj.setup.getParameterLabels();
            end

            for(j=1:numel(paramLabels))
                sheetHeader(j+1) = paramLabels{j};
            end
            sheetHeader = horzcat(sheetHeader,["Status", "Output Message"]);

            caseParamValues = {};
            for(i=1:length(obj.tasks))
                task = obj.tasks(i);

                caseParamValues(i,:) = horzcat(num2cell([i, task.getArrayOfParamValues()]), ...
                                               {task.status.name, task.taskOutputMessage}); %#ok<AGROW>
            end

            C = vertcat(cellstr(sheetHeader), caseParamValues);

            obj.tryWrite(@() writecell(C, xlsFile, 'WriteMode','overwritesheet', 'Sheet','Case Index'));
        end

        function tryWrite(~, fH)
            %tryWrite A failed output write must not throw away a run that
            %already cost hours of propagation.
            try
                fH();
            catch ME
                warning('LvdCaseMatrix:outputWriteFailed', ...
                        'Could not write a sweep output file: %s', ME.message);
            end
        end
    end

    methods(Static)
        function [runFinalStatus, message, task] = runTaskWithProgress(task, outputXlsFile, progressQueue)
            %runTaskWithProgress One Optimize-mode case on a worker, with a
            %live progress queue.  The queue arrives as a direct parfeval
            %argument; the send closure is built here on the worker, so no
            %unserializable handle ever rides inside the task object.
            arguments
                task(1,1) LvdCaseMatrixTask
                outputXlsFile(1,:) char
                progressQueue = [];
            end

            taskId = task.id;

            if(isempty(progressQueue))
                progressFcn = [];
            else
                progressFcn = @(iter,fval,maxViol,optim) send(progressQueue, struct( ...
                    'taskId', taskId, 'iter', iter, 'fval', fval, 'viol', maxViol, 'optim', optim));
            end

            [runFinalStatus, message, task] = task.runTask(outputXlsFile, progressFcn);
        end

        function Idx = orderNearestFirst(A, referenceRow)
            %orderNearestFirst Rows of A ordered by standardized Euclidean
            %distance from referenceRow, nearest first.
            %
            %   Pulled out of createAllTaskParamCombos so the two task
            %   generators and the warm-start lookup all order cases the same
            %   way.  Falls back to the natural order when knnsearch cannot
            %   answer -- a degenerate reference point must not stop a run.
            arguments
                A double
                referenceRow(1,:) double
            end

            if(isempty(A))
                Idx = [];
                return;
            end

            if(numel(referenceRow) ~= width(A) || any(not(isfinite(referenceRow))))
                Idx = (1:height(A))';
                return;
            end

            warnState = warning('off','stats:pdist2:ZeroInverseWeights');
            restore = onCleanup(@() warning(warnState));

            try
                [Idx,~] = knnsearch(A, referenceRow, 'Distance','seuclidean', 'K',height(A));
                Idx = Idx(:);
            catch
                Idx = (1:height(A))';
            end
        end

        function tasks = runTaskChunk(template, tasks, outputXlsFile)
            %runTaskChunk Runs a batch of independent propagate-only cases.
            %
            %   Runs on a worker (or, in the no-pool fallback, right here).
            %   The template arrives as a byte stream so the broadcast copy is
            %   made once per worker rather than once per case, and each case
            %   gets its own fresh clone of it.
            arguments
                template
                tasks(1,:) LvdCaseMatrixTask
                outputXlsFile(1,:) char = '';
            end

            if(isa(template, 'parallel.pool.Constant'))
                templateBytes = template.Value;
            else
                templateBytes = template;
            end

            for(i=1:numel(tasks))
                try
                    tasks(i).setCaseLvdData(getArrayFromByteStream(templateBytes));

                    [runStatus, message] = tasks(i).runTask(outputXlsFile);

                    tasks(i).setTaskAsFinished(runStatus, message);

                catch ME
                    tasks(i).setTaskAsFinished(LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError, ...
                                               sprintf('Run failed due to error: %s', ME.message));
                end

                tasks(i).clearLvdDataCache();
            end
        end
    end

    methods(Static,Access='private')
        function processTaskOutputs(f, runStatus,message,task)
            [path, name, ~] = fileparts(task.lvdFilePath);

            %f.InputArguments{1} is the CLIENT's task object; task is the copy
            %the worker ran and harvested into.  Everything the run produced
            %has to be copied across by hand or it stays on the worker.
            FTask = f.InputArguments{1};

            FTask.responseValues = task.responseValues;
            FTask.responseUnits = task.responseUnits;
            FTask.responseMessages = task.responseMessages;
            FTask.taskOutputData = task.taskOutputData;
            FTask.taskOutputXlsFile = task.taskOutputXlsFile;

            FTask.optExitflag = task.optExitflag;
            FTask.optFval = task.optFval;
            FTask.optMaxViol = task.optMaxViol;
            FTask.optIters = task.optIters;
            FTask.optOptim = task.optOptim;

            FTask.setTaskAsFinished(runStatus, message);

            if(not(isempty(task.taskOutputData)) && not(isempty(task.taskOutputXlsFile)))
                try
                    writecell(task.taskOutputData, task.taskOutputXlsFile, 'WriteMode','overwritesheet', 'Sheet',name, 'UseExcel',false);
                catch ME
                    disp(ME.message);
                end
            end

            logFile = fullfile(path, [name, '.log']);

            try
                diaryText = f.Diary;
                try
                    txt = eraseTags(diaryText);
                catch
                    txt = diaryText;
                end

                fid = fopen(logFile,'w+');
                fprintf(fid, '%s', txt);
                fclose(fid);
            catch ME
                disp(ME.message);
            end
        end
    end
end
