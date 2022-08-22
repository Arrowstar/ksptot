function [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromFrameBodyAxes(rVectFrame, bodyXFrame, bodyYFrame, bodyZFrame)
    R_body_2_frame = horzcat(bodyXFrame, bodyYFrame, bodyZFrame);

    [R_ned_2_frame, ~, ~, ~] = computeNedFrameInFrame(rVectFrame);
    angles = real(rotm2eulARH(R_ned_2_frame' * R_body_2_frame, 'zyx'));
    
    rollAngle = angles(3);
    pitchAngle = angles(2);
    yawAngle = angles(1);
end