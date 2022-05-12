classdef BodyFixedFrame < AbstractReferenceFrame
    %BodyFixedFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.BodyFixedRotating
    end
    
    methods
        function obj = BodyFixedFrame(bodyInfo, celBodyData)
            obj.bodyInfo = bodyInfo;
            obj.celBodyData = celBodyData;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, ~, ~)
            bi = obj.bodyInfo;
            [rVectSunToBody, vVectSunToBody] = getPositOfBodyWRTSun(time, bi, obj.celBodyData);
            
            rotMatToInertial = obj.getRotMatToInertialAtTime(time);

            rotRateRadSec = 2*pi/bi.rotperiod;
            omegaRI = repmat([0;0;rotRateRadSec], [1 length(time)]);
            
            posOffsetOrigin = rVectSunToBody;
            velOffsetOrigin = vVectSunToBody;
            angVelWrtOrigin = omegaRI;
        end

        function rotMatToInertial = getRotMatToInertialAtTime(obj, time, ~, ~)
            bi = obj.bodyInfo;

            spinAngle = getBodySpinAngle(bi, time);
            spinAngle = spinAngle(:)';
            
            if(numel(time) == 1)
                c = cos(spinAngle);
                s = sin(spinAngle);
                rotMatToInertial = [c -s 0;  s c 0;  0 0 1] * bi.bodyRotMatFromGlobalInertialToBodyInertial;
            else
                zero = permute(zeros(size(spinAngle)), [1 3 2]);
                one  = zero + 1;
                c = permute(cos(spinAngle), [1 3 2]);
                s = permute(sin(spinAngle), [1 3 2]);
                rotMatToInertial = pagemtimes([c -s zero;  s c zero;  zero zero one], repmat(bi.bodyRotMatFromGlobalInertialToBodyInertial, [1 1 length(time)]));
            end
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = [obj.bodyInfo];
        end
        
        function setOriginBody(obj, newBodyInfo)
            obj.bodyInfo = newBodyInfo;
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('Body-Fixed Frame (Origin: %s)', obj.bodyInfo.name);
        end
        
        function newFrame = editFrameDialogUI(obj, ~)
            if(isempty(obj.celBodyData))
                obj.celBodyData = obj.bodyInfo.celBodyData;
            end
            
            [bodiesStr, sortedBodyInfo] = ma_getSortedBodyNames(obj.celBodyData);
            for(i=1:length(sortedBodyInfo))
                sortedBodyInfoArr(i) = sortedBodyInfo{i}; %#ok<AGROW>
            end
            
            ind = find(obj.bodyInfo == sortedBodyInfoArr,1,'first');
            
            out = AppDesignerGUIOutput();
            listdlgARH_App('ListString',bodiesStr, 'SelectionMode','single', 'InitialValue',ind, ...
                           'Name','Select Frame Central Body', ...
                           'PromptString', {'Select the central body of the reference frame:'}, ...
                           'ListSize', [250 300], ...
                           'out',out);
            selection = out.output{1};
            ok = out.output{2};
                           
            if(ok == 1)
                newBodyInfo = sortedBodyInfoArr(selection);
                newFrame = BodyFixedFrame(newBodyInfo, obj.celBodyData);
            else
                newFrame = obj;
            end
        end
    end
    
    methods
        function bool = eq(A,B)
            try
                if(numel(A) == 1 && numel(B) == 1 && ...
                   A.typeEnum == ReferenceFrameEnum.BodyFixedRotating && ...
                   B.typeEnum == ReferenceFrameEnum.BodyFixedRotating)
                    bool = A.bodyInfo == B.bodyInfo;
                else
                    bool = eq@handle(A,B);
                end
            catch ME %#ok<NASGU>
                bool = eq@handle(A,B);
            end
        end
        
        function bool = ne(A,B)
            bool = not(eq(A,B));
        end
    end
end