classdef LibrationPointEnum < matlab.mixin.SetGet
    %LibrationPointEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        L1('L1')
        L2('L2');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = LibrationPointEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('LibrationPointEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m;
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('LibrationPointEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('LibrationPointEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end