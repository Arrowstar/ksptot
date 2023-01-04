classdef NomadSurrogateUncertaintyTypeEnum < matlab.mixin.SetGet
    %NomadSurrogateUncertaintyTypeEnum Summary of this class goes here
    %   See: https://nomad-4-user-guide.readthedocs.io/en/latest/SgteLib.html
    
    enumeration
        SMOOTH('SMOOTH', 'Smooth alternative of the uncertainty')
        NONSMOOTH('NONSMOOTH', 'Non-smooth alternative of the uncertainty')
    end
    
    properties
        optionStr char = ''
        name char = '';
    end
    
    methods
        function obj = NomadSurrogateUncertaintyTypeEnum(optionStr, name)
            obj.optionStr = optionStr;
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('NomadSurrogateUncertaintyTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            m = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('NomadSurrogateUncertaintyTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('NomadSurrogateUncertaintyTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end