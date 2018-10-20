function datapt = lvd_SteeringAngleTask(stateLogEntry, subTask)
%lvd_SteeringAngleTask Summary of this function goes here
%   Detailed explanation goes here

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;

    [rollAngle, pitchAngle, yawAngle] =  stateLogEntry.attitude.getEulerAngles(ut, rVect, vVect, bodyInfo);
    [bankAng,angOfAttack,angOfSideslip] =  stateLogEntry.attitude.getAeroAngles(ut, rVect, vVect, bodyInfo);

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
    end
end