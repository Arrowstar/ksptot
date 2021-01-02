classdef ODE113Integrator < AbstractIntegrator
    %ODE45Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) BuiltInIntegratorOptions = BuiltInIntegratorOptions();
        integratorEnum = IntegratorEnum.ODE113;
    end
    
    methods
        function obj = ODE113Integrator(options)
            if(nargin > 0)
                obj.options = options;
            else
                obj.options = BuiltInIntegratorOptions();
            end
        end
        
        function [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0, evtsFunc, odeOutputFun)
            odeSetOptions = obj.options.getIntegratorOptions();
            optionsToUse = odeset(odeSetOptions, 'Events',evtsFunc, 'OutputFcn',odeOutputFun);
            
            [t,y,te,ye,ie] = ode113(odefun, tspan, y0, optionsToUse);
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
    end
end

%     use for implicit integration in the future.
%             evtsFunc = @(t,y,yp) ODE113Integrator.odeEventsImp(t,y,yp, evtsFunc);
%
%             yp0 = odefun(tspan(1), y0(:));
%             odefun = @(t,y,yp) ODE113Integrator.odeFuncImp(t,y,yp, odefun);
%             [t,y,te,ye,ie] = ode15i(odefun, tspan, y0, yp0, optionsToUse);
%     methods(Static)
%         function ydot = odeFuncImp(t,y,~, odefun)
%             ydot = odefun(t,y);
%         end
%         
%         function [value,isterminal,direction] = odeEventsImp(t,y,~, evtsFunc)
%             [value,isterminal,direction] = evtsFunc(t,y);
%         end
%     end