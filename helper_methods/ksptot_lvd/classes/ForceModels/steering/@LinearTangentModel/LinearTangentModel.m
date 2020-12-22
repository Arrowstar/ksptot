classdef LinearTangentModel < matlab.mixin.SetGet
    %LinearTangentModel Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        t0(1,1) double = 0;
        
        a(1,1) double = 0;
        a_dot(1,1) double = 0;
        
        b(1,1) double = 0;
        b_dot(1,1) double = 0;
    end
    
    methods
        function obj = LinearTangentModel(t0, a, a_dot, b, b_dot)
            obj.t0 = t0;
            
            obj.a = real(a);
            obj.a_dot = real(a_dot);
            
            obj.b = real(b);
            obj.b_dot = real(b_dot);
        end
        
        function value = getValueAtTime(obj,ut)
            dt = ut - obj.t0;
            
            a_value = obj.a + (obj.a_dot .* dt);
            b_value = obj.b + (obj.b_dot .* dt);
            value = atan(a_value .* dt + b_value);
        end
        
        function setBForContinuity(obj, contAngleValue)
            obj.b = tan(contAngleValue);
        end
        
        function newLinTanModel = deepCopy(obj)
            newLinTanModel = LinearTangentModel(obj.t0, obj.a, obj.a_dot, obj.b, obj.b_dot);
        end
    end
end