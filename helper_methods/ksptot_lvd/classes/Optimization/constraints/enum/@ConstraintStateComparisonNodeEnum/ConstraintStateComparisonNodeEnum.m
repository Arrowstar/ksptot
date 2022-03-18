classdef ConstraintStateComparisonNodeEnum < matlab.mixin.SetGet
    %ConstraintStateComparisonNodeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        InitialState('Initial State')
        FinalState('Final State');
    end
    
    properties
        name char = '';
    end
    
    methods
        function obj = ConstraintStateComparisonNodeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('ConstraintStateComparisonNodeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ConstraintStateComparisonNodeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ConstraintStateComparisonNodeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end