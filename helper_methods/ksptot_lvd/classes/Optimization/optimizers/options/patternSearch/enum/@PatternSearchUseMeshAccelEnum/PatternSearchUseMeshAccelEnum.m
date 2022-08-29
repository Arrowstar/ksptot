classdef PatternSearchUseMeshAccelEnum < matlab.mixin.SetGet
    %PatternSearchUseMeshAccelEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UseAccel('Use Mesh Acceleration',true)
        DoNotUseAccel('Do Not Use Mesh Acceleration',false);
    end
    
    properties
        name char = '';
        optionVal(1,1) logical = true
    end
    
    methods
        function obj = PatternSearchUseMeshAccelEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PatternSearchUseMeshAccelEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PatternSearchUseMeshAccelEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PatternSearchUseMeshAccelEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end