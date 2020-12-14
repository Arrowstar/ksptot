function M = getBodyXformMatrix(time, bodyInfo, viewFrame)
    bodyFixedFrame = bodyInfo.getBodyFixedFrame();

    [~, ~, ~, rotMatToInertial12] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time);
    [~, ~, ~, rotMatToInertial32] = viewFrame.getOffsetsWrtInertialOrigin(time);
    bodyRotMatFromGlobalInertialToBodyInertial = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial();

    M33 = rotMatToInertial32' * rotMatToInertial12 * bodyRotMatFromGlobalInertialToBodyInertial * rotz(bodyInfo.surftexturezrotoffset);
    M = eye(4);
    M(1:3,1:3) = M33;    
end