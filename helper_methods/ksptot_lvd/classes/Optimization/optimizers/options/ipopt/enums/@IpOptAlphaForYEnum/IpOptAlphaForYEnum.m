classdef IpOptAlphaForYEnum < matlab.mixin.SetGet
    %IpOptAlphaForYEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Primal('Primal','primal')
        BoundMult('Bound-Mult','bound-mult')
        Min('Min','min')
        Max('Max','max')
        Full('Full','full')
        MinDualInfeas('Min. Dual Infeasibilty','min-dual-infeas')
        SaferMinDualInfeas('Safer Min. Dual Infeasibilty','safer-min-dual-infeas')
        PrimalAndFull('Primal And Full','primal-and-full')
        DualAndFull('Dual And Full','dual-and-full')
    end
    
    properties
        name(1,:) char
        optStr(1,:) char
    end
    
    methods
        function obj = IpOptAlphaForYEnum(name, optStr)
            obj.name = name;
            obj.optStr = optStr;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('IpOptAlphaForYEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('IpOptAlphaForYEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('IpOptAlphaForYEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end