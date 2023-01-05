classdef IpOptRecalcYEnum < matlab.mixin.SetGet
    %IpOptRecalcYEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        No('No','no')
        Yes('Yes','yes')
    end
    
    properties
        name(1,:) char
        optStr(1,:) char
    end
    
    methods
        function obj = IpOptRecalcYEnum(name, optStr)
            obj.name = name;
            obj.optStr = optStr;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('IpOptRecalcYEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('IpOptRecalcYEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('IpOptRecalcYEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end