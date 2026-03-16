function [bodyX, bodyY, bodyZ, R_body_2_inertial] = computeInertialBodyAxesFromFrameAeroAngles(ut, rVect, vVect, bodyInfo, bankAng, angOfAttack, angOfSideslip, baseFrame, atmoState)
    arguments
        ut(1,1) double
        rVect(3,1) double
        vVect(3,1) double
        bodyInfo(1,1) KSPTOT_BodyInfo
        bankAng(1,1) double
        angOfAttack(1,1) double
        angOfSideslip(1,1) double
        baseFrame(1,1) AbstractReferenceFrame
        atmoState struct = struct()
    end

    body_inertial_frame = bodyInfo.getBodyCenteredInertialFrame();

    if(not(isempty(atmoState)) && isfield(atmoState,'REci2Ecef') && ...
       baseFrame.typeEnum == ReferenceFrameEnum.BodyFixedRotating && baseFrame.getOriginBody() == bodyInfo)
        
        % Optimized path using atmoState to avoid expensive recalculations
        R_baseFrame_2_GlobalInertial = atmoState.REci2Ecef';
        R_bodyInertialFrame_2_GlobalInertial = body_inertial_frame.getRotMatToInertialAtTime(ut, [], []);

        R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';
        R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;
        
        rVectBaseFrame = atmoState.REci2Ecef * (R_bodyInertialFrame_2_GlobalInertial * rVect);
        vVectBaseFrame = atmoState.vVectECEF;
    else
        ce = CartesianElementSet(ut, rVect, vVect, body_inertial_frame);
        ce = ce.convertToFrame(baseFrame, true);
        rVectBaseFrame = ce.rVect;
        vVectBaseFrame = ce.vVect;

        [~,~,~, R_baseFrame_2_GlobalInertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce);

        R_bodyInertialFrame_2_GlobalInertial = body_inertial_frame.getRotMatToInertialAtTime(ut, ce, []);
        R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';

        R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;
    end

    [R_wind_2_BaseFrame, ~, ~, ~] = computeWindFrame(rVectBaseFrame, vVectBaseFrame);

    R_vehicleBodyFrame_2_wind = eul2rotmARH_mex([angOfSideslip,angOfAttack,bankAng],'zyx');

    R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_wind_2_BaseFrame * R_vehicleBodyFrame_2_wind);
    
    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
end