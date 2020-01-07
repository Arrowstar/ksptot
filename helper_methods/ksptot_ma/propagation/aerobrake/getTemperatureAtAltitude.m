function temperature = getTemperatureAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData) 
    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        if(isa(bodyInfo.atmotempsunmultcurve,'griddedInterpolant') && all(bodyInfo.atmotempsunmultcurve.Values == 0))
            atmosphereTemperatureOffset = 1;
        else
            parentGmu = getParentGM(bodyInfo, celBodyData);

            if(isa(bodyInfo.lattempsunmultcurve,'griddedInterpolant') && all(bodyInfo.lattempsunmultcurve.Values == 0))
                sunDotNormal = 1;
            else
                sunDotNormal = computeSunDotNormal(ut, rECEF, bodyInfo, celBodyData);
            end

            if(isa(bodyInfo.axialtempsunmultcurve,'griddedInterpolant') && all(bodyInfo.axialtempsunmultcurve.Values == 0))
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

function sunDotNormal = computeSunDotNormal(ut, rECEF, bodyInfo, celBodyData)
    rVectSunSC = -1.0 * getPositOfBodyWRTSun(ut, bodyInfo, celBodyData);
    
    if(norm(rVectSunSC) == 0)
        sunDotNormal = 1.0;
    else
        rVectSunECEF = getFixedFrameVectFromInertialVect(ut, rVectSunSC, bodyInfo);

        planarRvectEcef = [rECEF(1); rECEF(2); 0];
        planarRvectSunEcef = [rVectSunECEF(1); rVectSunECEF(2); 0];

        hra = angleNegPiToPi(dang(planarRvectEcef,planarRvectSunEcef));

        sunDotNormal = 0.5 * cos(hra + deg2rad(45)) + 0.5;
    end
end

function axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, gmu)
    if(isempty(gmu) || gmu == 0 || (isa(bodyInfo.axialtempsunbiascurve,'griddedInterpolant') &&  all(bodyInfo.axialtempsunbiascurve.Values == 0)))
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
    if(isempty(gmu) || gmu == 0 || (isa(bodyInfo.ecctempbiascurve,'griddedInterpolant') &&  all(bodyInfo.ecctempbiascurve.Values == 0)))
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