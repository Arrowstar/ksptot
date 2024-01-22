classdef CompareAgainstEnum < matlab.mixin.SetGet
    %CompareAgainstEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        NumericConstant('Numeric Constant');
        GaTaskQuantity('Quantity');
    end

    properties
        name(1,1) string
    end

    methods
        function obj = CompareAgainstEnum(name)
            obj.name = name;
        end
    end

    methods(Static)
        function [listBoxStr, m] = getListBoxStr()
            m = enumeration('CompareAgainstEnum');
            [~,I] = sort([m.name]);
            listBoxStr = [m(I).name];
            m = m(I);
        end
    end
end