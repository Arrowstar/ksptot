classdef LvdSweepDistVariation < AbstractLvdSweepVariation
    %LvdSweepDistVariation A parameter varied by drawing from a distribution.
    %
    %   This is the Monte Carlo case, but it is deliberately usable in a full
    %   factorial run too: getGridValues discretizes the distribution at
    %   equally probable quantile midpoints, so a dispersed parameter can be
    %   crossed against gridded ones without a special case in the sampler.

    properties
        dist(1,1) AbstractLvdDistribution = LvdUniformDistribution(0, 1);
        numGridLevels(1,1) double {mustBePositive, mustBeInteger} = 5;
    end

    methods
        function obj = LvdSweepDistVariation(dist, numGridLevels)
            arguments
                dist(1,1) AbstractLvdDistribution = LvdUniformDistribution(0, 1);
                numGridLevels(1,1) double = 5;
            end

            obj.dist = dist;
            obj.numGridLevels = numGridLevels;

            obj.id = rand();
        end

        function values = getGridValues(obj)
            n = obj.numGridLevels;
            u = (((1:n) - 0.5)/n)';

            values = obj.dist.invCdf(u)';
        end

        function x = sampleFromUnit(obj, u)
            x = reshape(obj.dist.invCdf(u), size(u));
        end

        function tf = isGrid(~)
            tf = false;
        end

        function str = getSummaryStr(obj)
            str = obj.dist.getSummaryStr();
        end

        function [lb, ub] = getRange(obj)
            [lb, ub] = obj.dist.getSupport();

            if(not(isfinite(lb)) || not(isfinite(ub)))
                %an unbounded distribution has no plot range, so fall back on
                %a +/- 4 sigma window around the mean
                m = obj.dist.getMean();
                s = obj.dist.getStdDev();

                if(not(isfinite(lb)))
                    lb = m - 4*s;
                end

                if(not(isfinite(ub)))
                    ub = m + 4*s;
                end
            end
        end
    end
end
