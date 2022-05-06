function datapt = lvd_SteeringAngleTask(stateLogEntry, subTask, inFrame)
%lvd_SteeringAngleTask Summary of this function goes here
%   Detailed explanation goes here

%     stateLogEntry = stateLogEntry.deepCopy();
%     cartElem = stateLogEntry.getCartesianElementSetRepresentation().convertToFrame(inFrame);
%     stateLogEntry.setCartesianElementSet(cartElem);

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;

    [rollAngle, pitchAngle, yawAngle] =  stateLogEntry.attitude.getEulerAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);
    [bankAng,angOfAttack,angOfSideslip,totalAoA] =  stateLogEntry.attitude.getAeroAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);

    switch subTask
        case 'roll'
            datapt = rad2deg(rollAngle);
        case 'pitch'
            datapt = rad2deg(pitchAngle);
        case 'yaw'
            datapt = rad2deg(yawAngle);
        case 'bank'
            datapt = rad2deg(bankAng);
        case 'angleOfAttack'
            datapt = rad2deg(angOfAttack);
        case 'sideslip'
            datapt = rad2deg(angOfSideslip);
        case 'totalAngleOfAttack'
            datapt = rad2deg(totalAoA);
    end
end