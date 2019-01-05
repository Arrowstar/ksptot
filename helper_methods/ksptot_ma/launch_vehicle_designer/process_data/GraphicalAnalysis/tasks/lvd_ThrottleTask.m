function datapt = lvd_ThrottleTask(stateLogEntry, subTask)
%lvd_SteeringAngleTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'throttle'
            datapt = 100*stateLogEntry.throttle;
            
        case 't2w'
            throttle = stateLogEntry.throttle;
            tankStates = stateLogEntry.getAllActiveTankStates();
            
            tankMasses = zeros(size(tankStates));
            for(i=1:length(tankStates))
                tankMasses(i) = tankStates(i).tankMass;
            end
            
            datapt = computeTWRatio(throttle, stateLogEntry.time, stateLogEntry.position, stateLogEntry.velocity, tankMasses, stateLogEntry.getTotalVehicleDryMass(), ...
                                    stateLogEntry.stageStates, stateLogEntry.lvState, tankStates, stateLogEntry.centralBody);
    end
end