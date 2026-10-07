classdef AdamNlOptLinearAlgebraTest < AdamNlOptTestCase
%ADAMNLOPTLINEARALGEBRATEST  Contract tests for the kkt_*, linalg_* and step_*
%   layer -- the numerical core underneath adamnlopt.solve.
%
%   These modules are small, pure and side-effect free, which makes them the
%   one place in the package where the contract can be checked directly rather
%   than inferred from a converged solve.  Every assertion here is against an
%   independent oracle: a densely assembled matrix, a backslash solve, an
%   eigenvalue count, or a property the mathematics guarantees (symmetry,
%   orthogonality, a trust-region bound).  Nothing is compared against the
%   solver's own opinion of itself.
%
%   No Optimization Toolbox anywhere.
%
%   See also ADAMNLOPTTESTCASE, ADAMNLOPTSOLVETEST.

    properties (TestParameter)
        krylovMethod = {'minres', 'gmres'};
        precondition = {'none', 'jacobi'};
    end

    methods (Test)

        %% ================================================================
        %  kkt_KKTOperator -- the matrix-free mirror of kkt_assemble
        %  ================================================================

        function testOperatorMaterializesToTheAssembledMatrix(testCase)
            %   The operator and the assembler are two implementations of one
            %   matrix, and the direct and Krylov paths must be solving the
            %   same system.  Materialize the operator column by column and
            %   require exact agreement.
            [state, res, reg] = testCase.kktFixture();
            K = adamnlopt.kkt_assemble(state, res, reg);
            op = adamnlopt.kkt_KKTOperator(state, reg);

            N = op.n + op.mE;
            Kop = zeros(N);
            for j = 1:N
                e = zeros(N, 1);  e(j) = 1;
                Kop(:, j) = op.apply(e);
            end

            testCase.verifyEqual(Kop, full(K), 'AbsTol', 1e-12, ...
                ['the matrix-free operator and the assembled KKT matrix ' ...
                 'disagree -- the direct and Krylov paths are solving ' ...
                 'different systems']);
        end

        function testOperatorIsSymmetric(testCase)
            [state, ~, reg] = testCase.kktFixture();
            op = adamnlopt.kkt_KKTOperator(state, reg);
            rng(7);
            u = randn(op.n + op.mE, 1);
            v = randn(op.n + op.mE, 1);

            % u'Kv == v'Ku for a symmetric K, with no matrix in sight.
            testCase.verifyEqual(u.' * op.apply(v), v.' * op.apply(u), ...
                'RelTol', 1e-12, 'the KKT operator is not symmetric');
        end

        function testOperatorDiagonalMatchesTheAssembledDiagonal(testCase)
            [state, res, reg] = testCase.kktFixture();
            K = adamnlopt.kkt_assemble(state, res, reg);
            op = adamnlopt.kkt_KKTOperator(state, reg);

            testCase.verifyEqual(op.diag, full(diag(K)), 'AbsTol', 1e-12);
        end

        function testPrecondDiagIsStrictlyPositive(testCase)
            %   The Jacobi preconditioner has to be SPD for MINRES to be legal,
            %   which abs(diag(K)) cannot deliver: the (2,2) block is -gamma*I
            %   and gamma is zero unless the inertia correction fired, so the
            %   dual entries would be exactly zero.  Hence the Schur-complement
            %   estimate -- and hence this test.
            [state, ~, reg] = testCase.kktFixture();
            reg.gamma = 0;
            op = adamnlopt.kkt_KKTOperator(state, reg);

            testCase.verifyNumElements(op.precondDiag, op.n + op.mE);
            testCase.verifyGreaterThan(min(op.precondDiag), 0, ...
                ['a non-positive preconditioner diagonal makes the Jacobi ' ...
                 'preconditioner indefinite and MINRES undefined']);
        end

        function testOperatorDiagonalsAreEmptyForAnLBFGSModel(testCase)
            %   An L-BFGS operator has no cheaply available diagonal, and the
            %   documented contract is [] rather than a fabricated one.
            [state, ~, reg] = testCase.kktFixture();
            state.H = adamnlopt.LBFGSHessian(numel(state.x), 5);
            op = adamnlopt.kkt_KKTOperator(state, reg);

            testCase.verifyEmpty(op.diag);
            testCase.verifyEmpty(op.precondDiag);
        end

        %% ================================================================
        %  kkt_residual
        %  ================================================================

        function testResidualVanishesAtAKKTPoint(testCase)
            %   min x'x/2 s.t. sum(x) = 1.  The exact solution is x = 1/n with
            %   lamE = -1/n, so every residual block is identically zero.
            n = 4;
            x = ones(n, 1) / n;
            state = struct('g', x, 'JE', ones(1, n), 'JI', [], ...
                'lamE', -1 / n, 'lamI', [], 'cE', sum(x) - 1, 'cI', [], ...
                's', []);

            res = adamnlopt.kkt_residual(state);

            testCase.verifyLessThan(res.opt,  1e-14);
            testCase.verifyLessThan(res.feas, 1e-14);
            testCase.verifyEqual(res.comp, 0);
        end

        function testResidualEmptyBlocksDropOutCleanly(testCase)
            %   An unconstrained state must give empty constraint blocks that
            %   still concatenate -- solve.m builds its right-hand side as
            %   -[res.rStat; res.rFeasE], and a block with the wrong
            %   orientation turns that into a dimension error rather than a
            %   degenerate-but-valid system.  The norms must read zero, not
            %   empty, so the termination test can compare them against a
            %   tolerance without a special case.
            state = struct('g', [1; 2], 'JE', [], 'JI', [], 'lamE', [], ...
                'lamI', [], 'cE', [], 'cI', [], 's', []);

            res = adamnlopt.kkt_residual(state);

            testCase.verifyEmpty(res.rFeasE);
            testCase.verifyEmpty(res.rFeasI);
            testCase.verifyEmpty(res.rComp);
            testCase.verifySize([res.rStat; res.rFeasE], [2, 1], ...
                'the empty equality block does not concatenate onto rStat');
            testCase.verifyEqual(res.feas, 0);
            testCase.verifyEqual(res.comp, 0);
            testCase.verifyEqual(res.opt, 2);
        end

        function testStationarityFollowsTheDocumentedSignConvention(testCase)
            %   L = f + lamE'cE + lamI'(cI+s) - zL'(x-l) - zU'(u-x), so the
            %   stationarity block is g + JE'lamE + JI'lamI - zL + zU.  A sign
            %   slip here is invisible in any norm-based check.
            state = struct('g', [1; 1], 'JE', [1 0], 'JI', [0 1], ...
                'lamE', 3, 'lamI', 5, 'cE', 0, 'cI', 0, 's', 1, ...
                'zL', [7; 0], 'zU', [0; 11]);

            res = adamnlopt.kkt_residual(state);

            testCase.verifyEqual(res.rStat, ...
                [1 + 3 - 7; 1 + 5 + 11], 'AbsTol', 1e-14);
        end

        %% ================================================================
        %  kkt_inertiaCorrection
        %  ================================================================

        function testInertiaCorrectionIsAnIdentityOnAWellPosedSystem(testCase)
            %   SPD H with a full-rank JE already has inertia (n, mE, 0), so a
            %   correct implementation must not perturb it at all.
            n = 4;  mE = 1;
            state = testCase.spdState(n, mE);
            res = adamnlopt.kkt_residual(state);
            reg0 = struct('delta', 0, 'gamma', 0);

            [d, idx, info, reg] = adamnlopt.kkt_inertiaCorrection( ...
                state, res, n, mE, reg0, adamnlopt.defaultOptions());

            testCase.verifyEqual(info.tries, 0, ...
                'a well-posed KKT system should need no correction');
            testCase.verifyEqual(reg.delta, 0);
            testCase.verifyEqual(reg.gamma, 0);
            testCase.verifyNumElements(d, n + mE);
            testCase.verifyEqual(idx.x, 1:n);
            testCase.verifyEqual(idx.lamE, n + (1:mE));
        end

        function testInertiaCorrectionFixesAnIndefiniteHessian(testCase)
            %   The point of the module: force inertia (n, mE, 0) on a system
            %   that does not have it.  The oracle is an eigenvalue count of
            %   the corrected matrix, computed here and not by the solver.
            n = 4;  mE = 1;
            state = testCase.spdState(n, mE);
            state.H = state.H - 20 * eye(n);     % now strongly indefinite
            res = adamnlopt.kkt_residual(state);

            [~, ~, info, reg] = adamnlopt.kkt_inertiaCorrection( ...
                state, res, n, mE, [], adamnlopt.defaultOptions());

            testCase.verifyGreaterThan(info.tries, 0, ...
                'the fixture is not actually indefinite');
            K = full(adamnlopt.kkt_assemble(state, res, reg));
            ev = eig((K + K.') / 2);
            testCase.verifyEqual(sum(ev > 0), n, ...
                'corrected system does not have n positive eigenvalues');
            testCase.verifyEqual(sum(ev < 0), mE, ...
                'corrected system does not have mE negative eigenvalues');
            testCase.verifyLessThanOrEqual(info.tries, 40);
        end

        function testCorrectedRegularizationIsReusableAsAWarmStart(testCase)
            %   solve.m feeds the previous iteration's reg back in as reg0.
            %   Since review D15 the first factorization always tries delta = 0
            %   and reg0 seeds only the first RETRY (delta_last/3, then x8), so
            %   the warm start must cost no more corrections than a cold start
            %   and land within the x8 growth step of the cold result.
            n = 4;  mE = 1;
            state = testCase.spdState(n, mE);
            state.H = state.H - 20 * eye(n);
            res = adamnlopt.kkt_residual(state);
            opts = adamnlopt.defaultOptions();

            [~, ~, ~, reg1] = adamnlopt.kkt_inertiaCorrection( ...
                state, res, n, mE, [], opts);
            [~, ~, info2, reg2] = adamnlopt.kkt_inertiaCorrection( ...
                state, res, n, mE, reg1, opts);

            [~, ~, info1] = adamnlopt.kkt_inertiaCorrection( ...
                state, res, n, mE, [], opts);
            testCase.verifyLessThanOrEqual(info2.tries, info1.tries, ...
                'a warm start must not cost more corrections than a cold one');
            testCase.verifyGreaterThan(reg2.delta, 0);
            testCase.verifyLessThanOrEqual(reg2.delta, 8 * reg1.delta);
        end

        %% ================================================================
        %  linalg_solveKKTdirect / linalg_solveKKTkrylov
        %  ================================================================

        function testDirectSolveMatchesBackslash(testCase)
            [state, res, reg] = testCase.kktFixture();
            [K, rhs] = adamnlopt.kkt_assemble(state, res, reg);

            d = adamnlopt.linalg_solveKKTdirect(K, rhs);

            testCase.verifyEqual(d, full(K) \ full(rhs), ...
                'AbsTol', 1e-9, 'RelTol', 1e-9);
        end

        function testKrylovReproducesTheDirectSolve(testCase, krylovMethod, precondition)
            %   Every method x preconditioner combination on one well-posed
            %   indefinite KKT system.  This is the fixture that proved, during
            %   the finding-60 hunt, that the linear solver itself was correct
            %   and the fault lay in how the caller used its flag.
            [state, res, reg] = testCase.kktFixture();
            [K, rhs] = adamnlopt.kkt_assemble(state, res, reg);
            dRef = full(K) \ full(rhs);

            op = adamnlopt.kkt_KKTOperator(state, reg);
            opts = adamnlopt.defaultOptions();
            opts.krylovMethod = krylovMethod;
            opts.precondition = precondition;
            applyP = adamnlopt.linalg_preconditioner(op, opts);

            [d, info] = adamnlopt.linalg_solveKKTkrylov( ...
                op, full(rhs), 1e-12, applyP, opts);

            testCase.verifyEqual(info.flag, 0, ...
                sprintf('%s/%s did not converge on a well-posed system', ...
                        krylovMethod, precondition));
            testCase.verifyEqual(info.method, krylovMethod);
            testCase.verifyEqual(d, dRef, 'AbsTol', 1e-8, 'RelTol', 1e-8);
        end

        function testKrylovFlagAgreesWithItsOwnReportedResidual(testCase, krylovMethod)
            %   FINDING 60.  MATLAB's gmres/minres test convergence on the
            %   PRECONDITIONED residual but report the TRUE one, so flag == 0
            %   did not mean the step solved the system.  Starve the solver and
            %   require the flag and the residual to tell the same story.
            rng(0);
            n = 14;
            B = randn(n);
            K = B + B.';
            rhs = randn(n, 1);
            op = struct('apply', @(v) K * v);

            [~, info] = adamnlopt.linalg_solveKKTkrylov(op, rhs, 1e-12, [], ...
                struct('krylovMethod', krylovMethod, 'krylovMaxIter', 1));

            testCase.verifyGreaterThan(info.relres, 1e-12, ...
                'the fixture is too easy -- one iteration should not solve it');
            testCase.verifyNotEqual(info.flag, 0, ...
                [krylovMethod ' reports convergence while its own relres ' ...
                 'misses the requested tolerance']);
        end

        %% ================================================================
        %  linalg_preconditioner / conditionEstimate / forcingSequence
        %  ================================================================

        function testNonePreconditionerIsExactlyTheIdentity(testCase)
            [state, ~, reg] = testCase.kktFixture();
            op = adamnlopt.kkt_KKTOperator(state, reg);
            opts = adamnlopt.defaultOptions();
            opts.precondition = 'none';
            applyP = adamnlopt.linalg_preconditioner(op, opts);

            rng(3);
            r = randn(op.n + op.mE, 1);
            testCase.verifyEqual(applyP(r), r);
        end

        function testJacobiPreconditionerNormalizesItsOwnDiagonal(testCase)
            %   Applying the preconditioner to the diagonal it was built from
            %   must return all ones -- the defining property, and the one that
            %   breaks if a clamp is applied absolutely rather than relatively.
            [state, ~, reg] = testCase.kktFixture();
            op = adamnlopt.kkt_KKTOperator(state, reg);
            opts = adamnlopt.defaultOptions();
            opts.precondition = 'jacobi';
            applyP = adamnlopt.linalg_preconditioner(op, opts);

            testCase.verifyEqual(applyP(op.precondDiag), ...
                ones(op.n + op.mE, 1), 'AbsTol', 1e-12);
        end

        function testUniformlyTinyDiagonalIsNotFlattenedByAnAbsoluteFloor(testCase)
            %   A system scaled down by 1e-10 is perfectly well conditioned; an
            %   absolute floor would clamp every entry to the same value and
            %   silently turn the Jacobi preconditioner into the identity.
            [state, ~, reg] = testCase.kktFixture();
            state.H  = 1e-10 * state.H;
            state.JE = 1e-10 * state.JE;
            op = adamnlopt.kkt_KKTOperator(state, reg);
            opts = adamnlopt.defaultOptions();
            opts.precondition = 'jacobi';
            applyP = adamnlopt.linalg_preconditioner(op, opts);

            testCase.verifyEqual(applyP(op.precondDiag), ...
                ones(op.n + op.mE, 1), 'AbsTol', 1e-8, ...
                'the preconditioner collapsed under a uniform rescaling');
        end

        function testConditionEstimateLeavesTheGlobalRngAlone(testCase)
            %   normest/condest draw random vectors.  A module that perturbs
            %   the global stream makes every downstream stochastic test
            %   irreproducible, and the bug only shows up elsewhere.
            rng(42);
            A = sprandsym(60, 0.2) + 60 * speye(60);
            % Snapshot AFTER building the fixture: sprandsym draws from the
            % same stream, so capturing earlier measures the fixture, not the
            % function under test.
            before = rng;

            adamnlopt.linalg_conditionEstimate(A, 1000);

            testCase.verifyEqual(rng, before, ...
                'linalg_conditionEstimate disturbed the global RNG state');
        end

        function testConditionEstimateIsRepeatableAndMatchesCond(testCase)
            rng(5);
            A = full(sprandsym(30, 0.5) + 30 * speye(30));

            c1 = adamnlopt.linalg_conditionEstimate(A, 1000);
            c2 = adamnlopt.linalg_conditionEstimate(A, 1000);

            testCase.verifyEqual(c1, c2, ...
                'repeated calls on the same matrix disagree');
            % An estimate, not an evaluation: one order of magnitude either way.
            testCase.verifyGreaterThan(c1, cond(A) / 10);
            testCase.verifyLessThan(c1, cond(A) * 10);
        end

        function testConditionEstimateDeclinesToMaterializeALargeOperator(testCase)
            %   nMax governs the MATRIX-FREE branch only: materializing an
            %   operator costs n mat-vecs, so above the cap the honest answer
            %   is NaN ("unknown"), which a caller must not read as a small
            %   condition number.  A numeric matrix is never capped -- cond and
            %   condest are cheap enough -- so the fixture has to be an
            %   operator, not a sparse identity.
            op = adamnlopt.kkt_KKTOperator( ...
                struct('H', eye(40), 'JE', ones(2, 40), ...
                       'x', zeros(40, 1), 'lamE', zeros(2, 1)), []);

            testCase.verifyTrue(isnan(adamnlopt.linalg_conditionEstimate(op, 10)), ...
                'an operator above nMax must return NaN, not an expensive answer');
            testCase.verifyFalse(isnan(adamnlopt.linalg_conditionEstimate(op, 1000)), ...
                'an operator below nMax must be materialized and estimated');
        end

        function testForcingSequenceStaysInsideItsClamps(testCase)
            opts = adamnlopt.defaultOptions();
            rng(11);
            for k = 1:50
                eta = adamnlopt.linalg_forcingSequence( ...
                    10 ^ (4 * rand - 6), 10 ^ (4 * rand - 6), rand, opts);
                testCase.verifyGreaterThanOrEqual(eta, opts.forcingEtaMin);
                testCase.verifyLessThanOrEqual(eta, opts.forcingEtaMax);
            end
        end

        function testForcingSequenceStartsAtTheCeiling(testCase)
            %   With no history there is nothing to extrapolate from, so the
            %   first solve is the loosest one the clamps allow.
            opts = adamnlopt.defaultOptions();
            eta = adamnlopt.linalg_forcingSequence(1, [], [], opts);
            testCase.verifyEqual(eta, opts.forcingEtaMax);
        end

        function testForcingSequenceTightensAsTheResidualFalls(testCase)
            %   Eisenstat-Walker choice 2: eta tracks (|F_new|/|F_old|)^alpha,
            %   so a faster-shrinking residual must buy a tighter solve.
            %   etaPrev is [] to disable the over-decrease safeguard, which
            %   would otherwise floor both arms at the same value and hide the
            %   ratio term entirely; the clamps are widened for the same
            %   reason.
            opts = adamnlopt.defaultOptions();
            opts.forcingEtaMin = 1e-14;
            opts.forcingEtaMax = 0.9;
            etaFast = adamnlopt.linalg_forcingSequence(1e-6, 1, [], opts);
            etaSlow = adamnlopt.linalg_forcingSequence(1e-1, 1, [], opts);

            testCase.verifyLessThan(etaFast, etaSlow, ...
                'the forcing term is not monotone in the residual ratio');
        end

        function testOverDecreaseSafeguardFloorsTheForcingTerm(testCase)
            %   Eisenstat-Walker eq. 3.2: when gamma*etaPrev^alpha exceeds 0.1
            %   the term is not allowed to collapse in one step, because an
            %   over-eager tightening wastes Krylov iterations on a step the
            %   nonlinear iteration is about to throw away.  Below 0.1 the
            %   guard is inactive and the raw ratio stands.
            opts = adamnlopt.defaultOptions();
            opts.forcingEtaMin = 1e-14;
            opts.forcingEtaMax = 0.9;

            guarded   = adamnlopt.linalg_forcingSequence(1e-8, 1, 0.5, opts);
            unguarded = adamnlopt.linalg_forcingSequence(1e-8, 1, 1e-4, opts);

            testCase.verifyEqual(guarded, ...
                opts.forcingGamma * 0.5 ^ opts.forcingAlpha, 'RelTol', 1e-12, ...
                'the over-decrease safeguard did not hold the forcing term up');
            testCase.verifyLessThan(unguarded, guarded, ...
                'the safeguard fired below its own 0.1 activation threshold');
        end

        %% ================================================================
        %  step_*
        %  ================================================================

        function testNormalStepRespectsTheTrustRegion(testCase)
            rng(1);
            JE = randn(2, 5);
            cE = randn(2, 1);
            for Delta = [1e-3, 0.1, 1, 100]
                v = adamnlopt.step_normalStep(JE, cE, Delta);
                testCase.verifyLessThanOrEqual(norm(v), Delta * (1 + 1e-10), ...
                    sprintf('normal step left the trust region at Delta = %g', Delta));
            end
        end

        function testNormalStepLiesInTheRangeOfJEtranspose(testCase)
            %   The Byrd-Omojokun normal step is a minimum-norm feasibility
            %   correction, so it must carry no component in null(JE) -- that
            %   is the tangential step's job, and a leak here double-counts.
            rng(2);
            JE = randn(2, 5);
            cE = randn(2, 1);
            v = adamnlopt.step_normalStep(JE, cE, 10);

            % Project out range(JE'); nothing should remain.
            resid = v - JE.' * ((JE * JE.') \ (JE * v));
            testCase.verifyLessThan(norm(resid), 1e-9 * max(1, norm(v)), ...
                'the normal step has a null-space component');
        end

        function testNormalStepIsZeroWhenAlreadyFeasible(testCase)
            rng(3);
            JE = randn(2, 5);
            v = adamnlopt.step_normalStep(JE, zeros(2, 1), 1);
            testCase.verifyLessThan(norm(v), 1e-12);
        end

        function testTangentialStepStaysInTheNullSpace(testCase)
            %   JE*u ~ 0 is what makes v + u preserve the feasibility the
            %   normal step just bought.
            rng(4);
            n = 5;
            H = eye(n);
            g = randn(n, 1);
            JE = randn(2, n);
            v = zeros(n, 1);

            u = adamnlopt.step_tangentialStep(H, g, JE, v, 1);

            testCase.verifyLessThan(norm(JE * u), 1e-8 * max(1, norm(u)), ...
                'the tangential step leaves the null space of JE');
            testCase.verifyLessThanOrEqual(norm(v + u), 1 + 1e-10);
        end

        function testTangentialStepIsZeroWhenTheNormalStepFillsTheRadius(testCase)
            rng(5);
            n = 5;
            JE = randn(2, n);
            v = randn(n, 1);
            u = adamnlopt.step_tangentialStep(eye(n), randn(n, 1), JE, v, ...
                0.5 * norm(v));
            testCase.verifyLessThan(norm(u), 1e-12, ...
                'no radius is left, so the tangential step must be zero');
        end

        function testTrustRegionSubproblemMatchesNewtonWhenUnconstrained(testCase)
            %   SPD H and a radius large enough not to bind: Steihaug-Toint
            %   must return the full Newton step.
            rng(6);
            n = 6;
            B = randn(n);
            H = B.' * B + n * eye(n);
            g = randn(n, 1);

            [p, info] = adamnlopt.step_trustRegionSubproblem(H, g, 1e6, 1e-12, 200);

            testCase.verifyEqual(p, -H \ g, 'AbsTol', 1e-7, 'RelTol', 1e-7);
            testCase.verifyFalse(info.boundary, ...
                'an interior Newton step was reported as hitting the boundary');
            testCase.verifyGreaterThanOrEqual(info.predRed, 0);
        end

        function testTrustRegionSubproblemStopsOnTheBoundaryUnderNegativeCurvature(testCase)
            %   Negative curvature means the model is unbounded below along
            %   that direction, so the only sane answer is the boundary.
            n = 4;
            H = -eye(n);
            g = ones(n, 1);
            Delta = 2;

            [p, info] = adamnlopt.step_trustRegionSubproblem(H, g, Delta, 1e-10, 100);

            testCase.verifyEqual(norm(p), Delta, 'RelTol', 1e-8);
            testCase.verifyTrue(info.boundary);
            testCase.verifyTrue(info.negCurv);
            testCase.verifyGreaterThanOrEqual(info.predRed, 0);
        end

        function testTrustRegionSubproblemReturnsZeroAtAStationaryPoint(testCase)
            p = adamnlopt.step_trustRegionSubproblem(eye(3), zeros(3, 1), 1, 1e-10, 50);
            testCase.verifyEqual(p, zeros(3, 1), 'AbsTol', 1e-14);
        end

        function testFractionToBoundaryKeepsTheIterateStrictlyInterior(testCase)
            v  = [1; 2; 0.5];
            dv = [-2; 1; -10];
            tau = 0.995;

            alpha = adamnlopt.step_fractionToBoundary(v, dv, tau);

            testCase.verifyGreaterThanOrEqual(alpha, 0);
            testCase.verifyLessThanOrEqual(alpha, 1);
            testCase.verifyGreaterThanOrEqual(min(v + alpha * dv), ...
                min((1 - tau) * v) - 1e-12, ...
                'the fraction-to-boundary rule let a variable leave the interior');
        end

        function testFractionToBoundaryIsUnrestrictedOnAnAscendingStep(testCase)
            testCase.verifyEqual(adamnlopt.step_fractionToBoundary( ...
                [1; 2], [3; 4], 0.995), 1, ...
                'a step that increases every positive variable cannot bind');
        end

        function testMultiplierUpdateSolvesTheNormalEquations(testCase)
            %   The least-squares multiplier estimate minimizes
            %   ||g + JE'lamE||, whose stationarity condition is
            %   JE*(g + JE'lamE) = 0.
            rng(8);
            n = 6;
            JE = randn(2, n);
            g  = randn(n, 1);

            lamE = adamnlopt.step_multiplierUpdate(g, JE);

            testCase.verifyLessThan(norm(JE * (g + JE.' * lamE)), 1e-8, ...
                'the multiplier estimate does not satisfy the normal equations');
        end

        function testMultiplierUpdateReturnsAnEmptyColumnWithNoEqualities(testCase)
            lamE = adamnlopt.step_multiplierUpdate([1; 2], zeros(0, 2));
            testCase.verifySize(lamE, [0, 1]);
        end

        function testUnitWeightsReproduceTheUnweightedEstimate(testCase)
            rng(9);
            JE = randn(2, 5);
            g  = randn(5, 1);
            testCase.verifyEqual( ...
                adamnlopt.step_multiplierUpdate(g, JE, ones(5, 1)), ...
                adamnlopt.step_multiplierUpdate(g, JE), ...
                'AbsTol', 1e-10, 'RelTol', 1e-10);
        end

        function testMultiplierUpdateLeaksNoRankWarnings(testCase)
            %   A rank-deficient JE is normal near a degenerate point; it must
            %   be handled, not warned about into the user's console.
            JE = [1 0 0; 1 0 0];          % duplicated row: rank 1 of 2
            testCase.verifyWarningFree(@() ...
                adamnlopt.step_multiplierUpdate([1; 2; 3], JE));
        end

    end

    %% ====================================================================
    %  Fixtures
    %  ====================================================================
    methods (Access = private)

        function [state, res, reg] = kktFixture(~)
            %KKTFIXTURE  A small, well-posed, genuinely indefinite KKT system.
            %   Hand-written rather than random so a failure is reproducible
            %   from the test source alone.  H is SPD and JE has full row rank,
            %   so the saddle-point matrix has inertia (4, 1, 0) and every
            %   solver in the package is required to handle it exactly.
            H = [3 1 0 0; 1 4 1 0; 0 1 5 1; 0 0 1 2];
            state = struct( ...
                'H',    H, ...
                'JE',   [2 9.5 7.6 2.8], ...
                'JI',   [], ...
                'x',    [0.5; -1.25; 2; 0.75], ...
                'g',    [1; -2; 0.5; 3], ...
                'lamE', 0.4, ...
                'lamI', [], ...
                'cE',   -0.7, ...
                'cI',   [], ...
                's',    []);
            res = adamnlopt.kkt_residual(state);
            reg = struct('delta', 0, 'gamma', 0);
        end

        function state = spdState(~, n, mE)
            %SPDSTATE  SPD Hessian, full-row-rank JE: inertia (n, mE, 0).
            rng(123);
            B = randn(n);
            H = B.' * B + n * eye(n);
            JE = randn(mE, n);
            state = struct('H', H, 'JE', JE, 'JI', [], ...
                'x', randn(n, 1), 'g', randn(n, 1), ...
                'lamE', zeros(mE, 1), 'lamI', [], ...
                'cE', randn(mE, 1), 'cI', [], 's', []);
        end

    end

end
