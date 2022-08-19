function [datapt, unitStr] = lvd_ElectricalPowerStorageTasks(stateLogEntry, subTask, pwrStorage)
%lvd_ElectricalPowerStorageTasks Summary of this function goes here
%   Detailed explanation goes here

    stageStates = stateLogEntry.stageStates;

    pwrStorageStates = AbstractLaunchVehicleEpsStorageState.empty(1,0);
    for(i=1:length(stageStates)) %#ok<*NO4LP>
        pwrStorageStates = horzcat(pwrStorageStates, stageStates(i).powerStorageStates); %#ok<AGROW>
    end
    
    pwrStorages = AbstractLaunchVehicleElectricalPowerStorage.empty(1,0);
    for(i=1:length(pwrStorageStates))
        pwrStorages = horzcat(pwrStorages, pwrStorageStates(i).getEpsStorageComponent()); %#ok<AGROW>
    end
    
    pwrStorageInd = find(pwrStorages == pwrStorage,1,'first');
    pwrStorageState = pwrStorageStates(pwrStorageInd);
    
    switch subTask
        case 'active'           
            if(not(isempty(pwrStorageState)))
                pwrStorageState = pwrStorageState(1);
                datapt = pwrStorageState.getActiveState();
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = '';
            else
                datapt = -1;
                unitStr = '';
            end
            
        case 'stateOfCharge'
            if(not(isempty(pwrStorageState)))
                pwrStorageState = pwrStorageState(1);
                datapt = pwrStorageState.getStateOfCharge();
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = 'EC';
            else
                datapt = -1;
                unitStr = 'EC';
            end
            
        otherwise
            error('Unknow EPS storage task: %s', subTask);            
    end
end