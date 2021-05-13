classdef HaloArriveDepartManifoldEnum < matlab.mixin.SetGet
    %HaloArriveDepartManifoldEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Arrive('Arrival Manifold');
        Depart('Departure Manifold');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = HaloArriveDepartManifoldEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('HaloArriveDepartManifoldEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m;
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('HaloArriveDepartManifoldEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('HaloArriveDepartManifoldEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end