function datapt = lvd_PropulsionTasks(stateLogEntry, subTask)
%lvd_PropulsionTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'totalEffIsp'
            tankStates = stateLogEntry.getAllActiveTankStates();
            tankStatesMasses = [tankStates.tankMass];
            stageStates = stateLogEntry.stageStates;
            lvState = stateLogEntry.lvState;
            ut = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            bodyInfo = stateLogEntry.centralBody;
            steeringModel = stateLogEntry.steeringModel;

            altitude = stateLogEntry.altitude;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            throttle = 1.0;
            
            powerStorageStates = stateLogEntry.getAllActivePwrStorageStates();
            storageSoCs = NaN(size(powerStorageStates));
            for(i=1:length(powerStorageStates))
                storageSoCs(i) = powerStorageStates(i).getStateOfCharge();
            end

            [tankMDots, totalThrust, ~] = stateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel, storageSoCs, powerStorageStates, []);
            
            if(abs(sum(tankMDots)) > 0)
                tankMDotsKgS = tankMDots * 1000;
                totalMDotKgS = sum(tankMDotsKgS);
                totalThrustN = totalThrust * 1000;
                effIsp = totalThrustN / (getG0() * abs(totalMDotKgS)); %sec

                datapt = effIsp;
            else
                datapt = 0;
            end

        case 'remainingDeltaV'
            %Rocket-equation capability of the currently active engines at
            %full throttle: g0*Isp*ln(mWet/mDry).  Uses base (unthrottled)
            %engine performance at the current pressure so the value is
            %stable through coast arcs.  Zero when no engine is flagged
            %active or the vehicle is already dry.
            bodyInfo = stateLogEntry.centralBody;

            altitude = norm(stateLogEntry.position) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);

            [effIsp, anyActive] = lvd_getBaseEffIspForActiveEngines(stateLogEntry, pressure);

            mWet = stateLogEntry.getTotalVehicleMass();
            mDry = stateLogEntry.getTotalVehicleDryMass();

            if(anyActive && effIsp > 0 && mWet > mDry && mDry > 0)
                datapt = (getG0() * effIsp * log(mWet / mDry))/1000; %km/s
            else
                datapt = 0;
            end
    end
end

function [effIsp, anyActive] = lvd_getBaseEffIspForActiveEngines(stateLogEntry, pressure)
%lvd_getBaseEffIspForActiveEngines Thrust-weighted effective Isp of the
%engines flagged active (in active stages) at full throttle and the given
%pressure.  Throttle and fuel-curve scaling are deliberately excluded so
%the remaining-DeltaV capability does not flicker with the throttle.
    engineStates = stateLogEntry.getAllEngineStates();

    totalThrust = 0; %kN
    totalMDot = 0; %mT/s, negative when burning
    anyActive = false;

    for(i=1:length(engineStates)) %#ok<NO4LP>
        engineState = engineStates(i);

        if(engineState.active && engineState.stageState.active)
            anyActive = true;
            engine = engineState.engine;

            [baseThrust, baseMdot] = engine.getThrustFlowRateForPressure(pressure);
            totalThrust = totalThrust + baseThrust;
            totalMDot = totalMDot + baseMdot;
        end
    end

    if(abs(totalMDot) > 0)
        effIsp = (totalThrust*1000) / (getG0() * abs(totalMDot*1000)); %sec
    else
        effIsp = 0;
    end
end