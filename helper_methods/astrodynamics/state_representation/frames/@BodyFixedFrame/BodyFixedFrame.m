classdef BodyFixedFrame < AbstractReferenceFrame
    %BodyFixedFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData struct
    end
    
    methods
        function obj = BodyFixedFrame(bodyInfo, celBodyData)
            obj.bodyInfo = bodyInfo;
            obj.celBodyData = celBodyData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time)
            [rVectSunToBody, vVectSunToBody] = getPositOfBodyWRTSun(time, obj.bodyInfo, obj.celBodyData);
            
            spinAngle = getBodySpinAngle(obj.bodyInfo, time);
            rotMatToInertial = [cos(spinAngle) -sin(spinAngle) 0;
                                sin(spinAngle) cos(spinAngle) 0;
                                0 0 1];
            
            rotRateRadSec = 2*pi/obj.bodyInfo.rotperiod;
            omegaRI = [0;0;rotRateRadSec];
            
            posOffsetOrigin = rVectSunToBody;
            velOffsetOrigin = vVectSunToBody;
            angVelWrtOrigin = omegaRI;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.bodyInfo;
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('Body-Fixed Frame (Origin: %s)', obj.bodyInfo.name);
        end
    end
end