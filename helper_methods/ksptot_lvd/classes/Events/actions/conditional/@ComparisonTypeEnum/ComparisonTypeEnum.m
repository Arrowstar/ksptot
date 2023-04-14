classdef ComparisonTypeEnum < matlab.mixin.SetGet
    %ComparisonTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Equals('Equals', '==');
        GreaterThan('Greater Than', ">");
        LessThan('Less Than', '<');
        GreaterThanOrEquals('Greater Than Or Equals', '>=');
        LessThanOrEquals('Less Than Or Equals', '<=');
    end

    properties
        name(1,1) string
        symbol(1,1) string
    end

    methods
        function obj = ComparisonTypeEnum(name, symbol)
            obj.name = name;
            obj.symbol = symbol;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('ComparisonTypeEnum');
            [~,I] = sort([m.name]);
            listBoxStr = [m(I).name];
            m = m(I);
        end
    end
end