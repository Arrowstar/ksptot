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
        
        function dcm = computeDcmToInertialFrame(~, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, ~)
           [~, ~, ~, dcm] = computeBodyAxesFromInertialAeroAngles(ut, rVect, vVect, bodyInfo, betaAng, alphaAng, gammaAng);
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(~, dcm, ut, rVect, vVect, bodyInfo, ~)
            [gammaAngle,betaAngle,alphaAngle] = computeInertialAeroAnglesFromBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
        end
    end
end