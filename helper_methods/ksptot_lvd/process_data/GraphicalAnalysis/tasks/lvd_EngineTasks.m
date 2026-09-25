function [datapt, depVarUnit] = lvd_EngineTasks(stateLogEntry, subTask, engine)
%lvd_EngineTasks Summary of this function goes here
%   Detailed explanation goes here
%   Per-engine thrust (kN) and mass flow rate (mT/s, negative when burning,
%   matching the tank mass-flow sign convention) are zero when the engine
%   is off (inactive engine or stage, empty connected tanks, no EC for
%   EC-dependent engines, or zero adjusted throttle).  Isp (s) is the
%   pressure-curve capability and is reported even when the engine is off.
%   Like T/W (and unlike Total Thrust), these are pure functions of the
%   logged state: no propagator thrust-capability gate is applied.

    switch subTask
        case 'active'
            engineStates = stateLogEntry.getAllEngineStates();
            engineState = engineStates([engineStates.engine] == engine);

            if(not(isempty(engineState)))
                engineState = engineState(1);
                datapt = double(engineState.active);
            else
                datapt = -1;
            end
            depVarUnit = '';

        case 'thrust'
            [thrust, ~, ~] = lvd_getPerEngineThrustMdotIsp(stateLogEntry, engine);
            datapt = thrust;
            depVarUnit = 'kN';

        case 'isp'
            [~, ~, isp] = lvd_getPerEngineThrustMdotIsp(stateLogEntry, engine);
            datapt = isp;
            depVarUnit = 'sec';

        case 'mdot'
            [~, mdot, ~] = lvd_getPerEngineThrustMdotIsp(stateLogEntry, engine);
            datapt = mdot;
            depVarUnit = 'mT/s';

        otherwise
            error('Unrecognized engine sub-task: %s', subTask);
    end
end

function [thrust, mdot, isp] = lvd_getPerEngineThrustMdotIsp(stateLogEntry, engine)
%lvd_getPerEngineThrustMdotIsp Thrust (kN), mass flow (mT/s) and Isp (s)
%for one engine at the entry's state.  Mirrors the gating in
%LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines: the engine
%must be flagged active in an active stage, at least one connected tank
%must hold propellant, EC-dependent engines need charge, and the throttle
%is adjusted by min/max limits and the fuel-remaining curve.
    thrust = 0;
    mdot = 0;

    bodyInfo = stateLogEntry.centralBody;
    altitude = norm(stateLogEntry.position) - bodyInfo.radius;
    pressure = getPressureAtAltitude(bodyInfo, altitude);

    [~, isp] = engine.getThrustIspForPressure(pressure);

    engineStates = stateLogEntry.getAllEngineStates();
    matches = engineStates([engineStates.engine] == engine);
    if(isempty(matches))
        return;
    end
    engineState = matches(1);

    if(not(engineState.active) || not(engineState.stageState.active))
        return;
    end

    tankStates = stateLogEntry.getAllActiveTankStates();
    if(isempty(tankStates))
        return;
    end
    tankStatesMasses = [tankStates.tankMass]';

    stageStates = stateLogEntry.stageStates;
    lvState = stateLogEntry.lvState;

    powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
    storageSoCs = NaN(size(powerStorageStates));
    for(i=1:length(powerStorageStates)) %#ok<NO4LP>
        storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
    end

    dryMass = stateLogEntry.getTotalVehicleDryMass();
    throttleModel = stateLogEntry.throttleModel;
    throttle = throttleModel.getThrottleAtTime(stateLogEntry.time, stateLogEntry.position, stateLogEntry.velocity, ...
        tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo, storageSoCs, powerStorageStates);

    adjustedThrottle = engine.adjustThrottle(throttle, []);

    if(adjustedThrottle <= 0)
        return;
    end

    engTankInds = lvState.getEngineToTankStateIndices(tankStates, stageStates);

    stgStates = stageStates;
    for(i=1:length(stgStates)) %#ok<NO4LP>
        if(not(stgStates(i).active))
            continue;
        end

        engStates = stgStates(i).engineStates;
        for(j=1:length(engStates))
            if(engStates(j).engine == engine)
                connTankInds = engTankInds{i}{j};

                totalConnTankCapacity = 0;
                totalConnTankMass = 0;
                anyNonEmpty = false;
                for(k=1:length(connTankInds))
                    idx = connTankInds(k);
                    tState = tankStates(idx);
                    if(tState.stageState.active)
                        totalConnTankCapacity = totalConnTankCapacity + tState.tank.getCapacity();
                        totalConnTankMass = totalConnTankMass + tankStatesMasses(idx);
                        if(tankStatesMasses(idx) > 0)
                            anyNonEmpty = true;
                        end
                    end
                end

                if(not(anyNonEmpty))
                    return;
                end

                if(engine.reqsElecCharge && (isempty(storageSoCs) || sum(storageSoCs) <= 0))
                    return;
                end

                if(totalConnTankCapacity > 0 && totalConnTankMass > 0)
                    fuelRemainPct = 100 * totalConnTankMass / totalConnTankCapacity;
                else
                    fuelRemainPct = 0;
                end

                adjustedThrottle = engine.adjustThrottle(throttle, fuelRemainPct);
                if(totalConnTankMass <= 0)
                    adjustedThrottle = 0;
                end

                if(adjustedThrottle <= 0)
                    return;
                end

                [baseThrust, baseMdot] = engine.getThrustFlowRateForPressure(pressure);
                thrust = adjustedThrottle * baseThrust;
                mdot = adjustedThrottle * baseMdot;
                return;
            end
        end
    end
end
