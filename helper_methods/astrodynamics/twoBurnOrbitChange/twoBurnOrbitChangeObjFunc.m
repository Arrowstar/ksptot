function [dv, deltaV1, deltaV2, deltaV1R, deltaV2R, xfrOrbit, deltaV1NTW, deltaV2NTW] = twoBurnOrbitChangeObjFunc(x, iniOrbit, finOrbit, gmuXfr)
%twoBurnOrbitChangeObjFunc Summary of this function goes here
%   Detailed explanation goes here
    burn1TA = AngleZero2Pi(x(1));
    burn2TA = AngleZero2Pi(x(2));
    xfrArcTOF = x(3);
    
%     if(iniOrbit(2)<1E-5 && finOrbit(2)<1E-5) 
%         if(finOrbit(2)<1E-5)
%             finOrbit(2) = finOrbit(2) + 1E-5;
%         else
%             iniOrbit(2) = iniOrbit(2) + 1E-5;
%         end
%     end
 
%     if(iniOrbit(3)<1E-3 && finOrbit(3)<1E-3) 
%         finOrbit(3) = finOrbit(3) + 1E-3;
%     end

    if(length(iniOrbit) >= 8)
        gmuXfr1 = iniOrbit(8);
    else
        gmuXfr1 = gmuXfr;
    end
    
    if(length(finOrbit) >= 8)
        gmuXfr2 = finOrbit(8);
    else
        gmuXfr2 = gmuXfr;
    end
    
    [rVect1,vVect1Pre]=getStatefromKepler(iniOrbit(1), iniOrbit(2), iniOrbit(3), iniOrbit(4), iniOrbit(5), burn1TA, gmuXfr1);
    [rVect2,vVect2Post]=getStatefromKepler(finOrbit(1), finOrbit(2), finOrbit(3), finOrbit(4), finOrbit(5), burn2TA, gmuXfr2);

    xfrArcTOFDays = xfrArcTOF/(86400);
    [vVect1PostSW,vVect2PreSW]=orbit.lambert(rVect1', rVect2', xfrArcTOFDays, 0, gmuXfr);
    [vVect1PostLW,vVect2PreLW]=orbit.lambert(rVect1', rVect2', -xfrArcTOFDays, 0, gmuXfr);

    deltaV1SW = vVect1PostSW' - vVect1Pre;
    deltaV1LW = vVect1PostLW' - vVect1Pre;
    deltaV2SW = vVect2Post - vVect2PreSW';
    deltaV2LW = vVect2Post - vVect2PreLW';
    
    dvSW = norm(deltaV1SW) + norm(deltaV2SW);
    dvLW = norm(deltaV1LW) + norm(deltaV2LW);
    if(dvSW < dvLW)
        dv = dvSW;
        deltaV1 = deltaV1SW;
        deltaV2 = deltaV2SW;
        [sma, ecc, inc, longAscNode, ArgPeri, TA1] = getKeplerFromState(rVect1,vVect1PostSW,gmuXfr);
        [~, ~, ~, ~, ~, TA2] = getKeplerFromState(rVect2,vVect2PreSW,gmuXfr);
        xfrOrbit = [sma, ecc, inc, longAscNode, ArgPeri, TA1, TA2];
        if(ecc<1.0)
            xfrOrbit(6) = AngleZero2Pi(TA1);
            xfrOrbit(7) = AngleZero2Pi(TA2);
        end
        
        deltaV1NTW = getNTWdvVect(deltaV1, rVect1, vVect1Pre);
        deltaV2NTW = getNTWdvVect(deltaV2, rVect2, vVect2PreSW);
    else
        dv = dvLW;
        deltaV1 = deltaV1LW;
        deltaV2 = deltaV2LW;
        [sma, ecc, inc, longAscNode, ArgPeri, TA1] = getKeplerFromState(rVect1,vVect1PostLW,gmuXfr);
        [~, ~, ~, ~, ~, TA2] = getKeplerFromState(rVect2,vVect2PreLW,gmuXfr);
        xfrOrbit = [sma, ecc, inc, longAscNode, ArgPeri, TA1, TA2];
        if(ecc<1.0)
            xfrOrbit(6) = AngleZero2Pi(TA1);
            xfrOrbit(7) = AngleZero2Pi(TA2);
        end
        
        deltaV1NTW = getNTWdvVect(deltaV1, rVect1, vVect1Pre);
        deltaV2NTW = getNTWdvVect(deltaV2, rVect2, vVect2PreLW);
    end
    deltaV1R = rVect1;
    deltaV2R = rVect2;
end

