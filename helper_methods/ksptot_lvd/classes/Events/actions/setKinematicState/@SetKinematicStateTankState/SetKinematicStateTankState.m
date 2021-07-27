classdef SetKinematicStateTankState < matlab.mixin.SetGet
    %SetKinematicStateTankState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        tank LaunchVehicleTank
        
        tankStateMassToSet(1,1) double = 0;
        
        inheritTankState(1,1) logical = true;
        inheritTankStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritTankStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0); 
        
        optVar SetKinematicStateTankStateOptimVar
    end
    
    methods
        function obj = SetKinematicStateTankState(tank)
            obj.tank = tank;
            
            obj.optVar = SetKinematicStateTankStateOptimVar(obj);
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            tankState = obj.getTankState(newStateLogEntry);
            
            if(obj.inheritTankState)
                if(obj.inheritTankStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritTankStateFromEvent)) && ...
                   not(isempty(obj.inheritTankStateFromEvent.getEventNum())) && ...
                   obj.inheritTankStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritTankStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtTankState = obj.getTankState(evtStateLog);
                        tankState.tankMass = evtTankState.tankMass;
                    end
                end
            else
                tankState.tankMass = obj.tankStateMassToSet;
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).tank.name; %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function tankState = getTankState(obj, stateLogEntry)
            tankStates = stateLogEntry.getAllTankStates();
            tankState = tankStates([tankStates.tank] == obj.tank);
        end
    end
end