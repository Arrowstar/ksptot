classdef LvdSweepSampler
    %LvdSweepSampler Turns a set of parameter variations into the matrix of
    %cases to run.
    %
    %   Every sample is generated here, on the client, before a single case
    %   is dispatched.  That is what makes a seeded run reproducible: the
    %   workers never touch a random stream, so the results do not depend on
    %   the pool size, the dispatch order, or whether there was a pool at
    %   all.
    %
    %   The random machinery is a single RandStream plus rand/randperm.  It
    %   deliberately does not use lhsdesign (Statistics and Machine Learning
    %   Toolbox) or combvec (Deep Learning Toolbox) -- the latter was a real
    %   dependency of the original case matrix, and dropping it means a
    %   sweep now runs on a stock LVD installation.

    methods(Static)
        function [X, numCases] = generate(variations, mode, numSamples, seed)
            %generate The N x P matrix of parameter values to run.
            %
            %   variations  1 x P heterogeneous AbstractLvdSweepVariation
            %   mode        LvdSweepSamplingEnum
            %   numSamples  N, ignored for full factorial
            %   seed        RandStream seed, ignored for full factorial

            arguments
                variations(1,:) AbstractLvdSweepVariation
                mode(1,1) LvdSweepSamplingEnum = LvdSweepSamplingEnum.FullFactorial;
                numSamples(1,1) double = 100;
                seed(1,1) double = 0;
            end

            if(isempty(variations))
                X = [];
                numCases = 0;
                return;
            end

            switch mode
                case LvdSweepSamplingEnum.FullFactorial
                    X = LvdSweepSampler.fullFactorial(variations);

                otherwise
                    U = LvdSweepSampler.generateUnitMatrix(mode, numSamples, numel(variations), seed);

                    X = NaN(size(U));
                    for(i = 1:numel(variations))
                        X(:,i) = variations(i).sampleFromUnit(U(:,i));
                    end
            end

            numCases = height(X);
        end

        function U = generateUnitMatrix(mode, numSamples, numParams, seed)
            %generateUnitMatrix The N x P matrix of uniform [0, 1] draws that
            %backs a sampled run.  Split out from generate so the sampling
            %scheme itself can be checked without any mission in the way.

            arguments
                mode(1,1) LvdSweepSamplingEnum
                numSamples(1,1) double
                numParams(1,1) double
                seed(1,1) double = 0;
            end

            N = max(round(numSamples), 1);
            P = max(round(numParams), 0);

            s = LvdSweepSampler.getRandStream(seed);

            switch mode
                case LvdSweepSamplingEnum.Random
                    U = rand(s, N, P);

                case LvdSweepSamplingEnum.LatinHypercube
                    %one draw inside each of the N equal probability strata,
                    %with the stratum order shuffled independently per column
                    U = NaN(N, P);
                    for(j = 1:P)
                        strata = randperm(s, N)';
                        U(:,j) = (strata - 1 + rand(s, N, 1))/N;
                    end

                otherwise
                    error('LvdSweepSampler:unsampledMode', ...
                          'Sampling mode "%s" does not draw from a unit hypercube.', mode.name);
            end
        end

        function X = fullFactorial(variations)
            %fullFactorial Cartesian product of the parameters' grid levels.
            %
            %   Ordering matches what combvec(...)' produced -- the first
            %   parameter varies fastest -- so an existing case matrix
            %   numbering is unchanged by the switch away from combvec.

            arguments
                variations(1,:) AbstractLvdSweepVariation
            end

            levels = cell(1, numel(variations));
            for(i = 1:numel(variations))
                levels{i} = variations(i).getGridValues();
            end

            X = LvdSweepSampler.cartesianProduct(levels);
        end

        function X = cartesianProduct(levels)
            %cartesianProduct Every combination of the given level vectors,
            %one combination per row, first vector varying fastest.
            %
            %   This is the combvec(levels{:})' replacement.  Kept separate
            %   from fullFactorial so the legacy plugin-variable-only entry
            %   point, which is handed plain numeric ranges rather than
            %   variation objects, shares the same ordering.

            arguments
                levels(1,:) cell
            end

            P = numel(levels);

            for(i = 1:P)
                v = levels{i};
                levels{i} = v(:)';
            end

            if(P == 0)
                X = [];
                return;
            end

            if(P == 1)
                X = levels{1}';
                return;
            end

            grids = cell(1, P);
            [grids{:}] = ndgrid(levels{:});

            X = NaN(numel(grids{1}), P);
            for(i = 1:P)
                X(:,i) = grids{i}(:);
            end
        end

        function numCases = getNumCases(variations, mode, numSamples)
            %getNumCases Case count without building the matrix, for the
            %"this run will be N cases" label in the GUI.

            arguments
                variations(1,:) AbstractLvdSweepVariation
                mode(1,1) LvdSweepSamplingEnum
                numSamples(1,1) double = 100;
            end

            if(isempty(variations))
                numCases = 0;
                return;
            end

            if(mode == LvdSweepSamplingEnum.FullFactorial)
                numCases = 1;
                for(i = 1:numel(variations))
                    numCases = numCases * variations(i).getNumGridValues();
                end
            else
                numCases = max(round(numSamples), 1);
            end
        end

        function s = getRandStream(seed)
            %getRandStream The one stream a sampled run is generated from.
            arguments
                seed(1,1) double = 0;
            end

            seed = mod(round(abs(seed)), 2^32);

            s = RandStream('twister', 'Seed', seed);
        end

        function seed = getRandomSeed()
            %getRandomSeed A fresh seed for the GUI's "Randomize" button.
            %Recorded in the results so the run can always be repeated.
            seed = randi([0, 2^31 - 1], 1, 1);
        end
    end
end
