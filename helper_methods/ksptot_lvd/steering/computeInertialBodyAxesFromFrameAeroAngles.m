function [bodyX, bodyY, bodyZ, R_body_2_inertial] = computeInertialBodyAxesFromFrameAeroAngles(ut, rVect, vVect, bodyInfo, bankAng, angOfAttack, angOfSideslip, baseFrame)
    arguments
        ut(1,1) double
        rVect(3,1) double
        vVect(3,1) double
        bodyInfo(1,1) KSPTOT_BodyInfo
        bankAng(1,1) double
        angOfAttack(1,1) double
        angOfSideslip(1,1) double
        baseFrame(1,1) AbstractReferenceFrame
    end

    frame = bodyInfo.getBodyCenteredInertialFrame();
    ce = CartesianElementSet(ut, rVect, vVect, frame);
    ce = ce.convertToFrame(baseFrame, true);
    rVectFrame = ce.rVect;
    vVectFrame = ce.vVect;

    [R_wind_2_frame, ~, ~, ~] = computeWindFrame(rVectFrame, vVectFrame);
    R_body_2_wind = eul2rotmARH([angOfSideslip,angOfAttack,bankAng],'zyx');
    [~,~,~, R_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce);
    R_body_2_inertial = real(R_frame_2_inertial * R_wind_2_frame * R_body_2_wind);
    
    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end