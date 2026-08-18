classdef Evaluator < handle
%EVALUATOR  Single gateway for objective/constraint values and derivatives.
%   Routes to user-supplied gradients/Jacobians when available and falls back
%   to finite differences otherwise, so no other module branches on derivative
%   availability. Folds linear constraints (A,b,Aeq,beq) together with the
%   nonlinear ones into the internal representation:
%       cE(x) = [Aeq*x - beq ; ceq_nl(x)]      (== 0)
%       cI(x) = [A*x   - b    ; c_nl(x)]        (<= 0)
%   Caches the most recent evaluation point to avoid recomputation. When
%   Jacobians are expensive (or Broyden mode is enabled) it maintains an
%   eval_BroydenJacobian rank-1 approximation between exact refreshes, timed by
%   an eval_costModel.
%
%   Properties:
%     objFun          - objective handle @(x) f or @(x) [f,g].
%     hasObjGrad      - logical; true if objFun returns an analytic gradient.
%     nlcon           - nonlinear constraint handle @(x) [c,ceq] (or with grads).
%     hasConGrad      - logical; true if nlcon returns analytic Jacobians.
%     Aineq, bineq    - linear inequality data (A*x <= b).
%     Aeqlin, beqlin  - linear equality data (Aeq*x = beq).
%     n               - number of variables.
%     mE, mI          - total (linear + nonlinear) equality/inequality counts.
%     mEnl, mInl      - nonlinear-only equality/inequality counts.
%     mIlin, mElin    - linear-only inequality/equality counts.
%     fdStep          - finite-difference base step size.
%     fdType          - 'forward' or 'central' difference scheme.
%     fdLb, fdUb      - bounds the FD probes must respect ([] when HonorBounds
%                       is off, which reproduces unbounded differencing exactly).
%     jacPattern      - sparsity pattern of the nonlinear Jacobian (or []).
%     nFun, nCon      - objective and constraint evaluation counters.
%     parallelFD      - logical; use parallel finite differencing when true.
%     costModel       - eval_costModel instance timing Jacobian evaluations.
%     enableBroyden   - logical; use rank-1 secant updates between refreshes.
%     broydenMaxStale - steps before a mandatory exact Jacobian refresh.
%     broydenTol      - Broyden model-error threshold for early refresh.
%     costThreshold   - avg FD Jacobian time (s) that auto-enables Broyden.
%     xf/fVal/gVal/hasCachedG - (private) objective cache and gradient flag.
%     xc/cEVal/cIVal          - (private) constraint-value cache.
%     xj/JEVal/JIVal          - (private) Jacobian cache.
%     broyden_        - (private) eval_BroydenJacobian instance ([] = inactive).
%     cNlAtJac_       - (private) stacked nonlinear constraints at last refresh.
%     xAtJac_         - (private) x at the last exact Jacobian point.
%
%   Methods:
%     Evaluator   - construct from a problem struct and options.
%     objective   - cached objective value f and (optional) gradient g.
%     constraints - cached folded equality cE and inequality cI values.
%     jacobian    - cached folded equality JE and inequality JI Jacobians.
%     evalNonlinear        - (private) raw nonlinear [c, ceq].
%     evalNonlinearStacked - (private) stacked [c; ceq] for differencing.
%     linIneq              - (private) linear inequality residual A*x - b.
%     linEq                - (private) linear equality residual Aeq*x - beq.
%     numFDevals           - (private) FD evaluation count for a gradient.
%     getOpt               - (static, private) option lookup with default.
%
%   See also EVAL_BROYDENJACOBIAN, EVAL_COSTMODEL, FINITEDIFFGRADIENT,
%   FINITEDIFFJACOBIAN.

    properties
        objFun            % @(x) f  or  @(x) [f,g]
        hasObjGrad = false
        nlcon = []        % @(x) [c,ceq] or [c,ceq,gc,gceq]
        hasConGrad = false
        Aineq  = [];  bineq  = [];
        Aeqlin = [];  beqlin = [];
        n = 0
        mE = 0;  mI = 0            % total (linear + nonlinear) counts
        mEnl = 0; mInl = 0         % nonlinear-only counts
        mIlin = 0; mElin = 0       % linear-only counts
        fdStep = sqrt(eps)
        fdType = 'forward'
        % Bounds the FD probes must stay inside.  Set from problem.lb/ub when
        % opts.HonorBounds is true, and left EMPTY otherwise -- fdBoundedStep
        % treats empty bounds as the identity, so HonorBounds = false takes the
        % legacy steps bit-for-bit rather than following a separate code path.
        % These are in the Evaluator's OWN space: scaleProblem scales lb/ub
        % alongside x0, so a scaled-space Evaluator gets scaled bounds and the
        % physical probe Evaluator gets physical ones.
        fdLb = []
        fdUb = []
        jacPattern = []            % sparsity of nonlinear inequality+equality Jacobian
        nFun = 0                   % objective evaluations
        nCon = 0                   % constraint evaluations
        parallelFD = false         % use parallel_parallelFiniteDiff when true
        costModel  = []            % eval_costModel instance (optional)
        % Broyden options (Gap 5)
        enableBroyden   = false    % use rank-1 secant updates between refreshes
        broydenMaxStale = 20       % steps before mandatory exact refresh
        broydenTol      = 0.1     % Broyden model-error threshold for early refresh
        costThreshold   = 0.1     % seconds: avg FD Jacobian time before auto-enable
        % Automatic finite-difference step calibration (autoFDStep)
        optTolForCalib = 1e-6      % optTol target for the V-curve step selection
    end

    properties (Access = private)
        xf = [];  fVal = [];  gVal = [];   hasCachedG = false
        xc = [];  cEVal = []; cIVal = [];
        xj = [];  JEVal = []; JIVal = [];
        % Broyden state (Gap 5)
        broyden_   = []   % eval_BroydenJacobian instance ([] = inactive)
        cNlAtJac_  = []   % stacked [c_nl; ceq_nl] at the last exact Jacobian point
        xAtJac_    = []   % x at the last exact Jacobian point
    end

    methods
        function obj = Evaluator(problem, opts)
        %EVALUATOR  Construct an evaluation gateway from a problem and options.
        %   obj = Evaluator(problem, opts) captures the objective and constraint
        %   handles, linear constraint data, and derivative flags, computes the
        %   linear/nonlinear/total constraint counts, and reads finite-difference
        %   and Broyden settings. A cost model is created for Jacobian timing.
        %
        %   Inputs:
        %     obj     - (constructor output).
        %     problem - struct with fields objFun, hasObjGrad, nlcon,
        %               hasConGrad, Aineq, bineq, Aeqlin, beqlin, n, mInl, mEnl.
        %     opts    - options struct with fields FiniteDifferenceStepSize,
        %               FiniteDifferenceType, JacobPattern, optional parallel,
        %               and optional Broyden fields (enableBroyden,
        %               broydenMaxStale, broydenTol, costThreshold).
        %
        %   Outputs:
        %     obj - the constructed Evaluator handle object.
            obj.objFun     = problem.objFun;
            obj.hasObjGrad = problem.hasObjGrad;
            obj.nlcon      = problem.nlcon;
            obj.hasConGrad = problem.hasConGrad;
            obj.Aineq  = problem.Aineq;   obj.bineq  = problem.bineq;
            obj.Aeqlin = problem.Aeqlin;  obj.beqlin = problem.beqlin;
            obj.n      = problem.n;
            obj.mInl   = problem.mInl;    obj.mEnl   = problem.mEnl;
            obj.mIlin  = size(obj.Aineq,1);
            obj.mElin  = size(obj.Aeqlin,1);
            obj.mI     = obj.mIlin + obj.mInl;
            obj.mE     = obj.mElin + obj.mEnl;
            obj.fdStep = opts.FiniteDifferenceStepSize;
            obj.fdType = opts.FiniteDifferenceType;
            if adamnlopt.Evaluator.getOpt(opts, 'HonorBounds', true)
                obj.fdLb = getfielddef(problem, 'lb', []);
                obj.fdUb = getfielddef(problem, 'ub', []);
            end
            obj.jacPattern = opts.JacobPattern;
            obj.parallelFD = isfield(opts,'parallel') && ...
                (strcmpi(opts.parallel,'finitediff') || strcmpi(opts.parallel,'async'));
            obj.costModel = adamnlopt.eval_costModel();
            obj.enableBroyden   = adamnlopt.Evaluator.getOpt(opts, 'enableBroyden',   false);
            obj.broydenMaxStale = adamnlopt.Evaluator.getOpt(opts, 'broydenMaxStale',  20);
            obj.broydenTol      = adamnlopt.Evaluator.getOpt(opts, 'broydenTol',       0.1);
            obj.costThreshold   = adamnlopt.Evaluator.getOpt(opts, 'costThreshold',    0.1);
            obj.optTolForCalib  = adamnlopt.Evaluator.getOpt(opts, 'optTol', 1e-6);
        end

        function [f, g] = objective(obj, x)
        %OBJECTIVE  Cached objective value and optional gradient.
        %   f = objective(obj, x) returns the objective value f(x).
        %   [f, g] = objective(obj, x) also returns the gradient g, taken from
        %   the user objective when hasObjGrad is set, otherwise from finite
        %   differences (parallel when parallelFD is set). Results are cached at
        %   x so repeated calls at the same point are not recomputed, and the
        %   evaluation counter nFun is advanced by the number of extra
        %   evaluations performed.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 point at which to evaluate.
        %
        %   Outputs:
        %     f - scalar objective value f(x).
        %     g - n-by-1 objective gradient (only if requested).
            import adamnlopt.*
            if ~isequal(x, obj.xf)
                if obj.hasObjGrad && nargout > 1
                    [obj.fVal, obj.gVal] = obj.objFun(x);
                    obj.gVal = obj.gVal(:);
                    obj.hasCachedG = true;
                else
                    obj.fVal = obj.objFun(x);
                    obj.hasCachedG = false;
                end
                obj.xf = x;
                obj.nFun = obj.nFun + 1;
            end
            f = obj.fVal;
            if nargout > 1
                if obj.hasObjGrad
                    if ~obj.hasCachedG
                        [~, gtmp] = obj.objFun(x);
                        obj.gVal = gtmp(:);
                        obj.hasCachedG = true;
                    end
                    g = obj.gVal;
                else
                    if obj.parallelFD
                        [g, ~] = parallel_parallelFiniteDiff( ...
                            @(z) obj.objFun(z), [], x, obj.fVal, [], ...
                            obj.fdStep, obj.fdType, [], obj.fdLb, obj.fdUb);
                    else
                        g = finiteDiffGradient(@(z) obj.objFun(z), x, obj.fVal, ...
                                               obj.fdStep, obj.fdType, ...
                                               obj.fdLb, obj.fdUb);
                    end
                    obj.nFun = obj.nFun + numFDevals(obj, x);
                end
            end
        end

        function info = calibrateStep(obj, x0)
        %CALIBRATESTEP  Set fdStep/fdType by a V-curve of the FD error at x0.
        %   info = calibrateStep(obj, x0) chooses the finite-difference step
        %   obj.fdStep and scheme obj.fdType by directly measuring how the FD
        %   error of the objective gradient and the nonlinear constraint Jacobian
        %   varies with the step, and picking the step at the bottom of the "V":
        %   large steps are truncation-dominated, tiny steps are noise-dominated,
        %   and the minimum is the best achievable accuracy.  This removes the
        %   need to hand-tune FiniteDifferenceStepSize/Type for simulation-based
        %   problems (e.g. ODE integrations), whose noise floor is far above
        %   machine precision so the default step sqrt(eps) is far too small.
        %
        %   The error is measured as a RELATIVE directional-derivative error
        %   against a Richardson-extrapolated (O(h^4)) reference, so the choice is
        %   invariant to how the problem is scaled -- it works whether the caller
        %   pre-normalised the problem or left it in raw units (the two regimes
        %   that defeat an absolute-noise-magnitude heuristic).  Forward
        %   differences (n evals/gradient) are kept when their best achievable
        %   relative error already meets optTol; otherwise the scheme is promoted
        %   to central (2n evals) when that is meaningfully more accurate.
        %
        %   Probes are skipped for any block with analytic derivatives (objective
        %   when hasObjGrad; constraints when hasConGrad or none are nonlinear).
        %   All probe evaluations are added to nFun.  Wrapped so a probe failure
        %   leaves the defaults untouched rather than stopping the solve.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x0  - n-by-1 point at which to calibrate (the Evaluator's own space).
        %
        %   When the Evaluator carries bounds (opts.HonorBounds), the sweep is
        %   truncated to the steps whose probes x0 +- h*svec stay inside the box,
        %   and calibration is abandoned outright when fewer than 3 steps survive
        %   -- see the comment at the truncation.
        %
        %   Outputs:
        %     info - struct: flag ('set'|'skipped'|'inconclusive'|'analytic'|
        %            'boundLimited'), promoted, fdStep, fdType, errFwd (best
        %            forward rel error), errCen (best central rel error), nEvals,
        %            hMax (largest in-bounds step; Inf when unbounded) and
        %            nSweepDropped (candidate steps removed by the bounds).
        %
        %   See also FINITEDIFFGRADIENT, FINITEDIFFJACOBIAN, ESTIMATENOISE.
            info = struct('flag', 'skipped', 'promoted', false, ...
                          'fdStep', obj.fdStep, 'fdType', obj.fdType, ...
                          'errFwd', NaN, 'errCen', NaN, 'nEvals', 0, ...
                          'hMax', Inf, 'nSweepDropped', 0);
            x0 = x0(:);  nx = numel(x0);

            % Probe functions returning VECTOR outputs: the (scalar) objective and
            % the full nonlinear constraint vector.  The constraint vector is kept
            % vector-valued -- not collapsed to a scalar projection -- because on a
            % simulation problem only a few components (e.g. the out-of-plane
            % control rows) carry the noise that sets the plateau; averaging them
            % into one projection hides that worst component and picks a step far
            % too small.  The per-component error is combined by the RELATIVE
            % inf-norm below, so the noisiest row governs the step, matching how it
            % will poison its own Jacobian column.
            probes = {};
            if ~obj.hasObjGrad
                probes{end+1} = @(z) obj.objFun(z);
            end
            if ~obj.hasConGrad && (obj.mEnl + obj.mInl) > 0
                probes{end+1} = @(z) obj.evalNonlinearStacked(z);
            end
            if isempty(probes)
                return;                      % all-analytic: nothing to calibrate
            end

            % Probe direction: a seeded random mix (so it is not aligned with any
            % single coordinate), weighted per coordinate by max(1,|x_i|) to match
            % finiteDiffGradient's relative-step convention, then NORMALISED to
            % unit length so the sweep variable h is the actual step magnitude
            % (without normalisation, summing nx~O(100+) coordinates makes even a
            % tiny h a huge perturbation and inverts the V-curve).
            sRng = rng;  rng(97531, 'twister');  p = randn(nx, 1);  rng(sRng);
            svec = p .* max(1, abs(x0));
            nsv = norm(svec);
            if ~(nsv > 0), return; end
            svec = svec / nsv;

            hSweep = 10 .^ (-1:-1:-9);       % candidate base steps (relative)

            % Keep the sweep inside the box.  Both probes x0 +- h*svec are taken,
            % so the largest usable h is the distance to the nearer bound along
            % +-svec.  Unbounded, this sweep starts at h = 0.1 on a UNIT-norm
            % direction, which on a narrow box lands far outside it: measured 92
            % BOX WIDTHS out on a 1e-3-wide box, i.e. the calibration was the
            % single largest source of out-of-bounds evaluations.
            %
            % Dropping the large-h end also removes the truncation-dominated arm
            % of the V, and the step is only meaningful if the V's bottom is
            % actually visible -- with one or two points left, min() just returns
            % the smallest of a monotone tail and would pin fdStep to whatever
            % the box happens to allow.  So below 3 usable steps, skip
            % calibration entirely and keep the default step, recording the
            % truncation in info so a caller can see why.
            info.hMax = Inf;  info.nSweepDropped = 0;
            if ~isempty(obj.fdLb) || ~isempty(obj.fdUb)
                hMax = maxFeasibleStep(x0, svec, obj.fdLb, obj.fdUb);
                info.hMax = hMax;
                keep = hSweep <= hMax;
                info.nSweepDropped = nnz(~keep);
                hSweep = hSweep(keep);
                if numel(hSweep) < 3
                    info.flag = 'boundLimited';
                    return;
                end
            end

            nh = numel(hSweep);
            target = obj.optTolForCalib;

            % Reference-free convergence measure.  At each step h form the forward
            % and central directional derivatives of every probe, then measure how
            % much each estimate CHANGED from the previous (10x larger) step,
            % relative to its own magnitude.  As h shrinks from large values this
            % adjacent change falls (truncation error decreasing) until noise
            % takes over and it rises again -- a V whose bottom is the best
            % achievable step.  No Richardson reference is needed (a fixed
            % reference step can itself sit on the noise floor and corrupt the
            % whole curve), and the inf-norm over the vector-valued constraint
            % probe keeps the noisiest component binding.
            nEv = 0;
            % adjacent-change per step, per probe (NaN at k=1: no previous step).
            adjFwdP = nan(nh, numel(probes));
            adjCenP = nan(nh, numel(probes));
            ok = true;
            try
                for ip = 1:numel(probes)
                    g = probes{ip};
                    g0 = g(x0);  nEv = nEv + 1;
                    dFprev = [];  dCprev = [];
                    for k = 1:nh
                        h = hSweep(k);
                        gp = g(x0 + h*svec);
                        gm = g(x0 - h*svec);
                        nEv = nEv + 2;
                        dFwd = (gp - g0) / h;
                        dCen = (gp - gm) / (2*h);
                        if ~isempty(dFprev)
                            sF = max(norm(dFwd, inf), realmin);
                            sC = max(norm(dCen, inf), realmin);
                            adjFwdP(k, ip) = norm(dFwd - dFprev, inf) / sF;
                            adjCenP(k, ip) = norm(dCen - dCprev, inf) / sC;
                        end
                        dFprev = dFwd;  dCprev = dCen;
                    end
                end
            catch
                ok = false;
            end
            obj.nFun = obj.nFun + nEv;
            info.nEvals = nEv;
            if ~ok
                info.flag = 'skipped';
                return;                      % probe failed: keep defaults
            end

            % Worst probe is binding at each step; k=1 stays NaN and is ignored.
            adjFwd = max(adjFwdP, [], 2);
            adjCen = max(adjCenP, [], 2);
            [bestF, iF] = min(adjFwd);
            [bestC, iC] = min(adjCen);
            info.errFwd = bestF;  info.errCen = bestC;

            if ~isfinite(bestF) && ~isfinite(bestC)
                info.flag = 'inconclusive';
                return;
            end

            % Clean-problem guard.  The reliable discriminator is how deep the
            % CENTRAL difference can converge: on a function smooth to machine
            % precision the best central adjacent-change reaches round-off
            % (~1e-10 or below, whether the curve is a deep V like Rosenbrock or
            % monotone like a plain quadratic), whereas a noisy simulation/iterative
            % problem cannot push the central estimate below its noise floor, which
            % sits well above round-off (empirically >~ 1e-9).  When central
            % reaches round-off the default step (sqrt(eps)) is already optimal and
            % overriding it can only lose accuracy, so keep the defaults; otherwise
            % a genuine noise floor is present and autoFDStep should act.
            noiseFloorTol = 1e-9;
            if ~(isfinite(bestC) && bestC > noiseFloorTol)
                info.flag = 'analytic';      % central reaches round-off: keep default
                return;
            end

            % Choose forward vs central.  Keep forward (half the evals) only when
            % its best achievable convergence floor is COMFORTABLY below the
            % optimality target (<= 0.1*target): the adjacent-change measure is a
            % convergence indicator, not the exact attainable KKT residual, and a
            % forward difference carries an O(h) truncation floor that can leave
            % the optimality residual plateaued near the target even when the
            % measure looks marginal (the documented forward-FD control-block
            % plateau).  Whenever central is available and meaningfully tighter,
            % promote to it -- the extra n evals/Jacobian buy the accuracy needed
            % to certify tight tolerances on a noisy simulation problem.
            if isfinite(bestF) && bestF <= 0.1 * target
                obj.fdType = 'forward';  obj.fdStep = hSweep(iF);
            elseif isfinite(bestC) && bestC < 0.5 * bestF
                obj.fdType = 'central';  obj.fdStep = hSweep(iC);
                info.promoted = true;
            elseif isfinite(bestF)
                obj.fdType = 'forward';  obj.fdStep = hSweep(iF);
            else
                obj.fdType = 'central';  obj.fdStep = hSweep(iC);
                info.promoted = true;
            end
            info.flag = 'set';
            info.fdStep = obj.fdStep;  info.fdType = obj.fdType;
        end

        function [cE, cI] = constraints(obj, x)
        %CONSTRAINTS  Cached folded equality and inequality constraint values.
        %   [cE, cI] = constraints(obj, x) returns the stacked constraint
        %   vectors with linear rows first and nonlinear rows appended:
        %       cE = [Aeq*x - beq ; ceq_nl(x)]   (== 0)
        %       cI = [A*x   - b    ; c_nl(x)]     (<= 0)
        %   Values are cached at x and the counter nCon is advanced once per new
        %   point.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 point at which to evaluate.
        %
        %   Outputs:
        %     cE - mE-by-1 folded equality constraint values.
        %     cI - mI-by-1 folded inequality constraint values.
            if ~isequal(x, obj.xc)
                [cnl, ceqnl] = obj.evalNonlinear(x);
                cIl = obj.linIneq(x);
                cEl = obj.linEq(x);
                obj.cIVal = [cIl; cnl(:)];
                obj.cEVal = [cEl; ceqnl(:)];
                obj.xc = x;
                obj.nCon = obj.nCon + 1;
            end
            cE = obj.cEVal;
            cI = obj.cIVal;
        end

        function [JE, JI] = jacobian(obj, x)
        %JACOBIAN  Cached folded equality and inequality constraint Jacobians.
        %   [JE, JI] = jacobian(obj, x) returns the stacked Jacobians matching
        %   the constraints layout, linear rows first:
        %       JE = [Aeqlin ; d(ceq_nl)/dx]
        %       JI = [Aineq  ; d(c_nl)/dx]
        %   The nonlinear blocks come from user-supplied gradients when
        %   hasConGrad is set, otherwise from finite differences (parallel or
        %   pattern-colored as configured). When Broyden mode is active and not
        %   stale, a rank-1 secant update supplies the nonlinear block instead of
        %   an exact recompute; on refresh the exact Jacobian is timed via the
        %   cost model and the Broyden state is (re)initialized. Results are
        %   cached at x.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 point at which to evaluate.
        %
        %   Outputs:
        %     JE - mE-by-n folded equality constraint Jacobian.
        %     JI - mI-by-n folded inequality constraint Jacobian.
            import adamnlopt.*
            if isequal(x, obj.xj)
                JE = obj.JEVal;  JI = obj.JIVal;
                return;
            end

            % --- Broyden update path ---
            if obj.enableBroyden && ~isempty(obj.broyden_) && ~obj.broyden_.needsRefresh()
                [cnl, ceqnl] = obj.evalNonlinear(x);
                cNlNew = [cnl(:); ceqnl(:)];
                s = x - obj.xAtJac_;
                y = cNlNew - obj.cNlAtJac_;
                obj.broyden_.update(s, y, cNlNew);
                if ~obj.broyden_.needsRefresh()
                    Jstacked = obj.broyden_.full();
                    obj.JIVal = [obj.Aineq;  Jstacked(1:obj.mInl, :)];
                    obj.JEVal = [obj.Aeqlin; Jstacked(obj.mInl+1:end, :)];
                    obj.xj = x;
                    JE = obj.JEVal;  JI = obj.JIVal;
                    return;
                end
                % needsRefresh became true: fall through to exact path.
            end

            % --- Exact Jacobian path ---
            t0 = tic;
            if obj.hasConGrad
                [~, ~, gc, gceq] = obj.nlcon(x);
                Jc   = transposeOrEmpty(gc,   obj.mInl, obj.n);
                Jceq = transposeOrEmpty(gceq, obj.mEnl, obj.n);
            else
                [cnl, ceqnl] = obj.evalNonlinear(x);
                h = @(z) obj.evalNonlinearStacked(z);
                base = [cnl(:); ceqnl(:)];
                if obj.parallelFD
                    [~, J] = parallel_parallelFiniteDiff( ...
                        [], h, x, [], base, obj.fdStep, obj.fdType, ...
                        obj.jacPattern, obj.fdLb, obj.fdUb);
                else
                    J = finiteDiffJacobian(h, x, base, obj.fdStep, obj.fdType, ...
                                           obj.jacPattern, obj.fdLb, obj.fdUb);
                end
                Jc   = J(1:obj.mInl, :);
                Jceq = J(obj.mInl+1:end, :);
            end
            obj.costModel.tick(toc(t0));

            obj.JIVal = [obj.Aineq;  Jc];
            obj.JEVal = [obj.Aeqlin; Jceq];
            obj.xj = x;

            % --- Initialize or refresh Broyden approximation ---
            if obj.enableBroyden || obj.costModel.tooExpensive(obj.costThreshold)
                Jstacked = [Jc; Jceq];
                if isempty(obj.broyden_)
                    obj.broyden_ = eval_BroydenJacobian( ...
                        Jstacked, obj.broydenMaxStale, obj.broydenTol);
                else
                    obj.broyden_.setExact(Jstacked);
                end
                [cnl2, ceqnl2] = obj.evalNonlinear(x);
                obj.cNlAtJac_ = [cnl2(:); ceqnl2(:)];
                obj.xAtJac_   = x;
            end

            JE = obj.JEVal;  JI = obj.JIVal;
        end
    end

    methods (Access = private)
        function [c, ceq] = evalNonlinear(obj, x)
        %EVALNONLINEAR  Evaluate the raw nonlinear constraints.
        %   [c, ceq] = evalNonlinear(obj, x) calls nlcon and returns the
        %   nonlinear inequality and equality values as columns, or empty
        %   columns when no nonlinear constraint is defined.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 evaluation point.
        %
        %   Outputs:
        %     c   - mInl-by-1 nonlinear inequality values.
        %     ceq - mEnl-by-1 nonlinear equality values.
            if isempty(obj.nlcon)
                c = zeros(0,1);  ceq = zeros(0,1);
            else
                [c, ceq] = obj.nlcon(x);
                c = c(:);  ceq = ceq(:);
            end
        end
        function v = evalNonlinearStacked(obj, x)
        %EVALNONLINEARSTACKED  Stacked nonlinear constraints for differencing.
        %   v = evalNonlinearStacked(obj, x) returns [c; ceq] as a single column,
        %   the vector function differenced when forming the nonlinear Jacobian.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 evaluation point.
        %
        %   Outputs:
        %     v - (mInl+mEnl)-by-1 stacked nonlinear constraint values.
            [c, ceq] = obj.evalNonlinear(x);
            v = [c(:); ceq(:)];
        end
        function v = linIneq(obj, x)
        %LININEQ  Linear inequality residual A*x - b.
        %   v = linIneq(obj, x) returns Aineq*x - bineq, or an empty column when
        %   there are no linear inequalities.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 evaluation point.
        %
        %   Outputs:
        %     v - mIlin-by-1 linear inequality residual.
            if isempty(obj.Aineq), v = zeros(0,1); else, v = obj.Aineq*x - obj.bineq; end
        end
        function v = linEq(obj, x)
        %LINEQ  Linear equality residual Aeq*x - beq.
        %   v = linEq(obj, x) returns Aeqlin*x - beqlin, or an empty column when
        %   there are no linear equalities.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - n-by-1 evaluation point.
        %
        %   Outputs:
        %     v - mElin-by-1 linear equality residual.
            if isempty(obj.Aeqlin), v = zeros(0,1); else, v = obj.Aeqlin*x - obj.beqlin; end
        end
        function k = numFDevals(obj, ~)
        %NUMFDEVALS  Number of function evaluations for a finite-diff gradient.
        %   k = numFDevals(obj, x) returns 2*n for central differences and n for
        %   forward differences. The second argument is ignored.
        %
        %   Inputs:
        %     obj - the Evaluator handle object.
        %     x   - (ignored) evaluation point placeholder.
        %
        %   Outputs:
        %     k - number of extra objective evaluations used by the gradient.
            if strcmp(obj.fdType, 'central'), k = 2*obj.n; else, k = obj.n; end
        end
    end

    methods (Static, Access = private)
        function v = getOpt(opts, field, default)
        %GETOPT  Option-struct lookup with a fallback default.
        %   v = getOpt(opts, field, default) returns opts.(field) when it is
        %   present and non-empty, otherwise DEFAULT.
        %
        %   Inputs:
        %     opts    - options struct.
        %     field   - char field name to look up.
        %     default - value returned when the field is absent or empty.
        %
        %   Outputs:
        %     v - the resolved option value.
            if isfield(opts, field) && ~isempty(opts.(field))
                v = opts.(field);
            else
                v = default;
            end
        end
    end
end

function J = transposeOrEmpty(G, m, n)
%TRANSPOSEOREMPTY  Convert fmincon-convention gradients to an m-by-n Jacobian.
%   J = transposeOrEmpty(G, m, n) transposes the user gradient matrix G (whose
%   columns are constraints, n-by-m in fmincon convention) into the m-by-n
%   Jacobian used internally, or returns an m-by-n zero matrix when G is empty.
%
%   Inputs:
%     G - n-by-m gradient matrix in fmincon convention, or empty.
%     m - number of constraints (rows of the result).
%     n - number of variables (columns of the result).
%
%   Outputs:
%     J - m-by-n Jacobian.
% fmincon derivative convention: columns are constraints (n-by-m). Return m-by-n.
if isempty(G)
    J = zeros(m, n);
else
    J = G.';
end
end

function hMax = maxFeasibleStep(x0, svec, lb, ub)
%MAXFEASIBLESTEP  Largest h with both x0 + h*svec and x0 - h*svec inside [lb,ub].
%   Since the calibration sweep is symmetric, each coordinate is limited by the
%   NEARER of its two bounds regardless of the sign of svec(i); coordinates with
%   svec(i) == 0 never move and impose no limit.
%
%   Inputs:
%     x0   - n-by-1 base point (assumed already inside the box).
%     svec - n-by-1 probe direction.
%     lb   - n-by-1 lower bounds, or empty for none.
%     ub   - n-by-1 upper bounds, or empty for none.
%
%   Outputs:
%     hMax - largest feasible step magnitude (Inf when nothing binds, 0 when the
%            base point is already on a bound in a moving coordinate).
n = numel(x0);
if isempty(lb), lb = -Inf(n,1); end
if isempty(ub), ub =  Inf(n,1); end
room = min(max(x0(:) - lb(:), 0), max(ub(:) - x0(:), 0));
move = svec(:) ~= 0;
if ~any(move)
    hMax = Inf;
else
    hMax = min(room(move) ./ abs(svec(move)));
end
end

function v = getfielddef(s, field, default)
%GETFIELDDEF  Struct field lookup with a fallback default.
%   Used for problem.lb/ub, which the tests construct directly and may omit.
if isstruct(s) && isfield(s, field)
    v = s.(field);
else
    v = default;
end
end
