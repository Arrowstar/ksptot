classdef NedControlFrame < AbstractControlFrame
    %NedControlFrame North-East-Down control frame
    
    properties(Constant)
        enum = ControlFramesEnum.NedFrame;
    end
    
    methods
        function obj = NedControlFrame()
            
        end
        
        function dcm = computeDcmToInertialFrame(~, ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng, ~)
%             geoElemSet = elemSet.convertToGeographicElementSet().convertToFrame(obj.baseFrame);
%             time = geoElemSet.time;
%             phi = geoElemSet.lat;
%             lambda = geoElemSet.long;
%             
%             RBaseFrameToNed = [-sin(phi)*cos(lambda), -sin(lambda), -cos(phi)*cos(lambda);
%                                -sin(phi)*sin(lambda),  cos(lambda), -cos(phi)*sin(lambda);
%                                 cos(phi),              0,           -sin(phi)]';
%             
%             [~, ~, ~, R_from_inertial_to_base] = obj.baseFrame.getOffsetsWrtInertialOrigin(time);
%             RNed2Inert = (RBaseFrameToNed * R_from_inertial_to_base')';
%             
%             dcmCntrl2Inertial = RNed2Inert;

            [~, ~, ~, dcm] = computeBodyAxesFromEuler(ut, rVect, vVect, bodyInfo, gammaAng, betaAng, alphaAng);
        end
        
        function [gammaAngle, betaAngle, alphaAngle] = getAnglesFromInertialBodyAxes(~, dcm, ut, rVect, vVect, bodyInfo, ~)
            [gammaAngle, betaAngle, alphaAngle] = computeEulerAnglesFromInertialBodyAxes(ut, rVect, vVect, bodyInfo, dcm(:,1), dcm(:,2), dcm(:,3));
        end
    end
end