classdef HaloCoordAdjustEnum < matlab.mixin.SetGet
    %HaloCoordAdjustEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        X('X_0', 1)
        Z('Z_0', 3);
    end
    
    properties
        name char = '';
        adjustInd(1,1) double = 0;
    end
    
    methods
        function obj = HaloCoordAdjustEnum(name, adjustInd)
            obj.name = name;
            obj.adjustInd = adjustInd;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('HaloCoordAdjustEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m;
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('HaloCoordAdjustEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('HaloCoordAdjustEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end