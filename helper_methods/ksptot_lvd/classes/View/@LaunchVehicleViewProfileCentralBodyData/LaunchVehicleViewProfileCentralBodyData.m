classdef LaunchVehicleViewProfileCentralBodyData < matlab.mixin.SetGet
    %LaunchVehicleViewProfileCentralBodyData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo = KSPTOT_BodyInfo();
        hCBodySurfXForm = matlab.graphics.GraphicsPlaceholder();
        viewFrame AbstractReferenceFrame
    end
    
    methods
        function obj = LaunchVehicleViewProfileCentralBodyData(bodyInfo, hCBodySurfXForm, viewFrame)
            if(nargin > 0)
                obj.bodyInfo = bodyInfo;
                obj.hCBodySurfXForm = hCBodySurfXForm;
                obj.viewFrame = viewFrame;
            end
        end
        
        function setCentralBodyRotation(obj, time)
%             bodyFixedFrame = obj.bodyInfo.getBodyFixedFrame();
%             
%             [~, ~, ~, rotMatToInertial12] = bodyFixedFrame.getOffsetsWrtInertialOrigin(time);
%             [~, ~, ~, rotMatToInertial32] = obj.viewFrame.getOffsetsWrtInertialOrigin(time);
%             bodyRotMatFromGlobalInertialToBodyInertial = obj.bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial();
%             
%             M33 = rotMatToInertial32' * rotMatToInertial12 * bodyRotMatFromGlobalInertialToBodyInertial * rotz(obj.bodyInfo.surftexturezrotoffset);
%             M = eye(4);
%             M(1:3,1:3) = M33;
            M = getBodyXformMatrix(time, obj.bodyInfo, obj.viewFrame);
            obj.hCBodySurfXForm.Matrix = M;
        end
    end
end