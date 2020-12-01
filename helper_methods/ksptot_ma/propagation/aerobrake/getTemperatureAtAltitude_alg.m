function temperature = getTemperatureAtAltitude_alg(altitude, lat, ut, long, ...
                       doNotUseAtmoTempSunMultCurve, doNotUseLatTempSunMultCurve, doNotUseAxialTempSunMultCurve, doNotUseAxialTempSunBiasCurveGI, doNotUseEccTempBiasCurveGI, ...
                       lattempsunmultcurve, axialtempsunbiascurve, axialtempsunmultcurve, ecctempbiascurve, lattempbiascurve, atmotempcurve, atmotempsunmultcurve, ...
                       atmohgt, rotperiod, rotini, radius,...
                       smas, eccs, incs, raans, args, means, epochs, parentGMs)
    bool = altitude <= atmohgt & altitude >= 0;
    
    temperature = zeros(length(altitude),1);
    if(any(bool))
        altitude = altitude(:);
        lat = lat(:);
        ut = ut(:);
        long = long(:);
        
        if(doNotUseAtmoTempSunMultCurve)
            atmosphereTemperatureOffset = 1;
        else
            if(doNotUseLatTempSunMultCurve)
                sunDotNormalProduct = zeros(size(ut));
            else
                hra = computeHourAngle_alg(ut, long, rotperiod, rotini, radius, smas, eccs, incs, raans, args, means, epochs, parentGMs);
                sunDotNormal = computeSunDotNormal(hra);
                lattempsunmultcurveData = interp1q(lattempsunmultcurve{1}, lattempsunmultcurve{2}, abs(lat));
                sunDotNormalProduct = sunDotNormal(:) .* lattempsunmultcurveData(:);
            end
            
            if(doNotUseAxialTempSunMultCurve)
                axialtempsunbiasProduct = zeros(size(ut));
            else
                axialtempsunbias = computeAxialTempSunBias(ut, smas(1), eccs(1), deg2rad(means(1)), epochs(1), parentGMs(1), doNotUseAxialTempSunBiasCurveGI, axialtempsunbiascurve);
                axialtempsunmultcurveData = interp1q(axialtempsunmultcurve{1}, axialtempsunmultcurve{2}, abs(lat));
                axialtempsunbiasProduct = axialtempsunbias(:) .* axialtempsunmultcurveData(:);
            end

            ecctempbias = computeEccTempBias(ut, smas(1), eccs(1), incs(1), raans(1), args(1), means(1), epochs(1), parentGMs(1), doNotUseEccTempBiasCurveGI, ecctempbiascurve);
            
            lattempbiascurveData = interp1q(lattempbiascurve{1}, lattempbiascurve{2}, abs(lat));
            
            atmosphereTemperatureOffset = lattempbiascurveData(:) + ...
                                        sunDotNormalProduct(:) + ... 
                                        axialtempsunbiasProduct(:) + ...
                                        ecctempbias(:);
        end
        
        atmotempcurveData = interp1q(atmotempcurve{1}, atmotempcurve{2}, altitude);
        atmotempsunmultcurveData = interp1q(atmotempsunmultcurve{1}, atmotempsunmultcurve{2}, altitude);
        
        temperature = atmotempcurveData(:) + ... %base temperature
                      atmosphereTemperatureOffset(:) .* atmotempsunmultcurveData(:); % altitude-based multiplier to temperature delta
    end
    
    if(any(not(bool)))
        temperature(not(bool)) = 0;
    end
end

function axialtempsunbias = computeAxialTempSunBias(ut, sma, ecc, M0, M0epoch, gmu, doNotUseAxialTempSunBiasCurveGI, axialtempsunbiascurve)
    if(isempty(gmu) || gmu == 0 || (doNotUseAxialTempSunBiasCurveGI))
        axialtempsunbias = zeros(size(ut));
    else
        n = computeMeanMotion(sma, gmu);
        deltaT = ut - M0epoch;
        M = M0 + n.*deltaT;
        tru = computeTrueAnomFromMean(M, ecc);

        axialtempsunbias = interp1q(axialtempsunbiascurve{1}, axialtempsunbiascurve{2}, rad2deg(tru));
    end
end

function ecctempbias = computeEccTempBias(ut, sma, ecc, inc, raan, arg, mean, epoch, gmu, doNotUseEccTempBiasCurveGI, ecctempbiascurve)
    if(isempty(gmu) || gmu == 0 || (doNotUseEccTempBiasCurveGI))
        ecctempbias = zeros(size(ut));
    else
        [rVect, ~] = getStateAtTime_alg(ut, sma, ecc, inc, raan, arg, mean, epoch, gmu);
        radius = norm(rVect);

        [rAp, rPe] = computeApogeePerigee(sma, ecc);
    
        if(rAp == rPe)
            inputVal = 0;
        else
            inputVal = (radius - rPe) / (rAp - rPe);
        end

        ecctempbias = interp1q(ecctempbiascurve{1}, ecctempbiascurve{2}, inputVal);
    end
end