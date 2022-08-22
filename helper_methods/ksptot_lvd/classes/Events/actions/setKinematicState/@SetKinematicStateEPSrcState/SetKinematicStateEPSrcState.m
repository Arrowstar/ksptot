classdef SetKinematicStateEPSrcState < matlab.mixin.SetGet
    %SetKinematicStateEPSrcState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        src AbstractLaunchVehicleElectricalPowerSrcSnk
        
        srcStateToSet(1,1) logical = true;
        
        inheritSrcState(1,1) logical = true;
        inheritSrcStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritSrcStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);        
    end
    
    methods
        function obj = SetKinematicStateEPSrcState(src)
            obj.src = src;
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            srcState = obj.getSrcState(newStateLogEntry);
            
            if(obj.inheritSrcState)
                if(obj.inheritSrcStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritSrcStateFromEvent)) && ...
                   not(isempty(obj.inheritSrcStateFromEvent.getEventNum())) && ...
                   obj.inheritSrcStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritSrcStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtSrcState = obj.getSrcState(evtStateLog);
                        srcState.setActiveState(evtSrcState.getActiveState());
                    end
                end
            else
                srcState.setActiveState(obj.srcStateToSet);
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).src.getName(); %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function srcState = getSrcState(obj, stateLogEntry)
            srcStates = stateLogEntry.getAllPwrSrcsStates();
            srcState = srcStates(getEpsSrcComponent(srcStates) == obj.src);
        end
    end
end