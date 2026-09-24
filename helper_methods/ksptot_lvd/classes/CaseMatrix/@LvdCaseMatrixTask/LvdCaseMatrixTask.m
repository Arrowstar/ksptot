classdef LvdCaseMatrixTask < matlab.mixin.SetGet
    %LvdCaseMatrixTask One case of a sweep: a set of parameter values, the
    %mission file they are applied to, and the run state machine around it.
    %
    %   A task holds parameter DEFINITIONS (params) alongside the values this
    %   particular case applies (paramValues).  The two arrays run in
    %   parallel.  That split is what generalized the case matrix beyond
    %   plugin variables: the definitions know how to find and write their
    %   target in any mission, so the same task machinery drives a plugin
    %   variable, an optimization variable element, a constraint bound or a
    %   vehicle knob without caring which it is.
    %
    %   The mission itself is NOT held in memory.  It lives in a .mat file at
    %   lvdFilePath and is reached through loadLvdData/saveLvdData, which
    %   cache the handle in a Transient property.  This used to be a dependent
    %   property whose getter was a bare load(), so every single read
    %   deserialized an entire mission off disk -- including once per
    %   iteration inside LvdCaseMatrix.updateFailedTaskWithFitXVector, and
    %   twice for no effect at all in processTaskOutputs.

    properties
        caseMatrix LvdCaseMatrix

        %Parallel arrays: params(i) is applied with the value paramValues(i).
        params(1,:) AbstractLvdSweepParameter = AbstractLvdSweepParameter.empty(1,0);
        paramValues(1,:) double = [];

        %What to harvest out of this case once it has run, and what came out.
        responses(1,:) LvdSweepResponse = LvdSweepResponse.empty(1,0);
        responseValues(1,:) double = [];
        responseUnits(1,:) cell = {};
        responseMessages(1,:) cell = {};

        %Optimize-mode run summary, harvested after the run.  NaN in
        %propagate-only mode, which never optimizes.  optIters fills in
        %during the run; the other three are harvested off the
        %re-propagated final log.
        optExitflag(1,1) double = NaN;
        optFval(1,1) double = NaN;
        optMaxViol(1,1) double = NaN;
        optIters(1,1) double = NaN;

        %Latest reported first-order optimality, when the solver reports
        %one (fmincon-family, IPOPT, Adam).  NaN otherwise; display-only,
        %never an optimization input.
        optOptim(1,1) double = NaN;

        runMode(1,1) LvdCaseMatrixRunModeEnum = LvdCaseMatrixRunModeEnum.Optimize;

        %Per-case graphical analysis time series sheet, and the per-case .mat
        %file.  Both are always on in Optimize mode (the warm start reads the
        %.mat) and optional in propagate-only mode, where at Monte Carlo
        %sample counts they dominate the run time.
        writeGaTimeSeries(1,1) logical = true;
        persistCaseFile(1,1) logical = true;

        status(1,1) LvdCaseMatrixTaskStatusEnum = LvdCaseMatrixTaskStatusEnum.NotRun
        prereqTasks(1,:) LvdCaseMatrixTask
        numAttempts(1,1) double = 0;

        taskOutputXlsFile(1,:) char = '';
        taskOutputMessage(1,:) char = '';
        taskOutputData cell

        lvdFilePath(1,:) char = '';

        %Which of the mission's plugin variables this case sweeps.  Only
        %meaningful for the legacy plugin-variable-only path; kept because the
        %case matrix window's column headings are built from it.
        pluginVarIsUsed(1,:) logical

        id(1,1) double
    end

    properties(Hidden)
        %DEPRECATED.  Retained only so tasks inside case files written by an
        %older build still deserialize with their values intact; loadobj
        %migrates them into params/paramValues.
        caseParams(1,:) LvdCaseMatrixTaskParameter
    end

    properties(Transient, Access=private)
        %The mission from lvdFilePath, once it has been read.  Transient: a
        %task is serialized to a parallel worker, and shipping a whole mission
        %along with it would defeat the point of keeping it on disk.
        cachedLvdData LvdData
    end

    properties(Dependent)
        caseNumber(1,1) double
    end

    events
        StatusUpdated
        NumAttemptsUpdated
        OutputMessageUpdated
    end

    methods
        function obj = LvdCaseMatrixTask(caseMatrix, params, paramValues, prereqTasks, lvdFilePath, pluginVarIsUsed)
            arguments
                caseMatrix LvdCaseMatrix
                params(1,:) AbstractLvdSweepParameter
                paramValues(1,:) double
                prereqTasks(1,:) LvdCaseMatrixTask
                lvdFilePath(1,:) char
                pluginVarIsUsed(1,:) logical = false(1,0);
            end

            obj.lvdFilePath = lvdFilePath;
            obj.caseMatrix = caseMatrix;
            obj.params = params;
            obj.paramValues = paramValues;
            obj.prereqTasks = prereqTasks;
            obj.pluginVarIsUsed = pluginVarIsUsed(:)';

            obj.id = rand();
        end

        function lvdData = loadLvdData(obj)
            %loadLvdData This case's mission, read once and then cached.
            if(not(isempty(obj.cachedLvdData)))
                lvdData = obj.cachedLvdData;
                return;
            end

            if(not(isfile(obj.lvdFilePath)))
                error('LvdCaseMatrixTask:caseFileNotFound', ...
                      'The case file for this task does not exist (yet?): %s', obj.lvdFilePath);
            end

            s = load(obj.lvdFilePath, 'lvdData');

            if(not(isfield(s, 'lvdData')))
                error('LvdCaseMatrixTask:notACaseFile', ...
                      'The file "%s" does not contain a mission.', obj.lvdFilePath);
            end

            lvdData = s.lvdData;
            obj.cachedLvdData = lvdData;
        end

        function saveLvdData(obj, lvdData)
            %saveLvdData Writes the case file and refreshes the cache to match.
            arguments
                obj(1,1) LvdCaseMatrixTask
                lvdData(1,1) LvdData
            end

            save(obj.lvdFilePath, 'lvdData'); %#ok<*NASGU>

            obj.cachedLvdData = lvdData;
        end

        function setCaseLvdData(obj, lvdData)
            %setCaseLvdData Hands this task the mission to run, without it
            %having to come off disk.
            %
            %   This is how a propagate-only case gets its copy of the
            %   template: the worker clones the broadcast byte stream and
            %   injects the result, so a run with persistCaseFile off never
            %   touches the file system at all.
            %
            %   Stored sweep results are shed here: they belong to the
            %template, and a case-bound clone neither needs them (it harvests
            %fresh ones) nor should persist them into per-case files.
            arguments
                obj(1,1) LvdCaseMatrixTask
                lvdData(1,1) LvdData
            end

            lvdData.clearStoredSweepResults();
            obj.cachedLvdData = lvdData;
        end

        function newObj = makeDetachedCopy(obj)
            %makeDetachedCopy A dispatchable copy with no link back to the
            %case matrix.
            %
            %   A task's caseMatrix back-reference drags the whole matrix --
            %   every other task and the template mission -- through the
            %   serializer on its way to a worker.  Optimize mode needs that
            %   (it warm starts off the other tasks); an independent
            %   propagate-only case does not, and at Monte Carlo sample counts
            %   paying for it per chunk would dominate the run.
            arguments
                obj(1,1) LvdCaseMatrixTask
            end

            newObj = LvdCaseMatrixTask(LvdCaseMatrix.empty(1,0), obj.params, obj.paramValues, ...
                                       LvdCaseMatrixTask.empty(1,0), obj.lvdFilePath, obj.pluginVarIsUsed);

            newObj.responses = obj.responses;
            newObj.runMode = obj.runMode;
            newObj.writeGaTimeSeries = obj.writeGaTimeSeries;
            newObj.persistCaseFile = obj.persistCaseFile;
            newObj.status = obj.status;
            newObj.numAttempts = obj.numAttempts;

            %Same id as the original: that is what the client matches the
            %returned results back onto its own task by.
            newObj.id = obj.id;
        end

        function clearLvdDataCache(obj)
            %clearLvdDataCache Drops the in-memory mission.  Call after a run
            %so a finished sweep does not hold every case's mission at once.
            for(i=1:numel(obj)) %#ok<*NO4LP>
                obj(i).cachedLvdData = LvdData.empty(1,0);
            end
        end

        function set.status(obj, newStatus)
            oldStatus = obj.status;
            obj.status = newStatus;

            sStatus.oldStatus = oldStatus;
            sStatus.newStatus = newStatus;

            data = LvdCaseMatrixTaskNotifyEventData(obj, sStatus);

            notify(obj,'StatusUpdated',data);
        end

        function set.numAttempts(obj, newNumAttempts)
            obj.numAttempts = newNumAttempts;

            data = LvdCaseMatrixTaskNotifyEventData(obj, newNumAttempts);

            notify(obj,'NumAttemptsUpdated',data);
        end

        function set.taskOutputMessage(obj, newMessage)
            obj.taskOutputMessage = newMessage;

            data = LvdCaseMatrixTaskNotifyEventData(obj, newMessage);

            notify(obj,'OutputMessageUpdated',data);
        end

        function value = get.caseNumber(obj)
            value = find(obj == obj.caseMatrix.tasks,1,'first');
        end

        function setTaskStatusAsRunning(obj)
            obj.status = LvdCaseMatrixTaskStatusEnum.Running;
            obj.numAttempts = obj.numAttempts + 1;
            obj.taskOutputMessage = 'Running...';
        end

        function values = getArrayOfParamValues(obj)
            %getArrayOfParamValues One row per task, one column per parameter.
            numParams = 0;
            for(i=1:numel(obj))
                numParams = max(numParams, numel(obj(i).paramValues));
            end

            values = NaN(numel(obj), numParams);

            for(i=1:numel(obj))
                v = obj(i).paramValues;
                values(i,1:numel(v)) = v;
            end
        end

        function values = getArrayOfResponseValues(obj)
            %getArrayOfResponseValues One row per task, one column per
            %response.  NaN wherever a case could not produce that response.
            numResp = 0;
            for(i=1:numel(obj))
                numResp = max(numResp, numel(obj(i).responses));
            end

            values = NaN(numel(obj), numResp);

            for(i=1:numel(obj))
                v = obj(i).responseValues;

                if(numel(v) == numResp)
                    values(i,:) = v;
                elseif(not(isempty(v)))
                    values(i,1:numel(v)) = v;
                end
            end
        end

        function setTaskAsFinished(obj, runFinalStatus, message)
            switch runFinalStatus
                case LvdCaseMatrixTaskRunStatusEnum.RunSuceeded
                    obj.status = LvdCaseMatrixTaskStatusEnum.Completed;

                case {LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError, LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged, LvdCaseMatrixTaskRunStatusEnum.RunFailedPreReqNotSatisfied}
                    obj.status = LvdCaseMatrixTaskStatusEnum.Failed;

                otherwise
                    error('Unknown or unexpected run status: %s', runFinalStatus.name);
            end

            obj.taskOutputMessage = message;
        end

        function setTaskAsUnRun(obj)
            obj.status = LvdCaseMatrixTaskStatusEnum.NotRun;
            obj.numAttempts = 0;
            obj.taskOutputMessage = '';
        end

        function [runFinalStatus, message, obj] = runTask(obj, outputXlsFile, progressFcn)
            %runTask Runs this one case, start to finish, in whatever process
            %it finds itself in.  Returns the task so a parfeval future hands
            %the harvested values back to the client.
            %
            %   progressFcn(iteration, fval, maxConstrViol, optimality) is
            %called after every reported optimizer iteration in Optimize
            %mode (it runs on the worker; it must only touch serializable
            %values, never UI).  The task always records the latest values
            %into optIters/optFval/optMaxViol itself, so the run's final
            %harvest has them with or without a listener.
            arguments
                obj(1,1) LvdCaseMatrixTask
                outputXlsFile(1,:) char = '';
                progressFcn = [];
            end

            %The per-case diary is an artefact of the same kind as the case
            %file: worth having when a long optimization needs a record of what
            %it did, pure overhead when a dispersion run is propagating
            %thousands of independent samples.  So it follows persistCaseFile,
            %which is what makes setCaseLvdData's promise -- a run with
            %persistCaseFile off touches no files at all -- actually true.
            %
            %Putting the diary back matters because the no-pool fallback runs
            %this method in the CLIENT process, not on a worker: redirecting
            %the diary and walking away would leave the user's whole session
            %logging into the last case's temporary file.
            if(obj.persistCaseFile)
                prevDiaryState = get(0,'Diary');
                prevDiaryFile = get(0,'DiaryFile');
                restoreDiary = onCleanup(@() LvdCaseMatrixTask.setDiaryState(prevDiaryState, prevDiaryFile));

                [folderName,name,~] = fileparts(obj.lvdFilePath);
                dName = fullfile(folderName,sprintf('%s_running.log',name));
                diary('off');
                diary(dName);
                disp(dName);
                disp('This log file records the MATLAB diary for each run as it processes it.');
            end

            lvdData = LvdData.empty(1,0);

            if(not(obj.areAllPreReqsSatisfied()))
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedPreReqNotSatisfied;
                message = 'Prerequisite cases have not run.';
            else
                [lvdData, runFinalStatus, message, exitflag] = obj.prepareAndRunCase(progressFcn);
            end

            if(not(isempty(lvdData)) && ...
               (runFinalStatus == LvdCaseMatrixTaskRunStatusEnum.RunSuceeded || runFinalStatus == LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged))

                try
                    %In Optimize mode the state log left behind by the
                    %optimizer belongs to whichever trial vector fmincon
                    %evaluated last, which is not necessarily the answer it
                    %returned.  Re-propagate on the final x so the harvested
                    %numbers describe the solution.  Propagate-only mode has
                    %already produced exactly the log it wants.
                    if(obj.runMode == LvdCaseMatrixRunModeEnum.Optimize)
                        obj.propagateCase(lvdData);
                    end

                    obj.harvestResponses(lvdData);

                    if(obj.runMode == LvdCaseMatrixRunModeEnum.Optimize)
                        obj.optExitflag = exitflag;
                        obj.harvestOptimizationSummary(lvdData);
                    end

                    if(obj.writeGaTimeSeries)
                        obj.taskOutputXlsFile = outputXlsFile;
                        obj.harvestGaTimeSeries(lvdData);
                    end

                catch ME
                    runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError;
                    message = sprintf('Run failed due to error: %s', ME.message);
                    disp(message);
                    if(not(isempty(ME.stack)))
                        disp(ME.stack(1));
                    end
                end
            end

            if(not(isempty(lvdData)) && obj.persistCaseFile)
                %The state log is by far the largest thing in a mission and
                %is regenerable; a sweep of a thousand cases would otherwise
                %write gigabytes of it.
                lvdData.stateLog.clearStateLog();
                obj.saveLvdData(lvdData);
            end
        end

        function tf = areAllPreReqsSatisfied(obj)
            if(not(isempty(obj.prereqTasks)))
                tf = true;
                for(i=1:length(obj.prereqTasks))
                    if(obj.prereqTasks(i).status ~= LvdCaseMatrixTaskStatusEnum.Completed)
                        tf = false;
                        break;
                    end
                end

            else
                tf = true;
            end
        end

        function [ok, msg] = applyParamsTo(obj, lvdData)
            %applyParamsTo Rebinds every parameter onto this mission and
            %writes this case's value into it.
            %
            %   Rebinding is unavoidable: the mission here is a byte stream
            %   clone (warm start) or a fresh deserialization (retry), so
            %   every handle the parameter captured when the user picked it
            %   belongs to a different object graph.  resolve() finds the
            %   counterpart by id.
            arguments
                obj(1,1) LvdCaseMatrixTask
                lvdData(1,1) LvdData
            end

            ok = true;
            msg = '';

            for(i=1:numel(obj.params))
                param = obj.params(i);

                if(not(param.resolve(lvdData)))
                    ok = false;
                    msg = sprintf('Sweep parameter "%s" no longer exists in this mission.', param.getName());
                    return;
                end

                try
                    param.applyValue(obj.paramValues(i));
                catch ME
                    ok = false;
                    msg = sprintf('Could not apply sweep parameter "%s": %s', param.getName(), ME.message);
                    return;
                end
            end
        end
    end

    methods(Access=private)
        function [lvdData, runFinalStatus, message, exitflag] = prepareAndRunCase(obj, progressFcn)
            %prepareAndRunCase Get the mission, apply the case, run it.
            %   Also returns the optimizer exit flag (NaN outside Optimize
            %mode) so the caller can record how the run ended.  progressFcn
            %is forwarded to the optimizer in Optimize mode; see runTask.
            arguments
                obj(1,1) LvdCaseMatrixTask
                progressFcn = [];
            end

            %First attempt: start from the nearest already-converged case, so
            %a sweep walks its way across the design space instead of
            %restarting from the template every time.  A retry starts from
            %this case's own file, which holds wherever the failed attempt
            %got to.
            exitflag = NaN;

            if(obj.numAttempts <= 1 && not(isempty(obj.caseMatrix)))
                lvdData = obj.caseMatrix.getNearestCompletedTaskLvdDataToTask(obj);
            else
                lvdData = obj.loadLvdData();
            end

            %Case-bound clones shed stored sweep results (the warm-start and
            %retry paths materialize the mission here; the chunk path sheds
            %in setCaseLvdData).  The template itself is never stripped.
            lvdData.clearStoredSweepResults();

            [ok, applyMsg] = obj.applyParamsTo(lvdData);

            if(not(ok))
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError;
                message = applyMsg;
                disp(message);
                return;
            end

            try
                switch obj.runMode
                    case LvdCaseMatrixRunModeEnum.Optimize
                        %Persist before optimizing: consoleOptimize can run
                        %for a long time, and the file on disk is what a
                        %retry and the warm start of later cases read.
                        if(obj.persistCaseFile)
                            obj.saveLvdData(lvdData);
                        end

                        %Nested parallelism: this case already occupies a
                        %parallel worker, so optimizer-level parallelism
                        %(finite-difference pools, solver UseParallel) would
                        %nest.  Force serial on this clone; the guard
                        %restores the user's setting on every exit, before
                        %the post-run harvest and save in runTask.
                        restoreSerial = obj.forceSerialOptimizerForCase(lvdData);
                        serialGuard = onCleanup(@() restoreSerial());

                        %The recording closure always rides along so optIters
                        %is harvested; the listener (a queue sender) rides
                        %only when someone is watching live.
                        if(isempty(progressFcn))
                            caseProgressFcn = @(iter,fval,maxViol,optim) obj.recordProgress(iter,fval,maxViol,optim);
                        else
                            listener = progressFcn;
                            caseProgressFcn = @(iter,fval,maxViol,optim) LvdCaseMatrixTask.recordAndForward(obj, listener, iter,fval,maxViol,optim);
                        end

                        [exitflag, message] = lvdData.optimizer.consoleOptimize(caseProgressFcn);

                    otherwise
                        obj.propagateCase(lvdData);

                        if(lvdData.script.lastRunCompletedFully)
                            exitflag = 1;
                            message = 'Propagation completed.';
                        else
                            %A script that stopped early produced a partial
                            %state log.  That is a failed case, not a case
                            %with short results.
                            exitflag = 0;
                            message = 'Propagation did not run the full script to completion.';
                        end
                end

            catch ME
                exitflag = -Inf;
                message = sprintf('Run failed due to error: %s', ME.message);
                disp(message);
                if(not(isempty(ME.stack)))
                    disp(ME.stack(1));
                end
            end

            if(exitflag > 0)
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunSuceeded;

            elseif(exitflag == -Inf)
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError;

            else
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged;
            end
        end

        function propagateCase(~, lvdData)
            %propagateCase A full, dense, non-interactive run of the script.
            %
            %   Incremental reuse is off: the parameter this case applied may
            %   be something the incremental resolver does not track (a tank
            %   capacity, a scaled thrust curve), and reusing a cached log
            %   would then silently return the previous case's trajectory.
            evt1 = lvdData.script.getEventForInd(1);

            lvdData.stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);
        end

        function harvestResponses(obj, lvdData)
            numResp = numel(obj.responses);

            obj.responseValues = NaN(1, numResp);
            obj.responseUnits = repmat({''}, 1, numResp);
            obj.responseMessages = repmat({''}, 1, numResp);

            for(i=1:numResp)
                [value, unit, msg] = obj.responses(i).evaluate(lvdData);

                obj.responseValues(i) = value;
                obj.responseUnits{i} = unit;
                obj.responseMessages{i} = msg;
            end
        end

        function harvestGaTimeSeries(obj, lvdData)
            %harvestGaTimeSeries The per-case sheet of every graphical
            %analysis task in the mission, over the whole run.
            if(lvdData.graphAnalysis.getNumTasks() <= 0)
                obj.taskOutputData = {'No Graphical Analysis tasks in scenario.'};
                return;
            end

            entries = lvdData.stateLog.getAllEntries();

            if(isempty(entries))
                obj.taskOutputData = {'No state log entries: the mission did not propagate.'};
                return;
            end

            times = [entries.time];

            [depVarValues, depVarUnits, ~, utTimeForDepVarValues, taskLabels] = ...
                lvdData.graphAnalysis.executeTasks([], min(times), max(times), [], []);

            C = cellstr(["Universal Time", taskLabels]);
            C(end+1,:) = horzcat({'sec'}, depVarUnits);
            C = vertcat(C, num2cell([utTimeForDepVarValues, depVarValues]));

            obj.taskOutputData = C;
        end

        function recordProgress(obj, iter, fval, maxViol, optim)
            %recordProgress Remembers the latest reported optimizer iterate
            %so the final harvest has it even if nobody listened live.
            arguments
                obj(1,1) LvdCaseMatrixTask
                iter(1,1) double
                fval(1,1) double
                maxViol(1,1) double
                optim(1,1) double = NaN
            end

            if(isfinite(iter))
                obj.optIters = iter;
            end
            if(isfinite(fval))
                obj.optFval = fval;
            end
            if(isfinite(maxViol))
                obj.optMaxViol = maxViol;
            end
            if(isfinite(optim))
                obj.optOptim = optim;
            end
        end

        function harvestOptimizationSummary(obj, lvdData)
            %harvestOptimizationSummary Final objective value and maximum
            %constraint violation off the re-propagated log.  Neither
            %propagates: the objective hits the E1 x-keyed evaluation cache
            %(this x just optimized) and the constraints read the given log
            %directly.  Failures stay NaN rather than losing the case.
            obj.optFval = NaN;
            obj.optMaxViol = NaN;

            try
                evt1 = lvdData.script.getEventForInd(1);
                [x, ~, ~] = lvdData.optimizer.vars.getTotalScaledXVector();

                [f, ~] = lvdData.optimizer.objFcn.evalObjFcn(x, evt1);
                if(isfinite(f))
                    obj.optFval = f;
                end

                [c, ceq] = lvdData.optimizer.constraints.evalConstraints(x, false, evt1, false, lvdData.stateLog);
                v = [c(:); abs(ceq(:))];
                v = v(isfinite(v) & v > 0);

                if(isempty(v))
                    obj.optMaxViol = 0;
                else
                    obj.optMaxViol = max(v);
                end
            catch ME
                disp(['Could not harvest the optimization summary: ' ME.message]);
            end
        end
    end

    methods(Static)
        function restoreFcn = forceSerialOptimizerForCase(lvdData)
            %forceSerialOptimizerForCase Pins the selected optimizer to
            %serial evaluation for one case run, returning a closure that
            %restores the user's setting.
            %
            %   A case already occupies a parallel worker, so
            %optimizer-level parallelism (parallel finite differences, solver
            %UseParallel) would nest pools, warn and oversubscribe.  Every
            %downstream reader (gradient methods, problem.UseParallel, the
            %lvd_executeOptimProblem broadcast) goes through the selected
            %optimizer's options object, so forcing that one flag covers
            %them all.  The flag's property is useParallel everywhere except
            %AdamNlOpt (parallel); both enums carry a DoNotUseParallel
            %member.  The template on the client is never touched: this runs
            %on the worker's clone.
            arguments
                lvdData(1,1) LvdData
            end

            restoreFcn = @() [];

            optimizer = lvdData.optimizer.getSelectedOptimizer();
            opts = optimizer.getOptions();

            if(isprop(opts, 'useParallel'))
                prop = 'useParallel';
            elseif(isprop(opts, 'parallel'))
                prop = 'parallel';
            else
                return;
            end

            prior = opts.(prop);

            %Member .name values are display strings ("Compute Gradients in
            %Parallel"), not identifiers, so the serial member is the one
            %whose optionVal is false -- true in every optimizer's enum.
            if(not(isprop(prior, 'optionVal')))
                warning('LvdCaseMatrixTask:unknownParallelEnum', ...
                    'Could not read the parallel flag on %s; optimizer-level parallelism left as-is.', class(opts));
                return;
            end

            members = enumeration(prior);
            idx = find(not([members.optionVal]), 1, 'first');

            if(isempty(idx))
                warning('LvdCaseMatrixTask:unknownParallelEnum', ...
                    'Could not find a serial member on %s; optimizer-level parallelism left as-is.', class(opts));
                return;
            end

            opts.(prop) = members(idx);
            restoreFcn = @() LvdCaseMatrixTask.restoreOptimizerParallelMember(opts, prop, prior);
        end

        function restoreOptimizerParallelMember(opts, prop, prior)
            %restoreOptimizerParallelMember Writes back the parallel member
            %captured before forcing serial.  Idempotent: assigning the same
            %member twice is a no-op, so an onCleanup backstop plus an
            %explicit restore never double-applies.
            opts.(prop) = prior;
        end

        function recordAndForward(task, listener, iter, fval, maxViol, optim)
            %recordAndForward Remembers the iterate on the task and forwards
            %it to the live listener (a queue sender).  Static so the
            %worker-side closure stays a plain function of values.
            task.recordProgress(iter, fval, maxViol, optim);
            listener(iter, fval, maxViol, optim);
        end

        function setDiaryState(state, file)
            %setDiaryState Puts the diary back the way a case run found it.
            diary('off');

            if(not(isempty(file)))
                set(0, 'DiaryFile', file);
            end

            if(strcmpi(state, 'on'))
                diary('on');
            end
        end

        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end

            %Migrate a task written before parameters were generalized.  An
            %LvdCaseMatrixTaskParameter is itself a sweep parameter now, so
            %the definitions carry straight over; only the values, which used
            %to live on the parameter as newVal, have to be lifted out.
            if(isempty(obj.params) && not(isempty(obj.caseParams)))
                obj.params = obj.caseParams;
                obj.paramValues = [obj.caseParams.newVal];
            end
        end
    end
end
