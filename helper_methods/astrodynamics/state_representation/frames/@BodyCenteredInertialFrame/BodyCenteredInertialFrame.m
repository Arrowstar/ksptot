classdef BodyCenteredInertialFrame < AbstractReferenceFrame
    %BodyCenteredInertialFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData
        
        bodyRotMatFromGlobalInertialToBodyInertial(3,3) double
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.BodyCenteredInertial
    end
    
    methods
        function obj = BodyCenteredInertialFrame(bodyInfo, celBodyData)
            obj.bodyInfo = bodyInfo;
            obj.celBodyData = celBodyData;
            obj.bodyRotMatFromGlobalInertialToBodyInertial = obj.bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, ~)            
            [rVectB, vVectB] = getPositOfBodyWRTSun(time, [obj.bodyInfo], obj(1).celBodyData);

            posOffsetOrigin = rVectB;
            velOffsetOrigin = vVectB;
            angVelWrtOrigin = repmat([0;0;0], [1, length(time)]);
            
            if(numel(obj) == 1)
                rotMatToInertial = repmat(obj.bodyRotMatFromGlobalInertialToBodyInertial, [1, 1, length(time)]);
                
            else
                rotMatToInertial = NaN([3, 3, length(time)]);
                
                [uniObj,~,ic] = unique(obj,'stable');
                for(i=1:length(uniObj))
                    subObj = uniObj(i);
                    bool = i == ic;
                    subTimes = time(bool);
                    
                    rotMatToInertial(:,:,bool) = repmat(subObj.bodyRotMatFromGlobalInertialToBodyInertial, [1, 1, numel(subTimes)]);
                end
            end
        end
        
        function bodyInfo = getOriginBody(obj)
            bodyInfo = [obj.bodyInfo];
        end
        
        function setOriginBody(obj, newBodyInfo)
            obj.bodyInfo = newBodyInfo;
        end
        
        function nameStr = getNameStr(obj)
            nameStr = sprintf('Inertial Frame (Origin: %s)', obj.bodyInfo.name);
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
            
            [selection,ok] = listdlgARH('ListString',bodiesStr, 'SelectionMode','single', 'InitialValue',ind, ...
                                           'Name','Select Frame Central Body', ...
                                           'PromptString', {'Select the central body of the reference frame:'}, ...
                                           'ListSize', [250 300]);
                           
            if(ok == 1)
                newBodyInfo = sortedBodyInfoArr(selection);
                newFrame = BodyCenteredInertialFrame(newBodyInfo, obj.celBodyData);
            else
                newFrame = obj;
            end
        end
    end
    
    methods
        function bool = eq(A,B)
            try
                if(numel(A) == 1 && numel(B) == 1 && ...
                   A.typeEnum == ReferenceFrameEnum.BodyCenteredInertial && ...
                   B.typeEnum == ReferenceFrameEnum.BodyCenteredInertial)
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
            obj.bodyRotMatFromGlobalInertialToBodyInertial = obj.bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial;
        end
    end
end