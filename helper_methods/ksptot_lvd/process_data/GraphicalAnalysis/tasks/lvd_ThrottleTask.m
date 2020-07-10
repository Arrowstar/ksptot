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
            [totalThrust] = getThrustParameters(stateLogEntry);
            datapt = totalThrust;
            
        case 'thrust_x'
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            datapt = thrustForceVector(1);
            if(isnan(datapt))
                datapt = 0;
            end
            
        case 'thrust_y'
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            datapt = thrustForceVector(2);
            if(isnan(datapt))
                datapt = 0;
            end
            
        case 'thrust_z'
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            datapt = thrustForceVector(3);
            if(isnan(datapt))
                datapt = 0;
            end
            
        otherwise
            error('Unrecongized task: %s', subTask);
            
    end
end

function [totalThrust, thrustForceVector] = getThrustParameters(stateLogEntry)    
    if(stateLogEntry.event.propagatorObj.canProduceThrust())
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

        [~, totalThrust, thrustForceVector] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);
        thrustForceVector = 1000*thrustForceVector; %in order to recover kN
    else
        totalThrust = 0;
        thrustForceVector = [0;0;0];
    end
end