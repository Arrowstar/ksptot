classdef LvdCaseMatrix < matlab.mixin.SetGet
    %LvdCaseMatrix Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        current_save_location(1,:) char
        
        tasks(1,:) LvdCaseMatrixTask
        maxNumAttempts(1,1) double = 2;

        runCanceled(1,1) logical = false;
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
        
        function createAllTaskParamCombos(obj, paramsAndRanges)
            warning('off','stats:pdist2:ZeroInverseWeights');

            usedPluginVars = [paramsAndRanges{:,1}];
            paramRanges = paramsAndRanges(:,2);
            
            for(i=1:length(paramRanges))
                arr = paramRanges{i};
                arr = arr(:)';
                paramRanges{i} = arr;
            end
            
            A = combvec(paramRanges{:})'; %all parameter combinations, each row is a unique combo
            
            pluginVars = obj.lvdData.pluginVars.getPluginVarsArray();
            for(i=1:length(pluginVars))
                bool(i) = any(pluginVars(i) == usedPluginVars); %#ok<AGROW>
            end
            
            currentPluginValues = obj.lvdData.pluginVars.getPluginVarValues();
            currentPluginValues = currentPluginValues(bool);
            currentPluginValues = currentPluginValues(:)';
            
            [Idx,~] = knnsearch(A,currentPluginValues, 'Distance','seuclidean', 'K',height(A)); 
            
            numDigits = ceil(log10(abs(max(Idx))));
            for(i=1:length(Idx))
%                 newLvdDataSerialized = getByteStreamFromArray(obj.lvdData); %for now, but need to grab lvdData from the nearest finished case eventually
%                 newLvdData = getArrayFromByteStream(newLvdDataSerialized);
                
                pluginVars = obj.lvdData.pluginVars.getPluginVarsArray();
                pluginVars = pluginVars(bool);

                runParams = A(Idx(i), :);
                
                caseParams = LvdCaseMatrixTaskParameter.empty(1,0);
                for(j=1:length(runParams))
                    caseParams(j) = LvdCaseMatrixTaskParameter(pluginVars(j), runParams(j));
                end
                
                lvdFilePath = fullfile(obj.current_save_location, sprintf('Case_%0*u.mat', numDigits, i));
                
                prereqTask = LvdCaseMatrixTask.empty(1,0);
                
                obj.tasks(i) = LvdCaseMatrixTask(obj, caseParams, prereqTask, lvdFilePath, bool);

                s = LvdCaseMatrixTaskGenerationEvtData(obj.tasks(i), i, length(Idx));
                notify(obj, 'TaskCreated', s);
            end
            
            warning('on','stats:pdist2:ZeroInverseWeights');
        end
        
        function runAllTasks(obj)
            pp = gcp('nocreate');
            if(isempty(pp))
                error('No parallel pool established.  Parallel pool is required to use the case matrix functionality.');
            end
            
            d = datetime();
            xlsFile = fullfile(obj.current_save_location, sprintf('LVD_Case_Matrix_Run_%s.xlsx', datestr(d, 'yyyymmdd_HHMMSS')));
                       
            writematrix([], xlsFile, 'WriteMode','overwritesheet', 'Sheet','Case Index');
            
            for(i=1:length(obj.tasks))
                task = obj.tasks(i);
                [~,name,~] = fileparts(task.lvdFilePath);
                writematrix([],xlsFile, 'WriteMode','overwritesheet', 'Sheet',name);
            end
            
            fcn = @(nextTask) runTask(nextTask, xlsFile);
            
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
            
            sheetHeader = "Case";
            for(i=1:length(obj.tasks))
                task = obj.tasks(i);
                
                caseParamValues(i,:) = horzcat(num2cell([i, task.getArrayOfParamValues()]), {task.status.name, task.taskOutputMessage}); %#ok<AGROW> 
                
                for(j=1:length(task.caseParams)) %#ok<*NO4LP> 
                    sheetHeader(j+1) = task.caseParams(j).pluginVar.name;
                end
            end
            sheetHeader = horzcat(sheetHeader,["Status", "Output Message"]);

            C = vertcat(cellstr(sheetHeader), caseParamValues);
            writecell(C, xlsFile, 'WriteMode','overwritesheet', 'Sheet','Case Index');
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
                        %nothing, just don't do anything here
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
            statuses = [obj.tasks.status];
            numRuns = [obj.tasks.numAttempts];
            bool = (statuses == LvdCaseMatrixTaskStatusEnum.Failed & numRuns < obj.maxNumAttempts);

            successfulTasks = obj.tasks(~bool);
            successfulTasks = setdiff(successfulTasks, failedTask);
            
            sX = [];
            sP = [];
            for(i=1:length(successfulTasks))
                subX = successfulTasks(i).lvdData.optimizer.vars.getTotalScaledXVector();
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

            failedLvdData = failedTask.lvdData;
            failedLvdData.optimizer.vars.updateObjsWithScaledVarValues(fX);
            failedTask.lvdData = failedLvdData;
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
                
                A = obj.tasks.getArrayOfParamValues();
                Ai = task.getArrayOfParamValues();

                [Idx,~] = knnsearch(A, Ai, 'Distance','seuclidean', 'K',height(A)); 
                for(i=1:length(Idx))
                    subTask = obj.tasks(Idx(i));
                    if(subTask.status == LvdCaseMatrixTaskStatusEnum.Completed)
                        nearestTask = subTask;
                        nearestTaskLvdData = getArrayFromByteStream(getByteStreamFromArray(subTask.lvdData));
                        
                        break;
                    end
                end
            end            
        end
        
        function data = getUITableData(obj)
            data = {};
            for(i=1:length(obj.tasks))
                task = obj.tasks(i);
                
                values = task.getArrayOfParamValues();
                status = task.status.name;
                message = task.taskOutputMessage;
                
                valuesC = num2cell(values);
                
                data(end+1, :) = horzcat({i}, valuesC, {status, message}); %#ok<AGROW> 
            end
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

    methods(Static,Access='private')
        function processTaskOutputs(f, runStatus,message,task)
            disp('a');
            FTask = f.InputArguments{1};
            disp('b');
            FTask.setTaskAsFinished(runStatus, message);
            disp('c');
            FTask.lvdData = task.lvdData;
            disp('d');
            writecell(task.taskOutputData, task.taskOutputXlsFile, 'WriteMode','overwritesheet', 'Sheet',name, 'UseExcel',false);
            disp('e');
            [path, name, ~] = fileparts(task.lvdFilePath);
            logFile = fullfile(path, [name, '.log']);
            disp('f');
            txt = eraseTags(f.Diary);
            disp('g');
            fid = fopen(logFile,'w+'); 
            disp('h');
            fprintf(fid, '%s', txt);
            disp('i');
            fclose(fid);
            disp('j');
            
            fprintf('Output for %s:\n', name);
            disp('k');
            disp(txt);
            disp('l');
        end
    end
end