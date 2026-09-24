classdef SweepSamplerTest < KsptotTestCase
    %SweepSamplerTest LvdSweepSampler: the case matrix of a G1/G2 run.
    %
    % Two properties matter here and neither is obvious from reading the
    % code.  First, reproducibility: every sample is drawn on the client from
    % one seeded stream before a single case is dispatched, so a seeded run
    % must produce the same matrix no matter how many workers there are or
    % whether there is a pool at all.  Second, ordering: the full factorial
    % path replaced combvec (a Deep Learning Toolbox dependency) with an
    % ndgrid product, and it has to number the cases the same way combvec
    % did -- first parameter varying fastest -- or an existing case matrix
    % silently renumbers itself.
    %
    % The oracles are plain nested iteration (for the Cartesian product) and
    % direct counting of strata (for the Latin hypercube), so they cannot
    % share an implementation bug with ndgrid or randperm.

    methods(Test)

        function fullFactorialMatchesANestedIterationProductWithTheFirstParameterFastest(testCase)
            variations = [LvdSweepGridVariation(0, 2, 1), ...        % 0 1 2
                          LvdSweepGridVariation(10, 30, 10), ...     % 10 20 30
                          LvdSweepGridVariation(100, 200, 100)];     % 100 200

            [X, numCases] = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.FullFactorial);

            expected = refCartesianProduct({[0 1 2], [10 20 30], [100 200]});

            testCase.verifySize(X, [18 3], 'A 3 x 3 x 2 factorial must be 18 cases wide of 3 parameters');
            testCase.verifyEqual(numCases, 18, 'Reported case count must be the number of rows generated');
            testCase.verifyEqual(X, expected, 'AbsTol', 1e-12, ...
                'Full factorial rows do not match an independent Cartesian product');

            %Spell the ordering contract out: combvec(...)'  varied the first
            %argument fastest, and the second row here must therefore differ
            %from the first only in parameter 1.
            testCase.verifyEqual(X(1,:), [0 10 100], 'AbsTol', 1e-12);
            testCase.verifyEqual(X(2,:), [1 10 100], 'AbsTol', 1e-12, ...
                'The first parameter must vary fastest, as combvec did');
            testCase.verifyEqual(X(4,:), [0 20 100], 'AbsTol', 1e-12, ...
                'The second parameter must only advance once the first has wrapped');
            testCase.verifyEqual(X(end,:), [2 30 200], 'AbsTol', 1e-12);

            %Every combination appears exactly once.
            testCase.verifyEqual(size(unique(X, 'rows'), 1), 18, 'A factorial must not repeat a combination');

            testCase.verifyEqual(LvdSweepSampler.getNumCases(variations, LvdSweepSamplingEnum.FullFactorial), 18, ...
                'getNumCases must agree with the matrix the sampler actually builds');
        end

        function cartesianProductHandlesTheDegenerateWidths(testCase)
            %The GUI can ask for a preview before any parameter is added, and
            %a one parameter sweep is perfectly ordinary.  Both were literal
            %edge cases in combvec too.
            testCase.verifyEmpty(LvdSweepSampler.cartesianProduct({}), ...
                'No level vectors must produce an empty matrix, not an error');

            single = LvdSweepSampler.cartesianProduct({[5 6 7]});
            testCase.verifyEqual(single, [5; 6; 7], 'One parameter must produce one column of its levels');

            %Orientation must not matter: a level list may arrive as a row or
            %a column depending on which variation produced it.
            asColumns = LvdSweepSampler.cartesianProduct({[1; 2], [3; 4]});
            asRows = LvdSweepSampler.cartesianProduct({[1 2], [3 4]});
            testCase.verifyEqual(asColumns, asRows, 'Level vector orientation must not change the product');
            testCase.verifyEqual(asRows, [1 3; 2 3; 1 4; 2 4], 'AbsTol', 1e-12);

            %A single level parameter is a constant column, not a dropped one.
            withConstant = LvdSweepSampler.cartesianProduct({[1 2 3], 99});
            testCase.verifyEqual(withConstant, [1 99; 2 99; 3 99], 'AbsTol', 1e-12, ...
                'A one level parameter must survive as a constant column');
        end

        function fullFactorialCrossesGriddedAndDispersedParametersTogether(testCase)
            %A distribution answers getGridValues by discretizing at equally
            %probable midpoints, so it can be crossed against a grid without
            %the sampler special casing it.  U(0,10) with 3 levels gives the
            %1/6, 3/6, 5/6 quantiles.
            variations = [LvdSweepGridVariation(1, 2, 1), ...
                          LvdSweepDistVariation(LvdUniformDistribution(0, 10), 3)];

            X = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.FullFactorial);

            expected = refCartesianProduct({[1 2], 10*([1 3 5]/6)});
            testCase.verifyEqual(X, expected, 'RelTol', 1e-12, ...
                'A dispersed parameter in a full factorial must contribute its quantile midpoints');
            testCase.verifySize(X, [6 2]);
        end

        function emptyVariationSetProducesNoCases(testCase)
            [X, numCases] = LvdSweepSampler.generate(AbstractLvdSweepVariation.empty(1,0), ...
                                                     LvdSweepSamplingEnum.LatinHypercube, 50, 7);

            testCase.verifyEmpty(X, 'A run with no parameters must have no cases');
            testCase.verifyEqual(numCases, 0);
            testCase.verifyEqual(LvdSweepSampler.getNumCases(AbstractLvdSweepVariation.empty(1,0), ...
                                                             LvdSweepSamplingEnum.Random, 50), 0);
        end

        function latinHypercubePlacesExactlyOneSampleInEachStratumOfEachColumn(testCase)
            n = 200;
            p = 4;
            U = LvdSweepSampler.generateUnitMatrix(LvdSweepSamplingEnum.LatinHypercube, n, p, 12345);

            testCase.verifySize(U, [n p]);
            testCase.verifyTrue(all(U(:) > 0 & U(:) < 1), 'Unit draws must lie strictly inside (0, 1)');

            %The defining property: each column, cut into n equal probability
            %strata, holds exactly one sample per stratum.  Counting the
            %strata directly is the whole oracle -- no reimplementation of
            %the shuffle is needed or wanted.
            for(j = 1:p)
                stratum = floor(U(:,j)*n) + 1;
                testCase.verifyEqual(sort(stratum)', 1:n, ...
                    sprintf('Column %u is not a Latin hypercube: some stratum holds zero or two samples', j));
            end

            %The columns must be shuffled independently, otherwise every
            %parameter moves together and the design degenerates into a
            %diagonal line through the hypercube.
            R = refCorrelationMatrix(U);
            offDiag = R(not(eye(p, 'logical')));
            testCase.verifyLessThan(max(abs(offDiag)), 0.25, ...
                'Latin hypercube columns are correlated: the per-column permutations are not independent');

            %Plain random sampling must NOT be stratified -- if it were, the
            %two modes would be the same thing under different names.
            R2 = LvdSweepSampler.generateUnitMatrix(LvdSweepSamplingEnum.Random, n, 1, 12345);
            randStratumCounts = histcounts(floor(R2*n) + 1, 0.5:1:(n + 0.5));
            testCase.verifyGreaterThan(max(randStratumCounts), 1, ...
                'Random sampling should not be perfectly stratified; it appears to be a Latin hypercube');
        end

        function seedFullyDeterminesASampledRun(testCase)
            variations = [LvdSweepDistVariation(LvdNormalDistribution(5, 1), 5), ...
                          LvdSweepDistVariation(LvdUniformDistribution(0, 1), 5)];

            for(mode = [LvdSweepSamplingEnum.LatinHypercube, LvdSweepSamplingEnum.Random])
                a = LvdSweepSampler.generate(variations, mode, 40, 2026);
                b = LvdSweepSampler.generate(variations, mode, 40, 2026);
                c = LvdSweepSampler.generate(variations, mode, 40, 2027);

                testCase.verifyEqual(a, b, ...
                    sprintf('%s: the same seed must reproduce the same case matrix exactly', mode.name));
                testCase.verifyNotEqual(a, c, ...
                    sprintf('%s: a different seed must produce a different case matrix', mode.name));
            end

            %The client side stream must not be perturbed by the global one,
            %or a run would stop being reproducible the moment anything else
            %in the session called rand.
            rng(1);
            d = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.LatinHypercube, 40, 2026);
            rand(1, 17);
            e = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.LatinHypercube, 40, 2026);

            testCase.verifyEqual(d, e, ...
                'Sampling must come from its own RandStream, not the global stream');
        end

        function seedIsNormalizedSoAnyUserEntryIsUsable(testCase)
            %The GUI lets a seed be typed.  A negative or fractional entry
            %must be folded into a valid RandStream seed rather than erroring
            %halfway through building a 5000 case run.
            for(seed = [0, 1, 2.7, -12, 2^33 + 5])
                s = LvdSweepSampler.getRandStream(seed);
                testCase.verifyClass(s, 'RandStream', sprintf('Seed %g did not produce a stream', seed));
            end

            negative = LvdSweepSampler.getRandStream(-12);
            positive = LvdSweepSampler.getRandStream(12);
            testCase.verifyEqual(negative.Seed, positive.Seed, ...
                'A negative seed must fold onto its magnitude, not error');

            %A fresh seed for the Randomize button must be a plain
            %non-negative integer that the stream will accept.
            newSeed = LvdSweepSampler.getRandomSeed();
            testCase.verifyGreaterThanOrEqual(newSeed, 0);
            testCase.verifyEqual(newSeed, round(newSeed), 'A generated seed must be an integer');
            testCase.verifyClass(LvdSweepSampler.getRandStream(newSeed), 'RandStream');
        end

        function eachColumnIsTransformedByItsOwnVariation(testCase)
            %The column-to-parameter mapping is the part of the sampler that
            %a transpose would break invisibly: the matrix would still be the
            %right size and the run would still complete, having swept the
            %wrong parameters.  Give the two parameters disjoint supports so
            %a swap cannot hide.
            variations = [LvdSweepDistVariation(LvdUniformDistribution(0, 1), 5), ...
                          LvdSweepDistVariation(LvdUniformDistribution(1000, 1001), 5)];

            n = 30;
            X = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.LatinHypercube, n, 99);

            testCase.verifySize(X, [n 2]);
            testCase.verifyTrue(all(X(:,1) >= 0 & X(:,1) <= 1), 'Column 1 left the first parameter''s support');
            testCase.verifyTrue(all(X(:,2) >= 1000 & X(:,2) <= 1001), 'Column 2 left the second parameter''s support');

            %And the transform really is the inverse CDF of that column's
            %unit draws, in order.
            U = LvdSweepSampler.generateUnitMatrix(LvdSweepSamplingEnum.LatinHypercube, n, 2, 99);
            testCase.verifyEqual(X(:,1), variations(1).sampleFromUnit(U(:,1)), 'RelTol', 1e-14);
            testCase.verifyEqual(X(:,2), variations(2).sampleFromUnit(U(:,2)), 'RelTol', 1e-14);
        end

        function numSamplesIsHonouredForSampledModesAndIgnoredForFullFactorial(testCase)
            variations = [LvdSweepGridVariation(0, 3, 1), LvdSweepGridVariation(0, 1, 1)];

            [Xff, nff] = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.FullFactorial, 7, 1);
            testCase.verifyEqual(nff, 8, 'Full factorial case count is set by the grids, not by the sample count');
            testCase.verifySize(Xff, [8 2]);

            for(mode = [LvdSweepSamplingEnum.LatinHypercube, LvdSweepSamplingEnum.Random])
                [X, n] = LvdSweepSampler.generate(variations, mode, 7, 1);
                testCase.verifyEqual(n, 7, sprintf('%s must produce exactly the requested sample count', mode.name));
                testCase.verifySize(X, [7 2]);

                testCase.verifyEqual(LvdSweepSampler.getNumCases(variations, mode, 7), 7, ...
                    sprintf('%s: getNumCases must match what generate produces', mode.name));
            end

            %A nonsense sample count must degrade to one case rather than
            %producing a zero row matrix that the run loop would skip
            %entirely without saying why.
            [~, nZero] = LvdSweepSampler.generate(variations, LvdSweepSamplingEnum.Random, 0, 1);
            testCase.verifyEqual(nZero, 1, 'A requested sample count of zero must still run one case');
        end

        function fullFactorialModeIsRejectedByTheUnitHypercubeGenerator(testCase)
            %generateUnitMatrix exists so the sampling scheme can be checked
            %without a mission in the way; a full factorial has no unit
            %hypercube behind it and must say so rather than returning
            %something plausible.
            testCase.verifyError(@() LvdSweepSampler.generateUnitMatrix( ...
                                    LvdSweepSamplingEnum.FullFactorial, 10, 2, 0), ...
                'LvdSweepSampler:unsampledMode');
        end

        function samplingModeEnumRoundTripsThroughItsListboxStrings(testCase)
            %The GUI stores the sampling mode as the string in a dropdown and
            %converts it back on every read, so a duplicate or mistyped
            %display name would silently pin a run to the wrong mode.
            [listBoxStr, modes] = LvdSweepSamplingEnum.getListBoxStr();

            testCase.verifyNumElements(modes, 3, 'Expected exactly full factorial, Latin hypercube and random');
            testCase.verifyEqual(numel(unique(listBoxStr)), 3, 'Sampling mode display names must be distinct');
            testCase.verifyEqual(modes(1), LvdSweepSamplingEnum.FullFactorial, ...
                'Full factorial must stay first: it is the historical default');

            for(i = 1:numel(modes))
                [enum, ind] = LvdSweepSamplingEnum.getEnumForListboxStr(listBoxStr{i});
                testCase.verifyEqual(enum, modes(i), ...
                    sprintf('Sampling mode "%s" did not round trip through its display name', listBoxStr{i}));
                testCase.verifyEqual(ind, i, 'Round tripped index must match the listbox position');
            end

            testCase.verifyFalse(LvdSweepSamplingEnum.FullFactorial.usesNumSamples(), ...
                'A full factorial case count comes from the grids, so the sample count box must be disabled');
            testCase.verifyTrue(LvdSweepSamplingEnum.LatinHypercube.usesNumSamples());
            testCase.verifyTrue(LvdSweepSamplingEnum.Random.usesNumSamples());
        end

        function runModeEnumRoundTripsThroughItsListboxStrings(testCase)
            [listBoxStr, modes] = LvdCaseMatrixRunModeEnum.getListBoxStr();

            testCase.verifyNumElements(modes, 2, 'Expected exactly optimize and propagate only');
            testCase.verifyEqual(modes(1), LvdCaseMatrixRunModeEnum.Optimize, ...
                'Optimize must stay first: it is what every existing case matrix does');
            testCase.verifyEqual(numel(unique(listBoxStr)), 2, 'Run mode display names must be distinct');

            for(i = 1:numel(modes))
                testCase.verifyEqual(LvdCaseMatrixRunModeEnum.getEnumForListboxStr(listBoxStr{i}), modes(i), ...
                    sprintf('Run mode "%s" did not round trip through its display name', listBoxStr{i}));
            end
        end
    end
end

function R = refCorrelationMatrix(X)
    %refCorrelationMatrix Pearson correlation written out from the definition.
    %corr lives in the Statistics and Machine Learning Toolbox, and the point
    %of the sampler is that a dispersion run needs no such dependency -- the
    %test should not quietly reintroduce one.
    Xc = X - mean(X, 1);
    s = sqrt(sum(Xc.^2, 1));
    s(s == 0) = 1;

    Xn = Xc ./ s;
    R = Xn' * Xn;
end

function rows = refCartesianProduct(ranges)
    %refCartesianProduct Every combination of one element from each range, as
    %rows, with the first range varying fastest.  Plain nested iteration, so
    %it cannot share a bug with production's ndgrid based product (nor with
    %the combvec call that product replaced).
    rows = zeros(1, 0);
    for(i = 1:numel(ranges)) %#ok<*NO4LP>
        r = ranges{i};
        r = r(:);

        n = size(rows, 1);
        if(n == 0)
            rows = r;
        else
            rows = [repmat(rows, numel(r), 1), repelem(r, n, 1)]; %#ok<AGROW>
        end
    end
end
