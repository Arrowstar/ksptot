function [depVarValue, depVarUnit] = lvd_CumulativeDeltaVTasks(entryInd, subLog)
%lvd_CumulativeDeltaVTasks Cumulative finite-burn + impulsive Delta-V in km/s.
%   Integrates propulsive Delta-V from subLog(1) up to subLog(entryInd):
%     * forward propagation steps (dt > 0) contribute the finite-burn
%       increment g0*Isp*ln(m1/m2), exactly the per-segment computation in
%       EventDeltaVExpendedConstraint (same throttle, pressure and
%       mass-flow evaluation);
%     * same-time steps (dt == 0, produced by AddDeltaVAction entries)
%       contribute norm(v2 - v1), i.e. the impulsive magnitude (0 when the
%       action did not change velocity, e.g. staging or engine toggles).
%   Per the F2 decision this includes impulsive Delta-V.  Per-event or
%   per-stage splits are intentionally NOT separate tasks: use a
%   GenericMAConstraint on this quantity with StateComparison mode.
%
%   Sequential-access memo: GraphicalAnalysis loops call with increasing
%   entryInd on the same array, so each call costs one segment.  Random
%   access (constraints) recomputes the prefix.  Backward propagation is
%   not counted (finite segments require increasing time, as in
%   EventDeltaVExpendedConstraint); non-sequential-event impulses that do
%   not produce same-time log entries are not counted either.
    arguments
        entryInd(1,1) double
        subLog(1,:) LaunchVehicleStateLogEntry
    end

    persistent cachedEntries cachedCum

    depVarUnit = 'km/s';

    if(entryInd < 1 || entryInd > numel(subLog))
        depVarValue = 0;
        return;
    end

    useCache = not(isempty(cachedEntries)) && numel(cachedEntries) <= numel(subLog);
    if(useCache)
        nCached = numel(cachedEntries);
        try
            useCache = all(cachedEntries == subLog(1:nCached));
        catch
            useCache = false;
        end
    end

    if(useCache && entryInd <= numel(cachedCum))
        depVarValue = cachedCum(entryInd);
        return;
    end

    if(useCache)
        startK = numel(cachedCum) + 1;
        cumVals = cachedCum;
    else
        startK = 2;
        cumVals = zeros(1, entryInd);
        cumVals(1) = 0;
    end

    if(numel(cumVals) < entryInd)
        cumVals(entryInd) = 0;
    end

    for(k=max(startK,2):entryInd) %#ok<NO4LP>
        cumVals(k) = cumVals(k-1) + lvd_deltaVSegmentIncrement(subLog(k-1), subLog(k));
    end

    cachedEntries = subLog(1:entryInd);
    cachedCum = cumVals(1:entryInd);

    depVarValue = cumVals(entryInd);
end

function incr = lvd_deltaVSegmentIncrement(e1, e2)
%lvd_deltaVSegmentIncrement Delta-V contributed going from e1 to e2 (km/s).
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
