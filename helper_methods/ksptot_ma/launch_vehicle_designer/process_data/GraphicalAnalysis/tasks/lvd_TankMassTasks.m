function datapt = lvd_TankMassTasks(stateLogEntry, subTask, tank)
%lvd_TankMassTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'tankMass'
            tankStates = stateLogEntry.getAllTankStates();
            tankState = tankStates([tankStates.tank] == tank);
            
            if(not(isempty(tankState)))
                tankState = tankState(1);
                datapt = tankState.tankMass;
            else
                datapt = -1;
            end
    end
end