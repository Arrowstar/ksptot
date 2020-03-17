classdef GriddedInterpolantMethodEnum < matlab.mixin.SetGet
    %GriddedInterpolantMethodEnum Summary of this class goes here
    %   Detailed explanation goes here
    
    enumeration
        Linear('Linear Interpolation', 'linear')
        Nearest('Nearest Point', 'nearest')
        Next('Next Point', 'next')
        Previous('Previous Point', 'previous')
        PChip('Shape-Preserving Piecewise Cubic Interpolation', 'pchip')
        Makima('Modified Akima cubic Hermite Interpolation', 'makima')
        Spline('Cubic Spline Interpolation', 'spline')
    end
    
    properties
        name(1,:) char
        methodStr(1,:) char
    end
    
    methods
        function obj = GriddedInterpolantMethodEnum(name, methodStr)
            obj.name = name;
            obj.methodStr = methodStr;
        end
    end
    
    methods(Static)
        function listBoxStr = getListBoxStr()
            m = enumeration('GriddedInterpolantMethodEnum');
            [~,I] = sort({m.name});
            listBoxStr = {m(I).name};
        end
        
        function [ind, enum] = getIndForName(name)
            m = enumeration('GriddedInterpolantMethodEnum');
            [~,I] = sort({m.name});
            m = m(I);
            ind = find(ismember({m.name},name),1,'first');
            enum = m(ind);
        end
        
        function [enum, ind] = getEnumForListboxStr(nameStr)
            m = enumeration('GriddedInterpolantMethodEnum');
            ind = find(ismember({m.name},nameStr),1,'first');
            enum = m(ind);
        end
    end
end