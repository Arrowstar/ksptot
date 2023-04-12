classdef SetLvdPluginVarValueAction < AbstractEventAction
    %SetLvdPluginValueAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pluginVar LvdPluginOptimVarWrapper
        pluginValueToSet(1,1) double = 0;
    end
    
    methods
        function obj = SetLvdPluginVarValueAction(lvdPluginVar, pluginValueToSet)
            if(nargin > 0)
                obj.pluginVar = lvdPluginVar;
                obj.pluginValueToSet = pluginValueToSet;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) SetLvdPluginVarValueAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            newStateLogEntry = stateLogEntry;

            obj.pluginVar.value = obj.pluginValueToSet;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            name = sprintf('Set Plugin Variable Value (%s => %0.3f)', obj.pluginVar.name, obj.pluginValueToSet);
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
                action(1,1) SetLvdPluginVarValueAction
                lv(1,1) LaunchVehicle
            end

            lvdData = lv.lvdData;
            numPluginVars = lvdData.pluginVars.getNumPluginVars();

            if(numPluginVars > 0)
                if(isempty(action.pluginVar))
                    action.pluginVar = lvdData.pluginVars.getPluginVarAtInd(1);
                end

                output = AppDesignerGUIOutput({false});
                lvd_EditActionSetPluginVarValueGUI_App(action, output);
                addActionTf = output.output{1};
            else
                addActionTf = false;
                warndlg('There are no plugin variables in this mission.  Create one first.','Cannot Create Action','modal');
            end
        end
    end
end