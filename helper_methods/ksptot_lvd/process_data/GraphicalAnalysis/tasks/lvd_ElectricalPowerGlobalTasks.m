function [datapt, unitStr] = lvd_ElectricalPowerGlobalTasks(stateLogEntry, subTask)
%lvd_ElectricalPowerSrcTasks Summary of this function goes here
%   Detailed explanation goes here

       
    switch subTask
        case 'netChargeRate'       
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = [];
            for(i=1:length(powerStorageStates))
                storageSoCs(end+1) = powerStorageStates(i).getStateOfCharge(); %#ok<AGROW>
            end
            
            stgStates = stateLogEntry.stageStates;
            
            elemSet = stateLogEntry.getCartesianElementSetRepresentation();
            ut = elemSet.time;
            rVect = elemSet.rVect(:);
            vVect = elemSet.vVect(:);
            bodyInfo = elemSet.frame.getOriginBody();
            
            steeringModel = stateLogEntry.steeringModel;
            
            storageRates = LaunchVehicleStateLogEntry.getStorageChargeRatesDueToSourcesSinks(storageSoCs, powerStorageStates, stgStates, ut, rVect, vVect, bodyInfo, steeringModel);
            
            datapt = sum(storageRates);
            unitStr = 'EC/s';
            
        case 'cumStorageSoC'
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = [];
            for(i=1:length(powerStorageStates))
                storageSoCs(end+1) = powerStorageStates(i).getStateOfCharge(); %#ok<AGROW>
            end
            
            datapt = sum(storageSoCs);
            unitStr = 'EC';
            
        case 'maxAvailableStorage'
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            maxAvailStorage = [];
            for(i=1:length(powerStorageStates))
                maxAvailStorage(end+1) = powerStorageStates(i).getEpsStorageComponent().getMaximumCapacity(); %#ok<AGROW>
            end
            
            datapt = sum(maxAvailStorage);
            unitStr = 'EC';
            
        otherwise
            error('Unknow EPS sink task: %s', subTask);            
    end
end