function ypp = odefun(~,y, ~, eventInitStateLogEntry, ~, totalMass, gravForceModel)
    bodyInfo = eventInitStateLogEntry.centralBody;
    
    rVect = reshape(y,[3,1]);
%     [~, rVect, ~, tankStatesMasses] = AbstractODE.decomposeIntegratorTandY(t,y);
%     tankStates = eventInitStateLogEntry.getAllActiveTankStates();
%     stageStates = eventInitStateLogEntry.stageStates;
%     lvState = eventInitStateLogEntry.lvState;

%     altitude = norm(rVect) - bodyInfo.radius;
%     if(altitude <= 0 && any(fmEnums == ForceModelsEnum.Normal))
%         rswVVect = rotateVectorFromEciToRsw(vVect, rVect, vVect);
%         rswVVect(1) = 0; %kill vertical velocity because we don't want to go throught the surface of the planet
%         vVect = rotateVectorFromRsw2Eci(rswVVect, rVect, vVect);
%     end  

    holdDownEnabled = eventInitStateLogEntry.isHoldDownEnabled();

    ypp = zeros(length(y),1);
    if(holdDownEnabled)
        %launch clamp is enabled, only motion is circular motion
        %(fixed to body)       
        bodySpinRate = 2*pi/bodyInfo.rotperiod; %rad/sec
        spinVect = [0;0;bodySpinRate];
        rotAccel = crossARH(spinVect,crossARH(spinVect,rVect));

        ypp(1:3) = rotAccel(:);
    else
        %launch clamp disabled, propagate like normal
        if(totalMass > 0)
            [forceVect, ~] = gravForceModel.getForce([], rVect, [], totalMass, bodyInfo, [], [], [], [], [], [], [], []);
            accelVect = forceVect/totalMass;
        else
            accelVect = zeros(3,1);
        end

        ypp(1:3) = accelVect;
    end
end