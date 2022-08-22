classdef DeltaVFrameEnum < matlab.mixin.SetGet
    %DeltaVFrameEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Inertial('Inertial Frame', {'X', 'Y', 'Z'});
        OrbitNtw('Orbit Frame (NTW)', {'Prograde', 'Normal', 'Radial'})
    end
    
    properties
        nameStr char = '';
        compNames cell = {};
    end
    
    methods
        function obj = DeltaVFrameEnum(nameStr, compNames)
            obj.nameStr = nameStr;
            obj.compNames = compNames;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('DeltaVFrameEnum');
            [~,I] = sort({m.nameStr});
            listBoxStr = {m(I).nameStr};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('DeltaVFrameEnum');
            [~,I] = sort({m.nameStr});
            m = m(I);
            ind = find(ismember({m.nameStr},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('DeltaVFrameEnum');
            ind = find(ismember({m.nameStr},nameStr),1,'first');
            enum = m(ind);
        end
    end
end

