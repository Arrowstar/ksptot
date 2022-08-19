classdef LvdGraphicalAnalysis < matlab.mixin.SetGet
    %GraphicalAnalysisTask Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tasks(1,:) GraphicalAnalysisTask = GraphicalAnalysisTask.empty(1,0);

        %indep var
        indepVarType(1,1) GraphicalAnalysisIndepVarEnum = GraphicalAnalysisIndepVarEnum.MissionElapsedTime;
        indepVarTimeUnit(1,1) TimeUnitEnum = TimeUnitEnum.Seconds;

        %tabular output
        genTabTextOutput(1,1) logical = false;

        %plotting
        useSubplots(1,1) logical = false;
        subplotX(1,1) double = 3;
        subplotY(1,1) double = 3;
        lineWidth(1,1) double = 1.5;
        lineColor(1,1) ColorSpecEnum = ColorSpecEnum.White
        useEvtColors(1,1) logical = false;
        bgColor(1,1) ColorSpecEnum = ColorSpecEnum.Black
        lineType(1,1) LineSpecEnum = LineSpecEnum.SolidLine

        %plotting options
        showGrid(1,1) logical = true;
        showEvtEnds(1,1) logical = false;
        showSoITrans(1,1) logical = false;
        showPeriCrossings(1,1) logical = false;
        showApoCrossings(1,1) logical = false;

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

        function ind = getIndOfTask(obj, tasks)
            ind = find([obj.tasks] == tasks,1,'first');
        end

        function moveTaskUp(obj, task)
            ind = obj.getIndOfTask(task);
            
            if(ind > 1)
                obj.tasks([ind,ind-1]) = obj.tasks([ind-1,ind]);
            end
        end
        
        function moveTaskDown(obj, task)
            ind = obj.getIndOfTask(task);
            
            if(ind < obj.getNumTasks())
                obj.tasks([ind+1,ind]) = obj.tasks([ind,ind+1]);
            end
        end
        
        function [depVarValues, depVarUnits, dataEvtNums, utTimeForDepVarValues, taskLabels] = executeTasks(obj, hFig, startTimeUT, endTimeUT, otherSCId, stationID)
            propNames = obj.lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            celBodyData = obj.lvdData.celBodyData;
            
            lvdSubLog = obj.lvdData.stateLog.getStateLogEntriesBetweenTimes(startTimeUT, endTimeUT);
            
            depVarValues = zeros(numel(lvdSubLog), length(obj.tasks));
            depVarUnits = cell(1,length(obj.tasks));
            utTimeForDepVarValues = NaN(numel(lvdSubLog),1);
            
            if(not(isempty(hFig)))
                hWaitBar = uiprogressdlg(hFig, 'Value',0, 'Message','Computing Dependent Variables...', 'Title','Computing Dependent Variables');
            else
                hWaitBar = [];
            end
            
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            
            dataEvtNums = [];
            prevDistTraveled = 0;
            for(i=1:numel(lvdSubLog)) %#ok<*NO4LP> 
                lvdStateLogEntry = lvdSubLog(i);
                
                for(j=1:length(obj.tasks))
                    task = obj.tasks(j);  
                    
                    if(not(isempty(hWaitBar)) && isvalid(hWaitBar))
                        hWaitBar.Value = i/length(lvdSubLog);
                        hWaitBar.Message = sprintf('Computing Dependent Variables...\n[%u of %u]', i, length(lvdSubLog));
                    end

                    try
                        [depVarValues(i,j), depVarUnits{j}, prevDistTraveled] = task.executeTask(lvdStateLogEntry, maTaskList, prevDistTraveled, otherSCId, stationID, propNames, celBodyData);
                    catch ME %#ok<NASGU> 
                        depVarValues(i,j) = -1;
                        depVarUnits{j} = '';
                    end
                end

                dataEvtNums(i) = lvdStateLogEntry.event.getEventNum(); %#ok<AGROW>
                utTimeForDepVarValues(i) = lvdStateLogEntry.time;
            end
            
            for(i=1:length(obj.tasks))
                taskLabels(i) = string(obj.tasks(i).getListBoxStr()); %#ok<AGROW> 
            end
            
            if(not(isempty(hWaitBar)) && isvalid(hWaitBar))
                close(hWaitBar);
            end
        end
        
        function tf = usesGeometricRefFrame(obj, refFrame)
            tf = false;
            for(i=1:length(obj.tasks))
                tf = tf || obj.tasks(i).usesGeometricRefFrame(refFrame);
            end
        end
    end
end