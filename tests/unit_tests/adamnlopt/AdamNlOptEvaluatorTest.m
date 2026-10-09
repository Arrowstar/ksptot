classdef AdamNlOptEvaluatorTest < AdamNlOptTestCase
%ADAMNLOPTEVALUATORTEST  Contract tests for the adamnlopt evaluation layer.
%   Covers the Evaluator gateway (caching, counting, folding, the two
%   constraint-gradient errors, and the finite-difference step calibration),
%   the finite-difference family (finiteDiffGradient, finiteDiffJacobian,
%   fdBoundedStep, sparsityColoring), the noise estimator (estimateNoise and
%   ecnoiseCore), the secant Jacobian (eval_BroydenJacobian), the Jacobian cost
%   model, and the parallel evaluation helpers.
%
%   The oracles are closed-form derivatives, DERIVESTsuite's gradest and
%   jacobianest, and the serial code path itself where a parallel path claims
%   to reproduce it.  No Optimization Toolbox is used.
%
%   The evaluation COUNTERS get as much attention here as the values do: they
%   are what maxFunEvals bounds the run with and what output.funcCount reports,
%   so a counter that is quietly wrong makes the budget not bind and the report
%   not true, with nothing else to show for it.
%
%   See also ADAMNLOPTTESTCASE, EVALUATOR, FINITEDIFFGRADIENT, ESTIMATENOISE.

    methods (Test)

        %% ---------------------------------------------------------------
        %  Evaluator: construction and the folded layout
        %  ---------------------------------------------------------------
        function testConstraintCountsAreDerivedFromTheData(testCase)
            ev = testCase.evaluatorFrom(struct( ...
                'Aineq', [1 1], 'bineq', 1, ...
                'Aeqlin', [1 -1; 2 0], 'beqlin', [0; 1], ...
                'nlcon', @AdamNlOptTestCase.hs71Con, 'hasConGrad', true, ...
                'mInl', 1, 'mEnl', 1));
            testCase.verifyEqual(ev.mIlin, 1);
            testCase.verifyEqual(ev.mElin, 2);
            testCase.verifyEqual(ev.mI, 2);
            testCase.verifyEqual(ev.mE, 3);
        end

        function testConstraintsPutLinearRowsFirst(testCase)
            %   Every index in the package -- the lambda split at mElin/mIlin,
            %   the degeneracy row drops, the active-set logic -- assumes this
            %   layout.  If the ordering flipped, every one of them would point
            %   at the wrong constraint while still being the right length.
            ev = testCase.evaluatorFrom(struct( ...
                'Aineq', [1 1], 'bineq', 1, ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, 'hasConGrad', true, ...
                'mInl', 1));
            x = [0.3; 0.4];
            [cE, cI] = ev.constraints(x);
            testCase.verifyEmpty(cE);
            testCase.verifySize(cI, [2 1]);
            testCase.verifyEqual(cI(1), sum(x) - 1, 'AbsTol', 1e-14, ...
                'the linear row must come first');
            testCase.verifyEqual(cI(2), x.' * x - 1, 'AbsTol', 1e-14);
        end

        function testJacobianMatchesTheConstraintLayout(testCase)
            ev = testCase.evaluatorFrom(struct( ...
                'Aineq', [1 1], 'bineq', 1, ...
                'Aeqlin', [1 -1], 'beqlin', 0, ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, 'hasConGrad', true, ...
                'mInl', 1));
            x = [0.3; 0.4];
            [JE, JI] = ev.jacobian(x);
            testCase.verifySize(JE, [1 2]);
            testCase.verifySize(JI, [2 2]);
            testCase.verifyEqual(JE, [1 -1], 'AbsTol', 0);
            testCase.verifyEqual(JI(1, :), [1 1], 'AbsTol', 0);
            testCase.verifyEqual(JI(2, :), 2 * x.', 'AbsTol', 1e-14);
        end

        function testEmptyBlocksAreEmptyColumnsNotEmptyMatrices(testCase)
            %   zeros(0,1) and [] behave differently under vertcat with a
            %   nonempty column, so the shape is part of the contract.
            ev = testCase.evaluatorFrom(struct());
            [cE, cI] = ev.constraints([1; 2]);
            testCase.verifySize(cE, [0 1]);
            testCase.verifySize(cI, [0 1]);
            testCase.verifyEqual(ev.nCon, 0, ...
                'no nlcon means no user constraint call to charge for');
        end

        %% ---------------------------------------------------------------
        %  Evaluator: caching and evaluation counting
        %  ---------------------------------------------------------------
        function testObjectiveIsCachedAtTheSamePoint(testCase)
            ev = testCase.evaluatorFrom(struct());
            x = [1; 2];
            [f1, g1] = ev.objective(x);
            [f2, g2] = ev.objective(x);
            testCase.verifyEqual(f1, f2);
            testCase.verifyEqual(g1, g2);
            testCase.verifyEqual(ev.nFun, 1, ...
                'the second call at the same point must be free');
        end

        function testMovingThePointInvalidatesTheCache(testCase)
            ev = testCase.evaluatorFrom(struct());
            ev.objective([1; 2]);
            ev.objective([1; 3]);
            testCase.verifyEqual(ev.nFun, 2);
        end

        function testAValueOnlyCallLaterAskedForAGradientIsCharged(testCase)
            %   The documented accounting fix.  A value-only call caches f with
            %   no gradient; asking for the gradient at that same point is a
            %   SECOND user objective call and costs a real evaluation.  When
            %   it went uncounted, any run mixing the two call styles
            %   under-reported funcCount by one per occurrence -- and the
            %   maxFunEvals budget by the same amount.
            ev = testCase.evaluatorFrom(struct());
            x = [1; 2];
            ev.objective(x);                      % value only
            testCase.verifyEqual(ev.nFun, 1);
            [~, g] = ev.objective(x);             % now wants the gradient
            testCase.verifyEqual(ev.nFun, 2, ...
                'the gradient re-evaluation went uncounted');
            testCase.verifyEqual(g, 2 * x, 'AbsTol', 1e-14);
            [~, ~] = ev.objective(x);             % cached now
            testCase.verifyEqual(ev.nFun, 2);
        end

        function testAGradientCallThenAValueCallCostsNothingExtra(testCase)
            %   The other order: the gradient call already cached both.
            ev = testCase.evaluatorFrom(struct());
            x = [1; 2];
            [~, ~] = ev.objective(x);
            ev.objective(x);
            testCase.verifyEqual(ev.nFun, 1);
        end

        function testForwardDifferenceGradientCostsNEvaluations(testCase)
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false, 'n', 3), ...
                struct('FiniteDifferenceType', 'forward'));
            [~, ~] = ev.objective([1; 2; 3]);
            testCase.verifyEqual(ev.nFun, 1 + 3, ...
                'one base value plus one probe per coordinate');
        end

        function testCentralDifferenceGradientCostsTwoNEvaluations(testCase)
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false, 'n', 3), ...
                struct('FiniteDifferenceType', 'central'));
            [~, ~] = ev.objective([1; 2; 3]);
            testCase.verifyEqual(ev.nFun, 1 + 6);
        end

        function testEveryNlconCallGoesThroughTheCounter(testCase)
            %   nCon is advanced at evalNonlinear, the single chokepoint, and
            %   not at constraints().  Counting at the caller missed the
            %   finite-difference Jacobian probes -- which on a black-box
            %   problem ARE the dominant cost -- so neither funcCount nor the
            %   maxFunEvals budget saw them.
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, ...
                'hasConGrad', false, 'mInl', 1));
            ev.jacobian([0.3; 0.4]);
            testCase.verifyEqual(ev.nCon, 1 + 2, ...
                'one base constraint call plus one probe per coordinate');
        end

        function testAnAnalyticJacobianCostsExactlyOneCall(testCase)
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, ...
                'hasConGrad', true, 'mInl', 1));
            ev.jacobian([0.3; 0.4]);
            testCase.verifyEqual(ev.nCon, 1);
        end

        function testJacobianIsCachedAtTheSamePoint(testCase)
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, ...
                'hasConGrad', true, 'mInl', 1));
            x = [0.3; 0.4];
            ev.jacobian(x);
            ev.jacobian(x);
            testCase.verifyEqual(ev.nCon, 1);
        end

        function testTotalEvalsIsTheSumOfBothCounters(testCase)
            %   nFun alone is the wrong budget: on a black-box problem the
            %   constraint evaluations dominate, and budgeting on nFun let a
            %   run spend unbounded time in them while reporting a count that
            %   never approached its limit.
            ev = testCase.evaluatorFrom(struct( ...
                'hasObjGrad', false, ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, ...
                'hasConGrad', false, 'mInl', 1));
            x = [0.3; 0.4];
            [~, ~] = ev.objective(x);
            ev.jacobian(x);
            testCase.verifyGreaterThan(ev.nFun, 0);
            testCase.verifyGreaterThan(ev.nCon, 0);
            testCase.verifyEqual(ev.totalEvals(), ev.nFun + ev.nCon);
        end

        %% ---------------------------------------------------------------
        %  Evaluator: the two constraint-gradient errors
        %  ---------------------------------------------------------------
        function testAnEmptyConstraintGradientWithRowsIsAnError(testCase)
            %   An empty block used to be turned into zeros(m,n), a
            %   valid-looking Jacobian asserting that every constraint is
            %   locally constant.  The solver then takes steps that ignore
            %   those rows and converges to a point satisfying first-order
            %   conditions for a problem the user did not pose -- a wrong
            %   answer with no error anywhere.
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptEvaluatorTest.diskNoGrad, ...
                'hasConGrad', true, 'mInl', 1));
            testCase.verifyError(@() ev.jacobian([0.3; 0.4]), ...
                'adamnlopt:Evaluator:missingConGrad');
        end

        function testAWronglyOrientedConstraintGradientIsAnError(testCase)
            %   fmincon's convention is n-by-m (one COLUMN per constraint); the
            %   transpose is the single most common user mistake and is caught
            %   here rather than producing a silently wrong Jacobian.
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptEvaluatorTest.diskBadGrad, ...
                'hasConGrad', true, 'mInl', 1));
            testCase.verifyError(@() ev.jacobian([0.3; 0.4]), ...
                'adamnlopt:Evaluator:conGradSize');
        end

        function testAnEmptyGradientIsFineWhenThereAreNoRows(testCase)
            ev = testCase.evaluatorFrom(struct( ...
                'nlcon', @AdamNlOptEvaluatorTest.noConstraints, ...
                'hasConGrad', true));
            [JE, JI] = ev.jacobian([0.3; 0.4]);
            testCase.verifySize(JE, [0 2]);
            testCase.verifySize(JI, [0 2]);
        end

        %% ---------------------------------------------------------------
        %  Evaluator: calibrateStep
        %  ---------------------------------------------------------------
        function testCalibrationDefersToBothUserSettingsWithoutProbing(testCase)
            %   An explicit FiniteDifferenceStepSize/Type is a request, not a
            %   suggestion.  Both exposed all the way out to the LVD options
            %   dialog, and both were inert for anyone who did not also know to
            %   turn autoFDStep off.
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false), ...
                struct('FiniteDifferenceStepSize', 1e-7, ...
                       'FiniteDifferenceType', 'central'));
            info = ev.calibrateStep([1; 2]);
            testCase.verifyEqual(info.flag, 'userSet');
            testCase.verifyEqual(info.nEvals, 0, ...
                'a fully pinned calibration must not spend a probe');
            testCase.verifyTrue(info.fdStepUserSet);
            testCase.verifyTrue(info.fdTypeUserSet);
            testCase.verifyEqual(ev.fdStep, 1e-7);
            testCase.verifyEqual(ev.fdType, 'central');
        end

        function testCalibrationSkipsAFullyAnalyticProblem(testCase)
            %   Nothing to measure: the objective gradient is analytic and
            %   there are no nonlinear constraints, so there is no
            %   finite-difference step in use to calibrate.
            ev = testCase.evaluatorFrom(struct('hasObjGrad', true));
            info = ev.calibrateStep([1; 2]);
            testCase.verifyEqual(info.flag, 'skipped');
            testCase.verifyEqual(info.nEvals, 0);
        end

        function testCalibrationGivesUpWhenTheBoxLeavesTooFewSteps(testCase)
            %   The sweep starts at h = 0.1 on a UNIT-norm direction, which on
            %   a narrow box lands far outside it -- measured 92 box widths out
            %   on a 1e-3-wide box, the single largest source of out-of-bounds
            %   evaluations.  Truncating the sweep also removes the
            %   truncation-dominated arm of the V, so below three usable steps
            %   the bottom of the V is not visible and min() would just pin
            %   fdStep to whatever the box happens to allow.
            w = 1e-8;
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false, ...
                'lb', -w * ones(2, 1), 'ub', w * ones(2, 1)));
            h0 = ev.fdStep;
            info = ev.calibrateStep([0; 0]);
            testCase.verifyEqual(info.flag, 'boundLimited');
            testCase.verifyGreaterThan(info.nSweepDropped, 0);
            testCase.verifyLessThan(info.hMax, 1e-6);
            testCase.verifyEqual(ev.fdStep, h0, ...
                'an abandoned calibration must leave the default step alone');
        end

        function testEveryCalibrationPathReportsTheUserSetFlags(testCase)
            %   Whichever way it exits, a caller has to be able to tell whether
            %   the step it is looking at was chosen or supplied.
            fixtures = { ...
                testCase.evaluatorFrom(struct('hasObjGrad', true)), ...
                testCase.evaluatorFrom(struct('hasObjGrad', false)), ...
                testCase.evaluatorFrom(struct('hasObjGrad', false), ...
                    struct('FiniteDifferenceStepSize', 1e-7, ...
                           'FiniteDifferenceType', 'central'))};
            for k = 1:numel(fixtures)
                info = fixtures{k}.calibrateStep([1; 2]);
                testCase.verifyTrue(isfield(info, 'fdStepUserSet'), ...
                    sprintf('fixture %d lost fdStepUserSet', k));
                testCase.verifyTrue(isfield(info, 'fdTypeUserSet'), ...
                    sprintf('fixture %d lost fdTypeUserSet', k));
                testCase.verifyTrue(ismember(info.flag, {'set', 'skipped', ...
                    'inconclusive', 'analytic', 'boundLimited', 'userSet'}), ...
                    sprintf('fixture %d returned an undocumented flag %s', ...
                            k, info.flag));
            end
        end

        function testCalibrationLeavesTheGlobalRngAlone(testCase)
            %   It seeds a fixed stream to pick a probe direction.  Restoring
            %   the stream is what keeps the calibration from silently
            %   reshuffling any randomness the caller depends on.
            before = rng;
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false));
            ev.calibrateStep([1; 2]);
            testCase.verifyEqual(rng, before, ...
                'calibrateStep perturbed the global RNG stream');
        end

        function testCalibrationBooksObjectiveProbesToTheObjectiveCounter(testCase)
            %   Constraint probes count themselves in nCon via evalNonlinear;
            %   adding them to nFun as well would both double-count them and
            %   book them to the wrong counter.
            ev = testCase.evaluatorFrom(struct('hasObjGrad', false, ...
                'nlcon', @AdamNlOptTestCase.unitDiskIneq, ...
                'hasConGrad', false, 'mInl', 1));
            info = ev.calibrateStep([1; 2]);
            testCase.verifyLessThanOrEqual(info.nEvalsObj, info.nEvals);
            testCase.verifyEqual(ev.nFun, info.nEvalsObj, ...
                'nFun must carry exactly the objective share');
            testCase.verifyEqual(ev.nCon, info.nEvals - info.nEvalsObj, ...
                'nCon must carry exactly the constraint share');
        end

        %% ---------------------------------------------------------------
        %  finiteDiffGradient
        %  ---------------------------------------------------------------
        function testForwardGradientIsExactOnAQuadratic(testCase)
            %   For f = x'x the forward quotient is 2*x_i + h_i exactly, so the
            %   error is the step itself -- a closed-form oracle with no
            %   reference implementation involved.
            x = [1; -2; 3];
            h = sqrt(eps);
            g = adamnlopt.finiteDiffGradient(@AdamNlOptEvaluatorTest.sphereVal, ...
                x, x.' * x, h, 'forward');
            testCase.verifyEqual(g, 2 * x + h * max(1, abs(x)), ...
                'RelTol', 1e-6);
        end

        function testForwardGradientMatchesTheDerivestOracle(testCase)
            x = [-1.2; 1];
            f0 = AdamNlOptEvaluatorTest.rosenVal(x);
            g = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.rosenVal, x, f0, sqrt(eps), 'forward');
            gRef = testCase.quietGradest(@AdamNlOptEvaluatorTest.rosenVal, x);
            testCase.verifyEqual(g, gRef, 'RelTol', 1e-5, 'AbsTol', 1e-4);
        end

        function testCentralGradientIsSharperThanForward(testCase)
            %   Second-order accuracy is the entire reason central differences
            %   cost 2n instead of n; if the two schemes gave the same error
            %   the promotion in calibrateStep would be buying nothing.
            x = [-1.2; 1];
            f0 = AdamNlOptEvaluatorTest.rosenVal(x);
            gRef = testCase.quietGradest(@AdamNlOptEvaluatorTest.rosenVal, x);
            h = 1e-5;
            gF = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.rosenVal, x, f0, h, 'forward');
            gC = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.rosenVal, x, f0, h, 'central');
            testCase.verifyLessThan(norm(gC - gRef), norm(gF - gRef) / 10, ...
                'central differences were not meaningfully more accurate');
        end

        function testGradientIsExactlyZeroAtAFixedVariable(testCase)
            %   lb == ub leaves no feasible direction to difference along, so
            %   the entry is 0 by contract -- not a tiny number produced by a
            %   probe that never moved.
            x = [1; 2];
            lb = [1; -10];  ub = [1; 10];
            g = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.sphereVal, x, x.' * x, sqrt(eps), ...
                'forward', lb, ub);
            testCase.verifyEqual(g(1), 0, 'AbsTol', 0);
            testCase.verifyGreaterThan(abs(g(2)), 1);
        end

        function testGradientFlipsBackwardAtAnUpperBound(testCase)
            %   Flipping costs the same one evaluation at the same order of
            %   accuracy, so a coordinate pinned at its upper bound must lose
            %   nothing but the direction.
            x = [1; 0];
            ub = [1; 10];  lb = [-10; -10];
            g = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.sphereVal, x, x.' * x, 1e-6, ...
                'forward', lb, ub);
            testCase.verifyEqual(g(1), 2 * x(1), 'RelTol', 1e-5, ...
                'the backward difference at the bound lost accuracy');
        end

        function testOmittingBoundsReproducesTheUnboundedResultExactly(testCase)
            %   This is how opts.HonorBounds = false works, so "exactly" is the
            %   contract, not "closely".
            x = [1; -2];
            gA = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.sphereVal, x, x.' * x, 1e-6, 'forward');
            gB = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.sphereVal, x, x.' * x, 1e-6, ...
                'forward', [], []);
            testCase.verifyEqual(gB, gA, 'AbsTol', 0);
        end

        %% ---------------------------------------------------------------
        %  finiteDiffJacobian
        %  ---------------------------------------------------------------
        function testForwardJacobianMatchesTheAnalyticOne(testCase)
            x = [0.6; 0.4];
            base = AdamNlOptEvaluatorTest.threeCon(x);
            J = adamnlopt.finiteDiffJacobian( ...
                @AdamNlOptEvaluatorTest.threeCon, x, base, sqrt(eps), ...
                'forward', []);
            testCase.verifySize(J, [3 2]);
            testCase.verifyEqual(J, testCase.threeConJac(x), ...
                'RelTol', 1e-6, 'AbsTol', 1e-7);
        end

        function testCentralJacobianMatchesTheJacobianestOracle(testCase)
            x = [0.6; 0.4];
            base = AdamNlOptEvaluatorTest.threeCon(x);
            J = adamnlopt.finiteDiffJacobian( ...
                @AdamNlOptEvaluatorTest.threeCon, x, base, 1e-5, ...
                'central', []);
            Jref = testCase.quietJacobianest(@AdamNlOptEvaluatorTest.threeCon, x);
            testCase.verifyEqual(J, Jref, 'RelTol', 1e-7, 'AbsTol', 1e-8);
        end

        function testTheColouredJacobianPathMatchesTheDenseOne(testCase)
            %   Colouring perturbs structurally independent columns together,
            %   so it is EXACT, not an approximation -- any discrepancy is a
            %   colouring bug leaking cross-talk between blocks.
            x = [1.1; 0.5; -0.7; 2];
            base = AdamNlOptEvaluatorTest.blockCon(x);
            P = logical([1 1 0 0; 0 0 1 1]);
            dense = adamnlopt.finiteDiffJacobian( ...
                @AdamNlOptEvaluatorTest.blockCon, x, base, sqrt(eps), ...
                'forward', []);
            coloured = adamnlopt.finiteDiffJacobian( ...
                @AdamNlOptEvaluatorTest.blockCon, x, base, sqrt(eps), ...
                'forward', P);
            testCase.verifyEqual(coloured(P), dense(P), 'AbsTol', 1e-8);
            testCase.verifyEqual(coloured(~P), zeros(nnz(~P), 1), 'AbsTol', 0, ...
                'entries outside the pattern must stay exactly zero');
        end

        function testTheColouredJacobianCostsOneProbePerColour(testCase)
            %   The saving the whole path exists for: two colours instead of
            %   four columns on this block-separable pattern.
            x = [1.1; 0.5; -0.7; 2];
            base = AdamNlOptEvaluatorTest.blockCon(x);
            P = logical([1 1 0 0; 0 0 1 1]);
            counter = struct('n', 0);
            fcn = @countedBlockCon;
            adamnlopt.finiteDiffJacobian(fcn, x, base, sqrt(eps), ...
                'forward', P);
            testCase.verifyEqual(counter.n, max(adamnlopt.sparsityColoring(P)), ...
                'one probe per colour, not one per column');

            function v = countedBlockCon(z)
                counter.n = counter.n + 1;
                v = AdamNlOptEvaluatorTest.blockCon(z);
            end
        end

        %% ---------------------------------------------------------------
        %  fdBoundedStep
        %  ---------------------------------------------------------------
        function testUnboundedStepsReturnImmediatelyUnmodified(testCase)
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep([1; -2; 3], 1e-6, [], []);
            testCase.verifyEqual(hs, 1e-6 * ones(3, 1), 'AbsTol', 0);
            testCase.verifyEqual(sgn, ones(3, 1), 'AbsTol', 0);
            testCase.verifyTrue(all(twoSided));
            testCase.verifyFalse(any(squeezed));
        end

        function testAScalarStepIsExpandedPerCoordinate(testCase)
            hs = adamnlopt.fdBoundedStep(zeros(4, 1), 1e-6, [], []);
            testCase.verifySize(hs, [4 1]);
        end

        function testRuleOneTakesTheForwardStepWhenItFits(testCase)
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep(0, 0.1, -1, 1);
            testCase.verifyEqual(hs, 0.1);
            testCase.verifyEqual(sgn, 1);
            testCase.verifyTrue(twoSided);
            testCase.verifyFalse(squeezed);
        end

        function testRuleTwoFlipsWithoutChangingTheMagnitude(testCase)
            %   Flipping costs the same evaluation at the same order and still
            %   reuses f(x); shrinking raises the cancellation error.  So a
            %   coordinate with room on only one side must FLIP, never shrink.
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep(0.95, 0.1, -1, 1);
            testCase.verifyEqual(hs, 0.1, 'AbsTol', 0, ...
                'the step magnitude must survive the flip intact');
            testCase.verifyEqual(sgn, -1);
            testCase.verifyFalse(twoSided);
            testCase.verifyFalse(squeezed, ...
                'a flip is not a squeeze and must not be reported as one');
        end

        function testRuleThreeShrinksToTheLargerGapAndSaysSo(testCase)
            %   x sits 0.03 below the top of a 0.1-wide box, so neither side
            %   holds the requested 0.08: the larger gap is downward, 0.07.
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep(0.07, 0.08, 0, 0.1);
            testCase.verifyEqual(hs, 0.07, 'AbsTol', 1e-15);
            testCase.verifyEqual(sgn, -1);
            testCase.verifyFalse(twoSided);
            testCase.verifyTrue(squeezed, ...
                'a shrunk step is the least accurate and must be flagged');
        end

        function testRuleFourZeroesAFixedVariable(testCase)
            [hs, sgn, twoSided] = adamnlopt.fdBoundedStep(2, 0.1, 2, 2);
            testCase.verifyEqual(hs, 0, 'AbsTol', 0);
            testCase.verifyEqual(sgn, 0, 'AbsTol', 0);
            testCase.verifyFalse(twoSided);
        end

        function testABoxNarrowerThanFloatingPointSpacingIsTreatedAsFixed(testCase)
            %   Rule 3 has no lower limit of its own, so without rule 4 the
            %   probe point rounds back to x exactly, the function returns the
            %   identical value, and (f-f)/hs enters the gradient as a genuine
            %   derivative of zero -- round-off reported as curvature, with
            %   nothing said about it.
            x = 1e6;
            w = 1e-12;                  % far below eps(1e6) = 2.3e-10
            [hs, sgn] = adamnlopt.fdBoundedStep(x, 0.1, x - w, x + w);
            testCase.verifyEqual(hs, 0, 'AbsTol', 0);
            testCase.verifyEqual(sgn, 0, 'AbsTol', 0);
        end

        function testAPointOutsideTheBoxNeverYieldsANegativeStep(testCase)
            %   HonorBounds prevents this at x0, but a caller-supplied
            %   evaluation point can still be outside; a negative step would
            %   make the quotient's sign wrong rather than merely inaccurate.
            [hs, sgn] = adamnlopt.fdBoundedStep(5, 0.1, 0, 1);
            testCase.verifyGreaterThanOrEqual(hs, 0);
            testCase.verifyTrue(all(ismember(sgn, [-1 0 1])));
        end

        %% ---------------------------------------------------------------
        %  sparsityColoring
        %  ---------------------------------------------------------------
        function testColouringNeverSharesAColourBetweenConflictingColumns(testCase)
            %   The defining property.  Violate it and the coloured Jacobian is
            %   silently wrong: two columns' contributions land in the same
            %   difference and are attributed to whichever column is read first.
            P = logical([1 1 0 0 0; 0 1 1 0 0; 0 0 1 1 0; 0 0 0 1 1]);
            groups = adamnlopt.sparsityColoring(P);
            testCase.verifySize(groups, [1 5]);
            testCase.verifyGreaterThanOrEqual(min(groups), 1);
            for c = unique(groups)
                rows = sum(P(:, groups == c), 2);
                testCase.verifyLessThanOrEqual(max(rows), 1, ...
                    sprintf('colour %d has columns sharing a row', c));
            end
        end

        function testADiagonalPatternNeedsExactlyOneColour(testCase)
            testCase.verifyEqual(adamnlopt.sparsityColoring(eye(6) > 0), ...
                ones(1, 6));
        end

        function testADensePatternDegeneratesToOneColourPerColumn(testCase)
            groups = adamnlopt.sparsityColoring(true(3, 4));
            testCase.verifyEqual(numel(unique(groups)), 4, ...
                'every column conflicts with every other');
        end

        function testTheColouringCacheStillAnswersForANewPattern(testCase)
            %   The single-slot content-keyed cache is worth having -- the
            %   colouring is a pure function of a pattern fixed for the whole
            %   solve -- but a one-slot cache that failed to notice a changed
            %   pattern would return another matrix's colouring.  Callers
            %   genuinely alternate between two patterns (Hessian and
            %   Jacobian), so alternate here too.
            P1 = logical(eye(4));
            P2 = true(2, 4);
            for k = 1:3
                testCase.verifyEqual(adamnlopt.sparsityColoring(P1), ...
                    ones(1, 4), 'the cache returned the wrong pattern''s answer');
                testCase.verifyEqual(numel(unique( ...
                    adamnlopt.sparsityColoring(P2))), 4);
            end
        end

        %% ---------------------------------------------------------------
        %  ecnoiseCore
        %  ---------------------------------------------------------------
        function testEcnoiseReportsSpacingTooSmallOnIdenticalSamples(testCase)
            [fnoise, ~, inform] = adamnlopt.ecnoiseCore(ones(7, 1));
            testCase.verifyEqual(inform, 2, ...
                'all-identical samples mean the spacing is too small');
            testCase.verifyEqual(fnoise, 0, ...
                'every non-detecting outcome must return a zero noise level');
        end

        function testEcnoiseReportsSpacingTooLargeOnAStrongTrend(testCase)
            [fnoise, ~, inform] = adamnlopt.ecnoiseCore((1:7).');
            testCase.verifyEqual(inform, 3);
            testCase.verifyEqual(fnoise, 0);
        end

        function testEcnoiseDetectsAnAlternatingNoiseFloor(testCase)
            %   A sign-alternating perturbation on a flat trend is the cleanest
            %   possible noise signal: the difference table changes sign at
            %   every level and the level estimates are stable within 1.3x, so
            %   the first-stable-level rule must fire on level 1.  The expected
            %   value is closed form: level(1) = sqrt(gamma_1)*|d_1| =
            %   sqrt(0.5)*2a.
            a = 1e-9;
            fval = 1 + a * (-1) .^ (1:7).';
            [fnoise, level, inform] = adamnlopt.ecnoiseCore(fval);
            testCase.verifyEqual(inform, 1);
            testCase.verifyEqual(fnoise, sqrt(0.5) * 2 * a, 'RelTol', 1e-6);
            testCase.verifySize(level, [6 1]);
        end

        function testEcnoiseLevelsHaveOneEntryPerDifferenceLevel(testCase)
            [~, level] = adamnlopt.ecnoiseCore(ones(9, 1) + 1e-9 * (-1) .^ (1:9).');
            testCase.verifySize(level, [8 1]);
        end

        %% ---------------------------------------------------------------
        %  estimateNoise
        %  ---------------------------------------------------------------
        function testNoiseEstimateReturnsZeroWheneverItDidNotDetect(testCase)
            %   epsf = 0 is also what an inconclusive or failed probe returns,
            %   so a caller that cannot tell "measured as clean" from "could not
            %   measure" will silently trust a default step on a function it
            %   never characterised.  detected is the field that distinguishes
            %   them and it must never disagree with epsf.
            [epsf, info] = adamnlopt.estimateNoise( ...
                @AdamNlOptEvaluatorTest.sphereVal, [1; 2], [], struct());
            testCase.verifyEqual(epsf, info.epsf);
            if ~info.detected
                testCase.verifyEqual(epsf, 0, 'AbsTol', 0);
            end
            testCase.verifyTrue(ismember(info.flag, ...
                {'noise', 'inconclusive', 'flat', 'error'}));
        end

        function testACleanAnalyticFunctionMeasuresAtTheRoundOffFloor(testCase)
            %   A smooth analytic function is not noiseless -- its noise floor
            %   is machine round-off, and ECnoise finding it is correct, not a
            %   false positive.  What matters to the caller is the SCALE: the
            %   measured floor here must sit at eps*|f| and therefore orders of
            %   magnitude below a genuine algorithmic noise level, because that
            %   gap is what the finite-difference step selection keys on.
            [epsf, info] = adamnlopt.estimateNoise( ...
                @AdamNlOptEvaluatorTest.sphereVal, [1; 2], [1; 0], struct());
            testCase.verifyTrue(info.detected);
            f0 = AdamNlOptEvaluatorTest.sphereVal([1; 2]);
            testCase.verifyLessThan(epsf, 1e-13 * max(1, abs(f0)), ...
                'a clean quadratic measured far above its round-off floor');
        end

        function testNoiseEstimateDetectsAnInjectedNoiseFloor(testCase)
            %   A high-frequency ripple of known amplitude on a smooth trend is
            %   exactly the signal ECnoise is built to find: deterministic, so
            %   no RNG is touched, but incoherent at the sampling spacing.
            amp = 1e-10;
            [epsf, info] = adamnlopt.estimateNoise( ...
                @(z) AdamNlOptEvaluatorTest.rippleVal(z, amp), [1; 2], ...
                [1; 0], struct('baseSpacing', 1e-6));
            testCase.verifyTrue(info.detected, ...
                sprintf('noise floor missed; flag was %s', info.flag));
            testCase.verifyGreaterThan(epsf, amp / 100);
            testCase.verifyLessThan(epsf, amp * 100);
        end

        function testNoiseEstimateReportsAThrowingFunction(testCase)
            [epsf, info] = adamnlopt.estimateNoise( ...
                @(~) error('test:boom', 'boom'), [1; 2], [1; 0], struct());
            testCase.verifyEqual(info.flag, 'error');
            testCase.verifyEqual(epsf, 0);
            testCase.verifyFalse(info.detected);
        end

        function testNoiseEstimateLeavesTheGlobalRngAlone(testCase)
            %   With dir = [] it draws a seeded random direction; the stream is
            %   saved and restored so calibration does not perturb anything
            %   downstream that depends on it.
            before = rng;
            adamnlopt.estimateNoise(@AdamNlOptEvaluatorTest.sphereVal, ...
                [1; 2], [], struct());
            testCase.verifyEqual(rng, before);
        end

        function testNoiseEstimateForcesAnOddSampleCount(testCase)
            %   x0 has to be centred in the sample line, which an even count
            %   cannot do.
            [~, info] = adamnlopt.estimateNoise( ...
                @AdamNlOptEvaluatorTest.sphereVal, [1; 2], [1; 0], ...
                struct('nPts', 6));
            testCase.verifyEqual(mod(info.nEvals, 7), 0, ...
                'nPts = 6 must be promoted to 7 samples per sweep');
        end

        %% ---------------------------------------------------------------
        %  eval_BroydenJacobian
        %  ---------------------------------------------------------------
        function testBroydenStoresTheExactJacobianItWasBuiltFrom(testCase)
            J0 = [1 2; 3 4; 5 6];
            b = adamnlopt.eval_BroydenJacobian(J0);
            testCase.verifyEqual(b.m, 3);
            testCase.verifyEqual(b.n, 2);
            testCase.verifyEqual(b.full(), J0, 'AbsTol', 0);
            testCase.verifyFalse(b.needsRefresh());
        end

        function testBroydenSatisfiesTheSecantConditionAfterAnUpdate(testCase)
            %   J+ = J + (y - J*s)*s'/(s's) gives J+*s = y identically; that is
            %   the whole content of the rank-1 secant update.
            b = adamnlopt.eval_BroydenJacobian(eye(2));
            s = [0.1; -0.05];
            y = [0.105; -0.045];
            testCase.verifyTrue(b.update(s, y));
            testCase.verifyEqual(b.apply(s), y, 'AbsTol', 1e-14);
        end

        function testBroydenApplyAndApplyTAgreeWithTheMatrix(testCase)
            J0 = [1 2; 3 4; 5 6];
            b = adamnlopt.eval_BroydenJacobian(J0);
            testCase.verifyEqual(b.apply([1; -1]), J0 * [1; -1], 'AbsTol', 0);
            testCase.verifyEqual(b.applyT([1; 0; 2]), J0.' * [1; 0; 2], ...
                'AbsTol', 0);
            testCase.verifyEqual(b.apply([1, -1]), J0 * [1; -1], 'AbsTol', 0, ...
                'apply must flatten a row vector');
        end

        function testBroydenSkipsANegligibleStepButStillAges(testCase)
            b = adamnlopt.eval_BroydenJacobian(eye(2), 3);
            testCase.verifyFalse(b.update([0; 0], [1; 1]));
            testCase.verifyEqual(b.full(), eye(2), 'AbsTol', 0);
            b.update([0; 0], [1; 1]);
            b.update([0; 0], [1; 1]);
            testCase.verifyTrue(b.needsRefresh(), ...
                'a run of skipped steps must still force a refresh eventually');
        end

        function testTheNegligibleStepTestIsRelativeToTheReferencePoint(testCase)
            %   The old test read ss2 < eps*norm(ss)^2 + eps, which is
            %   tautological -- norm(ss)^2 IS ss2 -- so the intended relative
            %   guard collapsed to the absolute threshold ||s|| < 1.5e-8.  On
            %   variables of order 1e6 that accepted steps eleven orders below
            %   the variable scale and divided by an effectively zero s's; on
            %   variables of order 1e-6 it rejected every legitimate step.
            s = 1e-3 * [1; 0];
            y = 1e-3 * [1; 0];

            small = adamnlopt.eval_BroydenJacobian(eye(2));
            testCase.verifyTrue(small.update(s, y, [1; 1]), ...
                'a 1e-3 step on O(1) variables is not negligible');

            huge = adamnlopt.eval_BroydenJacobian(eye(2));
            testCase.verifyFalse(huge.update(s, y, [1e6; 1e6]), ...
                'a 1e-3 step on O(1e6) variables IS negligible');
        end

        function testALargeResidualForcesARefreshInsteadOfAnUpdate(testCase)
            %   Past the tolerance the secant model is no longer describing the
            %   same function; folding the discrepancy in anyway would corrupt
            %   the approximation rather than correct it.
            b = adamnlopt.eval_BroydenJacobian(eye(2), 20, 0.1);
            s = [1; 0];
            y = [100; 0];                  % residual 99 against a model prediction of 1
            testCase.verifyFalse(b.update(s, y));
            testCase.verifyEqual(b.full(), eye(2), 'AbsTol', 0);
            testCase.verifyTrue(b.needsRefresh(), ...
                'the refresh must be due immediately, not in maxStale steps');
        end

        function testBroydenRefreshIsDueAfterMaxStaleUpdates(testCase)
            b = adamnlopt.eval_BroydenJacobian(eye(2), 3, 1e3);
            for k = 1:2
                b.update([0.1 * k; 0], [0.1 * k; 0]);
                testCase.verifyFalse(b.needsRefresh());
            end
            b.update([0.5; 0], [0.5; 0]);
            testCase.verifyTrue(b.needsRefresh());
        end

        function testSetExactReplacesTheModelAndClearsTheStaleness(testCase)
            b = adamnlopt.eval_BroydenJacobian(eye(2), 1, 1e3);
            b.update([0.1; 0], [0.1; 0]);
            testCase.verifyTrue(b.needsRefresh());
            Jnew = [2 0; 0 3];
            b.setExact(Jnew);
            testCase.verifyEqual(b.full(), Jnew, 'AbsTol', 0);
            testCase.verifyFalse(b.needsRefresh());
        end

        %% ---------------------------------------------------------------
        %  eval_costModel
        %  ---------------------------------------------------------------
        function testCostModelStartsEmpty(testCase)
            cm = adamnlopt.eval_costModel();
            testCase.verifyEqual(cm.avgTime(), 0);
            testCase.verifyEqual(cm.nEvals, 0);
            testCase.verifyEqual(cm.totalTime, 0);
            testCase.verifyFalse(cm.tooExpensive(), ...
                'an unmeasured evaluator must not look expensive');
        end

        function testCostModelAccumulatesTotalsAcrossTheWholeHistory(testCase)
            %   nEvals and totalTime are lifetime figures; only the AVERAGE is
            %   windowed.
            cm = adamnlopt.eval_costModel(2);
            cm.tick(1);  cm.tick(2);  cm.tick(3);
            testCase.verifyEqual(cm.nEvals, 3);
            testCase.verifyEqual(cm.totalTime, 6);
        end

        function testCostModelAveragesOnlyOverItsWindow(testCase)
            %   The window is what lets the Broyden auto-enable react to a
            %   regime change instead of being anchored by the cold-start
            %   timings at the beginning of the solve.
            cm = adamnlopt.eval_costModel(3);
            cm.tick(1);  cm.tick(2);  cm.tick(3);  cm.tick(100);
            testCase.verifyEqual(cm.avgTime(), mean([2 3 100]), 'AbsTol', 1e-12);
        end

        function testTooExpensiveIsStrictlyGreaterThan(testCase)
            cm = adamnlopt.eval_costModel();
            cm.tick(0.1);
            testCase.verifyFalse(cm.tooExpensive(0.1), ...
                'equal to the threshold is not over it');
            testCase.verifyTrue(cm.tooExpensive(0.09));
        end

        function testTooExpensiveDefaultsToATenthOfASecond(testCase)
            cm = adamnlopt.eval_costModel();
            cm.tick(0.2);
            testCase.verifyTrue(cm.tooExpensive());
        end

        function testCostModelResetClearsEverything(testCase)
            cm = adamnlopt.eval_costModel();
            cm.tick(5);
            cm.reset();
            testCase.verifyEqual(cm.avgTime(), 0);
            testCase.verifyEqual(cm.nEvals, 0);
            testCase.verifyEqual(cm.totalTime, 0);
        end

        %% ---------------------------------------------------------------
        %  The parallel family
        %  ---------------------------------------------------------------
        function testParallelFiniteDiffReproducesTheSerialGradient(testCase)
            %   The parallel path is an optimization, not a different
            %   algorithm, so the numbers must be identical rather than merely
            %   close -- the same step rule, the same base value reuse.
            testCase.assumeTrue(license('test', 'Distrib_Computing_Toolbox') == 1, ...
                'Parallel Computing Toolbox not licensed.');
            x = [1; -2; 0.5];
            f0 = AdamNlOptEvaluatorTest.sphereVal(x);
            gSerial = adamnlopt.finiteDiffGradient( ...
                @AdamNlOptEvaluatorTest.sphereVal, x, f0, sqrt(eps), 'forward');
            [gPar, J, info] = adamnlopt.parallel_parallelFiniteDiff( ...
                @AdamNlOptEvaluatorTest.sphereVal, [], x, f0, [], ...
                sqrt(eps), 'forward', [], [], []);
            testCase.verifyEqual(gPar, gSerial, 'AbsTol', 1e-12);
            testCase.verifyEmpty(J);
            testCase.verifyEqual(info.nObjEvals, 3, ...
                'the count must be exact, not the n/2n estimate');
            testCase.verifyEqual(info.nConEvals, 0);
        end

        function testParallelFiniteDiffReproducesTheSerialJacobian(testCase)
            testCase.assumeTrue(license('test', 'Distrib_Computing_Toolbox') == 1, ...
                'Parallel Computing Toolbox not licensed.');
            x = [0.6; 0.4];
            c0 = AdamNlOptEvaluatorTest.threeCon(x);
            Jserial = adamnlopt.finiteDiffJacobian( ...
                @AdamNlOptEvaluatorTest.threeCon, x, c0, sqrt(eps), ...
                'forward', []);
            [g, Jpar, info] = adamnlopt.parallel_parallelFiniteDiff( ...
                [], @AdamNlOptEvaluatorTest.threeCon, x, [], c0, ...
                sqrt(eps), 'forward', [], [], []);
            testCase.verifyEmpty(g);
            testCase.verifyEqual(Jpar, Jserial, 'AbsTol', 1e-12);
            testCase.verifyEqual(info.nConEvals, 2);
            testCase.verifyTrue(islogical(info.remote), ...
                'remote decides whether the caller adds these counts');
        end
    end

    %% ------------------------------------------------------------------
    %  Fixtures
    %  ------------------------------------------------------------------
    methods (Access = private)
        function ev = evaluatorFrom(~, problem, optOverrides)
            %EVALUATORFROM  An Evaluator over the 11 required fields.
            %   PROBLEM supplies only what the case actually has; everything
            %   else falls back to a two-variable unconstrained sphere, which
            %   keeps the cases readable and guarantees the constructor never
            %   sees a missing field.
            p = struct('objFun', @AdamNlOptTestCase.sphere, ...
                'hasObjGrad', true, 'nlcon', [], 'hasConGrad', false, ...
                'Aineq', [], 'bineq', [], 'Aeqlin', [], 'beqlin', [], ...
                'n', 2, 'mInl', 0, 'mEnl', 0);
            f = fieldnames(problem);
            for i = 1:numel(f)
                p.(f{i}) = problem.(f{i});
            end
            opts = adamnlopt.defaultOptions();
            if nargin > 2 && ~isempty(optOverrides)
                g = fieldnames(optOverrides);
                for i = 1:numel(g)
                    opts.(g{i}) = optOverrides.(g{i});
                end
            end
            ev = adamnlopt.Evaluator(p, opts);
        end

        function J = threeConJac(~, x)
            %THREECONJAC  The analytic Jacobian of THREECON.
            J = [2 * x(1), 2 * x(2);
                 x(2),     x(1);
                 1,        -1];
        end
    end

    methods (Static)
        function f = sphereVal(x)
            %SPHEREVAL  f = x'x with a SINGLE output.
            %   The finite-difference routines call their function handle with
            %   nargout = 1; a two-output objective is fine there, but a
            %   value-only handle is what the bare FD modules are documented to
            %   take, so use one and keep the probe honest.
            f = x(:).' * x(:);
        end

        function f = rosenVal(x)
            %ROSENVAL  Rosenbrock, value only.
            f = 100 * (x(2) - x(1) ^ 2) ^ 2 + (1 - x(1)) ^ 2;
        end

        function f = rippleVal(x, amp)
            %RIPPLEVAL  A smooth trend plus a deterministic high-frequency
            %   ripple of known amplitude -- a reproducible stand-in for the
            %   error floor of an ODE integrator, with no RNG involved.
            s = sum(x(:));
            f = 0.5 * s ^ 2 + amp * sin(1e9 * s);
        end

        function v = threeCon(x)
            %THREECON  A 3-by-2 vector function with an analytic Jacobian.
            v = [x(1) ^ 2 + x(2) ^ 2 - 1;
                 x(1) * x(2) - 0.25;
                 x(1) - x(2)];
        end

        function v = blockCon(x)
            %BLOCKCON  Block-separable in (x1,x2) and (x3,x4), so its pattern
            %   colours into two groups rather than four.
            v = [x(1) ^ 2 + x(2);
                 x(3) * x(4)];
        end

        function [c, ceq, gc, gceq] = diskNoGrad(x)
            %DISKNOGRAD  Declares a gradient and returns an empty one anyway.
            c = x.' * x - 1;  ceq = [];  gc = [];  gceq = [];
        end

        function [c, ceq, gc, gceq] = diskBadGrad(x)
            %DISKBADGRAD  Returns the gradient transposed (1-by-n not n-by-1).
            c = x.' * x - 1;  ceq = [];  gc = (2 * x).';  gceq = [];
        end

        function [c, ceq, gc, gceq] = noConstraints(~)
            %NOCONSTRAINTS  An nlcon with no rows at all; empty IS correct here.
            c = [];  ceq = [];  gc = [];  gceq = [];
        end
    end
end
