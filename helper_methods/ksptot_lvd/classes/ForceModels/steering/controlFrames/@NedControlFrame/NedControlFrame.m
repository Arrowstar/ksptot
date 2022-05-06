classdef NedControlFrame < AbstractControlFrame
    %NedControlFrame North-East-Down control frame
    
    properties(Constant)
        enum = ControlFramesEnum.NedFrame;
    end
    
    methods
        function obj = NedControlFrame()
            
        end

        function enum = getControlFrameEnum(~)
            enum = ControlFramesEnum.NedFrame;
        end
        
        function R_body_2_inertial = computeDcmToInertialFrame(obj, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame)
            arguments
                obj(1,1) NedControlFrame
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                gammaAng(1,1) double
                betaAng(1,1) double
                alphaAng(1,1) double
                baseFrame(1,1) AbstractReferenceFrame
            end

%             [~, ~, ~, dcm] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame);
            [~, ~, ~, R_body_2_inertial] = computeInertialBodyAxesFromFrameEuler(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame);
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(obj, attState, ut, rVect, vVect, bodyInfo, inFrame)
            arguments
                obj(1,1) NedControlFrame
                attState(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            [gammaAngle, betaAngle, alphaAngle] = attState.getEulerAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);

%             [gammaAngle, betaAngle, alphaAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3)); 
        end
    end
end