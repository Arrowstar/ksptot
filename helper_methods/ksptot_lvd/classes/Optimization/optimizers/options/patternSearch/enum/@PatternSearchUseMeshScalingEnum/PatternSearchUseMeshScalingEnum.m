classdef PatternSearchUseMeshScalingEnum < matlab.mixin.SetGet
    %PatternSearchUseMeshScalingEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        UseMeshScaling('Use Mesh Scaling',true)
        DoNotUseMeshScaling('Do Not Use Mesh Scaling',false);
    end
    
    properties
        name char = '';
        optionVal(1,1) logical = true
    end
    
    methods
        function obj = PatternSearchUseMeshScalingEnum(name, optionVal)
            obj.name = name;
            obj.optionVal = optionVal;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('PatternSearchUseMeshScalingEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('PatternSearchUseMeshScalingEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('PatternSearchUseMeshScalingEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end