classdef IpOptCorrectorTypeEnum < matlab.mixin.SetGet
    %IpOptCorrectorTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        None('None','none')
        Affine('Affine','affine')
        PrimalDual('Primal-Dual','primal-dual')
    end
    
    properties
        name(1,:) char
        optStr(1,:) char
    end
    
    methods
        function obj = IpOptCorrectorTypeEnum(name, optStr)
            obj.name = name;
            obj.optStr = optStr;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('IpOptCorrectorTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('IpOptCorrectorTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('IpOptCorrectorTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end