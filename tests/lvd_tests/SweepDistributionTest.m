classdef SweepDistributionTest < KsptotTestCase
    %SweepDistributionTest The dispersion distributions behind G1/G2.
    %
    % Every distribution is sampled by the inverse CDF method, so the inverse
    % CDF is the whole contract: get it wrong and a Monte Carlo run produces
    % numbers that look perfectly plausible and are silently from the wrong
    % population.  Production writes the inverses in closed form on base
    % MATLAB (erfinv for the normal, the two-leg square root for the
    % triangular) rather than calling the Statistics Toolbox's icdf, so the
    % oracles here are built the other way round: the CDF is written out and
    % inverted by bisection, plus a short table of standard normal quantiles
    % that does not come from MATLAB at all.

    properties(Constant)
        %Standard normal quantiles to 15 digits, from the published inverse
        %normal CDF.  These are the "does erfinv mean what we think it
        %means" anchor -- a bisection oracle on erf would share erf's
        %scaling convention with production, a table does not.
        StdNormalU = [0.5, 0.75, 0.84134474606854293, 0.95, 0.975, 0.99, 0.9986501019683699];
        StdNormalZ = [0.0, 0.674489750196082, 1.0, 1.644853626951472, 1.959963984540054, 2.326347874040841, 3.0];
    end

    methods(Test)

        function uniformInverseCdfIsTheAffineMapOntoItsBounds(testCase)
            lb = -3.25;
            ub = 11.75;
            dist = LvdUniformDistribution(lb, ub);

            u = [0; 0.25; 0.5; 0.5423; 1];
            testCase.verifyEqual(dist.invCdf(u), lb + u*(ub - lb), 'RelTol', 1e-14, ...
                'Uniform inverse CDF must be the affine map from [0,1] onto [lb,ub]');

            testCase.verifyEqual(dist.invCdf(0), lb, 'AbsTol', 1e-14, 'u = 0 must map to the lower bound');
            testCase.verifyEqual(dist.invCdf(1), ub, 'AbsTol', 1e-14, 'u = 1 must map to the upper bound');

            [sLb, sUb] = dist.getSupport();
            testCase.verifyEqual([sLb, sUb], [lb, ub], 'Support must be the bounds');

            %Closed form moments, checked against the definition rather than
            %against a second closed form.
            testCase.verifyEqual(dist.getMean(), (lb + ub)/2, 'RelTol', 1e-14);
            testCase.verifyEqual(dist.getStdDev(), (ub - lb)/sqrt(12), 'RelTol', 1e-14);
        end

        function normalInverseCdfMatchesPublishedStandardNormalQuantiles(testCase)
            mu = 7.5;
            sigma = 2.25;
            dist = LvdNormalDistribution(mu, sigma);

            u = testCase.StdNormalU(:);
            expected = mu + sigma*testCase.StdNormalZ(:);

            testCase.verifyEqual(dist.invCdf(u), expected, 'RelTol', 1e-12, ...
                'Normal inverse CDF does not reproduce the published standard normal quantiles');

            %Symmetry about the mean: u and 1-u must be mirror images.  A
            %sign or factor-of-two slip in the erfinv argument survives a
            %median check but not this one.
            uLow = 1 - u;
            testCase.verifyEqual(dist.invCdf(uLow) - mu, -(dist.invCdf(u) - mu), 'RelTol', 1e-12, 'AbsTol', 1e-12, ...
                'Normal inverse CDF must be antisymmetric about the mean');

            testCase.verifyEqual(dist.getMean(), mu, 'RelTol', 1e-14, 'Untruncated normal mean must be mu');
            testCase.verifyEqual(dist.getStdDev(), sigma, 'RelTol', 1e-14, 'Untruncated normal std dev must be sigma');

            [sLb, sUb] = dist.getSupport();
            testCase.verifyEqual([sLb, sUb], [-Inf, Inf], 'An untruncated normal has unbounded support');
        end

        function normalRoundTripsThroughItsOwnCdf(testCase)
            dist = LvdNormalDistribution(-4, 0.75);

            %invCdf(cdf(x)) == x over a wide range of x.  Round tripping a
            %quantile through the CDF is the strongest statement available
            %without a second implementation: the two are inverses or they
            %are not.
            x = (-4 + 0.75*(-4:0.5:4))';
            u = dist.cdfUntruncated(x);

            testCase.verifyTrue(all(u > 0 & u < 1), 'Fixture broken: the CDF saturated over the test range');
            testCase.verifyEqual(dist.invCdf(u), x, 'RelTol', 1e-10, 'AbsTol', 1e-10, ...
                'invCdf(cdf(x)) must return x');

            %And the other way: cdf(invCdf(u)) == u.
            u2 = (0.001:0.001:0.999)';
            testCase.verifyEqual(dist.cdfUntruncated(dist.invCdf(u2)), u2, 'AbsTol', 1e-12, ...
                'cdf(invCdf(u)) must return u');

            %Monotone and finite at the clamped ends: a caller must never be
            %handed +/-Inf, which would blow up any parameter it was applied to.
            testCase.verifyTrue(all(isfinite(dist.invCdf([0; 1]))), ...
                'u of exactly 0 or 1 must be nudged inside the unit interval, not mapped to +/-Inf');
            testCase.verifyTrue(all(diff(dist.invCdf((0:0.01:1)')) > 0), 'Inverse CDF must be strictly increasing');
        end

        function truncatedNormalStaysInsideItsWindowAndRescalesTheQuantiles(testCase)
            mu = 1.0;
            sigma = 0.5;
            lo = 0.4;
            hi = 1.9;
            dist = LvdNormalDistribution(mu, sigma, lo, hi);

            testCase.verifyTrue(dist.truncate, 'Finite truncation limits must switch truncation on');

            u = (0:0.02:1)';
            x = dist.invCdf(u);

            testCase.verifyTrue(all(x >= lo - 1e-12 & x <= hi + 1e-12), ...
                'A truncated normal must never produce a sample outside its window');
            testCase.verifyTrue(all(diff(x) >= -1e-12), 'The truncated inverse CDF must still be non-decreasing');

            %Oracle: the truncated quantile is the untruncated quantile of
            %the rescaled probability F(lo) + u*(F(hi) - F(lo)).  Computed
            %here from a bisection on the plain normal CDF so it does not
            %reuse production's erfinv path.
            fLo = refNormalCdf(lo, mu, sigma);
            fHi = refNormalCdf(hi, mu, sigma);
            uTest = [0.05; 0.25; 0.5; 0.75; 0.95];
            expected = arrayfun(@(p) refInvertByBisection(@(z) refNormalCdf(z, mu, sigma), ...
                                                          fLo + p*(fHi - fLo), mu - 20*sigma, mu + 20*sigma), uTest);

            testCase.verifyEqual(dist.invCdf(uTest), expected, 'RelTol', 1e-9, 'AbsTol', 1e-9, ...
                'Truncated normal quantiles must be the rescaled untruncated quantiles');

            %The truncated moments are no longer mu and sigma.  This window
            %is asymmetric -- it cuts at -1.2 sigma but only at +1.8 sigma --
            %so removing more of the low tail must push the mean above mu.
            testCase.verifyGreaterThan(dist.getMean(), mu, ...
                'A window that cuts more off the low side must push the mean up');
            testCase.verifyLessThan(dist.getStdDev(), sigma, 'Truncation must shrink the standard deviation');

            [sLb, sUb] = dist.getSupport();
            testCase.verifyEqual([sLb, sUb], [lo, hi], 'A truncated normal reports its window as its support');
        end

        function oneSidedTruncationIsStillTruncation(testCase)
            %The physically common case: a mass or a drag multiplier that
            %cannot go negative but has no upper limit.
            dist = LvdNormalDistribution(1, 0.5, 0, Inf);

            testCase.verifyTrue(dist.truncate, 'A single finite limit must still switch truncation on');

            x = dist.invCdf((0:0.01:1)');
            testCase.verifyTrue(all(x >= 0), 'A lower-truncated normal must never go below its limit');
            testCase.verifyTrue(all(isfinite(x)), 'The open end must still be clamped to a finite value');
            testCase.verifyGreaterThan(dist.getMean(), 1, ...
                'Cutting off the lower tail must push the mean above mu');
        end

        function degenerateTruncationWindowCollapsesOntoItself(testCase)
            %A user can type a window with the bounds the wrong way round.
            %That must produce a constant, not NaN quietly poisoning a run.
            dist = LvdNormalDistribution(0, 1, 2, 1);

            x = dist.invCdf((0:0.25:1)');
            testCase.verifyTrue(all(isfinite(x)), 'An inverted truncation window must not produce NaN or Inf');
            testCase.verifyEqual(x, repmat(x(1), size(x)), 'A degenerate window must collapse to a constant');
        end

        function triangularInverseCdfInvertsTheTriangularCdf(testCase)
            a = 2;
            c = 3.5;
            b = 9;
            dist = LvdTriangularDistribution(a, c, b);

            u = (0.001:0.001:0.999)';
            x = dist.invCdf(u);

            testCase.verifyTrue(all(x >= a - 1e-12 & x <= b + 1e-12), 'Triangular samples must stay inside [a, b]');
            testCase.verifyTrue(all(diff(x) >= 0), 'The triangular inverse CDF must be non-decreasing');

            %Round trip against the CDF written out independently.
            testCase.verifyEqual(refTriangularCdf(x, a, c, b), u, 'AbsTol', 1e-12, ...
                'cdf(invCdf(u)) must return u for the triangular distribution');

            %The mode splits the unit interval at F(c) = (c-a)/(b-a).  A leg
            %swap would be invisible at the ends and obvious here.
            fc = (c - a)/(b - a);
            testCase.verifyEqual(dist.invCdf(fc), c, 'AbsTol', 1e-9, 'u = F(c) must map exactly onto the mode');
            testCase.verifyLessThan(dist.invCdf(fc - 1e-6), c, 'Just below F(c) must land on the rising leg');
            testCase.verifyGreaterThan(dist.invCdf(fc + 1e-6), c, 'Just above F(c) must land on the falling leg');

            testCase.verifyEqual(dist.invCdf(0), a, 'AbsTol', 1e-12);
            testCase.verifyEqual(dist.invCdf(1), b, 'AbsTol', 1e-12);

            %Closed form moments against the definition.
            testCase.verifyEqual(dist.getMean(), (a + b + c)/3, 'RelTol', 1e-14);
            testCase.verifyEqual(dist.getStdDev(), ...
                sqrt((a^2 + b^2 + c^2 - a*b - a*c - b*c)/18), 'RelTol', 1e-14);
        end

        function triangularHandlesTheRightTriangleAndZeroWidthEdgeCases(testCase)
            %Mode on a limit makes one leg vanish.  The square root of a zero
            %product is the place a naive implementation divides by zero.
            rising = LvdTriangularDistribution(0, 1, 1);
            x = rising.invCdf((0:0.05:1)');
            testCase.verifyTrue(all(isfinite(x)), 'A right triangle must not produce NaN');
            testCase.verifyTrue(all(x >= 0 & x <= 1));
            testCase.verifyEqual(refTriangularCdf(x, 0, 1, 1), (0:0.05:1)', 'AbsTol', 1e-12);

            falling = LvdTriangularDistribution(0, 0, 1);
            x = falling.invCdf((0:0.05:1)');
            testCase.verifyTrue(all(isfinite(x)));
            testCase.verifyEqual(refTriangularCdf(x, 0, 0, 1), (0:0.05:1)', 'AbsTol', 1e-12);

            degenerate = LvdTriangularDistribution(4, 4, 4);
            testCase.verifyEqual(degenerate.invCdf((0:0.25:1)'), repmat(4, 5, 1), ...
                'A zero width triangular must return its single point');
        end

        function inverseCdfPreservesTheShapeOfItsInput(testCase)
            %The sampler hands whole columns in and writes whole columns out,
            %and the variation wrapper reshapes to match.  A distribution
            %that quietly transposed would produce a matrix where a column
            %was expected and take the case count with it.
            dists = AbstractLvdDistribution.getAllDistributionTypes();

            for(i = 1:numel(dists))
                d = dists(i);
                msg = sprintf('%s did not preserve the shape of its input', d.getTypeName());

                testCase.verifySize(d.invCdf((0.1:0.1:0.9)'), [9 1], msg);
                testCase.verifySize(d.invCdf(0.1:0.1:0.9), [1 9], msg);
                testCase.verifySize(d.invCdf(0.5), [1 1], msg);
            end
        end

        function sampleMeanAndStdDevConvergeOnTheDistributionMoments(testCase)
            %Not a test of MATLAB's RNG: a test that invCdf maps the uniform
            %stream onto the population it claims.  A Latin hypercube over
            %the same inverse CDF converges far faster than plain sampling,
            %which is exactly why the sweep engine offers it.
            dists = {LvdUniformDistribution(-2, 6), ...
                     LvdNormalDistribution(10, 3), ...
                     LvdTriangularDistribution(0, 4, 5)};

            n = 20000;
            u = LvdSweepSampler.generateUnitMatrix(LvdSweepSamplingEnum.LatinHypercube, n, 1, 20260921);

            for(i = 1:numel(dists))
                d = dists{i};
                x = d.invCdf(u);

                testCase.verifyEqual(mean(x), d.getMean(), 'RelTol', 5e-3, 'AbsTol', 5e-3, ...
                    sprintf('%s sample mean did not converge on the reported mean', d.getTypeName()));
                testCase.verifyEqual(std(x, 1), d.getStdDev(), 'RelTol', 5e-3, ...
                    sprintf('%s sample std dev did not converge on the reported std dev', d.getTypeName()));
            end
        end

        function truncatedNormalMomentsMatchTheClosedFormTruncatedMoments(testCase)
            %A truncated normal is the one distribution with no closed form
            %in production: it falls back on AbstractLvdDistribution's
            %quadrature of the inverse CDF.  That fallback is what the GUI
            %shows next to a dispersion definition and what the statistics
            %view compares a sample against, so check it against the
            %published truncated normal moments rather than trusting it.
            mu = 2;
            sigma = 1.5;
            lo = 0.5;
            hi = 4.0;
            dist = LvdNormalDistribution(mu, sigma, lo, hi);

            alpha = (lo - mu)/sigma;
            beta  = (hi - mu)/sigma;
            phi = @(z) exp(-0.5*z.^2)/sqrt(2*pi);
            Z = refNormalCdf(hi, mu, sigma) - refNormalCdf(lo, mu, sigma);

            expMean = mu + sigma*(phi(alpha) - phi(beta))/Z;
            expVar  = sigma^2 * (1 + (alpha*phi(alpha) - beta*phi(beta))/Z - ((phi(alpha) - phi(beta))/Z)^2);

            testCase.verifyEqual(dist.getMean(), expMean, 'RelTol', 5e-3, ...
                'Truncated normal mean disagrees with the closed form truncated mean');
            testCase.verifyEqual(dist.getStdDev(), sqrt(expVar), 'RelTol', 5e-3, ...
                'Truncated normal std dev disagrees with the closed form truncated std dev');
        end

        function parameterVectorsRoundTripThroughTheGenericEditor(testCase)
            %The GUI edits any distribution through getParamNames /
            %getParamValues / setParamValues without knowing its type.  A
            %mismatch in the order or the count silently writes the wrong
            %field -- a std dev into a mean, say.
            dists = AbstractLvdDistribution.getAllDistributionTypes();

            %Each perturbation is finite and keeps the distribution valid, so
            %the read-back can be compared numerically without an Inf in it.
            perturbations = {[-1, 2], [0.5, 1.5, -3, 3], [-1, 0.5, 2]};

            for(i = 1:numel(dists))
                d = dists(i);
                names = d.getParamNames();
                values = d.getParamValues();

                testCase.verifyEqual(numel(names), numel(values), ...
                    sprintf('%s reports %u parameter names for %u values', ...
                            d.getTypeName(), numel(names), numel(values)));

                perturbed = perturbations{i};
                testCase.assertEqual(numel(perturbed), numel(values), ...
                    sprintf('Fixture broken: no perturbation of the right width for %s', d.getTypeName()));

                d.setParamValues(perturbed);
                testCase.verifyEqual(d.getParamValues(), perturbed, 'RelTol', 1e-14, ...
                    sprintf('%s did not read back the parameter vector it was given', d.getTypeName()));
            end

            %Setting finite truncation limits through the generic editor must
            %switch truncation on: the GUI never touches the flag directly.
            n = LvdNormalDistribution(0, 1);
            testCase.verifyFalse(n.truncate, 'Fixture broken: a plain normal should start untruncated');
            n.setParamValues([0, 1, -2, 2]);
            testCase.verifyTrue(n.truncate, 'Finite limits written through setParamValues must enable truncation');
            testCase.verifyTrue(all(abs(n.invCdf((0:0.1:1)')) <= 2 + 1e-12), ...
                'The truncation written through the generic editor must actually bound the samples');
        end

        function factoryBuildsEachTypeAroundTheNominalValue(testCase)
            nominal = 40;

            for(typeName = {'Uniform', 'Normal', 'Triangular'})
                d = AbstractLvdDistribution.createByTypeName(typeName{1}, nominal);

                testCase.verifyEqual(d.getTypeName(), typeName{1});
                testCase.verifyEqual(d.getMean(), nominal, 'RelTol', 1e-9, ...
                    sprintf('A default %s around %g should be centred on it', typeName{1}, nominal));
                testCase.verifyGreaterThan(d.getStdDev(), 0, ...
                    sprintf('A default %s must have a non-zero spread', typeName{1}));
            end

            %A nominal value of zero cannot scale its spread by a percentage,
            %so the fallback spread must still give a usable distribution.
            zeroed = AbstractLvdDistribution.createByTypeName('Normal', 0);
            testCase.verifyGreaterThan(zeroed.getStdDev(), 0, ...
                'A distribution defaulted around zero must not collapse to a point');

            testCase.verifyError(@() AbstractLvdDistribution.createByTypeName('Weibull', 1), ...
                'LvdDistribution:unknownType', 'An unknown type name must error, not return an empty');
        end

        function distributionsCarryDistinctIdentitiesAndSurviveCloning(testCase)
            %Parameters rebind to their targets by id after the sweep engine
            %byte-stream clones a mission onto a worker, and distributions
            %follow the same rule.
            a = LvdNormalDistribution(0, 1);
            b = LvdNormalDistribution(0, 1);

            testCase.verifyNotEqual(a.id, b.id, 'Two distributions must not share an id');
            testCase.verifyTrue(a == a, 'A distribution must equal itself');
            testCase.verifyFalse(a == b, 'Distinct distributions must not compare equal');

            clone = getArrayFromByteStream(getByteStreamFromArray(a));
            testCase.verifyNotSameHandle(clone, a, 'Fixture broken: the clone is the same handle');
            testCase.verifyTrue(clone == a, 'A byte-stream clone must keep its id so it can be rebound');
            testCase.verifyEqual(clone.invCdf(0.3), a.invCdf(0.3), 'RelTol', 1e-14, ...
                'A clone must sample identically to its original');
        end

        function gridVariationKeepsItsUpperBoundAndSamplesOnlyItsLevels(testCase)
            v = LvdSweepGridVariation(0, 10, 3);

            %The original case matrix always appended the upper bound even
            %when the step did not land on it; losing that would quietly drop
            %the boundary case from every sweep.
            testCase.verifyEqual(v.getGridValues(), [0 3 6 9 10], 'AbsTol', 1e-12, ...
                'A grid must include its upper bound even when the step overshoots it');
            testCase.verifyEqual(v.getNumGridValues(), 5);
            testCase.verifyTrue(v.isGrid());

            exact = LvdSweepGridVariation(0, 10, 5);
            testCase.verifyEqual(exact.getGridValues(), [0 5 10], 'AbsTol', 1e-12, ...
                'A step that lands on the upper bound must not duplicate it');

            %Reversed bounds and a negative step are user typos, not errors.
            reversed = LvdSweepGridVariation(10, 0, -5);
            testCase.verifyEqual(reversed.getGridValues(), [0 5 10], 'AbsTol', 1e-12, ...
                'Reversed bounds and a negative step must still produce the ascending grid');

            degenerate = LvdSweepGridVariation(4, 4, 1);
            testCase.verifyEqual(degenerate.getGridValues(), 4, 'A zero width grid is a single level');

            zeroStep = LvdSweepGridVariation(0, 10, 0);
            testCase.verifyEqual(zeroStep.getGridValues(), [0 10], 'AbsTol', 1e-12, ...
                'A zero step must fall back on the two endpoints rather than hang');

            %In a sampled run a grid parameter is a discrete factor: u picks
            %a level.  Interpolating would produce values the user chose not
            %to include.
            u = (0:0.001:1)';
            x = v.sampleFromUnit(u);
            testCase.verifyTrue(all(ismember(x, v.getGridValues())), ...
                'Sampling a grid variation must only ever return one of its levels');
            testCase.verifyEqual(numel(unique(x)), 5, 'Every level must be reachable');
            testCase.verifySize(x, size(u), 'sampleFromUnit must preserve the shape of u');
        end

        function distVariationDiscretizesAtEquallyProbableMidpoints(testCase)
            dist = LvdUniformDistribution(0, 10);
            v = LvdSweepDistVariation(dist, 5);

            testCase.verifyFalse(v.isGrid());
            testCase.verifyEqual(v.getNumGridValues(), 5);

            %Quantile midpoints of U(0,10) with 5 levels: 1, 3, 5, 7, 9.
            testCase.verifyEqual(v.getGridValues(), [1 3 5 7 9], 'RelTol', 1e-12, ...
                'A distribution crossed into a full factorial must discretize at equally probable midpoints');

            u = (0:0.1:1)';
            testCase.verifyEqual(v.sampleFromUnit(u), dist.invCdf(u), 'RelTol', 1e-14, ...
                'sampleFromUnit must be the distribution inverse CDF');
            testCase.verifySize(v.sampleFromUnit(u), size(u));

            %An unbounded distribution has no plot range, so getRange falls
            %back on a +/- 4 sigma window rather than handing a viewer Inf.
            unbounded = LvdSweepDistVariation(LvdNormalDistribution(2, 0.5), 5);
            [lb, ub] = unbounded.getRange();
            testCase.verifyTrue(isfinite(lb) && isfinite(ub), 'An unbounded distribution must still report a finite range');
            testCase.verifyEqual([lb, ub], [2 - 4*0.5, 2 + 4*0.5], 'RelTol', 1e-12);

            [lb, ub] = v.getRange();
            testCase.verifyEqual([lb, ub], [0, 10], 'A bounded distribution reports its support as its range');
        end
    end
end

function p = refNormalCdf(x, mu, sigma)
    %refNormalCdf The normal CDF written out from the definition.  Used to
    %invert by bisection so the oracle never calls erfinv, which is the
    %function under test.
    p = 0.5*erfc(-(x - mu)./(sigma*sqrt(2)));
end

function p = refTriangularCdf(x, a, c, b)
    %refTriangularCdf The triangular CDF, piecewise from the definition.
    p = zeros(size(x));

    if(b - a <= 0)
        p(x >= a) = 1;
        return;
    end

    risingTf = x >= a & x < c;
    p(risingTf) = (x(risingTf) - a).^2 ./ ((b - a)*(c - a));

    fallingTf = x >= c & x <= b;
    if(b - c > 0)
        p(fallingTf) = 1 - (b - x(fallingTf)).^2 ./ ((b - a)*(b - c));
    else
        p(fallingTf) = 1;
    end

    p(x > b) = 1;
end

function x = refInvertByBisection(cdfFcn, p, lo, hi)
    %refInvertByBisection Solves cdfFcn(x) = p on [lo, hi] by bisection.  Slow
    %and obviously correct, which is the point of an oracle.
    for(i = 1:200) %#ok<*NO4LP>
        mid = 0.5*(lo + hi);
        if(cdfFcn(mid) < p)
            lo = mid;
        else
            hi = mid;
        end
    end

    x = 0.5*(lo + hi);
end
