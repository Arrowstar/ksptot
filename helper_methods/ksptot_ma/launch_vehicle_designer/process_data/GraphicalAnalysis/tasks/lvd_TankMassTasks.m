function datapt = lvd_TankMassTasks(stateLogEntry, subTask, tank)
%lvd_TankMassTasks Summary of this function goes here
%   Detailed explanation goes here
    datapt = -1;

    switch subTask
        case 'tankMass'
            tankStates = stateLogEntry.getAllTankStates();
            tankState = tankStates([tankStates.tank] == tank);
            
            if(not(isempty(tankState)))
                tankState = tankState(1);
                datapt = tankState.tankMass;
            else
                datapt = -1;
            end
            
        case 'tankMDot'
            bodyInfo = stateLogEntry.centralBody;
            
            [~,y, tankStateInds] = stateLogEntry.getFirstOrderIntegratorStateRepresentation();
            ut = stateLogEntry.time;
            rVect = stateLogEntry.position;
            vVect = stateLogEntry.velocity;
            tankStatesMasses = y(tankStateInds);
            
            tankStates = stateLogEntry.getAllActiveTankStates();
            stageStates = stateLogEntry.stageStates;
            lvState = stateLogEntry.lvState;

            altitude = norm(rVect) - bodyInfo.radius;

            throttleModel = stateLogEntry.throttleModel;
            steeringModel = stateLogEntry.steeringModel;

            dryMass = stateLogEntry.getTotalVehicleDryMass();
            
            throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);
            presskPa = getPressureAtAltitude(bodyInfo, altitude); 
            
            [tankMDots] = LaunchVehicleStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, presskPa, ut, rVect, vVect, bodyInfo, steeringModel);
            
            bool = [tankStates.tank] == tank;
            if(any(bool))
                datapt = tankMDots(bool);
            else
                datapt = 0;
            end
            
    end
end