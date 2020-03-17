function dydt = odefun(t,y, simDriver, eventInitStateLogEntry, tankStates, dryMass, fmEnums)
    bodyInfo = eventInitStateLogEntry.centralBody;
    [ut, rVect, vVect, tankStatesMasses] = AbstractODE.decomposeIntegratorTandY(t,y);
    altitude = norm(rVect) - bodyInfo.radius;
    
    stageStates = eventInitStateLogEntry.stageStates;
    lvState = eventInitStateLogEntry.lvState;
    t2tConnStates = lvState.t2TConns;
       
    throttleModel = eventInitStateLogEntry.throttleModel;
    steeringModel = eventInitStateLogEntry.steeringModel;
    
    holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

    tankMassDotsT2TConns = TankToTankConnection.getTankMassFlowRatesFromTankToTankConnections(tankStates, tankStatesMasses, t2tConnStates);
    
    dydt = zeros(length(y),1);
    if(holdDownEnabled)
        pressure = getPressureAtAltitude(bodyInfo, altitude);
        throttle = throttleModel.getThrottleAtTime(ut, rVect, vVect, tankStatesMasses, dryMass, stageStates, lvState, tankStates, bodyInfo);
        
        tankMassDotsEngines = eventInitStateLogEntry.getTankMassFlowRatesDueToEngines(tankStates, tankStatesMasses, stageStates, throttle, lvState, pressure, ut, rVect, vVect, bodyInfo, steeringModel);
        
        tankMassDots = tankMassDotsEngines + tankMassDotsT2TConns;
        
        %launch clamp is enabled, only motion is circular motion
        %(fixed to body)
        %In this case, we are integrating in the body-fixed frame, 
        %so all rates are effectively zero
% % % % % %         bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
% % % % % %         spinVect = [0;0;bodySpinRate];
% % % % % %         rotAccel = crossARH(spinVect,crossARH(spinVect,rVect));
% % % % % % 
% % % % % %         [rVectECEF] = getFixedFrameVectFromInertialVect(ut, rVect, bodyInfo);
% % % % % %         vVectECEF = [0;0;0];
% % % % % %         [~, vVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF);
% % % % % % 
% % % % % %         dydt(1:3) = vVectECI(:); 
% % % % % %         dydt(4:6) = rotAccel(:);
        
        dydt(1:3) = [0;0;0]; 
        dydt(4:6) = [0;0;0];
        dydt(7:end) = tankMassDots;
    else
        %launch clamp disabled, propagate like normal
        if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
            rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
            rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
            vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
        end
        
        aero = eventInitStateLogEntry.aero;
        thirdBodyGravity = eventInitStateLogEntry.thirdBodyGravity;
        
        totalMass = dryMass + sum(tankStatesMasses);

        if(totalMass > 0)
            [forceSum, tankMassDotsForceModels] = simDriver.forceModel.getForce(fmEnums, ut, rVect, vVect, totalMass, bodyInfo, aero, throttleModel, steeringModel, tankStates, stageStates, lvState, dryMass, tankStatesMasses, thirdBodyGravity);
            accelVect = forceSum/totalMass; %F = dp/dt = d(mv)/dt = m*dv/dt + v*dm/dt, but since the thrust force causes us to shed mass, we actually account for the v*dm/dt term there and therefore don't need it!  See: https://en.wikipedia.org/wiki/Variable-mass_system         
            
            tankMassDots = tankMassDotsForceModels + tankMassDotsT2TConns;
            
            dydt(7:end) = tankMassDots;
        else
            accelVect = zeros(3,1);
            dydt(7:end) = zeros(size(tankStates));
        end

        dydt(1:3) = vVect'; 
        dydt(4:6) = accelVect;
    end
end
