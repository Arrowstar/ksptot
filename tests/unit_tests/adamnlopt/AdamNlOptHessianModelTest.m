classdef AdamNlOptHessianModelTest < AdamNlOptTestCase
%ADAMNLOPTHESSIANMODELTEST  Contract tests for the adamnlopt curvature layer.
%   Covers the HessianModel interface, its two implementations (BFGSHessian
%   dense and LBFGSHessian compact), the finite-difference Lagrangian Hessian,
%   and the Hessian-vector product that lets the rest of the package treat a
%   matrix and a secant model interchangeably.
%
%   The independent oracles here are the secant condition B*s = y (which every
%   undamped quasi-Newton update must satisfy exactly), the eigenvalues of the
%   materialized matrix, and DERIVESTsuite's Richardson-extrapolated HESSIAN
%   for the finite-difference path.  No Optimization Toolbox is used.
%
%   See also ADAMNLOPTTESTCASE, HESSIANMODEL, BFGSHESSIAN, LBFGSHESSIAN.

    methods (Test)

        %% ---------------------------------------------------------------
        %  The HessianModel interface itself
        %  ---------------------------------------------------------------
        function testHessianModelIsAbstract(testCase)
            %   The base class exists only to give the solver a single positive
            %   test (isa(H, 'adamnlopt.HessianModel')); instantiating it
            %   directly must fail.
            mc = meta.class.fromName('adamnlopt.HessianModel');
            testCase.verifyTrue(mc.Abstract, ...
                'HessianModel must stay abstract');
            testCase.verifyError(@() adamnlopt.HessianModel(), ?MException);
        end

        function testBothImplementationsSatisfyTheInterface(testCase)
            %   isa() is the ONLY test the solver makes before calling apply,
            %   getMatrix and diagonal, so a subclass that fails to implement
            %   one of them breaks the solver at run time rather than at load.
            models = {adamnlopt.BFGSHessian(3), adamnlopt.LBFGSHessian(3, 5)};
            names  = {'reset', 'update', 'getMatrix', 'apply', 'diagonal'};
            for k = 1:numel(models)
                h = models{k};
                testCase.verifyTrue(isa(h, 'adamnlopt.HessianModel'), ...
                    sprintf('%s must be a HessianModel', class(h)));
                testCase.verifyTrue(isa(h, 'handle'), ...
                    sprintf('%s must have handle semantics', class(h)));
                for j = 1:numel(names)
                    testCase.verifyTrue(ismethod(h, names{j}), ...
                        sprintf('%s is missing %s', class(h), names{j}));
                end
            end
        end

        function testHandleSemanticsMeanUpdatesArePropagated(testCase)
            %   solve.m hands the model around by reference and never reassigns
            %   it; a value class here would silently discard every update.
            h = adamnlopt.BFGSHessian(2);
            alias = h;
            h.update([1; 0], [2; 0]);
            testCase.verifyEqual(alias.nUpdates, 1);
        end

        %% ---------------------------------------------------------------
        %  BFGSHessian
        %  ---------------------------------------------------------------
        function testBfgsStartsAtTheIdentity(testCase)
            h = adamnlopt.BFGSHessian(4);
            testCase.verifyEqual(h.getMatrix(), eye(4), 'AbsTol', 0);
            testCase.verifyEqual(h.apply([1; 2; 3; 4]), [1; 2; 3; 4], ...
                'AbsTol', 0);
            testCase.verifyEqual(h.diagonal(), ones(4, 1), 'AbsTol', 0);
            testCase.verifyEqual(h.nUpdates, 0);
            testCase.verifyEqual(h.nRejected, 0);
        end

        function testBfgsSatisfiesTheSecantConditionOnACleanPair(testCase)
            %   B+ = B - Bs*Bs'/s'Bs + y*y'/s'y gives B+*s = y identically.
            %   This is the defining property of the update; if it does not
            %   hold the model is not a BFGS model, whatever else it is.
            h = adamnlopt.BFGSHessian(2);
            s = [1; 0];  y = [2; 1];
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-12, ...
                'first update violated the secant condition');
        end

        function testBfgsSecantHoldsForTheNewestPairInASequence(testCase)
            h = testCase.trainedBfgs();
            [s, y] = testCase.quadraticPair([1; -1; 1]);
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-10, ...
                'the newest undamped pair must be reproduced exactly');
        end

        function testBfgsApplyAgreesWithGetMatrix(testCase)
            %   kkt_KKTOperator uses apply while kkt_assemble uses getMatrix;
            %   if they disagree the Krylov and direct solvers are solving
            %   different problems.
            h = testCase.trainedBfgs();
            B = h.getMatrix();
            V = [1 0 2; 0 1 -3; 0 0 1.5];
            for j = 1:size(V, 2)
                testCase.verifyEqual(h.apply(V(:, j)), B * V(:, j), ...
                    'AbsTol', 1e-12);
            end
        end

        function testBfgsApplyAcceptsARowVector(testCase)
            h = testCase.trainedBfgs();
            testCase.verifyEqual(h.apply([1, 2, 3]), h.apply([1; 2; 3]), ...
                'AbsTol', 0);
        end

        function testBfgsMatrixStaysSymmetricPositiveDefinite(testCase)
            %   The inertia correction assumes the Hessian block is at worst
            %   indefinite by a known amount; a secant model that silently
            %   loses positive definiteness defeats it.
            h = testCase.trainedBfgs();
            B = h.getMatrix();
            testCase.verifyEqual(B, B.', 'AbsTol', 0, ...
                'getMatrix must return an exactly symmetric matrix');
            testCase.verifyGreaterThan(min(eig(B)), 0, ...
                'the BFGS model lost positive definiteness');
        end

        function testBfgsDiagonalIsTheMatrixDiagonal(testCase)
            %   linalg_preconditioner builds the Jacobi preconditioner from
            %   diagonal(); it must not be a separate, stale copy.
            h = testCase.trainedBfgs();
            testCase.verifyEqual(h.diagonal(), diag(h.getMatrix()), ...
                'AbsTol', 0);
        end

        function testBfgsRejectsAZeroStep(testCase)
            %   Nothing to learn, and s'Bs = 0 would divide by zero.  A zero
            %   step is not a bad pair, so it must NOT count as a rejection.
            h = adamnlopt.BFGSHessian(2);
            testCase.verifyFalse(h.update([0; 0], [1; 1]));
            testCase.verifyEqual(h.nUpdates, 0);
            testCase.verifyEqual(h.nRejected, 0, ...
                'a degenerate step is not a curvature rejection');
            testCase.verifyEqual(h.getMatrix(), eye(2), 'AbsTol', 0);
        end

        function testBfgsRejectsNonFiniteData(testCase)
            h = adamnlopt.BFGSHessian(2);
            testCase.verifyFalse(h.update([1; NaN], [1; 1]));
            testCase.verifyFalse(h.update([1; 0], [Inf; 1]));
            testCase.verifyEqual(h.getMatrix(), eye(2), 'AbsTol', 0);
        end

        function testBfgsRejectsRoundOffCurvatureAndCountsIt(testCase)
            %   s'y > 0 alone admits pairs whose curvature is pure round-off;
            %   the relative floor s'y > sqrt(eps)*|s|*|y| is what keeps the
            %   y*y'/s'y term from exploding.  Unlike a zero step this IS a
            %   rejection and must be counted.
            h = adamnlopt.BFGSHessian(2);
            testCase.verifyFalse(h.update([1; 0], [1e-18; 1]));
            testCase.verifyEqual(h.nUpdates, 0);
            testCase.verifyEqual(h.nRejected, 1);
        end

        function testBfgsDampsNegativeCurvatureRatherThanDiscardingIt(testCase)
            %   Powell damping replaces y with phi*y + (1-phi)*B*s so that
            %   s'ybar >= powellEta*s'Bs > 0.  The pair is kept -- the point of
            %   damping is to use the step's information without losing
            %   positive definiteness -- so the update is ACCEPTED and the
            %   secant condition deliberately does not hold for the raw y.
            h = adamnlopt.BFGSHessian(2);
            h.update([1; 0], [2; 1]);          % first pair sets the B0 scale
            s = [0; 1];  y = -s;               % pure negative curvature
            testCase.verifyTrue(h.update(s, y), ...
                'a dampable pair must be accepted, not rejected');
            B = h.getMatrix();
            testCase.verifyGreaterThan(min(eig(B)), 0, ...
                'damping failed to preserve positive definiteness');
            testCase.verifyGreaterThanOrEqual(s.' * (B * s), ...
                h.powellEta * 1 - 1e-12, ...
                'damped curvature fell below powellEta*s''Bs');
        end

        function testBfgsCountsAcceptedUpdates(testCase)
            h = adamnlopt.BFGSHessian(3);
            for k = 1:3
                v = zeros(3, 1);  v(k) = 1;
                [s, y] = testCase.quadraticPair(v);
                h.update(s, y);
            end
            testCase.verifyEqual(h.nUpdates, 3);
            testCase.verifyEqual(h.nRejected, 0);
        end

        function testBfgsResetRestoresTheInitialModel(testCase)
            %   solve.m resets after a restoration phase, which jumps x and lam
            %   discontinuously; carrying the pre-jump curvature or its SCALE
            %   forward is what the reset exists to prevent.
            h = testCase.trainedBfgs();
            testCase.verifyGreaterThan(h.nUpdates, 0);
            h.reset();
            testCase.verifyEqual(h.getMatrix(), eye(3), 'AbsTol', 0);
            testCase.verifyEqual(h.nUpdates, 0);
            testCase.verifyEqual(h.gamma0, 1);
            testCase.verifyFalse(h.scaled, ...
                'reset must clear the one-shot B0 scaling flag');
        end

        function testBfgsIsUsableAgainAfterAReset(testCase)
            h = testCase.trainedBfgs();
            h.reset();
            s = [1; 0; 0];  y = [3; 1; 0];
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-12);
        end

        function testBfgsB0ScalingIsAppliedOnceAndRecorded(testCase)
            %   The one-shot scaling B0 = gamma*I is what makes the first step
            %   after a reset the right ORDER OF MAGNITUDE; without it the unit
            %   identity is arbitrarily wrong on a badly scaled problem.
            h = adamnlopt.BFGSHessian(2);
            testCase.verifyFalse(h.scaled);
            h.update([1; 0], [2; 1]);
            testCase.verifyTrue(h.scaled);
            g0 = h.gamma0;
            h.update([0; 1], [1; 2]);
            testCase.verifyEqual(h.gamma0, g0, ...
                'the B0 scale must be frozen after the first pair');
        end

        function testBfgsScaleIsClampedIntoItsStatedRange(testCase)
            %   gamma = (y'y)/(s'y) explodes when y is nearly orthogonal to s;
            %   the gammaCurvCap and [gammaMin,gammaMax] clamps are the only
            %   thing standing between that and a 1e18 initial Hessian.
            h = adamnlopt.BFGSHessian(2);
            h.update([1; 0], [1e-9; 1]);
            testCase.verifyGreaterThanOrEqual(h.gamma0, h.gammaMin);
            testCase.verifyLessThanOrEqual(h.gamma0, h.gammaMax);
        end

        function testBfgsRebaseFlattensToTheNewScale(testCase)
            %   rebase is the conditioning recovery that keeps the ITERATE but
            %   re-derives the scale, as opposed to reset, which is for a
            %   discontinuous jump in x.  It takes a scalar curvature scale and
            %   discards the accumulated curvature entirely -- the documented
            %   choice, because a partial spectral correction cannot be made to
            %   keep B positive definite.
            h = testCase.trainedBfgs();
            gUsed = h.rebase(50);
            testCase.verifyEqual(gUsed, 50);
            testCase.verifyEqual(h.getMatrix(), 50 * eye(3), 'AbsTol', 0);
            testCase.verifyEqual(h.gammaBase, 50);
            testCase.verifyEqual(h.nRebases, 1);
        end

        function testBfgsRebaseLeavesTheFrozenDiagnosticAlone(testCase)
            %   gamma0 is deliberately NOT touched: it is the first-pair scale,
            %   and the drift logic compares the live gammaBase against it to
            %   decide how far the regime has moved.  Moving it with the rebase
            %   would make that comparison trivially true forever.
            h = testCase.trainedBfgs();
            g0 = h.gamma0;
            h.rebase(50);
            testCase.verifyEqual(h.gamma0, g0);
        end

        function testBfgsRebaseClampsItsScale(testCase)
            h = testCase.trainedBfgs();
            testCase.verifyEqual(h.rebase(1e99), h.gammaMax);
            testCase.verifyEqual(h.rebase(0), h.gammaMin);
        end

        %% ---------------------------------------------------------------
        %  LBFGSHessian
        %  ---------------------------------------------------------------
        function testLbfgsStartsAtTheIdentity(testCase)
            h = adamnlopt.LBFGSHessian(4, 3);
            testCase.verifyEqual(h.getMatrix(), eye(4), 'AbsTol', 0);
            testCase.verifyEqual(h.apply([1; 2; 3; 4]), [1; 2; 3; 4], ...
                'AbsTol', 0);
            testCase.verifyEqual(h.gamma, 1);
            testCase.verifyEqual(h.m, 3);
            testCase.verifyEqual(h.nDropped, 0);
        end

        function testLbfgsSatisfiesTheSecantConditionOnACleanPair(testCase)
            h = adamnlopt.LBFGSHessian(2, 5);
            s = [1; 0];  y = [2; 1];
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-12, ...
                'the compact representation violated the secant condition');
        end

        function testLbfgsSecantHoldsForTheNewestPairInASequence(testCase)
            h = testCase.trainedLbfgs(10);
            [s, y] = testCase.quadraticPair([1; -1; 1]);
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-9, ...
                'the newest undamped pair must be reproduced exactly');
        end

        function testLbfgsApplyAgreesWithGetMatrix(testCase)
            %   apply uses the compact form directly; getMatrix materializes
            %   it.  kkt_KKTOperator and kkt_assemble each pick one, so a
            %   discrepancy here is a silent inconsistency between the Krylov
            %   and direct solve paths.
            h = testCase.trainedLbfgs(10);
            B = h.getMatrix();
            V = [1 0 2; 0 1 -3; 0 0 1.5];
            for j = 1:size(V, 2)
                testCase.verifyEqual(h.apply(V(:, j)), B * V(:, j), ...
                    'AbsTol', 1e-10);
            end
        end

        function testLbfgsApplyAcceptsARowVector(testCase)
            h = testCase.trainedLbfgs(10);
            testCase.verifyEqual(h.apply([1, 2, 3]), h.apply([1; 2; 3]), ...
                'AbsTol', 1e-14);
        end

        function testLbfgsMatrixStaysSymmetricPositiveDefinite(testCase)
            h = testCase.trainedLbfgs(10);
            B = h.getMatrix();
            testCase.verifyEqual(B, B.', 'AbsTol', 0, ...
                'getMatrix must symmetrize the compact form');
            testCase.verifyGreaterThan(min(eig(B)), 0, ...
                'the compact L-BFGS model lost positive definiteness');
        end

        function testLbfgsDiagonalIsEmptyByContract(testCase)
            %   Documented: [] tells kkt_KKTOperator to leave op.diag empty and
            %   linalg_preconditioner to fall back to the identity.  Forming
            %   diag(getMatrix()) here would cost an n-by-n materialization per
            %   iteration, which is the whole reason the limited-memory model
            %   exists.
            h = adamnlopt.LBFGSHessian(3, 5);
            testCase.verifyEmpty(h.diagonal());
            testCase.verifyEmpty(testCase.trainedLbfgs(10).diagonal(), ...
                'diagonal() must stay empty after updates too');
        end

        function testLbfgsRejectsAZeroStep(testCase)
            h = adamnlopt.LBFGSHessian(2, 5);
            testCase.verifyFalse(h.update([0; 0], [1; 1]));
            testCase.verifyEqual(h.getMatrix(), eye(2), 'AbsTol', 0);
        end

        function testLbfgsRejectsNonFiniteData(testCase)
            h = adamnlopt.LBFGSHessian(2, 5);
            testCase.verifyFalse(h.update([1; 0], [NaN; 1]));
            testCase.verifyFalse(h.update([Inf; 0], [1; 1]));
            testCase.verifyEqual(h.getMatrix(), eye(2), 'AbsTol', 0);
        end

        function testLbfgsTamesRoundOffCurvatureIntoABoundedModel(testCase)
            %   The failure mode this guards is the documented one: gamma =
            %   (y'y)/(s'y) with s'y pure round-off gives a B0 of ~1e18, which
            %   ill-conditions the compact matrix B = gamma*I - Phi*(M\Phi'),
            %   drives its smallest eigenvalue negative, and corrupts the Newton
            %   step.  Unlike the dense model -- whose first pair skips damping
            %   and is therefore rejected outright by the curvature floor -- the
            %   compact model damps FIRST, so the pair is rescued rather than
            %   discarded.  Either outcome is acceptable; what is not acceptable
            %   is admitting the pair at its raw scale.
            s = [1; 0];  y = [1e-18; 1];
            rawGamma = (y.' * y) / (s.' * y);
            testCase.assertGreaterThan(rawGamma, 1e17, ...
                'fixture no longer reproduces the runaway scale');

            h = adamnlopt.LBFGSHessian(2, 5);
            h.update(s, y);
            testCase.verifyLessThan(h.gamma, 1e3, ...
                'the round-off scale reached B0 unattenuated');
            B = h.getMatrix();
            testCase.verifyGreaterThan(min(eig(B)), 0, ...
                'the compact model went indefinite on a round-off pair');
            testCase.verifyLessThan(cond(B), 1e6, ...
                'the compact model is ill-conditioned after one bad pair');
        end

        function testLbfgsDampsNegativeCurvatureRatherThanDiscardingIt(testCase)
            h = adamnlopt.LBFGSHessian(2, 5);
            h.update([1; 0], [2; 1]);
            s = [0; 1];
            testCase.verifyTrue(h.update(s, -s), ...
                'a dampable pair must be accepted, not rejected');
            B = h.getMatrix();
            testCase.verifyGreaterThan(min(eig(B)), 0, ...
                'damping failed to preserve positive definiteness');
        end

        function testLbfgsEvictsTheOldestPairAtTheMemoryLimit(testCase)
            %   The window is the entire point of the limited-memory model.  A
            %   model that has seen three pairs with m = 2 must be
            %   INDISTINGUISHABLE from a fresh model shown only the last two --
            %   the directions here are orthogonal, so no damping differs
            %   between the two histories.
            dirs = {[1; 0; 0], [0; 1; 0], [0; 0; 1]};
            scal = [2, 3, 5];

            windowed = adamnlopt.LBFGSHessian(3, 2);
            for k = 1:3
                windowed.update(dirs{k}, scal(k) * dirs{k});
            end

            fresh = adamnlopt.LBFGSHessian(3, 2);
            for k = 2:3
                fresh.update(dirs{k}, scal(k) * dirs{k});
            end

            testCase.verifyEqual(windowed.getMatrix(), fresh.getMatrix(), ...
                'AbsTol', 1e-12, ...
                'the oldest pair is still influencing the model');
            testCase.verifyEqual(windowed.gamma, fresh.gamma, ...
                'AbsTol', 1e-14);
        end

        function testLbfgsKeepsEveryPairBelowTheMemoryLimit(testCase)
            %   The counterpart to the eviction test: with room to spare, the
            %   oldest pair must still be there.  m = 3 and two pairs, so the
            %   first pair's secant information survives the second update in
            %   a way it cannot when the window has evicted it.
            dirs = {[1; 0; 0], [0; 1; 0]};
            full3 = adamnlopt.LBFGSHessian(3, 3);
            only2 = adamnlopt.LBFGSHessian(3, 3);
            for k = 1:2
                full3.update(dirs{k}, (k + 1) * dirs{k});
            end
            only2.update(dirs{2}, 3 * dirs{2});
            testCase.verifyNotEqual(full3.getMatrix(), only2.getMatrix(), ...
                'the first pair was dropped despite room in the window');
            testCase.verifyEqual(full3.apply(dirs{1}), 2 * dirs{1}, ...
                'AbsTol', 1e-12, ...
                'the retained first pair must still satisfy its secant');
        end

        function testLbfgsResetRestoresTheInitialModel(testCase)
            h = testCase.trainedLbfgs(10);
            h.reset();
            testCase.verifyEqual(h.getMatrix(), eye(3), 'AbsTol', 0);
            testCase.verifyEqual(h.gamma, 1);
            testCase.verifyEmpty(h.diagonal());
        end

        function testLbfgsIsUsableAgainAfterAReset(testCase)
            h = testCase.trainedLbfgs(10);
            h.reset();
            s = [1; 0; 0];  y = [3; 1; 0];
            testCase.verifyTrue(h.update(s, y));
            testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-12);
        end

        function testLbfgsScaleIsClampedIntoItsStatedRange(testCase)
            h = adamnlopt.LBFGSHessian(2, 5);
            h.update([1; 0], [1e-9; 1]);
            testCase.verifyGreaterThanOrEqual(h.gamma, h.gammaMin);
            testCase.verifyLessThanOrEqual(h.gamma, h.gammaMax);
        end

        function testLbfgsMemoryDefaultsWhenNotGiven(testCase)
            h = adamnlopt.LBFGSHessian(3);
            testCase.verifyEqual(h.m, 10, ...
                'the documented default memory is 10 pairs');
        end

        %% ---------------------------------------------------------------
        %  The two models against each other
        %  ---------------------------------------------------------------
        function testDenseAndCompactModelsAgreeOnTheFirstPair(testCase)
            %   With one stored pair the Byrd-Nocedal-Schnabel compact form IS
            %   the dense rank-2 BFGS update applied to the same B0, so the two
            %   implementations must produce the same matrix to round-off.
            %   They diverge afterwards BY DESIGN -- the dense model freezes its
            %   B0 scale after the first pair while the compact model refreshes
            %   gamma from the newest pair every time -- so this agreement is
            %   only asserted where the two models genuinely claim to agree.
            s = [1; 0];  y = [2; 1];
            dense = adamnlopt.BFGSHessian(2);
            compact = adamnlopt.LBFGSHessian(2, 5);
            dense.update(s, y);
            compact.update(s, y);
            testCase.verifyEqual(compact.getMatrix(), dense.getMatrix(), ...
                'AbsTol', 1e-12);
        end

        function testBothModelsReproduceAQuadraticAlongItsOwnStep(testCase)
            %   A shared sanity check: for a quadratic with Hessian A, the pair
            %   (s, A*s) carries exactly the curvature A has along s, and any
            %   secant model fed that pair must reproduce it.
            [s, y] = testCase.quadraticPair([1; 2; -1]);
            models = {adamnlopt.BFGSHessian(3), adamnlopt.LBFGSHessian(3, 5)};
            for k = 1:numel(models)
                h = models{k};
                h.update(s, y);
                testCase.verifyEqual(h.apply(s), y, 'AbsTol', 1e-10, ...
                    sprintf('%s missed the quadratic curvature', class(h)));
            end
        end

        %% ---------------------------------------------------------------
        %  hessianVecProduct
        %  ---------------------------------------------------------------
        function testHessianVecProductOnAPlainMatrix(testCase)
            H = [4 1 0; 1 3 1; 0 1 2];
            v = [1; -2; 3];
            testCase.verifyEqual(adamnlopt.hessianVecProduct(H, v), H * v, ...
                'AbsTol', 0);
        end

        function testHessianVecProductFlattensARowVector(testCase)
            %   The dispatcher does H*v(:) precisely so callers need not care;
            %   without the colon a row vector is a dimension-mismatch error.
            H = [4 1; 1 3];
            testCase.verifyEqual(adamnlopt.hessianVecProduct(H, [1, -2]), ...
                H * [1; -2], 'AbsTol', 0);
        end

        function testHessianVecProductDispatchesToTheModel(testCase)
            %   isa(H, 'adamnlopt.HessianModel') is the single positive test;
            %   a model must go through apply, never through H*v (which would
            %   error, a handle object having no mtimes).
            models = {testCase.trainedBfgs(), testCase.trainedLbfgs(10)};
            v = [1; -2; 3];
            for k = 1:numel(models)
                h = models{k};
                testCase.verifyEqual(adamnlopt.hessianVecProduct(h, v), ...
                    h.getMatrix() * v, 'AbsTol', 1e-10, ...
                    sprintf('%s dispatched wrong', class(h)));
            end
        end

        function testHessianVecProductIsLinearInV(testCase)
            %   The Krylov solvers assume the operator is linear; a model whose
            %   apply allocated or cached per-direction state would break that
            %   without breaking any single-vector test.
            models = {[4 1 0; 1 3 1; 0 1 2], testCase.trainedBfgs(), ...
                      testCase.trainedLbfgs(10)};
            u = [1; 0; -2];  w = [0.5; 3; 1];
            for k = 1:numel(models)
                H = models{k};
                lhs = adamnlopt.hessianVecProduct(H, 2 * u - 3 * w);
                rhs = 2 * adamnlopt.hessianVecProduct(H, u) ...
                    - 3 * adamnlopt.hessianVecProduct(H, w);
                testCase.verifyEqual(lhs, rhs, 'AbsTol', 1e-9);
            end
        end

        function testHessianVecProductIsSymmetric(testCase)
            %   u'Hv == v'Hu is what MINRES requires of the operator; both
            %   models are symmetric by construction and must stay so.
            models = {testCase.trainedBfgs(), testCase.trainedLbfgs(10)};
            u = [1; 0; -2];  w = [0.5; 3; 1];
            for k = 1:numel(models)
                H = models{k};
                testCase.verifyEqual( ...
                    u.' * adamnlopt.hessianVecProduct(H, w), ...
                    w.' * adamnlopt.hessianVecProduct(H, u), ...
                    'AbsTol', 1e-10);
            end
        end

        %% ---------------------------------------------------------------
        %  lagrangianHessian
        %  ---------------------------------------------------------------
        function testLagrangianHessianMatchesTheDerivestOracle(testCase)
            %   Unconstrained: the Lagrangian is just f, so forward-differencing
            %   the ANALYTIC gradient should land within a few parts in 1e8 of
            %   Richardson extrapolation.  Rosenbrock is used because its
            %   Hessian entries span three orders of magnitude, which catches a
            %   step rule that is right only for O(1) curvature.
            x = [-1.2; 1];
            ev = testCase.evaluatorFor(@AdamNlOptTestCase.rosenbrock, 2);
            H = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), zeros(0, 1), ...
                adamnlopt.defaultOptions());
            Href = testCase.hessianOracle(@testCase.rosenbrockGrad, x);
            testCase.verifyEqual(H, Href, 'RelTol', 1e-5, 'AbsTol', 1e-4);
        end

        function testLagrangianHessianIncludesTheConstraintCurvature(testCase)
            %   L = f + lamE'*cE + lamI'*cI.  A multiplier-weighted constraint
            %   Hessian that went missing would leave the KKT system with the
            %   objective curvature only -- which still converges on linear
            %   constraints and fails on curved ones, the hardest kind of bug
            %   to see from the outside.
            x = [0.6; -0.8];
            lamE = 2.5;
            ev = testCase.evaluatorFor(@AdamNlOptTestCase.sumCoords, 2, ...
                @AdamNlOptTestCase.unitCircleEq, 0, 1);
            H = adamnlopt.lagrangianHessian(ev, x, lamE, zeros(0, 1), ...
                adamnlopt.defaultOptions());
            Href = testCase.hessianOracle( ...
                @(z) testCase.circleLagrangianGrad(z, lamE), x);
            testCase.verifyEqual(H, Href, 'RelTol', 1e-5, 'AbsTol', 1e-5);
            testCase.verifyEqual(H, 2 * lamE * eye(2), 'AbsTol', 1e-5, ...
                'the analytic Lagrangian Hessian here is exactly 2*lamE*I');
        end

        function testLagrangianHessianIncludesInequalityCurvature(testCase)
            x = [0.3; 0.4];
            lamI = 1.5;
            ev = testCase.evaluatorFor(@AdamNlOptTestCase.distanceTo21, 2, ...
                @AdamNlOptTestCase.unitDiskIneq, 1, 0);
            H = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), lamI, ...
                adamnlopt.defaultOptions());
            testCase.verifyEqual(H, (2 + 2 * lamI) * eye(2), 'AbsTol', 1e-5);
        end

        function testLagrangianHessianIsSymmetric(testCase)
            %   Forward differencing a gradient gives an unsymmetric matrix to
            %   O(h); the explicit (H+H')/2 is what the inertia test and the
            %   LDL' factorization both depend on.
            x = [0.7; 1.3];
            ev = testCase.evaluatorFor(@AdamNlOptTestCase.beale, 2);
            H = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), zeros(0, 1), ...
                adamnlopt.defaultOptions());
            testCase.verifyEqual(H, H.', 'AbsTol', 0);
        end

        function testLagrangianHessianHonoursTheHessPattern(testCase)
            %   Columns with disjoint row supports are perturbed together, so a
            %   wrong colouring shows up as cross-talk between blocks.  Entries
            %   outside the pattern must come back EXACTLY zero, not merely
            %   small, and the in-pattern entries must match the dense run.
            x = [1.1; -0.4; 0.7; 2];
            ev = testCase.evaluatorFor(@AdamNlOptTestCase.powellQuartic, 4);
            opts = adamnlopt.defaultOptions();
            dense = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), ...
                zeros(0, 1), opts);

            P = logical(dense) | logical(dense.');
            P = P | eye(4) > 0;
            opts.HessPattern = double(P);
            sparsed = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), ...
                zeros(0, 1), opts);

            testCase.verifyEqual(sparsed(~P), zeros(nnz(~P), 1), 'AbsTol', 0, ...
                'entries outside the pattern must stay exactly zero');
            testCase.verifyEqual(sparsed(P), dense(P), 'AbsTol', 1e-6, ...
                'the coloured path disagreed with the dense path');
        end

        function testLagrangianHessianUsesAUserSuppliedHessianFcn(testCase)
            %   The analytic path short-circuits everything: no evaluator calls
            %   at all, and the multipliers arrive in fmincon's lambda struct
            %   with the eqnonlin/ineqnonlin names.
            opts = adamnlopt.defaultOptions();
            seen = struct('called', 0, 'eq', [], 'ineq', []);
            opts.HessianFcn = @hessFcn;
            H = adamnlopt.lagrangianHessian([], [1; 2], 7, 9, opts);
            testCase.verifyEqual(seen.called, 1);
            testCase.verifyEqual(seen.eq, 7);
            testCase.verifyEqual(seen.ineq, 9);
            testCase.verifyEqual(H, [1 2; 2 4], 'AbsTol', 0, ...
                'the user Hessian must be symmetrized, not returned raw');

            function Hu = hessFcn(~, lambda)
                seen.called = seen.called + 1;
                seen.eq     = lambda.eqnonlin;
                seen.ineq   = lambda.ineqnonlin;
                Hu = [1 3; 1 4];          % deliberately unsymmetric
            end
        end

        function testLagrangianHessianCostsOneGradientPerColour(testCase)
            %   The saving the colouring exists for.  Powell's quartic has a
            %   block-separable pattern, so the coloured run must make strictly
            %   fewer objective evaluations than the dense n+1.
            x = [1.1; -0.4; 0.7; 2];
            opts = adamnlopt.defaultOptions();

            evDense = testCase.evaluatorFor(@AdamNlOptTestCase.powellQuartic, 4);
            adamnlopt.lagrangianHessian(evDense, x, zeros(0, 1), ...
                zeros(0, 1), opts);

            opts.HessPattern = double(logical(eye(4)));
            evSparse = testCase.evaluatorFor(@AdamNlOptTestCase.powellQuartic, 4);
            adamnlopt.lagrangianHessian(evSparse, x, zeros(0, 1), ...
                zeros(0, 1), opts);

            testCase.verifyLessThan(evSparse.nFun, evDense.nFun, ...
                'a diagonal HessPattern must cost fewer gradients than dense');
        end
    end

    %% ------------------------------------------------------------------
    %  Fixtures and oracles
    %  ------------------------------------------------------------------
    methods (Access = private)
        function h = trainedBfgs(testCase)
            %TRAINEDBFGS  A dense model fed three orthogonal quadratic pairs.
            h = adamnlopt.BFGSHessian(3);
            for k = 1:3
                v = zeros(3, 1);  v(k) = 1;
                [s, y] = testCase.quadraticPair(v);
                h.update(s, y);
            end
        end

        function h = trainedLbfgs(testCase, memory)
            %TRAINEDLBFGS  The same three pairs through the compact model.
            h = adamnlopt.LBFGSHessian(3, memory);
            for k = 1:3
                v = zeros(3, 1);  v(k) = 1;
                [s, y] = testCase.quadraticPair(v);
                h.update(s, y);
            end
        end

        function [s, y] = quadraticPair(~, s)
            %QUADRATICPAIR  The exact secant pair of a fixed SPD quadratic.
            %   Deterministic on purpose: the suite elsewhere asserts that the
            %   package leaves the global RNG alone, so no test here may seed
            %   it.
            A = [4 1 0; 1 3 1; 0 1 2];
            s = s(:);
            y = A * s;
        end

        function H = hessianOracle(~, gradFcn, x)
            %HESSIANORACLE  An independent Hessian: the Jacobian of the gradient.
            %   DERIVESTsuite's hessian() cannot be used on this repo: its body
            %   is a parfor whose sliced indexing violates parfor's own rules,
            %   so it fails to compile before it ever runs.  jacobianest of the
            %   ANALYTIC gradient is the same Richardson extrapolation one
            %   derivative down, and is the sharper oracle for exactly the thing
            %   under test -- lagrangianHessian also differences that gradient,
            %   but with a single forward step of sqrt(eps).
            H = AdamNlOptTestCase.quietJacobianest(gradFcn, x);
            H = (H + H.') / 2;
        end

        function g = rosenbrockGrad(~, z)
            %ROSENBROCKGRAD  The analytic objective gradient alone, as a column.
            [~, g] = AdamNlOptTestCase.rosenbrock(z);
        end

        function g = circleLagrangianGrad(~, z, lamE)
            %CIRCLELAGRANGIANGRAD  grad(f + lamE'*ceq) for sumCoords/unitCircle.
            [~, g]      = AdamNlOptTestCase.sumCoords(z);
            [~, ~, ~, gceq] = AdamNlOptTestCase.unitCircleEq(z);
            g = g + gceq * lamE;
        end

        function ev = evaluatorFor(~, objFun, n, nlcon, mInl, mEnl)
            %EVALUATORFOR  A minimal Evaluator over the 11 required fields.
            if nargin < 4, nlcon = [];  mInl = 0;  mEnl = 0; end
            problem = struct( ...
                'objFun',     objFun, ...
                'hasObjGrad', true, ...
                'nlcon',      nlcon, ...
                'hasConGrad', ~isempty(nlcon), ...
                'Aineq',      zeros(0, n), 'bineq', zeros(0, 1), ...
                'Aeqlin',     zeros(0, n), 'beqlin', zeros(0, 1), ...
                'n',          n, ...
                'mInl',       mInl, ...
                'mEnl',       mEnl);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());
        end
    end

end
