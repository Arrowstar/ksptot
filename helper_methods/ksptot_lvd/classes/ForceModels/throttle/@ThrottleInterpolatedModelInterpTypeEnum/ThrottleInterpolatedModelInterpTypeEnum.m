classdef ThrottleInterpolatedModelInterpTypeEnum < matlab.mixin.SetGet
    %ThrottleInterpolatedModelInterpTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Linear('Linear','linear');
        PChip('Shape-preserving Piecewise Cubic','pchip');
        Cubic('Cubic','cubic');
        Spline('Cubic Spline','spline');
        Makima('Modified Akima cubic Hermite','makima');
    end
    
    properties
        nameStr char = '';
        giModelTypeStr char = '';
    end
    
    methods
        function obj = ThrottleInterpolatedModelInterpTypeEnum(nameStr,giModelTypeStr)
            obj.nameStr = nameStr;
            obj.giModelTypeStr = giModelTypeStr;
        end
    end
    
    methods(Static)
        function [throttleModelNameStrs, m] = getThrottleModelTypeNameStrs()
            [m,~] = enumeration('ThrottleInterpolatedModelInterpTypeEnum');
            
            throttleModelNameStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                throttleModelNameStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForThrottleModel(throttleModel)
            [m,~] = enumeration('ThrottleInterpolatedModelInterpTypeEnum');
            inputClass = class(throttleModel);
            
            ind = -1;
            for(i=1:length(m))
                if(strcmpi(m(i).classNameStr,inputClass))
                    ind = i;
                    break;
                end
            end
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ThrottleInterpolatedModelInterpTypeEnum');
            ind = find(ismember({m.nameStr},nameStr),1,'first');
            enum = m(ind);
        end
    end
end