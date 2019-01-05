function dydt = odefun(t,y, obj, eventInitStateLogEntry, dryMass, fmEnums)
    bodyInfo = eventInitStateLogEntry.centralBody;
    [ut, rVect, vVect, tankStatesMasses] = LaunchVehicleSimulationDriver.decomposeIntegratorTandY(t,y);
    tankStates = eventInitStateLogEntry.getAllActiveTankStates();
    stageStates = eventInitStateLogEntry.stageStates;
    lvState = eventInitStateLogEntry.lvState;

    altitude = norm(rVect) - bodyInfo.radius;
    if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
        rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
        rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
        vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
    end
    
    throttleModel = eventInitStateLogEntry.throttleModel;
    steeringModel = eventInitStateLogEntry.steeringModel;
    
    throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);

    pressure = getPressureAtAltitude(bodyInfo, altitude);            

    holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

    dydt = zeros(length(y),1);
    if(holdDownEnabled)
        %launch clamp is enabled, only motion is circular motion
        %(fixed to body)
        tankMassDots = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);
        
        bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
        spinVect = [0;0;bodySpinRate];
        rotAccel = crossARH(spinVect,crossARH(spinVect,rVect));

        [rVectECEF] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo);
        vVectECEF = [0;0;0];
        [~, vVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF);

        dydt(1:3) = vVectECI(:); 
        dydt(4:6) = rotAccel(:);
        dydt(7:end) = tankMassDots;
    else
        %launch clamp disabled, propagate like normal
%                 CdA = eventInitStateLogEntry.aero.area * eventInitStateLogEntry.aero.Cd;  
        aero = eventInitStateLogEntry.aero;

        totalMass = dryMass + sum(tankStatesMasses);

        tankStates = tankStates.copy();
        tmCellArr = num2cell(tankStatesMasses);
        [tankStates.tankMass] = tmCellArr{:};

        if(totalMass > 0)
            [forceSum, tankMassDots] = obj.forceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses);
            accelVect = forceSum/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt, but since the thrust force causes us to shed mass, we actually account for the v*dm/dt term there and therefore don't need it!  See: https://en.wikipedia.org/wiki/Variable-mass_system         
            dydt(7:end) = tankMassDots;
        else
            accelVect = zeros(3,1);
            dydt(7:end) = zeros(size(tankStates));
        end

        dydt(1:3) = vVect'; 
        dydt(4:6) = accelVect;
    end
end
