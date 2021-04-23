classdef SteerMathModelTypeEnum < matlab.mixin.SetGet
    %SteerMathModelTypeEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        GenericPoly('Polynomial Euler Angles');
        SumOfSines('Sum of Sines');
        LinearTangent('Linear Tangent');
    end
    
    properties
        name(1,:) char
    end
    
    methods
        function obj = SteerMathModelTypeEnum(name)
            obj.name = name;
        end
    end
    
    methods(Static)
        function [listBoxStr, enums] = getListBoxStr()
            m = enumeration('SteerMathModelTypeEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
            enums = m(I);
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('SteerMathModelTypeEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('SteerMathModelTypeEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end