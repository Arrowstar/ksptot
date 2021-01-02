classdef NedControlFrame < AbstractControlFrame
    %NedControlFrame North-East-Down control frame
    
    properties(Constant)
        enum = ControlFramesEnum.NedFrame;
    end
    
    methods
        function obj = NedControlFrame()
            
        end
        
        function dcm = computeDcmToInertialFrame(~, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, ~)
            [~, ~, ~, dcm] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng);
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(~, dcm, ut, rVect, vVect, bodyInfo, ~)
            [gammaAngle, betaAngle, alphaAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
        end
        
        function enum = getControlFrameEnum(obj)
            enum = ControlFramesEnum.NedFrame;
        end
    end
end