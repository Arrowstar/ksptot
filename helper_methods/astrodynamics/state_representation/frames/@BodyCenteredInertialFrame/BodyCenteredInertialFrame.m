classdef BodyCenteredInertialFrame < AbstractReferenceFrame
    %BodyCenteredInertialFrame Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bodyInfo KSPTOT_BodyInfo
        celBodyData
    end

    properties(Dependent)
        bodyRotMatFromGlobalInertialToBodyInertial(3,3) double
    end
    
    properties(Constant)
        typeEnum = ReferenceFrameEnum.BodyCenteredInertial
    end
    
    methods
        function obj = BodyCenteredInertialFrame(bodyInfo, celBodyData)
            obj.bodyInfo = bodyInfo;
            obj.celBodyData = celBodyData;
        end

        function value = get.bodyRotMatFromGlobalInertialToBodyInertial(obj)
            value = obj.bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial;
        end
        
        function [posOffsetOrigin, velOffsetOrigin, angVelWrtOrigin, rotMatToInertial] = getOffsetsWrtInertialOrigin(obj, time, ~, ~)            
            [rVectB, vVectB] = getPositOfBodyWRTSun(time, [obj.bodyInfo], obj(1).celBodyData);

            posOffsetOrigin = rVectB;
            velOffsetOrigin = vVectB;
            
            [angVelWrtOrigin, rotMatToInertial] = obj.getAngVelWrtOriginAndRotMatToInertial(time, [], []);
        end

        function R_BodyInertial_to_GlobalInertial = getRotMatToInertialAtTime(obj, time, ~, ~)
            if(numel(obj) == 1)
                R_BodyInertial_to_GlobalInertial = repmat(obj.bodyRotMatFromGlobalInertialToBodyInertial', [1, 1, length(time)]);
                
            else
                R_BodyInertial_to_GlobalInertial = NaN([3, 3, length(time)]);
                
                [uniObj,~,ic] = unique(obj,'stable');
                for(i=1:length(uniObj)) %#ok<*NO4LP> 
                    subObj = uniObj(i);
                    bool = i == ic;
                    subTimes = time(bool);
                    
                    R_BodyInertial_to_GlobalInertial(:,:,bool) = repmat(subObj.bodyRotMatFromGlobalInertialToBodyInertial', [1, 1, numel(subTimes)]);
                end
            end
        end

        function [angVelWrtOrigin, rotMatToInertial] = getAngVelWrtOriginAndRotMatToInertial(obj, time, vehElemSet, bodyInfoInertialOrigin)
            angVelWrtOrigin = repmat([0;0;0], [1, length(time)]);
            rotMatToInertial = obj.getRotMatToInertialAtTime(time, vehElemSet, bodyInfoInertialOrigin);
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
                newFrame = newBodyInfo.getBodyCenteredInertialFrame();
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
        % function obj = loadobj(obj)
        % 
        % end
    end
end