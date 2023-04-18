function datapt = lvd_ThrottleTask(stateLogEntry, subTask, inFrame)
%lvd_ThrottleTask Summary of this function goes here
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
            
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = NaN(size(powerStorageStates));
            for(i=1:length(powerStorageStates))
                storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
            end
            
            datapt = computeTWRatio(throttle, stateLogEntry.time, stateLogEntry.position, stateLogEntry.velocity, tankMasses, stateLogEntry.getTotalVehicleDryMass(), ...
                                    stateLogEntry.stageStates, stateLogEntry.lvState, tankStates, stateLogEntry.centralBody, storageSoCs, powerStorageStates);
        case 'totalthrust'
            [totalThrust] = getThrustParameters(stateLogEntry);
            datapt = totalThrust;
            
        case 'thrust_x'
            vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();
            [~, ~, ~, rotMat] = inFrame.getOffsetsWrtInertialOrigin(stateLogEntry.time, vehElemSet);
            
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            thrustForceVector = thrustForceVector(:);
            thrustForceVector = rotMat * thrustForceVector;
            
            datapt = thrustForceVector(1);
            if(isnan(datapt))
                datapt = 0;
            end
            
        case 'thrust_y'
            vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();
            [~, ~, ~, rotMat] = inFrame.getOffsetsWrtInertialOrigin(stateLogEntry.time, vehElemSet);
            
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            thrustForceVector = thrustForceVector(:);
            thrustForceVector = rotMat * thrustForceVector;
            
            datapt = thrustForceVector(2);
            if(isnan(datapt))
                datapt = 0;
            end
            
        case 'thrust_z'
            vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();
            [~, ~, ~, rotMat] = inFrame.getOffsetsWrtInertialOrigin(stateLogEntry.time, vehElemSet);
            
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            thrustForceVector = thrustForceVector(:);
            thrustForceVector = rotMat * thrustForceVector;
            
            datapt = thrustForceVector(3);
            if(isnan(datapt))
                datapt = 0;
            end

        case 'thrust_vector'
            [~, thrustForceVector] = getThrustParameters(stateLogEntry);
            
            datapt = thrustForceVector(:);
            if(any(isnan(datapt)))
                datapt = [0;0;0];
            end
            
        otherwise
            error('Unrecongized task: %s', subTask);
            
    end
end

function [totalThrust, thrustForceVector] = getThrustParameters(stateLogEntry)    
    if(not(isempty(stateLogEntry.event)) && stateLogEntry.event.propagatorObj.canProduceThrust())
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

        powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
        storageSoCs = NaN(size(powerStorageStates));
        for(i=1:length(powerStorageStates)) %#ok<*NO4LP> 
            storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
        end

        attState = LaunchVehicleAttitudeState();
        attState.dcm = steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);
        
        throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

        [~, totalThrust, thrustForceVector] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attState);
        thrustForceVector = 1000*thrustForceVector; %in order to recover kN
    else
        totalThrust = 0;
        thrustForceVector = [0;0;0];
    end
end