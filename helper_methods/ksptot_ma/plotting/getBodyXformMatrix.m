function M = getBodyXformMatrix(time, bodyInfo, viewFrame)
    bodyFixedFrame = bodyInfo.getBodyFixedFrame();
    ce = bodyInfo.getElementSetsForTimes(time);
    
    [~, ~, ~, rotMatToInertial12] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time, ce);
    [~, ~, ~, rotMatToInertial32] = viewFrame.getOffsetsWrtInertialOrigin(time, ce);

    zRotOffset = bodyInfo.surftexturezrotoffset; %degrees
    rotMatZOffset = [cosd(zRotOffset) -sind(zRotOffset) 0; sind(zRotOffset) cosd(zRotOffset) 0; 0 0 1];
    
    M33 = rotMatToInertial32' * rotMatToInertial12 * rotMatZOffset;
    axang = rotm2axangARH(M33);
    
    ce = bodyInfo.getElementSetsForTimes(time);
    ce = ce.convertToCartesianElementSet().convertToFrame(viewFrame);
    posOffset = ce.rVect;
    
    M = makehgtform('translate',posOffset(:)', 'axisrotate',axang(1:3),axang(4));     
end