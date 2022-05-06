classdef InertialControlFrame < AbstractControlFrame
    %InertialControlFrame 
    
    properties(Constant)
        enum = ControlFramesEnum.InertialFrame;
    end
    
    methods
        function obj = InertialControlFrame()
            
        end
        
        function enum = getControlFrameEnum(obj)
            enum = ControlFramesEnum.InertialFrame;
        end
        
        function dcm = computeDcmToInertialFrame(obj, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame)
            arguments
                obj(1,1) InertialControlFrame
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                gammaAng(1,1) double
                betaAng(1,1) double
                alphaAng(1,1) double
                baseFrame(1,1) AbstractReferenceFrame
            end

            frame = bodyInfo.getBodyCenteredInertialFrame();
            ce = CartesianElementSet(ut, rVect, vVect, frame);
            ce = ce.convertToFrame(baseFrame);
            
            [~, ~, ~, base_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce, baseFrame.getOriginBody()); 
            body_2_base_frame = eul2rotmARH([alphaAng,betaAng,gammaAng],'zyx');
            dcm = base_frame_2_inertial * body_2_base_frame;
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(obj, attState, ut, rVect, vVect, bodyInfo, inFrame)
            arguments
                obj(1,1) InertialControlFrame
                attState(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            [gammaAngle, betaAngle, alphaAngle] = attState.getEulerAnglesInBaseFrame(ut, rVect, vVect, bodyInfo, inFrame);

%             [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes_Func(dcm, ut, rVect, vVect, bodyInfo, baseFrame);
        end
    end
end