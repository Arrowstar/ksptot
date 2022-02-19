classdef SetKinematicStateEPSinkState < matlab.mixin.SetGet
    %SetKinematicStateEPSinkState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sink AbstractLaunchVehicleElectricalPowerSrcSnk
        
        sinkStateToSet(1,1) logical = true;
        
        inheritSinkState(1,1) logical = true;
        inheritSinkStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritSinkStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);        
    end
    
    methods
        function obj = SetKinematicStateEPSinkState(sink)
            obj.sink = sink;
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            sinkState = obj.getSinkState(newStateLogEntry);
            
            if(obj.inheritSinkState)
                if(obj.inheritSinkStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritSinkStateFromEvent)) && ...
                   not(isempty(obj.inheritSinkStateFromEvent.getEventNum())) && ...
                   obj.inheritSinkStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritSinkStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtSinkState = obj.getSinkState(evtStateLog);
                        sinkState.setActiveState(evtSinkState.getActiveState());
                    end
                end
            else
                sinkState.setActiveState(obj.sinkStateToSet);
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).sink.getName(); %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function sinkState = getSinkState(obj, stateLogEntry)
            sinkStates = stateLogEntry.getAllPwrSinksStates();
            sinkState = sinkStates(getEpsSinkComponent(sinkStates) == obj.sink);
        end
    end
end