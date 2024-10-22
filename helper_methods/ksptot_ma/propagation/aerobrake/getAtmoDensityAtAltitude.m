function [density, pressure, temperature] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long)
%getAtmoDensityAtAltitude Summary of this function goes here
%   Detailed explanation goes here
%   See here for math: https://forum.kerbalspaceprogram.com/index.php?/topic/142686-modeling-atmospheres-in-ksp/
    arguments
        bodyInfo(1,1) KSPTOT_BodyInfo
        altitude(1,1) double
        lat(1,1) double
        ut(1,1) double
        long(1,1) double
    end

    if(altitude <= bodyInfo.atmohgt && altitude >= 0)
        if(not(isempty(bodyInfo.densityGI)))
            lat = angleNegPiToPi_mex(lat);
            long = AngleZero2Pi(long);

            out = bodyInfo.densityGI(lat, long, altitude);
            % out = squeeze(out);

            density = out(1);
            pressure = out(2);
            temperature = out(3);
        else
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