classdef(Abstract) AbstractGradientCalculationMethod < matlab.mixin.SetGet
    %AbstractGradientCalculationMethod Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        tf = useBuiltInMethod(obj);
        
        g = computeGrad(obj, fun, x0, fAtX0, useParallel);
        
        J = computeJacobian(obj, cFun, x0, cAtX0, useParallel);
        
        openOptionsDialog(obj)
    end
end

