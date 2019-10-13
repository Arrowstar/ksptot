function [density] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData)
%getAtmoDensityAtAltitude Summary of this function goes here
%   Detailed explanation goes here
%   See here for math: https://forum.kerbalspaceprogram.com/index.php?/topic/142686-modeling-atmospheres-in-ksp/

    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        pressure = getPressureAtAltitude(bodyInfo, altitude);
        
        if(pressure > 0)
            parentGmu = getParentGM(bodyInfo, celBodyData);
            
            sunDotNormal = computeSunDotNormal(ut, rECEF, bodyInfo, celBodyData);
            axialtempsunbias = computeAxialTempSunBias(ut, bodyInfo, parentGmu);
            ecctempbias = computeEccTempBias(ut, bodyInfo, parentGmu);
            
            atmosphereTemperatureOffset = bodyInfo.lattempbiascurve(abs(lat)) + ...
                                          bodyInfo.lattempsunmultcurve(abs(lat))*sunDotNormal + ... 
                                          axialtempsunbias * bodyInfo.axialtempsunmultcurve(abs(lat)) + ...
                                          ecctempbias;

            temperature = bodyInfo.atmotempcurve(altitude) + ... %base temperature
                          bodyInfo.atmotempsunmultcurve(altitude) + ... % altitude-based multiplier to temperature delta
                          atmosphereTemperatureOffset; 

            density = getDensityFromIdealGasLaw(pressure, temperature, bodyInfo.atmomolarmass);
            if(density < 0)
                density = 0;
            end
        else
            density = 0;
        end
    elseif(altitude <= 0)
        density = 0;
    else 
        density = 0;
    end
end