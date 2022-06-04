function datapt = lvd_AeroTasks(stateLogEntry, subTask, dummy)
%lvd_AeroTasks Summary of this function goes here
%   Detailed explanation goes here
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        dummy
    end

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;
    mass = stateLogEntry.getTotalVehicleMass();
    aero = stateLogEntry.aero;
    attState = stateLogEntry.attitude;
    celBodyData = bodyInfo.celBodyData;
    
    maStateLogEntry = [ut, rVect(:)', vVect(:)', bodyInfo.id, mass, 0, 0, 0, -1];
    altitude = ma_GALongLatAltTasks(maStateLogEntry, 'alt', celBodyData);
    vVectEcefMag = ma_GALongLatAltTasks(maStateLogEntry, 'bodyFixedVNorm', celBodyData);
    [lat, long, ~, ~, ~, ~, ~, ~] = getLatLongAltFromInertialVect(ut, rVect, bodyInfo, vVect);
    [density, pressureKPA, ~] = getAtmoDensityAtAltitude(bodyInfo, altitude, lat, ut, long); 
    [~,angOfAttack,angOfSideslip,totalAoA] = attState.getAeroAngles(ut, rVect, vVect, bodyInfo);

    switch subTask            
        case 'dragCoeff'
            datapt = stateLogEntry.aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, altitude, pressureKPA, density, vVectEcefMag, totalAoA, angOfAttack, angOfSideslip);
        case 'dragForce'
            dragForceModel = DragForceModel();
            dragForceVect = dragForceModel.getForce(ut, rVect, vVect, mass, bodyInfo, aero, [], [], [], [], [], [], [], [], [], [], attState);
            dragForceMag = norm(dragForceVect); %mT*km/s^2
            datapt = dragForceMag*1000; %kN
    end
end