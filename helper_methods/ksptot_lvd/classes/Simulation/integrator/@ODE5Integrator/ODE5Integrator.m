classdef ODE5Integrator < AbstractFixedStepIntegrator
    %ODE5Integrator Summary of this class goes here
    %   Detailed explanation goes here
    
    methods
        function obj = ODE5Integrator()

        end
        
        function [t,y,te,ye,ie] = integrate(obj, odefun, tspan, y0)
            options = odeset(); %TODO remove when options are added in
            [t,y, te,ye,ie] = AbstractFixedStepIntegrator.integrate(odefun, tspan, y0, options);
        end
        
        function options = getOptions(obj)
            %TODO
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

