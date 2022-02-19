classdef PatternSearchUseMeshRotationEnum < matlab.mixin.SetGet
    %PatternSearchUseMeshRotationEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UseMeshRotation('Use Mesh Rotation',true)
        DoNotUseMeshRotation('Do Not Use Mesh Rotation',false);
    end
    
    properties
        name char = '';
        optionVal(1,1) logical = true
    end
    
    methods
        function obj = PatternSearchUseMeshRotationEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PatternSearchUseMeshRotationEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PatternSearchUseMeshRotationEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PatternSearchUseMeshRotationEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end