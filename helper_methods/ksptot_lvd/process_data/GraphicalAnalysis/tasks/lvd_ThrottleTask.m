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
        case 'totalthrust'
            ut = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            
            bodyInfo = stateLogEntry.centralBody;
            tankStates = stateLogEntry.getAllActiveTankStates();
            stageStates = stateLogEntry.stageStates;
            lvState = stateLogEntry.lvState;
            
            dryMass = stateLogEntry.getTotalVehicleDryMass();
            tankStatesMasses = [tankStates.tankMass]';
            
            throttleModel = stateLogEntry.throttleModel;
            steeringModel = stateLogEntry.steeringModel;
            
            altitude = norm(rVect) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude); 
            
            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);
            
            [~, totalThrust, ~] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);
            
            datapt = totalThrust;
    end
end