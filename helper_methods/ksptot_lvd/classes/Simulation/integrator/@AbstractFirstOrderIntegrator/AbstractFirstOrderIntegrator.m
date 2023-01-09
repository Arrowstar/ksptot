classdef(Abstract) AbstractFirstOrderIntegrator < AbstractIntegrator
    %AbstractFirstOrderIntegrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0, evtsFunc, odeOutputFun)
    end
end