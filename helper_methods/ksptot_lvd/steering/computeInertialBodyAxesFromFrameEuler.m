function [bodyX, bodyY, bodyZ, R_body_2_inertial] = computeInertialBodyAxesFromFrameEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng, baseFrame)
    bodyInertialFrame = bodyInfo.getBodyCenteredInertialFrame();

    [posOffset1, velOffset1, angVel1, R_1_to_GI] = getFrameOffsetsFromCache(bodyInertialFrame, ut);
    [posOffset2, velOffset2, angVel2, R_2_to_GI] = getFrameOffsetsFromCache(baseFrame, ut);

    rVectGI = posOffset1 + R_1_to_GI * rVect;
    vVectGI = velOffset1 + R_1_to_GI * (vVect + cross(angVel1, rVect));

    R_GI_to_2 = R_2_to_GI';
    rVectBaseFrame = R_GI_to_2 * (rVectGI - posOffset2);

    R_vehicleBody_2_ned = eul2rotmARH_mex([yawAng,pitchAng,rollAng],'zyx');

    [R_ned_2_baseFrame, ~, ~, ~] = computeNedFrameInFrame(rVectBaseFrame);

    R_baseFrame_2_GlobalInertial = R_2_to_GI;
    R_bodyInertialFrame_2_GlobalInertial = R_1_to_GI;

    R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';
    R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;

	R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_ned_2_baseFrame * R_vehicleBody_2_ned); 

    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end