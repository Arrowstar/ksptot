function temperature = getTemperatureAtAltitude(bodyInfo, altitude, lat, ut, long) 
    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        if(bodyInfo.doNotUseAtmoTempSunMultCurve)
            atmosphereTemperatureOffset = 1;
        else
%             parentGmu = getParentGM(bodyInfo, celBodyData);
            parentGmu = bodyInfo.getParentGmuFromCache();

            if(bodyInfo.doNotUseLatTempSunMultCurve)
                sunDotNormal = 1;
            else
%                 sunDotNormal = computeSunDotNormal(ut, long, bodyInfo, bodyInfo.celBodyData);
                sunDotNormal = bodyInfo.getCachedSunDotNormal(ut, long);
            end
            
            if(bodyInfo.doNotUseAxialTempSunMultCurve)
                axialtempsunbias = 1;
            else
                axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, parentGmu);
            end

            ecctempbias = computeEccTempBias(ut, bodyInfo, parentGmu);
            
            atmosphereTemperatureOffset = bodyInfo.lattempbiascurve(abs(lat)) + ...
                                        bodyInfo.lattempsunmultcurve(abs(lat))*sunDotNormal + ... 
                                        axialtempsunbias * bodyInfo.axialtempsunmultcurve(abs(lat)) + ...
                                        ecctempbias;
        end
        
        temperature = bodyInfo.atmotempcurve(altitude) + ... %base temperature
                      atmosphereTemperatureOffset * bodyInfo.atmotempsunmultcurve(altitude); % altitude-based multiplier to temperature delta
    elseif(altitude <= 0)
        temperature = 0;
    else 
        temperature = 0;
    end
end

function axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, gmu)
    if(isempty(gmu) || gmu == 0 || (bodyInfo.doNotUseAxialTempSunBiasCurveGI))
        axialtempsunbias = 0;
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
        ecctempbias = 0;
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