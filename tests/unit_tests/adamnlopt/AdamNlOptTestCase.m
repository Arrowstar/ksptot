classdef (Abstract) AdamNlOptTestCase < matlab.unittest.TestCase
%ADAMNLOPTTESTCASE  Shared base for the adamnlopt test suite.
%   Carries the three things every adamnlopt test file needs: the project path
%   setup, the independent verifiers (an analytic-optimum check and a KKT
%   residual check built from the RETURNED multipliers), and the benchmark
%   problem catalog.
%
%   No Optimization Toolbox is used anywhere in this suite.  The oracles are
%   closed-form optima, the in-repo DERIVESTsuite (gradest/jacobianest/hessian,
%   Richardson-extrapolated and far more accurate than the package's own forward
%   differences), the KKT conditions themselves, and brute force on the small
%   combinatorial subproblems.
%
%   Catalog entries are built by PROBLEM and their objectives/constraints are
%   real multi-output STATIC METHODS, never @(x) deal(f,g): solve probes the
%   objective with nargout = 1, where deal errors.  Static-method handles report
%   nargout correctly (verified: nargout(@AdamNlOptTestCase.sphere) == 2), so the
%   analytic gradient is actually visible to the solver -- an anonymous wrapper
%   reports -1 and gets finite-differenced instead.
%
%   See also ADAMNLOPTTEST, ADAMNLOPTSOLVETEST, GRADEST, JACOBIANEST.

    methods (TestClassSetup)
        function addPaths(~)
            ksptotAddProjectPaths();
        end
    end

    %% ------------------------------------------------------------------
    %  Verifiers
    %  ------------------------------------------------------------------
    methods
        function opts = quietOpts(~, overrides)
            %QUIETOPTS  Options struct with Display off and OVERRIDES applied.
            %   The workhorse of the A/B matrix.  Lifted from the private helper
            %   of the same name in AdamNlOptTest so both files agree on what a
            %   "quiet" solve means.
            opts = struct('Display', 'off');
            if nargin > 1 && ~isempty(overrides)
                f = fieldnames(overrides);
                for i = 1:numel(f)
                    opts.(f{i}) = overrides.(f{i});
                end
            end
        end

        function out = solveProblem(testCase, p, overrides)
            %SOLVEPROBLEM  Run adamnlopt.solve on a catalog entry.
            %   Returns a struct of every solve output so callers can assert on
            %   whichever they care about.
            if nargin < 3, overrides = struct(); end
            opts = testCase.quietOpts(overrides);
            if ~isfield(opts, 'SpecifyObjectiveGradient')
                opts.SpecifyObjectiveGradient = p.hasObjGrad;
            end
            if ~isfield(opts, 'SpecifyConstraintGradient')
                opts.SpecifyConstraintGradient = p.hasConGrad;
            end
            out = struct();
            [out.x, out.fval, out.exitflag, out.output, out.lambda, ...
                out.grad, out.hessian] = adamnlopt.solve( ...
                    p.fun, p.x0, p.A, p.b, p.Aeq, p.beq, p.lb, p.ub, ...
                    p.nonlcon, opts);
        end

        function out = verifySolvesTo(testCase, p, overrides)
            %VERIFYSOLVESTO  Solve P and check it against its known optimum.
            %   Asserts a converged exit, the analytic x*/f*, the reported
            %   feasibility and optimality against the tolerances actually in
            %   force, and then the KKT conditions at the returned point using
            %   the returned multipliers.
            if nargin < 3, overrides = struct(); end
            out = testCase.solveProblem(p, overrides);

            testCase.verifyGreaterThan(out.exitflag, 0, ...
                sprintf('%s: expected a converged exit, got %d (%s)', ...
                        p.name, out.exitflag, out.output.message));

            if ~isempty(p.xStar)
                testCase.verifyEqual(out.x, p.xStar, 'AbsTol', p.xTol, ...
                    sprintf('%s: wrong minimizer', p.name));
            end
            if ~isempty(p.fStar)
                testCase.verifyEqual(out.fval, p.fStar, 'AbsTol', p.fTol, ...
                    sprintf('%s: wrong optimal value', p.name));
            end

            feasTol = testCase.optionOrDefault(overrides, 'feasTol', 1e-6);
            testCase.verifyLessThanOrEqual(out.output.constrViolation, ...
                10 * feasTol, sprintf('%s: reported infeasible', p.name));

            testCase.verifyKKT(p, out.x, out.lambda);
        end

        function verifyKKT(testCase, p, x, lambda, tol)
            %VERIFYKKT  Check the KKT conditions from the RETURNED multipliers.
            %   The strongest black-box oracle in the suite, and the only one
            %   that can catch a solve that lands on the right x while reporting
            %   garbage multipliers.  Derivatives come from DERIVESTsuite, never
            %   from the package under test.
            %
            %   Sign convention (fmincon's, which makeLambda follows):
            %       grad f + A'*ineqlin + Aeq'*eqlin
            %                + Jc'*ineqnonlin + Jceq'*eqnonlin
            %                + upper - lower  =  0
            if nargin < 5 || isempty(tol), tol = p.kktTol; end
            n = numel(x);

            r = testCase.objGrad(p, x);
            if ~isempty(p.A)
                r = r + p.A.' * lambda.ineqlin;
                testCase.verifyGreaterThanOrEqual(lambda.ineqlin, -tol, ...
                    sprintf('%s: negative linear inequality multiplier', p.name));
                slack = p.b - p.A * x;
                testCase.verifyGreaterThanOrEqual(slack, -tol, ...
                    sprintf('%s: linear inequality violated', p.name));
                testCase.verifyLessThanOrEqual(abs(lambda.ineqlin .* slack), ...
                    tol, sprintf('%s: linear inequality complementarity', p.name));
            end
            if ~isempty(p.Aeq)
                r = r + p.Aeq.' * lambda.eqlin;
                testCase.verifyLessThanOrEqual(abs(p.Aeq * x - p.beq), tol, ...
                    sprintf('%s: linear equality violated', p.name));
            end
            if ~isempty(p.nonlcon)
                [c, ceq] = p.nonlcon(x);
                if ~isempty(c)
                    Jc = testCase.conJacobian(p, x, 1);
                    r = r + Jc.' * lambda.ineqnonlin;
                    testCase.verifyGreaterThanOrEqual(lambda.ineqnonlin, -tol, ...
                        sprintf('%s: negative nonlinear inequality multiplier', p.name));
                    testCase.verifyLessThanOrEqual(c, tol, ...
                        sprintf('%s: nonlinear inequality violated', p.name));
                    testCase.verifyLessThanOrEqual(abs(lambda.ineqnonlin .* c(:)), ...
                        tol, sprintf('%s: nonlinear inequality complementarity', p.name));
                end
                if ~isempty(ceq)
                    Jceq = testCase.conJacobian(p, x, 2);
                    r = r + Jceq.' * lambda.eqnonlin;
                    testCase.verifyLessThanOrEqual(abs(ceq), tol, ...
                        sprintf('%s: nonlinear equality violated', p.name));
                end
            end

            lo = testCase.padBound(lambda.lower, n);
            up = testCase.padBound(lambda.upper, n);
            r = r - lo + up;
            testCase.verifyGreaterThanOrEqual(lo, -tol, ...
                sprintf('%s: negative lower-bound multiplier', p.name));
            testCase.verifyGreaterThanOrEqual(up, -tol, ...
                sprintf('%s: negative upper-bound multiplier', p.name));
            if ~isempty(p.lb)
                gap = x - p.lb(:);
                active = isfinite(p.lb(:));
                testCase.verifyGreaterThanOrEqual(gap(active), -tol, ...
                    sprintf('%s: lower bound violated', p.name));
                testCase.verifyLessThanOrEqual(abs(lo(active) .* gap(active)), ...
                    tol, sprintf('%s: lower-bound complementarity', p.name));
            end
            if ~isempty(p.ub)
                gap = p.ub(:) - x;
                active = isfinite(p.ub(:));
                testCase.verifyGreaterThanOrEqual(gap(active), -tol, ...
                    sprintf('%s: upper bound violated', p.name));
                testCase.verifyLessThanOrEqual(abs(up(active) .* gap(active)), ...
                    tol, sprintf('%s: upper-bound complementarity', p.name));
            end

            testCase.verifyLessThanOrEqual(norm(r, inf), tol, ...
                sprintf('%s: stationarity residual %g exceeds %g', ...
                        p.name, norm(r, inf), tol));
        end

        function p = catalogEntry(~, name)
            %CATALOGENTRY  One named problem from the shared catalog.
            cat = AdamNlOptTestCase.catalog();
            p = cat.(name);
        end
    end

    methods (Static)
        function g = quietGradest(fcn, x)
            %QUIETGRADEST  gradest with its timing chatter swallowed.
            %   gradest/jacobianest end with an unconditional
            %   fprintf('Computed gradient in %0.3f sec.\n', ...) that no option
            %   turns off.  DERIVESTsuite is shared repo code used elsewhere, so
            %   it is not ours to patch; capture the output here instead.  Returns
            %   a COLUMN vector -- gradest itself returns a row.
            [~, g] = evalc('gradest(fcn, x)');
            g = reshape(g, [], 1);
        end

        function J = quietJacobianest(fcn, x)
            %QUIETJACOBIANEST  jacobianest, same chatter, same treatment.
            [~, J] = evalc('jacobianest(fcn, x)');
        end
    end

    methods (Access = private)
        function g = objGrad(~, p, x)
            %OBJGRAD  Objective gradient from DERIVESTsuite (column vector).
            g = AdamNlOptTestCase.quietGradest( ...
                @(z) p.fun(reshape(z, size(x))), x);
        end

        function J = conJacobian(~, p, x, which)
            %CONJACOBIAN  Constraint Jacobian from DERIVESTsuite.
            %   WHICH is 1 for the inequality block c, 2 for the equality block
            %   ceq.  jacobianest returns m-by-n.
            J = AdamNlOptTestCase.quietJacobianest( ...
                @(z) pickCon(p.nonlcon, reshape(z, size(x)), which), x);
        end

        function v = padBound(~, v, n)
            %PADBOUND  A bound multiplier block as a full n-by-1 column.
            if isempty(v), v = zeros(n, 1); else, v = v(:); end
        end

        function v = optionOrDefault(~, overrides, name, dflt)
            v = dflt;
            if isstruct(overrides) && isfield(overrides, name) ...
                    && ~isempty(overrides.(name))
                v = overrides.(name);
            end
        end
    end

    %% ------------------------------------------------------------------
    %  Problem catalog
    %  ------------------------------------------------------------------
    methods (Static)
        function p = problem(name, fun, x0)
            %PROBLEM  A catalog entry with every field defaulted.
            %   Callers override only what their problem actually has, which
            %   keeps the catalog readable and guarantees solveProblem never
            %   sees a missing field.
            p = struct( ...
                'name',       name, ...
                'fun',        fun, ...
                'x0',         x0(:), ...
                'A',          [], 'b',   [], ...
                'Aeq',        [], 'beq', [], ...
                'lb',         [], 'ub',  [], ...
                'nonlcon',    [], ...
                'hasObjGrad', true, ...
                'hasConGrad', false, ...
                'xStar',      [], 'fStar', [], ...
                'xTol',       1e-5, 'fTol', 1e-6, ...
                'kktTol',     1e-4);
        end

        function cat = catalog()
            %CATALOG  The benchmark battery, keyed by problem name.
            %   Returned as a struct so it can be used directly as a
            %   matlab.unittest TestParameter (one parameterization per field).
            %   Every entry carries an ANALYTIC optimum; nothing here is pinned
            %   to a number the solver itself produced.
            mk = @AdamNlOptTestCase.problem;
            cat = struct();

            % --- Unconstrained -----------------------------------------
            p = mk('sphere2', @AdamNlOptTestCase.sphere, [1.3; -2.7]);
            p.xStar = [0; 0];           p.fStar = 0;
            cat.sphere2 = p;

            p = mk('sphere5', @AdamNlOptTestCase.sphere, (1:5).');
            p.xStar = zeros(5, 1);      p.fStar = 0;
            cat.sphere5 = p;

            p = mk('rosenbrock', @AdamNlOptTestCase.rosenbrock, [-1.2; 1]);
            p.xStar = [1; 1];           p.fStar = 0;
            p.xTol = 1e-4;              p.fTol = 1e-8;
            cat.rosenbrock = p;

            p = mk('beale', @AdamNlOptTestCase.beale, [1; 1]);
            p.xStar = [3; 0.5];         p.fStar = 0;
            p.xTol = 1e-4;              p.fTol = 1e-8;
            cat.beale = p;

            p = mk('booth', @AdamNlOptTestCase.booth, [0; 0]);
            p.xStar = [1; 3];           p.fStar = 0;
            cat.booth = p;

            % Singular Hessian at the minimizer: the inertia correction has to
            % cope with a genuinely rank-deficient model, not a contrived one.
            p = mk('powellQuartic', @AdamNlOptTestCase.powellQuartic, [3; -1; 0; 1]);
            p.xStar = zeros(4, 1);      p.fStar = 0;
            p.xTol = 2e-2;              p.fTol = 1e-6;    p.kktTol = 1e-3;
            cat.powellQuartic = p;

            % --- Bounds only -------------------------------------------
            p = mk('boundInterior', @AdamNlOptTestCase.shiftedSphereHalf, [0.9; 0.1]);
            p.lb = [0; 0];  p.ub = [1; 1];
            p.xStar = [0.5; 0.5];       p.fStar = 0;
            cat.boundInterior = p;

            % Optimum sits exactly ON the upper bound, so the barrier has to
            % drive a variable to its boundary and the bound multipliers carry
            % the whole stationarity row.
            p = mk('boundActive', @AdamNlOptTestCase.shiftedSphere2, [0.2; 0.2]);
            p.lb = [0; 0];  p.ub = [1; 1];
            p.xStar = [1; 1];           p.fStar = 2;
            cat.boundActive = p;

            % x0 outside the box: HonorBounds clips it and warns.
            p = mk('x0OutOfBox', @AdamNlOptTestCase.shiftedSphereHalf, [5; -5]);
            p.lb = [0; 0];  p.ub = [1; 1];
            p.xStar = [0.5; 0.5];       p.fStar = 0;
            cat.x0OutOfBox = p;

            p = mk('scalar', @AdamNlOptTestCase.scalarShifted, 0);
            p.xStar = 3;                p.fStar = 0;
            cat.scalar = p;

            % --- Linear equality ---------------------------------------
            % min ||x||^2 s.t. sum(x) = 1  ->  x = 1/n, f* = 1/n.
            p = mk('simplexCenter', @AdamNlOptTestCase.sphere, [3; -1; 2]);
            p.Aeq = ones(1, 3);  p.beq = 1;
            p.xStar = ones(3, 1) / 3;   p.fStar = 1 / 3;
            cat.simplexCenter = p;

            % --- Linear inequality -------------------------------------
            % min ||x-[2;2]||^2 s.t. x1+x2 <= 1.  The constraint is ACTIVE; the
            % optimum is the projection of [2;2] onto the line, [0.5;0.5].
            p = mk('ineqActive', @AdamNlOptTestCase.shiftedSphere2, [0; 0]);
            p.A = [1 1];  p.b = 1;
            p.xStar = [0.5; 0.5];       p.fStar = 4.5;
            cat.ineqActive = p;

            % Same constraint, optimum strictly INSIDE it: every multiplier
            % must come back zero.
            p = mk('ineqInactive', @AdamNlOptTestCase.shiftedSphereSmall, [0; 0]);
            p.A = [1 1];  p.b = 1;
            p.xStar = [0.2; 0.2];       p.fStar = 0;
            cat.ineqInactive = p;

            % Redundant row: [2 2]x <= 2 says exactly what [1 1]x <= 1 says.
            p = mk('ineqRedundant', @AdamNlOptTestCase.shiftedSphere2, [0; 0]);
            p.A = [1 1; 2 2];  p.b = [1; 2];
            p.xStar = [0.5; 0.5];       p.fStar = 4.5;
            cat.ineqRedundant = p;

            % --- Nonlinear equality ------------------------------------
            % min x1+x2 s.t. x1^2+x2^2 = 1  ->  -(1/sqrt(2))*[1;1], f* = -sqrt(2).
            p = mk('circleEq', @AdamNlOptTestCase.sumCoords, [0.9; 0.3]);
            p.nonlcon = @AdamNlOptTestCase.unitCircleEq;  p.hasConGrad = true;
            p.xStar = -ones(2, 1) / sqrt(2);  p.fStar = -sqrt(2);
            cat.circleEq = p;

            % --- Nonlinear inequality ----------------------------------
            % min (x1-2)^2+(x2-1)^2 s.t. x'x <= 1  ->  [2;1]/sqrt(5).
            p = mk('diskIneq', @AdamNlOptTestCase.distanceTo21, [0; 0]);
            p.nonlcon = @AdamNlOptTestCase.unitDiskIneq;  p.hasConGrad = true;
            p.xStar = [2; 1] / sqrt(5);  p.fStar = (sqrt(5) - 1)^2;
            cat.diskIneq = p;

            % --- Mixed -------------------------------------------------
            % HS71: bounds + one nonlinear equality + one nonlinear inequality.
            p = mk('hs71', @AdamNlOptTestCase.hs71Obj, [1; 5; 5; 1]);
            p.lb = ones(4, 1);  p.ub = 5 * ones(4, 1);
            p.nonlcon = @AdamNlOptTestCase.hs71Con;  p.hasConGrad = true;
            p.xStar = [1; 4.74299963; 3.82114998; 1.37940829];
            p.fStar = 17.01401724;
            p.xTol = 1e-4;  p.fTol = 1e-6;  p.kktTol = 1e-3;
            cat.hs71 = p;
        end

        %% --- Objectives (all two-output; nargout(@handle) == 2) ---------
        function [f, g] = sphere(x)
            %SPHERE  f = x'x, minimized at the origin.
            f = x.' * x;
            g = 2 * x;
        end

        function [f, g] = rosenbrock(x)
            %ROSENBROCK  The classic banana valley; x* = [1;1], f* = 0.
            f = 100 * (x(2) - x(1)^2)^2 + (1 - x(1))^2;
            g = [-400 * x(1) * (x(2) - x(1)^2) - 2 * (1 - x(1));
                  200 * (x(2) - x(1)^2)];
        end

        function [f, g] = beale(x)
            %BEALE  x* = [3; 0.5], f* = 0.
            t1 = 1.5   - x(1) + x(1) * x(2);
            t2 = 2.25  - x(1) + x(1) * x(2)^2;
            t3 = 2.625 - x(1) + x(1) * x(2)^3;
            f = t1^2 + t2^2 + t3^2;
            g = [2 * (t1 * (x(2) - 1) + t2 * (x(2)^2 - 1) + t3 * (x(2)^3 - 1));
                 2 * (t1 * x(1) + t2 * 2 * x(1) * x(2) + t3 * 3 * x(1) * x(2)^2)];
        end

        function [f, g] = booth(x)
            %BOOTH  x* = [1; 3], f* = 0.
            a = x(1) + 2 * x(2) - 7;
            b = 2 * x(1) + x(2) - 5;
            f = a^2 + b^2;
            g = [2 * a + 4 * b;  4 * a + 2 * b];
        end

        function [f, g] = powellQuartic(x)
            %POWELLQUARTIC  Powell's singular function; x* = 0, f* = 0.
            %   The Hessian is SINGULAR at the minimizer, so this is the case
            %   that exercises the inertia correction on a genuinely rank-
            %   deficient model rather than a contrived one.
            a = x(1) + 10 * x(2);
            b = x(3) - x(4);
            c = x(2) - 2 * x(3);
            d = x(1) - x(4);
            f = a^2 + 5 * b^2 + c^4 + 10 * d^4;
            g = [ 2 * a + 40 * d^3;
                 20 * a +  4 * c^3;
                 10 * b -  8 * c^3;
                -10 * b - 40 * d^3];
        end

        function [f, g] = shiftedSphere2(x)
            %SHIFTEDSPHERE2  f = ||x - [2;2]||^2.
            d = x - [2; 2];
            f = d.' * d;
            g = 2 * d;
        end

        function [f, g] = shiftedSphereSmall(x)
            %SHIFTEDSPHERESMALL  f = ||x - [0.2;0.2]||^2 (optimum interior).
            d = x - [0.2; 0.2];
            f = d.' * d;
            g = 2 * d;
        end

        function [f, g] = shiftedSphereHalf(x)
            %SHIFTEDSPHEREHALF  f = ||x - [0.5;0.5]||^2.
            d = x - [0.5; 0.5];
            f = d.' * d;
            g = 2 * d;
        end

        function [f, g] = sumCoords(x)
            %SUMCOORDS  f = sum(x); linear, so the curvature is all in the
            %   constraint.  Used for the nonlinear-equality circle case.
            f = sum(x);
            g = ones(numel(x), 1);
        end

        function [f, g] = distanceTo21(x)
            %DISTANCETO21  f = (x1-2)^2 + (x2-1)^2.
            d = x - [2; 1];
            f = d.' * d;
            g = 2 * d;
        end

        function [f, g] = scalarShifted(x)
            %SCALARSHIFTED  f = (x-3)^2 in one variable.
            f = (x(1) - 3)^2;
            g = 2 * (x(1) - 3);
        end

        function [f, g] = hs71Obj(x)
            %HS71OBJ  Hock-Schittkowski 71: f = x1*x4*(x1+x2+x3) + x3.
            s = x(1) + x(2) + x(3);
            f = x(1) * x(4) * s + x(3);
            g = [x(4) * s + x(1) * x(4);
                 x(1) * x(4);
                 x(1) * x(4) + 1;
                 x(1) * s];
        end

        %% --- Constraints (four-output; fmincon's n-by-m gradient layout) --
        function [c, ceq, gc, gceq] = unitCircleEq(x)
            %UNITCIRCLEEQ  ceq = x'x - 1 (the unit circle).
            c = [];
            ceq = x.' * x - 1;
            gc = [];
            gceq = 2 * x;
        end

        function [c, ceq, gc, gceq] = unitDiskIneq(x)
            %UNITDISKINEQ  c = x'x - 1 <= 0 (the closed unit disk).
            c = x.' * x - 1;
            ceq = [];
            gc = 2 * x;
            gceq = [];
        end

        function [c, ceq, gc, gceq] = hs71Con(x)
            %HS71CON  c = 25 - prod(x) <= 0, ceq = sum(x.^2) - 40 = 0.
            c = 25 - prod(x);
            ceq = sum(x.^2) - 40;
            gc = -[x(2)*x(3)*x(4); x(1)*x(3)*x(4); x(1)*x(2)*x(4); x(1)*x(2)*x(3)];
            gceq = 2 * x;
        end

        function [c, ceq, gc, gceq] = impossibleEq(x)
            %IMPOSSIBLEEQ  ceq = x'x + 1 = 0, which has no real solution.
            c = [];
            ceq = x.' * x + 1;
            gc = [];
            gceq = 2 * x;
        end
    end
end

function v = pickCon(nonlcon, x, which)
%PICKCON  The inequality (1) or equality (2) constraint block as a column.
%   Module-level so jacobianest can difference one block at a time.
[c, ceq] = nonlcon(x);
if which == 1, v = c(:); else, v = ceq(:); end
end
