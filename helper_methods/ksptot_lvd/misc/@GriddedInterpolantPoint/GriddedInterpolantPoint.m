classdef GriddedInterpolantPoint < matlab.mixin.SetGet
    %GriddedInterpolantPoint Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        x(1,1) double
        v(1,1) double
    end
    
    methods
        function obj = GriddedInterpolantPoint(x,v)
            obj.x = x;
            obj.v = v;
        end
        
        function str = getListboxStr(obj)
            str = sprintf('X = %0.3G; Y = %0.3G', obj.x, obj.v);
        end
    end
end