classdef BuiltInGradientCalculationMethod < AbstractGradientCalculationMethod
    %BuiltInGradientCalculationMethod The build in method of FMINCON, etc
    %for computing gradients.
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        function obj = BuiltInGradientCalculationMethod()

        end
        
        function tf = useBuiltInMethod(obj)
            tf = true;
        end
        
        function g = computeGrad(fun, x0, fAtX0, useParallel)
            error('The builtin method for computing gradients should not call computeGrad()');
        end
    end
end