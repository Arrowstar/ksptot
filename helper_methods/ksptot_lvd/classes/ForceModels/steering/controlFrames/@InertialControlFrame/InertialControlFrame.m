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
        
        function dcm = computeDcmToInertialFrame(~, ut, rVect, vVect, frame, gammaAng, betaAng, alphaAng, baseFrame)
            ce = CartesianElementSet(ut, rVect(:), vVect(:), frame);
            
            [~, ~, ~, base_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce); 
            body_2_base_frame = eul2rotmARH([alphaAng,betaAng,gammaAng],'zyx');
            dcm = base_frame_2_inertial * body_2_base_frame;
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(~, dcm, ut, rVect, vVect, bodyInfo, baseFrame)
%             ce = CartesianElementSet(ut, rVect(:), vVect(:), bodyInfo.getBodyCenteredInertialFrame());
%             [~, ~, ~, base_frame_2_inertial] = baseFrame.getOffsetsWrtInertialOrigin(ut, ce);
%             
%             angles = rotm2eulARH(base_frame_2_inertial' * dcm, 'zyx');
% 
%             angles = real(angles);
% 
%             gammaAngle = angles(3);
%             betaAngle = angles(2);
%             alphaAngle = angles(1);

            [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes_Func(dcm, ut, rVect, vVect, bodyInfo, baseFrame);
        end
    end
end