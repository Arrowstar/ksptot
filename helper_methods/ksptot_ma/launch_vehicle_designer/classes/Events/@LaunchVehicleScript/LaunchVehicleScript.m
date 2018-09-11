classdef LaunchVehicleScript < matlab.mixin.SetGet
    %LaunchVehicleScript Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        evts(1,:) LaunchVehicleEvent
    end
    
    methods
        function obj = LaunchVehicleScript()

        end
        
        function addEvent(obj, newEvt)
            obj.evts(end+1) = newEvt;
        end
        
        function removeEvent(obj, evt)
            obj.evts(obj.evts == evt) = [];
        end
        
        function evtNum = getNumOfEvent(obj, evt)
            evtNum = find(obj.evts == evt);
        end
        
        function stateLog = executeScript(obj, initStateLogEntry, simDriver, stateLog)
            stateLog.clearStateLog();
            
            for(i=1:length(obj.evts)) %#ok<*NO4LP>
                obj.evts(i).initEvent(initStateLogEntry);
                initStateLogEntry.event = obj.evts(i);
                
                newStateLogEntries = obj.evts(i).executeEvent(initStateLogEntry, simDriver);
                stateLog.appendStateLogEntries(newStateLogEntries);
                
                initStateLogEntry = newStateLogEntries(end).deepCopy();
            end
        end
    end
end