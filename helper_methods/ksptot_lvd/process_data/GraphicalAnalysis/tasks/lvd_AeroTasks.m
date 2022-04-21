function datapt = lvd_AeroTasks(stateLogEntry, subTask, dummy)
%lvd_AeroTasks Summary of this function goes here
%   Detailed explanation goes here

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;
    mass = stateLogEntry.getTotalVehicleMass();
    celBodyData = bodyInfo.celBodyData;
    
    maStateLogEntry = [ut, rVect(:)', vVect(:)', bodyInfo.id, mass, 0, 0, 0, -1];
    altitude = ma_GALongLatAltTasks(maStateLogEntry, 'alt', celBodyData);
    vVectEcefMag = ma_GALongLatAltTasks(maStateLogEntry, 'bodyFixedVNorm', celBodyData);

    switch subTask            
        case 'dragCoeff'
            datapt = stateLogEntry.aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, altitude, vVectEcefMag);
    end
end