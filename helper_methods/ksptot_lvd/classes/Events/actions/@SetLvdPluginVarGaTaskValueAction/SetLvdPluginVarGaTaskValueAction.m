classdef SetLvdPluginVarGaTaskValueAction < AbstractEventAction
    %SetLvdPluginValueAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pluginVar LvdPluginOptimVarWrapper
        taskStr(1,:) char
        frame AbstractReferenceFrame

        task GraphicalAnalysisTask
    end
    
    methods
        function obj = SetLvdPluginVarGaTaskValueAction(lvdPluginVar, taskStr, frame)
            if(nargin > 0)
                obj.pluginVar = lvdPluginVar;
                obj.taskStr = taskStr;
                obj.frame = frame;

                obj.task = GraphicalAnalysisTask(taskStr, frame); %replaced in init area
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) SetLvdPluginVarGaTaskValueAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            newStateLogEntry = stateLogEntry;
            lvdData = newStateLogEntry.lvdData;
            gaTaskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());

            propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            celBodyData = lvdData.celBodyData;

            value = obj.task.executeTask(newStateLogEntry, gaTaskList, 0, [], [], propNames, celBodyData);

            obj.pluginVar.value = value;

            pluginVarState = newStateLogEntry.getPluginVarStateForPluginVar(obj.pluginVar);
            pluginVarState.valueAtState = value;
        end
        
        function initAction(obj, initialStateLogEntry)
            obj.task = GraphicalAnalysisTask(obj.taskStr, obj.frame);
        end
        
        function name = getName(obj)            
            name = sprintf('Set Plugin Variable Value to Quantity (%s => %s)', obj.pluginVar.name, obj.task.getListBoxStr());
        end
        
        function tf = usesPluginVariable(obj, pluginVar)
            arguments
                obj(1,1) AbstractEventAction
                pluginVar(1,1) LvdPluginOptimVarWrapper
            end

            tf = obj.pluginVar == pluginVar;
        end
                
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)      
            arguments
                action(1,1) SetLvdPluginVarGaTaskValueAction
                lv(1,1) LaunchVehicle
            end

            lvdData = lv.lvdData;
            numPluginVars = lvdData.pluginVars.getNumPluginVars();

            if(numPluginVars > 0)
                if(isempty(action.pluginVar))
                    action.pluginVar = lvdData.pluginVars.getPluginVarAtInd(1);
                end

                if(isempty(action.taskStr))
                    gaTaskList = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());

                    action.taskStr = gaTaskList{1};
                end

                if(isempty(action.frame))
                    action.frame = lvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
                end

                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetPluginVarGaTaskValueGUI_App(action, lvdData, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no plugin variables in this mission.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end