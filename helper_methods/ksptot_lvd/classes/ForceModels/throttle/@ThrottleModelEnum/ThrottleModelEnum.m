classdef ThrottleModelEnum < matlab.mixin.SetGet
    %ThrottleModelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        PolyModel('Polynominal Model','ThrottlePolyModel');
        T2WModel('Thrust To Weight Model','T2WThrottleModel');
    end
    
    properties
        nameStr char = '';
        classNameStr char = '';
    end
    
    methods
        function obj = ThrottleModelEnum(nameStr,classNameStr)
            obj.nameStr = nameStr;
            obj.classNameStr = classNameStr;
        end
    end
    
    methods(Static)
        function [throttleModelNameStrs, m] = getThrottleModelTypeNameStrs()
            [m,~] = enumeration('ThrottleModelEnum');
            
            throttleModelNameStrs = {};
            for(i=1:length(m)) %#ok<*NO4LP>
                throttleModelNameStrs{end+1} = m(i).nameStr; %#ok<AGROW>
            end
        end
        
        function ind = getIndOfListboxStrsForThrottleModel(throttleModel)
            [m,~] = enumeration('ThrottleModelEnum');
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
            m = enumeration('ThrottleModelEnum');
            ind = find(ismember({m.nameStr},nameStr),1,'first');
            enum = m(ind);
        end
    end
end