classdef ConditionalTypeEnum < matlab.mixin.SetGet
    %ConditionalTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        QuantityComparison('Quantity Comparison');
        AlwaysTrue('Always True');
        AlwaysFalse('Always False');
        LogicalAnd('Logical And');
        LogicalOr('Logical Or');
    end

    properties
        name(1,1) string
    end

    methods
        function obj = ConditionalTypeEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('ConditionalTypeEnum');
            [~,I] = sort([m.name]);
            listBoxStr = [m(I).name];
            m = m(I);
        end
    end
end