classdef BodyFixedFrame < AbstractReferenceFrame
    %BodyFixedFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData

        rotMatToInertialCacheTime = NaN;
        rotMatToInertialCache2 = NaN(3,3);
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

            [posOffsetOrigin, velOffsetOrigin] = getPositOfBodyWRTSun(time, bi, obj.celBodyData);
            [angVelWrtOrigin, rotMatToInertial] = obj.getAngVelWrtOriginAndRotMatToInertial(time, [], []);
        end

        function R_BodyFixed_to_GlobalInertial = getRotMatToInertialAtTime(obj, time, ~, ~)
            if(numel(time) == 1 && obj.rotMatToInertialCacheTime == time)
                R_BodyFixed_to_GlobalInertial = obj.rotMatToInertialCache2;
            else
                bi = obj.bodyInfo;
    
                spinAngle = getBodySpinAngle(bi, time);
                spinAngle = spinAngle(:)';
                
                axang = [repmat([0 0 1], length(time), 1), spinAngle(:)];
                R_BodyInertialFrame_to_BodyFixedFrame = pagetranspose(axang2rotmARH(axang)); %I'm not sure why this transpose is required here but I assume it has to do with the definition of the frame coming out of axang2rotm().  In any event, it's definitely needed, things get backwards without it.
                R_BodyFixed_to_GlobalInertial = pagetranspose(pagemtimes(R_BodyInertialFrame_to_BodyFixedFrame, repmat(bi.bodyRotMatFromGlobalInertialToBodyInertial, [1 1 length(time)]))); 

                if(numel(time) == 1)
                    obj.rotMatToInertialCacheTime = time;
                    obj.rotMatToInertialCache2 = R_BodyFixed_to_GlobalInertial;
                end
            end
        end

        function [angVelWrtOrigin, rotMatToInertial] = getAngVelWrtOriginAndRotMatToInertial(obj, time, vehElemSet, bodyInfoInertialOrigin)
            bi = obj.bodyInfo;

            rotRateRadSec = 2*pi/bi.rotperiod;
            angVelWrtOrigin = repmat([0;0;rotRateRadSec], [1 length(time)]);

            if(nargout > 1)
                rotMatToInertial = obj.getRotMatToInertialAtTime(time, vehElemSet, bodyInfoInertialOrigin);
            end
        end

        function tf = frameOriginIsACelBody(obj)
            tf = true;
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
                newFrame = newBodyInfo.getBodyFixedFrame();
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

    methods(Static)
        function obj = loadobj(obj)
            obj.rotMatToInertialCacheTime = NaN;
            obj.rotMatToInertialCache2 = NaN(3,3);
        end
    end
end