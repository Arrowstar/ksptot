function [density, pressure, temperature] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long)
%getAtmoDensityAtAltitude Summary of this function goes here
%   Detailed explanation goes here
%   See here for math: https://forum.kerbalspaceprogram.com/index.php?/topic/142686-modeling-atmospheres-in-ksp/

    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
%         pressure = getPressureAtAltitude(bodyInfo, altitude);
        pressure = getBodyAtmoPressure(bodyInfo, altitude);
        
        if(pressure > 0)
            temperature = getBodyAtmoTemperature(bodyInfo, ut, lat, long, altitude);

            density = getDensityFromIdealGasLaw(pressure, temperature, bodyInfo.atmomolarmass);
            if(density < 0)
                density = 0;
                pressure = 0;
                temperature = 0;
            end
        else
            density = 0;
            pressure = 0;
            temperature = 0;
        end
    elseif(altitude <= 0)
        density = 0;
        pressure = 0;
        temperature = 0;
    else 
        density = 0;
        pressure = 0;
        temperature = 0;
    end
end