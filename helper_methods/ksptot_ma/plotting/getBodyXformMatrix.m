function M = getBodyXformMatrix(time, bodyInfo, viewFrame)
    bodyFixedFrame = bodyInfo.getBodyFixedFrame();

    [~, ~, ~, rotMatToInertial12] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time);
    [~, ~, ~, rotMatToInertial32] = viewFrame.getOffsetsWrtInertialOrigin(time);
    bodyRotMatFromGlobalInertialToBodyInertial = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial();

    zRotOffset = bodyInfo.surftexturezrotoffset;
    rotMatZOffset = [cosd(zRotOffset) -sind(zRotOffset) 0; sind(zRotOffset) cosd(zRotOffset) 0; 0 0 1];
    
    M33 = rotMatToInertial32' * rotMatToInertial12 * bodyRotMatFromGlobalInertialToBodyInertial * rotMatZOffset;
    M = eye(4);
    M(1:3,1:3) = M33;    
end