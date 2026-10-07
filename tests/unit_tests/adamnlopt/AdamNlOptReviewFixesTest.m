classdef AdamNlOptReviewFixesTest < AdamNlOptTestCase
%ADAMNLOPTREVIEWFIXESTEST  Regression guards for AdamNlOpt_Review_Report.md fixes.
%   One test (or a few) per report finding, named after its ID, so a later
%   batch can see at a glance which findings are pinned.  Every test here fails
%   on the code before its fix.
%
%   Batch 1: D1.1, D2, D8.1, D9, D11.2, D11.3, D24, D26, D27, D29.
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

    methods (Static)
        function [c, ceq] = slowCircle(x)
            pause(0.06);
            c = [];
            ceq = x(1)^2 + x(2)^2 - 1;
        end
    end

    methods (Access = private)
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
