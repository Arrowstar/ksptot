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
        function testD11LoadobjMigratesTheOldForcingAndBroydenDefaults(testCase)
            o = AdamNlOptOptions();
            o.forcingEtaMax = 0.9;  o.forcingEtaMin = 1e-8;  o.costThreshold = 0.1;
            o = AdamNlOptOptions.loadobj(o);
            testCase.verifyEqual(o.forcingEtaMax, 1e-6);
            testCase.verifyEqual(o.forcingEtaMin, 1e-10);
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
            % Both cores converged to the MAXIMUM (f = +sqrt(2)).
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
