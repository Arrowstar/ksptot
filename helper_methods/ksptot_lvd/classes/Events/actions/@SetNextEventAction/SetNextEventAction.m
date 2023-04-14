classdef SetNextEventAction < AbstractEventAction
    %SetNextEventAction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nextEvent LaunchVehicleEvent
    end
    
    methods
        function obj = SetNextEventAction(nextEvent)
            if(nargin > 0)
                obj.nextEvent = nextEvent;
            end
            
            obj.id = rand();
        end
        
        function newStateLogEntry = executeAction(obj, stateLogEntry)
            arguments
                obj(1,1) SetNextEventAction
                stateLogEntry(1,1) LaunchVehicleStateLogEntry
            end

            newStateLogEntry = stateLogEntry;

            obj.nextEvent.script.nextEventToRun = obj.nextEvent;
        end
        
        function initAction(obj, initialStateLogEntry)
            %nothing
        end
        
        function name = getName(obj)            
            name = sprintf('Set Next Event (%s)', obj.nextEvent.getListboxStr());
        end
                        
        function [tf, vars] = hasActiveOptimVar(obj)
            tf = false;
            vars = AbstractOptimizationVariable.empty(0,1);
        end
    end
    
    methods(Static)
        function addActionTf = openEditActionUI(action, lv)      
            arguments
                action(1,1) SetNextEventAction
                lv(1,1) LaunchVehicle
            end

            output = AppDesignerGUIOutput({false});
            lvd_EditActionSetNextEventActionGUI_App(action, lv.lvdData, output);
            addActionTf = output.output{1};
        end
    end
end