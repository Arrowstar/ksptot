classdef LvdTriangularDistribution < AbstractLvdDistribution
    %LvdTriangularDistribution Triangular distribution on [a, b] peaking at c.
    %
    %   The usual stand in when all that is known about a dispersed quantity
    %   is a best estimate and a worst case in each direction, which is the
    %   normal state of affairs for a vehicle knob early in a design.

    properties
        a(1,1) double = 0;      %lower limit
        c(1,1) double = 0.5;    %mode (peak)
        b(1,1) double = 1;      %upper limit
    end

    methods
        function obj = LvdTriangularDistribution(a, c, b)
            arguments
                a(1,1) double = 0;
                c(1,1) double = 0.5;
                b(1,1) double = 1;
            end

            obj.a = a;
            obj.c = c;
            obj.b = b;

            obj.id = rand();
        end

        function x = invCdf(obj, u)
            %invCdf Closed form inverse of the triangular CDF.
            %
            %   F(c) = (c - a)/(b - a) splits the unit interval between the
            %   rising and falling legs.

            lo = min([obj.a, obj.b]);
            hi = max([obj.a, obj.b]);
            pk = min(max(obj.c, lo), hi);

            if(hi - lo <= 0)
                x = repmat(lo, size(u));
                return;
            end

            u = min(max(u, 0), 1);
            fc = (pk - lo)/(hi - lo);

            x = zeros(size(u));

            risingTf = u < fc;
            x(risingTf) = lo + sqrt(u(risingTf) * (hi - lo) * (pk - lo));

            fallingTf = not(risingTf);
            x(fallingTf) = hi - sqrt((1 - u(fallingTf)) * (hi - lo) * (hi - pk));
        end

        function name = getTypeName(~)
            name = 'Triangular';
        end

        function str = getSummaryStr(obj)
            str = sprintf('Triangular (min = %.6g, mode = %.6g, max = %.6g)', obj.a, obj.c, obj.b);
        end

        function names = getParamNames(~)
            names = {'Minimum', 'Mode', 'Maximum'};
        end

        function values = getParamValues(obj)
            values = [obj.a, obj.c, obj.b];
        end

        function setParamValues(obj, values)
            obj.a = values(1);
            obj.c = values(2);
            obj.b = values(3);
        end

        function [lb, ub] = getSupport(obj)
            lb = min([obj.a, obj.b]);
            ub = max([obj.a, obj.b]);
        end

        function m = getMean(obj)
            m = (obj.a + obj.b + obj.c)/3;
        end

        function s = getStdDev(obj)
            lo = min([obj.a, obj.b]);
            hi = max([obj.a, obj.b]);
            pk = min(max(obj.c, lo), hi);

            s = sqrt((lo^2 + hi^2 + pk^2 - lo*hi - lo*pk - hi*pk)/18);
        end
    end
end
