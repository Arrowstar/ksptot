function [datapt, unitStr] = lvd_ElectricalPowerStorageTasks(stateLogEntry, subTask, powerStorage)
%lvd_ElectricalPowerStorageTasks Summary of this function goes here
%   Detailed explanation goes here

    pwrStorageStates = stateLogEntry.getAllActivePwrStorageStates();
    pwrStorageState = pwrStorageStates([pwrStorageStates.getEpsStorageComponent()] == powerStorage);
    
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