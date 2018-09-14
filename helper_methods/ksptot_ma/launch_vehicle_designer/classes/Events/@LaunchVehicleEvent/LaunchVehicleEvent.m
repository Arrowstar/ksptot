classdef LaunchVehicleEvent < matlab.mixin.SetGet
    %LaunchVehicleEvent Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        termCond(1,1) AbstractEventTerminationCondition = EventDurationTermCondition(0);
        actions(1,:) AbstractEventAction
        
        name(1,:) char = 'Untitled Event';
        script(1,:) LaunchVehicleScript
    end
    
    methods
        function obj = LaunchVehicleEvent(script)
            obj.script = script;
        end
        
        function addAction(obj, newAction)
            obj.actions(end+1) = newAction;
        end
        
        function removeAction(obj, action)
            obj.actions(obj.actions == action) = [];
        end
        
        function evtNum = getEventNum(obj)
            evtNum = obj.script.getNumOfEvent(obj);
        end
        
        function initEvent(obj, initialStateLogEntry)
            obj.termCond.initTermCondition(initialStateLogEntry);
            
            for(i=1:length(obj.actions)) %#ok<*NO4LP>
                obj.actions(i).initAction(initialStateLogEntry);
            end
        end
        
        function newStateLogEntries = executeEvent(obj, initStateLogEntry, simDriver)
            [~,~,newStateLogEntries] = simDriver.integrateOneEvent(obj, initStateLogEntry);
            
            stateLogEntry = newStateLogEntries(end);
            for(i=1:length(obj.actions))
                newStateLogEntry = obj.actions(i).exectuteAction(stateLogEntry);
                
                newStateLogEntries(end+1) = newStateLogEntry; %#ok<AGROW>
                stateLogEntry = newStateLogEntry;
            end
        end
    end
end

