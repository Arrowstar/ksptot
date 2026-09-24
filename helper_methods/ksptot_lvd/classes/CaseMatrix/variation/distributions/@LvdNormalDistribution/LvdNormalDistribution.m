classdef LvdNormalDistribution < AbstractLvdDistribution
    %LvdNormalDistribution Normal distribution, optionally truncated.
    %
    %   Truncation matters for a dispersion run because plenty of dispersed
    %   quantities are physically one sided (a mass or a drag multiplier
    %   cannot go negative), and an untruncated normal will eventually
    %   produce a sample that makes the mission fail to propagate for a
    %   reason that has nothing to do with the trade being studied.

    properties
        mu(1,1) double = 0;
        sigma(1,1) double {mustBeNonnegative} = 1;

        truncate(1,1) logical = false;
        truncLb(1,1) double = -Inf;
        truncUb(1,1) double = Inf;
    end

    methods
        function obj = LvdNormalDistribution(mu, sigma, truncLb, truncUb)
            arguments
                mu(1,1) double = 0;
                sigma(1,1) double = 1;
                truncLb(1,1) double = -Inf;
                truncUb(1,1) double = Inf;
            end

            obj.mu = mu;
            obj.sigma = sigma;
            obj.truncLb = truncLb;
            obj.truncUb = truncUb;
            obj.truncate = isfinite(truncLb) || isfinite(truncUb);

            obj.id = rand();
        end

        function x = invCdf(obj, u)
            %invCdf Inverse standard normal CDF, scaled and shifted.
            %
            %   u of exactly 0 or 1 would map to -Inf/+Inf, which no caller
            %   can use, so the unit interval is nudged inside by eps.

            u = min(max(u, eps), 1 - eps);

            if(obj.truncate)
                fLb = obj.cdfUntruncated(obj.truncLb);
                fUb = obj.cdfUntruncated(obj.truncUb);

                if(fUb - fLb <= 0)
                    %degenerate truncation window: everything collapses onto
                    %the window itself
                    x = repmat(min(max(obj.mu, obj.truncLb), obj.truncUb), size(u));
                    return;
                end

                u = fLb + u * (fUb - fLb);
                u = min(max(u, eps), 1 - eps);
            end

            x = obj.mu + obj.sigma * sqrt(2) * erfinv(2*u - 1);

            if(obj.truncate)
                x = min(max(x, obj.truncLb), obj.truncUb);
            end
        end

        function p = cdfUntruncated(obj, x)
            %cdfUntruncated The plain normal CDF.  Public because the tests
            %use it as the round trip partner of invCdf.
            if(obj.sigma <= 0)
                p = double(x >= obj.mu);
                return;
            end

            p = 0.5 * (1 + erf((x - obj.mu)/(obj.sigma * sqrt(2))));
        end

        function name = getTypeName(~)
            name = 'Normal';
        end

        function str = getSummaryStr(obj)
            if(obj.truncate)
                str = sprintf('Normal (mu = %.6g, sigma = %.6g) truncated to [%.6g, %.6g]', ...
                              obj.mu, obj.sigma, obj.truncLb, obj.truncUb);
            else
                str = sprintf('Normal (mu = %.6g, sigma = %.6g)', obj.mu, obj.sigma);
            end
        end

        function names = getParamNames(~)
            names = {'Mean', 'Std Dev', 'Trunc Lower', 'Trunc Upper'};
        end

        function values = getParamValues(obj)
            values = [obj.mu, obj.sigma, obj.truncLb, obj.truncUb];
        end

        function setParamValues(obj, values)
            obj.mu = values(1);
            obj.sigma = values(2);

            if(numel(values) >= 4)
                obj.truncLb = values(3);
                obj.truncUb = values(4);
                obj.truncate = isfinite(values(3)) || isfinite(values(4));
            end
        end

        function [lb, ub] = getSupport(obj)
            if(obj.truncate)
                lb = obj.truncLb;
                ub = obj.truncUb;
            else
                lb = -Inf;
                ub = Inf;
            end
        end

        function m = getMean(obj)
            if(obj.truncate)
                m = getMean@AbstractLvdDistribution(obj);
            else
                m = obj.mu;
            end
        end

        function s = getStdDev(obj)
            if(obj.truncate)
                s = getStdDev@AbstractLvdDistribution(obj);
            else
                s = obj.sigma;
            end
        end
    end
end
