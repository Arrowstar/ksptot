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

    persistent lastInputs;
    persistent ceProxy;
    
    if(~isempty(lastInputs) && ...
       lastInputs.ut == ut && ...
       lastInputs.rollAng == rollAng && ...
       lastInputs.pitchAng == pitchAng && ...
       lastInputs.yawAng == yawAng && ...
       lastInputs.baseFrame == baseFrame && ...
       lastInputs.rVect(1) == rVect(1) && ...
       lastInputs.rVect(2) == rVect(2) && ...
       lastInputs.rVect(3) == rVect(3) && ...
       lastInputs.vVect(1) == vVect(1) && ...
       lastInputs.vVect(2) == vVect(2) && ...
       lastInputs.vVect(3) == vVect(3))
        
        bodyX = lastInputs.bodyX;
        bodyY = lastInputs.bodyY;
        bodyZ = lastInputs.bodyZ;
        R_body_2_inertial = lastInputs.R_body_2_inertial;
        return;
    end

    bodyInertialFrame = bodyInfo.getBodyCenteredInertialFrame();
    
    if(bodyInertialFrame == baseFrame)
        rVectBaseFrame = rVect;
        R_baseFrame_2_BodyInertialFrame = eye(3);
    else
        % We need an element set for some frame conversions
        if(isempty(ceProxy))
            ceProxy = CartesianElementSet(ut, rVect, vVect, bodyInertialFrame);
        else
            ceProxy.time = ut;
            ceProxy.rVect = rVect;
            ceProxy.vVect = vVect;
            ceProxy.frame = bodyInertialFrame;
        end

        if(baseFrame.getOriginBody() == bodyInfo)
            % Optimized path for frames sharing the same origin (typical for steering)
            % Avoids expensive conversion, but still needs rotation matrix
            R_baseFrame_2_GlobalInertial = baseFrame.getRotMatToInertialAtTime(ut, ceProxy, []);
            R_bodyInertialFrame_2_GlobalInertial = bodyInertialFrame.getRotMatToInertialAtTime(ut, ceProxy, []);

            R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';
            R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;
            
            % rVectBaseFrame = R_baseFrame_to_Global' * R_bodyInertialFrame_to_Global * rVect
            rVectBaseFrame = R_baseFrame_2_GlobalInertial' * (R_bodyInertialFrame_2_GlobalInertial * rVect);
        else
            % Fallback for different origins
            ce = ceProxy.convertToFrame(baseFrame, true);
            rVectBaseFrame = ce.rVect;
            
            R_baseFrame_2_GlobalInertial = baseFrame.getRotMatToInertialAtTime(ut, ce, []);
            R_bodyInertialFrame_2_GlobalInertial = bodyInertialFrame.getRotMatToInertialAtTime(ut, ce, []);

            R_GlobalInertial_2_bodyInertialFrame = R_bodyInertialFrame_2_GlobalInertial';
            R_baseFrame_2_BodyInertialFrame = R_GlobalInertial_2_bodyInertialFrame * R_baseFrame_2_GlobalInertial;
        end
    end

    R_vehicleBody_2_ned = eul2rotmARH_mex([yawAng,pitchAng,rollAng],'zyx');

    [R_ned_2_baseFrame, ~, ~, ~] = computeNedFrameInFrame(rVectBaseFrame);

	R_body_2_inertial = real(R_baseFrame_2_BodyInertialFrame * R_ned_2_baseFrame * R_vehicleBody_2_ned); 

    bodyX = R_body_2_inertial(:,1);
    bodyY = R_body_2_inertial(:,2);
    bodyZ = R_body_2_inertial(:,3);
    
    lastInputs.ut = ut;
    lastInputs.rVect = rVect;
    lastInputs.vVect = vVect;
    lastInputs.rollAng = rollAng;
    lastInputs.pitchAng = pitchAng;
    lastInputs.yawAng = yawAng;
    lastInputs.baseFrame = baseFrame;
    lastInputs.bodyX = bodyX;
    lastInputs.bodyY = bodyY;
    lastInputs.bodyZ = bodyZ;
    lastInputs.R_body_2_inertial = R_body_2_inertial;
end