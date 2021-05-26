classdef ODE15sIntegrator < AbstractIntegrator
    %ODE23Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) BuiltInIntegratorOptions = BuiltInIntegratorOptions();
        integratorEnum = IntegratorEnum.ODE15s;
    end
    
    methods
        function obj = ODE15sIntegrator(options)
            if(nargin > 0)
                obj.options = options;
            else
                obj.options = BuiltInIntegratorOptions();
            end
        end
        
        function [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0, evtsFunc, odeOutputFun)
            odeSetOptions = obj.options.getIntegratorOptions();
            optionsToUse = odeset(odeSetOptions, 'Events',evtsFunc, 'OutputFcn',odeOutputFun);
            
            [t,y,te,ye,ie] = ode15s(odefun, tspan, y0, optionsToUse);
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
    end
end