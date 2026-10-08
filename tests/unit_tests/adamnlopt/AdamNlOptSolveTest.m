classdef AdamNlOptSolveTest < AdamNlOptTestCase
%ADAMNLOPTSOLVETEST  End-to-end contract tests for adamnlopt.solve.
%   The public entry point, exercised as a black box: the benchmark battery
%   (every catalog problem solved to its ANALYTIC optimum and checked against
%   the KKT conditions built from the multipliers it returns), every reachable
%   exit flag with the condition that produces it, the output/lambda contract,
%   the PlotFcn/IterationFcn convention, fmincon-compatible argument handling,
%   and an A/B matrix that drives the option paths which are off by default.
%
%   No Optimization Toolbox anywhere.  Optima are closed-form, derivatives come
%   from DERIVESTsuite, and the KKT check is independent of the solver.
%
%   See also ADAMNLOPTTESTCASE, ADAMNLOPT.SOLVE, ADAMNLOPTTEST.

    properties (TestParameter)
        % One parameterization per catalog entry: 17 problems, one test method.
        prob = AdamNlOptTestCase.catalog();

        % --- A/B matrix arms (defaults noted in the test methods) -------
        hessianApprox = {'exact', 'fd', 'lbfgs', 'bfgs'};
        autoScale     = {'gradient', 'curvature', 'bounds', 'none'};
        globalization = {'filter', 'merit'};
        returnIterate = {'last', 'bestKKT'};
        fdType        = {'forward', 'central'};
        traceLevel    = {0, 1, 2};

        % Flipped off; every one of these is ON by default.
        defaultOnFlag = {'useSOC', 'enableRestoration', 'modeSwitch', ...
                         'lsMultiplierRefresh', 'excludeActiveBoundRows', ...
                         'bfgsB0Refresh', 'HonorBounds', 'autoFDStep'};

        % Flipped on; every one of these is OFF by default.
        defaultOffFlag = {'useNTdecomp', 'enableBroyden', ...
                          'enableDegeneracyDetection', 'modeNearBdryAugJE'};

        % Finding 56: how slack the inactive linear row is decided whether the
        % hang appeared at all, so the guard sweeps the range rather than
        % picking the one value that happened to reproduce it.
        slackRowBound = struct('b3', 3, 'b7', 7, 'b10', 10, 'b20', 20, ...
                               'b100', 100, 'b1000', 1000);
    end

    methods (Test)

        %% ================================================================
        %  Benchmark battery
        %  ================================================================

        function testSolvesCatalogProblem(testCase, prob)
            %TESTSOLVESCATALOGPROBLEM  The whole battery, one problem per run.
            %   verifySolvesTo asserts a converged exit, the analytic x* and f*,
            %   the reported constraint violation, and then the full KKT system
            %   at the returned point using the returned multipliers.
            testCase.verifySolvesTo(prob);
        end

        function testBatteryReportsConsistentOptimality(testCase, prob)
            %   output.firstOrderOpt must actually agree with the stationarity
            %   residual the suite computes independently -- a solver that
            %   under-reports its own optimality would otherwise sail through
            %   every tolerance check in the battery.
            out = testCase.solveProblem(prob);
            testCase.verifyLessThanOrEqual(out.output.firstOrderOpt, ...
                prob.kktTol, sprintf('%s: reported firstOrderOpt too large', prob.name));
            testCase.verifyGreaterThanOrEqual(out.output.firstOrderOpt, 0);
            testCase.verifyTrue(isfinite(out.output.firstOrderOpt));
        end

        function testGradientOutputMatchesDerivest(testCase, prob)
            %   The 6th output is the objective gradient at the solution, and
            %   DERIVESTsuite is the independent oracle for it.
            out = testCase.solveProblem(prob);
            gRef = AdamNlOptTestCase.quietGradest( ...
                @(z) feval(prob.fun, z(:)), out.x.');

            testCase.verifySize(out.grad, [numel(out.x), 1]);
            testCase.verifyEqual(out.grad, gRef, 'AbsTol', 1e-4, 'RelTol', 1e-3, ...
                sprintf('%s: returned grad disagrees with DERIVESTsuite', prob.name));
        end

        function testHessianOutputIsSymmetric(testCase, prob)
            out = testCase.solveProblem(prob);
            n = numel(out.x);
            testCase.verifySize(out.hessian, [n, n]);
            testCase.verifyLessThan(norm(out.hessian - out.hessian.', inf), ...
                1e-8 * max(1, norm(out.hessian, inf)), ...
                sprintf('%s: returned Hessian is not symmetric', prob.name));
        end

        %% ================================================================
        %  Exit flags -- every reachable value
        %  ================================================================

        function testExitflagOneOnOrdinaryConvergence(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('sphere2'));
            testCase.verifyEqual(out.exitflag, 1);
            testCase.verifySubstring(out.output.message, 'Converged');
        end

        function testExitflagOneWhenAllVariablesAreFixedAndFeasible(testCase)
            % lb == ub on every variable: the reduction removes the whole
            % problem and the answer is the fixed point itself.
            [x, fval, exitflag] = adamnlopt.solve(@AdamNlOptTestCase.sphere, ...
                [0; 0], [], [], [], [], [1; 2], [1; 2], [], ...
                testCase.quietOpts());

            testCase.verifyEqual(exitflag, 1);
            testCase.verifyEqual(x, [1; 2], 'AbsTol', 1e-12);
            testCase.verifyEqual(fval, 5, 'AbsTol', 1e-12);
        end

        function testExitflagZeroOnMaxIterations(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('rosenbrock'), ...
                struct('maxIter', 2));
            testCase.verifyEqual(out.exitflag, 0);
            testCase.verifySubstring(out.output.message, 'maximum iterations');
            testCase.verifyLessThanOrEqual(out.output.iterations, 2);
        end

        function testExitflagZeroOnMaxFunEvals(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('rosenbrock'), ...
                struct('maxFunEvals', 3));
            testCase.verifyEqual(out.exitflag, 0);
            testCase.verifySubstring(out.output.message, 'function evaluations');
        end

        function testExitflagZeroOnMaxTime(testCase)
            % maxTime = 0 trips on the very first check: deterministic, with no
            % pause and no dependence on how fast the machine is.
            out = testCase.solveProblem(testCase.catalogEntry('rosenbrock'), ...
                struct('maxTime', 0));
            testCase.verifyEqual(out.exitflag, 0);
            testCase.verifySubstring(out.output.message, 'maximum time');
        end

        function testExitflagMinusOneWhenIterationFcnStops(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('rosenbrock'), ...
                struct('IterationFcn', @(~) true));
            testCase.verifyEqual(out.exitflag, -1);
            testCase.verifySubstring(out.output.message, 'iteration function');
        end

        function testExitflagMinusTwoOnLocallyInfeasibleProblem(testCase)
            % ceq = x'x + 1 = 0 has no real solution anywhere.
            out = testCase.solveProblem(testCase.infeasibleProblem());
            testCase.verifyEqual(out.exitflag, -2);
        end

        function testExitflagMinusTwoWhenAllFixedAndInfeasible(testCase)
            % Every variable pinned, and the pinned point violates a NONLINEAR
            % equality.  (The all-linear form of this is an error, not a flag --
            % see testAllFixedInfeasibleLinearRowErrors.)
            [~, ~, exitflag] = adamnlopt.solve(@AdamNlOptTestCase.sphere, ...
                [1; 2], [], [], [], [], [1; 2], [1; 2], ...
                @AdamNlOptTestCase.impossibleEq, testCase.quietOpts());

            testCase.verifyEqual(exitflag, -2);
        end

        function testAllFixedInfeasibleLinearRowErrors(testCase)
            % reduceLinear can see that the row reduces to 0 == 4 and says so,
            % rather than handing the core an unsatisfiable problem.
            testCase.verifyError(@() adamnlopt.solve( ...
                @AdamNlOptTestCase.sphere, [0; 0], [], [], [1 0], 5, ...
                [1; 2], [1; 2], [], testCase.quietOpts()), ...
                'adamnlopt:fixedInfeasible');
        end

        function testExitflagMinusThreeOnNonFiniteObjective(testCase)
            % Finding 53: this used to report exitflag 1 with fval NaN.
            [~, fval, exitflag, output] = adamnlopt.solve(@(x) NaN, [1; 1], ...
                [], [], [], [], [], [], [], testCase.quietOpts());

            testCase.verifyEqual(exitflag, -3);
            testCase.verifyFalse(isfinite(fval));   % D21: a NaN objective reads +Inf
            testCase.verifyEmpty(regexp(output.message, 'Converged', 'once'));
        end

        function testUnboundedObjectiveIsNeverReportedAsConverged(testCase)
            % Finding 54: the step-size exit had no optimality gate and returned
            % the converged code 2 at opt = 2.85e+34.
            [~, ~, exitflag, output] = adamnlopt.solve(@(x) -1 / (x.' * x), ...
                [1; 1], [], [], [], [], [], [], [], testCase.quietOpts());

            testCase.verifyLessThanOrEqual(exitflag, 0);
            testCase.verifyEmpty(regexp(output.message, 'Converged', 'once'));
        end

        function testReturnIterateBestKKTDoesNotChangeTheFlag(testCase)
            % bestKKT rewrites WHICH iterate comes back, never the exit flag.
            p = testCase.catalogEntry('rosenbrock');
            last = testCase.solveProblem(p, struct('maxIter', 5));
            best = testCase.solveProblem(p, ...
                struct('maxIter', 5, 'returnIterate', 'bestKKT'));

            testCase.verifyEqual(best.exitflag, last.exitflag);
            testCase.verifyEqual(best.exitflag, 0);
            testCase.verifyLessThanOrEqual(best.output.firstOrderOpt, ...
                last.output.firstOrderOpt + 1e-12, ...
                'bestKKT returned a worse iterate than last');
        end

        function testReturnIterateBestKKTIsInertOnAConvergedSolve(testCase)
            % Documented: the rewrite applies only when ef == 0.
            p = testCase.catalogEntry('sphere2');
            last = testCase.solveProblem(p);
            best = testCase.solveProblem(p, struct('returnIterate', 'bestKKT'));

            testCase.verifyEqual(best.exitflag, 1);
            testCase.verifyEqual(best.x, last.x, 'AbsTol', 1e-12);
        end

        %% ================================================================
        %  Output and lambda contract
        %  ================================================================

        function testOutputHasEveryDocumentedField(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('hs71'));
            required = {'iterations', 'funcCount', 'objCount', 'conCount', ...
                        'firstOrderOpt', 'constrViolation', 'complementarity', ...
                        'exitflag', 'message'};
            for k = 1:numel(required)
                testCase.verifyTrue(isfield(out.output, required{k}), ...
                    sprintf('output.%s is missing', required{k}));
            end
            testCase.verifyEqual(out.output.exitflag, out.exitflag);
            testCase.verifyGreaterThan(out.output.funcCount, 0);
            testCase.verifyGreaterThan(out.output.conCount, 0);
        end

        function testOutputCountsAreConsistent(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('diskIneq'));
            testCase.verifyGreaterThanOrEqual(out.output.funcCount, ...
                out.output.objCount);
            testCase.verifyEqual(out.output.iterations, ...
                round(out.output.iterations));
            testCase.verifyGreaterThanOrEqual(out.output.iterations, 0);
        end

        function testTracePresentOnlyWhenTraceLevelIsPositive(testCase)
            p = testCase.catalogEntry('sphere2');
            on  = testCase.solveProblem(p, struct('traceLevel', 1));
            off = testCase.solveProblem(p, struct('traceLevel', 0));

            testCase.verifyTrue(isfield(on.output, 'trace'));
            testCase.verifyNotEmpty(on.output.trace);
            % At traceLevel 0 the field is ABSENT, not present-and-empty:
            % solve.m only assigns output.trace when the IterTrace handle exists.
            testCase.verifyFalse(isfield(off.output, 'trace'));
        end

        function testTraceLevelDoesNotChangeTheIterates(testCase)
            %   Tracing is pure observation.  defaultOptions documents this
            %   invariant and attributes it to a property test in
            %   "tests/tIterTrace" -- a file that does not exist anywhere in the
            %   repository.  The claim was never actually checked; it is now.
            p = testCase.catalogEntry('rosenbrock');
            a = testCase.solveProblem(p, struct('traceLevel', 0));
            b = testCase.solveProblem(p, struct('traceLevel', 1));
            c = testCase.solveProblem(p, struct('traceLevel', 2));

            testCase.verifyEqual(b.x, a.x, 'AbsTol', 0, ...
                'traceLevel 1 changed the iterates');
            testCase.verifyEqual(c.x, a.x, 'AbsTol', 0, ...
                'traceLevel 2 changed the iterates');
            testCase.verifyEqual([b.exitflag, c.exitflag], ...
                [a.exitflag, a.exitflag]);
            testCase.verifyEqual([b.output.iterations, c.output.iterations], ...
                [a.output.iterations, a.output.iterations]);
        end

        function testScalingRecordIsPopulated(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('hs71'));
            sc = out.output.scaling;
            for f = {'applied', 'mode', 'Dx', 'Dc', 'Di', 'wf', 'mElin', 'mIlin'}
                testCase.verifyTrue(isfield(sc, f{1}), ...
                    sprintf('output.scaling.%s is missing', f{1}));
            end
            testCase.verifyClass(sc.applied, 'logical');
            if sc.applied
                testCase.verifyGreaterThan(sc.Dx, 0);
                testCase.verifyGreaterThan(sc.wf, 0);
            end
        end

        function testScalingModeNoneReportsNotApplied(testCase)
            out = testCase.solveProblem(testCase.catalogEntry('sphere2'), ...
                struct('autoScale', 'none'));
            testCase.verifyFalse(out.output.scaling.applied);
            testCase.verifyEqual(out.output.scaling.mode, 'none');
        end

        function testFdCalibrationRecordAlwaysCarriesTheUserSetFlags(testCase)
            % Documented as present on every return path, including 'skipped'.
            out = testCase.solveProblem(testCase.catalogEntry('sphere2'));
            cal = out.output.fdCalibration;
            testCase.verifyTrue(isfield(cal, 'flag'));
            testCase.verifyTrue(isfield(cal, 'fdStepUserSet'));
            testCase.verifyTrue(isfield(cal, 'fdTypeUserSet'));
            testCase.verifyTrue(ismember(cal.flag, ...
                {'userSet', 'boundLimited', 'analytic', 'inconclusive', ...
                 'set', 'skipped'}), sprintf('unexpected flag "%s"', cal.flag));
        end

        function testLambdaHasAllSixFieldsWithTheRightLengths(testCase)
            p = testCase.catalogEntry('hs71');
            out = testCase.solveProblem(p);
            n = numel(out.x);
            lam = out.lambda;

            testCase.verifySize(lam.lower, [n, 1]);
            testCase.verifySize(lam.upper, [n, 1]);
            testCase.verifySize(lam.eqnonlin, [1, 1]);     % HS71 has one ceq
            testCase.verifySize(lam.ineqnonlin, [1, 1]);   % and one c
            testCase.verifyEmpty(lam.eqlin);
            testCase.verifyEmpty(lam.ineqlin);
        end

        function testLambdaSplitsLinearFromNonlinear(testCase)
            % One linear inequality and one nonlinear inequality at once: the
            % split happens at ev.mIlin, and getting it wrong silently swaps
            % two multipliers that are both plausible numbers.
            p = AdamNlOptTestCase.problem('mixedIneq', ...
                @AdamNlOptTestCase.distanceTo21, [0; 0]);
            p.A = [1 0];  p.b = 10;                       % inactive, lam = 0
            p.nonlcon = @AdamNlOptTestCase.unitDiskIneq;  % active, lam > 0
            p.hasConGrad = true;
            p.xStar = [2; 1] / sqrt(5);
            p.fStar = (sqrt(5) - 1)^2;

            out = testCase.verifySolvesTo(p);

            testCase.verifySize(out.lambda.ineqlin, [1, 1]);
            testCase.verifySize(out.lambda.ineqnonlin, [1, 1]);
            testCase.verifyLessThan(out.lambda.ineqlin, 1e-6, ...
                'inactive linear row should carry a zero multiplier');
            testCase.verifyGreaterThan(out.lambda.ineqnonlin, 1e-3, ...
                'active nonlinear row should carry a positive multiplier');
        end

        function testBoundMultipliersSitOnTheActiveSideOnly(testCase)
            % boundActive drives both variables onto their UPPER bound.
            out = testCase.verifySolvesTo(testCase.catalogEntry('boundActive'));

            testCase.verifyGreaterThan(out.lambda.upper, 1e-4, ...
                'active upper bound should carry a positive multiplier');
            testCase.verifyLessThan(out.lambda.lower, 1e-4, ...
                'inactive lower bound should carry a zero multiplier');
        end

        function testLambdaIsReindexedOntoTheOriginalVariables(testCase)
            % x2 is pinned by lb == ub, so the core never sees it; the returned
            % lambda must still be indexed over the ORIGINAL two variables.
            p = AdamNlOptTestCase.problem('pinned', ...
                @AdamNlOptTestCase.sphere, [3; 2]);
            p.lb = [-5; 2];  p.ub = [5; 2];
            p.xStar = [0; 2];  p.fStar = 4;

            out = testCase.solveProblem(p);

            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyEqual(out.x, [0; 2], 'AbsTol', 1e-5);
            testCase.verifySize(out.lambda.lower, [2, 1]);
            testCase.verifySize(out.lambda.upper, [2, 1]);
            testCase.verifySize(out.grad, [2, 1]);
            testCase.verifySize(out.hessian, [2, 2]);
            testCase.verifyTrue(isfield(out.output, 'fixedVars'));
        end

        %% ================================================================
        %  Hooks
        %  ================================================================

        function testIterationFcnSeesEveryIterationIncludingTheLast(testCase)
            calls = testCase.counter();
            lastIter = testCase.counter();
            fcn = @(info) hookRecord(calls, lastIter, info);

            out = testCase.solveProblem(testCase.catalogEntry('sphere2'), ...
                struct('IterationFcn', fcn));

            testCase.verifyGreaterThan(calls('n'), 0);
            testCase.verifyEqual(lastIter('n'), out.output.iterations, ...
                'the terminal iteration did not reach IterationFcn');
        end

        function testIterationInfoCarriesTheDocumentedFields(testCase)
            seen = testCase.counter();
            fcn = @(info) hookCapture(seen, info);

            testCase.solveProblem(testCase.catalogEntry('hs71'), ...
                struct('IterationFcn', fcn));

            info = seen('payload');
            testCase.verifyNotEmpty(info);
            for f = {'x', 'fval', 'grad', 'c', 'ceq', 'mu', 'alpha', ...
                     'constrviolation', 'firstorderopt', 'mode', ...
                     'state', 'res', 'step', 'lambda', 'advice', 'opts'}
                testCase.verifyTrue(isfield(info, f{1}), ...
                    sprintf('iteration info is missing "%s"', f{1}));
            end
            % Unscaled and indexed over the ORIGINAL variables.
            testCase.verifySize(info.x, [4, 1]);
        end

        function testPlotFcnIsCalled(testCase)
            calls = testCase.counter();
            fcn = @(info) hookCount(calls, info);

            testCase.solveProblem(testCase.catalogEntry('sphere2'), ...
                struct('PlotFcn', fcn));

            testCase.verifyGreaterThan(calls('n'), 0);
        end

        function testHookCellArrayRunsEveryHandleInOrder(testCase)
            order = testCase.counter();
            first  = @(info) hookStamp(order, 1, info);
            second = @(info) hookStamp(order, 2, info);

            testCase.solveProblem(testCase.catalogEntry('sphere2'), ...
                struct('PlotFcn', {{first, second}}));

            stamps = order('payload');
            testCase.verifyNotEmpty(stamps, 'neither cell-array hook ran');
            testCase.verifyEqual(stamps(1:2), [1 2], ...
                'cell-array hooks did not run in order');
        end

        function testThrowingHookWarnsOnceAndDoesNotAbortTheSolve(testCase)
            % safeHookCall: a broken hook is the user's problem, not a reason to
            % throw away a perfectly good solve.
            p = testCase.catalogEntry('sphere2');
            bad = @(~) error('test:boom', 'hook exploded');

            testCase.verifyWarning(@() testCase.solveProblem(p, ...
                struct('IterationFcn', bad)), 'adamnlopt:IterationFcnFailed');

            out = testCase.suppressWarnings(@() testCase.solveProblem(p, ...
                struct('IterationFcn', bad)));
            testCase.verifyEqual(out.exitflag, 1, ...
                'a throwing hook changed the outcome of the solve');
            testCase.verifyEqual(out.x, [0; 0], 'AbsTol', 1e-4);
        end

        %% ================================================================
        %  Argument handling (fmincon compatibility)
        %  ================================================================

        function testTrailingArgumentsMayBeOmitted(testCase)
            [x, ~, exitflag] = adamnlopt.solve(@AdamNlOptTestCase.sphere, ...
                [1.3; -2.7]);
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [0; 0], 'AbsTol', 1e-4);
        end

        function testEmptyPlaceholdersAreAccepted(testCase)
            [x, ~, exitflag] = adamnlopt.solve(@AdamNlOptTestCase.sphere, ...
                [1.3; -2.7], [], [], [], [], [], [], [], ...
                testCase.quietOpts());
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [0; 0], 'AbsTol', 1e-4);
        end

        function testRowVectorX0IsAccepted(testCase)
            % fmincon accepts either orientation.
            [x, ~, exitflag] = adamnlopt.solve(@AdamNlOptTestCase.sphere, ...
                [1.3, -2.7], [], [], [], [], [], [], [], ...
                testCase.quietOpts());
            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x(:), [0; 0], 'AbsTol', 1e-4);
        end

        function testEmptyOptionsUsesDefaults(testCase)
            % options = [] must behave exactly as defaultOptions, which means
            % Display = 'iter', so the command window is swallowed.
            [~, x, ~, exitflag] = evalc(['adamnlopt.solve(' ...
                '@AdamNlOptTestCase.sphere, [1; 1], [], [], [], [], ' ...
                '[], [], [], [])']);

            testCase.verifyGreaterThan(exitflag, 0);
            testCase.verifyEqual(x, [0; 0], 'AbsTol', 1e-4);
        end

        function testOptionsStructAndOptimoptionsObjectAgree(testCase)
            % mapOptions accepts either.  The SUITE never needs the Optimization
            % Toolbox, but this one compatibility test cannot construct an
            % optimoptions object without it, so it skips rather than fails.
            % license('test') can report the toolbox present while optimoptions
            % still cannot check out a seat, so probe the call itself.
            try
                optimoptions('fmincon');
            catch
                testCase.assumeFail('optimoptions unavailable (Optimization Toolbox not installed or no license seat); optimoptions input untested.');
            end
            p = testCase.catalogEntry('sphere2');
            viaStruct = testCase.solveProblem(p, struct('maxIter', 7));

            oo = optimoptions('fmincon', 'Display', 'off', ...
                              'MaxIterations', 7);
            [x, ~, exitflag, out] = adamnlopt.solve(p.fun, p.x0, [], [], [], [], ...
                [], [], [], oo);
            testCase.verifyLessThanOrEqual(out.iterations, 7, ...
                'MaxIterations was not read off the optimoptions object');

            %   Not bit-equality: an optimoptions object carries fmincon's OWN
            %   defaults for every mapped property it did not have set (a
            %   tighter StepTolerance, a smaller evaluation budget), so the two
            %   runs are legitimately different option sets and take different
            %   paths.  What must hold is that the object was READ at all and
            %   routed to the same answer -- both land on the optimum to well
            %   inside optTol, and both report the same exit.
            testCase.verifyEqual(exitflag, viaStruct.exitflag);
            testCase.verifyEqual(x, viaStruct.x, 'AbsTol', 1e-5);
            testCase.verifyEqual(x, [0; 0], 'AbsTol', 1e-5);
        end

        %% ================================================================
        %  Display and logging
        %  ================================================================

        function testEveryDisplayLevelRuns(testCase)
            p = testCase.catalogEntry('sphere2');
            for level = {'off', 'final', 'iter', 'iter-debug'}
                out = testCase.captureOutput(@() testCase.solveProblem(p, ...
                    struct('Display', level{1})));
                testCase.verifyEqual(out.exitflag, 1, ...
                    sprintf('Display = %s broke the solve', level{1}));
            end
        end

        function testLogFileIsWritten(testCase)
            logPath = [tempname, '.log'];
            cleanup = onCleanup(@() deleteIfPresent(logPath));

            testCase.captureOutput(@() testCase.solveProblem( ...
                testCase.catalogEntry('sphere2'), ...
                struct('Display', 'iter', 'LogFile', logPath)));

            testCase.verifyTrue(isfile(logPath), 'no log file was written');
            txt = fileread(logPath);
            testCase.verifyNotEmpty(strtrim(txt));
            clear cleanup;  %#ok<CLEAR>
        end

        %% ================================================================
        %  Option A/B matrix
        %  ================================================================
        %  Each arm solves the three representative problems -- one
        %  unconstrained, one linear-equality, one mixed nonlinear -- and all
        %  must reach the same optimum.  This is where the paths that are off by
        %  default actually get executed.

        function testHessianApproxArms(testCase, hessianApprox)
            testCase.verifyArmSolves(struct('hessianApprox', hessianApprox));
        end

        function testAutoScaleArms(testCase, autoScale)
            testCase.verifyArmSolves(struct('autoScale', autoScale));
        end

        function testGlobalizationArms(testCase, globalization)
            testCase.verifyArmSolves(struct('globalization', globalization));
        end

        function testReturnIterateArms(testCase, returnIterate)
            testCase.verifyArmSolves(struct('returnIterate', returnIterate));
        end

        function testFiniteDifferenceTypeArms(testCase, fdType)
            % Derivatives withheld, so the FD path is the one under test.
            testCase.verifyArmSolves(struct( ...
                'FiniteDifferenceType', fdType, ...
                'SpecifyObjectiveGradient', false, ...
                'SpecifyConstraintGradient', false));
        end

        function testTraceLevelArms(testCase, traceLevel)
            testCase.verifyArmSolves(struct('traceLevel', traceLevel));
        end

        function testDefaultOnFlagsCanBeTurnedOff(testCase, defaultOnFlag)
            %   Every one of these guards or accelerates something; with it off
            %   the solver must still find the optimum, just by a different
            %   route.  A flag whose "off" path is broken is invisible until
            %   someone turns it off in anger.
            d = adamnlopt.defaultOptions();
            testCase.assertTrue(d.(defaultOnFlag), ...
                sprintf('%s is not actually on by default', defaultOnFlag));
            testCase.verifyArmSolves(struct(defaultOnFlag, false));
        end

        function testDefaultOffFlagsCanBeTurnedOn(testCase, defaultOffFlag)
            d = adamnlopt.defaultOptions();
            testCase.assertFalse(d.(defaultOffFlag), ...
                sprintf('%s is not actually off by default', defaultOffFlag));
            if strcmp(defaultOffFlag, 'useNTdecomp')
                % useNTdecomp cannot do NONLINEAR INEQUALITIES -- see
                % testUseNTdecompIsRefusedOnNonlinearInequalities below.  Those
                % problems now warn and fall back, so they are covered by that
                % test; here the arm exercises what the NT branch itself runs.
                testCase.verifyArmSolves(struct(defaultOffFlag, true), ...
                    {'sphere2', 'simplexCenter'});
                return;
            end
            testCase.verifyArmSolves(struct(defaultOffFlag, true));
        end

        function testUseNTdecompIsRefusedOnNonlinearInequalities(testCase)
            %   With useNTdecomp = true the interior-point core takes a
            %   Byrd-Omojokun normal+tangential step inside a trust-region inner
            %   loop (solve.m, the `if opts.useNTdecomp` branch of the IP core)
            %   instead of a condensed KKT step plus line search.  On a problem
            %   with a nonlinear INEQUALITY the trust radius collapses -- 4.0 ->
            %   1.2e-4 -> 3.0e-5 -> 3.0e-8 -> 1.1e-16 over five outer iterations
            %   on HS71 -- after which every NT step is numerically zero, the
            %   least-squares multiplier refit inside computeNTStep fires against
            %   a null step, and ||lamE|| grows by a factor of nine per iteration
            %   (the exact factor dualStepMax = 10 permits) to 9e11.  The solve
            %   stalled at f = 17.3695 against the true 17.0140175 and reported
            %   exitflag 0 -- a wrong answer that looked merely under-converged.
            %
            %   The branch is not repaired; it is REFUSED.  A caller who leaves
            %   the flag set in a saved case gets a warning and a correct solve
            %   rather than an error or a quiet stall.  Bounds, linear
            %   inequalities, linear equalities and nonlinear EQUALITIES are all
            %   unaffected -- mInl > 0 is the exact trigger, measured across the
            %   whole catalog -- which is why the arm test above still runs the
            %   NT branch for real.
            p = testCase.catalogEntry('hs71');
            out = testCase.verifyWarning( ...
                @() testCase.solveProblem(p, struct('useNTdecomp', true)), ...
                'adamnlopt:useNTdecompUnsupported');
            testCase.verifyGreaterThan(out.exitflag, 0, ...
                'the fallback must still solve the problem');
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-4);
        end

        function testUseNTdecompIsLeftAloneOnANonlinearEquality(testCase)
            %   The guard keys on nonlinear INEQUALITIES only; narrowing it any
            %   further would disable a branch that works, and widening it to
            %   any nonlinear constraint would silently drop the equality case
            %   the NT decomposition was written for.
            p = testCase.catalogEntry('circleEq');
            out = testCase.verifyWarningFree( ...
                @() testCase.solveProblem(p, struct('useNTdecomp', true)));
            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-4);
        end

        function testAllFourDerivativeSupplyCombinations(testCase)
            p = testCase.catalogEntry('hs71');
            for objGrad = [false true]
                for conGrad = [false true]
                    out = testCase.solveProblem(p, struct( ...
                        'SpecifyObjectiveGradient', objGrad, ...
                        'SpecifyConstraintGradient', conGrad));
                    testCase.verifyGreaterThan(out.exitflag, 0, sprintf( ...
                        'objGrad=%d conGrad=%d failed to converge', ...
                        objGrad, conGrad));
                    testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-3, ...
                        sprintf('objGrad=%d conGrad=%d wrong minimizer', ...
                                objGrad, conGrad));
                end
            end
        end

        function testFiniteDivergeWindowArmsTheDivergenceExit(testCase)
            % Inert by default (divergeWindow = Inf); setting it finite must not
            % break an ordinary solve.
            testCase.verifyArmSolves(struct('divergeWindow', 10));
        end

        function testStepTolZeroDisablesTheStepExit(testCase)
            testCase.verifyArmSolves(struct('stepTol', 0));
        end

        function testActiveBoundGapTolZeroStillSolves(testCase)
            testCase.verifyArmSolves(struct('activeBoundGapTol', 0));
        end

        function testSparsityPatternsAreHonoured(testCase)
            p = testCase.catalogEntry('hs71');
            out = testCase.solveProblem(p, struct( ...
                'JacobPattern', sparse(ones(2, 4)), ...
                'HessPattern',  sparse(ones(4, 4)), ...
                'SpecifyObjectiveGradient', false, ...
                'SpecifyConstraintGradient', false));

            testCase.verifyGreaterThan(out.exitflag, 0);
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-3);
        end

        function testParallelFiniteDiffMatchesSerial(testCase)
            testCase.assumeTrue(license('test', 'Distrib_Computing_Toolbox') == 1, ...
                'Parallel Computing Toolbox not available.');
            p = testCase.catalogEntry('sphere5');
            serial = testCase.solveProblem(p, struct( ...
                'parallel', 'off', 'SpecifyObjectiveGradient', false));
            par = testCase.solveProblem(p, struct( ...
                'parallel', 'finitediff', 'SpecifyObjectiveGradient', false));

            testCase.verifyEqual(par.x, serial.x, 'AbsTol', 1e-6, ...
                'the parallel FD path disagrees with the serial one');
        end

    end

    %% ====================================================================
    %  Regression guards for findings 56, 57 and 61
    %  ====================================================================
    methods (Test)

        function testInactiveLinearRowDoesNotHangTheSolver(testCase, slackRowBound)
            %   FINDING 56.  The restoration trigger used to test
            %   norm([cE; cI + s], 1) -- the primal residual of the SLACK-
            %   augmented system -- while degeneracy_restorationPhase minimizes
            %   the true violation theta(x) = ||cE||_1 + ||max(cI,0)||_1.  Add a
            %   trivially inactive row and the slacks drift out of sync with cI,
            %   so the trigger fires at a point where x is already feasible:
            %   restoration sees theta = 0, returns immediately with iters = 0,
            %   misses the ef = -2 guard, resets the filter and continues --
            %   re-arming itself every iteration forever.  The bound is
            %   parameterized because the defect only appeared once the row was
            %   slack enough (b >= 10 hung; b <= 7 did not), so a single value
            %   would have been luck rather than coverage.
            p = AdamNlOptTestCase.problem('inactiveRow', ...
                @AdamNlOptTestCase.distanceTo21, [0.3; 0.2]);
            p.nonlcon = @AdamNlOptTestCase.unitDiskIneq;
            p.hasConGrad = true;
            p.A = [1 0];
            p.b = slackRowBound;
            % min (x1-2)^2 + (x2-1)^2 s.t. ||x|| <= 1: the optimum is the radial
            % projection of (2,1) onto the unit circle, and x1 <= b never binds.
            p.xStar = [2; 1] / norm([2; 1]);

            out = testCase.solveProblem(p, struct('maxIter', 300));

            testCase.verifyGreaterThan(out.exitflag, 0, sprintf( ...
                ['b = %g: adding an inactive linear row must not prevent ' ...
                 'convergence (got exitflag %d after %d iterations)'], ...
                slackRowBound, out.exitflag, out.output.iterations));
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-5);
            testCase.verifyLessThan(out.output.iterations, 100, ...
                'the solve converged, but took the iteration count of a stall');
        end

        function testRestorationAugmentsTheFilterRatherThanClearingIt(testCase)
            %   FINDING 57.  Waechter-Biegler add (theta_k, phi_k) to the filter
            %   on the way INTO restoration, precisely so the main iteration
            %   cannot walk back into the region that sent it there.  This code
            %   called filt.reset() instead, throwing away the only cycle-
            %   prevention mechanism the method has.  At b = 100 that produced a
            %   textbook period-2 limit cycle: restoration fired 147 times, each
            %   time restoring to feasibility, whereupon the next interior-point
            %   step jumped straight back out to the same infeasible point.  The
            %   solve ran to maxIter and reported exitflag 0.
            %
            %   A wide-but-inactive row is the cheapest reproducer, so this
            %   shares the finding-56 setup; what distinguishes the two is that
            %   56 is about restoration firing at all and 57 is about what the
            %   filter looks like afterwards.  Restoration must therefore
            %   actually fire here for the test to mean anything -- hence the
            %   trace assertion rather than a bare convergence check.
            p = AdamNlOptTestCase.problem('limitCycle', ...
                @AdamNlOptTestCase.distanceTo21, [0.3; 0.2]);
            p.nonlcon = @AdamNlOptTestCase.unitDiskIneq;
            p.hasConGrad = true;
            p.A = [1 0];
            p.b = 100;
            p.xStar = [2; 1] / norm([2; 1]);

            out = testCase.solveProblem(p, ...
                struct('maxIter', 300, 'traceLevel', 2));

            testCase.verifyGreaterThan(out.exitflag, 0, ...
                'the restoration limit cycle is back');
            testCase.verifyEqual(out.x, p.xStar, 'AbsTol', 1e-5);

            fired = sum(out.output.trace.restorationFired > 0);
            testCase.verifyLessThan(fired, 10, sprintf( ...
                ['restoration fired %d times; repeated firing is the ' ...
                 'signature of the cleared filter letting the iteration ' ...
                 'walk back into the region it just escaped'], fired));
        end

    end

    %% ====================================================================
    %  Helpers
    %  ====================================================================
    methods (Access = private)

        function p = infeasibleProblem(~)
            %INFEASIBLEPROBLEM  ceq = x'x + 1 = 0: no real solution anywhere, so
            %   restoration cannot find a feasible point and must report -2.
            %   Deliberately NOT in the catalog -- it has no optimum, so the
            %   parameterized battery would have nothing to assert against.
            p = AdamNlOptTestCase.problem('infeasible', ...
                @AdamNlOptTestCase.sphere, [0.7; -0.4]);
            p.nonlcon    = @AdamNlOptTestCase.impossibleEq;
            p.hasConGrad = true;
        end

        function verifyArmSolves(testCase, overrides, names)
            %VERIFYARMSOLVES  Solve the three representative problems under the
            %   supplied option overrides.  Each must still reach its analytic
            %   optimum; tolerances are loosened by one decade relative to the
            %   catalog because an off-default path is allowed to be slightly
            %   less accurate, just not wrong.
            if nargin < 3, names = {'sphere2', 'simplexCenter', 'hs71'}; end
            cat = AdamNlOptTestCase.catalog();
            for name = names
                p = cat.(name{1});
                p.xTol = max(10 * p.xTol, 1e-3);
                p.fTol = max(10 * p.fTol, 1e-5);
                p.kktTol = max(10 * p.kktTol, 1e-3);
                testCase.verifySolvesTo(p, overrides);
            end
        end

        function c = counter(~)
            %COUNTER  A mutable box a hook can write to through its closure.
            %   containers.Map is a handle, so assignments inside the hook are
            %   visible here afterwards.  Same idiom as AdamNlOptTest's
            %   countingObj/countingCircle helpers.
            c = containers.Map({'n', 'payload'}, {0, []}, ...
                               'UniformValues', false);  %#ok<*CTNRMAP>
        end

        function out = captureOutput(~, fcn)
            %CAPTUREOUTPUT  Run FCN with the command window swallowed.
            [~, out] = evalc('fcn()');
        end

        function out = suppressWarnings(~, fcn)
            %SUPPRESSWARNINGS  Run FCN with warnings off, restoring the state.
            w = warning('off', 'all');
            restore = onCleanup(@() warning(w));
            out = fcn();
            clear restore;  %#ok<CLEAR>
        end

    end
end

% =========================================================================
% Hook bodies.  Written as real functions rather than anonymous closures so
% they can mutate the shared handle and still return a value SOLVE can read.
% =========================================================================

function stop = hookRecord(calls, lastIter, info)
%HOOKRECORD  Count calls and remember the highest iteration number seen.
calls('n') = calls('n') + 1;
if isfield(info, 'iteration')
    lastIter('n') = max(lastIter('n'), info.iteration);
elseif isfield(info, 'iter')
    lastIter('n') = max(lastIter('n'), info.iter);
end
stop = false;
end

function stop = hookCapture(seen, info)
%HOOKCAPTURE  Keep the first info struct for field inspection.
if isempty(seen('payload'))
    seen('payload') = info;
end
seen('n') = seen('n') + 1;
stop = false;
end

function stop = hookCount(calls, ~)
%HOOKCOUNT  Count calls only.
calls('n') = calls('n') + 1;
stop = false;
end

function stop = hookStamp(order, id, ~)
%HOOKSTAMP  Append this hook's id, so call ORDER is observable.
order('payload') = [order('payload'), id];
stop = false;
end

function deleteIfPresent(path)
%DELETEIFPRESENT  Remove a temp file without complaining if it never appeared.
if isfile(path)
    delete(path);
end
end
