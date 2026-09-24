classdef LvdSweepGridVariation < AbstractLvdSweepVariation
    %LvdSweepGridVariation An explicit list of levels between two bounds.
    %
    %   This is what the original case matrix did with every plugin variable
    %   it swept, including the "always include the upper bound even if the
    %   step does not land on it" rule, which is preserved here.

    properties
        lowerBnd(1,1) double = 0;
        upperBnd(1,1) double = 1;
        step(1,1) double = 1;
    end

    methods
        function obj = LvdSweepGridVariation(lowerBnd, upperBnd, step)
            arguments
                lowerBnd(1,1) double = 0;
                upperBnd(1,1) double = 1;
                step(1,1) double = 1;
            end

            obj.lowerBnd = lowerBnd;
            obj.upperBnd = upperBnd;
            obj.step = step;

            obj.id = rand();
        end

        function values = getGridValues(obj)
            if(obj.step == 0 || not(isfinite(obj.step)) || obj.upperBnd == obj.lowerBnd)
                values = unique([obj.lowerBnd, obj.upperBnd]);
                return;
            end

            lb = min([obj.lowerBnd, obj.upperBnd]);
            ub = max([obj.lowerBnd, obj.upperBnd]);

            values = unique([lb : abs(obj.step) : ub, ub]);
        end

        function x = sampleFromUnit(obj, u)
            %sampleFromUnit Draws uniformly from the levels.  A gridded
            %parameter in a random or Latin hypercube run is a discrete
            %factor, so u selects a level rather than interpolating between
            %them -- interpolating would produce values the user explicitly
            %chose not to include.
            values = obj.getGridValues();
            n = numel(values);

            idx = floor(min(max(u, 0), 1 - eps) * n) + 1;
            idx = min(max(idx, 1), n);

            x = reshape(values(idx), size(u));
        end

        function tf = isGrid(~)
            tf = true;
        end

        function str = getSummaryStr(obj)
            str = sprintf('Grid %.6g : %.6g : %.6g (%u levels)', ...
                          obj.lowerBnd, obj.step, obj.upperBnd, obj.getNumGridValues());
        end
    end
end
