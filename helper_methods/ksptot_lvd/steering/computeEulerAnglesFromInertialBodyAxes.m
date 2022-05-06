function [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, bodyX, bodyY, bodyZ)
    R_body_2_inertial = horzcat(bodyX, bodyY, bodyZ);

    [R_ned_2_inert, ~, ~, ~] = computeNedFrame(ut, rVect, bodyInfo);
    angles = rotm2eulARH(R_ned_2_inert' * R_body_2_inertial, 'zyx');
    
    rollAngle = real(angles(3));
    pitchAngle = real(angles(2));
    yawAngle = real(angles(1));
end