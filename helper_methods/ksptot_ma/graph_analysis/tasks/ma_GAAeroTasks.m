function datapt = ma_GAAeroTasks(stateLogEntry, subTask, celBodyData)
%ma_GAAeroTasks Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    ut = stateLogEntry(1);
    rVectECI = stateLogEntry(2:4)';
    vVectECI = stateLogEntry(5:7)';
    
    switch subTask
        case 'dynPress'
            altitude = norm(rVectECI) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, ~, ~, ~, ~, ~, rECEF, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData); 
            elseif(altitude <= 0)
                density = 0;
                vVectECEF = [0;0;0];
            else 
                density = 0;
                vVectECEF = [0;0;0];
            end
            
            vVectEcefMag = norm(vVectECEF);
            vVectEcefMagMS = vVectEcefMag*1000;
            
            dynP = density * (vVectEcefMagMS^2) / 2; %kg/m^3 * m^2 / s^2  = kg/(m*s^2)
            dynP_kPa = dynP/1000;
            
            datapt = dynP_kPa;
        case 'atmoPress'
            altitude = norm(rVectECI) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            
            datapt = pressure;
            
        case 'atmoTemp'
            altitude = norm(rVectECI) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, ~, ~, ~, ~, ~, rECEF, ~] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                temperature = getTemperatureAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData) ;
            elseif(altitude <= 0)
                temperature = 0;
            else 
                temperature = 0;
            end
            
            datapt = temperature;
            
        case 'atmoDensity'
            altitude = norm(rVectECI) - bodyInfo.radius;

            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, ~, ~, ~, ~, ~, rECEF, ~] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData); 
            elseif(altitude <= 0)
                density = 0;
            else 
                density = 0;
            end
            
            datapt = density;
        case 'machNumber'
            altitude = norm(rVectECI) - bodyInfo.radius;
            pressure = getPressureAtAltitude(bodyInfo, altitude);
            
            if(altitude <= bodyInfo.atmohgt && altitude >= 0)
                [lat, ~, ~, ~, ~, ~, rECEF, vVectECEF, ~] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, rECEF, celBodyData); 
            elseif(altitude <= 0)
                density = 0;
            else 
                density = 0;
            end
            
            pressurePa = pressure*1000; %kPa -> Pa
            
            if(density > 0)
                speedSound = sqrt(1.4 * pressurePa / density);
                vECEFMag = norm(vVectECEF) * 1000; %km/s -> m/s

                datapt = vECEFMag/speedSound;
            else
                datapt = 0;
            end
    end
end

