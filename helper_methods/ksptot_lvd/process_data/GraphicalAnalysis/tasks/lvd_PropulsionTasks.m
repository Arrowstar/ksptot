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
    end
end