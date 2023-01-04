classdef NomadSurrogateDistanceTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateDistanceTypeEnum Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html
    
    enumeration
        NORM1('NORM1', 'Euclidian distance')
        NORM2('NORM2', 'Distance based on norm 1')
        NORMINF('NORMINF', 'Distance based on infinity norm')
        NORM2_IS0('NORM2_IS0', 'Tailored distance for discontinuity in 0')
        NORM2_CAT('NORM2_CAT', 'Tailored distance for categorical models')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadSurrogateDistanceTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateDistanceTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateDistanceTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateDistanceTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end