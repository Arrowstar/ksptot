function [bodyX, bodyY, bodyZ, R_body_2_inertial] = computeInertialBodyAxesFromFrameEuler(ut, rVect, vVect, bodyInfo, rollAng, pitchAng, yawAng, baseFrame) 
    arguments
        ut(1,1) double
        rVect(3,1) double
        vVect(3,1) double
        bodyInfo(1,1) KSPTOT_BodyInfo
        rollAng(1,1) double
        pitchAng(1,1) double
        yawAng(1,1) double
        baseFrame(1,1) AbstractReferenceFrame
    end

    bodyInertialFrame = bodyInfo.getBodyCenteredInertialFrame();
    ce = CartesianElementSet(ut, rVect, vVect, bodyInertialFrame);
    ce = ce.convertToFrame(baseFrame, true);
    rVectBaseFrame = ce.rVect;

    R_vehicleBody_2_ned = eul2rotmARH_mex([yawAng,pitchAng,rollAng],'zyx');

    [R_ned_2_baseFrame, ~, ~, ~] = computeNedFrameInFrame(rVectBaseFrame);

    R_baseFrame_2_GlobalInertial = baseFrame.getRotMatToInertialAtTime(ut, ce, []);
    R_bodyInertialFrame_2_GlobalInertial = bodyInertialFrame.getRotMatToInertialAtTime(ut, ce, []);

    R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';
    R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;

	R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_ned_2_baseFrame * R_vehicleBody_2_ned); 

    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end