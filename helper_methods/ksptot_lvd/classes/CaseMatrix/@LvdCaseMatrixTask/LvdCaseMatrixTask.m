classdef LvdCaseMatrixTask < matlab.mixin.SetGet
    %LvdCaseMatrixTask Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        lvdData LvdData
        caseMatrix LvdCaseMatrix
        
        caseParams(1,:) LvdCaseMatrixTaskParameter
        
        status(1,1) LvdCaseMatrixTaskStatusEnum = LvdCaseMatrixTaskStatusEnum.NotRun
        prereqTasks(1,:) LvdCaseMatrixTask
        numAttempts(1,1) double = 0;
        taskOutputMessage(1,:) char = '';
        
        lvdFilePath(1,:) char = '';
        
        pluginVarIsUsed(1,:) logical
        
        id(1,1) double
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
        function obj = LvdCaseMatrixTask(lvdData, caseMatrix, caseParams, prereqTasks, lvdFilePath, pluginVarIsUsed)
            obj.lvdData = lvdData;
            obj.caseMatrix = caseMatrix;
            obj.caseParams = caseParams;
            obj.prereqTasks = prereqTasks;
            obj.lvdFilePath = lvdFilePath;
            obj.pluginVarIsUsed = pluginVarIsUsed(:)';
            
            obj.id = rand();
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
            for(i=1:length(obj))
                values(i,:) = [obj(i).caseParams.newVal];
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
        
        function [runFinalStatus, message, obj] = runTask(obj, outputXlsFile)            
            if(obj.areAllPreReqsSatisfied())
                obj.lvdData = obj.caseMatrix.getNearestCompletedTaskLvdDataToTask(obj);

                pluginVars = obj.lvdData.pluginVars.getPluginVarsArray();
                for(i=1:length(pluginVars)) %#ok<*NO4LP> 
                    for(j=1:length(obj.caseParams))
                        if(pluginVars(i).id == obj.caseParams(j).pluginVar.id)
                            obj.caseParams(j).pluginVar = pluginVars(i);
                        end
                    end
                end

                for(i=1:length(obj.caseParams))
                    param = obj.caseParams(i);
                    param.updatePluginVar();
                end
                
                try
                    [exitflag, message] = obj.lvdData.optimizer.consoleOptimize();
                catch ME
                    exitflag = -Inf;
                    message = sprintf('Run failed due to error: %s', ME.message);
                end
                
                if(exitflag > 0)
                    runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunSuceeded;
                    
                elseif(exitflag == -Inf)
                    runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedDueToError;
                    
                else
                    runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged;
                end
                
            else
                runFinalStatus = LvdCaseMatrixTaskRunStatusEnum.RunFailedPreReqNotSatisfied;
                message = 'Prerequisite cases have not run.';
            end
            
            if(not(isempty(outputXlsFile)) && ...
               (runFinalStatus == LvdCaseMatrixTaskRunStatusEnum.RunSuceeded || runFinalStatus == LvdCaseMatrixTaskRunStatusEnum.RunFailedOptimizerNotConverged))
                obj.lvdData.stateLog = obj.lvdData.script.executeScript(false, obj.lvdData.script.getEventForInd(1), false, false, false, false);
                stateLog = obj.lvdData.stateLog.getAllEntries();
                times = [stateLog.time];

                startTimeUT = min(times);
                endTimeUT = max(times);
                [depVarValues, depVarUnits, dataEvtNums, utTimeForDepVarValues, taskLabels] = obj.lvdData.graphAnalysis.executeTasks([], startTimeUT, endTimeUT, [], []);
                
%                 varNames = ["Universal Time", taskLabels];
%                 bool = strlength(varNames) > 63;
%                 varNames(bool) = matlab.lang.makeValidName(varNames(bool));
%                 
%                 unitsStr = string(horzcat({'sec'}, depVarUnits));
%                 unitsStr(unitsStr == "") = " ";
%                 
%                 T = array2table([utTimeForDepVarValues, depVarValues], ...
%                                 'VariableNames',varNames);
%                 T.Properties.VariableUnits = unitsStr;
%                 
%                 [~,name,~] = fileparts(obj.lvdFilePath);
%                 writetable(T, outputXlsFile, 'WriteMode','overwritesheet', 'Sheet',name);

                C = cellstr(["Universal Time", taskLabels]);
                C(end+1,:) = horzcat({'sec'}, depVarUnits);
                C = vertcat(C, num2cell([utTimeForDepVarValues, depVarValues]));
                
                [~,name,~] = fileparts(obj.lvdFilePath);
                writecell(C, outputXlsFile, 'WriteMode','overwritesheet', 'Sheet',name);
            end
            
            obj.lvdData.stateLog.clearStateLog();
            lvdData = obj.lvdData;
            save(obj.lvdFilePath, 'lvdData');
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
    end
end