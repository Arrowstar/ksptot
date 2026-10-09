classdef AdamNlOptReviewFixesTest < AdamNlOptTestCase
%ADAMNLOPTREVIEWFIXESTEST  Regression guards for AdamNlOpt_Review_Report.md fixes.
%   One test (or a few) per report finding, named after its ID, so a later
%   batch can see at a glance which findings are pinned.  Every test here fails
%   on the code before its fix.
%
%   Batch 1: D1.1, D2, D8.1, D9, D11.2, D11.3, D24, D26, D27, D29.
%   Batch 2: D4, D7, D12.1, D12.2, D12.3, A2.
%   Batch 3: D3 (the LVD dialog side is in tests/lvd_tests/AdamNlOptOptionsDialogTest),
%            D33 (found while landing D3).
%   Batch 4: D6, D14, D22, D23.
%   Batch 5: D10 (equality-core restoration parity), plus the equality-core
%            part of D30 (non-finite KKT step).
%   Batch 6: A9, D16 (sub-commit 1); D15, D17.1 (2); D5, D30 (3).
%   Batch 7: D18 (7.1); D13 (7.2); D20, A6 (7.3); A4, A5 (7.4); D17.2/3 (7.5).
%   (The D29 restoration resets are exercised end to end by the benchmark
%   battery; they have no observable unit-level contract.  D13 was tried in
%   Batch 1 and backed out: it stalled HS71 on the unpreconditioned MINRES arm,
%   so it moves to the barrier work -- see the report's batch plan.)
%
%   See also ADAMNLOPTTESTCASE.

    methods (Test)
        %% ---- D1.1: Broyden is opt-in --------------------------------------
        function testD1BroydenIsNotAutoEnabledBySlowJacobians(testCase)
            % A constraint slow enough that one FD Jacobian exceeds the old
            % 0.1 s threshold.  Under the old default the SECOND Jacobian came
            % from a Broyden secant update, not from differencing.
            nl = @(x) AdamNlOptReviewFixesTest.slowCircle(x);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 1));
            x0 = [0.6; 0.7];  x1 = [0.65; 0.62];
            ev.jacobian(x0);
            JE1 = ev.jacobian(x1);
            testCase.verifyEqual(JE1, 2 * x1.', 'AbsTol', 1e-6, ...
                'the Jacobian at a new point must be an exact FD Jacobian, not a secant update');
            testCase.verifyEqual(adamnlopt.defaultOptions().costThreshold, Inf);
            testCase.verifyEqual(AdamNlOptOptions().costThreshold, Inf);
        end

        %% ---- D2: FD step survives a text round trip -----------------------
        function testD2RoundTrippedDefaultStepIsNotUserSet(testCase)
            hRound = str2double(fullAccNum2Str(sqrt(eps)));
            testCase.assumeNotEqual(hRound, sqrt(eps), ...
                'fullAccNum2Str round-trips sqrt(eps) exactly on this platform');
            ev = testCase.evaluatorFrom(struct(), ...
                struct('FiniteDifferenceStepSize', hRound));
            testCase.verifyFalse(ev.fdStepUserSet, ...
                'a default that only round-tripped through text must not disable autoFDStep');
        end

        function testD2GenuinelyUserSetStepIsStillHonoured(testCase)
            ev = testCase.evaluatorFrom(struct(), struct('FiniteDifferenceStepSize', 1e-6));
            testCase.verifyTrue(ev.fdStepUserSet);
        end

        function testD2LvdDefaultStepIsTheSolverDefault(testCase)
            o = AdamNlOptOptions();
            testCase.verifyTrue(isnan(o.finDiffStepSize));
            opts = o.getOptionsForOptimizer([]);
            testCase.verifyEqual(opts.FiniteDifferenceStepSize, sqrt(eps));
        end

        function testD2LoadobjMigratesTheOldStepDefault(testCase)
            o = AdamNlOptOptions();
            o.finDiffStepSize = str2double(fullAccNum2Str(sqrt(eps)));
            o = AdamNlOptOptions.loadobj(o);
            testCase.verifyTrue(isnan(o.finDiffStepSize));
            o.finDiffStepSize = 1e-5;                      % a user choice is kept
            o = AdamNlOptOptions.loadobj(o);
            testCase.verifyEqual(o.finDiffStepSize, 1e-5);
        end

        %% ---- D11.2 / D11.3: LVD defaults equal package defaults -----------
        function testD11LoadobjMigratesTheOldBroydenDefault(testCase)
            o = AdamNlOptOptions();
            o.costThreshold = 0.1;
            o = AdamNlOptOptions.loadobj(o);
            testCase.verifyEqual(o.costThreshold, Inf);
        end

        function testD11LvdDefaultsMatchPackageDefaults(testCase)
            % Every option a default AdamNlOptOptions writes must equal the
            % package default.  LVD writes every non-NaN numeric unconditionally,
            % so a stale value here silently overrides a deliberate package
            % default -- which is how the 0.9 Krylov forcing clamp survived.
            d = adamnlopt.defaultOptions();
            o = AdamNlOptOptions().getOptionsForOptimizer([]);
            % Fields LVD sets on purpose, with the reason.
            intentional = { ...
                'Display', ...   % LVD shows the iteration table by default
                };
            f = fieldnames(d);
            bad = {};
            for i = 1:numel(f)
                if any(strcmp(f{i}, intentional)), continue; end
                a = d.(f{i});  b = o.(f{i});
                if isa(a, 'function_handle') || isa(b, 'function_handle'), continue; end
                if ischar(a) || isstring(a), same = strcmpi(char(a), char(b));
                else, same = isequaln(a, b); end
                if ~same
                    bad{end+1} = sprintf('%s: package %s, LVD %s', f{i}, ...
                        mat2str(a), mat2str(b)); %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(bad, strjoin(bad, newline));
        end

        %% ---- D8.1: no FD Jacobian when there are no nonlinear rows --------
        function testD8NoNonlinearRowsMeansNoDifferencing(testCase)
            calls = 0;
            function v = probe(~), calls = calls + 1; v = zeros(0, 1); end
            J = adamnlopt.finiteDiffJacobian(@probe, [1; 2; 3], zeros(0, 1), ...
                sqrt(eps), 'forward');
            testCase.verifySize(J, [0 3]);
            testCase.verifyEqual(calls, 0);

            ev = testCase.evaluatorFrom(struct('Aeqlin', [1 1], 'beqlin', 1));
            [JE, JI] = ev.jacobian([0.2; 0.3]);
            testCase.verifyEqual(JE, [1 1]);
            testCase.verifySize(JI, [0 2]);
        end

        %% ---- D9: HessianFcn gets the nonlinear multipliers only -----------
        function testD9HessianFcnReceivesOnlyNonlinearMultipliers(testCase)
            nl = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 1, ...
                'Aeqlin', [1 -1], 'beqlin', 0));
            seen = [];
            function H = hfun(~, lambda), seen = lambda; H = eye(2); end
            opts = adamnlopt.defaultOptions();
            opts.HessianFcn = @hfun;
            adamnlopt.lagrangianHessian(ev, [0.5; 0.5], [3; 7], zeros(0, 1), opts);
            testCase.verifyEqual(seen.eqnonlin, 7, ...
                'eqnonlin must hold the nonlinear multiplier only, not [linear; nonlinear]');
            testCase.verifyEmpty(seen.ineqnonlin);
        end

        %% ---- D24: bestKKT also applies on a user stop ---------------------
        function testD24BestKktRollbackAppliesOnUserStop(testCase)
            % Rosenbrock inside a loose box runs in the interior-point core
            % (where bestKKT lives) and is feasible at every iterate.  Stop it
            % early from an IterationFcn: the returned point must be the trace
            % row with the smallest scaled stationarity -- the quantity the
            % rollback ranks on -- not merely the stop iterate.
            p = testCase.catalogEntry('rosenbrock');
            p.lb = -10 * ones(2, 1);  p.ub = 10 * ones(2, 1);
            stopAt = 12;
            o = struct('returnIterate', 'bestKKT', ...
                'IterationFcn', @(info) info.iteration >= stopAt);
            out = testCase.solveProblem(p, o);
            testCase.assumeEqual(out.exitflag, -1, 'the solve converged before the stop');
            tr = out.output.trace;
            k = find(tr.iter <= stopAt);
            [~, j] = min(tr.optScaled(k));
            testCase.assumeLessThan(tr.optScaled(k(j)), tr.optScaled(k(end)), ...
                'the stop iterate is already the best one; nothing to roll back');
            testCase.verifyEqual(out.output.firstOrderOpt, tr.optPrinted(k(j)), ...
                'RelTol', 1e-12, ...
                'a user stop with bestKKT must return the best KKT iterate seen');
            testCase.verifyNotEmpty(regexp(out.output.message, 'best KKT iterate', 'once'));
        end

        %% ---- D26: returned hessian is the final model ---------------------
        function testD26ReturnedHessianIsTheFinalModel(testCase)
            p = testCase.catalogEntry('rosenbrock');
            out = testCase.solveProblem(p, struct('autoScale', 'none'));
            testCase.verifyEqual(out.hessian, out.output.hessianModel.getMatrix(), ...
                'AbsTol', 1e-12);
        end

        %% ---- D27: no merit increase on an ascent direction ----------------
        function testD27AscentDirectionAtFeasiblePointIsNotAccepted(testCase)
            % theta0 = 0 and gd = +1: phi rises along the step.  Two rules used
            % to accept it.  The filter's theta-type test read thetaT <= (1-g)*0
            % as 0 <= 0, accepting any phi; and the merit backup's Armijo test
            % phiT <= phi0 + c*alpha*dphi passed with dphi = gd > 0.
            phiTheta = @(a) deal(10 + 0.5 * a, 0);
            [alpha, ~, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 0, 1, adamnlopt.Filter(), 1);
            testCase.verifyTrue(lsFailed, 'a merit increase must not be accepted');
            testCase.verifyLessThanOrEqual(alpha, 1e-10);
        end

        %% ---- D29: plot-info physical violation ignores interior distance --
        function testD29InteriorPointHasNoBoundViolation(testCase)
            p = testCase.catalogEntry('boundInterior');
            infos = {};
            function stop = rec(info), infos{end+1} = info; stop = false; end
            testCase.solveProblem(p, struct('IterationFcn', @rec, 'maxIter', 3));
            testCase.assertNotEmpty(infos);
            testCase.verifyEqual(infos{1}.constrviolationPhys, 0, ...
                'a point strictly inside its bounds violates nothing');
        end
    end

    methods (Test)
        %% ==== Batch 2: start-up pipeline ===================================

        %% ---- D4: row scales measured with the calibrated step --------------
        function testD4RowScaleIsNotSizedByFdNoise(testCase)
            % A 1e3-gradient inequality row carrying 1e-3 high-frequency noise.
            % Differenced with sqrt(eps) the noise dominates the row norm, so the
            % old pipeline (scale first, calibrate after) set Di 10.6x too small
            % (measured: Di/want = 0.094).  The calibrated step sees the true 1e3.
            fun = @(x) sum(x.^2);
            nl  = @(x) deal(1e3 * x(1) + 1e-3 * sin(1e7 * x(1)) - 500, []);
            o = testCase.quietOpts(struct('maxIter', 0));
            [~, ~, ~, out] = adamnlopt.solve(fun, [0.1; 0.2], [], [], [], [], ...
                [-1; -1], [1; 1], nl, o);
            testCase.assertEqual(out.fdCalibration.flag, 'set');
            want = min(1, 100 / (1e3 * out.scaling.Dx(1)));   % autoScaleMaxGradient = 100 (D3)
            ratio = out.scaling.Di(1) / want;
            testCase.verifyGreaterThan(ratio, 0.5, sprintf('Di off by %.3g', ratio));
            testCase.verifyLessThan(ratio, 2, sprintf('Di off by %.3g', ratio));
        end

        %% ---- D7: calibration is invariant to variable magnitude ------------
        function testD7CalibrationWorksInPhysicalUnits(testCase)
            % Unit relative curvature, 1e-9 noise, variables of size 1e3..2e4.
            % The old probe direction was m_rms times too short, so the sweep
            % measured the wrong displacement: measured rel-err 2.0e-1 (forward,
            % h = 1e-9) before the fix, 1.7e-7 (central, h = 1e-2) after.
            xref = [1e4; 2e4; 1e3];
            fobj = @(x) 0.5 * sum((x ./ xref).^2) + 1e-9 * sin(1e9 * sum((1:3).' .* x) / 2e4);
            ev = testCase.evaluatorFrom(struct('objFun', fobj, 'hasObjGrad', false, 'n', 3));
            x0 = 0.7 * xref;
            ev.calibrateStep(x0);
            [~, g] = ev.objective(x0);
            gTrue = x0 ./ xref.^2;
            relErr = norm(g - gTrue, inf) / norm(gTrue, inf);
            testCase.verifyLessThan(relErr, 1e-4, ...
                sprintf('calibrated gradient rel-err %.2e (fdStep %.1e, %s)', relErr, ev.fdStep, ev.fdType));
        end

        %% ---- D12.1: the scaled Evaluator reuses the probe's x0 Jacobian ----
        function testD12ScaledSolveDoesNotRedifferenceX0(testCase)
            % maxIter = 0: one probe Jacobian at x0 (base + n calls) plus the
            % validateProblem sizing call.  The scaled core used to difference
            % x0 again (another base + n).
            n = 6;  calls = 0;
            function [c, ceq] = con(x), calls = calls + 1; c = sum(x.^2) - 4; ceq = []; end
            o = testCase.quietOpts(struct('maxIter', 0, 'autoFDStep', false));
            [~, ~, ~, out] = adamnlopt.solve(@(x) sum((x - 0.3).^2), (1:n).' / n, ...
                [], [], [], [], [], [], @con, o);
            testCase.assertTrue(out.scaling.applied);
            testCase.verifyEqual(calls, n + 2, ...
                'x0 constraint values and Jacobian must be computed once, not twice');
            testCase.verifyEqual(out.conCount, calls, 'conCount must match the real calls');
        end

        function testD12SeedingWithLinearRowsAndNoNonlinearEqualities(testCase)
            % One linear equality, one nonlinear inequality, no nonlinear
            % equality: sc.Dc is 1x1, and sc.Dc(2:end) is a 1x0 ROW, which made
            % the Batch 2 seeding error with "Arrays have incompatible sizes".
            nl = @(x) deal(x(1)^2 + x(2)^2 - 1, []);
            o = testCase.quietOpts(struct());
            [~, ~, ef] = adamnlopt.solve(@(x) sum(x.^2), [0.1; 0.1], [], [], ...
                [1 1], 2, [], [], nl, o);
            testCase.verifyEqual(ef, -2, 'x1 + x2 = 2 and |x| <= 1 are inconsistent');
        end

        %% ---- D12.2: jacobian() reuses the constraints cache ----------------
        function testD12JacobianReusesTheConstraintsCache(testCase)
            nl = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 1));
            x = [0.3; 0.4];
            ev.constraints(x);
            ev.jacobian(x);
            testCase.verifyEqual(ev.nCon, 1 + 2, 'base values must come from the cache');
        end

        %% ---- D12.3: an FD gradient is cached --------------------------------
        function testD12FdGradientIsCachedAndInvalidatedByTheStep(testCase)
            ev = testCase.evaluatorFrom(struct('objFun', @(x) sum(x.^3), ...
                'hasObjGrad', false, 'n', 3));
            x = [0.1; 0.2; 0.3];
            [~, g1] = ev.objective(x);  n1 = ev.nFun;
            [~, g2] = ev.objective(x);
            testCase.verifyEqual(ev.nFun, n1, 'a second [f,g] at the same x must be free');
            testCase.verifyEqual(g2, g1);
            ev.fdStep = 1e-6;
            [~, ~] = ev.objective(x);
            testCase.verifyEqual(ev.nFun, n1 + 3, 'a new fdStep must invalidate the cached gradient');
        end

        function testD12FdGradientCountIsExactAtABound(testCase)
            calls = 0;
            function v = f(x), calls = calls + 1; v = sum(x.^2); end
            x = [1; 0.5; 0.5];
            [~, nEv] = adamnlopt.finiteDiffGradient(@f, x, f(x), 1e-6, 'central', ...
                zeros(3, 1), ones(3, 1));
            testCase.verifyEqual(nEv, calls - 1, 'nEvals must count the calls actually made');
            testCase.verifyEqual(nEv, 2 * 3 - 1, 'x(1) on its upper bound is one-sided');
        end

        %% ---- A2: one sweep for gradient and Jacobian -----------------------
        function testA2GradientAndJacobianShareOneSweep(testCase)
            seen = zeros(2, 0);
            function v = fobj(x), seen(:, end+1) = x; v = x(1)^2 + 3 * x(2); end
            function [c, ceq] = con(x), seen(:, end+1) = x; c = x(1) * x(2) - 1; ceq = x(1) - x(2)^2; end
            ev = testCase.evaluatorFrom(struct('objFun', @fobj, 'hasObjGrad', false, ...
                'nlcon', @con, 'mInl', 1, 'mEnl', 1));
            x = [0.7; 0.4];
            [f0, g] = ev.objective(x);
            [cE, cI] = ev.constraints(x);
            nBefore = size(seen, 2);
            [JE, JI] = ev.jacobian(x);
            testCase.verifyEqual(size(seen, 2), nBefore, 'the Jacobian must already be cached');
            testCase.verifyEqual(size(unique(seen.', 'rows'), 1), 1 + 2, ...
                'each probe point must be visited by one sweep only');
            % Bit-identical to the separate sweeps.
            h = ev.fdStep;
            gSep = adamnlopt.finiteDiffGradient(@(z) z(1)^2 + 3 * z(2), x, f0, h, 'forward');
            Jsep = adamnlopt.finiteDiffJacobian(@(z) AdamNlOptReviewFixesTest.stackedCon(z), ...
                x, [cI; cE], h, 'forward');
            testCase.verifyEqual(g, gSep);
            testCase.verifyEqual([JI; JE], Jsep);
        end
    end

    methods (Test)
        %% ==== Batch 3: physical feasibility (D3) ===========================
        function testD3ReportedViolationIsInPhysicalUnits(testCase)
            % A steep equality row (gradient 1e7) is scaled by ~1e-5.  Stop
            % early so the iterate is still infeasible: the reported
            % constrViolation must be the caller's |ceq|, not the scaled one.
            fun = @(x) (x(1) - 3)^2 + (x(2) - 1)^2;
            nl  = @(x) deal([], 1e7 * (x(1) + x(2) - 2) + x(1)^2);
            o = testCase.quietOpts(struct('maxIter', 1));
            [x, ~, ~, out] = adamnlopt.solve(fun, [0; 0], [], [], [], [], [], [], nl, o);
            [~, ceq] = nl(x);
            testCase.assumeGreaterThan(abs(ceq), 1e-6, 'iterate already feasible');
            testCase.verifyEqual(out.constrViolation, abs(ceq), 'RelTol', 1e-9);
            testCase.verifyLessThan(out.constrViolationScaled, out.constrViolation, ...
                'the scaled value is reported separately');
        end

        function testD3ConvergenceNeedsPhysicalFeasibility(testCase)
            state = struct('iter', 3, 'x', [1; 2], 'lamE', 1, 'lamI', zeros(0, 1), ...
                'f', 0, 'nFunEvals', 10, 'elapsed', 0, 'stepNorm', 1);
            res = struct('opt', 1e-9, 'feas', 1e-9, 'comp', 0);
            opts = adamnlopt.defaultOptions();
            opts.compTol = opts.optTol;
            stop = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyTrue(stop, 'control: no feasPhys means the scaled test alone decides');
            res.feasPhys = 1e-2;
            [stop, ef] = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyFalse(stop && ef > 0, ...
                'a point violating its constraints by 1e-2 in physical units is not converged');
            res.feasPhys = 1e-5;
            [stop, ef] = adamnlopt.terminationCheck(state, res, opts);
            testCase.verifyTrue(stop && ef == 1);
        end

        function testD3RowsFlatterThanMaxGradientAreNotScaled(testCase)
            nl = @(x) deal([50 * x(1) - 1; 1e4 * x(2) - 1], []);
            o = testCase.quietOpts(struct('maxIter', 0, 'autoFDStep', false));
            [~, ~, ~, out] = adamnlopt.solve(@(x) sum(x.^2), [0.01; 0.01], ...
                [], [], [], [], [], [], nl, o);
            testCase.verifyEqual(out.scaling.Di(1), 1, 'a gradient-50 row is below the cap: unscaled');
            testCase.verifyEqual(out.scaling.Di(2), 100 / 1e4, 'RelTol', 1e-6, ...
                'a gradient-1e4 row is scaled down to the cap');
        end

        function testD33StepExitWaitsForTheBarrier(testCase)
            % min (x-3)'(x-3) s.t. x1 + x2 = 2, 0 <= x <= 10: the Newton step is
            % exact, so the step collapses after two iterations while mu is
            % still large.  The step-size exit used to report exitflag 2 there
            % with complementarity 2e-2 and lamE = 4.018 (analytic 4).
            fun = @(x) deal(sum((x - 3).^2), 2 * (x - 3));
            o = testCase.quietOpts(struct('SpecifyObjectiveGradient', true));
            [x, ~, ef, out, lam] = adamnlopt.solve(fun, [0.5; 0.5], [], [], ...
                [1 1], 2, [0; 0], [10; 10], [], o);
            testCase.verifyGreaterThan(ef, 0);
            testCase.verifyEqual(x, [1; 1], 'AbsTol', 1e-6);
            testCase.verifyLessThanOrEqual(out.complementarity, 1e-5, ...
                'a converged exit must have finished the barrier');
            testCase.verifyEqual(lam.eqlin, 4, 'AbsTol', 1e-4);
        end

        function testD3IterationInfoViolationIsPhysical(testCase)
            nl  = @(x) deal([], 1e7 * (x(1) + x(2) - 2));
            infos = {};
            function stop = rec(info), infos{end+1} = info; stop = false; end
            testCase.solveProblem(struct('name', 'steep', 'fun', @(x) sum(x.^2), ...
                'x0', [0; 0], 'A', [], 'b', [], 'Aeq', [], 'beq', [], 'lb', [], 'ub', [], ...
                'nonlcon', nl, 'hasObjGrad', false, 'hasConGrad', false), ...
                struct('IterationFcn', @rec, 'maxIter', 2));
            i0 = infos{1};
            testCase.verifyEqual(i0.constrviolation, 2e7, 'RelTol', 1e-9, ...
                'info.constrviolation is |ceq| at x0 in the caller''s units');
            testCase.verifyTrue(isfield(i0, 'constrviolationScaled'));
        end
    end

    methods (Test)
        %% ==== Batch 4: quasi-Newton and dual-update hygiene ================
        function testD6AndD22FailedLineSearchesLearnNothing(testCase)
            % FD gradients at sqrt(eps) on a 1e-4-noise objective: the gradient
            % error (~1e-4/1.5e-8) swamps the curvature, so line searches fail
            % (58 of 60 iterations).  At 1e-6 noise the steps collapse to 1e-10
            % but the filter still accepts them, so lsFailed never fires.
            % On a failed search the step is the 1e-10 creep: the Hessian model
            % must not take the pair (D6) and the duals must not take a full
            % Newton step (D22: aD = aP).
            tr = testCase.noisyBoundedTrace();
            failed = tr.lsFailed == 1 & tr.restorationFired ~= 1;
            testCase.assumeTrue(any(failed), 'fixture produced no failed line search');
            testCase.verifyFalse(any(tr.bfgsAccepted(failed) == 1), ...
                'a failed line search must not feed the secant model (D6)');
            testCase.verifyEqual(tr.aD(failed), tr.aP(failed), ...
                'a failed line search must not take a full dual step (D22)');
            testCase.verifyTrue(all(tr.bfgsSkippedShort(failed) == 1));
        end

        function testD14BoundMultipliersStayWithinKappaSigma(testCase)
            p = testCase.catalogEntry('boundActive');
            kS = 1.5;
            ratios = [];
            function stop = rec(info)
                st = info.state;  stop = false;
                if info.iteration < 1, return; end
                fin = isfinite(info.lb);
                ratios = [ratios; st.zL(fin) .* (st.x(fin) - info.lb(fin)) / st.mu]; %#ok<AGROW>
            end
            testCase.solveProblem(p, struct('kappaSigma', kS, 'autoScale', 'none', ...
                'IterationFcn', @rec));
            testCase.assertNotEmpty(ratios);
            testCase.verifyLessThanOrEqual(max(ratios), kS * (1 + 1e-9));
            testCase.verifyGreaterThanOrEqual(min(ratios), (1 / kS) * (1 - 1e-9));
        end

        function testD23PenaltyCanFallAfterABarrierDecrease(testCase)
            p = testCase.catalogEntry('hs71');
            out = testCase.solveProblem(p, struct('globalization', 'merit'));
            rho = out.output.trace.rho;
            rho = rho(isfinite(rho));
            testCase.assumeGreaterThan(numel(rho), 3);
            testCase.verifyTrue(any(diff(rho) < 0), ...
                'rho must be able to fall once a barrier subproblem ends (D23)');
            testCase.verifyGreaterThan(out.exitflag, 0);
        end
    end

    methods (Test)
        %% ==== Batch 4: quasi-Newton and dual-update hygiene ================
        function testD6NoisyShortPairDoesNotReachTheModel(testCase)
            % n = 50 BFGS model after one sane pair; then a pair whose step is
            % far shorter than the FD step, with a pure-noise y.  BFGS alone
            % accepts it (cond goes 1 -> ~7e6); the solver's gate must not
            % pass it on.
            n = 50;  rng(4);
            B = adamnlopt.BFGSHessian(n);
            s1 = randn(n, 1);  B.update(s1, 3 * s1);
            Bbefore = B.getMatrix();
            ev = testCase.evaluatorFrom(struct('objFun', @(x) sum(x.^2), ...
                'hasObjGrad', false, 'n', n));
            x = ones(n, 1);  s = 1e-10 * randn(n, 1);  y = 1e-6 * randn(n, 1);
            info = AdamNlOptReviewFixesTest.callUpdate(B, s, y, ev, x, false);
            testCase.verifyEqual(info.bfgsSkippedShort, 1);
            testCase.verifyEqual(B.getMatrix(), Bbefore, ...
                'a sub-resolution noise pair must leave the model untouched');
        end

        function testD6ForcedCreepIsNotLearned(testCase)
            n = 3;
            B = adamnlopt.BFGSHessian(n);
            ev = testCase.evaluatorFrom(struct('objFun', @(x) sum(x.^2), ...
                'hasObjGrad', true, 'n', n));
            s = [0.3; -0.2; 0.1];
            info = AdamNlOptReviewFixesTest.callUpdate(B, s, 2 * s, ev, ones(n, 1), true);
            testCase.verifyEqual(info.bfgsSkippedShort, 1, ...
                'a step from a failed line search is a creep, not a curvature sample');
            info = AdamNlOptReviewFixesTest.callUpdate(B, s, 2 * s, ev, ones(n, 1), false);
            testCase.verifyEqual(info.bfgsSkippedShort, 0, 'control: an ordinary step is learned');
        end
    end

    methods (Test)
        %% ==== Batch 5: equality-core parity (D10) ==========================
        function testD10EqualityRestorationKeepsTheFilter(testCase)
            % Equality-only, so the equality core runs.  From (0.01, 0) on the
            % unit circle the first steps stall and restoration fires.  The
            % filter must be AUGMENTED on the way out (as the IP core has done
            % since 517d42b3), never cleared to zero entries.
            p = AdamNlOptTestCase.problem('linCircle', @(x) x(1) + x(2), [0.01; 0]);
            p.hasObjGrad = false;
            p.nonlcon = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            out = testCase.solveProblem(p, struct('maxIter', 200));
            tr = out.output.trace;
            testCase.assertEqual(tr.meta.core, 'eq');
            k = find(tr.restorationFired > 0);
            testCase.assumeNotEmpty(k, 'restoration did not fire; fixture no longer exercises D10');
            k = k(k < numel(tr.iter));
            testCase.verifyTrue(all(tr.filterSize(k + 1) >= 1), ...
                'the filter must not be empty after a restoration');
            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyEqual(out.fval, -sqrt(2), 'AbsTol', 1e-6);
        end

        function testD10EqualityCoreReportsLineSearchFailures(testCase)
            % lsFailed used to be hard-coded false in the equality core's trace.
            % This inconsistent system fails its first line search.  (Before
            % Batch 6.3's minimum-norm multipliers its KKT step was NaN; the D30
            % guard for that case is pinned by testD30NonFiniteKktIsRejectedImmediately.)
            nl = @(x) deal([], [x(1) + x(2) - 1; x(1) + x(2) - 3]);
            o = testCase.quietOpts(struct());
            [x, ~, ef, out] = adamnlopt.solve(@(x) sum(x.^2), [0.5; 0.5], [], [], ...
                [], [], [], [], nl, o);
            testCase.verifyEqual(out.trace.lsFailed(1), 1);
            testCase.verifyTrue(all(isfinite(x)), 'a NaN step must never be taken');
            testCase.verifyEqual(ef, -2, 'x1 + x2 = 1 and = 3 are inconsistent');
        end
    end

    methods (Test)
        %% ==== Batch 6.1: factor plumbing (A9) and solve accuracy (D16) =====
        function testD16ReportsTheRelativeResidual(testCase)
            % Refinement was measured and rejected (see linalg_solveKKTdirect);
            % the residual is kept as a diagnostic.
            rng(11);  n = 8;  mE = 2;
            A = randn(n);  H = A * A.' + eye(n);  JE = randn(mE, n);
            K = [H, JE.'; JE, zeros(mE)];  rhs = randn(n + mE, 1);
            [d, info] = adamnlopt.linalg_solveKKTdirect(K, rhs);
            testCase.verifyEqual(info.resRel, norm(K * d - rhs, inf) / max(1, norm(rhs, inf)), ...
                'RelTol', 1e-12);
            testCase.verifyLessThan(info.resRel, 1e-12);
        end

        function testD16HealthySmallPivotIsNotCalledZero(testCase)
            % Primal pivots 1e9, one constraint whose Schur pivot is -1e-4, N = 600.
            % N*eps*1e9 = 1.3e-4 called that pivot zero; 10*eps*1e9 does not.
            n = 599;
            JE = sqrt(1e5 / n) * ones(1, n);
            K = [1e9 * eye(n), JE.'; JE, 0];
            [~, info] = adamnlopt.linalg_solveKKTdirect(K, [ones(n, 1); 1]);
            testCase.verifyFalse(info.rankDeficient);
            testCase.verifyEqual(info.inertia, [n 1 0]);
        end

        function testA9ResolveMatchesAFreshSolve(testCase)
            rng(12);  n = 8;  mE = 3;
            A = randn(n);  H = A * A.' + eye(n);  JE = randn(mE, n);
            K = [H, JE.'; JE, -1e-8 * eye(mE)];
            [~, info] = adamnlopt.linalg_solveKKTdirect(K, randn(n + mE, 1));
            rhs2 = randn(n + mE, 1);
            d2 = adamnlopt.linalg_resolveKKT(info.factors, rhs2);
            testCase.verifyEqual(d2, K \ rhs2, 'RelTol', 1e-10);
        end

        function testD16DenseHessianGivesADenseKkt(testCase)
            state = struct('H', eye(3), 'JE', sparse([1 1 0]), 'x', zeros(3, 1), 'lamE', 0);
            res = struct('rStat', zeros(3, 1), 'rFeasE', 0);
            K = adamnlopt.kkt_assemble(state, res, []);
            testCase.verifyFalse(issparse(K), 'dense H with sparse JE must assemble a dense K');
        end
    end

    methods (Test)
        %% ==== Batch 6.2: regularization policy (D15), SOC re-solve (D17.1) ==
        function testD15FirstFactorizationIgnoresAStaleRegularization(testCase)
            rng(3);  n = 5;  mE = 2;
            B = randn(n);  H = B.' * B + n * eye(n);  JE = randn(mE, n);
            state = struct('H', H, 'JE', JE, 'x', zeros(n, 1), 'lamE', zeros(mE, 1));
            res = struct('rStat', randn(n, 1), 'rFeasE', randn(mE, 1));
            stale = struct('delta', 1e-2, 'gamma', 1e-2);
            [d, ~, info, reg] = adamnlopt.kkt_inertiaCorrection(state, res, n, mE, ...
                stale, adamnlopt.defaultOptions());
            testCase.verifyEqual(info.tries, 0);
            testCase.verifyEqual([reg.delta reg.gamma], [0 0], ...
                'a well-posed system must be solved unregularized whatever reg0 says');
            K = [H, JE.'; JE, zeros(mE)];
            testCase.verifyEqual(d, K \ (-[res.rStat; res.rFeasE]), 'RelTol', 1e-9);
        end

        function testD15FixAShiftVanishesNearFeasibility(testCase)
            % cond(S) ~ 4e10 > dualCondMax = 1e8, so Fix A wants gamma ~ 2e-8.
            JE = [1 0; 1 1e-5];  H = eye(2);
            state = struct('H', H, 'JE', JE, 'x', zeros(2, 1), 'lamE', zeros(2, 1));
            opts = adamnlopt.defaultOptions();
            opts.dualStepMax = Inf;   % isolate D15 from the D5.2 dual-cap growth
            far = struct('rStat', [1; 1], 'rFeasE', [1; 1]);
            [~, ~, iFar] = adamnlopt.kkt_inertiaCorrection(state, far, 2, 2, [], opts);
            near = struct('rStat', [1; 1], 'rFeasE', [1e-12; 1e-12]);
            [~, ~, iNear, rNear] = adamnlopt.kkt_inertiaCorrection(state, near, 2, 2, [], opts);
            testCase.assumeGreaterThan(iFar.schur.gamma, 1e-8, 'Fix A did not fire on the fixture');
            testCase.verifyLessThanOrEqual(rNear.gamma, 1e-8 * (1 + 1e-12), ...
                'near feasibility the dual shift must fall to its 1e-8 floor');
            testCase.verifyEqual(iNear.tries, 0);
        end

        function testD17SocReSolvesReuseThePrimaryFactorization(testCase)
            % Maratos-type problem forced into the interior-point core by a box:
            % SOC is attempted on several iterations.  Each attempt is a solve,
            % but only the primary step may factor the KKT matrix.
            fun = @(x) 2 * (x(1)^2 + x(2)^2 - 1) - x(1);
            p = AdamNlOptTestCase.problem('maratos', fun, [cos(0.8); sin(0.8)]);
            p.hasObjGrad = false;
            p.nonlcon = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            p.lb = [-5; -5];  p.ub = [5; 5];
            out = testCase.solveProblem(p, struct('maxIter', 100));
            tr = out.output.trace;
            k = tr.nSolves > 1;
            testCase.assumeTrue(any(k), 'SOC was never attempted; fixture no longer exercises D17.1');
            testCase.verifyEqual(unique(tr.nFactorizations(k)).', 1, ...
                'an SOC re-solve must re-use the primary factorization');
            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyEqual(out.fval, -1, 'AbsTol', 1e-6);
        end
    end

    methods (Test)
        %% ==== Batch 6.3: degenerate Jacobians (D5), non-finite steps (D30) ==
        function testD5DegenerateStartFindsTheMinimum(testCase)
            % min x1 + x2 on the unit circle from x0 = 0, FD constraint
            % gradient: JE(x0) is analytically 0 and the FD value is 1.5e-8.
            % Both cores converged to the MAXIMUM (f = +sqrt(2)).  The equality
            % core (no box) relies on the D5.2 cap, on there by default.
            nl = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            o = testCase.quietOpts(struct());
            for box = [false true]
                if box, lb = [-5; -5]; ub = [5; 5]; else, lb = []; ub = []; end
                [~, f, ef] = adamnlopt.solve(@(x) x(1) + x(2), [0; 0], [], [], [], [], ...
                    lb, ub, nl, o);
                testCase.verifyGreaterThan(ef, 0);
                testCase.verifyEqual(f, -sqrt(2), 'AbsTol', 1e-6, ...
                    sprintf('box = %d: converged to the wrong stationary point', box));
            end
        end

        function testD5MultiplierFitIsMinimumNorm(testCase)
            lam = adamnlopt.step_multiplierUpdate([1; 2; 3], [1 0 0; 1 0 0]);
            testCase.verifyEqual(lam, [-0.5; -0.5], 'AbsTol', 1e-12, ...
                'a rank-deficient JE must give the minimum-norm multipliers');
            lam = adamnlopt.step_multiplierUpdate([1; 1], [1e-8 1e-8], [], 1e-6);
            testCase.verifyEqual(lam, 0, 'a row below the noise tolerance carries no multiplier');
        end

        function testD5DualCapIsEnforcedInTheCoupledSolve(testCase)
            % Near-zero constraint row: with gamma = 1e-8 the solve wants
            % dlamE ~ cE/gamma.  The cap must hold for the step the solve
            % returns, with dx consistent with that dlamE.
            state = struct('H', eye(2), 'JE', [1e-8 1e-8], 'x', zeros(2, 1), 'lamE', 0);
            res = struct('rStat', [1; 1], 'rFeasE', -1);
            opts = adamnlopt.defaultOptions();
            opts.dualCapViaGamma = true;   % opt-in since the MunarFlyby regression
            [d, idx, info, reg] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 1, [], opts);
            testCase.verifyLessThanOrEqual(norm(d(idx.lamE), inf), opts.dualStepMax * (1 + 1e-9));
            testCase.verifyGreaterThan(info.dualCapGrows, 0);
            % Primal row of the regularized system holds for the returned step.
            testCase.verifyEqual((state.H + reg.delta * eye(2)) * d(idx.x) + ...
                state.JE.' * d(idx.lamE), -res.rStat, 'AbsTol', 1e-12);
            testCase.verifyGreaterThan(reg.gamma, 1e-8);
        end

        function testD30NonFiniteKktIsRejectedImmediately(testCase)
            state = struct('H', [Inf 0; 0 1], 'JE', [1 1], 'x', zeros(2, 1), 'lamE', 0);
            res = struct('rStat', [1; 1], 'rFeasE', 0);
            [d, ~, info] = adamnlopt.kkt_inertiaCorrection(state, res, 2, 1, [], adamnlopt.defaultOptions());
            testCase.verifyEqual(info.tries, 0, 'no regularization ladder on a non-finite K');
            testCase.verifyFalse(info.solved);
            testCase.verifyTrue(all(isfinite(d)));
        end
    end

    methods (Test)
        %% ==== Batch 7.1: filter line search (D18) ==========================
        function testD18CurvedFullStepIsAnFTypeAccept(testCase)
            % Feasible start, descent direction, theta grows quadratically along
            % a curved constraint.  The theta-growth cap (1e-4 here) used to veto
            % the f-type trial too and backtrack to ~0.1.
            phiTheta = @(a) deal(10 - a, 1e-2 * a^2);
            [alpha, augment, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 0, -1, adamnlopt.Filter(), 1, 1, 1e-4);
            testCase.verifyFalse(lsFailed);
            testCase.verifyEqual(alpha, 1, 'the full step satisfies Armijo and the switching rule');
            testCase.verifyFalse(augment, 'an f-type accept does not augment the filter');
        end

        function testD18AlphaMinCutsAStalledSearchShort(testCase)
            calls = 0;
            function [phi, theta] = worse(a), calls = calls + 1; phi = 10 + a; theta = 1 + a; end
            [alpha, ~, ~, lsFailed] = adamnlopt.globalize_filterLineSearch( ...
                @worse, 10, 1, -1, adamnlopt.Filter(), 1);
            testCase.verifyTrue(lsFailed);
            testCase.verifyLessThanOrEqual(alpha, 1e-10, 'the forced creep is unchanged');
            testCase.verifyLessThanOrEqual(calls, 22, sprintf( ...
                'a stalled search must stop at the WB alpha_min (%d trials)', calls));
        end

        function testD18ThetaMinComesFromTheFilter(testCase)
            % theta0 = 0.3 is below a solve-level thetaMin of 0.5, so the step
            % is f-type (no augment).  With thetaMin computed from the current
            % theta (1e-4) the same step was theta-type and augmented.
            f = adamnlopt.Filter();  f.thetaMin = 0.5;
            phiTheta = @(a) deal(10 - a, 0.3);
            [alpha, augment] = adamnlopt.globalize_filterLineSearch( ...
                phiTheta, 10, 0.3, -1, f, 1);
            testCase.verifyEqual(alpha, 1);
            testCase.verifyFalse(augment);
        end
    end

    methods (Test)
        %% ==== Batch 7.2: barrier gate (D13) =================================
        function testD13BarrierCanFallSeveralLevelsInOneIteration(testCase)
            % An interior minimum: once the iterate is centred, the next barrier
            % subproblems are already solved, and mu should fall more than one
            % level per iteration instead of paying a KKT solve per level.
            p = testCase.catalogEntry('boundInterior');
            out = testCase.solveProblem(p, struct());
            tr = out.output.trace;
            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyGreaterThan(max(tr.nMuSteps), 1, ...
                'mu never fell more than one level in an iteration');
        end

        function testD13NoisyBoundedProblemConverges(testCase)
            % 1e-7-noise objective in a box (the review's noisy5 case): the
            % unscaled barrier gate froze mu above compTol and the solve stopped
            % on its step tolerance with exitflag 0 at opt 3.0e-6.
            fun = @(x) sum((x - 0.3).^2) + 1e-7 * sin(1e7 * sum(x));
            o = testCase.quietOpts(struct());
            [x, ~, ef] = adamnlopt.solve(fun, ones(5, 1), [], [], [], [], ...
                zeros(5, 1), 2 * ones(5, 1), [], o);
            testCase.verifyGreaterThan(ef, 0);
            testCase.verifyEqual(x, 0.3 * ones(5, 1), 'AbsTol', 1e-5);
        end
    end

    methods (Test)
        %% ==== Batch 7.3: restoration (D20, A6) =============================
        function testD20RankDeficientConsistentSystemIsRestored(testCase)
            % cE = [x1-1; 2(x1-1); x2+3]: rank-2 J, consistent.  The l1 Armijo
            % test on a Gauss-Newton direction had no descent guarantee here.
            nl = @(x) deal([], [x(1) - 1; 2 * (x(1) - 1); x(2) + 3]);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 3));
            [x, info] = adamnlopt.degeneracy_restorationPhase(ev, [5; 5], [], [], ...
                adamnlopt.defaultOptions());
            testCase.verifyTrue(info.reduced);
            testCase.verifyLessThan(info.theta, 1e-6);
            testCase.verifyEqual(x, [1; -3], 'AbsTol', 1e-6);
            testCase.verifyFalse(info.stationary);
        end

        function testD20InconsistentSystemCarriesACertificate(testCase)
            nl = @(x) deal([], [x(1) - 1; x(1) - 2]);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 2));
            [~, info] = adamnlopt.degeneracy_restorationPhase(ev, [5; 5], [], [], ...
                adamnlopt.defaultOptions());
            testCase.verifyTrue(info.stationary, ...
                'x1 = 1 and x1 = 2 is locally infeasible; restoration must say so');
            testCase.verifyGreaterThan(info.theta, 0.9);
        end

        function testA7RestorationRecalibratesANoiseLimitedJacobian(testCase)
            % 1e-5 high-frequency "simulation noise" on a consistent linear
            % system: at sqrt(eps) the FD Jacobian is ~100x wrong, every
            % restoration step failed Armijo and theta stalled at 10.6.  As on
            % lvdExample_SpinLaunchOptimization, which then exited -2.
            nz = @(x) 1e-5 * sin(1e7 * x(1) + 3e6 * x(2));
            nl = @(x) deal([], [x(1) - 1 + nz(x); x(2) + 3 + nz(x)]);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 2));
            [~, info] = adamnlopt.degeneracy_restorationPhase(ev, [5; 5], [], [], ...
                adamnlopt.defaultOptions());
            testCase.verifyTrue(info.fdRecalibrated);
            testCase.verifyLessThan(info.theta, 1e-4);
            testCase.verifyFalse(info.stationary);
        end

        function testA7CalibrationRunsAtAPointOnABound(testCase)
            % One coordinate on its bound capped the symmetric sweep at h = 0 and
            % returned 'boundLimited' with the sqrt(eps) step kept, so neither
            % LVD's x0 (10*eps inside the box) nor a restoration iterate
            % (projected onto it) was ever calibrated.
            fn = @(x) (x(1) - 1)^2 + (x(2) - 2)^2 + 1e-6 * sin(1e8 * x(1) + 7e7 * x(2));
            ev = testCase.evaluatorFrom(struct('objFun', fn, 'hasObjGrad', false, ...
                'lb', [0; -10], 'ub', [10; 10]));
            info = ev.calibrateStep([0; 1]);
            testCase.verifyEqual(info.flag, 'set');
            testCase.verifyGreaterThan(ev.fdStep, 1e-5, 'the 1e-6 noise needs a large step');
        end

        function testD20RestorationHoldsAVariableOnItsBound(testCase)
            % 100*x1 + x2 + 1 = 0 with x1 >= 0, from x = 0 (on the bound).  The
            % bound-blind step pointed mostly out of the box; projected, it made
            % no progress (theta stayed 1).  Holding x1 restores via x2.
            nl = @(x) deal([], 100 * x(1) + x(2) + 1);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 1));
            [x, info] = adamnlopt.degeneracy_restorationPhase(ev, [0; 0], [0; -inf], ...
                [inf; inf], adamnlopt.defaultOptions());
            testCase.verifyLessThan(info.theta, 1e-6);
            testCase.verifyEqual(x, [0; -1], 'AbsTol', 1e-6);
            testCase.verifyFalse(info.stationary);
        end

        function testD20BoundInfeasibleSystemCarriesACertificate(testCase)
            % Adding x1 = x2 makes it infeasible in the box (x1 = -1/101 < 0).
            % The bound-blind step spun 50 iterations with no verdict; the
            % free-variable certificate fires at the least-violation point.
            nl = @(x) deal([], [100 * x(1) + x(2) + 1; x(1) - x(2)]);
            ev = testCase.evaluatorFrom(struct('nlcon', nl, 'mEnl', 2));
            [x, info] = adamnlopt.degeneracy_restorationPhase(ev, [0; 0], [0; -inf], ...
                [inf; inf], adamnlopt.defaultOptions());
            testCase.verifyTrue(info.stationary);
            testCase.verifyEqual(x, [0; -0.5], 'AbsTol', 1e-3);
        end

        function testD20InfeasibleExitIsGroundedInTheCertificate(testCase)
            nl = @(x) deal([], [x(1) + x(2) - 1; x(1) + x(2) - 3]);
            [~, ~, ef, out] = adamnlopt.solve(@(x) sum(x.^2), [0.5; 0.5], [], [], ...
                [], [], [], [], nl, testCase.quietOpts(struct()));
            testCase.verifyEqual(ef, -2);
            testCase.verifyNotEmpty(regexp(out.message, 'stationary point', 'once'));
        end
    end

    methods (Test)
        %% ==== Batch 7.4: acceptable termination (A5), filter reset (A4) ====
        function testA5AcceptableExitOnAnFdLimitedProblem(testCase)
            % Rosenbrock n = 10 with forward-difference gradients: optTol 1e-6
            % is below the FD noise floor, so the solve used to stop on its
            % step tolerance with exitflag 0 at f = 2e-10.
            nr = 10;
            fros = @(x) sum(100 * (x(2:end) - x(1:end-1).^2).^2 + (1 - x(1:end-1)).^2);
            [x, f, ef, out] = adamnlopt.solve(fros, -2 * ones(nr, 1), [], [], [], [], ...
                [], [], [], testCase.quietOpts(struct()));
            testCase.verifyGreaterThan(ef, 0, out.message);
            testCase.verifyLessThan(f, 1e-8);
            testCase.verifyEqual(x, ones(nr, 1), 'AbsTol', 1e-3);
        end

        function testA5FullConvergenceStillReportsExitflagOne(testCase)
            p = testCase.catalogEntry('hs71');
            out = testCase.solveProblem(p, struct());
            testCase.verifyEqual(out.exitflag, 1, 'a well-posed problem must not stop at "acceptable"');
        end

        function testA4FilterResetsAfterRepeatedFirstTrialBlocks(testCase)
            f = adamnlopt.Filter();
            f.augment(1, 1);
            for k = 1:4
                testCase.verifyFalse(f.noteFirstTrial(true, 5, 2));
            end
            testCase.verifyTrue(f.noteFirstTrial(true, 5, 2), 'the fifth block resets');
            testCase.verifyEmpty(f.entries);
            f.augment(1, 1);
            f.noteFirstTrial(true, 5, 2);
            f.noteFirstTrial(false, 5, 2);   % an unblocked iteration restarts the count
            testCase.verifyEqual(f.nBlocked, 0);
            for k = 1:5, f.noteFirstTrial(true, 5, 2); end
            testCase.verifyEqual(f.nResets, 2);
            f.augment(1, 1);
            for k = 1:10, f.noteFirstTrial(true, 5, 2); end
            testCase.verifyNotEmpty(f.entries, 'no more than maxResets resets');
        end
    end

    methods (Test)
        %% ==== Batch 7.5: second-order correction order (D17.2, D17.3) =====
        function testD17SocCorrectsTheRejectedFullStep(testCase)
            % Maratos-type problem in the IP core: the full Newton step along
            % the circle raises theta.  SOC must be tried right after that first
            % rejection, one trial per correction, and adopted.  Before 7.5 SOC
            % ran only after a full backtracking collapse, never adopted on this
            % problem, and the solve took 13 iterations / 300 evaluations.
            fun = @(x) 2 * (x(1)^2 + x(2)^2 - 1) - x(1);
            p = AdamNlOptTestCase.problem('maratos', fun, [cos(0.8); sin(0.8)]);
            p.hasObjGrad = false;
            p.nonlcon = @(x) deal([], x(1)^2 + x(2)^2 - 1);
            p.lb = [-5; -5];  p.ub = [5; 5];
            out = testCase.solveProblem(p, struct('maxIter', 100));
            testCase.verifyEqual(out.exitflag, 1);
            testCase.verifyEqual(out.fval, -1, 'AbsTol', 1e-6);
            testCase.verifyGreaterThan(nansum(out.output.trace.socAdopted), 0, ...
                'a second-order correction must be adopted on the Maratos problem');
            testCase.verifyLessThanOrEqual(out.output.funcCount, 150);
        end

        function testD17SocThresholdOptionIsGone(testCase)
            testCase.verifyFalse(isfield(adamnlopt.defaultOptions(), 'socThreshold'), ...
                'socThreshold no longer does anything and must not be offered');
        end
    end

    methods (Static)
        function info = callUpdate(B, s, y, ev, x, forced)
            % adamnlopt.updateHessianModel (moved out of solve.m in Batch 4 so
            % it can be tested): a zero-constraint pair with gOld = 0 and
            % gNew = y gives exactly (s, y).
            n = numel(s);
            info = adamnlopt.updateHessianModel(B, zeros(n, 1), [], [], y, [], [], ...
                zeros(0, 1), zeros(0, 1), s, ev, x, forced);
        end

        function v = stackedCon(x)
            v = [x(1) * x(2) - 1; x(1) - x(2)^2];
        end

        function [c, ceq] = slowCircle(x)
            pause(0.06);
            c = [];
            ceq = x(1)^2 + x(2)^2 - 1;
        end
    end

    methods (Test)
        %% ==== Batch 9.1: failed evaluations (D21) ============================
        function testD21FailedEvaluationIsRejectedNotAccepted(testCase)
            % nlcon returns scalar NaNs for x1 > 0.9, as LVD's ConstraintSet
            % does when a propagation fails.  The first step landed there, and
            % the NaN point was ACCEPTED (max() skips NaN, so it read feas 0)
            % and the solve sat on it to maxIter.
            x1 = (0.1 + sqrt(1.99)) / 2;
            [x, f, ef] = adamnlopt.solve(@(x) -x(1) - x(2), [0.3; 0.2], [], [], [], [], ...
                [-2; -2], [2; 2], @failsBeyond09, testCase.quietOpts(struct()));
            testCase.verifyGreaterThan(ef, 0);
            testCase.verifyEqual(x, [x1; x1 - 0.1], 'AbsTol', 1e-6);
            testCase.verifyEqual(f, -(2 * x1 - 0.1), 'AbsTol', 1e-6);
        end

        function testD8FdHessianOfAnFdGradientUsesALargerStep(testCase)
            % 1e-9 noise, calibrated FD gradient: differencing it at sqrt(eps)
            % amplified the gradient error to 7e-2 relative in H.
            A = [4 1; 1 3];
            fn = @(x) 0.5 * x.' * A * x + 1e-9 * sin(1e9 * sum(x));
            ev = testCase.evaluatorFrom(struct('objFun', fn, 'hasObjGrad', false));
            x = [0.3; -0.2];
            ev.calibrateStep(x);
            H = adamnlopt.lagrangianHessian(ev, x, zeros(0, 1), zeros(0, 1), ...
                adamnlopt.defaultOptions());
            testCase.verifyLessThan(norm(H - A) / norm(A), 1e-4);
        end

        function testD8FdHessianCostIsWarned(testCase)
            fn = @(x) sum((x - 1).^2);
            testCase.verifyWarning(@() adamnlopt.solve(fn, [0; 0], [], [], [], [], [], [], [], ...
                testCase.quietOpts(struct('hessianApprox', 'exact'))), 'adamnlopt:fdHessianCost');
            testCase.verifyWarningFree(@() adamnlopt.solve(@(x) deal(fn(x), 2 * (x - 1)), ...
                [0; 0], [], [], [], [], [], [], [], testCase.quietOpts(struct( ...
                'hessianApprox', 'exact', 'SpecifyObjectiveGradient', true))));
        end

        function testA1ForwardDifferencesArePromotedAtTheirAccuracyFloor(testCase)
            % Rosenbrock n = 10, FD gradients: forward differences stopped at
            % exitflag 2 (opt 4e-5, f 2e-10).  Promoted once to central, the
            % solve converges to optTol.
            nr = 10;
            fros = @(x) sum(100 * (x(2:end) - x(1:end-1).^2).^2 + (1 - x(1:end-1)).^2);
            [x, ~, ef, out] = adamnlopt.solve(fros, -2 * ones(nr, 1), [], [], [], [], ...
                [], [], [], testCase.quietOpts(struct('traceLevel', 1)));
            testCase.verifyEqual(ef, 1, out.message);
            testCase.verifyEqual(x, ones(nr, 1), 'AbsTol', 1e-6);
            testCase.verifyEqual(nnz(out.trace.fdPromoted == 1), 1);
        end

        function testA1PinnedCentralIsNotTouched(testCase)
            [~, ~, ~, out] = adamnlopt.solve(@(x) sum((x - 1).^4), zeros(3, 1), [], [], [], [], ...
                [], [], [], testCase.quietOpts(struct('FiniteDifferenceType', 'central', 'traceLevel', 1)));
            testCase.verifyEqual(nnz(out.trace.fdPromoted == 1), 0);
        end

        function testA7StepCollapseRecalibratesANoiseLimitedGradient(testCase)
            % Clean at x0 (calibration keeps sqrt(eps)), 1e-5 noise where the
            % optimum is.  The equality core stopped at iteration 4, exitflag 0
            % ("stalled short of a stationary point"), on a gradient that was
            % pure noise (opt 45).
            [x, ~, ef, out] = adamnlopt.solve(@movingNoise, [0; 0], [], [], [], [], ...
                [], [], [], testCase.quietOpts(struct('traceLevel', 1)));
            testCase.verifyEqual(ef, 2, out.message);
            testCase.verifyGreaterThan(nnz(out.trace.fdRecalibrated == 1), 0);
            testCase.verifyEqual(x, [3; 3], 'AbsTol', 1e-3);
        end

        function testA1NoiseFloorPlateauStopsAtFdAccuracy(testCase)
            % Same objective in a box (IP core): after the re-calibration the
            % solve sat at its noise floor (opt ~1e-3) until maxIter, 300
            % iterations and ~11000 evaluations.
            [x, ~, ef, out] = adamnlopt.solve(@movingNoise, [0; 0], [], [], [], [], ...
                -10 * ones(2, 1), 10 * ones(2, 1), [], testCase.quietOpts(struct()));
            testCase.verifyEqual(ef, 2, out.message);
            testCase.verifyLessThan(out.iterations, 100);
            testCase.verifyEqual(x, [3; 3], 'AbsTol', 1e-2);
            testCase.verifyNotEmpty(regexp(out.message, 'finite-difference accuracy', 'once'));
        end

        function testD21FdProbeIntoAFailureRegionRetriesTheOtherSide(testCase)
            % At x1 = 0.9 - 1e-10 the forward probe fails.  The Jacobian
            % column was Inf/NaN (and a wrong-sized return crashed it with
            % "incompatible sizes"); it must come from the backward probe.
            ev = testCase.evaluatorFrom(struct('nlcon', @failsBeyond09, ...
                'mInl', 2, 'mEnl', 1));
            x = [0.9 - 1e-10; 0.2];
            [JE, JI] = ev.jacobian(x);
            testCase.verifyEqual(JI, [2 * x.'; -1 0], 'AbsTol', 1e-6);
            testCase.verifyEqual(JE, [1 -1], 'AbsTol', 1e-6);
        end

        %% ==== Batch 9.5: derivative checker (A8) ============================
        function testA8CorrectGradientsAreSilent(testCase)
            % Correct analytic derivatives must not warn, and the advisory
            % check must not disturb the solve.
            o = testCase.quietOpts(struct('CheckGradients', true, ...
                'SpecifyObjectiveGradient', true, 'SpecifyConstraintGradient', true));
            testCase.verifyWarningFree(@() adamnlopt.solve(@quadObj, [0.5; 0.5], ...
                [], [], [], [], [], [], @circleCon, o));
        end

        function testA8WrongObjectiveGradientWarns(testCase)
            % A sign-flipped objective gradient differs from central
            % differences by 200% relative; the checker must say so.
            o = testCase.quietOpts(struct('CheckGradients', true, 'maxIter', 5, ...
                'SpecifyObjectiveGradient', true));
            testCase.verifyWarning(@() adamnlopt.solve(@quadObjFlipped, [0.5; 0.5], ...
                [], [], [], [], [], [], [], o), 'adamnlopt:checkGradients');
        end

        function testA8WrongConstraintJacobianWarns(testCase)
            o = testCase.quietOpts(struct('CheckGradients', true, 'maxIter', 5, ...
                'SpecifyConstraintGradient', true));
            testCase.verifyWarning(@() adamnlopt.solve(@(x) sum((x - 1).^2), ...
                [0.5; 0.5], [], [], [], [], [], [], @circleConFlipped, o), ...
                'adamnlopt:checkGradients');
        end

        function testA8LvdCheckGradientsReachesTheSolver(testCase)
            o = AdamNlOptOptions();
            testCase.verifyFalse(o.checkGradients);
            testCase.verifyFalse(o.getOptionsForOptimizer([]).CheckGradients);
            o.checkGradients = true;
            testCase.verifyTrue(o.getOptionsForOptimizer([]).CheckGradients);
        end

        %% ==== Batch 10.1: safe hygiene (D31) ================================
        function testD31DeadOptionIsGone(testCase)
            % lsRefreshFeasTol was defined, exposed in LVD options/GUI, and
            % never read (the dominance gate replaced it).  All four surfaces
            % go together; mapOptions warns on unknown names, so a leftover
            % writer would fail loudly rather than silently.
            testCase.verifyFalse(isfield(adamnlopt.defaultOptions(), 'lsRefreshFeasTol'));
            testCase.verifyFalse(isfield(AdamNlOptOptions().getOptionsForOptimizer([]), ...
                'lsRefreshFeasTol'));
        end

        function testD31NaNBoundsAreRejected(testCase)
            o = testCase.quietOpts(struct());
            testCase.verifyError(@() adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [], [], [], [], [NaN; -1], [1; 1], [], o), 'adamnlopt:bounds');
            testCase.verifyError(@() adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [], [], [], [], [-1; -1], [1; NaN], [], o), 'adamnlopt:bounds');
        end

        function testD31NonFiniteLinearDataIsRejected(testCase)
            o = testCase.quietOpts(struct());
            testCase.verifyError(@() adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [1 1], NaN, [], [], [], [], [], o), 'adamnlopt:linear');
            testCase.verifyError(@() adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [1 NaN], 1, [], [], [], [], [], o), 'adamnlopt:linear');
        end

        function testD31SelectorTyposAreErrors(testCase)
            testCase.verifyError(@() adamnlopt.mapOptions(struct('globalization', 'fliter')), ...
                'adamnlopt:selector');
            testCase.verifyError(@() adamnlopt.mapOptions(struct('autoScale', 'grads')), ...
                'adamnlopt:selector');
            testCase.verifyError(@() adamnlopt.mapOptions(struct('FiniteDifferenceType', 'backwards')), ...
                'adamnlopt:selector');
            testCase.verifyError(@() adamnlopt.mapOptions(struct('Display', 'verbose')), ...
                'adamnlopt:selector');
        end

        function testD31FminconDisplayAliasesMap(testCase)
            testCase.verifyEqual(adamnlopt.mapOptions(struct('Display', 'iter-detailed')).Display, 'iter');
            testCase.verifyEqual(adamnlopt.mapOptions(struct('Display', 'final-detailed')).Display, 'final');
            testCase.verifyEqual(adamnlopt.mapOptions(struct('Display', 'notify')).Display, 'final');
            testCase.verifyEqual(adamnlopt.mapOptions(struct('Display', 'none')).Display, 'off');
        end

        function testD31TraceCarriesItsScaledFlag(testCase)
            [~, ~, ~, out] = adamnlopt.solve(@(x) sum((x - 1).^2), [0; 0], ...
                [], [], [], [], [], [], [], testCase.quietOpts(struct()));
            testCase.verifyEqual(out.scaling.traceIsScaled, out.scaling.applied);
            [~, ~, ~, outNone] = adamnlopt.solve(@(x) sum((x - 1).^2), [0; 0], ...
                [], [], [], [], [], [], [], testCase.quietOpts(struct('autoScale', 'none')));
            testCase.verifyFalse(outNone.scaling.traceIsScaled);
        end

        %% ==== Batch 10.2: behavioral hygiene (D31) ==========================
        function testD31SmallMultipliersCanBeConfident(testCase)
            % An active constraint with lamI = 1e-3 at mu = 0.1 is centred
            % (s*lamI ~ mu with s = 1e-7); the absolute max(1,||lam||) scale
            % capped its confidence at 1e-2, so no small-multiplier problem
            % could ever read as confident.
            state = struct('cI', 0, 'lamI', 1e-3, 's', 1e-7, 'mu', 0.1);
            [conf, info] = adamnlopt.control_activeSetConfidence(state, ...
                struct('feasTol', 1e-6));
            testCase.verifyEqual(info.nActive, 1);
            testCase.verifyGreaterThan(conf, 0.05);
        end

        function testD31WeakActivityUsesTheBarrierScale(testCase)
            % lamI = 5e-7 on an active row: vanishing against mu = 0.1 (a
            % genuine strict-complementarity failure is 1e-6*mu), but above
            % the old absolute 1e-6 threshold, which cried weak either way.
            mkState = @(mu) struct('x', zeros(2,1), 'JE', zeros(0,2), ...
                'JI', [1 0], 'cI', 0, 'lamI', 5e-7, 'mu', mu);
            opts = struct('feasTol', 1e-6);
            testCase.verifyFalse(adamnlopt.degeneracy_detectDegeneracy( ...
                mkState(0.1), opts).weaklyActive, ...
                '5e-7 is not vanishing against mu = 0.1');
            noMu = rmfield(mkState(0.1), 'mu');
            testCase.verifyTrue(adamnlopt.degeneracy_detectDegeneracy( ...
                noMu, opts).weaklyActive, ...
                'without mu the old absolute scale still applies');
        end

        function testD31DegeneracyDetectionSeesInequalityRows(testCase)
            % Two parallel active inequalities: the IP core used to pass only
            % (H, JE, x, lamE), so cI/JI/lamI defaulted empty and only linDepE
            % could ever route.  With the full fields the active set is seen.
            full_ = struct('x', zeros(2,1), 'JE', zeros(0,2), ...
                'JI', [1 0; 2 0], 'cE', zeros(0,1), 'cI', [0; 0], ...
                'lamE', zeros(0,1), 'lamI', [1; 1], 'mu', 0.1);
            minimal = struct('x', zeros(2,1), 'JE', zeros(0,2), ...
                'lamE', zeros(0,1));
            opts = struct('feasTol', 1e-6);
            testCase.verifyTrue(adamnlopt.degeneracy_detectDegeneracy( ...
                full_, opts).linDepActive);
            testCase.verifyFalse(adamnlopt.degeneracy_detectDegeneracy( ...
                minimal, opts).linDepActive);
        end

        function testD31LargeConsistentSystemAvoidsElasticMode(testCase)            % 1e4-scaled, ill-conditioned but consistent equalities: the
            % elastic penalty test is absolute (<= 1e-8*n), so the stalled
            % elastic solve below reads INCONSISTENT and every step detours
            % through elastic mode.  The min-norm residual is scale-relative
            % and sees consistency.
            [~, einfo] = adamnlopt.degeneracy_elasticVariables( ...
                [1e4; 1e4 + 1], [1e4 0; 1e4 1], zeros(0,1), zeros(0,2));
            testCase.verifyFalse(einfo.feasible, ...
                'the absolute penalty test fails at this scale');
            [x, ~, ef, out] = adamnlopt.solve(@bigConsistentObj, [0; 0], ...
                [], [], [], [], [], [], @bigConsistentCon, testCase.quietOpts( ...
                struct('enableDegeneracyDetection', true, ...
                       'SpecifyObjectiveGradient', true, ...
                       'SpecifyConstraintGradient', true)));
            testCase.verifyGreaterThan(ef, 0, out.message);
            testCase.verifyEqual(x, [1; 2], 'AbsTol', 1e-4);
            testCase.verifyEqual(nnz(out.trace.stepSource == 2), 0, ...
                'no step may route through elastic mode on a consistent system');
        end

        function testD31FixedVariableGradientIsFiniteDifferenceFilled(testCase)            % x2 fixed at 0, FD objective: grad(2) used to be NaN with both
            % bound multipliers 0.  One off-fix probe fills it (2*(0-3) = -6)
            % and the upper multiplier absorbs the row, matching fmincon.
            [x, ~, ef, output, lambda, grad] = adamnlopt.solve( ...
                @(x) (x(1) - 1)^2 + (x(2) - 3)^2 + (x(3) - 2)^2 + (x(4) + 1)^2, ...
                zeros(4, 1), [], [], [], [], [-5; 0; -5; -5], [5; 0; 5; 5], ...
                [], testCase.quietOpts(struct()));
            testCase.verifyGreaterThan(ef, 0, output.message);
            testCase.verifyEqual(x, [1; 0; 2; -1], 'AbsTol', 1e-6);
            testCase.verifyEqual(grad(2), -6, 'AbsTol', 1e-4);
            testCase.verifyEqual(lambda.upper(2), 6, 'AbsTol', 1e-4);
            testCase.verifyEqual(lambda.lower(2), 0, 'AbsTol', 0);
            testCase.verifyTrue(output.fixedVars.gradKnown);
        end

        function testD31MaxTimeStopsMidIteration(testCase)
            % Wide bowl (n = 40) with 0.1 s evaluations: one FD gradient sweep
            % alone costs ~4 s, so maxTime = 8 s fires MID-iteration (a probe
            % past the deadline throws) rather than at the next iteration top.
            % Top-of-iteration testing alone overran maxTime by a full long
            % iteration (TwoStageToOrbit: 1308 s of 900 allowed).  The exit is
            % 0 at the last accepted iterate, well before one more iteration
            % could finish.
            t0 = tic;
            [x, fval, ef, out] = adamnlopt.solve(@slowWide, zeros(40, 1), ...
                [], [], [], [], [], [], [], testCase.quietOpts( ...
                struct('maxTime', 8)));
            testCase.verifyEqual(ef, 0);
            testCase.verifyNotEmpty(regexp(out.message, 'maximum time', 'once'));
            testCase.verifyEqual(fval, slowWide(x), 'AbsTol', 1e-12);
            testCase.verifyLessThan(toc(t0), 12, ...
                'the stop must come from mid-iteration, not after another full one');
        end

        function testD31MaxTimeStopsTheInteriorPointCore(testCase)
            % Same deadline through the IP core (bounds present): the other
            % catch block restores s/lamI/z from the loop-top state.
            [x, fval, ef, out] = adamnlopt.solve(@slowWide, zeros(40, 1), ...
                [], [], [], [], -5 * ones(40, 1), 5 * ones(40, 1), [], ...
                testCase.quietOpts(struct('maxTime', 8)));
            testCase.verifyEqual(ef, 0);
            testCase.verifyNotEmpty(regexp(out.message, 'maximum time', 'once'));
            testCase.verifyEqual(fval, slowWide(x), 'AbsTol', 1e-12);
        end

        function testD31CorrectJacobPatternIsSilent(testCase)
            ev = testCase.evaluatorFrom(struct('nlcon', @separableCon, 'mInl', 2), ...
                struct('JacobPattern', eye(2)));
            testCase.verifyWarningFree(@() ev.jacobian([0.5; -0.5]));
        end

        function testD31WrongJacobPatternWarns(testCase)
            % Column 2 of c2 really depends on x2; a pattern claiming
            % otherwise silently zeroes a -1 Jacobian entry.
            ev = testCase.evaluatorFrom(struct('nlcon', @separableCon, 'mInl', 2), ...
                struct('JacobPattern', [1 0; 0 0]));
            testCase.verifyWarning(@() ev.jacobian([0.5; -0.5]), ...
                'adamnlopt:jacobPattern');
        end

        function testD31JacobPatternCheckOptsOut(testCase)
            ev = testCase.evaluatorFrom(struct('nlcon', @separableCon, 'mInl', 2), ...
                struct('JacobPattern', [1 0; 0 0], 'CheckJacobPattern', false));
            testCase.verifyWarningFree(@() ev.jacobian([0.5; -0.5]));
        end

        %% ==== Batch 10.4: NT trust-region path (D19/D28) ====================
        function testD19NTDecompSolvesAnEqualityProblem(testCase)
            % min x'x s.t. x1+x2 = 10 through the opt-in NT path, exercising
            % the shrink-on-reject, penalty-update and 0.8-radius changes.
            [x, ~, ef, out] = adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [], [], [1 1], 10, [], [], [], testCase.quietOpts( ...
                struct('useNTdecomp', true)));
            testCase.verifyGreaterThan(ef, 0, out.message);
            testCase.verifyEqual(x, [5; 5], 'AbsTol', 1e-6);
        end

        function testD19NTDecompSolvesWithMeritAndBounds(testCase)
            % Same through the IP core (bounds present) under merit
            % globalization, where rho comes from control_penaltyUpdate.
            [x, ~, ef, out] = adamnlopt.solve(@(x) sum(x.^2), [0; 0], ...
                [], [], [1 1], 10, -20 * ones(2, 1), 20 * ones(2, 1), [], ...
                testCase.quietOpts(struct('useNTdecomp', true, ...
                'globalization', 'merit')));
            testCase.verifyGreaterThan(ef, 0, out.message);
            testCase.verifyEqual(x, [5; 5], 'AbsTol', 1e-6);
        end

        function testD19NTFallbackSolvesThroughTheFilter(testCase)
            % trMaxInner = 1 forces nearly every iteration into the
            % ~stepAccepted fallback, which must come from the filter line
            % search (D19), not the merit rule that used to take
            % filter-rejected steps without augmenting.
            [x, ~, ef, out] = adamnlopt.solve(@(x) (x(1) - 2)^2 + (x(2) - 1)^2, ...
                [0.3; 0.2], [], [], [], [], [], [], ...
                @(x) deal([], x(1)^2 + x(2)^2 - 1), testCase.quietOpts( ...
                struct('useNTdecomp', true, 'trMaxInner', 1)));
            testCase.verifyGreaterThan(ef, 0, out.message);
            testCase.verifyEqual(x, [2; 1] / sqrt(5), 'AbsTol', 1e-4);
        end

        %% ==== Batch 10.5: warm start (A3) and shared handles (D32) =========
        function testA3WarmStartResolvesInTwoIterations(testCase)
            % Re-solving HS71 from its solution with its multipliers must not
            % rebuild the costates and the barrier (~10 iterations normally).
            p = testCase.catalogEntry('hs71');
            out1 = testCase.solveProblem(p, struct());
            testCase.assumeGreaterThan(out1.exitflag, 0, 'cold solve failed');
            p2 = p;
            p2.x0 = out1.x;
            o2 = struct('SpecifyObjectiveGradient', true, ...
                'SpecifyConstraintGradient', true, 'lambda0', out1.lambda);
            out2 = testCase.solveProblem(p2, o2);
            testCase.verifyGreaterThan(out2.exitflag, 0, out2.output.message);
            testCase.verifyLessThanOrEqual(out2.output.iterations, 2);
            testCase.verifyEqual(out2.x, p.xStar, 'AbsTol', p.xTol);
        end

        function testA3MismatchedWarmStartFallsBackSilently(testCase)
            % A stale lambda (wrong sizes after an edit) is not an error: the
            % solve falls back to the cold start and converges anyway.
            p = testCase.catalogEntry('hs71');
            bad = struct('eqlin', 0, 'eqnonlin', zeros(7, 1), ...
                'ineqlin', zeros(0, 1), 'ineqnonlin', 0, ...
                'lower', zeros(2, 1), 'upper', zeros(2, 1));
            out = testCase.solveProblem(p, struct('lambda0', bad));
            testCase.verifyGreaterThan(out.exitflag, 0, out.output.message);
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', p.xTol);
        end

        function testD32ClonedOptimizerIsIndependent(testCase)
            % cloneFrom gives an independent optimizer with equal settings.
            a = AdamNlOptOptimizer();
            b = AdamNlOptOptimizer.cloneFrom(a);
            testCase.verifyTrue(b ~= a, ...
                'clone must be a distinct handle');
            testCase.verifyEqual(b.getOptions().maxIter, ...
                a.getOptions().maxIter);
            b.getOptions().maxIter = 11;
            testCase.verifyEqual(a.getOptions().maxIter, 300);
        end

        function testD32LoadedCasesDoNotShareTheOptimizer(testCase)
            % .mat files saved before AdamNlOpt existed store no adamNlOptOpt,
            % so every such case loaded in one session shared the
            % class-default handle: an option set for one case leaked into all
            % the others.  loadobj must clone on load.
            ex1 = dir(fullfile(ksptotTestRoot(), 'examples', ...
                'LaunchVehicleDesigner', '**', 'lvdExample_MunarLanding.mat'));
            ex2 = dir(fullfile(ksptotTestRoot(), 'examples', ...
                'LaunchVehicleDesigner', '**', 'lvdExample_TwoStageToOrbit.mat'));
            testCase.assumeNotEmpty(ex1, 'example mission not in checkout');
            testCase.assumeNotEmpty(ex2, 'example mission not in checkout');
            s1 = load(fullfile(ex1(1).folder, ex1(1).name), 'lvdData');
            s2 = load(fullfile(ex2(1).folder, ex2(1).name), 'lvdData');
            o1 = s1.lvdData.optimizer.adamNlOptOpt;
            o2 = s2.lvdData.optimizer.adamNlOptOpt;
            testCase.verifyTrue(o1 ~= o2, ...
                'two loaded cases must not share one optimizer handle');
            o1.getOptions().maxIter = 11;
            testCase.verifyEqual(o2.getOptions().maxIter, 300);
        end

        %% ==== Batch 10.3: Broyden refresh test (D25) ========================
        function testD25RefreshVerdictIsScaleInvariant(testCase)
            % Same (s, y, J) at 1e6 and 1e-6 scale: the old test divided by
            % max(1, ||cNew||), so near feasibility it went absolute on a
            % vanishing residual (a 100%-wrong model passed), while on O(1e6)
            % constraints it admitted 1e5 absolute errors.  Both scales must
            % give the same accept/refresh verdict.
            s = [1; 0];
            for k = [1e6, 1e-6]
                bad = adamnlopt.eval_BroydenJacobian(k * eye(2), 20, 0.1);
                testCase.verifyFalse(bad.update(s, k * [1.5; 0]), sprintf( ...
                    'scale %g: a 50%% residual must force a refresh', k));
                testCase.verifyTrue(bad.needsRefresh());
                good = adamnlopt.eval_BroydenJacobian(k * eye(2), 20, 0.1);
                testCase.verifyTrue(good.update(s, k * [1.05; 0]), sprintf( ...
                    'scale %g: a 5%% residual must update', k));
            end
        end
    end

    methods (Access = private)
        function tr = noisyBoundedTrace(testCase)
            fun = @(x) sum((x - 0.3).^2) + 1e-4 * sin(1e8 * sum(x));
            o = testCase.quietOpts(struct('autoFDStep', false, 'maxIter', 60));
            [~, ~, ~, out] = adamnlopt.solve(fun, ones(5, 1), [], [], [], [], ...
                zeros(5, 1), 2 * ones(5, 1), [], o);
            tr = out.trace;
        end

        function ev = evaluatorFrom(~, problem, optOverrides)
            %EVALUATORFROM  Evaluator over a 2-variable sphere plus PROBLEM's fields.
            p = struct('objFun', @AdamNlOptTestCase.sphere, ...
                'hasObjGrad', true, 'nlcon', [], 'hasConGrad', false, ...
                'Aineq', zeros(0, 2), 'bineq', zeros(0, 1), ...
                'Aeqlin', zeros(0, 2), 'beqlin', zeros(0, 1), ...
                'n', 2, 'mInl', 0, 'mEnl', 0);
            f = fieldnames(problem);
            for i = 1:numel(f), p.(f{i}) = problem.(f{i}); end
            opts = adamnlopt.defaultOptions();
            if nargin > 2
                g = fieldnames(optOverrides);
                for i = 1:numel(g), opts.(g{i}) = optOverrides.(g{i}); end
            end
            ev = adamnlopt.Evaluator(p, opts);
        end
    end
end

function [c, ceq] = separableCon(x)
% Two decoupled inequalities (Jacobian diag([2x1, 2x2])), for the
% CheckJacobPattern tests.
c = [x(1)^2 - 1; x(2)^2 - 1];
ceq = [];
end

function [c, ceq] = failsBeyond09(x)% Disk, sign and a linear equality; a "failed simulation" beyond x1 = 0.9.
if x(1) > 0.9, c = NaN;  ceq = NaN;  return; end
c = [x(1)^2 + x(2)^2 - 1; -x(1)];
ceq = x(1) - x(2) - 0.1;
end

function f = movingNoise(x)
% Quadratic, clean near x0 = 0, with 1e-5 "simulation noise" beyond x1 = 1.
f = sum((x - 3).^2) + (1e-12 + 1e-5 * (x(1) > 1)) * sin(1e9 * sum(x));
end

function f = slowBowl(x)
% Bowl with a 50 ms evaluation cost, for the maxTime deadline test.
pause(0.05);
f = sum((x - 1).^2);
end

function f = slowWide(x)
% Wide bowl with a 100 ms evaluation cost: one FD sweep outlasts the test's
% maxTime, so only a mid-iteration deadline can stop it in time.
pause(0.1);
f = sum((x - 1).^2);
end

function [f, g] = quadObj(x)
% Bowl with an analytic gradient, for the A8 checker tests.
f = (x(1) - 1)^2 + (x(2) - 2)^2;
g = [2 * (x(1) - 1); 2 * (x(2) - 2)];
end

function [f, g] = quadObjFlipped(x)
% Same bowl with a sign-flipped (wrong) gradient.
[f, g] = quadObj(x);
g = -g;
end

function [c, ceq, gc, gceq] = circleCon(x)
% Unit disk plus a linear equality, with analytic gradients (fmincon
% convention: one COLUMN per constraint).
c = x(1)^2 + x(2)^2 - 1;
ceq = x(1) - x(2) - 0.1;
gc = [2 * x(1); 2 * x(2)];
gceq = [1; -1];
end

function [c, ceq, gc, gceq] = circleConFlipped(x)
% Same constraints with a sign-flipped inequality gradient.
[c, ceq, ~, gceq] = circleCon(x);
gc = -[2 * x(1); 2 * x(2)];
end

function [f, g] = bigConsistentObj(x)
% Bowl centred on the consistent point of bigConsistentCon.
f = (x(1) - 1)^2 + (x(2) - 2)^2;
g = [2 * (x(1) - 1); 2 * (x(2) - 2)];
end

function [c, ceq, gc, gceq] = bigConsistentCon(x)
% 1e4-scaled, ill-conditioned but consistent equalities (solution [1; 2]).
c = [];
ceq = [1e4 * (x(1) - 1); 1e4 * (x(1) - 1) + (x(2) - 2)];
gc = zeros(2, 0);
gceq = [1e4 1e4; 0 1];
end
