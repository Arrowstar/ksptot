classdef TwoBodyRotatingFrame < AbstractReferenceFrame
    %TwoBodyRotatingFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        primaryBodyInfo KSPTOT_BodyInfo
        secondaryBodyInfo KSPTOT_BodyInfo
        originPt(1,1) TwoBodyRotatingFrameOriginEnum = TwoBodyRotatingFrameOriginEnum.Primary
        celBodyData
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.TwoBodyRotating
    end
    
    methods
        function obj = TwoBodyRotatingFrame(primaryBodyInfo, secondaryBodyInfo, originPt, celBodyData)
            obj.primaryBodyInfo = primaryBodyInfo;
            obj.secondaryBodyInfo = secondaryBodyInfo;
            obj.originPt = originPt;
            obj.celBodyData = celBodyData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, ~, ~)            
            [rVectSunToPrimaryBody, vVectSunToPrimaryBody] = getPositOfBodyWRTSun(time, obj.primaryBodyInfo, obj.celBodyData);            
            [rVectSunToSecondaryBody, vVectSunToSecondaryBody] = getPositOfBodyWRTSun(time, obj.secondaryBodyInfo, obj.celBodyData);

            switch obj.originPt
                case TwoBodyRotatingFrameOriginEnum.Primary
                    rVectSunToOriginBody = rVectSunToPrimaryBody;
                    vVectSunToOriginBody = vVectSunToPrimaryBody;
                    
                case TwoBodyRotatingFrameOriginEnum.Secondary
                    rVectSunToOriginBody = rVectSunToSecondaryBody;
                    vVectSunToOriginBody = vVectSunToSecondaryBody;
                    
                otherwise
                    error('Unknown origin point enumeration: %s', obj.originPt.name);
            end
            
            rPrimaryToSecondary = rVectSunToSecondaryBody - rVectSunToPrimaryBody;
            vPrimaryToSecondary = vVectSunToSecondaryBody - vVectSunToPrimaryBody;
            
            xHat = permute(vect_normVector(rPrimaryToSecondary), [1 3 2]);
            zHat = permute(vect_normVector(cross(rPrimaryToSecondary, vPrimaryToSecondary)), [1 3 2]);
            yHat = vect_normVector(cross(zHat,xHat));
            
            rotMatToInertial = [xHat, yHat, zHat];
            
            omegaRI = cross(rPrimaryToSecondary, vPrimaryToSecondary) ./ vecNormARH(rPrimaryToSecondary).^2;
            
            posOffsetOrigin = rVectSunToOriginBody;
            velOffsetOrigin = vVectSunToOriginBody;
            angVelWrtOrigin = omegaRI;
        end

        function rotMatToInertial = getRotMatToInertialAtTime(obj, time, ~, ~)
            [~, ~, ~, rotMatToInertial] = obj.getOffsetsWrtInertialOrigin(time);
        end
        
        function bodyInfo = getOriginBody(obj)
            switch obj.originPt
                case TwoBodyRotatingFrameOriginEnum.Primary
                    bodyInfo = obj.primaryBodyInfo;
                    
                case TwoBodyRotatingFrameOriginEnum.Secondary
                    bodyInfo = obj.secondaryBodyInfo;
                    
                otherwise
                    error('Unknown origin point enumeration: %s', obj.originPt.name);
            end
        end
        
        function bodyInfo = getNonOriginBody(obj)
            for(i=1:length(obj))
                switch obj.originPt
                    case TwoBodyRotatingFrameOriginEnum.Primary
                        bodyInfo(i) = obj(i).secondaryBodyInfo; 

                    case TwoBodyRotatingFrameOriginEnum.Secondary
                        bodyInfo(i) = obj(i).primaryBodyInfo;

                    otherwise
                        error('Unknown origin point enumeration: %s', string(obj(i).originPt));
                end
            end
        end
        
        function setOriginBody(obj, newBodyInfo)
            switch obj.originPt
                case TwoBodyRotatingFrameOriginEnum.Primary
                    obj.primaryBodyInfo = newBodyInfo;
                    
                case TwoBodyRotatingFrameOriginEnum.Secondary
                    obj.secondaryBodyInfo = newBodyInfo;
                    
                otherwise
                    error('Unknown origin point enumeration: %s', obj.originPt.name);
            end
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('Two Body Rotating Frame (Primary: %s, Secondary: %s, Origin: %s)', ...
                              obj.primaryBodyInfo.name, ...
                              obj.secondaryBodyInfo.name, ...
                              obj.originPt.name);
        end
        
        function newFrame = editFrameDialogUI(obj, ~)
            if(isempty(obj.celBodyData))
                obj.celBodyData = obj.primaryBodyInfo.celBodyData;
            end
            
%             editTwoBodyRotatingFrameGUI(obj);

            output = AppDesignerGUIOutput({false});
            editTwoBodyRotatingFrameGUI_App(obj, output);
            newFrame = obj; %the frame is either going to be updated or not.
        end
    end
end