classdef AdamNlOptTest < matlab.unittest.TestCase
    %AdamNlOptTest Regression guards for the AdamNLOpt algorithm fixes.
    %
    % One test (or small group) per finding from the algorithm audit, each
    % written so it fails against the pre-fix behaviour:
    %
    %   1  projected-gradient optimality metric (util_projectedGradient)
    %   2  computeNTStep lamE double-subtraction (via the NT solve paths)
    %   3  NT trust-region ratio on the merit function (ditto)
    %   4  Schur conditioning probe uses the signed spectrum (eig, not svd)
    %   5  maxTime is enforced
    %   6  stepTol terminates a solve
    %   7  post-restoration multiplier reseed keeps the optW scale weight
    %   8  condensed Hessian diagonal add does not densify
    %   9  tangential step accepts a Hessian operator; QR null basis
    %  10  lagrangianHessian honours HessPattern and uses the forward-diff step
    %  11  slack floor is relative; the IP core seeds lamE by least squares
    %  12  inertia-correction escalation is capped and reports the cap
    %
    %
    % Second audit pass:
    %
    %  13  every nlcon call is counted (FD Jacobian probes were free)
    %  14  restoration is bounded by maxFunEvals and always reports .iters
    %  15  (removed with the Krylov path, review Batch 8)
    %  16  BFGS/L-BFGS curvature floor (the old test was algebraically inert)
    %  17  L-BFGS drops pairs that make the compact matrix singular
    %  18  elastic mode without quadprog (dual coordinate ascent)
    %  19  the second objective call made for a gradient is counted
    %  20/21  Broyden never displaces an analytic constraint Jacobian
    %  22  a missing or wrongly shaped analytic gradient is an error
    %  23  calibrateStep books probes to nFun / nCon separately
    %  24/25  the Broyden negligible-step test is relative to ||xRef||
    %  33  an operator condition estimate is exact or NaN, never a Ritz ratio
    %  34  one rank factorization per iteration, from a pivoted QR
    %  36  dropConstraints on a single-row working set (the diag(vector) trap)
    %  37  stagnation is net progress across the window, not its spread
    %  38  estimateNoise fills info on every return and reports h it sampled
    %  40  a reduced solve counts the calls expandResult makes at the solution
    %  41  the FD step transfer applies only to a step calibration measured
    %  42  an explicitly set FD step/type survives autoFDStep
    %  44  maxTime is the solver's budget exit, not the wrapper's output-fcn stop
    %  46  the Async parallel mode is off the UI and rewritten on load
    %  47  the parallel-availability probe is memoized and licence-aware
    %
    % 32 and 35 are covered by the tests for 15 and 14 respectively (the same
    % fix answered both); 39 and 43 were withdrawn as invalid; 45 is a guard
    % in the LVD-side wrapper with no headless entry point.
    %
    %
    % Third audit pass (kkt_assemble, linalg_solveKKTdirect, initializeIterate,
    % filterLineSearch, the rest of solve.m):
    %
    %  48  kkt_assemble keeps a sparse KKT system sparse, and takes a partially
    %      populated reg struct
    %  49  the zero-pivot tolerance is relative, so the inertia (the descent
    %      certificate) is invariant to a rescaling of the system
    %  50  the post-restoration slack re-seed shares the start-up seed's
    %      relative floor instead of its own absolute 1e-4
    %  51  the merit backup replays the filter's trials rather than re-running
    %      the whole backtracking sequence
    %  52  a failed line search never returns a step longer than aMax
    %
    % Findings 2, 3 and 9 sit on the default-off NT decomposition path, so
    % those tests switch useNTdecomp on explicitly.

    methods (TestClassSetup)
        function addPaths(~)
            ksptotAddProjectPaths();
        end
    end

    methods (Test)

        % --- 1: projected-gradient optimality metric -----------------------

        function testProjectedGradientNoFalseZeroWhenAllPinned(testCase)
            % Every variable pinned and every one pinned AGAINST its gradient:
            % the old row mask zeroed the whole metric and reported exitflag 1
            % from an arbitrary point.  The projection must keep the full
            % magnitude on each row.
            rd = [-3; -7];                      % rdFree = rd (no bound duals yet)
            zL = [0; 0];  zU = [0; 0];
            m = adamnlopt.util_projectedGradient(rd, zL, zU, [true; true], [false; false]);

            testCase.verifyEqual(m, [-3; -7], 'AbsTol', 0);
            testCase.verifyGreaterThan(norm(m, inf), 1);
        end

        function testProjectedGradientZeroWhenPinnedCorrectly(testCase)
            % Lower bound with rdFree >= 0 and upper bound with rdFree <= 0 are
            % both first-order optimal: those rows must contribute exactly zero.
            rd = [5; -5];
            zL = [0; 0];  zU = [0; 0];
            m = adamnlopt.util_projectedGradient(rd, zL, zU, [true; false], [false; true]);

            testCase.verifyEqual(m, [0; 0], 'AbsTol', 0);
        end

        function testProjectedGradientStripsBoundDualsAndKeepsFreeRows(testCase)
            % rdFree = rd + zL - zU; row 3 is free and must pass through intact.
            rd = [-2; 6; 9];
            zL = [4; 0; 0];                      % row 1: rdFree = 2 >= 0 -> optimal
            zU = [0; 4; 0];                      % row 2: rdFree = 2 >  0 -> violation at ub
            m = adamnlopt.util_projectedGradient(rd, zL, zU, ...
                [true; false; false], [false; true; false]);

            testCase.verifyEqual(m, [0; 2; 9], 'AbsTol', 1e-14);
        end

        function testProjectedGradientBothBoundsIsStationary(testCase)
            % A variable pinned at both bounds cannot move, so any sign is
            % stationary.
            m = adamnlopt.util_projectedGradient(-11, 0, 0, true, true);

            testCase.verifyEqual(m, 0, 'AbsTol', 0);
        end

        % --- 2 and 3: NT step multipliers and trust-region ratio -----------

        function testNTDecompEqualityCoreMatchesDefaultPath(testCase)
            % min x'x s.t. x1 + x2 = 2.  Analytic: x = [1;1], and the costate
            % must agree with the default (non-NT) path.  A dlamE that is an
            % absolute multiplier mistaken for an increment collapses the
            % update to lamE <- dlamE and moves the reported costate.
            fun = @sumSquaresObj;
            x0  = [3; -1];

            [xRef, ~, efRef, ~, lamRef] = adamnlopt.solve(fun, x0, [], [], ...
                [1 1], 2, [], [], [], testCase.quietOpts(struct('useNTdecomp', false)));
            [xNT, ~, efNT, ~, lamNT] = adamnlopt.solve(fun, x0, [], [], ...
                [1 1], 2, [], [], [], testCase.quietOpts(struct('useNTdecomp', true)));

            testCase.verifyGreaterThan(efRef, 0);
            testCase.verifyGreaterThan(efNT, 0);
            testCase.verifyEqual(xNT, [1; 1], 'AbsTol', 1e-6);
            testCase.verifyEqual(xNT, xRef, 'AbsTol', 1e-5);
            testCase.verifyEqual(lamNT.eqlin, lamRef.eqlin, 'AbsTol', 1e-4);
        end

        function testNTDecompInteriorPointCoreMatchesDefaultPath(testCase)
            % Bounds force the interior-point core, which is where the
            % condensed barrier LAGRANGIAN gradient was handed to computeNTStep
            % as if it were the objective gradient (lamE subtracted twice).
            % min (x-3)'(x-3) s.t. x1 + x2 = 2, 0 <= x <= 10 -> x = [1;1].
            fun = @(x) shiftedSumSquaresObj(x, 3);
            x0  = [0.5; 0.5];
            lb  = [0; 0];  ub = [10; 10];

            [~, ~, efRef, ~, lamRef] = adamnlopt.solve(fun, x0, [], [], ...
                [1 1], 2, lb, ub, [], testCase.quietOpts(struct('useNTdecomp', false)));
            [xNT, ~, efNT, ~, lamNT] = adamnlopt.solve(fun, x0, [], [], ...
                [1 1], 2, lb, ub, [], testCase.quietOpts(struct('useNTdecomp', true)));

            % Analytic costate: 2*(x1 - 3) + lamE = 0 at x1 = 1, so lamE = 4.
            % Anchored to that rather than to the reference path, which exits on
            % its step tolerance after two iterations and is itself only good
            % to ~3e-3 here.  Collapsing lamE to an increment moves this by O(1).
            testCase.verifyGreaterThan(efRef, 0);
            testCase.verifyGreaterThan(efNT, 0);
            testCase.verifyEqual(xNT, [1; 1], 'AbsTol', 1e-5);
            testCase.verifyEqual(lamNT.eqlin, 4, 'AbsTol', 1e-4);
            testCase.verifyEqual(lamRef.eqlin, 4, 'AbsTol', 1e-2);
        end

        % --- 4: Schur conditioning probe on the signed spectrum ------------

        function testSchurProbeDeclinesIndefiniteS(testCase)
            % W = diag([1 -1]), JE = I  =>  S = W^-1 = diag([1 -1]), indefinite.
            % svd sees |lambda| = [1 1] and reports a perfectly conditioned S;
            % eig sees the negative eigenvalue, which no positive shift can fix.
            [state, res] = testCase.kktFixture(diag([1 -1]), eye(2));
            opts = testCase.probeOpts(1e8);

            [~, ~, info] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 2, [], opts);

            testCase.verifyEqual(info.schur.skipReason, 6);
            testCase.verifyFalse(info.schur.ran);
            testCase.verifyEqual(info.gammaFixA, 0);
        end

        function testSchurProbeBoundsConditionOfDefiniteS(testCase)
            % W = I, JE = diag([1 1e-8])  =>  S = diag([1 1e-16]), cond 1e16.
            % The shift must bring cond(S + gamma*I) down to dualCondMax.
            condMax = 1e8;
            [state, res] = testCase.kktFixture(eye(2), diag([1 1e-8]));
            opts = testCase.probeOpts(condMax);

            [~, ~, info] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 2, [], opts);

            testCase.verifyTrue(info.schur.ran);
            testCase.verifyEqual(info.schur.skipReason, 0);
            testCase.verifyGreaterThan(info.gammaFixA, 0);

            % cond(S + gamma*I) = (sMax + gamma)/(sMin + gamma); with
            % gamma = sMax/condMax - sMin that is exactly condMax + 1, so allow
            % a hair over the target rather than demanding it be met below.
            shifted = [1 1e-16] + info.gammaFixA;
            testCase.verifyLessThanOrEqual(max(shifted) / min(shifted), condMax * (1 + 1e-6));
            testCase.verifyGreaterThan(1 / 1e-16, condMax);       % premise: S was worse
        end

        % --- 5: maxTime is enforced ----------------------------------------

        function testMaxTimeStopsTheSolve(testCase)
            opts = adamnlopt.defaultOptions();
            opts.maxTime = 10;
            [state, res] = testCase.termFixture();
            state.elapsed = 11;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifySubstring(msg, 'maximum time');
        end

        function testMaxTimeDoesNotStopEarly(testCase)
            opts = adamnlopt.defaultOptions();
            opts.maxTime = 10;
            [state, res] = testCase.termFixture();
            state.elapsed = 9.9;

            stop = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop);
        end

        % --- 6: stepTol terminates a solve ---------------------------------

        function testStepTolStopsAtFeasiblePoint(testCase)
            % Stationary as well as feasible, so this is a genuine convergence.
            % termFixture is deliberately NON-converged (opt = 1), which is the
            % stall case covered by the test below, not this one.
            opts = adamnlopt.defaultOptions();
            opts.stepTol = 1e-6;
            [state, res] = testCase.termFixture();
            state.stepNorm = 1e-12;
            res.opt = 1e-8;      % under objPlateauOptTol; res.comp = 1 still
                                 % blocks the exitflag-1 test above it
            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 2);        % fmincon's StepTolerance code
            testCase.verifySubstring(msg, 'StepTolerance');
            testCase.verifySubstring(msg, 'Converged');
        end

        function testStepTolStallIsNotReportedAsConverged(testCase)
            % Finding 54. The step-size exit gated on feasibility alone and
            % returned the converged code 2 with no optimality test whatever --
            % unlike the objective-plateau exit beside it. Measured on an
            % objective unbounded below (f = -1/||x||^2), solve returned
            % exitflag 2 with fval = -6.1e22 and "Converged: ... at a feasible
            % point (opt = 2.85e+34)". A collapsed step at a feasible but wildly
            % non-stationary point is a stall; it must stop, but as exitflag 0.
            opts = adamnlopt.defaultOptions();
            opts.stepTol = 1e-6;
            [state, res] = testCase.termFixture();   % opt = 1, far from stationary
            state.stepNorm = 1e-12;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 0);
            testCase.verifySubstring(msg, 'stalled');
            testCase.verifyNotEmpty(regexp(msg, '^Stopped', 'once'));
        end

        function testStepTolStallEndToEndIsNotPositive(testCase)
            % The end-to-end form of finding 54: an objective unbounded below
            % must never come back with a positive exitflag.
            fun = @(x) -1 / (x.' * x);
            [~, fval, exitflag] = adamnlopt.solve(fun, [1; 1], [], [], [], [], ...
                [], [], [], testCase.quietOpts(struct()));

            testCase.verifyLessThanOrEqual(exitflag, 0);
            testCase.verifyLessThan(fval, 0);
        end

        function testUnresolvedCompTolDoesNotBreakConvergence(testCase)
            % Finding 55. defaultOptions leaves compTol = [] and solve resolves
            % it to optTol after mapOptions, but terminationCheck read it raw.
            % `compScaled <= []` is not a logical scalar, and it is the third
            % operand of the exitflag-1 test -- so a caller driving
            % terminationCheck with a plain defaultOptions() struct ran fine
            % until the iterate actually converged and then errored with
            % MATLAB:nonLogicalConditional. Short-circuiting hid it completely.
            opts = adamnlopt.defaultOptions();
            testCase.assertEmpty(opts.compTol, ...
                'Fixture assumes the [] sentinel; see solve.m line 70.');
            [state, res] = testCase.termFixture();
            res.opt = 0;  res.feas = 0;  res.comp = 0;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, 1);
        end

        function testNonFiniteObjectiveBeatsTheConvergenceTest(testCase)
            % Finding 53. The non-finite guard sat BELOW the three convergence
            % exits, so a NaN objective whose residuals happened to come back
            % zero passed the exitflag-1 test and the guard -- which explicitly
            % tests ~isfinite(state.f) -- was unreachable. Measured:
            % solve(@(x) NaN, ...) returned exitflag 1, fval NaN, "Converged:
            % first-order optimality, feasibility, and complementarity within
            % tolerances."
            opts = adamnlopt.defaultOptions();
            [state, res] = testCase.termFixture();
            res.opt = 0;  res.feas = 0;  res.comp = 0;   % would pass exitflag 1
            state.f = NaN;

            [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, -3);
            testCase.verifySubstring(msg, 'not finite');
        end

        function testNonFiniteResidualBeatsTheConvergenceTest(testCase)
            % Same ordering bug reached through res.feas rather than state.f.
            opts = adamnlopt.defaultOptions();
            [state, res] = testCase.termFixture();
            res.opt = 0;  res.comp = 0;  res.feas = Inf;

            [stop, exitflag] = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyTrue(stop);
            testCase.verifyEqual(exitflag, -3);
        end

        function testNaNObjectiveSolveDoesNotReportConvergence(testCase)
            % The end-to-end form of finding 53.
            [~, fval, exitflag, output] = adamnlopt.solve(@(x) NaN, [1; 1], ...
                [], [], [], [], [], [], [], testCase.quietOpts(struct()));

            testCase.verifyEqual(exitflag, -3);
            testCase.verifyFalse(isfinite(fval));   % D21: a NaN objective reads +Inf
            testCase.verifyEmpty(regexp(output.message, 'Converged', 'once'));
        end

        function testStepTolDoesNotStopAtInfeasiblePoint(testCase)
            % A line search collapsing to alpha ~ 0 while infeasible is a
            % restoration trigger, not a solution.
            opts = adamnlopt.defaultOptions();
            opts.stepTol = 1e-6;
            [state, res] = testCase.termFixture();
            state.stepNorm = 1e-12;
            res.feas = 1;

            stop = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop);
        end

        function testStepTolDoesNotStopAtIterationZero(testCase)
            opts = adamnlopt.defaultOptions();
            opts.stepTol = 1e-6;
            [state, res] = testCase.termFixture();
            state.stepNorm = 1e-12;
            state.iter = 0;                            % no step has been taken

            stop = adamnlopt.terminationCheck(state, res, opts);

            testCase.verifyFalse(stop);
        end

        % --- 7: weighted multiplier reseed ---------------------------------

        function testWeightedMultiplierUpdateFitsInPhysicalUnits(testCase)
            % The post-restoration reseed dropped optW, so the fit was measured
            % in scaled-gradient units and the large-scale rows dominated.  The
            % weighted estimate must actually minimize the WEIGHTED residual.
            % Overdetermined on purpose: with mE = n the fit is exact and the
            % weights cannot matter, so a square JE would make this test vacuous.
            JE = [1, 1e6, 1];                          % mE = 1, n = 3
            g  = [2; 3; 5];
            w  = [1; 1e-6; 1];                         % optW = 1./Dx

            lamW = adamnlopt.step_multiplierUpdate(g, JE, w);
            lamU = adamnlopt.step_multiplierUpdate(g, JE);

            rW = norm(w .* (g + JE.' * lamW));
            rU = norm(w .* (g + JE.' * lamU));

            testCase.verifyLessThanOrEqual(rW, rU + 1e-12);
            testCase.verifyGreaterThan(norm(lamW - lamU), 1e-6);  % the weight is not inert
        end

        % --- 8: condensed Hessian diagonal add does not densify ------------

        function testCondensedDiagonalAddKeepsSparsityAndValue(testCase)
            % W = H + diag(sigL + sigU) for both the sparse and the dense form,
            % without ever materializing an n-by-n identity.
            n = 5;
            H = spdiags([ones(n,1), 4*ones(n,1), ones(n,1)], -1:1, n, n);
            sigLU = (1:n).';
            expected = full(H) + diag(sigLU);

            Wsp = H + spdiags(sigLU, 0, n, n);
            testCase.verifyTrue(issparse(Wsp));
            testCase.verifyEqual(full(Wsp), expected, 'AbsTol', 0);

            Wde = full(H);
            Wde(1:n+1:end) = Wde(1:n+1:end) + sigLU.';   % orientation matters
            testCase.verifyEqual(Wde, expected, 'AbsTol', 0);
        end

        % --- 9: tangential step operator support and QR null basis ---------

        function testTangentialStepAcceptsHessianOperator(testCase)
            % The docstring promised operator support but the body formed H*Z,
            % which a HessianModel does not implement at all.
            n = 4;
            B = adamnlopt.BFGSHessian(n);
            B.update([1;0;0;0], [2;0.3;0;0]);
            B.update([0;1;0;0], [0.3;3;0.2;0]);
            Bdense = B.getMatrix();

            g  = (1:n).';
            JE = [1 1 1 1; 1 -1 0 0];
            v  = zeros(n, 1);
            Delta = 1.0;

            uDense = adamnlopt.step_tangentialStep(Bdense, g, JE, v, Delta);
            uOp    = adamnlopt.step_tangentialStep(B,      g, JE, v, Delta);

            testCase.verifyEqual(uOp, uDense, 'AbsTol', 1e-10);
            testCase.verifyLessThan(norm(JE * uOp), 1e-10);     % stays in null(JE)
            testCase.verifyLessThanOrEqual(norm(uOp), Delta * (1 + 1e-10));
        end

        function testTangentialStepNullBasisMatchesNull(testCase)
            % Rank-deficient JE: rows 2 and 3 are multiples of row 1, so the
            % null space is 3-dimensional even though JE has 3 rows.  The QR
            % basis must find the same dimension null() does, and the step must
            % lie in it.
            JE = [1 2 3 4; 2 4 6 8; -1 -2 -3 -4];
            n  = 4;
            testCase.verifyEqual(size(null(JE), 2), 3);          % premise

            H = diag([1 2 3 4]);
            g = [1; -1; 1; -1];
            u = adamnlopt.step_tangentialStep(H, g, JE, zeros(n,1), 10);

            testCase.verifyLessThan(norm(JE * u) / norm(u), 1e-10);
            testCase.verifyGreaterThan(norm(u), 1e-6);           % a real step, not zero
        end

        function testTangentialStepSingleConstraintRow(testCase)
            % mE = 1 makes R a column vector, where diag() builds a matrix
            % instead of extracting a diagonal -- the rank count then comes
            % back as a vector and the basis slice errors outright.
            JE = [1 1];
            u = adamnlopt.step_tangentialStep(eye(2), [1; -1], JE, zeros(2,1), 1);

            testCase.verifyLessThan(abs(JE * u), 1e-12);
            testCase.verifyGreaterThan(norm(u), 1e-6);
            testCase.verifyLessThanOrEqual(norm(u), 1 + 1e-10);
        end

        function testTangentialStepFullRankJacobianPinsEveryDirection(testCase)
            JE = eye(3);
            u = adamnlopt.step_tangentialStep(eye(3), [1;2;3], JE, zeros(3,1), 10);

            testCase.verifyEqual(u, zeros(3,1), 'AbsTol', 1e-12);
        end

        % --- 10: HessPattern coloring and the forward-difference step ------

        function testHessPatternColoringMatchesDenseAndCostsFewerGradients(testCase)
            % Tridiagonal Lagrangian: columns three apart have disjoint row
            % supports, so three colours suffice regardless of n.
            n = 10;
            nGrad = 0;
            ev = struct('objective', @obj, 'jacobian', @jac);
            x  = (1:n).' / 10;
            P  = logical(spdiags(ones(n,3), -1:1, n, n));

            optsP = adamnlopt.defaultOptions();
            optsP.HessPattern = P;
            Hp = adamnlopt.lagrangianHessian(ev, x, zeros(0,1), zeros(0,1), optsP);
            nGradPatterned = nGrad;

            nGrad = 0;
            optsD = adamnlopt.defaultOptions();
            Hd = adamnlopt.lagrangianHessian(ev, x, zeros(0,1), zeros(0,1), optsD);
            nGradDense = nGrad;

            Hexact = full(spdiags([ones(n,1), 2*ones(n,1), ones(n,1)], -1:1, n, n));

            testCase.verifyEqual(Hp, Hexact, 'AbsTol', 1e-6);
            testCase.verifyEqual(Hp, Hd, 'AbsTol', 1e-6);
            testCase.verifyEqual(nGradDense, n + 1);
            testCase.verifyLessThanOrEqual(nGradPatterned, 5);   % 1 base + 3 colours

            function [f, g] = obj(z)
                nGrad = nGrad + 1;
                f = sum(z.^2) + sum(z(1:end-1) .* z(2:end));
                g = 2 * z;
                g(1:end-1) = g(1:end-1) + z(2:end);
                g(2:end)   = g(2:end)   + z(1:end-1);
            end
            function [JE, JI] = jac(~)
                JE = zeros(0, n);  JI = zeros(0, n);
            end
        end

        function testHessPatternOutsidePatternStaysExactlyZero(testCase)
            % Entries outside the pattern must be left at exactly zero, not
            % merely small: that is what lets structurally independent columns
            % be differenced simultaneously.  A diagonal Hessian with a
            % diagonal pattern colours into ONE group, so the whole Hessian
            % costs a single extra gradient.
            n = 4;
            c = [1; 2; 3; 4];
            A = diag(2 * c);
            ev = struct('objective', @(z) deal(sum(c .* z.^2), 2 * c .* z), ...
                        'jacobian',  @(~) deal(zeros(0,n), zeros(0,n)));

            opts = adamnlopt.defaultOptions();
            opts.HessPattern = logical(eye(n));
            H = adamnlopt.lagrangianHessian(ev, ones(n,1), zeros(0,1), zeros(0,1), opts);

            testCase.verifyEqual(H, A, 'AbsTol', 1e-6);
            testCase.verifyEqual(nnz(H - diag(diag(H))), 0);     % exactly zero off-diagonal
        end

        function testForwardDifferenceStepIsSqrtEps(testCase)
            % f = sum(x.^4): the third derivative is 24*x, so the O(h)
            % truncation error of a FORWARD difference is ~12*x*h.  At
            % h = sqrt(eps) that is ~2e-6 on this point; at the
            % central-difference optimum eps^(1/3) it is ~6e-4, three orders
            % worse.  The 1e-5 tolerance separates the two.
            x = [1; 2; 3];
            n = 3;
            ev = struct('objective', @(z) deal(sum(z.^4), 4 * z.^3), ...
                        'jacobian',  @(~) deal(zeros(0,n), zeros(0,n)));

            H = adamnlopt.lagrangianHessian(ev, x, zeros(0,1), zeros(0,1), ...
                adamnlopt.defaultOptions());

            testCase.verifyEqual(H, diag(12 * x.^2), 'AbsTol', 1e-5);
        end

        % --- 11: relative slack floor and the least-squares lamE seed ------

        function testSlackFloorTracksConstraintScale(testCase)
            % cI ~ 1e-6: an absolute floor of 1e-2 discards the natural slack
            % entirely and starts the barrier far off the central path.
            cI = [-1e-6; -2e-6];
            [state, ~] = testCase.initFixture(cI);

            testCase.verifyEqual(state.s, -cI, 'RelTol', 1e-12);
            testCase.verifyGreaterThan(min(state.s), 0);
        end

        function testSlackFloorKeepsStrictPositivityAtZeroConstraints(testCase)
            % cI identically zero gives no scale to read off, so the floor
            % falls back to the absolute 1e-2 and the slacks stay positive.
            [state, ~] = testCase.initFixture([0; 0]);

            testCase.verifyGreaterThan(min(state.s), 0);
            testCase.verifyEqual(state.s, [1e-2; 1e-2], 'RelTol', 1e-12);
        end

        function testSlackFloorScalesUpWithLargeConstraints(testCase)
            cI = [-1e6; 1e5];                 % one satisfied, one violated
            [state, ~] = testCase.initFixture(cI);

            testCase.verifyEqual(state.s(1), 1e6, 'RelTol', 1e-12);
            testCase.verifyEqual(state.s(2), 1e4, 'RelTol', 1e-12);   % 1e-2 * 1e6
        end

        function testInteriorPointSeedsEqualityMultipliersByLeastSquares(testCase)
            % Stopping at iteration 0 returns the seed itself.  A zero lamE
            % makes the first condensed step solve the wrong system; the seed
            % must be the weighted least-squares estimate instead.
            fun = @(x) shiftedSumSquaresObj(x, 3);
            opts = testCase.quietOpts(struct('maxIter', 0));

            [~, ~, exitflag, ~, lambda] = adamnlopt.solve(fun, [0.5; 0.5], ...
                [], [], [1 1], 2, [0; 0], [10; 10], [], opts);

            testCase.verifyEqual(exitflag, 0);                     % limit exit
            testCase.verifyGreaterThan(norm(lambda.eqlin, inf), 1e-8);
        end

        % --- 12: capped inertia-correction escalation ----------------------

        function testInertiaCorrectionCapsRegularization(testCase)
            % Ask for an inertia the system can never have (one negative
            % eigenvalue from a 2-by-2 block with no dual rows).  Escalation
            % must stop at the 1e20 ceiling and SAY it failed, instead of
            % running delta to ~1e31 and returning an invalid step silently.
            state = struct('H', eye(2), 'JE', zeros(0,2), ...
                           'x', zeros(2,1), 'lamE', zeros(0,1));
            res = struct('rStat', [1; 1], 'rFeasE', zeros(0,1));

            [~, ~, info, reg] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 1, [], []);

            testCase.verifyTrue(info.regCapped);
            testCase.verifyTrue(info.triesExhausted);
            testCase.verifyLessThanOrEqual(reg.delta, 1e20);
            testCase.verifyLessThanOrEqual(info.tries, 40);
        end

        function testInertiaCorrectionReportsSuccessUncapped(testCase)
            % The healthy case must not raise either flag.
            state = struct('H', eye(2), 'JE', [1 1], ...
                           'x', zeros(2,1), 'lamE', 0);
            res = struct('rStat', [1; 1], 'rFeasE', 0);

            [~, ~, info, reg] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 1, [], []);

            testCase.verifyFalse(info.regCapped);
            testCase.verifyFalse(info.triesExhausted);
            testCase.verifyLessThanOrEqual(reg.delta, 1e20);
        end

        % --- end-to-end: the fixes did not break ordinary convergence ------

        function testEqualityConstrainedQpStillConverges(testCase)
            fun = @sumSquaresObj;
            [x, fval, exitflag] = adamnlopt.solve(fun, [3; -1], [], [], ...
                [1 1], 2, [], [], [], testCase.quietOpts(struct()));

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [1; 1], 'AbsTol', 1e-6);
            testCase.verifyEqual(fval, 2, 'AbsTol', 1e-6);
        end

        function testBoundAndInequalityConstrainedProblemStillConverges(testCase)
            % min (x-3)'(x-3) s.t. x1 + x2 <= 2, x >= 0 -> x = [1;1].
            fun = @(x) shiftedSumSquaresObj(x, 3);
            [x, ~, exitflag] = adamnlopt.solve(fun, [0.2; 0.2], [1 1], 2, ...
                [], [], [0; 0], [], [], testCase.quietOpts(struct()));

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [1; 1], 'AbsTol', 1e-5);
        end

        function testBoundActiveSolutionStillConverges(testCase)
            % The optimum pins both variables at their lower bounds, the case
            % the projected-gradient metric had to get right.
            fun = @(x) shiftedSumSquaresObj(x, -1);
            [x, ~, exitflag] = adamnlopt.solve(fun, [1; 2], [], [], [], [], ...
                [0; 0], [], [], testCase.quietOpts(struct()));

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [0; 0], 'AbsTol', 1e-5);
        end

        % --- 13: every nlcon call is counted -------------------------------

        function testFiniteDiffJacobianProbesAreCounted(testCase)
            % The FD Jacobian makes n (forward) user constraint calls per
            % Jacobian and they went through evalNonlinearStacked, which bypassed
            % the only place nCon was incremented.  On a black-box problem that
            % uncounted set is the bulk of the solve.
            counter = containers.Map({'n'}, {0});
            [ev, x0] = testCase.countingEvaluator(counter, false);

            ev.jacobian(x0);

            testCase.verifyGreaterThan(counter('n'), 2);        % base + 2 probes
            testCase.verifyEqual(ev.nCon, counter('n'));
        end

        function testConstraintCallsAreNotDoubleCounted(testCase)
            % constraints() used to do the counting; evalNonlinear does it now.
            % Both would be exactly one increment too many per call.
            counter = containers.Map({'n'}, {0});
            [ev, x0] = testCase.countingEvaluator(counter, false);

            ev.constraints(x0);
            ev.constraints(x0);            % cached: no second user call

            testCase.verifyEqual(counter('n'), 1);
            testCase.verifyEqual(ev.nCon, 1);
        end

        function testFuncCountAndBudgetIncludeConstraintEvals(testCase)
            % output.funcCount is the number maxFunEvals is spent against, so it
            % has to be the TOTAL user-call count, with the split still visible.
            counter = containers.Map({'n'}, {0});
            nlc = @(x) countingCircle(x, counter);
            opts = testCase.quietOpts(struct('maxIter', 5));
            [~, ~, ~, output] = adamnlopt.solve(@sumSquaresObj, [0.5; 0.5], ...
                [], [], [], [], [], [], nlc, opts);

            testCase.verifyEqual(output.conCount, counter('n'));
            testCase.verifyGreaterThan(output.conCount, 0);
            testCase.verifyEqual(output.funcCount, output.objCount + output.conCount);
        end

        % --- 14: restoration is bounded and always reports ------------------

        function testRestorationAlwaysReportsIters(testCase)
            % A first-iteration break left info without an .iters field at all.
            counter = containers.Map({'n'}, {0});
            [ev, ~] = testCase.countingEvaluator(counter, false);
            opts = adamnlopt.defaultOptions();

            [~, info] = adamnlopt.degeneracy_restorationPhase( ...
                ev, [1; 0], [], [], opts);     % already on the circle: feasible

            testCase.verifyTrue(isfield(info, 'iters'));
            testCase.verifyEqual(info.iters, 0);
        end

        function testRestorationStopsAtTheEvaluationBudget(testCase)
            % Restoration never consulted maxFunEvals: up to 50 Gauss-Newton
            % iterations, each with a finite-differenced Jacobian, could blow
            % through the whole budget inside one call.
            counter = containers.Map({'n'}, {0});
            [ev, ~] = testCase.countingEvaluator(counter, false);
            opts = adamnlopt.defaultOptions();
            opts.maxFunEvals = 6;

            [~, info] = adamnlopt.degeneracy_restorationPhase( ...
                ev, [8; 8], [], [], opts);     % far outside the circle

            testCase.verifyTrue(info.budgetHit);
            testCase.verifyLessThan(info.evals, 4 * opts.maxFunEvals);
            testCase.verifyEqual(info.evals, counter('n'));
        end

        % --- 16: BFGS curvature floor ---------------------------------------

        function testBfgsRejectsNoiseCurvaturePair(testCase)
            % s'y > 0 but 1e-18 against ||s||*||y|| = 1e6: the y*y'/s'y term is
            % of order 1e30.  The old floor used eps(sy), which cancels sy and
            % reduces the test to ||y||*||s|| >= 4.5e15, so it never fired.
            B = adamnlopt.BFGSHessian(2);
            accepted = B.update([1; 0], [1e-18; 1e6]);

            testCase.verifyFalse(accepted);
            testCase.verifyLessThan(norm(B.getMatrix()), 1e3);
        end

        function testBfgsStillAcceptsAnOrdinaryPair(testCase)
            % The floor must not reject real curvature: cos(s,y) = 1 here.
            B = adamnlopt.BFGSHessian(2);
            accepted = B.update([1; 0], [2; 0]);

            testCase.verifyTrue(accepted);
            testCase.verifyTrue(all(isfinite(B.getMatrix()), 'all'));
        end

        function testLbfgsRejectsNoiseCurvaturePair(testCase)
            % Same floor on the limited-memory model, which only tested sy > 0.
            % The pair has to clear Powell damping first (sy >= eta*s'Bs, which
            % a tiny step does), so the floor is the only thing left between
            % s'y = 1e-16 against ||s||*||y|| = 1e-2 and gamma = y'y/s'y = 1e28.
            L = adamnlopt.LBFGSHessian(2);
            accepted = L.update([1e-8; 0], [1e-8; 1e6]);

            testCase.verifyFalse(accepted);
        end

        % --- 17: L-BFGS singular compact matrix ------------------------------

        function testLbfgsDropsPairsThatMakeTheCompactMatrixSingular(testCase)
            % getMatrix/apply silenced MATLAB:nearlySingularMatrix and then USED
            % the product, so a singular M produced a Hessian of order 1/eps that
            % flowed into the KKT assembly.  gamma = 0 makes M = [0, L; L', -D]
            % exactly singular for one stored pair.
            L = adamnlopt.LBFGSHessian(2);
            L.update([1; 0], [2; 0]);
            L.gamma = 0;

            B = L.getMatrix();

            testCase.verifyTrue(all(isfinite(B), 'all'));
            testCase.verifyGreaterThanOrEqual(L.nDropped, 1);
            testCase.verifyTrue(all(isfinite(L.apply([1; 1]))));
        end

        function testLbfgsKeepsAHealthyPair(testCase)
            % The guard must not prune a well-conditioned model.
            L = adamnlopt.LBFGSHessian(2);
            L.update([1; 0], [2; 0]);
            B = L.getMatrix();

            testCase.verifyEqual(L.nDropped, 0);
            testCase.verifyTrue(all(isfinite(B), 'all'));
        end

        % --- 18: elastic mode without the Optimization Toolbox ---------------

        function testElasticModeMatchesTheKnownEqualityOptimum(testCase)
            % min 0.5*dx^2 + rho*|1 + dx|.  rho = 0.5 is too weak to reach
            % feasibility, so the optimum sits at dx = -rho.
            [dx, info] = adamnlopt.degeneracy_elasticVariables( ...
                1, 1, zeros(0,1), zeros(0,1), 0.5, 1.0);

            testCase.verifyEqual(dx, -0.5, 'AbsTol', 1e-8);
            testCase.verifyEqual(info.penalty, 0.5, 'AbsTol', 1e-8);
            testCase.verifyFalse(info.feasible);
            testCase.verifyTrue(info.converged);
        end

        function testElasticModeReachesFeasibilityWithALargePenalty(testCase)
            % Same problem with rho large enough: dx = -1 kills the violation.
            [dx, info] = adamnlopt.degeneracy_elasticVariables( ...
                1, 1, zeros(0,1), zeros(0,1), 1e3, 1.0);

            testCase.verifyEqual(dx, -1, 'AbsTol', 1e-6);
            testCase.verifyEqual(info.penalty, 0, 'AbsTol', 1e-6);
            testCase.verifyTrue(info.feasible);
        end

        function testElasticModeHandlesAnInequality(testCase)
            % min 0.5*dx^2 + rho*max(1 + dx, 0); the inequality is one-sided, so
            % only the violated side is penalized.
            [dx, info] = adamnlopt.degeneracy_elasticVariables( ...
                zeros(0,1), zeros(0,1), 1, 1, 0.5, 1.0);

            testCase.verifyEqual(dx, -0.5, 'AbsTol', 1e-8);
            testCase.verifyEqual(info.sI, 0.5, 'AbsTol', 1e-8);
            testCase.verifyEmpty(info.wE);
        end

        function testElasticModeBoundsConflictingConstraints(testCase)
            % 1 + dx = 0 and 1 - dx = 0 cannot both hold.  The proximal term
            % must keep dx finite; the l1 sum is flat at 2 across [-1, 1] so the
            % proximal term picks dx = 0.
            [dx, info] = adamnlopt.degeneracy_elasticVariables( ...
                [1; 1], [1; -1], zeros(0,1), zeros(0,1), 0.5, 1.0);

            testCase.verifyEqual(dx, 0, 'AbsTol', 1e-8);
            testCase.verifyEqual(info.penalty, 2, 'AbsTol', 1e-8);
            testCase.verifyFalse(info.feasible);
        end

        function testElasticModeAgreesWithABruteForceOptimum(testCase)
            % Independent oracle: the reduced problem is one-dimensional, so a
            % fine scan over dx certifies the dual coordinate ascent.
            cE = 0.7;  JE = 2;  cI = -0.3;  JI = -1.5;  rho = 3;  prox = 0.8;
            [dx, ~] = adamnlopt.degeneracy_elasticVariables(cE, JE, cI, JI, rho, prox);

            grid = linspace(-3, 3, 600001).';
            obj  = 0.5 * prox * grid.^2 + rho * (abs(cE + JE*grid) ...
                                                 + max(cI + JI*grid, 0));
            [~, k] = min(obj);

            testCase.verifyEqual(dx, grid(k), 'AbsTol', 1e-4);
        end

        % --- 19-23: Evaluator accounting -------------------------------------

        function testSecondObjectiveCallForGradientIsCounted(testCase)
            % A value-only call caches f with no gradient; asking for the
            % gradient at the same x is a SECOND user call and costs one eval.
            counter = containers.Map({'n'}, {0});
            ev = testCase.countingObjEvaluator(counter);

            ev.objective([1; 1]);            % value only
            [~, ~] = ev.objective([1; 1]);   % needs the gradient: second call

            testCase.verifyEqual(counter('n'), 2);
            testCase.verifyEqual(ev.nFun, 2);
        end

        function testBroydenNeverDisplacesAnAnalyticJacobian(testCase)
            % enableBroyden used to be tested BEFORE hasConGrad, so turning it on
            % replaced exact user Jacobians with a rank-1 approximation -- and
            % paid an extra constraint evaluation per Jacobian to maintain it.
            counter = containers.Map({'n'}, {0});
            [ev, x0] = testCase.countingEvaluator(counter, true);
            ev.enableBroyden = true;

            [~, JI1] = ev.jacobian(x0);
            [~, JI2] = ev.jacobian(x0 + 0.1);

            testCase.verifyEqual(JI1, 2 * x0.', 'AbsTol', 1e-12);
            testCase.verifyEqual(JI2, 2 * (x0 + 0.1).', 'AbsTol', 1e-12);
            testCase.verifyEqual(counter('n'), 2);   % one call per Jacobian
        end

        function testMissingConstraintGradientIsAnError(testCase)
            % An empty gradient block with live constraint rows became a block of
            % ZEROS -- a valid-looking Jacobian claiming the constraints are
            % locally constant.
            counter = containers.Map({'n'}, {0});
            problem = testCase.circleProblem(@(x) emptyGradCon(x, counter), true);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());

            testCase.verifyError(@() ev.jacobian([0.5; 0.5]), ...
                'adamnlopt:Evaluator:missingConGrad');
        end

        function testWronglyShapedConstraintGradientIsAnError(testCase)
            % fmincon convention is one COLUMN per constraint (n-by-m).
            counter = containers.Map({'n'}, {0});
            problem = testCase.circleProblem(@(x) rowGradCon(x, counter), true);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());

            testCase.verifyError(@() ev.jacobian([0.5; 0.5]), ...
                'adamnlopt:Evaluator:conGradSize');
        end

        function testCalibrateStepBooksProbesToTheRightCounter(testCase)
            % Constraint probes self-count in nCon now, so adding the whole
            % sweep to nFun would double-count them into the wrong counter.
            counter = containers.Map({'n'}, {0});
            [ev, x0] = testCase.countingEvaluator(counter, false);

            info = ev.calibrateStep(x0);

            testCase.verifyGreaterThan(info.nEvals, 0);
            testCase.verifyEqual(ev.nCon, counter('n'));
            testCase.verifyEqual(ev.nFun, info.nEvalsObj);
            testCase.verifyEqual(ev.nFun + ev.nCon, info.nEvals);
        end

        % --- 24-25: Broyden secant updates ------------------------------------

        function testBroydenNegligibleStepTestIsRelative(testCase)
            % The old test reduced to the ABSOLUTE threshold ||s|| < 1.5e-8: on a
            % problem whose variables are O(1e6) it accepted steps eleven orders
            % below the variable scale and divided by that squared.
            B = adamnlopt.eval_BroydenJacobian([1 0]);
            xRef = [1e6; 1e6];
            accepted = B.update([1e-3; 0], 1e-3, xRef);

            testCase.verifyFalse(accepted);
            testCase.verifyEqual(B.full(), [1 0], 'AbsTol', 1e-12);
        end

        function testBroydenAcceptsAStepAtTheVariableScale(testCase)
            % The secant condition must still be imposed for a real step.
            B = adamnlopt.eval_BroydenJacobian([1 0]);
            s = [1; 0];  y = 1.05;         % within the 0.1 refresh tolerance
            accepted = B.update(s, y, [1; 1]);

            testCase.verifyTrue(accepted);
            testCase.verifyEqual(B.full() * s, y, 'AbsTol', 1e-12);
        end

        % --- 26: BFGS conditioning estimate and rejection counter -------------

        function testBfgsConditionEstimateSeesOffDiagonalMass(testCase)
            % One update from B0 = I with s = e1, y = [1; t] gives exactly
            % B = [1 t; t 1+t^2], whose Cholesky factor is [1 t; 0 1]: a UNIT
            % diagonal. The old max/min-of-diag(R) estimate therefore reported
            % cond(B) = 1 for a matrix with cond(B) ~ 1e8.
            B = adamnlopt.BFGSHessian(2);
            B.autoScaleB0 = false;      % keep B0 = I so the matrix is exact
            B.condMax     = inf;        % measure the estimate, do not reset
            t = 100;
            testCase.verifyTrue(B.update([1; 0], [1; t]));

            M = B.getMatrix();
            testCase.verifyEqual(M, [1 t; t 1+t^2], 'AbsTol', 1e-9);

            R   = chol(M);
            old = (max(diag(R)) / min(diag(R)))^2;   % the pre-fix estimator
            testCase.verifyLessThan(old, cond(M) / 1e4);   % it really is blind
            testCase.verifyEqual(B.condLast, cond(M), 'RelTol', 0.5);
        end

        function testBfgsCondMaxResetActuallyFires(testCase)
            % Same matrix, with condMax below its true condition number: the
            % reset must now trigger. Under the diagonal-ratio estimate kappa
            % was 1 and the configured ceiling was unreachable.
            B = adamnlopt.BFGSHessian(2);
            B.autoScaleB0 = false;
            B.condMax     = 1e6;
            B.update([1; 0], [1; 100]);

            testCase.verifyEqual(B.nResets, 1);
        end

        function testBfgsCountsRejectedCurvaturePairs(testCase)
            % A pair that clears Powell damping but fails the relative
            % curvature floor is dropped; the drop must be visible.
            B = adamnlopt.BFGSHessian(2);
            B.autoScaleB0 = false;
            accepted = B.update([1e-8; 0], [1e-8; 1e6]);

            testCase.verifyFalse(accepted);
            testCase.verifyEqual(B.nRejected, 1);
            testCase.verifyEqual(B.getMatrix(), eye(2));   % B untouched
        end

        % --- 27: the B0-refresh gates can be mutually exclusive ---------------

        function testB0RefreshReportsItsOwnUnreachability(testCase)
            % refractory 5 and minLearned 0.20 want sinceRebase >= 5 AND
            % sinceRebase < 0.2*n at the same time, which is impossible for
            % every n <= 25 -- while every option still reads as enabled.
            B = adamnlopt.BFGSHessian(10);
            B.autoScaleB0 = false;
            B.b0Refresh   = true;
            testCase.verifyTrue(B.update([1; zeros(9,1)], [1; zeros(9,1)]));

            testCase.verifyTrue(B.b0RefreshUnreachable);
        end

        function testB0RefreshIsReachableOnALargeProblem(testCase)
            % n = 100 gives 0.2*n = 20 > 5, so the window is non-empty and the
            % trigger is genuinely live -- the flag must stay down.
            B = adamnlopt.BFGSHessian(100);
            B.autoScaleB0 = false;
            B.b0Refresh   = true;
            testCase.verifyTrue(B.update([1; zeros(99,1)], [1; zeros(99,1)]));

            testCase.verifyFalse(B.b0RefreshUnreachable);
        end

        % --- 28: one finite-difference step per column, not per color ---------

        function testColoredJacobianUsesAPerColumnStep(testCase)
            % Two structurally independent columns at wildly different scales
            % share a color. The step used to be set by the largest variable in
            % the color, so the 1e-6 variable was perturbed by 1e12 times its
            % own scale and its column was meaningless.
            f   = @(v) [v(1)^2; v(2)^2];
            x   = [1e-6; 1e6];
            pat = logical(eye(2));
            J = adamnlopt.finiteDiffJacobian(f, x, f(x), sqrt(eps), 'forward', pat);

            testCase.verifyEqual(adamnlopt.sparsityColoring(pat), [1 1]);
            testCase.verifyEqual(J, diag([2e-6; 2e6]), 'RelTol', 0.02);
        end

        function testColoredJacobianKeepsPerColumnStepsWhenSplitByBound(testCase)
            % Column 2 is pinned at its upper bound and flips to a backward
            % difference, splitting the color into two one-evaluation batches.
            % Each batch must still carry its own per-column step.
            f   = @(v) [v(1)^2; v(2)^2];
            x   = [1e-6; 1e6];
            pat = logical(eye(2));
            lb  = [-inf; -inf];
            ub  = [ inf;  1e6];
            J = adamnlopt.finiteDiffJacobian(f, x, f(x), sqrt(eps), 'forward', ...
                                             pat, lb, ub);

            testCase.verifyEqual(J, diag([2e-6; 2e6]), 'RelTol', 0.02);
        end

        function testParallelColoredJacobianUsesAPerColumnStep(testCase)
            % Same defect, same fix, on the parfor path (exercised serially
            % here when no pool is available -- the arithmetic is shared).
            f   = @(v) [v(1)^2; v(2)^2];
            x   = [1e-6; 1e6];
            pat = logical(eye(2));
            [g, J, info] = adamnlopt.parallel_parallelFiniteDiff( ...
                [], f, x, [], f(x), sqrt(eps), 'forward', pat);

            testCase.verifyEmpty(g);
            testCase.verifyEqual(info.nConEvals, 1);   % still one evaluation
            testCase.verifyEqual(J, diag([2e-6; 2e6]), 'RelTol', 0.02);
        end

        % --- 29: the coloring is memoized on its content ----------------------

        function testSparsityColoringMemoIsContentKeyed(testCase)
            p1 = logical([1 0 1; 0 1 1]);
            g1 = adamnlopt.sparsityColoring(p1);
            testCase.verifyEqual(g1, [1 1 2]);
            testCase.verifyEqual(adamnlopt.sparsityColoring(p1), g1);  % memo hit

            % A different pattern of the SAME SIZE must not reuse the slot.
            p2 = logical([1 1 1; 0 0 0]);
            testCase.verifyEqual(adamnlopt.sparsityColoring(p2), [1 2 3]);

            % ...and the first pattern must still color correctly afterwards.
            testCase.verifyEqual(adamnlopt.sparsityColoring(p1), g1);
        end

        % --- 30: bound-squeezed and unrepresentable steps ---------------------

        function testFdStepReportsASqueezedCoordinate(testCase)
            x     = [0;  1e10;       5];
            lb    = [-1; 1e10 - 1e-5; 5];
            ub    = [ 1; 1e10 + 1e-5; 5];
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep(x, 1e-3, lb, ub);

            % Room on both sides: full step, nothing reported.
            testCase.verifyEqual(hs(1), 1e-3);
            testCase.verifyEqual(sgn(1), 1);
            testCase.verifyTrue(twoSided(1));
            testCase.verifyFalse(squeezed(1));

            % Rule 3: shrunk to the available gap, and said so.
            testCase.verifyTrue(squeezed(2));
            testCase.verifyGreaterThan(hs(2), 0);
            testCase.verifyLessThan(hs(2), 1e-3);

            % lb == ub: fixed variable, also a rule-3 squeeze (to zero room).
            testCase.verifyEqual(hs(3), 0);
            testCase.verifyEqual(sgn(3), 0);
            testCase.verifyFalse(twoSided(3));
            testCase.verifyTrue(squeezed(3));
        end

        function testFdStepRefusesAnUnrepresentableStep(testCase)
            % A step below the floating-point spacing at x leaves the probe
            % point equal to x, so (f - f)/h is pure round-off reported as a
            % derivative. It must be routed to rule 4 instead.
            [hs, sgn, twoSided] = adamnlopt.fdBoundedStep(1e10, 1e-20, -inf, inf);

            testCase.verifyEqual(hs, 0);
            testCase.verifyEqual(sgn, 0);
            testCase.verifyFalse(twoSided);
        end

        function testFdStepWithoutBoundsReportsNoSqueeze(testCase)
            [hs, sgn, twoSided, squeezed] = ...
                adamnlopt.fdBoundedStep([1; 2; 3], 1e-4, [], []);

            testCase.verifyEqual(hs, repmat(1e-4, 3, 1));
            testCase.verifyEqual(sgn, ones(3, 1));
            testCase.verifyEqual(twoSided, true(3, 1));
            testCase.verifyEqual(squeezed, false(3, 1));
        end

        % --- 44: maxTime is the solver's own budget exit ----------------------

        function testMaxTimeIsABudgetExitNotAnOutputFunctionStop(testCase)
            % The LVD wrapper enforced maxTime from its IterationFcn, racing
            % the solver's terminationCheck for the same budget and usually
            % winning -- so a run that had merely used up its time was
            % reported as exitflag -1, "stopped by output function".  The
            % wrapper's copy is gone; this is what the caller now sees.
            opts = testCase.quietOpts(struct('maxTime', 1e-3, 'maxIter', 5000));
            [~, ~, exitflag, output] = adamnlopt.solve(@slowSumSquaresObj, ...
                [3; -1], [], [], [], [], [], [], [], opts);

            testCase.verifyEqual(exitflag, 0);
            testCase.verifyTrue(contains(lower(output.message), 'maximum time'));
        end

        function testMaxTimeLeavesAFastSolveAlone(testCase)
            % The budget check must not fire on a solve that finishes inside
            % it: an unreachable limit still has to converge normally.
            opts = testCase.quietOpts(struct('maxTime', 600));
            [x, ~, exitflag] = adamnlopt.solve(@sumSquaresObj, [3; -1], ...
                [], [], [1 1], 2, [], [], [], opts);

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [1; 1], 'AbsTol', 1e-6);
        end

        % --- 33: an operator condition estimate is exact or NaN ---------------

        function testOperatorConditionEstimateMatchesTheDenseMatrix(testCase)
            % A 20-step Lanczos Ritz ratio on an INDEFINITE KKT operator is
            % not a bound in either direction: the Ritz values interlace
            % inside an interval that straddles zero, so one can land next to
            % 0 on a perfectly conditioned K.  Small operators are
            % materialized and the numeric path used instead.
            H  = [4 1; 1 3];
            JE = [1 -1];
            K  = [H, JE.'; JE, 0];
            op = struct('apply', @(v) K * v, 'n', 2, 'mE', 1);

            testCase.verifyEqual(adamnlopt.linalg_conditionEstimate(op), ...
                cond(K), 'RelTol', 1e-10);
        end

        function testOperatorConditionEstimateIsNaNAboveTheMaterializeCap(testCase)
            % Too big to materialize is reported as "unknown".  NaN cannot be
            % mistaken for a small condition number; a Ritz-ratio
            % underestimate could, and that is what gated regularization.
            K  = [2 0; 0 1];
            op = struct('apply', @(v) K * v, 'n', 1, 'mE', 1);

            testCase.verifyTrue(isnan(adamnlopt.linalg_conditionEstimate(op, 1)));
            testCase.verifyEqual(adamnlopt.linalg_conditionEstimate(op, 2), 2, ...
                'RelTol', 1e-12);
        end

        % --- 34: degeneracy detection, two integers for one factorization ----

        function testRankActiveReusesRankEWhenNoInequalityIsActive(testCase)
            % With nothing active the active Jacobian IS JE, so the second
            % decomposition was re-deriving a rank just computed -- on an
            % inequality-free problem, every iteration of the solve.
            state = struct('x', zeros(3,1), 'JE', [1 1 0; 0 1 1], ...
                           'JI', [1 0 0], 'cI', -5, 'lamI', 0.1);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());

            testCase.verifyEqual(flags.rankE, 2);
            testCase.verifyEqual(flags.rankActive, flags.rankE);
            testCase.verifyFalse(flags.linDepActive);
        end

        function testPivotedQRRankStillCatchesDependentEqualityRows(testCase)
            % matrixRank moved off a full SVD (two per iteration) onto the
            % same column-pivoted QR the rest of the package uses.  It must
            % still call r2 = 2*r1 dependent.
            state = struct('x', zeros(3,1), 'JE', [1 2 3; 2 4 6], ...
                           'JI', [], 'cI', [], 'lamI', []);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());

            testCase.verifyEqual(flags.rankE, 1);
            testCase.verifyTrue(flags.linDepE);
            testCase.verifyTrue(flags.degenerate);
        end

        function testLICQFailureIsStillFlaggedWithAnActiveInequality(testCase)
            % The reuse shortcut must not swallow the case it exists beside:
            % an active inequality parallel to an equality row is an LICQ
            % failure and still takes the full factorization.
            state = struct('x', zeros(2,1), 'JE', [1 0], 'JI', [2 0], ...
                           'cI', 0, 'lamI', 1);
            flags = adamnlopt.degeneracy_detectDegeneracy(state, ...
                adamnlopt.defaultOptions());

            testCase.verifyTrue(flags.active);
            testCase.verifyEqual(flags.rankActive, 1);
            testCase.verifyTrue(flags.linDepActive);
        end

        % --- 36: dropConstraints on a single-row working set -----------------

        function testDropConstraintsHandlesASingleRow(testCase)
            % qr of a single-row A returns R as an n-by-1 VECTOR, and diag()
            % of a vector BUILDS an n-by-n matrix instead of extracting a
            % diagonal -- so the rank came back as a row vector and e(1:r)
            % threw MATLAB:colon:operandsNotRealScalar.
            testCase.verifyEqual(adamnlopt.degeneracy_dropConstraints([3 0 4]), 1);
        end

        function testDropConstraintsKeepsOneOfADependentPair(testCase)
            A    = [1 2; 2 4; 0 1];
            keep = adamnlopt.degeneracy_dropConstraints(A);

            testCase.verifyEqual(numel(keep), 2);
            testCase.verifyEqual(rank(A(keep, :)), 2);
        end

        % --- 37: stagnation is NET progress, not the window's spread ---------

        function testStagnationFlaggedWhenThetaReturnsToWhereItStarted(testCase)
            % A theta that spikes and falls back has a large SPREAD and zero
            % net progress.  Spread answered "did theta move at all", so the
            % restoration this case most needs was never suggested.
            opts = adamnlopt.defaultOptions();
            opts.modeSwitchStagnWindow = 3;
            state   = struct('theta', 1e-2, 'cE', [], 'cI', [], 's', []);
            res     = struct('opt', 1, 'feas', 1e-3, 'comp', 1);
            history = struct('theta', [1e-2; 5e-2; 1e-2], 'alpha', [0.1; 0.1]);

            advice = adamnlopt.control_modeController(state, res, history, opts);
            testCase.verifyTrue(advice.suggestRestore);
        end

        function testRealProgressIsNotFlaggedAsStagnation(testCase)
            opts = adamnlopt.defaultOptions();
            opts.modeSwitchStagnWindow = 3;
            state   = struct('theta', 1e-2, 'cE', [], 'cI', [], 's', []);
            res     = struct('opt', 1, 'feas', 1e-3, 'comp', 1);
            history = struct('theta', [1; 0.5; 1e-2], 'alpha', [0.1; 0.1]);

            advice = adamnlopt.control_modeController(state, res, history, opts);
            testCase.verifyFalse(advice.suggestRestore);
        end

        function testThetaIsRebuiltFromTheResidualsWhenStateThetaIsZero(testCase)
            % Guard on the branch whose byte-identical dead twin was removed.
            opts = adamnlopt.defaultOptions();
            opts.modeSwitchStagnWindow = 2;
            state   = struct('theta', 0, 'cE', [0.03; 0.04], 'cI', 0.1, 's', 0.9);
            res     = struct('opt', 1, 'feas', 1e-3, 'comp', 1);
            history = struct('theta', [0.07; 0.07], 'alpha', [0.1; 0.1]);

            advice = adamnlopt.control_modeController(state, res, history, opts);
            testCase.verifyTrue(advice.suggestRestore);
        end

        % --- 38: estimateNoise reports what it actually measured -------------

        function testEstimateNoiseFillsTheWholeInfoStructOnAnEarlyReturn(testCase)
            % Every early return used to leave info partly unset, so a caller
            % reading info.detected or info.hUsed got "reference to
            % non-existent field" instead of an answer.  A constant function
            % takes the 'flat' return, the shortest path through.
            [epsf, info] = adamnlopt.estimateNoise(@(~) 5, [1; 1], [1; 0], struct());

            testCase.verifyEqual(sort(fieldnames(info)), ...
                sort({'epsf'; 'detected'; 'flag'; 'hUsed'; 'levels'; 'nEvals'}));
            testCase.verifyEqual(info.flag, 'flat');
            testCase.verifyFalse(info.detected);
            testCase.verifyEqual(epsf, 0);
            % hUsed is the spacing of the attempt that returned, not the one
            % the next retry would have used: this probe retried once, wider.
            testCase.verifyGreaterThan(info.hUsed, 1e-3 * norm([1; 1]));
        end

        function testEstimateNoiseSeparatesDetectedFromUndetected(testCase)
            % epsf = 0 means both "clean" and "could not measure", so
            % detected is the field a caller has to read.
            rs  = RandStream('twister', 'Seed', 20260401);
            [epsf, info] = adamnlopt.estimateNoise( ...
                @(x) sum(x.^2) + 1e-8 * (2*rand(rs) - 1), [1; 1], [1; 0], struct());

            testCase.verifyTrue(info.detected);
            testCase.verifyEqual(info.flag, 'noise');
            testCase.verifyGreaterThan(epsf, 1e-11);
            testCase.verifyLessThan(epsf, 1e-6);

            [~, tooCoarse] = adamnlopt.estimateNoise(@(x) sum(x.^2), [1; 1], ...
                [1; 0], struct('baseSpacing', 1e4));
            testCase.verifyFalse(tooCoarse.detected);
            testCase.verifyEqual(tooCoarse.flag, 'inconclusive');
        end

        % --- 40: a reduced solve counts the calls it makes at the solution ---

        function testExpandResultBooksItsGradientRefillCall(testCase)
            % expandResult re-evaluates the objective at the solution to fill
            % the gradient rows of the fixed variables.  The help has always
            % said that call is recorded in output.funcCount; nothing
            % recorded it, so a reduced problem under-reported the user calls
            % it made.
            counter = containers.Map('n', 0);
            [fx, problem] = testCase.fixedVarFixture(counter, []);
            output = struct('objCount', 7, 'conCount', 0, 'funcCount', 7);

            [x, grad, ~, ~, out] = adamnlopt.expandResult(1, 3, [], ...
                struct('lower', 0, 'upper', 0), output, fx, problem);

            testCase.verifyEqual(counter('n'), 1);
            testCase.verifyEqual(out.objCount, 8);
            testCase.verifyEqual(out.funcCount, 8);
            testCase.verifyEqual(x, [1; 2]);
            testCase.verifyEqual(grad, [3; 4]);   % fixed row filled analytically
        end

        function testExpandResultBooksItsConstraintJacobianCall(testCase)
            % Same for the one nlcon call fixedStationarity makes to split the
            % fixed-variable bound multipliers.
            counter = containers.Map('n', 0);
            conCounter = containers.Map('n', 0);
            [fx, problem] = testCase.fixedVarFixture(counter, ...
                @(x) countingCircleGrad(x, conCounter));
            output = struct('objCount', 7, 'conCount', 2, 'funcCount', 9);

            [~, ~, ~, lambda, out] = adamnlopt.expandResult(1, 3, [], ...
                struct('lower', 0, 'upper', 0, 'ineqnonlin', 0.5), output, fx, problem);

            testCase.verifyEqual(conCounter('n'), 1);
            testCase.verifyEqual(out.conCount, 3);
            testCase.verifyEqual(out.funcCount, 11);   % +1 objective, +1 constraint
            % Bound-only lambda structs reach here without eqlin/ineqlin; the
            % guarded read must pad them rather than throw.
            testCase.verifyEqual(numel(lambda.lower), 2);
        end

        % --- 41: the FD step transfer applies only to a MEASURED step --------

        function testFDStepTransferLeavesAnUncalibratedDefaultAlone(testCase)
            % A bounded variable takes its scale from the BOUND RANGE, so the
            % physical-to-scaled transfer factor is 0.1 here.  Applied to the
            % generic sqrt(eps) -- which calibration returns untouched when it
            % finds no noise floor -- it puts forward differencing 10x inside
            % the cancellation regime.  sqrt(eps) is a RELATIVE step, already
            % correct in whichever space it is used in.
            [~, ~, ~, out] = adamnlopt.solve(@(x) shiftedSumSquaresObj(x, 3), ...
                [0.5; 0.5], [], [], [1 1], 2, [0; 0], [10; 10], [], ...
                testCase.quietOpts(struct()));

            testCase.verifyEqual(out.fdCalibration.flag, 'analytic');
            testCase.verifyEqual(out.fdCalibration.scaleFactor, 1);
            testCase.verifyEqual(out.fdCalibration.fdStepScaled, sqrt(eps), ...
                'RelTol', 1e-12);
        end

        function testFDStepTransferAppliesToAMeasuredStep(testCase)
            % With a genuine noise floor the calibration returns a PHYSICAL
            % step, and that one does have to be carried across the variable
            % scaling: Dx = 10 here, so the scaled step is a tenth of it.
            rs = RandStream('twister', 'Seed', 20260402);
            [~, ~, ~, out] = adamnlopt.solve( ...
                @(x) sum((x-3).^2) + 1e-7 * (2*rand(rs) - 1), [0.5; 0.5], ...
                [], [], [1 1], 2, [0; 0], [10; 10], [], ...
                testCase.quietOpts(struct('maxIter', 5)));

            testCase.verifyEqual(out.fdCalibration.flag, 'set');
            testCase.verifyEqual(out.fdCalibration.scaleFactor, 0.1, 'RelTol', 1e-12);
            testCase.verifyEqual(out.fdCalibration.fdStepScaled, ...
                out.fdCalibration.fdStep * 0.1, 'RelTol', 1e-12);
        end

        % --- 42: an explicitly set FD step/type survives autoFDStep ----------

        function testUserSetFDStepAndTypeSkipCalibrationEntirely(testCase)
            % autoFDStep is on by default, so it silently overwrote both
            % FiniteDifferenceStepSize and FiniteDifferenceType for anyone who
            % set them without also knowing to turn autoFDStep off.
            opts = adamnlopt.defaultOptions();
            opts.FiniteDifferenceStepSize = 1e-5;
            opts.FiniteDifferenceType     = 'central';
            ev   = adamnlopt.Evaluator(testCase.fdProblem(@sumSquaresObj), opts);
            info = ev.calibrateStep([0.5; 0.5]);

            testCase.verifyEqual(info.flag, 'userSet');
            testCase.verifyEqual(info.nEvals, 0);   % not one wasted probe
            testCase.verifyEqual(ev.fdStep, 1e-5);
            testCase.verifyEqual(ev.fdType, 'central');
        end

        function testUserSetFDStepSurvivesWhileTheTypeIsStillPromoted(testCase)
            % Pinning only the step still lets the V-curve promote forward to
            % central -- the half the caller did not ask to control.
            rs = RandStream('twister', 'Seed', 20260402);
            opts = adamnlopt.defaultOptions();
            opts.FiniteDifferenceStepSize = 1e-5;
            ev = adamnlopt.Evaluator(testCase.fdProblem( ...
                @(x) sum((x-3).^2) + 1e-7 * (2*rand(rs) - 1)), opts);
            info = ev.calibrateStep([0.5; 0.5]);

            testCase.verifyEqual(info.flag, 'set');
            testCase.verifyEqual(ev.fdStep, 1e-5);     % untouched
            testCase.verifyEqual(ev.fdType, 'central'); % promoted
            testCase.verifyTrue(info.promoted);
        end

        % --- 46: the Async parallel mode is no longer offered ----------------

        function testParallelEnumListBoxOmitsAsync(testCase)
            % 'async' was never a distinct strategy -- the Evaluator routes it
            % through the same parallel finite-difference path as 'finitediff'
            % (the standalone parallel_asyncEvaluator is deleted) -- so offering it
            % promised one evaluation strategy and delivered the other.
            names = AdamNlOptParallelEnum.getListBoxStr();

            testCase.verifyFalse(any(strcmp(names, ...
                AdamNlOptParallelEnum.Async.name)));
            testCase.verifyTrue(any(strcmp(names, ...
                AdamNlOptParallelEnum.FiniteDiffs.name)));
            testCase.verifyEqual(numel(names), ...
                numel(enumeration('AdamNlOptParallelEnum')) - 1);
        end

        function testParallelEnumIndexAgreesWithTheListBox(testCase)
            % The two used to build their own lists, so any divergence in
            % membership or order silently mis-selected the control.
            names = AdamNlOptParallelEnum.getListBoxStr();
            for k = 1:numel(names)
                [ind, en] = AdamNlOptParallelEnum.getIndForName(names{k});
                testCase.verifyEqual(ind, k);
                testCase.verifyEqual(en.name, names{k});
            end

            % A saved case still holding Async lands on the mode it was in
            % fact already getting, not on a blank control.
            [~, en] = AdamNlOptParallelEnum.getIndForName( ...
                AdamNlOptParallelEnum.Async.name);
            testCase.verifyEqual(en, AdamNlOptParallelEnum.FiniteDiffs);
        end

        function testLoadedAsyncOptionsNormalizeToFiniteDiffs(testCase)
            % The member cannot be deleted -- property-set validation runs on
            % a saved .mat BEFORE loadobj does -- so the rewrite happens here.
            opts = AdamNlOptOptions();
            opts.parallel = AdamNlOptParallelEnum.Async;

            testCase.verifyEqual(AdamNlOptOptions.loadobj(opts).parallel, ...
                AdamNlOptParallelEnum.FiniteDiffs);
        end

        % --- 47: the parallel-availability probe, asked once and correctly ---

        function testParallelFiniteDiffMatchesTheAnalyticDerivatives(testCase)
            % parallel_available moved off a per-Jacobian ver('parallel') path
            % scan -- once per solver iteration, for an answer that cannot
            % change in a session, and reporting INSTALLED rather than
            % licensed, so a shared-licence box took the parfor path and got
            % serial execution plus a licence error.  Whichever path it now
            % picks has to return the same derivatives.
            objFun = @(x) sum((x - 3).^2);
            x      = [0.7; -0.4];
            [c0, ~] = circleCon(x);
            [g, J, info] = adamnlopt.parallel_parallelFiniteDiff(objFun, ...
                @circleCon, x, objFun(x), c0, sqrt(eps), 'forward', [], [], []);

            testCase.verifyEqual(g(:), 2 * (x - 3), 'RelTol', 1e-6);
            testCase.verifyEqual(J(:), 2 * x, 'RelTol', 1e-6);
            testCase.verifyEqual(info.nObjEvals, 2);   % one per column, once
            testCase.verifyEqual(info.nConEvals, 2);
        end

        function testKktAssembleKeepsASparseSystemSparse(testCase)
            % 48: `H + delta*eye(n)` materializes a dense identity and hands
            % back a DENSE K -- destroying the one property the LDL' downstream
            % depends on, and doing it even at delta = 0, up to 40 times per
            % iteration because kkt_inertiaCorrection re-assembles per try.
            H  = spdiags([2; 3], 0, 2, 2);
            JE = sparse([1, 1]);
            [state, res] = testCase.kktFixture(H, JE);

            K = adamnlopt.kkt_assemble(state, res);          % reg omitted
            testCase.verifyTrue(issparse(K));

            K = adamnlopt.kkt_assemble(state, res, struct('delta', 1e-6, 'gamma', 1e-7));
            testCase.verifyTrue(issparse(K));
            testCase.verifyEqual(full(K(1,1)), 2 + 1e-6, 'RelTol', 1e-12);
            testCase.verifyEqual(full(K(3,3)), -1e-7, 'RelTol', 1e-12);

            % A dense H must stay dense and still pick up the diagonal add.
            [dState, dRes] = testCase.kktFixture(full(H), full(JE));
            Kd = adamnlopt.kkt_assemble(dState, dRes, struct('delta', 1e-6, 'gamma', 0));
            testCase.verifyFalse(issparse(Kd));
            testCase.verifyEqual(Kd(2,2), 3 + 1e-6, 'RelTol', 1e-12);
        end

        function testKktAssembleAcceptsAPartiallyPopulatedRegStruct(testCase)
            % 48b: the defaults were applied only when reg was wholly empty, so
            % a struct carrying delta but not gamma errored on the missing field
            % instead of taking the documented default of zero.
            [state, res] = testCase.kktFixture(eye(2), [1, 1]);

            K = adamnlopt.kkt_assemble(state, res, struct('delta', 0.5));
            testCase.verifyEqual(K(1,1), 1.5, 'RelTol', 1e-12);
            testCase.verifyEqual(K(3,3), 0);          % gamma defaulted to 0

            K = adamnlopt.kkt_assemble(state, res, struct('gamma', 0.25));
            testCase.verifyEqual(K(1,1), 1);          % delta defaulted to 0
            testCase.verifyEqual(K(3,3), -0.25, 'RelTol', 1e-12);
        end

        function testKktInertiaIsInvariantToARescalingOfTheSystem(testCase)
            % 49: the zero-pivot tolerance was an absolute 1e-14, so the inertia
            % -- which IS the descent certificate inertiaCorrection grows
            % delta/gamma to obtain -- depended on the units the problem is
            % posed in.  Scale the system down and every pivot reads as zero:
            % rank deficient on every iteration, every step from lsqminnorm, and
            % the correction loop unable to certify anything.
            A   = [4, 1, 1; 1, 3, 1; 1, 1, 0];
            rhs = [1; 2; 3];

            [~, info] = adamnlopt.linalg_solveKKTdirect(A, rhs);
            [~, scaledInfo] = adamnlopt.linalg_solveKKTdirect(1e-15 * A, 1e-15 * rhs);

            testCase.verifyEqual(info.inertia, [2, 1, 0]);
            testCase.verifyEqual(scaledInfo.inertia, info.inertia);
            testCase.verifyFalse(scaledInfo.rankDeficient);
            testCase.verifyTrue(scaledInfo.solved);
        end

        function testKktInertiaStillDetectsAGenuineSingularity(testCase)
            % 49b: the relative tolerance is ~2000x looser than the old absolute
            % one on a well-scaled system, so check it has not gone blind to the
            % rank deficiency it exists to report.
            A = [1, 0, 1; 0, 1, 1; 1, 1, 2];   % row 3 = row 1 + row 2

            [~, info] = adamnlopt.linalg_solveKKTdirect(A, [1; 1; 2]);

            testCase.verifyTrue(info.rankDeficient);
            testCase.verifyFalse(info.solved);
            testCase.verifyEqual(info.inertia(3), 1);
        end

        function testRestorationSlackSeedMatchesTheStartUpSeed(testCase)
            % 50: the post-restoration re-seed promised to re-seed "exactly as
            % at start-up" but carried its own absolute 1e-4 floor -- a vast
            % perturbation when the inequality residuals live at 1e6, and a
            % negligible one when they live at 1e-6.  Both sites now share this
            % one formula, so the floor is relative at both.
            cI = [-1e6; -2e6];
            [s, sMin] = adamnlopt.initSlackSeed(cI);
            testCase.verifyEqual(sMin, 1e-2 * 2e6, 'RelTol', 1e-12);
            testCase.verifyEqual(s, [1e6; 2e6], 'RelTol', 1e-12);

            % Tiny residuals: the floor follows them down instead of swamping
            % them, but never past the absolute backstop.
            [~, sMin] = adamnlopt.initSlackSeed([-1e-6; -1e-6]);
            testCase.verifyEqual(sMin, 1e-8, 'RelTol', 1e-12);
            [~, sMin] = adamnlopt.initSlackSeed([-1e-20; 0]);
            testCase.verifyEqual(sMin, 1e-10, 'RelTol', 1e-12);
            [~, sMin] = adamnlopt.initSlackSeed(zeros(0,1));
            testCase.verifyEqual(sMin, 1e-2, 'RelTol', 1e-12);

            % And the start-up seed is literally this function, not a copy.
            state = testCase.initFixture(cI);
            testCase.verifyEqual(state.s, s, 'RelTol', 1e-12);
        end

        function testMeritBackupReplaysTheFilterTrialsInsteadOfRecomputing(testCase)
            % 51: the merit backup re-evaluated the identical aMax, aMax/2, ...
            % sequence the filter loop had just computed -- ~34 extra user
            % objective+constraint pairs on every stalled line search, on
            % precisely the iterations that can least spare them.
            counter = containers.Map('n', 0);
            filt = adamnlopt.Filter();
            % theta above thetaCap: every trial is vetoed in both loops, so the
            % search runs the full backtracking sequence twice if it recomputes.
            % theta0 = 1 (above theta_min) keeps every trial THETA-type: since
            % review D18 the cap no longer vetoes f-type trials.
            [alpha, ~, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                @(a) countingPhiTheta(a, counter, 1), 0, 1, -1, filt, 1, 1, 0.5, 0);

            testCase.verifyTrue(lsFailed);
            % 1, 1/2, ... down to the WB alpha_min (D18): gamma_alpha *
            % min(gamma_theta, gamma_phi*theta0/(-gd)) = 5e-7, so 21 trials,
            % once each (34 under the old 1e-10 floor).
            testCase.verifyEqual(counter('n'), 21);
            testCase.verifyEqual(alpha, 1e-10);
        end

        function testLineSearchFailureNeverReturnsAStepLongerThanAMax(testCase)
            % 52: on failure the search returned alpha = amin = 1e-10, which
            % EXCEEDS aMax whenever fraction-to-boundary pins aMax below that --
            % reachable at the endgame, with a slack on its way to zero.  The
            % caller takes the step unconditionally, so the slack goes negative
            % and the next log-barrier evaluation is complex or NaN.
            counter = containers.Map('n', 0);
            filt = adamnlopt.Filter();
            aMax = 1e-14;
            [alpha, ~, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                @(a) countingPhiTheta(a, counter, 1), 0, 0, -1, filt, 1, aMax, 0.5, 0);

            testCase.verifyTrue(lsFailed);
            testCase.verifyLessThanOrEqual(alpha, aMax);
            testCase.verifyGreaterThan(alpha, 0);
        end

        function testLineSearchStillAcceptsAGoodStep(testCase)
            % Guard for 51/52: caching the trials must not change which step the
            % filter loop accepts, nor make a successful search report failure.
            filt = adamnlopt.Filter();
            [alpha, augment, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                @descentPhiTheta, 0, 0, -1, filt, 1, 1, inf, 0);

            testCase.verifyFalse(lsFailed);
            testCase.verifyFalse(augment);      % f-type step: do not augment
            testCase.verifyEqual(alpha, 1);
        end
    end

    methods (Access = private)

        function problem = circleProblem(~, nlc, hasConGrad)
            %CIRCLEPROBLEM  Evaluator problem struct for one nonlinear inequality.
            problem = struct('objFun', @sumSquaresObj, 'hasObjGrad', true, ...
                             'nlcon', nlc, 'hasConGrad', hasConGrad, ...
                             'Aineq', [], 'bineq', [], 'Aeqlin', [], 'beqlin', [], ...
                             'n', 2, 'mInl', 1, 'mEnl', 0);
        end

        function [ev, x0] = countingEvaluator(testCase, counter, hasConGrad)
            %COUNTINGEVALUATOR  Evaluator over a counted single-circle constraint.
            if hasConGrad
                nlc = @(x) countingCircleGrad(x, counter);
            else
                nlc = @(x) countingCircle(x, counter);
            end
            problem = testCase.circleProblem(nlc, hasConGrad);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());
            x0 = [0.5; 0.5];
        end

        function ev = countingObjEvaluator(~, counter)
            %COUNTINGOBJEVALUATOR  Evaluator whose OBJECTIVE calls are counted.
            problem = struct('objFun', @(x) countingObj(x, counter), ...
                             'hasObjGrad', true, 'nlcon', [], 'hasConGrad', false, ...
                             'Aineq', [], 'bineq', [], 'Aeqlin', [], 'beqlin', [], ...
                             'n', 2, 'mInl', 0, 'mEnl', 0);
            ev = adamnlopt.Evaluator(problem, adamnlopt.defaultOptions());
        end

        function opts = quietOpts(~, overrides)
            %QUIETOPTS  Solver options with display off, plus any overrides.
            opts = struct('Display', 'off');
            f = fieldnames(overrides);
            for k = 1:numel(f)
                opts.(f{k}) = overrides.(f{k});
            end
        end

        function problem = fdProblem(~, objFun)
            %FDPROBLEM  Evaluator problem with no analytic derivatives at all,
            %   so calibrateStep has something to calibrate.
            problem = struct('objFun', objFun, 'hasObjGrad', false, ...
                             'nlcon', [], 'hasConGrad', false, ...
                             'Aineq', [], 'bineq', [], 'Aeqlin', [], 'beqlin', [], ...
                             'n', 2, 'mInl', 0, 'mEnl', 0);
        end

        function [fx, problem] = fixedVarFixture(~, counter, nlcon)
            %FIXEDVARFIXTURE  A reduceProblem map pinning x2 at 2, with a
            %   counted objective (and optionally a counted nlcon) so
            %   expandResult's calls at the solution can be tallied.
            problem = struct('objFun', @(x) countingObj(x, counter), ...
                             'hasObjGrad', true, 'nlcon', nlcon, ...
                             'hasConGrad', ~isempty(nlcon), ...
                             'lb', [0; 2], 'ub', [10; 2], 'Aeqlin', [], 'Aineq', []);
            fx = struct('applied', true, 'n', 2, 'nr', 1, 'nFixed', 1, ...
                        'free', [true; false], 'fixed', [false; true], ...
                        'idxFixed', 2, 'xF', 2, 'xFull', [0; 2], ...
                        'keepEqLin', [], 'keepIneqLin', [], ...
                        'nDropEqLin', 0, 'nDropIneqLin', 0);
        end

        function opts = probeOpts(~, condMax)
            %PROBEOPTS  Options enabling the Fix A Schur conditioning probe.
            opts = adamnlopt.defaultOptions();
            opts.dualCondMax = condMax;
            opts.dualCondProbeMaxDim = 400;
        end

        function [state, res] = kktFixture(~, H, JE)
            %KKTFIXTURE  Minimal state/res pair for kkt_inertiaCorrection.
            mE = size(JE, 1);
            state = struct('H', H, 'JE', JE, 'x', zeros(size(H,1), 1), ...
                           'lamE', zeros(mE, 1));
            res = struct('rStat', ones(size(H,1), 1), 'rFeasE', ones(mE, 1));
        end

        function [state, res] = termFixture(~)
            %TERMFIXTURE  A feasible, non-converged state for terminationCheck.
            %   opt and comp are deliberately large so the exitflag-1 test never
            %   fires and the exit under test is the one that stops the run.
            state = struct('x', [1; 2], 'lamE', zeros(0,1), 'lamI', zeros(0,1), ...
                           'iter', 5, 'nFunEvals', 20, 'f', 1);
            res = struct('opt', 1, 'feas', 0, 'comp', 1);
        end

        function [state, problem] = initFixture(~, cI)
            %INITFIXTURE  Run initializeIterate on an unbounded 2-variable problem
            %   carrying the supplied inequality residuals.
            n = 2;
            ev = struct('mE', 0, 'constraints', @(~) deal(zeros(0,1), cI));
            problem = struct('n', n, 'lb', -inf(n,1), 'ub', inf(n,1), ...
                             'x0', zeros(n,1));
            opts = adamnlopt.defaultOptions();
            state = adamnlopt.initializeIterate(ev, problem, opts);
        end
    end
end

% --- objectives --------------------------------------------------------------
% Written as real two-output functions rather than @(x) deal(f, g): deal
% errors when the caller asks for one output, and adamnlopt.solve probes the
% objective with nargout = 1.

function [f, g] = sumSquaresObj(x)
%SUMSQUARESOBJ  f = x'*x with its gradient.
f = x.' * x;
g = 2 * x;
end

function [f, g] = slowSumSquaresObj(x)
%SLOWSUMSQUARESOBJ  sumSquaresObj with enough delay to exhaust a time budget.
pause(0.01);
f = x.' * x;
g = 2 * x;
end

function [f, g] = shiftedSumSquaresObj(x, c)
%SHIFTEDSUMSQUARESOBJ  f = sum((x - c).^2) with its gradient.
f = sum((x - c).^2);
g = 2 * (x - c);
end

function [c, ceq] = circleCon(x)
%CIRCLECON  Unit-circle inequality x'x - 1 <= 0, uncounted.
c   = x.' * x - 1;
ceq = [];
end

% --- counted user functions --------------------------------------------------
% The evaluation-accounting findings (13, 19-23) are all about whether the
% Evaluator's nFun/nCon match the number of times the USER's function actually
% ran, so these count their own calls in a containers.Map -- a handle class, so
% the count survives being captured in a function handle.

function [f, g] = countingObj(x, counter)
%COUNTINGOBJ  sumSquaresObj that tallies its own calls.
counter('n') = counter('n') + 1;
f = x.' * x;
g = 2 * x;
end

function [c, ceq] = countingCircle(x, counter)
%COUNTINGCIRCLE  Unit-circle inequality x'x - 1 <= 0, tallying its own calls.
counter('n') = counter('n') + 1;
c   = x.' * x - 1;
ceq = [];
end

function [c, ceq, gc, gceq] = countingCircleGrad(x, counter)
%COUNTINGCIRCLEGRAD  COUNTINGCIRCLE with analytic gradients (n-by-m columns).
counter('n') = counter('n') + 1;
c    = x.' * x - 1;
ceq  = [];
gc   = 2 * x;
gceq = [];
end

function [c, ceq, gc, gceq] = emptyGradCon(x, counter)
%EMPTYGRADCON  Claims analytic gradients but returns none for a live row.
counter('n') = counter('n') + 1;
c    = x.' * x - 1;
ceq  = [];
gc   = [];
gceq = [];
end

function [phi, theta] = countingPhiTheta(a, counter, theta)
%COUNTINGPHITHETA  Line-search trial that tallies its own calls.
%   A fixed THETA so the caller can veto every trial with thetaCap and drive
%   the search all the way to the amin floor.
counter('n') = counter('n') + 1;
phi = -a;
end

function [phi, theta] = descentPhiTheta(a)
%DESCENTPHITHETA  Feasible trial with strict objective descent in a.
phi   = -a;
theta = 0;
end

function [c, ceq, gc, gceq] = rowGradCon(x, counter)
%ROWGRADCON  Returns the gradient transposed (1-by-n instead of n-by-1).
counter('n') = counter('n') + 1;
c    = x.' * x - 1;
ceq  = [];
gc   = 2 * x.';
gceq = [];
end
