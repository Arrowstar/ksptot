function temperature = getTemperatureAtAltitude(bodyInfo, altitude, lat, ut, long)
    bool = altitude <= bodyInfo.atmohgt & altitude >= 0;
    
    if(any(bool))
        altitude = altitude(:);
        lat = lat(:);
        ut = ut(:);
        long = long(:);
        
        if(bodyInfo.doNotUseAtmoTempSunMultCurve)
            atmosphereTemperatureOffset = 1;
        else
            parentGmu = bodyInfo.getParentGmuFromCache();

            if(bodyInfo.doNotUseLatTempSunMultCurve)
                sunDotNormalProduct = zeros(size(ut));
            else
                hra = computeHourAngle(ut, long, bodyInfo);
                sunDotNormal = computeSunDotNormal(hra);
                sunDotNormalProduct = sunDotNormal(:) .* bodyInfo.lattempsunmultcurve(abs(lat));
            end
            
            if(bodyInfo.doNotUseAxialTempSunMultCurve)
                axialtempsunbiasProduct = zeros(size(ut));
            else
                axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, parentGmu);
                axialtempsunbiasProduct = axialtempsunbias(:) .* bodyInfo.axialtempsunmultcurve(abs(lat));
            end

            ecctempbias = computeEccTempBias(ut, bodyInfo, parentGmu);
            
            atmosphereTemperatureOffset = bodyInfo.lattempbiascurve(abs(lat)) + ...
                                        sunDotNormalProduct(:) + ... 
                                        axialtempsunbiasProduct(:) + ...
                                        ecctempbias(:);
        end
        
        temperature = bodyInfo.atmotempcurve(altitude) + ... %base temperature
                      atmosphereTemperatureOffset .* bodyInfo.atmotempsunmultcurve(altitude); % altitude-based multiplier to temperature delta
    end
    
    if(any(not(bool)))
        temperature(not(bool)) = 0;
    end
end

function axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, gmu)
    if(isempty(gmu) || gmu == 0 || (bodyInfo.doNotUseAxialTempSunBiasCurveGI))
        axialtempsunbias = zeros(size(ut));
    else
        sma = bodyInfo.sma;
        ecc = bodyInfo.ecc;    

        M0 = deg2rad(bodyInfo.mean); 

        n = computeMeanMotion(sma, gmu);
        deltaT = ut - bodyInfo.epoch;
        M = M0 + n.*deltaT;
        tru = computeTrueAnomFromMean(M, ecc);

        axialtempsunbias = bodyInfo.axialtempsunbiascurve(rad2deg(tru));
    end
end

function ecctempbias = computeEccTempBias(ut, bodyInfo, gmu)
    if(isempty(gmu) || gmu == 0 || (bodyInfo.doNotUseEccTempBiasCurveGI))
        ecctempbias = zeros(size(ut));
    else
        [rVect, ~] = getStateAtTime(bodyInfo,ut,gmu);
        radius = norm(rVect);

        [rAp, rPe] = computeApogeePerigee(bodyInfo.sma, bodyInfo.ecc);
    
        if(rAp == rPe)
            inputVal = 0;
        else
            inputVal = (radius - rPe) / (rAp - rPe);
        end
        
        ecctempbias = bodyInfo.ecctempbiascurve(inputVal);
    end
end