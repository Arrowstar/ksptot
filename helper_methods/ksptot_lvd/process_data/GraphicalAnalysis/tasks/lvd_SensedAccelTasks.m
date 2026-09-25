function datapt = lvd_SensedAccelTasks(stateLogEntry, subTask)
%lvd_SensedAccelTasks Sensed (non-gravitational) acceleration in g.
%   Sums thrust, drag and lift force vectors in the central-body inertial
%   frame and divides by the current total vehicle mass:
%       a = (F_thrust + F_drag + F_lift) / m
%   'totalAccel' reports norm(a); 'axialAccel' the projection onto the
%   vehicle body +X axis (the thrust axis); 'normalAccel' the magnitude of
%   the remainder.  Units are g (9.80665 m/s^2).  Coast arcs report 0.
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
    end

    aVectG = lvd_getSensedAccelVectG(stateLogEntry);

    attState = stateLogEntry.attitude;
    bodyXHat = attState.bodyX(:) / norm(attState.bodyX(:));

    switch subTask
        case 'totalAccel'
            datapt = norm(aVectG);
        case 'axialAccel'
            datapt = dot(aVectG, bodyXHat);
        case 'normalAccel'
            axial = dot(aVectG, bodyXHat);
            datapt = norm(aVectG - axial*bodyXHat);
        otherwise
            error('Unrecognized sensed acceleration sub-task: %s', subTask);
    end
end

function aVectG = lvd_getSensedAccelVectG(stateLogEntry)
%lvd_getSensedAccelVectG Sensed acceleration vector in g, body-centered
%inertial frame.  All three force models below return mT*km/s^2 and the
%vehicle mass is in mT, so the quotient is km/s^2 (x1000 / g0 -> g).
    mass = stateLogEntry.getTotalVehicleMass();

    if(mass <= 0)
        aVectG = [0;0;0];
        return;
    end

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position(:);
    vVect = stateLogEntry.velocity(:);
    bodyInfo = stateLogEntry.centralBody;
    aero = stateLogEntry.aero;

    attState = stateLogEntry.attitude;

    tankStates = stateLogEntry.getAllActiveTankStates();
    stageStates = stateLogEntry.stageStates;
    lvState = stateLogEntry.lvState;
    dryMass = stateLogEntry.getTotalVehicleDryMass();

    if(isempty(tankStates))
        tankStatesMasses = zeros(0,1);
    else
        tankStatesMasses = [tankStates.tankMass]';
    end

    throttleModel = stateLogEntry.throttleModel;
    steeringModel = stateLogEntry.steeringModel;

    powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
    storageSoCs = NaN(size(powerStorageStates));
    for(i=1:length(powerStorageStates)) %#ok<NO4LP>
        storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
    end

    altitude = norm(rVect) - bodyInfo.radius;
    pressure = getPressureAtAltitude(bodyInfo, altitude);
    throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

    [~, ~, thrustForceVect] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attState);

    dragForceModel = DragForceModel();
    [dragForceVect, ~, ~] = dragForceModel.getForce(ut, rVect, vVect, mass, bodyInfo, aero, [], [], [], [], [], [], [], [], [], [], attState, []);

    liftForceModel = LiftForceModel();
    [liftForceVect, ~, ~] = liftForceModel.getForce(ut, rVect, vVect, mass, bodyInfo, aero, [], [], [], [], [], [], [], [], [], [], attState, []);

    totalForceVect = thrustForceVect(:) + dragForceVect(:) + liftForceVect(:); %mT*km/s^2
    aVectKmS2 = totalForceVect / mass; %km/s^2
    aVectG = aVectKmS2 * 1000 / getG0(); %g
end
