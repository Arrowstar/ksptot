function incr = lvd_deltaVSegmentIncrement(e1, e2)
%lvd_deltaVSegmentIncrement Delta-V contributed going from e1 to e2 (km/s).
%   One segment of lvd_CumulativeDeltaVTasks, exposed so callers holding a
%   lone entry (lvd_cumulativeDeltaVAtEntry) can add their own last segment
%   without routing a still-mutable entry through that function's memo.
    incr = 0;

    dt = e2.time - e1.time;

    if(abs(dt) <= 1e-9)
        %same-time pair: impulsive action entry (AddDeltaVAction changes
        %velocity at fixed time; other actions leave velocity alone)
        dv = e2.velocity(:) - e1.velocity(:);
        if(all(isfinite(dv)))
            incr = norm(dv);
        end
        return;
    end

    if(dt < 0)
        return; %backward propagation: not counted
    end

    %forward propagation step: finite-burn increment from the mass ratio,
    %mirroring EventDeltaVExpendedConstraint.computeTotalDeltaV.  A dry-mass
    %change means staging happened between the entries, not propulsion.
    if(e1.getTotalVehicleDryMass() ~= e2.getTotalVehicleDryMass())
        return;
    end

    ut = e1.time;
    rVect = e1.position;
    vVect = e1.velocity;

    bodyInfo = e1.centralBody;
    tankStates = e1.getAllActiveTankStates();
    stageStates = e1.stageStates;
    lvState = e1.lvState;

    dryMass = e1.getTotalVehicleDryMass();
    if(isempty(tankStates))
        tankStatesMasses = zeros(0,1);
    else
        tankStatesMasses = [tankStates.tankMass]';
    end

    throttleModel = e1.throttleModel;
    steeringModel = e1.steeringModel;
    attitude = e1.attitude;

    altitude = norm(rVect) - bodyInfo.radius;
    pressure = getPressureAtAltitude(bodyInfo, altitude);

    powerStorageStates = e1.getAllActivePwrStorageStates();
    storageSoCs = NaN(size(powerStorageStates));
    for(j=1:length(powerStorageStates)) %#ok<NO4LP>
        storageSoCs(j) = powerStorageStates(j).getStateOfCharge();
    end

    throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

    [tankMDots, totalThrust, ~] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, attitude);

    if(abs(sum(tankMDots)) > 0)
        totalMDotKgS = sum(tankMDots) * 1000; %negative (outflow)
        totalThrustN = totalThrust * 1000;
        effIsp = totalThrustN / (getG0() * abs(totalMDotKgS)); %sec

        totalMass1 = dryMass + e1.getTotalVehiclePropMass();
        totalMass2 = dryMass + e2.getTotalVehiclePropMass();

        if(totalMass1 > totalMass2)
            incr = (getG0() * effIsp * log(totalMass1 / totalMass2))/1000; %km/s
        end
    end
end
