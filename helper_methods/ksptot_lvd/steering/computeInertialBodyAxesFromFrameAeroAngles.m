function [bodyX, bodyY, bodyZ, R_body_2_inertial] = computeInertialBodyAxesFromFrameAeroAngles(ut, rVect, vVect, bodyInfo, bankAng, angOfAttack, angOfSideslip, baseFrame)
    body_inertial_frame = bodyInfo.getBodyCenteredInertialFrame();

    [posOffset1, velOffset1, angVel1, R_1_to_GI] = getFrameOffsetsFromCache(body_inertial_frame, ut);
    [posOffset2, velOffset2, angVel2, R_2_to_GI] = getFrameOffsetsFromCache(baseFrame, ut);

    rVectGI = posOffset1 + R_1_to_GI * rVect;
    vVectGI = velOffset1 + R_1_to_GI * (vVect + cross(angVel1, rVect));

    R_GI_to_2 = R_2_to_GI';
    rVectBaseFrame = R_GI_to_2 * (rVectGI - posOffset2);
    vVectBaseFrame = R_GI_to_2 * (vVectGI - velOffset2) - cross(angVel2, rVectBaseFrame);

    [R_wind_2_BaseFrame, ~, ~, ~] = computeWindFrame(rVectBaseFrame, vVectBaseFrame);

    R_vehicleBodyFrame_2_wind = eul2rotmARH_mex([angOfSideslip,angOfAttack,bankAng],'zyx');

    R_baseFrame_2_GlobalInertial = R_2_to_GI;

    R_bodyInertialFrame_2_GlobalInertial = R_1_to_GI;
    R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';

    R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;

    R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_wind_2_BaseFrame * R_vehicleBodyFrame_2_wind);
    
    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end