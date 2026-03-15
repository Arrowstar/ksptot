classdef MockRotatingFrame < AbstractReferenceFrame
    properties
        posO
        velO
        omega
        R
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.UserDefined
    end
    
    methods
        function obj = MockRotatingFrame(posO, velO, omega, R)
            obj.posO = posO;
            obj.velO = velO;
            obj.omega = omega;
            obj.R = R;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, ~, ~)
            posOffsetOrigin = obj.posO;
            velOffsetOrigin = obj.velO;
            angVelWrtOrigin = obj.omega;
            rotMatToInertial = obj.R;
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = KSPTOT_BodyInfo.empty(1,0); 
        end
        
        function nameStr = getNameStr(obj)
            nameStr = 'Mock Rotating Frame';
        end
        
        function editFrameDialogUI(obj, ~)
        end
        
        function setOriginBody(~, ~)
        end
        
        function rotMatToInertial = getRotMatToInertialAtTime(obj, time, vehElemSet, bodyInfoInertialOrigin)
            [~, ~, ~, rotMatToInertial] = obj.getOffsetsWrtInertialOrigin(time, vehElemSet, bodyInfoInertialOrigin);
        end

        function [angVelWrtOrigin, rotMatToInertial] = getAngVelWrtOriginAndRotMatToInertial(obj, time, vehElemSet, bodyInfoInertialOrigin)
            [~, ~, angVelWrtOrigin, rotMatToInertial] = obj.getOffsetsWrtInertialOrigin(time, vehElemSet, bodyInfoInertialOrigin);
        end
    end
end
