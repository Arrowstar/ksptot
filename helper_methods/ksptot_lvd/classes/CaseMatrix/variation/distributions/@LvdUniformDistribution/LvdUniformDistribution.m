classdef LvdUniformDistribution < AbstractLvdDistribution
    %LvdUniformDistribution Uniform distribution on [lb, ub].

    properties
        lb(1,1) double = 0;
        ub(1,1) double = 1;
    end

    methods
        function obj = LvdUniformDistribution(lb, ub)
            arguments
                lb(1,1) double = 0;
                ub(1,1) double = 1;
            end

            obj.lb = lb;
            obj.ub = ub;
            obj.id = rand();
        end

        function x = invCdf(obj, u)
            x = obj.lb + u * (obj.ub - obj.lb);
        end

        function name = getTypeName(~)
            name = 'Uniform';
        end

        function str = getSummaryStr(obj)
            str = sprintf('Uniform [%.6g, %.6g]', obj.lb, obj.ub);
        end

        function names = getParamNames(~)
            names = {'Lower Bound', 'Upper Bound'};
        end

        function values = getParamValues(obj)
            values = [obj.lb, obj.ub];
        end

        function setParamValues(obj, values)
            obj.lb = values(1);
            obj.ub = values(2);
        end

        function [lb, ub] = getSupport(obj)
            lb = obj.lb;
            ub = obj.ub;
        end

        function m = getMean(obj)
            m = (obj.lb + obj.ub)/2;
        end

        function s = getStdDev(obj)
            s = (obj.ub - obj.lb)/sqrt(12);
        end
    end
end
