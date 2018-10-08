function [rollAngle, pitchAngle, yawAngle] = computeEulerAnglesFromInertialBodyAxes(rVect, vVect, bodyX, bodyY, bodyZ)
    [R_vvlh_2_inert, ~, ~, ~] = computeVvlhFrame(rVect,vVect);
    R_total = horzcat(bodyX, bodyY, bodyZ);
    
    [yawAngle,pitchAngle,rollAngle]=dcm2angle(R_vvlh_2_inert' * R_total,'xyz');
    rollAngle = real(rollAngle);
    pitchAngle = real(pitchAngle);
    yawAngle = real(yawAngle);
end