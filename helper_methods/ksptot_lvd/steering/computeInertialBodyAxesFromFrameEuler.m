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

    frame = bodyInfo.getBodyCenteredInertialFrame();
    ce = CartesianElementSet(ut, rVect, vVect, frame);
    ce = ce.convertToFrame(baseFrame, true);
    rVectFrame = ce.rVect;

    R_body_2_ned = eul2rotmARH([yawAng,pitchAng,rollAng],'zyx');
    [R_ned_2_frame, ~, ~, ~] = computeNedFrameInFrame(rVectFrame);
%     [~,~,~, R_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce, []);
    R_frame_2_inertial = baseFrame.getRotMatToInertialAtTime(ut, ce, []);
	R_body_2_inertial = real(R_frame_2_inertial * R_ned_2_frame * R_body_2_ned);
    
    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end