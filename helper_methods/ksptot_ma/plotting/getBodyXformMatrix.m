function M = getBodyXformMatrix(time, bodyInfo, viewFrame)
    bodyFixedFrame = bodyInfo.getBodyFixedFrame();
    ce = bodyInfo.getElementSetsForTimes(time);
    
    [~, ~, ~, R_BodyFixed_to_GlobalInertial] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time, ce);
    [~, ~, ~, R_ViewFrame_to_GlobalInertial] = viewFrame.getOffsetsWrtInertialOrigin(time, ce);

    zRotOffset = bodyInfo.surftexturezrotoffset; %degrees
    rotMatZOffset = [cosd(zRotOffset) -sind(zRotOffset) 0; sind(zRotOffset) cosd(zRotOffset) 0; 0 0 1];
    
    R_BodyFixed_to_ViewFrame = R_ViewFrame_to_GlobalInertial' * R_BodyFixed_to_GlobalInertial;

    M33 = R_BodyFixed_to_ViewFrame * rotMatZOffset;
    axang = rotm2axangARH(M33);
    
    ce = bodyInfo.getElementSetsForTimes(time);
    ce = ce.convertToCartesianElementSet().convertToFrame(viewFrame);
    posOffset = ce.rVect;
    
    M = makehgtform('translate',posOffset(:)', 'axisrotate',axang(1:3),axang(4));   
end