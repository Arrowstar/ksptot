classdef BodyCenteredInertialFrame < AbstractReferenceFrame
    %BodyCenteredInertialFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData struct
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.BodyCenteredInertial
    end
    
    methods
        function obj = BodyCenteredInertialFrame(bodyInfo, celBodyData)
            obj.bodyInfo = bodyInfo;
            obj.celBodyData = celBodyData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time)
            [rVectB, vVectB] = getPositOfBodyWRTSun(time, obj.bodyInfo, obj.celBodyData);
            
            posOffsetOrigin = rVectB;
            velOffsetOrigin = vVectB;
            angVelWrtOrigin = [0;0;0];
            rotMatToInertial = eye(3);
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = obj.bodyInfo;
        end
        
        function setOriginBody(obj, newBodyInfo)
            obj.bodyInfo = newBodyInfo;
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('Inertial Frame (Origin: %s)', obj.bodyInfo.name);
        end
    end
end