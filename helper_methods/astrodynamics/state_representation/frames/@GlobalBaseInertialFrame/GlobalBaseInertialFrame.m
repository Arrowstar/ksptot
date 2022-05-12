classdef GlobalBaseInertialFrame < AbstractReferenceFrame
    %GlobalBaseInertialFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        celBodyData
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.BodyCenteredInertial
    end
    
    methods
        function obj = BodyCenteredInertialFrame(celBodyData)
            obj.celBodyData = celBodyData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(~, time, ~, ~)            
            posOffsetOrigin = repmat([0;0;0], [1, length(time)]);
            velOffsetOrigin = repmat([0;0;0], [1, length(time)]);
            [angVelWrtOrigin, rotMatToInertial] = obj.getAngVelWrtOriginAndRotMatToInertial(time, [], []);
        end

        function rotMatToInertial = getRotMatToInertialAtTime(~, time, ~, ~)
            rotMatToInertial = repmat(eye(3), [1, 1, length(time)]);
        end

        function [angVelWrtOrigin, rotMatToInertial] = getAngVelWrtOriginAndRotMatToInertial(obj, time, vehElemSet, bodyInfoInertialOrigin)
            angVelWrtOrigin = repmat([0;0;0], [1, length(time)]);
            rotMatToInertial = obj.getRotMatToInertialAtTime(time, vehElemSet, bodyInfoInertialOrigin);
        end

        function tf = frameOriginIsACelBody(obj)
            tf = false;
        end
        
        function bodyInfo = getOriginBody(~)
            error('Not supported.');
        end
        
        function setOriginBody(~, ~)
            %nothing to do
        end
        
        function nameStr = getNameStr(~)
            nameStr = sprintf('Global Base Inertial Frame');
        end
        
        function newFrame = editFrameDialogUI(obj, ~)
            newFrame = obj;
        end
    end
    
    methods
        function bool = eq(A,B)
            bool = eq@handle(A,B);
        end
        
        function bool = ne(A,B)
            bool = ne@handle(A,B);
        end
    end
end