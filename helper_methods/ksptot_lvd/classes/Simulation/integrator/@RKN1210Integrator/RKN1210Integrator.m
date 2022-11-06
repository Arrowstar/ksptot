classdef RKN1210Integrator < AbstractSecondOrderIntegrator
    %RKN1210Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) BuiltInIntegratorOptions = BuiltInIntegratorOptions();
        integratorEnum = IntegratorEnum.RKN1210;
    end
    
    methods
        function obj = RKN1210Integrator(options)
            if(nargin > 0)
                obj.options = options;
            else
                obj.options = BuiltInIntegratorOptions();
            end
        end
        
        function [t,y,yp,te,ye,ype,ie] = integrate(obj, odefun, tspan, y0, yp0, evtsFunc, odeOutputFun)
            odeSetOptions = obj.options.getIntegratorOptions();
            optionsToUse = odeset(odeSetOptions, 'Events',evtsFunc, 'OutputFcn',odeOutputFun);
            
            [t,y,yp,te,ye,ype,ie] = rkn1210(odefun, tspan, y0, yp0, optionsToUse);

            if(not(isempty(te)))
                bool = t == te;
                if(any(bool))
                    inds = 1 : find(bool,1,'first');

                    t = t(inds);
                    y = y(inds, :);
                    yp = yp(inds, :);
                end
            end
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
    end
end