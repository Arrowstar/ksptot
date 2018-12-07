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
            
            datapt = computeTWRatio(throttle, stateLogEntry.position, tankMasses, stateLogEntry.getTotalVehicleDryMass(), ...
                                    stateLogEntry.stageStates, stateLogEntry.lvState, tankStates, stateLogEntry.centralBody);
    end
end

function twRatio = computeTWRatio(throttle, rVect, tankMasses, dryMass, stgStates, lvState, tankStates, bodyInfo)
    altitude = norm(rVect) - bodyInfo.radius;
    presskPa = getPressureAtAltitude(bodyInfo, altitude); 

    [~, totalThrust]= LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankMasses, stgStates, throttle, lvState, presskPa);

    totalMass = (dryMass + sum(tankMasses))*1000; %kg          
    totalThrust = totalThrust * 1000; % N

    twRatio = computeSLThrustToWeight(bodyInfo, totalThrust, totalMass);
end