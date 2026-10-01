classdef AdamNlOptGlobalizationTest < AdamNlOptTestCase
%ADAMNLOPTGLOBALIZATIONTEST  Contract tests for the globalization and control
%   layer: Filter, globalize_*, control_*, terminationCheck, IterTrace and
%   iterationInfo.
%
%   This is the machinery that decides whether a computed step may be taken and
%   when the iteration is allowed to stop -- the part of the solver whose
%   failures look like "it converged to the wrong place" or "it never stopped"
%   rather than like an exception.  Each module is driven directly with
%   hand-built states so exactly one rule is under test at a time; the
%   termination fixture in particular is engineered so that nothing fires until
%   a test arms one specific exit, which means a failure names the rule that
%   broke rather than just the test.
%
%   See also ADAMNLOPTTESTCASE, ADAMNLOPTSOLVETEST.

    methods (Test)

        %% ================================================================
        %  Filter
        %  ================================================================

        function testEmptyFilterAcceptsAnything(testCase)
            f = adamnlopt.Filter();
            testCase.verifyTrue(f.isAcceptable(1e6, 1e6));
            testCase.verifyTrue(f.isAcceptable(0, -1e6));
        end

        function testFilterRejectsADominatedTrial(testCase)
            %   A point worse in BOTH coordinates than a stored entry is the
            %   definition of unacceptable.  This is the assertion that makes
            %   the filter a globalization rather than a logbook.
            f = adamnlopt.Filter(1e-5, 1e-5);
            f.augment(1, 10);

            testCase.verifyFalse(f.isAcceptable(2, 20), ...
                'a trial worse in both theta and phi must be rejected');
            testCase.verifyTrue(f.isAcceptable(0.1, 20), ...
                'a trial that improves feasibility must stay acceptable');
            testCase.verifyTrue(f.isAcceptable(2, 1), ...
                'a trial that improves the objective must stay acceptable');
        end

        function testFilterEnforcesTheViolationCap(testCase)
            %   thetaMax is a hard veto that applies even to an empty filter.
            f = adamnlopt.Filter([], [], 5);
            testCase.verifyTrue(f.isAcceptable(4.9, -1e9));
            testCase.verifyFalse(f.isAcceptable(5, -1e9), ...
                'theta >= thetaMax must be rejected regardless of phi');
        end

        function testConstructorKeepsDefaultsForEmptyArguments(testCase)
            f = adamnlopt.Filter([], 7, []);
            testCase.verifyEqual(f.gammaTheta, 1e-5);
            testCase.verifyEqual(f.gammaPhi, 7);
            testCase.verifyEqual(f.thetaMax, inf);
        end

        function testAugmentStoresTheMarginShiftedCorner(testCase)
            %   Waechter-Biegler store (1-gammaTheta)*theta rather than theta,
            %   so merely matching a previous point is not good enough.
            gT = 1e-3;  gP = 1e-4;
            f = adamnlopt.Filter(gT, gP);
            f.augment(2, 7);

            testCase.verifyEqual(f.entries, ...
                [(1 - gT) * 2, 7 - gP * 2], 'AbsTol', 1e-14);
        end

        function testAugmentPrunesDominatedEntries(testCase)
            %   The filter must stay a minimal Pareto frontier or its cost
            %   grows without bound over a long solve.
            f = adamnlopt.Filter(0, 0);
            f.augment(5, 50);     % dominated by (1, 10) below
            f.augment(3, 30);     % likewise
            f.augment(1, 10);

            testCase.verifyEqual(f.entries, [1, 10], 'AbsTol', 1e-14, ...
                'augment did not prune the entries its new corner dominates');
        end

        function testAugmentKeepsNonDominatedEntries(testCase)
            %   The mirror of the test above: pruning must not be greedy.
            f = adamnlopt.Filter(0, 0);
            f.augment(5, 1);      % very infeasible, very good objective
            f.augment(1, 10);     % nearly feasible, poor objective

            testCase.verifySize(f.entries, [2, 2], ...
                'augment discarded an entry that was not dominated');
        end

        function testFilterResetEmptiesIt(testCase)
            f = adamnlopt.Filter();
            f.augment(1, 1);
            f.reset();
            testCase.verifyEmpty(f.entries);
            testCase.verifyTrue(f.isAcceptable(1, 1));
        end

        function testFilterIsAHandleObject(testCase)
            %   solve.m passes the filter around by reference and relies on
            %   augment mutating the caller's copy; value semantics would make
            %   every augment silently a no-op.
            f = adamnlopt.Filter();
            g = f;
            g.augment(1, 1);
            testCase.verifySize(f.entries, [1, 2], ...
                'Filter does not have handle semantics');
        end

        %% ================================================================
        %  globalize_* -- the acceptance primitives
        %  ================================================================

        function testConstraintViolationIsTheL1OfTheActualViolation(testCase)
            %   theta = ||cE||_1 + ||max(cI,0)||_1: equalities count in both
            %   directions, inequalities only where positive (violated).
            theta = adamnlopt.globalize_constraintViolation([3; -4], [-10; 2]);
            testCase.verifyEqual(theta, 3 + 4 + 2, 'AbsTol', 1e-14);
        end

        function testConstraintViolationIsZeroExactlyWhenFeasible(testCase)
            testCase.verifyEqual( ...
                adamnlopt.globalize_constraintViolation([], [-1; -2]), 0);
            testCase.verifyEqual( ...
                adamnlopt.globalize_constraintViolation([], []), 0);
            testCase.verifyGreaterThan( ...
                adamnlopt.globalize_constraintViolation(1e-12, []), 0);
        end

        function testConstraintViolationIgnoresOrientation(testCase)
            %   Callers hand it rows and columns interchangeably.
            testCase.verifyEqual( ...
                adamnlopt.globalize_constraintViolation([1 2], [3 4]), ...
                adamnlopt.globalize_constraintViolation([1; 2], [3; 4]));
        end

        function testMeritFunctionIsTheL1Penalty(testCase)
            testCase.verifyEqual( ...
                adamnlopt.globalize_meritFunction(2, 3, 10), 32, ...
                'AbsTol', 1e-14);
        end

        function testMeritAcceptIsArmijo(testCase)
            %   Accept iff phiT <= phi0 + c*alpha*dphi along a descent dphi.
            phi0 = 10;  dphi = -4;  alpha = 0.5;  c = 0.1;
            threshold = phi0 + c * alpha * dphi;      % 9.8

            testCase.verifyTrue(adamnlopt.globalize_meritAccept( ...
                phi0, threshold - 1e-6, dphi, alpha, c));
            testCase.verifyFalse(adamnlopt.globalize_meritAccept( ...
                phi0, threshold + 1e-6, dphi, alpha, c));
        end

        function testFilterAcceptMatchesTheFilterObject(testCase)
            %   The free function and the class must not drift apart: solve.m
            %   uses the class, globalize_filterLineSearch the function.
            entries = [1, 10; 0.5, 20];
            f = adamnlopt.Filter(1e-5, 1e-5);
            f.entries = entries;

            for theta = [0.1, 0.6, 2]
                for phi = [5, 15, 25]
                    testCase.verifyEqual( ...
                        adamnlopt.globalize_filterAccept(entries, theta, ...
                            phi, 1e-5, 1e-5), ...
                        f.isAcceptable(theta, phi), sprintf( ...
                        'globalize_filterAccept and Filter disagree at (%g, %g)', ...
                        theta, phi));
                end
            end
        end

        %% ================================================================
        %  globalize_filterLineSearch
        %  ================================================================

        function testFTypeStepIsAcceptedWithoutAugmenting(testCase)
            %   At a feasible point along a descent direction the switching
            %   condition holds, Armijo decides, and the accepted step must NOT
            %   enter the filter -- augmenting on every f-type step is what
            %   makes a filter method stall short of the solution.
            phiTheta = @(a) testCase.lineModel(a, 10, -1, 10, 0);

            [alpha, augment, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 0, -1, adamnlopt.Filter(), 1);

            testCase.verifyFalse(lsFailed);
            testCase.verifyGreaterThan(alpha, 0);
            testCase.verifyLessThanOrEqual(alpha, 1);
            testCase.verifyFalse(augment, ...
                'an Armijo-passing switching step must not augment the filter');

            % Armijo really does hold at the returned step length.
            phiT = phiTheta(alpha);
            testCase.verifyLessThanOrEqual(phiT, 10 + 1e-4 * alpha * (-1));
        end

        function testThetaTypeStepIsAcceptedAndAugments(testCase)
            %   Far from feasibility the switching condition is off and a step
            %   that buys feasibility is accepted even though it costs
            %   objective -- and it must be recorded in the filter.
            phiTheta = @(a) testCase.lineModel(a, 10, 1, 0, 1);

            [alpha, augment, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 1, 1, adamnlopt.Filter(), 1);

            testCase.verifyFalse(lsFailed);
            testCase.verifyEqual(alpha, 1, 'AbsTol', 1e-14);
            testCase.verifyTrue(augment, ...
                'an accepted theta-type step must be added to the filter');
        end

        function testLineSearchNeverExceedsTheFractionToBoundaryCap(testCase)
            %   aMax is the barrier's strict-feasibility limit; exceeding it
            %   drives a slack negative and the next log evaluation is complex.
            phiTheta = @(a) testCase.lineModel(a, 10, 1, 0, 1);

            alpha = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 1, 1, adamnlopt.Filter(), 1, 0.25);

            testCase.verifyLessThanOrEqual(alpha, 0.25);
        end

        function testThetaCapVetoesAFeasibilityBlowUp(testCase)
            %   The theta-type objective-decrease disjunct,
            %   phiT <= phi0 - gammaPhi*theta0, degenerates to "any decrease at
            %   all" when theta0 is small, so uncapped the search happily
            %   trades a violation of 1000 for an objective gain of 0.1.  The
            %   cap must force backtracking until the trial violation actually
            %   fits under the ceiling.
            theta0   = 1e-3;     % above thetaMin, so the switching rule is off
            phiTheta = @(a) testCase.blowUpModel(a, 10);

            [aUncapped, ~, ~, failedUncapped] = ...
                adamnlopt.globalize_filterLineSearch( ...
                    phiTheta, 10, theta0, -0.1, adamnlopt.Filter(), 1, 1, inf);
            [aCapped, ~, ~, failedCapped] = ...
                adamnlopt.globalize_filterLineSearch( ...
                    phiTheta, 10, theta0, -0.1, adamnlopt.Filter(), 1, 1, 1);

            testCase.verifyFalse(failedUncapped);
            testCase.verifyEqual(aUncapped, 1, 'AbsTol', 1e-14, ...
                'uncapped, the full step buying a violation of 1e3 is accepted');

            testCase.verifyFalse(failedCapped);
            [~, thetaCapped] = testCase.blowUpModel(aCapped, 10);
            testCase.verifyLessThanOrEqual(thetaCapped, 1, ...
                'the accepted trial violated the thetaCap ceiling');
            testCase.verifyLessThan(aCapped, aUncapped);
        end

        function testTotalFailureIsReportedNotDisguised(testCase)
            %   The restoration trigger keys off lsFailed, and alpha must not
            %   exceed the caller's cap even on the failure path: amin is a
            %   floor on the backtracking, not a licence to exceed aMax.
            f = adamnlopt.Filter(0, 0);
            f.augment(1, 10);                                % the current point
            phiTheta = @(a) testCase.constModel(a, 11, 2);   % worse in both

            [alpha, ~, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 1, -1, f, 1, 1e-12);

            testCase.verifyTrue(lsFailed);
            testCase.verifyLessThanOrEqual(alpha, 1e-12, ...
                'the failure path returned a step longer than aMax');
        end

        function testMeritBackupRaisesThePenaltyWeight(testCase)
            %   The backup must keep the l1 merit exact: rho >= ||lambda||_inf.
            %   Dropping multInfNorm left rho pinned at its initial value and
            %   made the penalty far too weak to price a feasibility increase.
            f = adamnlopt.Filter(0, 0);
            f.augment(1, 10);
            phiTheta = @(a) testCase.constModel(a, 11, 2);

            [~, ~, rho] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 1, -1, f, 1, 1, inf, 500);

            testCase.verifyGreaterThanOrEqual(rho, 500, ...
                'the merit backup ignored the multiplier norm it was given');
        end

        %% ================================================================
        %  control_barrierUpdate
        %  ================================================================

        function testBarrierParameterNeverIncreases(testCase)
            opts = testCase.barrierOpts();
            mu = 0.1;
            for k = 1:20
                [muNew, tau] = adamnlopt.control_barrierUpdate(mu, 1e-12, opts);
                testCase.verifyLessThanOrEqual(muNew, mu + 1e-15, ...
                    'the barrier parameter increased');
                testCase.verifyGreaterThanOrEqual(tau, opts.tau);
                testCase.verifyLessThan(tau, 1);
                mu = muNew;
            end
            testCase.verifyGreaterThanOrEqual(mu, opts.muMin, ...
                'mu fell below its floor');
        end

        function testBarrierParameterHoldsWhileTheSubproblemIsUnsolved(testCase)
            %   mu may only drop once the current barrier subproblem has been
            %   solved to kappaMu*mu.  Dropping early is what makes an interior
            %   point method lurch into the boundary.
            opts = testCase.barrierOpts();
            mu = 0.1;
            muNew = adamnlopt.control_barrierUpdate(mu, 1e6, opts);
            testCase.verifyEqual(muNew, mu, ...
                'mu was reduced while the barrier subproblem was far from solved');
        end

        function testBarrierReductionTakesTheFasterOfTheTwoRules(testCase)
            %   min(muGamma*mu, mu^muBeta): the superlinear branch has to be
            %   reachable somewhere or muBeta is dead configuration.
            opts = testCase.barrierOpts();
            mu = adamnlopt.control_barrierUpdate(0.5, 0, opts);
            testCase.verifyEqual(mu, ...
                min(opts.muGamma * 0.5, 0.5 ^ opts.muBeta), 'AbsTol', 1e-15);
        end

        function testFractionToBoundaryTauApproachesOneAsMuVanishes(testCase)
            %   tau -> 1 near the solution lets the final steps reach the
            %   boundary, which is where the active set lives.
            opts = testCase.barrierOpts();
            [~, tauFar]  = adamnlopt.control_barrierUpdate(1e-1,  1e-12, opts);
            [~, tauNear] = adamnlopt.control_barrierUpdate(1e-10, 1e-12, opts);
            testCase.verifyGreaterThanOrEqual(tauNear, tauFar);
            testCase.verifyLessThan(1 - tauNear, 1e-3);
        end

        %% ================================================================
        %  control_penaltyUpdate
        %  ================================================================

        function testPenaltyIsMonotoneAndIdempotent(testCase)
            rho = adamnlopt.control_penaltyUpdate(1, 10, -1, 2, 0.1);
            testCase.verifyGreaterThanOrEqual(rho, 1, ...
                'the l1 penalty decreased, which breaks the merit function');
            testCase.verifyEqual( ...
                adamnlopt.control_penaltyUpdate(rho, 10, -1, 2, 0.1), rho, ...
                'AbsTol', 1e-12, ...
                'a second update at the same state moved the penalty again');
        end

        function testPenaltyGuaranteesDescentOnTheMeritFunction(testCase)
            %   The reason the penalty exists: rho must be large enough that
            %   the directional derivative of the l1 merit, gd - rho*theta, is
            %   at most -buffer*theta.
            buffer = 0.1;
            for gd = [-1, 0, 5, 100]
                for theta = [1e-6, 1, 50]
                    rho = adamnlopt.control_penaltyUpdate(1, 3, gd, theta, buffer);
                    testCase.verifyLessThanOrEqual(gd - rho * theta, ...
                        -buffer * theta + 1e-9, sprintf( ...
                        'no descent guarantee at gd = %g, theta = %g', gd, theta));
                end
            end
        end

        function testPenaltyExceedsTheMultiplierNorm(testCase)
            rho = adamnlopt.control_penaltyUpdate(1, 25, 0, 1, 0.1);
            testCase.verifyGreaterThanOrEqual(rho, 25, ...
                'rho below ||lambda||_inf makes the l1 merit non-exact');
        end

        function testPenaltySkipsTheDivisionAtFeasibility(testCase)
            %   theta == 0 is the division-by-zero case, and it is reached on
            %   every feasible iterate -- which is most of the endgame.
            rho = adamnlopt.control_penaltyUpdate(7, 3, -1, 0, 0.1);
            testCase.verifyTrue(isfinite(rho));
            testCase.verifyGreaterThanOrEqual(rho, 7);
        end

        function testPenaltyBufferDefaults(testCase)
            testCase.verifyEqual( ...
                adamnlopt.control_penaltyUpdate(0, 3, 0, 0), 3 + 1e-2, ...
                'AbsTol', 1e-14);
        end

        %% ================================================================
        %  control_trustRegionUpdate
        %  ================================================================

        function testNonPositivePredictedReductionAlwaysRejects(testCase)
            %   A model predicting no improvement cannot certify anything, so
            %   the step is rejected and the region shrunk whatever the actual
            %   reduction turned out to be -- and ratio reports -inf rather
            %   than dividing by ~0.
            opts = adamnlopt.defaultOptions();
            for actRed = [-1, 0, 1e6]
                [Delta, accept, ratio] = adamnlopt.control_trustRegionUpdate( ...
                    1, 0, actRed, 1, opts);
                testCase.verifyFalse(accept, ...
                    'a step with predRed <= 0 was accepted');
                testCase.verifyEqual(ratio, -inf);
                testCase.verifyLessThan(Delta, 1, ...
                    'the trust region did not shrink after a rejected step');
            end
        end

        function testAcceptanceFollowsTheRatioThreshold(testCase)
            opts = adamnlopt.defaultOptions();
            [~, acceptLo] = adamnlopt.control_trustRegionUpdate( ...
                1, 1, opts.trEta1 - 1e-6, 1, opts);
            [~, acceptHi] = adamnlopt.control_trustRegionUpdate( ...
                1, 1, opts.trEta1 + 1e-6, 1, opts);

            testCase.verifyFalse(acceptLo);
            testCase.verifyTrue(acceptHi);
        end

        function testInteriorStepDoesNotExpandTheRegion(testCase)
            %   Expanding when the step never reached the boundary grows the
            %   radius with no evidence a larger one would have been used.
            opts = adamnlopt.defaultOptions();
            [Delta, accept] = adamnlopt.control_trustRegionUpdate( ...
                10, 1, 1, 0.1, opts);
            testCase.verifyTrue(accept);
            testCase.verifyEqual(Delta, 10, ...
                'an interior step changed the trust-region radius');
        end

        function testBoundaryStepWithAGoodRatioExpands(testCase)
            opts = adamnlopt.defaultOptions();
            Delta = adamnlopt.control_trustRegionUpdate(1, 1, 1, 1, opts);
            testCase.verifyEqual(Delta, opts.trExpand, 'AbsTol', 1e-14);
        end

        function testTrustRegionIsCappedAtDeltaMax(testCase)
            opts = adamnlopt.defaultOptions();
            Delta = opts.deltaMax;
            for k = 1:5
                Delta = adamnlopt.control_trustRegionUpdate( ...
                    Delta, 1, 1, Delta, opts);
            end
            testCase.verifyEqual(Delta, opts.deltaMax, ...
                'the trust region grew past deltaMax');
        end

        %% ================================================================
        %  control_activeSetConfidence
        %  ================================================================

        function testConfidenceIsOneWhenThereAreNoInequalities(testCase)
            state = struct('s', [], 'lamI', [], 'mu', 0.1, 'cI', []);
            [conf, info] = adamnlopt.control_activeSetConfidence( ...
                state, adamnlopt.defaultOptions());

            testCase.verifyEqual(conf, 1, ...
                'with nothing to be unsure about, confidence must be 1');
            testCase.verifyEmpty(info.perConstraint);
            testCase.verifyEqual(info.nActive, 0);
            testCase.verifyEqual(info.nWeakly, 0);
        end

        function testWeaklyActiveConstraintsLowerConfidence(testCase)
            %   A constraint sitting on its boundary with a vanishing
            %   multiplier is the degenerate case this score exists to flag.
            opts = adamnlopt.defaultOptions();
            strong = struct('cI', 0, 'lamI', 1, 's', 0, 'mu', 0);
            weak   = struct('cI', 0, 'lamI', 1e-9, 's', 0, 'mu', 0);

            [confStrong, infoStrong] = ...
                adamnlopt.control_activeSetConfidence(strong, opts);
            [confWeak, infoWeak] = ...
                adamnlopt.control_activeSetConfidence(weak, opts);

            testCase.verifyEqual(confStrong, 1, 'AbsTol', 1e-12);
            testCase.verifyLessThan(confWeak, 0.5);
            testCase.verifyEqual(infoStrong.nWeakly, 0);
            testCase.verifyEqual(infoWeak.nWeakly, 1, ...
                'a near-zero multiplier on an active row was not flagged weak');
        end

        function testConfidenceStaysInTheUnitIntervalAndCountsConsistently(testCase)
            rng(17);
            opts = adamnlopt.defaultOptions();
            nI = 5;
            for k = 1:25
                state = struct('cI', randn(nI, 1), ...
                    'lamI', 10 .^ (-6 * rand(nI, 1)), ...
                    's', 10 .^ (-6 * rand(nI, 1)), 'mu', 10 ^ (-6 * rand));

                [conf, info] = adamnlopt.control_activeSetConfidence(state, opts);

                testCase.verifyGreaterThanOrEqual(conf, 0);
                testCase.verifyLessThanOrEqual(conf, 1);
                testCase.verifyLessThanOrEqual(info.nWeakly, info.nActive);
                testCase.verifyLessThanOrEqual(info.nActive, nI);
                testCase.verifySize(info.perConstraint, [nI, 1]);
            end
        end

        %% ================================================================
        %  control_modeController -- rules R1..R4
        %  ================================================================

        function testModeControllerReturnsNeutralAdviceByDefault(testCase)
            %   A caller may invoke this unconditionally, so the advice must be
            %   a no-op when no rule fires rather than an arbitrary nudge.
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'standard');
            testCase.verifyEqual(advice.muFactor, 1);
            testCase.verifyEqual(advice.deltaFactor, 1);
            testCase.verifyFalse(advice.suggestRestore);
        end

        function testR1EntersFeasibilityModeOnALargeViolation(testCase)
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            res.feas = 1e4 * opts.feasTol;

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'feasibility');
            testCase.verifyLessThan(advice.muFactor, 1, ...
                'feasibility mode must slow the barrier, not speed it up');
        end

        function testR1ThresholdIsIndependentOfTheConstraintCount(testCase)
            %   R1 keys off the inf-norm residual, not the l1 theta.  Against
            %   theta the fixed 100*feasTol threshold grew with m and latched
            %   many-constraint problems permanently into feasibility mode.
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            res.feas    = 10 * opts.feasTol;                   % under the 100x gate
            state.cE    = 10 * opts.feasTol * ones(1000, 1);   % but a huge l1 norm
            state.theta = norm(state.cE, 1);

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'standard', ...
                'R1 fired on the l1 constraint norm rather than the inf-norm');
        end

        function testR2EntersNearBoundaryModeInTheEndgame(testCase)
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            res.opt  = 0.1 * opts.optTol;
            res.feas = 0;
            % A confidently identified active set: slack and multiplier well
            % separated and complementarity met, so confidence comes out at 1.
            state.cI   = [0; -1];
            state.s    = [1e-12; 1];
            state.lamI = [1; 1e-12];
            state.mu   = 1e-12;

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'nearBoundary');
            testCase.verifyGreaterThan(advice.muFactor, 1, ...
                'the endgame must push the barrier down faster');
        end

        function testR2IsGatedOnComplementarity(testCase)
            %   Once comp is inside tolerance mu has no remaining job, and
            %   accelerating it only re-derives the duals inconsistently.
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            res.opt  = 0.1 * opts.optTol;
            res.feas = 0;
            res.comp = 0.1 * opts.optTol;         % already inside tolerance
            state.cI   = [0; -1];
            state.s    = [1e-12; 1];
            state.lamI = [1; 1e-12];
            state.mu   = 1e-12;

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'standard', ...
                'R2 fired with complementarity already inside tolerance');
        end

        function testR3FlagsAStalledConstraintViolation(testCase)
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            state.theta = 1;
            n = 2 * opts.modeSwitchStagnWindow;
            hist.theta = ones(1, n);              % no net progress at all
            hist.alpha = 0.1 * ones(1, n);

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyTrue(advice.suggestRestore, ...
                'a flat theta history was not reported as stagnation');
        end

        function testR3MeasuresNetProgressNotSpread(testCase)
            %   A theta that spikes and falls back to where it started has a
            %   large spread and zero progress -- precisely the case
            %   restoration is for, and the spread test missed it.  Conversely
            %   an oscillation around a falling mean IS progress.
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            w = opts.modeSwitchStagnWindow;
            hist.alpha = 0.1 * ones(1, w);

            state.theta = 1;
            hist.theta  = ones(1, w);
            hist.theta(ceil(w / 2)) = 100;                      % spike and return
            spiky = adamnlopt.control_modeController(state, res, hist, opts);

            hist.theta  = linspace(10, 1, w) + 0.3 * (-1) .^ (1:w);   % noisy drop
            state.theta = hist.theta(end);
            falling = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyTrue(spiky.suggestRestore, ...
                'a spike-and-return history was not flagged as stagnant');
            testCase.verifyFalse(falling.suggestRestore, ...
                'a noisy but genuinely falling theta was flagged as stagnant');
        end

        function testR4OverridesR1sTrustRegionAdvice(testCase)
            %   R4 runs last and its deltaFactor wins in every mode, including
            %   over R1's "preserve the trust region": two consecutive
            %   unclipped steps are direct evidence that the radius, not the
            %   model, is what limits progress.
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            res.feas   = 1e4 * opts.feasTol;      % arms R1
            hist.alpha = [0.1, 1, 1];             % arms R4

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.mode, 'feasibility');
            testCase.verifyGreaterThan(advice.deltaFactor, 1, ...
                'R4 did not override the feasibility-mode trust-region advice');
        end

        function testR4NeedsTwoConsecutiveFullSteps(testCase)
            opts = adamnlopt.defaultOptions();
            [state, res, hist] = testCase.modeFixture();
            hist.alpha = [1, 1, 0.5];             % the most recent step was clipped

            advice = adamnlopt.control_modeController(state, res, hist, opts);

            testCase.verifyEqual(advice.deltaFactor, 1, ...
                'R4 fired on a history whose most recent step was clipped');
        end

        %% ================================================================
        %  terminationCheck -- one exit per test
        %  ================================================================

        function testNothingFiresOnAnOrdinaryIterate(testCase)
            [state, res, opts] = testCase.termFixture();
            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifyEmpty(msg);
        end

        function testConvergenceExit(testCase)
            [state, res, opts] = testCase.termFixture();
            res.opt = 0;  res.feas = 0;  res.comp = 0;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 1);
            testCase.verifySubstring(msg, 'Converged');
        end

        function testConvergenceWorksWithTheUnresolvedCompTolSentinel(testCase)
            %   compTol defaults to [] and is resolved to optTol by solve AFTER
            %   mapOptions.  `compScaled <= []` is [], not a logical scalar,
            %   and because it is the THIRD operand of a short-circuit chain
            %   the defect is invisible until the iterate actually converges --
            %   at which point a caller driving this directly errors with
            %   MATLAB:nonLogicalConditional instead of getting exitflag 1.
            [state, res, opts] = testCase.termFixture();
            opts.compTol = [];
            res.opt = 0;  res.feas = 0;  res.comp = 0;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 1);
        end

        function testNonFiniteExitBeatsEveryOtherTest(testCase)
            %   Nothing can be concluded from residuals computed on a NaN
            %   iterate, so this exit is tested first.  Arming the convergence
            %   condition at the same time is what proves the ordering: a
            %   constant-NaN objective arrives here with opt = feas = comp = 0
            %   and would otherwise be reported as a converged solve.
            [state, res, opts] = testCase.termFixture();
            res.opt = 0;  res.feas = 0;  res.comp = 0;
            state.f = NaN;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, -3, ...
                'a NaN objective was reported as a converged solve');
            testCase.verifySubstring(msg, 'not finite');
        end

        function testNonFiniteResidualAlsoExits(testCase)
            [state, res, opts] = testCase.termFixture();
            res.opt = Inf;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, -3);
        end

        function testObjectivePlateauExit(testCase)
            [state, res, opts] = testCase.termFixture();
            state.objStallCount = opts.objPlateauWindow;
            state.optGateCount  = opts.objPlateauOptWindow;
            res.feas = 0;
            res.comp = 0;
            % Inside the plateau gate but outside optTol, so the exitflag-1
            % test above cannot claim this point first.
            res.opt = 0.5 * (opts.optTol + opts.objPlateauOptTol);

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 2);
            testCase.verifySubstring(msg, 'objective stalled');
        end

        function testObjectivePlateauNeedsTheSustainedStationarityGate(testCase)
            %   An endgame whose opt oscillates will dip a spike under any
            %   threshold looser than optTol, so one touch must not be enough.
            [state, res, opts] = testCase.termFixture();
            state.objStallCount = opts.objPlateauWindow;
            state.optGateCount  = opts.objPlateauOptWindow - 1;
            res.feas = 0;
            res.comp = 0;
            res.opt  = 0.5 * (opts.optTol + opts.objPlateauOptTol);

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop, ...
                'the plateau exit fired on a single touch of the gate');
            testCase.verifyEqual(exitflag, 0);
        end

        function testStepSizeExitReportsTwoOnlyAtAStationaryPoint(testCase)
            %   fmincon's StepTolerance code (2) means "converged as far as the
            %   step size can tell".  A step that collapses at a feasible but
            %   grossly NON-stationary point is a stall, and reporting 2 tells
            %   a caller checking exitflag > 0 the answer is good when it is
            %   not -- measured once at a stationarity residual of 2.85e+34.
            [state, res, opts] = testCase.termFixture();
            state.stepNorm = 1e-16;
            res.feas = 0;

            res.opt = 0.5 * opts.objPlateauOptTol;
            [stopA, flagA, msgA] = adamnlopt.terminationCheck(state, res, opts);

            res.opt = 1e3 * opts.objPlateauOptTol;
            [stopB, flagB, msgB] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stopA);
            testCase.verifyEqual(flagA, 2);
            testCase.verifySubstring(msgA, 'Converged');

            testCase.verifyTrue(stopB);
            testCase.verifyEqual(flagB, 0, ...
                'a stall short of stationarity was reported as exitflag 2');
            testCase.verifySubstring(msgB, 'stalled');
        end

        function testStepSizeExitRequiresFeasibility(testCase)
            %   A line search collapsing to alpha ~ 0 at an infeasible point is
            %   a restoration trigger, not a solution.
            [state, res, opts] = testCase.termFixture();
            state.stepNorm = 1e-16;
            res.opt  = 0.5 * opts.objPlateauOptTol;
            res.feas = 1e3 * opts.feasTol;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop, ...
                'the step-size exit fired at an infeasible point');
            testCase.verifyEqual(exitflag, 0);
        end

        function testStepSizeExitIsDisabledByAZeroStepTol(testCase)
            [state, res, opts] = testCase.termFixture();
            state.stepNorm = 0;
            res.feas = 0;
            opts.stepTol = 0;

            testCase.verifyFalse( ...
                adamnlopt.terminationCheck(state, res, opts));
        end

        function testDivergenceExitIsDisarmedByDefault(testCase)
            %   divergeWindow = Inf by default because a bestFeas-relative
            %   threshold false-positives on ordinary endgame excursions, so
            %   the default must NOT fire even on a plainly diverging state.
            [state, res, opts] = testCase.termFixture();
            state.bestFeas = 1e-8;
            state.feasRegressCount = 1e6;
            res.feas = 1e8;

            [~, exitflag] = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyNotEqual(exitflag, -3, ...
                'the divergence exit fired at the default divergeWindow = Inf');

            opts.divergeWindow = 3;
            [stop, armedFlag, msg] = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyTrue(stop);
            testCase.verifyEqual(armedFlag, -3, ...
                'a finite divergeWindow did not arm the divergence exit');
            testCase.verifySubstring(msg, 'diverged');
        end

        function testWallClockExit(testCase)
            [state, res, opts] = testCase.termFixture();
            opts.maxTime  = 1;
            state.elapsed = 2;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifySubstring(msg, 'maximum time');
        end

        function testMaxIterExit(testCase)
            [state, res, opts] = testCase.termFixture();
            state.iter = opts.maxIter;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifySubstring(msg, 'maximum iterations');
        end

        function testMaxFunEvalsExit(testCase)
            [state, res, opts] = testCase.termFixture();
            state.nFunEvals = opts.maxFunEvals;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifySubstring(msg, 'function evaluations');
        end

        function testOptionalStateFieldsAreSkippedNotFailed(testCase)
            %   The equality core does not populate stepNorm, elapsed,
            %   objStallCount or feasRegressCount.  An absent field must skip
            %   its test rather than error -- the solver would otherwise die on
            %   iteration 0.
            [state, res, opts] = testCase.termFixture();
            opts.maxTime       = 1;
            opts.divergeWindow = 3;
            state = rmfield(state, {'stepNorm', 'elapsed', 'objStallCount', ...
                'optGateCount', 'feasRegressCount', 'bestFeas'});

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop);
            testCase.verifyEqual(exitflag, 0);
        end

        function testLargeMultipliersDoNotMaskConvergence(testCase)
            %   smax-style scaling divides stationarity and complementarity by
            %   the average multiplier magnitude; without it a problem whose
            %   duals are O(1e8) could never report convergence.
            [state, res, opts] = testCase.termFixture();
            state.lamE = 1e8;
            res.opt  = 1e3 * opts.optTol;
            res.comp = 1e3 * opts.optTol;
            res.feas = 0;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 1);
        end

        %% ================================================================
        %  IterTrace
        %  ================================================================

        function testTraceRecordsAndRoundTrips(testCase)
            t = adamnlopt.IterTrace({'iter', 'f'}, 4, 1);
            t.record(struct('iter', 1, 'f', 10));
            t.record(struct('iter', 2, 'f', 20));

            S = t.toStruct();

            testCase.verifyEqual(t.nRows, 2);
            testCase.verifyEqual(S.iter, [1; 2]);
            testCase.verifyEqual(S.f, [10; 20]);
        end

        function testUnrecordedFieldsReadAsNaN(testCase)
            %   NaN is the not-recorded sentinel; a zero would be a measurement.
            t = adamnlopt.IterTrace({'iter', 'f'}, 4, 1);
            t.record(struct('iter', 1));

            S = t.toStruct();
            testCase.verifyEqual(S.iter, 1);
            testCase.verifyTrue(isnan(S.f));
        end

        function testTraceGrowsPastItsCapacity(testCase)
            %   capacity is a hint, not a cap; exceeding it must grow the
            %   storage rather than drop rows or error.
            t = adamnlopt.IterTrace({'iter'}, 2, 1);
            for k = 1:9
                t.record(struct('iter', k));
            end

            S = t.toStruct();
            testCase.verifyEqual(t.nRows, 9);
            testCase.verifyEqual(S.iter, (1:9).');
            testCase.verifyGreaterThanOrEqual(t.capacity, 9);
        end

        function testUnknownFieldsAreIgnoredRatherThanFatal(testCase)
            %   record is handed the whole diagnostic struct, which at
            %   traceLevel 1 legitimately carries more than the columns in use.
            t = adamnlopt.IterTrace({'iter'}, 2, 1);
            t.record(struct('iter', 1, 'notAColumn', 99));

            S = t.toStruct();
            testCase.verifyEqual(t.nRows, 1);
            testCase.verifyEqual(S.iter, 1);
            testCase.verifyFalse(isfield(S, 'notAColumn'));
        end

        function testTraceResetKeepsItsShape(testCase)
            t = adamnlopt.IterTrace({'iter', 'f'}, 8, 2);
            t.record(struct('iter', 1, 'f', 1));
            t.reset();

            testCase.verifyEqual(t.nRows, 0);
            testCase.verifyEqual(t.capacity, 8);
            testCase.verifyEqual(t.fields, {'iter', 'f'});
            testCase.verifyEqual(t.level, 2);
        end

        function testTraceMetaIsStoredSeparatelyFromTheColumns(testCase)
            t = adamnlopt.IterTrace({'iter'}, 2, 1);
            t.setMeta('solver', 'ip');
            t.record(struct('iter', 1));

            S = t.toStruct();
            testCase.verifyEqual(S.meta.solver, 'ip');
            testCase.verifyEqual(S.iter, 1);
        end

        function testTraceIsAHandleObject(testCase)
            t = adamnlopt.IterTrace({'iter'}, 2, 1);
            u = t;
            u.record(struct('iter', 1));
            testCase.verifyEqual(t.nRows, 1, ...
                'IterTrace does not have handle semantics');
        end

        %% ================================================================
        %  iterationInfo
        %  ================================================================

        function testIterationInfoIsPurelyAdditive(testCase)
            %   The documented hook contract promises a callback that every
            %   field it was handed last iteration is still there this one.
            [info, state, res, problem, opts, extras] = testCase.infoFixture();
            info.myOwnField = 'kept';

            out = adamnlopt.iterationInfo(info, state, res, problem, opts, extras);

            testCase.verifyEqual(out.iter, info.iter);
            testCase.verifyEqual(out.myOwnField, 'kept', ...
                'iterationInfo dropped a field it was handed');
        end

        function testIterationInfoExposesTheDocumentedSubStructs(testCase)
            [info, state, res, problem, opts, extras] = testCase.infoFixture();

            out = adamnlopt.iterationInfo(info, state, res, problem, opts, extras);

            testCase.verifyEqual(sort(fieldnames(out.lambda)), ...
                sort({'lamE'; 'lamI'; 'zL'; 'zU'}));
            for f = {'dx', 'dlamE', 'aP', 'aD', 'Delta', 'tau', 'rho', 'stepsize'}
                testCase.verifyTrue(isfield(out.step, f{1}), sprintf( ...
                    'info.step is missing the documented field %s', f{1}));
            end
            testCase.verifyEqual(out.n,  numel(state.x));
            testCase.verifyEqual(out.mE, numel(state.lamE));
            testCase.verifyEqual(out.mI, numel(state.lamI));
            testCase.verifyEqual(out.optRaw, norm(res.rStat, inf), 'AbsTol', 1e-14);
        end

        function testIterationInfoFabricatesNoBoundMultipliers(testCase)
            %   The equality core carries no barrier, so zL/zU must come back
            %   empty rather than as plausible-looking zeros.
            [info, state, res, problem, opts, extras] = testCase.infoFixture();
            state = rmfield(state, {'zL', 'zU'});

            out = adamnlopt.iterationInfo(info, state, res, problem, opts, extras);

            testCase.verifyEmpty(out.lambda.zL);
            testCase.verifyEmpty(out.lambda.zU);
        end

    end

    %% ====================================================================
    %  Models and fixtures
    %  ====================================================================
    methods (Access = private)

        function [phi, theta] = lineModel(~, a, phi0, slope, curv, theta0)
            %LINEMODEL  A two-output phi/theta model for the line search.
            %   Written as a method rather than an anonymous handle because an
            %   anonymous function cannot return two outputs, and
            %   @(a) deal(...) errors the moment anything probes it with
            %   nargout = 1.
            phi   = phi0 + slope * a + curv * a ^ 2;
            theta = theta0 * (1 - 0.9 * a);
        end

        function [phi, theta] = blowUpModel(~, a, phi0)
            %BLOWUPMODEL  A small objective gain bought with a huge violation.
            phi   = phi0 - 0.1 * a;
            theta = 1e3 * a;
        end

        function [phi, theta] = constModel(~, ~, phi, theta)
            %CONSTMODEL  A trial worse in both coordinates at every step length.
        end

        function opts = barrierOpts(~)
            %BARRIEROPTS  defaultOptions with muMin resolved as solve resolves it.
            %   muMin defaults to [] and is tied to 0.1*optTol inside solve
            %   AFTER mapOptions, so a caller driving control_barrierUpdate
            %   directly has to do the same.
            opts = adamnlopt.defaultOptions();
            opts.muMin = 0.1 * opts.optTol;
        end

        function [state, res, opts] = termFixture(~)
            %TERMFIXTURE  A non-converged but FEASIBLE state with nothing armed.
            %   Residuals above tolerance, counters well short of their caps,
            %   nothing non-finite, a step far larger than stepTol, and the
            %   divergence exit left at its default Inf window.  Each test arms
            %   exactly one exit on top of this, so a failure names the rule
            %   that broke rather than just the test that noticed.
            opts = adamnlopt.defaultOptions();
            opts.maxIter     = 100;
            opts.maxFunEvals = 1000;
            opts.compTol     = opts.optTol;   % as solve resolves the sentinel
            state = struct( ...
                'x', [1; 2], 'f', 1, 'lamE', 0, 'lamI', zeros(0, 1), ...
                'iter', 5, 'nFunEvals', 20, ...
                'objStallCount', 0, 'optGateCount', 0, ...
                'feasRegressCount', 0, 'bestFeas', 0, ...
                'stepNorm', 1, 'elapsed', 0);
            res = struct('opt', 1, 'feas', 0, 'comp', 1);
        end

        function [state, res, hist] = modeFixture(~)
            %MODEFIXTURE  A neutral state with every mode-controller rule off.
            state = struct('theta', 0, 'cE', zeros(0, 1), 'cI', [-1; -1], ...
                's', [1; 1], 'lamI', [1; 1], 'mu', 1e-2);
            res  = struct('opt', 1, 'feas', 0, 'comp', 1);
            hist = struct('theta', [1, 0.5, 0.25], 'alpha', [0.1, 0.1, 0.1]);
        end

        function [info, state, res, problem, opts, extras] = infoFixture(~)
            %INFOFIXTURE  The six arguments iterationInfo reads, minimally.
            n = 2;  mE = 1;  mI = 1;
            state = struct('x', [1; 2], 'f', 3, 'g', [4; 5], ...
                'cE', 0.1, 'cI', -0.2, 'lamE', 0.3, 'lamI', 0.4, ...
                'zL', [0.5; 0.6], 'zU', [0.7; 0.8]);
            res = struct('rStat', [1; -2], 'rFeasE', 0.1, 'rFeasI', -0.2, ...
                'rComp', 0.3);
            problem = struct('lb', [-1; -1], 'ub', [10; 10]);
            opts = adamnlopt.defaultOptions();
            extras = struct('dx', zeros(n, 1), 'dlamE', zeros(mE, 1), ...
                'ds', zeros(mI, 1), 'dlamI', zeros(mI, 1), ...
                'dzL', zeros(n, 1), 'dzU', zeros(n, 1), ...
                'aP', 1, 'aD', 1, 'aLamE', 1, 'Delta', 2, 'tau', 0.995, ...
                'rho', 1, 'advice', struct('mode', 'standard'), ...
                'nActiveBnd', 0, 'lsAdopted', 0, 'lsFired', 0);
            info = struct('iter', 7, 'x', state.x, 'fval', state.f, ...
                'stepsize', 0.5);
        end

    end

end
