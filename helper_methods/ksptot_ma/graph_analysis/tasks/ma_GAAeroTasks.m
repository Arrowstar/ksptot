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
                [lat, ~, ~, ~, ~, ~, ~, vVectECEF] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
                density = getAtmoDensityAtAltitude(bodyInfo, altitude, lat); 
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
    end
end

