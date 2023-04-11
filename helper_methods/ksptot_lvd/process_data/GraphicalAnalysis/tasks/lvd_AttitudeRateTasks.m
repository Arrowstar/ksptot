function datapt = lvd_AttitudeRateTasks(stateLogEntry, subTask, inFrame)
%lvd_AttitudeRateTasks Summary of this function goes here
%   Detailed explanation goes here
    arguments
        stateLogEntry(1,1) LaunchVehicleStateLogEntry
        subTask(1,:) char
        inFrame AbstractReferenceFrame
    end

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    bodyInfo = stateLogEntry.centralBody;
    vehElemSet = stateLogEntry.getCartesianElementSetRepresentation();

    baseSteeringDcmFrame = bodyInfo.getBodyCenteredInertialFrame();
    R12 = baseSteeringDcmFrame.getRotMatToInertialAtTime(ut, vehElemSet, bodyInfo);

    R32 = inFrame.getRotMatToInertialAtTime(ut, vehElemSet, bodyInfo);

    R13 = R32' * R12;

    dcm1 = stateLogEntry.steeringModel.getBody2InertialDcmAtTime(ut, rVect, vVect, bodyInfo);
    q1 = rotm2quat(dcm1 * R13);

    dt = 0.001;
    ut2 = ut + dt;
    rVect2 = rVect + dt * vVect; %close enough
    vVect2 = vVect; %close enough
    dcm2 = stateLogEntry.steeringModel.getBody2InertialDcmAtTime(ut2, rVect2, vVect2, bodyInfo);
    q2 = rotm2quat(dcm2 * R13);
    
    %source = https://mariogc.com/post/angular-velocity-quaternions/
    %units: rad/s
    angRates = (2/dt) * [q1(1)*q2(2) - q1(2)*q2(1) - q1(3)*q2(4) + q1(4)*q2(3);
                         q1(1)*q2(3) + q1(2)*q2(4) - q1(3)*q2(1) - q1(4)*q2(2);
                         q1(1)*q2(4) - q1(2)*q2(3) + q1(3)*q2(2) - q1(4)*q2(1)];

    switch subTask
        case 'bodyAngVelX'
            datapt = angRates(1) * 180/pi;

        case 'bodyAngVelY'
            datapt = angRates(2) * 180/pi;

        case 'bodyAngVelZ'
            datapt = angRates(3) * 180/pi;

        case 'totalAngularVel'
            datapt = norm(angRates) * 180/pi;
            if(datapt > 15)
                a=1;
            end
    end
end