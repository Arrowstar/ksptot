classdef SetKinematicStateEngineState < matlab.mixin.SetGet
    %SetKinematicStateEngineState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        engine LaunchVehicleEngine
        
        engineStateToSet(1,1) logical = true;
        
        inheritEngineState(1,1) logical = true;
        inheritEngineStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritEngineStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);        
    end
    
    methods
        function obj = SetKinematicStateEngineState(engine)
            obj.engine = engine;
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            engineState = obj.getEngineState(newStateLogEntry);
            
            if(obj.inheritEngineState)
                if(obj.inheritEngineStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritEngineStateFromEvent)) && ...
                   not(isempty(obj.inheritEngineStateFromEvent.getEventNum())) && ...
                   obj.inheritEngineStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritEngineStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtEngineState = obj.getEngineState(evtStateLog);
                        engineState.active = evtEngineState.active;
                    end
                end
            else
                engineState.active = obj.engineStateToSet;
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).engine.name; %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function engineState = getEngineState(obj, stateLogEntry)
            engineStates = stateLogEntry.getAllEngineStates();
            engineState = engineStates([engineStates.engine] == obj.engine);
        end
    end
end