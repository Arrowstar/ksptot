classdef ResetExtremumValueAction < AbstractEventAction
    %ResetExtremumValueAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        extremum LaunchVehicleExtrema
    end
    
    methods
        function obj = ResetExtremumValueAction(extremum)
            if(nargin > 0)
                obj.extremum = extremum;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            newStateLogEntry = stateLogEntry;
            
            if(not(isempty(obj.extremum)))
                extremaState = newStateLogEntry.extremaStates([newStateLogEntry.extremaStates.extrema] == obj.extremum);
                extremaState.value = NaN;
            end
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            if(not(isempty(obj.extremum)))
                nameStr = obj.extremum.getNameStr();
            else
                nameStr = '<No Extremum Selected>';
            end
            
            name = sprintf('Reset Extremum Value (%s)', nameStr);
        end
        
        function tf = usesStage(obj, stage)
            tf = false;
        end
        
        function tf = usesEngine(obj, engine)
            tf = false;
        end
        
        function tf = usesTank(obj, tank)
            tf = false;
        end
        
        function tf = usesEngineToTankConn(obj, engineToTank)
            tf = false;
        end
        
        function tf = usesStopwatch(obj, stopwatch)
            tf = false;
        end
        
        function tf = usesExtremum(obj, extremum)
            tf = [obj.extremum] == extremum;
        end
        
        function tf = usesTankToTankConn(obj, tankToTank)
            tf = false;
        end
        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)
%             addActionTf = lvd_EditActionResetExtremumValueGUI(action, lv);
            
            output = AppDesignerGUIOutput({false});
            lvd_EditActionResetExtremumValueGUI_App(action, lv, output);
            addActionTf = output.output{1};
        end
    end
end