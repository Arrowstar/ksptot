classdef LvdGraphicalAnalysis < matlab.mixin.SetGet
    %GraphicalAnalysisTask Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tasks(1,:) GraphicalAnalysisTask = GraphicalAnalysisTask.empty(1,0);
        
        lvdData
    end
    
    methods
        function obj = LvdGraphicalAnalysis(lvdData)
            obj.lvdData = lvdData;
        end
        
        function addTask(obj, newTask)
            obj.tasks(end+1) = newTask;
        end
        
        function removeTask(obj, task)
            obj.tasks([obj.tasks] == task) = [];
        end
        
        function tasks = getTasks(obj)
            tasks = obj.tasks;
        end
        
        function numTasks = getNumTasks(obj)
            numTasks = length(obj.tasks);
        end
        
        function [listBoxStr, allTasks] = getListBoxStr(obj)
            listBoxStr = {};
            for(i=1:length(obj.tasks))
                listBoxStr{end+1} = obj.tasks(i).getListBoxStr(); %#ok<AGROW>
            end
            
            allTasks = obj.tasks;
        end
        
        function [depVarValues, depVarUnits, dataEvtNums] = executeTasks(obj, hFig, startTimeUT, endTimeUT, otherSCId, stationID)
            propNames = obj.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            celBodyData = obj.lvdData.celBodyData;
            
            lvdSubLog = obj.lvdData.stateLog.getStateLogEntriesBetweenTimes(startTimeUT, endTimeUT);
            
            depVarValues = zeros(numel(lvdSubLog), length(obj.tasks));
            depVarUnits = cell(1,length(obj.tasks));
            
            hWaitBar = uiprogressdlg(hFig, 'Value',0, 'Message','Computing Dependent Variables...', 'Title','Computing Dependent Variables');
            
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            
            dataEvtNums = [];
            prevDistTraveled = 0;
            for(i=1:numel(lvdSubLog))
                lvdStateLogEntry = lvdSubLog(i);
                
                for(j=1:length(obj.tasks))
                    task = obj.tasks(j);  
                    
                    if(isvalid(hWaitBar))
                        hWaitBar.Value = i/length(lvdSubLog);
                        hWaitBar.Message = sprintf('Computing Dependent Variables...\n[%u of %u]', i, length(lvdSubLog));
                    end

                    [depVarValues(i,j), depVarUnits{j}, prevDistTraveled] = task.executeTask(lvdStateLogEntry, maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData);
                end

                dataEvtNums(i) = lvdStateLogEntry.event.getEventNum(); %#ok<AGROW>
            end
            close(hWaitBar);
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.tasks))
                tf = tf || obj.tasks(i).usesGeometricRefFrame(refFrame);
            end
        end
    end
end