classdef ODE5Integrator < AbstractFixedStepIntegrator
    %ODE5Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        options(1,1) FixedStepSizeIntegratorOptions = FixedStepSizeIntegratorOptions()
        integratorEnum = IntegratorEnum.ODE5;
    end
    
    methods
        function obj = ODE5Integrator(options)
            if(nargin > 0)
                obj.options = options;
            else
                obj.options = FixedStepSizeIntegratorOptions();
            end
        end
        
        function [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0, evtsFunc, odeOutputFun)
%             odeSetOptions = obj.options.getIntegratorOptions();
            odeSetOptions = odeset();
            optionsToUse = odeset(odeSetOptions, 'Events',evtsFunc, 'OutputFcn',odeOutputFun);
            
            [t,y, te,ye,ie] = AbstractFixedStepIntegrator.integrate(odefun, tspan, y0, optionsToUse);
        end
        
        function options = getOptions(obj)
            options = obj.options;
        end
    end
    
    methods(Static,Access=protected)
        function [A,B,C] = getButcherTableauData()
            A = [  1/5,          0,           0,            0,         0
                   3/40,         9/40,        0,            0,         0
                   44/45        -56/15,       32/9,         0,         0
                   19372/6561,  -25360/2187,  64448/6561,  -212/729,   0
                   9017/3168,   -355/33,      46732/5247,   49/176,   -5103/18656];
        
            B = [35/384, 0, 500/1113, 125/192, -2187/6784, 11/84];

            C = [1/5; 3/10; 4/5; 8/9; 1];
            
            A = A.';
            B = B(:);
            C = C(:);
        end
    end
end

