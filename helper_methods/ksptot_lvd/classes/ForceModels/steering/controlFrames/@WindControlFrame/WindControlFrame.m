classdef WindControlFrame < AbstractControlFrame
    %WindControlFrame 
    
    properties(Constant)
        enum = ControlFramesEnum.WindFrame;
    end
    
    methods
        function obj = WindControlFrame()
            
        end
        
        function enum = getControlFrameEnum(obj)
            enum = ControlFramesEnum.WindFrame;
        end
        
        function R_body_2_inertial = computeDcmToInertialFrame(obj, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame)
            arguments
                obj(1,1) WindControlFrame
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                gammaAng(1,1) double
                betaAng(1,1) double
                alphaAng(1,1) double
                baseFrame(1,1) AbstractReferenceFrame
            end

%             [~, ~, ~, dcm] = computeBodyAxesFromInertialAeroAngles(ut, rVect, vVect, bodyInfo, betaAng, alphaAng, gammaAng);

            [~, ~, ~, R_body_2_inertial] = computeInertialBodyAxesFromFrameAeroAngles(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, baseFrame);
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(obj, attState, ut, rVect, vVect, bodyInfo, inFrame)
            arguments
                obj(1,1) WindControlFrame
                attState(1,1) LaunchVehicleAttitudeState
                ut(1,1) double
                rVect(3,1) double
                vVect(3,1) double
                bodyInfo(1,1) KSPTOT_BodyInfo
                inFrame(1,1) AbstractReferenceFrame
            end

            [gammaAngle,betaAngle,alphaAngle] = attState.getAeroAnglesInFrame(ut, rVect, vVect, bodyInfo, inFrame);

%             [gammaAngle,betaAngle,alphaAngle] = computeInertialAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
        end
    end
end