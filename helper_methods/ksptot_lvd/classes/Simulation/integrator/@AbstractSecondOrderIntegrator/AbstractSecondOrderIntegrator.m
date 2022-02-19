classdef(Abstract) AbstractSecondOrderIntegrator < AbstractIntegrator
    %AbstractSecondOrderIntegrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    methods
        [t,y,yp,te,ye,ype,ie] = integrate(obj, odefun, tspan, y0, yp0, evtsFunc, odeOutputFun)
    end
end