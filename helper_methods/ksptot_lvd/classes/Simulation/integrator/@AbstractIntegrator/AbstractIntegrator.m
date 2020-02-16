classdef(Abstract) AbstractIntegrator < matlab.mixin.SetGet
    %AbstractIntegrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0)
        
        options = getOptions(obj)
    end
end