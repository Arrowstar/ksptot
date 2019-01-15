function [density] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat)
%getAtmoDensityAtAltitude Summary of this function goes here
%   Detailed explanation goes here

    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        pressure = getPressureAtAltitude(bodyInfo, altitude);
        
        atmosphereTemperatureOffset = bodyInfo.lattempbiascurve(abs(lat)) + ...
                                      bodyInfo.lattempsunmultcurve(abs(lat))*1.0 + ... %the 1.0 is the sunDotNormalized, I'm not computing that here and just assuming its 1
                                      0.0; % this is where the axial temp sun mult curve would go, but I'm also not doing anything that that, so 0.

        temperature = bodyInfo.atmotempcurve(altitude) + ... %base temperature
                      bodyInfo.atmotempsunmultcurve(altitude) + ... % altitude-based multiplier to temperature delta
                      atmosphereTemperatureOffset; 

        density = getDensityFromIdealGasLaw(pressure, temperature, bodyInfo.atmomolarmass);
        if(density<0)
            density = 0;
        end
    elseif(altitude <= 0)
        density = 0;
    else 
        density = 0;
    end
end