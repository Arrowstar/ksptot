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

    body_inertial_frame = bodyInfo.getBodyCenteredInertialFrame();
    ce = CartesianElementSet(ut, rVect, vVect, body_inertial_frame);
    ce = ce.convertToFrame(baseFrame, true);
    rVectBaseFrame = ce.rVect;
    vVectBaseFrame = ce.vVect;

    [R_wind_2_BaseFrame, ~, ~, ~] = computeWindFrame(rVectBaseFrame, vVectBaseFrame);

    R_vehicleBodyFrame_2_wind = eul2rotmARH_mex([angOfSideslip,angOfAttack,bankAng],'zyx');

    [~,~,~, R_baseFrame_2_GlobalInertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce);

    R_bodyInertialFrame_2_GlobalInertial = body_inertial_frame.getRotMatToInertialAtTime(ut, ce, []);
    R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';

    R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;

    R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_wind_2_BaseFrame * R_vehicleBodyFrame_2_wind);
    
    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end