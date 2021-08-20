classdef SetKinematicStateEPStorageState < matlab.mixin.SetGet
    %SetKinematicStateEPStorageState Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        storage AbstractLaunchVehicleElectricalPowerStorage
        
        storageStateToSet(1,1) logical = true;
        socToSet(1,1) double = 0;
        
        inheritStorageState(1,1) logical = true;
        inheritStorageStateFrom(1,1) InheritStateEnum = InheritStateEnum.InheritFromLastState;
        inheritStorageStateFromEvent LaunchVehicleEvent = LaunchVehicleEvent.empty(1,0);
        
        optVar SetKinematicStateEpsStorageStateOptimVar
    end
    
    methods
        function obj = SetKinematicStateEPStorageState(storage)
            obj.storage = storage;
            
            obj.optVar = SetKinematicStateEpsStorageStateOptimVar(obj);
        end
        
        function updateStateLogEntry(obj, newStateLogEntry, stateLog)
            storageState = obj.getStorageState(newStateLogEntry);
            
            if(obj.inheritStorageState)
                if(obj.inheritStorageStateFrom == InheritStateEnum.InheritFromSpecifiedEvent && ...
                   not(isempty(obj.inheritStorageStateFromEvent)) && ...
                   not(isempty(obj.inheritStorageStateFromEvent.getEventNum())) && ...
                   obj.inheritStorageStateFromEvent.getEventNum() > 0)
               
                    evtStateLog = stateLog.getLastStateLogForEvent(obj.inheritStorageStateFromEvent);
                    if(not(isempty(evtStateLog)))
                        evtStorageState = obj.getStorageState(evtStateLog);
                        storageState.setActiveState(evtStorageState.getActiveState());
                        storageState.setStateOfCharge(evtStorageState.stateOfCharge);
                    end
                end
            else
                storageState.setActiveState(obj.storageStateToSet);
                storageState.setStateOfCharge(obj.socToSet);
            end
        end
        
        function listboxStr = getListboxStr(obj)
            listboxStr = {};
            for(i=1:length(obj))
                listboxStr{i} = obj(i).storage.getName(); %#ok<AGROW>
            end
        end
    end
    
    methods(Access=private)
        function storageState = getStorageState(obj, stateLogEntry)
            storageStates = stateLogEntry.getAllPwrStorageStates();
            storageState = storageStates(getEpsStorageComponent(storageStates) == obj.storage);
        end
    end
end