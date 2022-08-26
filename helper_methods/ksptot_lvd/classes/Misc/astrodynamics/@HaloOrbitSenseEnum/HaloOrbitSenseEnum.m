classdef HaloOrbitSenseEnum < matlab.mixin.SetGet
    %HaloOrbitSenseEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        North('Northern')
        South('Southern');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = HaloOrbitSenseEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('HaloOrbitSenseEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m;
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('HaloOrbitSenseEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('HaloOrbitSenseEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end