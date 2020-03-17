function datapt = lvd_AeroTasks(stateLogEntry, subTask, dummy)
%lvd_AeroTasks Summary of this function goes here
%   Detailed explanation goes here

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;
    mass = stateLogEntry.getTotalVehicleMass();
    celBodyData = bodyInfo.celBodyData;
    
    switch subTask            
        case 'dragCoeff'
            datapt = stateLogEntry.aero.getDragCoeff(ut, rVect, vVect, bodyInfo, mass, celBodyData);
            
        case 'dragArea'
            datapt = stateLogEntry.aero.getArea();
    end
end