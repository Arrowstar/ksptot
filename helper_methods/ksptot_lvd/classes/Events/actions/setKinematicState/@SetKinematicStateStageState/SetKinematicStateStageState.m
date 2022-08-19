classdef SetKinematicStateStageState < matlab.mixin.SetGet
    %SetKinematicStateStageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        stage LaunchVehicleStage
        
        stageStateToSet(1,1) logical = true;
        
        inheritStageState(1,1) logical = true;
        inheritStageStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStageStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);        
    end
    
    methods
        function obj = SetKinematicStateStageState(stage)
            obj.stage = stage;
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            stageState = obj.getStageState(newStateLogEntry);
            
            if(obj.inheritStageState)
                if(obj.inheritStageStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritStageStateFromEvent)) && ...
                   not(isempty(obj.inheritStageStateFromEvent.getEventNum())) && ...
                   obj.inheritStageStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritStageStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtStageState = obj.getStageState(evtStateLog);
                        stageState.active = evtStageState.active;
                    end
                end
            else
                stageState.active = obj.stageStateToSet;
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).stage.name; %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function stageState = getStageState(obj, stateLogEntry)
            stageStates = stateLogEntry.stageStates;
            stageState = stageStates([stageStates.stage] == obj.stage);
        end
    end
end