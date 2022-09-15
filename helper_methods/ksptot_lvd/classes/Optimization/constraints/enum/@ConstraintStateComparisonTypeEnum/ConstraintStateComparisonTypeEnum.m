classdef ConstraintStateComparisonTypeEnum < matlab.mixin.SetGet
    %ConstraintEvalTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Equals('Equals', '==')
        GreaterThan('Greater Than', '>=');
        LessThan('Less Than', '<=');
    end
    
    properties
        name char = '';
        symbol char = '';
    end
    
    methods
        function obj = ConstraintStateComparisonTypeEnum(name, symbol)
            obj.name = name;
            obj.symbol = symbol;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('ConstraintStateComparisonTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('ConstraintStateComparisonTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('ConstraintStateComparisonTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end