function [x, fval, exitflag, output, lambda, grad, hessian] = ...
        solve(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, options)
%SOLVE Constrained nonlinear optimization (fmincon-compatible interface).
%   [x,fval,exitflag,output,lambda,grad,hessian] =
%       adamnlopt.solve(fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options)
%
%   Solves  min f(x)  s.t.  A*x<=b, Aeq*x=beq, c(x)<=0, ceq(x)=0, lb<=x<=ub
%   using a primal-dual interior-point / trust-region / SQP hybrid. Trailing
%   arguments are optional; pass [] to skip. OPTIONS accepts an optimoptions
%   object or a struct (fmincon or adamnlopt field names). See defaultOptions.
%
%   NOTE: this build implements the equality-constrained Newton-KKT core.
%   Bounds and inequalities are added in the interior-point stage.
%
%   Inputs:
%     fun     - objective function handle @(x) f or @(x) [f,g].
%     x0      - n-by-1 initial point.
%     A, b    - linear inequality constraints A*x <= b (optional, [] to skip).
%     Aeq,beq - linear equality constraints Aeq*x = beq (optional, [] to skip).
%     lb, ub  - lower/upper bounds on x (optional, [] to skip; may be -/+Inf).
%     nonlcon - nonlinear constraint handle @(x) [c,ceq] (or with gradients);
%               c(x) <= 0 and ceq(x) = 0 (optional, [] to skip).
%     options - optimoptions object or struct of fmincon/adamnlopt fields
%               (optional, [] uses defaults). See defaultOptions.
%
%   Outputs:
%     x        - n-by-1 solution.  On a convergence exit this is the final
%                iterate; on a limit exit it follows opts.returnIterate
%                ('last', the default, or 'bestKKT'); on a divergence exit it is
%                the most feasible iterate seen.
%     fval     - objective value f(x) at the solution.
%     exitflag - termination code: >0 converged, 0 max iterations,
%                -1 stopped by the iteration function (user request),
%                -2 no feasible point found (local infeasibility),
%                -3 divergence (the most feasible iterate is returned).
%     output   - struct with iterations, funcCount, firstOrderOpt,
%                constrViolation, complementarity, message, and diagnostics.
%     lambda   - struct of Lagrange multipliers (lower, upper, eqlin,
%                eqnonlin, ineqlin, ineqnonlin).
%     grad     - n-by-1 objective gradient at the solution.
%     hessian  - n-by-n Lagrangian Hessian (model) at the solution.
%
%   See also DEFAULTOPTIONS, MAPOPTIONS, VALIDATEPROBLEM, EVALUATOR.

import adamnlopt.*

if nargin < 3,  A = [];        end
if nargin < 4,  b = [];        end
if nargin < 5,  Aeq = [];      end
if nargin < 6,  beq = [];      end
if nargin < 7,  lb = [];       end
if nargin < 8,  ub = [];       end
if nargin < 9,  nonlcon = [];  end
if nargin < 10, options = [];  end

opts = mapOptions(options);
if isempty(opts.muMin), opts.muMin = 0.1 * opts.optTol; end
% compTol defaults to optTol so a tightened optTol actually buys accuracy.  The
% barrier biases the solution off the true optimum by O(mu) -- at a bound-free
% minimizer the stationarity row reads g_i = zL_i - zU_i with zL_i ~ mu/(x_i-lb_i),
% so x_i is displaced by roughly mu/(2*(x_i-lb_i)) for a quadratic.  The barrier
% schedule only drives mu down while some residual still exceeds its tolerance, so
% comp <= compTol is what sets the FLOOR on mu, and hence the floor on that
% displacement.  With compTol pinned at 1e-6 while optTol was tightened to 1e-9,
% mu stalled at 2.5e-9 and left x2 = 2.005e-3 against a true 2e-3 (rel 2.6e-3):
% the solve reported exitflag 1 at optTol 1e-9 while being nowhere near that
% accurate, because the limiting error was never measured by opt at all.  Tying
% the default to optTol makes "tighten optTol" mean what a caller expects; an
% explicit compTol is still honoured verbatim.
if isempty(opts.compTol), opts.compTol = opts.optTol; end

problem = validateProblem(fun, x0, A, b, Aeq, beq, lb, ub, nonlcon, opts);

% --- Fixed-variable elimination (transparent; see reduceProblem/expandResult) ---
% A variable with lb(i) == ub(i) has no interior for the log-barrier to live in,
% so it is substituted out and the solver runs on the free variables only.  This
% happens BEFORE scaling so the reduction sees the user's own units (and so the
% wrapped HessianFcn stays in the space its author wrote it for), and outputs are
% mapped back by expandResult at the very end.  Identity when nothing is fixed.
[solveProblem0, fx, opts] = reduceProblem(problem, opts);
if fx.applied && fx.nr == 0
    % Everything is fixed: there is no optimization left, only a feasibility
    % question.  The solver cores cannot run at n = 0, so answer it directly.
    [x, fval, exitflag, output, lambda, grad, hessian] = ...
        allFixedResult(problem, fx, opts);
    return;
end

% --- Automatic problem scaling (transparent; see computeScaling/scaleProblem) ---
% Measure scale factors at x0 from a probe Evaluator, then run the solver on a
% scaled problem so poorly conditioned KKT systems (the usual cause of a frozen
% barrier parameter / stalled solve) do not require the user to hand-normalise.
% Outputs are mapped back to physical units by unscaleResult below.
evProbe = Evaluator(solveProblem0, opts);
sc = computeScaling(solveProblem0, evProbe, opts);
if sc.applied
    solveProblem = scaleProblem(solveProblem0, sc);
    ev = Evaluator(solveProblem, opts);
else
    solveProblem = solveProblem0;
    ev = evProbe;
end

% --- Automatic finite-difference step calibration (transparent; see
% estimateNoise/Evaluator.calibrateStep) ---
% Estimate the objective/constraint noise level at x0 and set the FD step (and
% forward/central scheme) so the differencing error is minimised.  The default
% step sqrt(eps) assumes machine-precision function values; a simulation-based
% objective (e.g. ODE integration) has a much larger noise floor that makes that
% step far too small, producing the classic noisy-gradient optimality plateau.
%
% Calibrate on evProbe -- the PHYSICAL-space Evaluator.  Auto-scaling divides the
% constraint/objective values by their magnitude, which also divides their noise
% down toward round-off, so the noise is only reliably measurable in physical
% units.  The estimated step is a scalar base step that finiteDiffGradient scales
% per coordinate by max(1,|x_i|); because the variable scale Dx is itself ~|x0|,
% that base step is unit-consistent in either space, so we copy the calibrated
% fdStep/fdType onto the scaled solver Evaluator ev.
if isfield(opts,'autoFDStep') && opts.autoFDStep
    try
        output_calib = evProbe.calibrateStep(solveProblem0.x0);
        ev.fdStep = evProbe.fdStep;
        ev.fdType = evProbe.fdType;
    catch
        output_calib = [];   % advisory: never let calibration failure stop the solve
    end
else
    output_calib = [];
end

% Scale-consistent optimality weight.  The solver runs in variable-scaled space
% (x = Dx.*xs), so the scaled stationarity residual is rd_s = Dx.*rd_phys: a wide
% Dx spread (here 1..4.5e4 for km-positions vs O(1) control angles) makes the raw
% scaled inf-norm ||rd_s||_inf, and the plain 2-norm least-squares multiplier
% estimate JE'\bLS, both dominated by the large-scale rows -- they minimise the
% big state rows and abandon the reduced gradient at a small-scale control
% variable, stranding the reported optimality on a physically-converged point.
% Weighting by 1./Dx measures stationarity and fits the multipliers in
% physical-gradient units, so every variable gets equal footing.  In 'curvature'
% mode the scaled gradient is additionally wf*drs and the same physical-unit
% weight is 1./(wf*Dx).  Inert (all ones) when scaling is off, so well-scaled
% problems are unchanged.
solveProblem.optScaleW = 1 ./ (sc.wf * sc.Dx);

hasIneq   = ev.mI > 0;
hasBounds = any(isfinite(solveProblem.lb)) || any(isfinite(solveProblem.ub));

% --- Echo the problem summary and non-default options before the first iteration ---
% The iteration table starts below, with the header print inside the chosen
% core.  When Display is not 'off', open the console with the problem being
% solved (variable/constraint counts, derivatives, scaling) followed by the
% non-default settings in effect, so the configuration that produced the
% numbers is visible before the first row.  Purely cosmetic -- never affects
% the solve.
if ~strcmpi(opts.Display, 'off')
    if hasIneq || hasBounds
        core = 'interior-point';
    else
        core = 'equality';
    end
    util_echoProblem(problem, fx, sc, ev, opts, core);
    util_echoOptions(opts);
end

if hasIneq || hasBounds
    [x, fval, exitflag, output, lambda, grad, hessian] = ...
        solveInteriorPoint(ev, solveProblem, opts, sc, fx, problem);
else
    [x, fval, exitflag, output, lambda, grad, hessian] = ...
        solveEqualityCore(ev, solveProblem, opts, sc, fx, problem);
end

% --- Map scaled-space results back to physical units and record the scaling ---
[x, fval, grad, hessian, lambda] = unscaleResult(x, fval, grad, hessian, lambda, sc);
output.scaling = sc;
output.fdCalibration = output_calib;
if sc.applied && isfield(output,'funcCount')
    output.funcCount = output.funcCount + evProbe.nFun;  % count the x0 probe
end

% --- Re-index onto the original variables when fixed ones were eliminated ---
% After unscaling, so expandResult works in the user's units throughout (the
% analytic-gradient fill for the fixed rows calls the user's own objective).
[x, grad, hessian, lambda, output] = ...
    expandResult(x, grad, hessian, lambda, output, fx, problem);

% --- Convergence advisor: on a non-converged solve, print a short diagnosis ---
if exitflag <= 0 && isfield(opts,'Display') && ~strcmpi(opts.Display,'off')
    try
        diagnose(output, opts.LogFile);
    catch
        % advisory only: never let diagnostics failure mask the solve result
    end
end
end

% ------------------------------------------------------------------------
function [x, fval, exitflag, output, lambda, grad, hessian] = ...
        solveEqualityCore(ev, problem, opts, sc, fx, probOrig)
%SOLVEEQUALITYCORE  Equality-constrained Newton-KKT / SQP solver core.
%   Iterates a Newton-KKT step (optionally Byrd-Omojokun normal+tangential when
%   opts.useNTdecomp) globalized by an l1-merit line search or a filter, with a
%   feasibility restoration phase. Used when the problem has no bounds and no
%   inequality constraints.
%
%   Inputs:
%     ev      - Evaluator providing objective/constraint values and Jacobians.
%     problem - validated problem struct (x0, bounds, constraint counts).
%     opts    - resolved options struct (see defaultOptions).
%     sc      - scaling struct from COMPUTESCALING (identity when scaling off);
%               used only to unscale the per-iteration plot info.
%     fx      - fixed-variable reduction map (identity when nothing is fixed);
%               used only to re-index the plot info onto the original variables.
%     probOrig - the ORIGINAL (unreduced, unscaled) problem struct, used only
%               for the plot info's linear rows and bounds.
%
%   Outputs:
%     x, fval, exitflag, output, lambda, grad, hessian - as for SOLVE.
import adamnlopt.*

x = problem.x0;
dx = zeros(numel(x), 1);
% Scale-consistent optimality weight (1./Dx; all ones when scaling is off), used
% to measure stationarity and fit the LS costates in physical-gradient units so a
% wide variable-scale spread cannot strand the reported opt (see solveInteriorPoint).
if isfield(problem, 'optScaleW') && ~isempty(problem.optScaleW)
    optW = problem.optScaleW(:);
else
    optW = ones(numel(x), 1);
end
[f, g]   = ev.objective(x);
[cE, ~]  = ev.constraints(x);
[JE, JI] = ev.jacobian(x);
lamE = step_multiplierUpdate(g, JE, optW);

hmodel = makeHessianModel(opts, numel(x));
useFilter = strcmpi(opts.globalization, 'filter');
filt = makeFilter(opts, norm(cE, 1));

util_logger('header', opts.Display, [], opts.LogFile);

exitflag = 0;  msg = 'Stopped: maximum iterations reached.';
alpha = 0;  hessian = [];  res = [];  rho = 1;  restTheta = inf;
% Iteration-hook visibility: the step quantities must exist (as zero/NaN
% placeholders) at iteration 0, before any step has been computed, so the
% per-iteration info struct can describe the last accepted step uniformly.
dlamE = zeros(numel(lamE), 1);  aLamE = 0;
ksolve = struct('Fprev', [], 'etaPrev', [], 'reg', []);
history = struct('theta', zeros(0,1), 'alpha', zeros(0,1));
Delta = opts.delta0;
trace = makeTrace(opts, opts.maxIter);
if ~isempty(trace)
    trace.setMeta('core', 'eq');
    trace.setMeta('n', numel(x));  trace.setMeta('mE', numel(lamE));
    trace.setMeta('mI', 0);
    trace.setMeta('dualCondProbeMaxDim', opts.dualCondProbeMaxDim);
    trace.setMeta('schurProbeApplies', ...
                  numel(lamE) > 0 && numel(lamE) <= opts.dualCondProbeMaxDim);
end
tStart = tic;
warnedPlot = false;   % plot-hook error already reported this solve (see firePlots)
warnedIter = false;   % iteration-function error already reported this solve
for iter = 0:opts.maxIter
    trow = struct('iter', iter);
    primaryInfo = [];  nSolves = 0;
    state = makeState(x, lamE, f, g, cE, JE, JI, iter, ev.nFun, alpha);
    res = kkt_residual(state);
    % Report/terminate on the scale-consistent optimality norm (rStat stays raw
    % for the Newton-step RHS).  Inert when scaling is off (optW all ones).
    res.opt = util_norms(optW .* res.rStat);

    advice = modeAdvice(state, res, history, opts);
    state.mode = modeLabel(advice.mode, 'eq');
    if strcmp(opts.Display, 'iter-debug')
        % Debug columns for the equality core.  The barrier ratio, active-bound
        % count, and costate-refresh flag do not exist here (no barrier, no
        % bounds, no IP multiplier refresh), so they are NaN and print as a dash.
        dbg = struct('optRaw', util_norms(res.rStat), ...
                     'optScaled', res.opt / kktScaleFactor(state), ...
                     'normLamE', norm(lamE, inf), ...
                     'gateRatio', NaN, 'nActiveBnd', NaN, 'lsAdopted', NaN);
    else
        dbg = [];
    end
    logState(state, res, opts, toc(tStart), dbg);

    trow.nFun = ev.nFun;   trow.f = f;      trow.mu = 0;
    trow.feas = res.feas;  trow.comp = res.comp;
    trow.optPrinted = res.opt;
    trow.optRaw     = util_norms(res.rStat);
    trow.optScaled  = res.opt / kktScaleFactor(state);
    trow.normLamE = norm(lamE, inf);   trow.normX = norm(x, inf);
    trow.filterSize = filterCardinality(filt);

    [stop, ef, m] = terminationCheck(state, res, opts);

    % Per-iteration plot hooks (user PlotFcn and/or the built-in uifigure
    % plot).  Fired after the termination test but before the stop branch so
    % the TERMINAL iterate also fires, carrying its stop/exitflag/message;
    % errors are caught inside firePlots and never alter the solve.  stepsize
    % is the last accepted step in physical units (0 at the starting iterate,
    % where dx/alpha are the loop initializers).  The user IterationFcn fires
    % on the same cadence with a strictly richer info struct (the raw internal
    % state of the iterate, see iterationInfo); its errors are caught inside
    % fireIterationFcns and never alter the solve either.  A callback that
    % returns truthy requests a stop: the solve terminates at the current
    % iterate with exitflag -1, unless the solver is already stopping on this
    % iteration, in which case the natural reason stands.
    if opts.Plot || ~isempty(opts.PlotFcn) || ~isempty(opts.IterationFcn)
        stepsize = state.alpha * norm(sc.Dx .* dx);
        info = plotInfo(state, res, sc, fx, probOrig, opts, toc(tStart), ...
                        stepsize, stop, ef, m);
        warnedPlot = firePlots(warnedPlot, opts, info);
        if ~isempty(opts.IterationFcn)
            extras = struct('dx', dx, 'dlamE', dlamE, 'ds', [], 'dlamI', [], ...
                            'dzL', [], 'dzU', [], 'aP', alpha, 'aD', NaN, ...
                            'aLamE', aLamE, 'Delta', Delta, 'tau', NaN, ...
                            'rho', rho, 'advice', advice, 'nActiveBnd', 0, ...
                            'lsAdopted', 0, 'lsFired', 0);
            info = iterationInfo(info, state, res, probOrig, opts, extras);
            [warnedIter, stopIter, info] = ...
                fireIterationFcns(warnedIter, opts, info);
            if stopIter && ~stop
                stop = true;  ef = -1;  m = info.message;
            end
        end
    end

    if stop
        % Record the terminal iterate before breaking: it is the converged point
        % and the one row a reader always wants.
        trow = mergeInto(trow, modelSnapshot(hmodel));
        recordTrace(trace, trow);
        exitflag = ef;  msg = m;  break;
    end

    if opts.modeSwitch
        Delta = min(Delta * advice.deltaFactor, opts.deltaMax);
    end

    H = currentHessian(hmodel, ev, x, lamE, zeros(0,1), opts);
    state.H = H;  hessian = H;

    if opts.useNTdecomp
        theta0 = norm(cE, 1);  phi0 = f;
        % Switching condition threshold (Waechter-Biegler): steps from a
        % near-feasible point are f-type steps — accept on TR ratio alone,
        % no filter augmentation (analogous to globalize_filterLineSearch line 35).
        thetaMinNT = 1e-4 * max(1, theta0);
        [JE_eff, cE_eff] = augmentForNearBoundary( ...
            JE, cE, zeros(0, numel(x)), zeros(0,1), advice, state, opts);
        stepAccepted = false;  alpha = 1;
        dx = zeros(numel(x),1);  dlamE = zeros(numel(lamE),1);
        for trIter = 1:opts.trMaxInner                                          %#ok<FORPERM>
            [dx, dlamE, predRed_nt] = computeNTStep(H, g, JE_eff, cE_eff, Delta, lamE);
            xt = x + dx;
            ft = ev.objective(xt);
            [cEt, ~] = ev.constraints(xt);
            theta_t = norm(cEt, 1);
            isSwitching = useFilter && (theta0 <= thetaMinNT);
            if isSwitching
                ok = true;          % near-feasible: TR ratio alone governs
            elseif useFilter
                ok = filt.isAcceptable(theta_t, ft);
            else
                rho   = max(rho, norm(lamE + dlamE, inf) + 1e-2);
                phi0m = globalize_meritFunction(f, theta0, rho);
                phi_tm = globalize_meritFunction(ft, theta_t, rho);
                dphi  = (g.' * dx) - rho * theta0;
                ok = globalize_meritAccept(phi0m, phi_tm, dphi, 1);
            end
            actRed = phi0 - ft;
            [Delta, tr_ok, ~] = control_trustRegionUpdate( ...
                Delta, predRed_nt, actRed, norm(dx), opts);
            if ok && tr_ok
                % Augment filter for theta-type steps only (infeasible region).
                % Switching (f-type) steps do not augment — mirroring the
                % no-augment branch in globalize_filterLineSearch.
                if useFilter && ~isSwitching
                    filt.augment(theta0, phi0);
                end
                stepAccepted = true;
                break;
            end
        end
        if ~stepAccepted
            % If the NT step collapsed (near-optimal, predRed<=0, ||dx||≈0),
            % compute a proper KKT step for the line search instead.
            if norm(dx) < opts.stepTol * 10
                [d, idx_fb, ksolve] = detectStep(state, res, numel(x), numel(lamE), opts, ksolve);
                primaryInfo = ksolve.last;
                nSolves = nSolves + 1;
                dx    = d(idx_fb.x);
                dlamE = d(idx_fb.lamE);
            end
            [alpha, rho] = lineSearch(ev, x, dx, f, g, cE, lamE + dlamE, rho);
        end
    else
        [d, idx, ksolve] = detectStep(state, res, numel(x), numel(lamE), opts, ksolve);
        primaryInfo = ksolve.last;
        nSolves = nSolves + 1;
        trow.condK = traceCondK(trace, state, ksolve.reg);
        dx    = d(idx.x);
        dlamE = d(idx.lamE);
        if useFilter
            theta0 = norm(cE, 1);  phi0 = f;  gd = g.' * dx;
            pt = @(a) phiThetaEq(ev, x, dx, a);
            [alpha, augment, rho] = globalize_filterLineSearch( ...
                pt, phi0, theta0, gd, filt, rho, 1, ...
                thetaGrowCap(theta0, opts), norm(lamE + dlamE, inf));
            if augment, filt.augment(theta0, phi0); end
        else
            [alpha, rho] = lineSearch(ev, x, dx, f, g, cE, lamE + dlamE, rho);
        end
    end

    needRestoration = opts.enableRestoration && norm(cE, 1) > opts.feasTol && ...
        (alpha <= 1e-10 || advice.suggestRestore);
    if needRestoration
        % Same reasoning as the IP core: this path CONTINUEs or BREAKs past the
        % foot-of-loop record, so record here or lose the row entirely.
        trow = finishTraceRow(trow, primaryInfo, [], alpha, NaN, NaN, rho, ...
                              Delta, false, nSolves, 0, 1);
        recordTrace(trace, trow);
        [x, rinfo] = degeneracy_restorationPhase(ev, x, problem.lb, problem.ub, opts);
        if rinfo.theta > opts.feasTol && ...
                (~rinfo.reduced || rinfo.theta >= restTheta - opts.feasTol)
            exitflag = -2;
            msg = 'No feasible point found (local infeasibility).';
            break;
        end
        restTheta = rinfo.theta;
        [f, g]  = ev.objective(x);
        [cE, ~] = ev.constraints(x);
        [JE, ~] = ev.jacobian(x);
        lamE = step_multiplierUpdate(g, JE);
        if useFilter, filt.reset(); end
        Delta = opts.delta0;
        alpha = 0;
        continue;
    end

    gOld = g;  JEold = JE;
    x    = x + alpha * dx;
    % Fix B: cap the equality-multiplier increment (dual trust region); the
    % primal step keeps alpha.  Bounds the dlamE blowup from a near-singular
    % Schur complement without throttling primal progress.
    aLamE = dualStepCoeff(alpha, dlamE, lamE, opts);
    lamE = lamE + aLamE * dlamE;
    [f, g]  = ev.objective(x);
    [cE, ~] = ev.constraints(x);
    [JE, ~] = ev.jacobian(x);
    hinfo = updateHessianModel(hmodel, gOld, JEold, [], g, JE, [], ...
                               lamE, zeros(0,1), alpha * dx);
    ksolve = warnBfgsReset(ksolve, opts, hinfo, iter);
    history = pushHistory(history, norm(cE, 1), alpha, opts);

    % The equality core has no dual fraction-to-boundary rule, so aD is not a
    % quantity here; aLamE is measured against the primal alpha instead.
    trow = finishTraceRow(trow, primaryInfo, hinfo, alpha, alpha, aLamE, rho, ...
                          Delta, false, nSolves, 0, 0);
    recordTrace(trace, trow);
end

fval = f;  grad = g;
output = makeOutput(state, res, ev, exitflag, msg);
if ~isempty(hmodel), output.hessianModel = hmodel; end   % secant model diagnostics
if ~isempty(trace), output.trace = trace.toStruct(); end % per-iteration trajectory
lambda = makeLambda(ev, lamE, zeros(0,1), zeros(numel(x),1), zeros(numel(x),1));
util_logger('final', opts.Display, output, opts.LogFile);
end

% ------------------------------------------------------------------------
function [x, fval, exitflag, output, lambda, grad, hessian] = ...
        solveInteriorPoint(ev, problem, opts, sc, fx, probOrig)
%SOLVEINTERIORPOINT Primal-dual interior-point core for bounds/inequalities.
%   Barrier-perturbed KKT system solved by a condensed Newton step in
%   (dx, dlamE); slacks, inequality multipliers, and bound multipliers are
%   recovered by back-substitution. A fraction-to-boundary rule keeps
%   (s, x-l, u-x, lamI, zL, zU) strictly positive; a log-barrier l1 merit line
%   search globalizes; the barrier parameter mu is driven to zero.
%
%   Inputs:
%     ev      - Evaluator providing objective/constraint values and Jacobians.
%     problem - validated problem struct (n, bounds, constraint counts).
%     opts    - resolved options struct (see defaultOptions).
%     sc      - scaling struct from COMPUTESCALING (identity when scaling off);
%               used only to unscale the per-iteration plot info.
%     fx      - fixed-variable reduction map (identity when nothing is fixed);
%               used only to re-index the plot info onto the original variables.
%     probOrig - the ORIGINAL (unreduced, unscaled) problem struct, used only
%               for the plot info's linear rows and bounds.
%
%   Outputs:
%     x, fval, exitflag, output, lambda, grad, hessian - as for SOLVE.
import adamnlopt.*

n  = problem.n;
lb = problem.lb;  ub = problem.ub;
finL = isfinite(lb);  finU = isfinite(ub);
mE = ev.mE;
dx = zeros(n, 1);

% Scale-consistent optimality weight (1./Dx; all-ones when scaling is off).  Used
% to measure stationarity and fit the LS costates in physical-gradient units so a
% wide variable-scale spread cannot strand the reported opt on a converged point.
if isfield(problem, 'optScaleW') && ~isempty(problem.optScaleW)
    optW = problem.optScaleW(:);
else
    optW = ones(n, 1);
end

st = initializeIterate(ev, problem, opts);
x = st.x;  s = st.s;
lamE = st.lamE;  lamI = st.lamI;
zL = st.zL;  zU = st.zU;
zL(~finL) = 0;  zU(~finU) = 0;
mu = st.mu;

[f, g]   = ev.objective(x);
[cE, cI] = ev.constraints(x);
[JE, JI] = ev.jacobian(x);

hmodel = makeHessianModel(opts, n);
useFilter = strcmpi(opts.globalization, 'filter');
filt = makeFilter(opts, norm([cE; cI + s], 1));

util_logger('header', opts.Display, [], opts.LogFile);

rho = 1;  alpha = 0;  hessian = [];  res = [];  state = [];  restTheta = inf;
exitflag = 0;  msg = 'Stopped: maximum iterations reached.';
ksolve = struct('Fprev', [], 'etaPrev', [], 'reg', []);
history = struct('theta', zeros(0,1), 'alpha', zeros(0,1));
Delta = opts.delta0;
% Iteration-hook visibility: the step quantities must exist (as zero/NaN
% placeholders) at iteration 0, before any step has been computed, so the
% per-iteration info struct can describe the last accepted step uniformly.
dlamE = zeros(mE, 1);  ds = zeros(size(s));  dlamI = zeros(size(lamI));
dzL = zeros(n, 1);  dzU = zeros(n, 1);
aD = 0;  aLamE = 0;  tau = 0;
bestFeas = inf;  feasStallCount = 0;  % main-iteration feasibility-stall tracker
feasRegressCount = 0;                 % consecutive iters with feasibility blown up
bestSnapFeas = inf;  bestSnapF = inf;  bestSnap = [];  % best-iterate snapshot
bestKKTopt = inf;  bestKKT = [];       % best-KKT snapshot (see the limit exit)
keepBestKKT = strcmpi(opts.returnIterate, 'bestKKT');  % opt-in; default is 'last'
fPrevObj = f;    objStallCount = 0;    % objective-plateau tracker (see terminationCheck)
optGateCount = 0;                     % consecutive iters inside objPlateauOptTol
trace = makeTrace(opts, opts.maxIter);
if ~isempty(trace)
    trace.setMeta('core', 'ip');
    trace.setMeta('n', n);  trace.setMeta('mE', mE);  trace.setMeta('mI', ev.mI);
    trace.setMeta('dualCondProbeMaxDim', opts.dualCondProbeMaxDim);
    trace.setMeta('schurProbeApplies', mE > 0 && mE <= opts.dualCondProbeMaxDim);
end
tStart = tic;
warnedPlot = false;   % plot-hook error already reported this solve (see firePlots)
warnedIter = false;   % iteration-function error already reported this solve
for iter = 0:opts.maxIter
    trow = struct('iter', iter);
    % Reset the per-iteration step provenance every pass, not only on the branch
    % that sets it.  The NT-decomp path never assigns primaryInfo, and a stale
    % value from the previous iteration is worse than no value at all: it would
    % read as a plausible row rather than an obviously missing one.
    primaryInfo = [];  nSolves = 0;  socAdopted = 0;
    dxl = x - lb;  dxu = ub - x;

    % --- Active-bound handling (Fix F row exclusion + Fix G bound-dual repair) ---
    % A variable pinned at a bound (bang-bang/bang-off control) has its
    % stationarity carried by the bound multiplier, not the equality costate.  As
    % the gap collapses the barrier bound dual zL=mu/(x-lb) lags its true active
    % value, leaving a large residual on that row that (1) the costate refresh
    % tries to cancel with lamE (-> lamE blows up in JE's left-null space) and
    % (2) dominates the reported opt metric.  Build a mask of near-active bound
    % variables; Fix F excludes those rows from the fit and the metric.
    % (A companion "Fix G" that re-estimated the bound dual zL/zU on these rows for
    % the metric was verified INERT -- see dbgVerifyFG: G-only was bit-identical to
    % baseline, BOTH bit-identical to F-only -- and removed per verify-each-contributes.)
    activeBnd = false(n,1);
    if opts.activeBoundGapTol > 0
        % Normalize the bound gap by a RELATIVE reference.  max(1,|x|) floors the
        % denominator at 1, which silently turns this into an ABSOLUTE test for
        % every variable with |x| < 1: a variable at x = 1.1e-4 with lb = 0 is
        % 100% of its own magnitude away from the bound -- maximally interior --
        % yet gets relL = 1.1e-4 < 1e-3 and is declared pinned.  Its stationarity
        % row is then masked out of the reported opt, so the solver declares
        % convergence while that row still carries a large residual (observed:
        % optRaw 3.8e-3 reported as opt 5.8e-11).  Scale instead by the
        % variable's own magnitude, falling back to the box width (then to 1) so
        % a variable legitimately sitting AT zero still has a finite reference.
        ref = abs(x);
        boxW = ub - lb;
        useBox = ~(ref > 0) & isfinite(boxW) & boxW > 0;
        ref(useBox) = boxW(useBox);
        ref(~(ref > 0)) = 1;
        relL = inf(n,1);  relU = inf(n,1);
        relL(finL) = dxl(finL) ./ ref(finL);
        relU(finU) = dxu(finU) ./ ref(finU);
        activeBnd(finL) = activeBnd(finL) | (relL(finL) < opts.activeBoundGapTol);
        activeBnd(finU) = activeBnd(finU) | (relU(finU) < opts.activeBoundGapTol);
    end

    % Least-squares equality-multiplier (costate) refresh.  When the Newton-
    % accumulated lamE lags the moving primal iterate, dual infeasibility is
    % dominated by (JE'*lamE).  Re-estimate lamE as the least-squares multipliers
    % that best cancel the current gradient (holding zL, zU, lamI fixed):
    %   JE' * lamE = -(g - zL + zU + JI'*lamI).
    % JE is full row rank here, so this is a cheap sparse-QR solve; adopt it only
    % if it does not increase the (inf-norm) dual infeasibility (the guard below).
    %
    % Gate: fire only when the dual residual DOMINATES primal feasibility
    % (opt > lsRefreshDomRatio*feas), i.e. a costate-lag stall is what is holding
    % the KKT residual up.  This replaces the old absolute feasibility threshold
    % (norm(cE,inf) < lsRefreshFeasTol), which created a gate-coupling deadlock:
    % the refresh could not fire until feas fell below the threshold, but with the
    % costates frozen opt stayed huge, so the barrier stayed high and the solver
    % ground in feasibility mode never reaching the threshold.  The dominance test
    % is scale-relative (no magic tolerance to tune), unsticks that deadlock, and
    % stays quiet during a genuine feasibility drive (feas dominates) so the BFGS
    % secant history is not corrupted by a jumping lamE.  The adopt-only-if-lower
    % guard still ensures the refresh can never raise the dual infeasibility.
    %
    % P2: snapshot the equality multipliers in effect at this (old) iterate
    % BEFORE the refresh may replace them.  The foot-of-loop secant pair must be
    % formed at the multipliers the iterate actually followed: when the refresh
    % adopts, its jump (lamE_ls - lamE) is a dual correction, not curvature, and
    % evaluating y at the jumped lamE injects that jump into the model.  Forming
    % the pair at lamE_pair keeps y a genuine sample of the curvature along s.
    lamE_pair = lamE;
    lsAdopted = false;
    if opts.lsMultiplierRefresh && mE > 0
        bLS = g - zL + zU;
        if ev.mI > 0, bLS = bLS + JI.' * lamI; end
        % Fix F: fit ONLY over rows whose variable is not pinned at a bound.  A
        % pinned variable's stationarity is carried by its bound dual, not lamE;
        % including that row forces the fit to cancel a lagging-bound-dual residual
        % with the equality costate (which cannot represent it -> lamE blows up in
        % JE's left-null space).  Excluding it is the EXCL counterfactual proven to
        % collapse the fit residual 27->1e-3 and the costate 3e6->3e2.  fitRows is
        % all-true when nothing is pinned, so interior/unconstrained fits are
        % identical to before.
        fitRows = ~activeBnd;
        if opts.excludeActiveBoundRows && any(activeBnd) && any(fitRows)
            wFit = optW .* fitRows;   % zero-weight the pinned rows
        else
            wFit = optW;
        end
        % Measure and fit in the scale-consistent metric (weight rows by wFit).
        optCur  = norm(wFit .* (bLS + JE.' * lamE), inf);   % weighted dual infeas
        feasCur = norm(cE, inf);
        if ev.mI > 0, feasCur = max(feasCur, norm(cI + s, inf)); end
        trow.lsOptCur = optCur;
        trow.lsFired  = double(optCur > opts.lsRefreshDomRatio * feasCur);
        trow.lsAdopted = 0;
        if optCur > opts.lsRefreshDomRatio * feasCur
            % Weighted least squares: argmin || wFit .* (bLS + JE'*lamE) ||_2, so
            % the fit is not dominated by large-scale rows (which would abandon the
            % reduced gradient at small-scale variables) nor by pinned-bound rows
            % (Fix F).  Rows of JE' and bLS are pre-multiplied by wFit; equivalent
            % to (diag(wFit)*JE')\(-wFit.*bLS).
            %
            % TRUNCATED fit (Fix C): a stiff/near-rank-deficient JE makes this LS
            % ill-posed -- the plain solve loads huge components onto JE's near-
            % null right-singular directions (costates ~1e5-1e6 that add ~0 to
            % JE'*lamE yet wreck a near-converged iterate).  lsqminnorm with a
            % singular-value tolerance smax/dualFitCondMax keeps only the well-
            % conditioned range and drops that toxic near-null tail; on a well-
            % conditioned JE nothing is truncated and it equals the plain solve.
            Aw = JE.' .* wFit;         % (n-by-mE) weighted JE'
            bw = -(wFit .* bLS);
            if isfinite(opts.dualFitCondMax) && opts.dualFitCondMax > 0 && ...
                    mE >= opts.dualFitCondMinEq
                % TRUNCATED fit (Fix C), only for large equality systems.  The
                % truncation protects the near-null TAIL of a large JE' (orbit
                % problems, mE 45-321): dropped directions carry ~0 residual and
                % their retention inflates ||lamE|| to 1e5-1e6.  A small problem
                % has no tail -- with mE = 3 and cond(JE) ~ 4e6, sigma_max/1e4
                % keeps ONLY the top singular direction, the fit must cancel a
                % residual spread across the dropped directions with enormous
                % costates, and the refresh ratchets ||lamE|| 1e3 -> 2.4e6 with
                % the solve failing ef=-2 (verified on the Hohmann transfer;
                % the plain fit below converges in 25-38 iters there).
                sMaxA = normest(Aw, 1e-2);            % cheap sigma_max estimate
                fitTol = sMaxA / opts.dualFitCondMax; % drop sv below this
                lamE_ls = lsqminnorm(Aw, bw, fitTol);
            else
                lamE_ls = lsqminnorm(Aw, bw);
            end
            % Adopt only if it lowers weighted dual infeas AND does not blow up
            % ||lamE|| (growth guard backstop, independent of the cond estimate).
            optNew   = norm(wFit .* (bLS + JE.' * lamE_ls), inf);
            growthOK = ~isfinite(opts.dualFitGrowthMax) || ...
                norm(lamE_ls, inf) <= opts.dualFitGrowthMax * max(1, norm(lamE, inf));
            trow.lsOptNew = optNew;
            % P3 deadband: the re-fit must beat the current weighted dual
            % infeasibility by a relative factor, so noise-level dips cannot
            % toggle lamE between two nearly-equal fits iteration to iteration.
            % In the low-feas endgame the dominance gate fires every iteration,
            % so without the deadband the costates keep jumping at the floor.
            if optNew < opts.lsRefreshDeadband * optCur && growthOK
                lamE = lamE_ls;
                lsAdopted = true;
                trow.lsAdopted = 1;
            end
        end
    end

    % Barrier-free residuals (mu = 0) for the outer termination test.
    rd  = g;
    if mE > 0,     rd = rd + JE.' * lamE;  end
    if ev.mI > 0,  rd = rd + JI.' * lamI;  end
    rd = rd - zL + zU;
    rpE = cE;
    rpI = cI + s;

    % Fix F optimality metric: measure stationarity with pinned-bound rows
    % excluded, so the reported opt is not inflated by a lagging bound dual at an
    % active-bound (bang-bang) variable.  rd itself (the Newton-step RHS) is
    % unchanged, so the primal-dual step is untouched.
    rdMetric = rd;
    optWmetric = optW;
    if opts.excludeActiveBoundRows && any(activeBnd)
        optWmetric = optW .* (~activeBnd);
    end

    state = ipState(x, s, lamE, lamI, zL, zU, f, g, cE, cI, JE, JI, ...
                    iter, ev.nFun, alpha, mu);
    res = ipRes(rd, rpE, rpI, s, lamI, dxl, zL, finL, dxu, zU, finU, optW);
    res.opt = util_norms(optWmetric .* rdMetric);   % Fix F scale-consistent opt

    % The three optimality metrics, side by side.  optPrinted is what the log
    % shows (Fix-F masked, Dx-weighted); optRaw is the unmasked, unweighted
    % residual; optScaled is res.opt/sd, the number terminationCheck gates on.
    % They have never been recorded together, so a scaled-metric artefact --
    % which has precedent on exactly this problem -- could not be distinguished
    % from a genuine stall by any measurement the solver produced.
    trow.optPrinted = res.opt;
    trow.optRaw     = util_norms(rd);
    trow.optScaled  = res.opt / kktScaleFactor(state);
    trow.nActiveBnd = nnz(activeBnd);

    % Update the main-iteration feasibility-progress tracker (see init above).
    % A relative improvement of >0.1% counts as progress; anything less increments
    % the stall counter that gates the restoration-failure ef=-2 declaration.
    if res.feas < bestFeas * (1 - 1e-3)
        bestFeas = res.feas;  feasStallCount = 0;
    else
        bestFeas = min(bestFeas, res.feas);
        feasStallCount = feasStallCount + 1;
    end

    % Divergence tracker: count consecutive iterations whose feasibility sits a
    % divergeFactor multiple above the best ever achieved.  This is a blow-up
    % detector, not a progress test -- the threshold is deliberately loose so an
    % iterate legitimately working its way back down from a bad patch does not
    % trip it, and the counter resets the moment feasibility comes back inside.
    if iter > 0 && res.feas > opts.divergeFactor * max(bestFeas, opts.feasTol)
        feasRegressCount = feasRegressCount + 1;
    else
        feasRegressCount = 0;
    end

    % Best-iterate snapshot.  A diverged run would otherwise return its final
    % (grossly infeasible) point; keep the most feasible iterate seen, breaking
    % ties on the objective, so the divergence exit can hand back something
    % usable.  Cheap: two vector copies on improvement only.
    if res.feas < bestSnapFeas || (res.feas <= bestSnapFeas && f < bestSnapF)
        bestSnapFeas = res.feas;  bestSnapF = f;
        bestSnap = struct('x', x, 's', s, 'lamE', lamE, 'lamI', lamI, ...
                          'zL', zL, 'zU', zU, 'f', f, 'g', g, ...
                          'cE', cE, 'cI', cI, 'JE', JE, 'JI', JI, ...
                          'iter', iter, 'res', res, 'state', []);
    end

    % Best-KKT snapshot, kept separately from bestSnap above.  That one ranks on
    % feasibility alone, which is the right question for a divergence exit but the
    % wrong one for a run that simply hits maxIter: on the orbit problem the solver
    % reaches opt = 4.6e-04 at a feasible iterate and then wanders back to 1.6e-03
    % by the iteration cap, so returning the last point discards a strictly better
    % answer it had already found.  Rank on the same scaled stationarity the
    % termination test gates on, among iterates that are feasible.
    %
    % Feasibility is the only admission gate, deliberately.  Requiring
    % complementarity as well -- the obvious way to mirror terminationCheck -- was
    % tried and is unreachable: comp sits at mu by construction at every interior
    % iterate, so once the barrier schedule stalls with mu above compTol (1.84e-06
    % against 1e-06 on the orbit case) NOTHING ever qualifies and the retention is
    % silently dead.  A gate that measures the barrier schedule rather than the
    % iterate is the wrong gate.  Ties never displace an incumbent.
    %
    % Skipped entirely under the default returnIterate = 'last', where the
    % snapshot could never be used: this is the one per-iteration cost the
    % retention adds, and a caller who wants the last iterate should not pay it.
    optK = res.opt / kktScaleFactor(state);
    if keepBestKKT && res.feas <= opts.feasTol && optK < bestKKTopt
        bestKKTopt = optK;
        bestKKT = struct('x', x, 's', s, 'lamE', lamE, 'lamI', lamI, ...
                         'zL', zL, 'zU', zU, 'f', f, 'g', g, ...
                         'cE', cE, 'cI', cI, 'JE', JE, 'JI', JI, ...
                         'iter', iter, 'res', res, 'state', []);
    end

    % Objective-plateau tracker: count consecutive iterations over which the
    % accepted objective has not moved by more than a relative objPlateauFtol.
    % f here is the accepted objective from the previous step (updated at the foot
    % of the loop), so this measures per-iteration objective progress.  Gated on
    % iter>0 (no progress can be assessed at the starting point).
    if iter > 0 && abs(f - fPrevObj) <= opts.objPlateauFtol * max(1, abs(f))
        objStallCount = objStallCount + 1;
    else
        objStallCount = 0;
    end
    fPrevObj = f;
    state.objStallCount = objStallCount;

    % Companion to the tracker above: how many CONSECUTIVE iterations the scaled
    % stationarity residual has held inside the plateau gate.  The flat-objective
    % count alone cannot qualify the exit, because f is quadratically flat near a
    % minimizer while opt is only linearly small -- measured on orbitRaiseTest,
    % 95% of iterations past 300 read as "flat", so that test is nearly vacuous
    % in exactly the regime the exit fires in.  opt meanwhile OSCILLATES, and a
    % single downward spike through the gate is not convergence.  optK is the
    % same scaled quantity terminationCheck gates on, so the counter and the gate
    % cannot disagree.
    if optK <= opts.objPlateauOptTol
        optGateCount = optGateCount + 1;
    else
        optGateCount = 0;
    end
    state.optGateCount = optGateCount;
    state.feasRegressCount = feasRegressCount;
    state.bestFeas = bestFeas;

    advice = modeAdvice(state, res, history, opts);
    state.mode = modeLabel(advice.mode, 'ip');
    if strcmp(opts.Display, 'iter-debug')
        % Debug columns for the interior-point core.  gateRatio is the barrier-
        % stall ratio ||rd||/(kappaMu*mu) -- res.opt is already the same scale-
        % consistent stationarity inf-norm used as ||rd|| here -- so a value
        % sitting well above 1 is a frozen barrier.  lsAdopted is the local flag
        % the costate refresh set (or left false) earlier this iteration.
        dbg = struct('optRaw', trow.optRaw, 'optScaled', trow.optScaled, ...
                     'normLamE', norm(lamE, inf), ...
                     'gateRatio', res.opt / max(opts.kappaMu * mu, realmin), ...
                     'nActiveBnd', nnz(activeBnd), ...
                     'lsAdopted', double(lsAdopted));
    else
        dbg = [];
    end
    logState(state, res, opts, toc(tStart), dbg);

    trow.nFun = ev.nFun;   trow.f = f;      trow.mu = mu;
    trow.feas = res.feas;  trow.comp = res.comp;
    trow.normLamE = norm(lamE, inf);        trow.normX = norm(x, inf);
    trow.filterSize = filterCardinality(filt);
    trow.feasStallCount = feasStallCount;   trow.objStallCount = objStallCount;
    trow.optGateCount = optGateCount;
    trow.feasRegressCount = feasRegressCount;

    [stop, ef, m] = terminationCheck(state, res, opts);

    % Per-iteration plot hooks (user PlotFcn and/or the built-in uifigure
    % plot).  Fired after the termination test so the terminal iterate carries
    % its stop/exitflag/message; errors are caught inside firePlots and never
    % alter the solve.  stepsize is the last accepted step in physical units
    % (0 at the starting iterate, where dx/alpha are the loop initializers).
    % The user IterationFcn fires on the same cadence with a strictly richer
    % info struct (the raw internal state of the iterate, see iterationInfo);
    % its errors are caught inside fireIterationFcns and never alter the solve
    % either.  A callback that returns truthy requests a stop: the solve
    % terminates at the current iterate with exitflag -1, unless the solver is
    % already stopping on this iteration, in which case the natural reason
    % stands.
    if opts.Plot || ~isempty(opts.PlotFcn) || ~isempty(opts.IterationFcn)
        stepsize = state.alpha * norm(sc.Dx .* dx);
        info = plotInfo(state, res, sc, fx, probOrig, opts, toc(tStart), ...
                        stepsize, stop, ef, m);
        warnedPlot = firePlots(warnedPlot, opts, info);
        if ~isempty(opts.IterationFcn)
            if isfield(trow, 'lsFired'), lsFired = trow.lsFired; ...
            else, lsFired = 0; end
            extras = struct('dx', dx, 'dlamE', dlamE, 'ds', ds, ...
                            'dlamI', dlamI, 'dzL', dzL, 'dzU', dzU, ...
                            'aP', alpha, 'aD', aD, 'aLamE', aLamE, ...
                            'Delta', Delta, 'tau', tau, ...
                            'rho', rho, 'advice', advice, ...
                            'nActiveBnd', nnz(activeBnd), ...
                            'lsAdopted', lsAdopted, 'lsFired', lsFired);
            info = iterationInfo(info, state, res, probOrig, opts, extras);
            [warnedIter, stopIter, info] = ...
                fireIterationFcns(warnedIter, opts, info);
            if stopIter && ~stop
                stop = true;  ef = -1;  m = info.message;
            end
        end
    end

    if stop
        % Record the terminal row before breaking: the iterate the solver
        % actually returns is the one a diagnosis most needs to see, and it
        % would otherwise be the single row missing from the trace.
        trow = mergeInto(trow, modelSnapshot(hmodel));
        recordTrace(trace, trow);
        exitflag = ef;  msg = m;
        % On a divergence exit the current iterate is the bad one -- roll back to
        % the best point seen so the caller gets a usable answer.
        if ef == -3 && ~isempty(bestSnap)
            [x, s, lamE, lamI, zL, zU, f, g, cE, cI, JE, JI, res, state] = ...
                restoreSnapshot(bestSnap, state);
            msg = sprintf(['%s  Returning the best iterate seen (iteration %d, ' ...
                'feas = %.3e).'], msg, bestSnap.iter, bestSnap.res.feas);
        elseif keepBestKKT && ef == 0 && ~isempty(bestKKT) && ...
                bestKKT.iter ~= iter && bestKKTopt < res.opt / kktScaleFactor(state)
            % A limit exit stops mid-iteration, not at a converged point, so there
            % is no reason to prefer the last iterate over the best one -- and on an
            % oscillating run it is measurably worse.  Guarded four ways: only when
            % the caller opted in via returnIterate = 'bestKKT' (the default 'last'
            % returns the endpoint and never captures a snapshot at all), only when
            % the retained point is strictly better on the termination test's own
            % metric, only when it is not already the current iterate, and never on
            % a convergence exit (ef 1/2), where the final point is the answer by
            % definition and rolling back would contradict the test that just fired.
            rolledFrom = res.opt / kktScaleFactor(state);
            [x, s, lamE, lamI, zL, zU, f, g, cE, cI, JE, JI, res, state] = ...
                restoreSnapshot(bestKKT, state);
            msg = sprintf(['%s  Returning the best KKT iterate seen (iteration %d, ' ...
                'scaled opt = %.3e vs %.3e at the last iterate).'], ...
                msg, bestKKT.iter, bestKKTopt, rolledFrom);
        end
        break;
    end

    if opts.modeSwitch
        Delta = min(Delta * advice.deltaFactor, opts.deltaMax);
    end

    % Barrier schedule: shrink mu once the mu-perturbed error is small.
    % Split the barrier error into the complementarity part (which mu directly
    % controls) and the stationarity/feasibility parts (which it does not).
    compErr = compInfNorm(s, lamI, dxl, zL, finL, dxu, zU, finU, mu);
    % Stationarity measured in the scale-consistent metric (same as res.opt), so
    % the barrier gate and stall detection track the optimality the termination
    % test uses -- not a raw scaled residual inflated by the variable-scale spread
    % nor by a lagging bound dual at an active bound (Fix F: use rdMetric and the
    % pinned-row-excluded weight, matching res.opt exactly).
    statW = norm(optWmetric .* rdMetric, inf);
    Emu = max([statW, norm(rpE, inf), norm(rpI, inf), compErr]);
    muPrev = mu;
    muOpts = opts;

    % Effective kappaMu = base * (adaptive muFactor when modeSwitch) * (barrier-
    % stall override).
    kFac = 1;
    if opts.modeSwitch, kFac = advice.muFactor; end

    % --- Automatic barrier-stall detection (always active) ---
    % The Fiacco-McCormick gate reduces mu only when Emu <= kappaMu*mu.  On a
    % stiff/poorly-costated problem Emu is chronically dominated by the
    % stationarity block ||rd|| (lagging equality multipliers or a bound dual
    % throttled below its true value near an active bound), which mu CANNOT
    % reduce directly -- so the gate never fires and the whole central-path march
    % freezes.  That is exactly the failure the manual kappaMu=100 override cured.
    % Reducing mu is nevertheless the correct cure: it lets the throttled bound
    % duals (zL~mu/dxl, zU~mu/dxu) grow toward their true active multipliers,
    % which is what clears ||rd||.
    %
    % Relax the gate only when a stall is BOTH structural and mu-curable:
    %   (a) on the central path -- complementarity AND feasibility are already
    %       within the standard gate, so mu is the only thing holding progress up;
    %   (b) stationarity-dominated -- ||rd|| is the block exceeding the gate (the
    %       part reducing mu will actually clear).  A feasibility-dominated stall
    %       is left to restoration / feasibility mode, not to mu;
    %   (c) complementarity NOT yet converged (compErr > compTol, P1).  Once
    %       comp is within tolerance mu has no remaining job -- its block of the
    %       error is done -- and a forced drop only re-derives the duals
    %       (z ~ mu/gap) inconsistently, spiking stationarity on the next rd.
    % When all three hold, widen kappaMu by exactly the factor that makes the
    % gate fire this iteration (statErr/gateBase), capped by barrierStallFactor.  A fixed
    % 10x widening was too small for genuinely stiff problems (e.g. a near-active
    % control bound can need ~150x); computing the required factor releases the
    % march regardless of stiffness, while (a)+(b) keep it from firing on a far-
    % from-solution nonconvex iterate (large feas -> (a) fails) and the cap bounds
    % how far a single relaxation can reach.  Firing the gate does NOT crash mu:
    % control_barrierUpdate still only drops it by one superlinear step (muGamma /
    % mu^muBeta), so the march stays monotone and controlled.
    % iter > 0: a stall cannot be diagnosed from the starting point, and relaxing
    % the gate on the very first step (before any progress) can tip a fragile
    % nonconvex solve into divergence.
    gateBase = opts.kappaMu * mu;
    statErr  = statW;                                    % scale-consistent ||rd||
    feasErr  = max(norm(rpE, inf), norm(rpI, inf));
    % Feasibility admission floor.  Testing feasErr <= gateBase alone makes the
    % admission tighten in lockstep with mu: at mu = 1.845e-6 it demanded
    % feas <= 1.84e-5 and disqualified iterations that were textbook structural
    % stalls.  Floor it at feasAdmitFactor*feasTol -- the same "feasibility is
    % under control" threshold the mode controller uses for R1 -- so the test
    % stops chasing mu downward.
    feasAdmit = max(gateBase, opts.feasAdmitFactor * opts.feasTol);
    % P1: freeze the barrier once complementarity is within tolerance.  compErr
    % is the block mu directly controls; when it is already below compTol a
    % forced mu drop cannot improve it -- it only re-derives the duals
    % (z ~ mu/gap) inconsistently and spikes stationarity on the next rd.
    structStall = iter > 0 && mu > opts.muMin && compErr > opts.compTol && ...
                  compErr <= gateBase && feasErr <= feasAdmit && statErr > gateBase;
    if structStall
        neededFac = statErr / gateBase;                 % widen to just release the gate
        kFac = max(kFac, min(neededFac, opts.barrierStallFactor));
        % Note the max() above also disarms the feasibility-mode muFactor=0.5
        % penalty whenever a stall is diagnosed: neededFac > 1 by construction
        % (structStall requires statErr > gateBase), so the widening always wins.
        % An advisory slowdown must not halve a gate that is already too tight.
    end

    trow.structStall = double(structStall);
    trow.statErr = statErr;  trow.gateBase = gateBase;  trow.Emu = Emu;
    trow.gateRatio = statErr / max(gateBase, realmin);

    muOpts.kappaMu = opts.kappaMu * kFac;
    [mu, tau] = control_barrierUpdate(mu, Emu, muOpts);
    trow.tau = tau;

    % NOTE: there is deliberately no "barrier escape" here that forces mu down
    % when the gate holds it still for many iterations.  A frozen mu looks like
    % the cause of a late-stage plateau but measurement says it is a symptom.  On
    % the N=50 orbit case, warm-started from the plateau itself, mu pins at
    % 1.845e-6 for 142 consecutive iterations -- yet across kappaMu = 1e3 and 1e6
    % (which widen the gate directly), barrierStallFactor = 1e4, and
    % muMin = 1e-12, opt after 60 iterations lands at 1.25e-3 to 2.6e-3 in every
    % configuration, versus 1.61e-3 for the default.  The most aggressive settings
    % are the WORST (muMin=1e-12: opt 2.6e-3, feas 3.1e-5, 2.4x the wall time).
    % The gate is not malfunctioning: statErr/gateBase sits at 150-900x during the
    % freeze, so the barrier is correctly declining to advance while stationarity
    % is nowhere near converged.  Forcing mu down anyway only pushes the iterate
    % off the central path.  The plateau is the near-singular-Schur conditioning
    % wall documented in the project notes, and it must be fixed there.
    if useFilter && mu < muPrev, filt.reset(); end

    % Condensed Newton system in (dx, dlamE).
    H = currentHessian(hmodel, ev, x, lamE, lamI, opts);
    hessian = H;
    sigS = lamI ./ s;
    sigL = zeros(n,1);  sigL(finL) = zL(finL) ./ dxl(finL);
    sigU = zeros(n,1);  sigU(finU) = zU(finU) ./ dxu(finU);
    W = H + sigL .* eye(n) + sigU .* eye(n);
    if ev.mI > 0
        W = W + JI.' * (sigS .* JI);
    end
    W = (W + W.') / 2;

    rc_s = s .* lamI - mu;
    corrL = zeros(n,1);  corrL(finL) = (dxl(finL) .* zL(finL) - mu) ./ dxl(finL);
    corrU = zeros(n,1);  corrU(finU) = (dxu(finU) .* zU(finU) - mu) ./ dxu(finU);
    r1 = rd + corrL - corrU;
    if ev.mI > 0
        r1 = r1 + JI.' * (sigS .* rpI - rc_s ./ s);
    end

    % Set by the filter line search when no trial passed any acceptance test.
    % Only that path can diagnose a genuine line-search failure; the NT and merit
    % paths report a step length instead, so they leave this false.
    lsFailed = false;

    if opts.useNTdecomp
        % NT step: normal (reduce equality violation) + tangential (reduce
        % condensed barrier objective in null(JE)). W and r1 play the roles of
        % the Hessian and gradient for the condensed barrier problem.
        theta_IP0 = norm([cE; cI + s], 1);
        phi0_bar  = barrierObj(f, s, x, lb, ub, finL, finU, mu);
        thetaMinNT_IP = 1e-4 * max(1, theta_IP0);
        [JE_eff, cE_eff] = augmentForNearBoundary(JE, cE, JI, cI, advice, state, opts);
        stepAccepted = false;  aP = 1;
        dx = zeros(n,1);  dlamE = zeros(mE,1);
        ds = zeros(size(s));  dlamI = zeros(size(lamI));
        dzL = zeros(n,1);  dzU = zeros(n,1);
        for trIter = 1:opts.trMaxInner                                          %#ok<FORPERM>
            [dx, dlamE, predRed_nt] = computeNTStep(W, r1, JE_eff, cE_eff, Delta, lamE);
            % Back-substitute the eliminated directions.
            if ev.mI > 0
                JIdx  = JI * dx;
                ds    = -rpI - JIdx;
                dlamI = sigS .* (JIdx + rpI) - rc_s ./ s;
            end
            dzL(finL) = -corrL(finL) - sigL(finL) .* dx(finL);
            dzU(finU) = -corrU(finU) + sigU(finU) .* dx(finU);
            % Fraction-to-boundary caps the primal step length.
            aP = 1;
            if ev.mI > 0,   aP = min(aP, step_fractionToBoundary(s, ds, tau)); end
            if any(finL),   aP = min(aP, step_fractionToBoundary(dxl(finL), dx(finL), tau)); end
            if any(finU),   aP = min(aP, step_fractionToBoundary(dxu(finU), -dx(finU), tau)); end
            % Evaluate trial point.
            xt = x + aP * dx;
            ft = ev.objective(xt);
            st = s + aP * ds;
            [cEt, cIt] = ev.constraints(xt);
            theta_t   = norm([cEt; cIt + st], 1);
            phi_t_bar = barrierObj(ft, st, xt, lb, ub, finL, finU, mu);
            isSwitchingIP = useFilter && (theta_IP0 <= thetaMinNT_IP);
            if isSwitchingIP
                ok = true;
            elseif useFilter
                ok = filt.isAcceptable(theta_t, phi_t_bar);
            else
                rho    = max(rho, norm([lamE + dlamE; lamI + dlamI], inf) + 1e-2);
                phi0m  = globalize_meritFunction(phi0_bar, theta_IP0, rho);
                phi_tm = globalize_meritFunction(phi_t_bar, theta_t, rho);
                dphi   = (r1.' * dx) - rho * theta_IP0;
                ok = globalize_meritAccept(phi0m, phi_tm, dphi, aP);
            end
            actRed = phi0_bar - phi_t_bar;
            [Delta, tr_ok, ~] = control_trustRegionUpdate( ...
                Delta, predRed_nt, actRed, aP * norm(dx), opts);
            if ok && tr_ok
                if useFilter && ~isSwitchingIP
                    filt.augment(theta_IP0, phi0_bar);
                end
                stepAccepted = true;
                break;
            end
        end
        if ~stepAccepted
            % NT step collapsed (dx≈0): back-substituting a zero step gives
            % dlamI ≈ sigS*rpI which blows up the multipliers. Fall back to the
            % standard condensed KKT step so that JI*dx ≈ -rpI, keeping dlamI safe.
            cstate_fb = struct('H', W, 'JE', JE, 'x', x, 'lamE', lamE);
            cres_fb   = struct('rStat', r1, 'rFeasE', rpE);
            [d_fb, idx_fb, ksolve] = detectStep(cstate_fb, cres_fb, n, mE, opts, ksolve);
            primaryInfo = ksolve.last;
            nSolves = nSolves + 1;
            dx    = d_fb(idx_fb.x);
            dlamE = d_fb(idx_fb.lamE);
            if ev.mI > 0
                JIdx  = JI * dx;
                ds    = -rpI - JIdx;
                dlamI = sigS .* (JIdx + rpI) - rc_s ./ s;
            else
                ds = zeros(0,1);  dlamI = zeros(0,1);
            end
            dzL = zeros(n,1);  dzL(finL) = -corrL(finL) - sigL(finL) .* dx(finL);
            dzU = zeros(n,1);  dzU(finU) = -corrU(finU) + sigU(finU) .* dx(finU);
            aP = 1;
            if ev.mI > 0,   aP = min(aP, step_fractionToBoundary(s, ds, tau)); end
            if any(finL),   aP = min(aP, step_fractionToBoundary(dxl(finL), dx(finL), tau)); end
            if any(finU),   aP = min(aP, step_fractionToBoundary(dxu(finU), -dx(finU), tau)); end
            [aP, rho] = ipLineSearch(ev, x, s, dx, ds, lb, ub, finL, finU, ...
                                     f, g, cE, cI, mu, rho, ...
                                     [lamE + dlamE; lamI + dlamI], aP);
        end
        % Compute dual step fractions.
        aD = 1;
        if ev.mI > 0,   aD = min(aD, step_fractionToBoundary(lamI, dlamI, tau)); end
        if any(finL),   aD = min(aD, step_fractionToBoundary(zL(finL), dzL(finL), tau)); end
        if any(finU),   aD = min(aD, step_fractionToBoundary(zU(finU), dzU(finU), tau)); end
    else
        cstate = struct('H', W, 'JE', JE, 'x', x, 'lamE', lamE);
        cres = struct('rStat', r1, 'rFeasE', rpE);
        [d, idx, ksolve] = detectStep(cstate, cres, n, mE, opts, ksolve);
        dx    = d(idx.x);
        dlamE = d(idx.lamE);

        % Snapshot the PRIMARY solve now.  detectStep runs again for every SOC
        % re-solve below (up to socMax = 4), each overwriting ksolve.last, so
        % reading it after the line search would attribute the last correction's
        % conditioning to the step -- silently, and precisely on the iterations
        % where SOC fired, which are the interesting ones.
        primaryInfo = ksolve.last;
        nSolves = 1;
        trow.condK = traceCondK(trace, cstate, ksolve.reg);

        % Recover the eliminated directions.
        if ev.mI > 0
            JIdx  = JI * dx;
            ds    = -rpI - JIdx;
            dlamI = sigS .* (JIdx + rpI) - rc_s ./ s;
        else
            ds    = zeros(0,1);
            dlamI = zeros(0,1);
        end
        dzL = zeros(n,1);  dzL(finL) = -corrL(finL) - sigL(finL) .* dx(finL);
        dzU = zeros(n,1);  dzU(finU) = -corrU(finU) + sigU(finU) .* dx(finU);

        % Fraction to boundary: separate primal and dual step lengths.
        aP = 1;
        if ev.mI > 0,   aP = min(aP, step_fractionToBoundary(s, ds, tau)); end
        if any(finL),   aP = min(aP, step_fractionToBoundary(dxl(finL), dx(finL), tau)); end
        if any(finU),   aP = min(aP, step_fractionToBoundary(dxu(finU), -dx(finU), tau)); end
        aD = 1;
        if ev.mI > 0,   aD = min(aD, step_fractionToBoundary(lamI, dlamI, tau)); end
        if any(finL),   aD = min(aD, step_fractionToBoundary(zL(finL), dzL(finL), tau)); end
        if any(finU),   aD = min(aD, step_fractionToBoundary(zU(finU), dzU(finU), tau)); end

        if useFilter
            theta0 = norm([cE; cI + s], 1);
            phi0 = barrierObj(f, s, x, lb, ub, finL, finU, mu);
            gd = g.' * dx ...
                 - mu * ( sumBarrierDir(ds, s) ...
                          + sumBarrierDir(dx(finL), x(finL) - lb(finL)) ...
                          - sumBarrierDir(dx(finU), ub(finU) - x(finU)) );
            pt = @(a) phiThetaIP(ev, x, s, dx, ds, lb, ub, finL, finU, mu, a);
            aMax0 = aP;
            % Absolute ceiling on how far one accepted step may raise the
            % constraint violation.  Without it the theta-type acceptance rule
            % trades an unbounded feasibility increase for an infinitesimal
            % objective decrease (see globalize_filterLineSearch / defaultOptions
            % kappaThetaGrow).
            thCap = thetaGrowCap(theta0, opts);
            multN = norm([lamE + dlamE; lamI + dlamI], inf);
            [aP, augment, rho, lsFailed] = globalize_filterLineSearch( ...
                pt, phi0, theta0, gd, filt, rho, aMax0, thCap, multN);

            % --- Second-order correction (Waechter-Biegler) ---
            % A collapsed step (aP << aMax0) on strongly nonlinear constraints
            % is the Maratos effect: the full step is rejected because the
            % constraint curvature raises theta.  Retry with a corrected
            % direction that also cancels the constraint value at the full
            % trial point, re-solving the condensed KKT system with the
            % modified RHS c_soc = alpha*c + c(x + alpha*dx).
            if opts.useSOC && aMax0 > 1e-6 && aP < opts.socThreshold * aMax0
                aFTB  = aMax0;
                cSocE = rpE;                       % accumulates alpha*c + c(trial)
                for socIt = 1:opts.socMax                                       %#ok<FORPERM>
                    xt = x + aFTB * dx;
                    [cEt, ~] = ev.constraints(xt);
                    cSocE = aFTB * cSocE + cEt;    % WB constraint accumulation
                    % Re-solve condensed KKT with the corrected constraint RHS.
                    cstateS = struct('H', W, 'JE', JE, 'x', x, 'lamE', lamE);
                    cresS   = struct('rStat', r1, 'rFeasE', cSocE);
                    [dS, idxS, ksolve] = detectStep(cstateS, cresS, n, mE, opts, ksolve);
                    nSolves = nSolves + 1;
                    dxC    = dS(idxS.x);
                    dlamEC = dS(idxS.lamE);
                    if ev.mI > 0
                        JIdxC  = JI * dxC;
                        dsC    = -rpI - JIdxC;
                        dlamIC = sigS .* (JIdxC + rpI) - rc_s ./ s;
                    else
                        dsC    = zeros(0,1);
                        dlamIC = zeros(0,1);
                    end
                    dzLC = zeros(n,1);  dzLC(finL) = -corrL(finL) - sigL(finL) .* dxC(finL);
                    dzUC = zeros(n,1);  dzUC(finU) = -corrU(finU) + sigU(finU) .* dxC(finU);
                    % Fraction-to-boundary cap for the corrected primal direction.
                    aC = 1;
                    if ev.mI > 0,   aC = min(aC, step_fractionToBoundary(s, dsC, tau)); end
                    if any(finL),   aC = min(aC, step_fractionToBoundary(dxl(finL), dxC(finL), tau)); end
                    if any(finU),   aC = min(aC, step_fractionToBoundary(dxu(finU), -dxC(finU), tau)); end
                    ptC = @(a) phiThetaIP(ev, x, s, dxC, dsC, lb, ub, finL, finU, mu, a);
                    % Directional derivative of phi along the CORRECTED direction.
                    % Passing the uncorrected gd made every Armijo and switching
                    % test inside the line search use the wrong slope -- and
                    % believe gd < 0 even when dxC is an ascent direction.
                    gdC = g.' * dxC ...
                          - mu * ( sumBarrierDir(dsC, s) ...
                                   + sumBarrierDir(dxC(finL), x(finL) - lb(finL)) ...
                                   - sumBarrierDir(dxC(finU), ub(finU) - x(finU)) );
                    [aTrial, augmentC, rhoC, lsFailedC] = globalize_filterLineSearch( ...
                        ptC, phi0, theta0, gdC, filt, rho, aC, thCap, multN);
                    % Adopt only when the correction is genuinely better.  A
                    % LONGER step is not by itself an improvement: the line search
                    % always returns something, so "aTrial > aP" is a bar the
                    % corrected direction clears almost automatically -- which is
                    % how SOC could manufacture a large step precisely when the
                    % ordinary one had collapsed.  Require the corrected trial to
                    % have actually succeeded and to not worsen feasibility.
                    [~, thAdopt] = ptC(aTrial);
                    if aTrial > aP && ~lsFailedC && thAdopt <= theta0
                        % SOC succeeded: adopt the corrected direction.  The
                        % adopted step now comes from the CORRECTED solve, so
                        % that solve's conditioning is the one describing it.
                        primaryInfo = ksolve.last;
                        socAdopted = 1;
                        aP = aTrial;  augment = augmentC;  rho = rhoC;
                        lsFailed = false;
                        dx = dxC;  ds = dsC;  dlamE = dlamEC;  dlamI = dlamIC;
                        dzL = dzLC;  dzU = dzUC;
                        aD = 1;
                        if ev.mI > 0,   aD = min(aD, step_fractionToBoundary(lamI, dlamI, tau)); end
                        if any(finL),   aD = min(aD, step_fractionToBoundary(zL(finL), dzL(finL), tau)); end
                        if any(finU),   aD = min(aD, step_fractionToBoundary(zU(finU), dzU(finU), tau)); end
                        break;
                    end
                    % No improvement: continue correcting only if the corrected
                    % full step at least reduces theta; otherwise abandon SOC.
                    [~, thC] = ptC(aC);
                    if thC >= theta0, break; end
                    aFTB = aC;
                end
            end

            if augment, filt.augment(theta0, phi0); end
        else
            [aP, rho] = ipLineSearch(ev, x, s, dx, ds, lb, ub, finL, finU, ...
                                     f, g, cE, cI, mu, rho, ...
                                     [lamE + dlamE; lamI + dlamI], aP);
        end
    end

    % Restoration trigger.  Restoration (and, on its failure, the ef=-2
    % local-infeasibility exit) is disruptive -- it discards the secant history,
    % resets the filter/trust region, and re-seeds multipliers.  Both of the
    % classic triggers fire on TRANSIENT events: a bare line-search collapse
    % (aP<=1e-10) is a single-iteration stall, and advice.suggestRestore is only a
    % stagnWindow-length plateau of the raw theta history.  On a stiff problem the
    % primal step transiently collapses and feasibility briefly plateaus while the
    % main iteration is still, across iterations, driving feasibility to new lows.
    % The eager triggers fired restoration on the first such event and, when
    % restoration could not reduce theta, declared local infeasibility and quit --
    % verified on the orbit case bailing ef=-2 at ~580 km (aP trigger) and again at
    % ~380 km (suggestRestore trigger) even though simply riding through reaches
    % ~2.5e-3.  Gate BOTH triggers behind a genuine main-iteration stall:
    % feasStallCount counts consecutive iters with no NEW best feasibility (a
    % transient plateau at the current best still counts as progress toward a
    % breakthrough and is spared), so restoration fires only once the main
    % iteration has truly stopped improving for restStallWindow iters.
    % lsFailed is the honest line-search-failure signal: the filter search always
    % RETURNS a step, so testing aP <= 1e-10 almost never fires (on the diverging
    % orbit run the collapsed steps bottomed out at 6.1e-5 and this trigger stayed
    % silent throughout).  Keep the aP test for the other step paths, which report
    % only a length.
    feasGenuinelyStalled = feasStallCount >= opts.restStallWindow;
    needRestoration = opts.enableRestoration && ...
        norm([cE; cI + s], 1) > opts.feasTol && ...
        feasGenuinelyStalled && (lsFailed || aP <= 1e-10 || advice.suggestRestore);
    if needRestoration
        % Restoration both CONTINUEs and BREAKs past the foot-of-loop record, so
        % this iteration would be the one gap in the trace -- and it is precisely
        % the iteration a reader would look for after an ef=-2 exit.  Record it
        % here, before either exit, with the flag that identifies it.
        trow = finishTraceRow(trow, primaryInfo, [], aP, aD, NaN, rho, Delta, ...
                              lsFailed, nSolves, socAdopted, 1);
        recordTrace(trace, trow);
        [x, rinfo] = degeneracy_restorationPhase(ev, x, lb, ub, opts);
        if rinfo.theta > opts.feasTol && ...
                (~rinfo.reduced || rinfo.theta >= restTheta - opts.feasTol)
            exitflag = -2;
            msg = 'No feasible point found (local infeasibility).';
            break;
        end
        restTheta = rinfo.theta;
        % Restoration projects trial points onto [lb,ub] and may land x exactly
        % on a bound.  The interior-point barrier then forms zL/(x-lb) with a
        % zero denominator, producing an Inf Hessian and a NaN Newton step.
        % Re-project x strictly into the interior and re-seed the bound and
        % inequality multipliers from the current barrier parameter, exactly as
        % at start-up.  The large discontinuous restoration jump also
        % invalidates the secant history, so reset the Hessian model.
        x = pushInterior(x, lb, ub, finL, finU);
        [f, g]   = ev.objective(x);
        [cE, cI] = ev.constraints(x);
        [JE, JI] = ev.jacobian(x);
        if ev.mI > 0
            s    = max(-cI, 1e-4);
            lamI = mu ./ max(s, 1e-4);
        end
        zL = seedBoundMult(lb, x, mu, +1, finL);
        zU = seedBoundMult(ub, x, mu, -1, finU);
        if ~isempty(hmodel) && ismethod(hmodel, 'reset'), hmodel.reset(); end
        if useFilter, filt.reset(); end
        Delta = opts.delta0;
        alpha = 0;
        continue;
    end

    gOld = g;  JEold = JE;  JIold = JI;
    x    = x + aP * dx;
    s    = s + aP * ds;
    % Equality multipliers are unconstrained duals (no fraction-to-boundary
    % limit), so they take the full dual step aD -- the standard primal-dual
    % convention.  Throttling them to min(aP,aD) starves dual convergence when
    % primal steps are small: lamE then lags, dual infeasibility (opt) stays
    % high, and the barrier parameter mu can never satisfy Emu <= kappaMu*mu.
    % Fix B applies only a scale-relative CEILING on the increment (inert unless
    % dlamE blows up on a near-singular Schur complement), so normal dual
    % progress is untouched but a 1e4-1e5 multiplier jump cannot wreck lamE.
    aLamE = dualStepCoeff(aD, dlamE, lamE, opts);
    lamE = lamE + aLamE * dlamE;
    lamI = lamI + aD * dlamI;
    zL(finL) = zL(finL) + aD * dzL(finL);
    zU(finU) = zU(finU) + aD * dzU(finU);
    alpha = aP;

    [f, g]   = ev.objective(x);
    [cE, cI] = ev.constraints(x);
    [JE, JI] = ev.jacobian(x);
    % P2: on an adopted-refresh iteration the secant pair must NOT be evaluated
    % at the jumped lamE (the refresh jump is a dual correction, not curvature;
    % injecting it into y corrupts the model).  Form the pair at the pre-refresh
    % multipliers -- the ones the iterate actually followed.  On non-adopted
    % iterations lamEsec = lamE, so behaviour is unchanged there.
    if lsAdopted
        lamEsec = lamE_pair;
    else
        lamEsec = lamE;
    end
    hinfo = updateHessianModel(hmodel, gOld, JEold, JIold, g, JE, JI, ...
                               lamEsec, lamI, aP * dx);
    ksolve = warnBfgsReset(ksolve, opts, hinfo, iter);
    theta_k = norm([cE; cI + s], 1);
    history = pushHistory(history, theta_k, aP, opts);

    % Foot of the loop: the secant update for THIS step has just happened, so
    % this is the first point at which the row is complete.
    trow = finishTraceRow(trow, primaryInfo, hinfo, aP, aD, aLamE, rho, Delta, ...
                          lsFailed, nSolves, socAdopted, 0);
    recordTrace(trace, trow);
end

fval = f;  grad = g;
output = makeOutput(state, res, ev, exitflag, msg);
if ~isempty(hmodel), output.hessianModel = hmodel; end   % secant model diagnostics
if ~isempty(trace), output.trace = trace.toStruct(); end % per-iteration trajectory
lambda = makeLambda(ev, lamE, lamI, zL, zU);

% --- Termination diagnostics (for convergence-plateau investigation) ---
% Capture the exact vectors behind the reported opt/feas so the caller can
% localise the residual by variable/constraint block, and probe constraint
% conditioning, without re-running the solve.
rd_diag = g;
if mE > 0,    rd_diag = rd_diag + JE.' * lamE; end
if ev.mI > 0, rd_diag = rd_diag + JI.' * lamI; end
rd_diag = rd_diag - zL + zU;
output.diag = struct('rd', rd_diag, 'rpE', cE, 'x', x, 'g', g, ...
                     'lamE', lamE, 'zL', zL, 'zU', zU, 'JE', JE, ...
                     'lb', lb, 'ub', ub, 'mu', mu);

util_logger('final', opts.Display, output, opts.LogFile);
end

function advice = modeAdvice(state, res, history, opts)
%MODEADVICE  Query the adaptive mode controller (or return a neutral default).
%   When opts.modeSwitch is on, delegates to control_modeController; otherwise
%   returns a standard advice struct that leaves mu, Delta, and restoration
%   unchanged.
%
%   Inputs:
%     state   - current iterate state struct.
%     res     - current residual struct (opt/feas/comp).
%     history - recent (theta, alpha) history struct.
%     opts    - resolved options struct.
%
%   Outputs:
%     advice - struct with muFactor, deltaFactor, suggestRestore, mode.
import adamnlopt.*
if opts.modeSwitch
    advice = control_modeController(state, res, history, opts);
else
    advice = struct('muFactor',1,'deltaFactor',1,'suggestRestore',false,'mode','standard');
end
end

function h = pushHistory(h, theta, alpha, opts)
%PUSHHISTORY  Append a (theta, alpha) sample to the rolling stagnation window.
%   Keeps only the most recent modeSwitchStagnWindow+1 entries so the mode
%   controller can detect stalled progress.
%
%   Inputs:
%     h     - history struct with fields theta and alpha (column vectors).
%     theta - constraint violation (l1 norm) at the accepted iterate.
%     alpha - accepted step length.
%     opts  - resolved options struct (uses modeSwitchStagnWindow).
%
%   Outputs:
%     h - updated history struct, truncated to the window length.
w = opts.modeSwitchStagnWindow + 1;
h.theta = [h.theta; theta];
h.alpha = [h.alpha; alpha];
if numel(h.theta) > w
    h.theta = h.theta(end-w+1:end);
    h.alpha = h.alpha(end-w+1:end);
end
end

function x = pushInterior(x, lb, ub, finL, finU)
%PUSHINTERIOR  Project x strictly inside its finite bounds.
%   Nudges each component in by a relative margin (kappa = 1e-2), matching
%   initializeIterate, so a barrier variable never sits exactly on a bound
%   (which would make zL/(x-lb) blow up).
%
%   Inputs:
%     x    - n-by-1 current point (possibly on a bound).
%     lb   - n-by-1 lower bounds (may be -Inf).
%     ub   - n-by-1 upper bounds (may be +Inf).
%     finL - logical mask of finite lower bounds.
%     finU - logical mask of finite upper bounds.
%
%   Outputs:
%     x - n-by-1 point projected strictly into the interior of [lb, ub].
% Project x strictly inside the finite bounds with a relative margin, matching
% initializeIterate.  A barrier variable must never sit exactly on a bound.
kappa = 1e-2;
both = finL & finU;
loOnly = finL & ~finU;
upOnly = finU & ~finL;
if any(both)
    % The two-sided margin must be a FRACTION of the box width, never an
    % absolute floor.  max(1, ub-lb) pushed a narrow variable by up to the full
    % width of its own box and then some: with lb=0, ub=1e-2 it gave margin=1,
    % so min(max(x,1), -0.99) drove x to -0.99 -- 99 box widths BELOW lb, and
    % mu/(x-lb) came back negative.  initializeIterate:45 has carried the
    % correct form and a comment saying so since the same bug was fixed there;
    % this copy was never updated.  Clamping the margin at kappa of the range
    % keeps [lb+margin, ub-margin] non-empty and strictly interior.
    margin = kappa * (ub(both) - lb(both));
    x(both) = min(max(x(both), lb(both) + margin), ub(both) - margin);
end
if any(loOnly)
    x(loOnly) = max(x(loOnly), lb(loOnly) + kappa * max(1, abs(lb(loOnly))));
end
if any(upOnly)
    x(upOnly) = min(x(upOnly), ub(upOnly) - kappa * max(1, abs(ub(upOnly))));
end
end

function z = seedBoundMult(bound, x, mu, sgn, fin)
%SEEDBOUNDMULT  Seed bound multipliers from the barrier parameter.
%   Sets z_i = mu / distance-to-bound for finite bounds and 0 otherwise, the
%   standard interior-point initialization consistent with s.*z ~ mu.
%
%   Inputs:
%     bound - n-by-1 bound vector (lb or ub).
%     x     - n-by-1 current (interior) point.
%     mu    - current barrier parameter.
%     sgn   - +1 for lower bounds (x - lb), -1 for upper bounds (ub - x).
%     fin   - logical mask of finite entries in bound.
%
%   Outputs:
%     z - n-by-1 bound multipliers (0 where fin is false).
% z_i = mu / distance to the (finite) bound; 0 for infinite bounds.
z = zeros(numel(x), 1);
d = sgn * (x(fin) - bound(fin));      % positive distance to the bound
z(fin) = mu ./ max(d, 1e-8);
end

function v = compInfNorm(s, lamI, dxl, zL, finL, dxu, zU, finU, mu)
%COMPINFNORM  Infinity norm of the mu-perturbed complementarity residual.
%   Stacks s.*lamI - mu, (x-lb).*zL - mu, and (ub-x).*zU - mu over the finite
%   entries and returns the max absolute value; used for the barrier error Emu.
%
%   Inputs:
%     s    - slack vector for inequalities (may be empty).
%     lamI - inequality multipliers.
%     dxl  - x - lb (distance to lower bounds).
%     zL   - lower-bound multipliers.
%     finL - logical mask of finite lower bounds.
%     dxu  - ub - x (distance to upper bounds).
%     zU   - upper-bound multipliers.
%     finU - logical mask of finite upper bounds.
%     mu   - current barrier parameter.
%
%   Outputs:
%     v - infinity norm of the perturbed complementarity residual (0 if empty).
parts = zeros(0,1);
if ~isempty(s),  parts = [parts; s .* lamI - mu]; end
if any(finL),    parts = [parts; dxl(finL) .* zL(finL) - mu]; end
if any(finU),    parts = [parts; dxu(finU) .* zU(finU) - mu]; end
if isempty(parts), v = 0; else, v = norm(parts, inf); end
end

function res = ipRes(rd, rpE, rpI, s, lamI, dxl, zL, finL, dxu, zU, finU, optW)
%IPRES  Assemble the interior-point residual struct and its scalar norms.
%   Packs the barrier-free stationarity, primal-feasibility, and (unperturbed)
%   complementarity residuals together with their infinity norms (opt/feas/comp)
%   for the termination test.
%
%   Inputs:
%     rd   - stationarity residual (dual infeasibility).
%     rpE  - equality primal residual cE.
%     rpI  - inequality primal residual cI + s.
%     s    - slack vector.
%     lamI - inequality multipliers.
%     dxl  - x - lb; zL lower-bound multipliers; finL finite-lower mask.
%     zL   - lower-bound multipliers.
%     finL - logical mask of finite lower bounds.
%     dxu  - ub - x; zU upper-bound multipliers; finU finite-upper mask.
%     zU   - upper-bound multipliers.
%     finU - logical mask of finite upper bounds.
%     optW - scale-consistent optimality weight (1./Dx); all ones when scaling
%            is off.  res.opt is the weighted stationarity inf-norm so a wide
%            variable-scale spread cannot strand the reported optimality; the
%            stored rStat stays UNweighted (it is the Newton-step RHS).
%
%   Outputs:
%     res - struct with rStat, rFeasE, rFeasI, rComp vectors and opt, feas,
%           comp scalar (infinity) norms.
import adamnlopt.*
res.rStat  = rd;                    % raw scaled residual (Newton-step RHS)
res.rFeasE = rpE;
res.rFeasI = rpI;
res.rComp  = compVec(s, lamI, dxl, zL, finL, dxu, zU, finU);
res.opt  = util_norms(optW .* rd);  % scale-consistent optimality (termination)
res.feas = util_norms(rpE, rpI);
res.comp = util_norms(res.rComp);
end

function v = compVec(s, lamI, dxl, zL, finL, dxu, zU, finU)
%COMPVEC  Stack the (unperturbed) complementarity products.
%   Concatenates s.*lamI, (x-lb).*zL, and (ub-x).*zU over the finite entries;
%   the raw complementarity residual reported at termination (mu = 0).
%
%   Inputs:
%     s    - slack vector (may be empty).
%     lamI - inequality multipliers.
%     dxl  - x - lb (distance to lower bounds).
%     zL   - lower-bound multipliers.
%     finL - logical mask of finite lower bounds.
%     dxu  - ub - x (distance to upper bounds).
%     zU   - upper-bound multipliers.
%     finU - logical mask of finite upper bounds.
%
%   Outputs:
%     v - stacked complementarity products (column vector, possibly empty).
v = zeros(0,1);
if ~isempty(s),  v = [v; s .* lamI]; end
if any(finL),    v = [v; dxl(finL) .* zL(finL)]; end
if any(finU),    v = [v; dxu(finU) .* zU(finU)]; end
end

function [x, s, lamE, lamI, zL, zU, f, g, cE, cI, JE, JI, res, state] = ...
        restoreSnapshot(snap, state)
%RESTORESNAPSHOT  Roll the iterate back to a stored best-iterate snapshot.
%   Used by the divergence exit so a blown-up run returns the most feasible point
%   it actually visited rather than the diverged one.  The state struct keeps its
%   bookkeeping fields (iter, nFunEvals, mode) so the reported iteration and
%   evaluation counts still describe the whole run.
%
%   Inputs:
%     snap  - snapshot struct captured in the main loop.
%     state - current state struct, used as the template for the restored one.
%
%   Outputs:
%     the snapshot's primal/dual variables, function/constraint values, Jacobians,
%     residual struct, and the state struct updated to match.
x = snap.x;  s = snap.s;
lamE = snap.lamE;  lamI = snap.lamI;
zL = snap.zL;  zU = snap.zU;
f = snap.f;  g = snap.g;
cE = snap.cE;  cI = snap.cI;
JE = snap.JE;  JI = snap.JI;
res = snap.res;
state.x = x;  state.s = s;
state.lamE = lamE;  state.lamI = lamI;
state.zL = zL;  state.zU = zU;
state.f = f;  state.g = g;
state.cE = cE;  state.cI = cI;
state.JE = JE;  state.JI = JI;
end

function state = ipState(x, s, lamE, lamI, zL, zU, f, g, cE, cI, JE, JI, ...
                         iter, nFun, alpha, mu)
%IPSTATE  Bundle the current interior-point iterate into a state struct.
%   Collects the primal/dual variables, objective and constraint values,
%   Jacobians, and iteration bookkeeping consumed by the mode controller,
%   residual assembly, termination test, and logger.
%
%   Inputs:
%     x, s          - primal variables and inequality slacks.
%     lamE, lamI    - equality and inequality multipliers.
%     zL, zU        - lower- and upper-bound multipliers.
%     f, g          - objective value and gradient.
%     cE, cI        - equality and inequality constraint values.
%     JE, JI        - equality and inequality Jacobians.
%     iter          - iteration index.
%     nFun          - cumulative objective evaluation count.
%     alpha         - last accepted (primal) step length.
%     mu            - current barrier parameter.
%
%   Outputs:
%     state - struct with the above fields plus mode = 'ip'.
state = struct();
state.x = x;  state.s = s;
state.lamE = lamE;  state.lamI = lamI;
state.zL = zL;  state.zU = zU;
state.f = f;  state.g = g;
state.cE = cE;  state.cI = cI;
state.JE = JE;  state.JI = JI;
state.iter = iter;  state.nFunEvals = nFun;  state.alpha = alpha;
state.mu = mu;  state.mode = 'ip';
end

function [alpha, rho] = ipLineSearch(ev, x, s, dx, ds, lb, ub, finL, finU, ...
                                     f, g, cE, cI, mu, rho, multNew, aMax)
%IPLINESEARCH  Backtracking Armijo line search on the log-barrier l1 merit.
%   Minimizes phi = f - mu*sum(log barriers) + rho*||[cE; cI+s]||_1 along the
%   primal direction (dx, ds), starting from the fraction-to-boundary cap aMax
%   and halving until the Armijo condition holds (or amin is reached). rho is
%   raised so the predicted directional derivative is negative.
%
%   Inputs:
%     ev         - Evaluator for trial objective/constraint values.
%     x, s       - current primal variables and slacks.
%     dx, ds     - primal search directions for x and s.
%     lb, ub     - bounds; finL, finU finite-bound masks.
%     finL, finU - logical masks of finite lower/upper bounds.
%     f, g       - current objective value and gradient.
%     cE, cI     - current equality and inequality constraint values.
%     mu         - current barrier parameter.
%     rho        - current l1 penalty weight (updated on the way in).
%     multNew    - trial multiplier vector used to lower-bound rho.
%     aMax       - initial (fraction-to-boundary) step length.
%
%   Outputs:
%     alpha - accepted step length in (0, aMax].
%     rho   - possibly increased l1 penalty weight.
% Backtracking Armijo on the log-barrier l1 merit
%   phi = f - mu*sum(log barriers) + rho*||[cE; cI+s]||_1
% starting from the fraction-to-boundary cap aMax.
theta = norm([cE; cI + s], 1);
gd = g.' * dx ...
     - mu * ( sumBarrierDir(ds, s) ...
              + sumBarrierDir(dx(finL), x(finL) - lb(finL)) ...
              - sumBarrierDir(dx(finU), ub(finU) - x(finU)) );

rho = max(rho, norm(multNew, inf) + 1e-2);
if theta > 0
    rho = max(rho, gd / theta + 1e-2);
end
phi0 = barrierMerit(f, s, x, lb, ub, finL, finU, mu, rho, theta);
dphi = gd - rho * theta;

alpha = aMax;  amin = 1e-10;  c = 1e-4;
while alpha > amin
    xt = x + alpha * dx;
    st = s + alpha * ds;
    ft = ev.objective(xt);
    [cEt, cIt] = ev.constraints(xt);
    tht = norm([cEt; cIt + st], 1);
    phit = barrierMerit(ft, st, xt, lb, ub, finL, finU, mu, rho, tht);
    if phit <= phi0 + c * alpha * dphi
        return;
    end
    alpha = 0.5 * alpha;
end
alpha = max(alpha, amin);
end

function phi = barrierMerit(f, s, x, lb, ub, finL, finU, mu, rho, theta)
%BARRIERMERIT  Log-barrier l1 merit function value.
%   Returns the barrier objective plus the penalty term rho*theta.
%
%   Inputs:
%     f          - objective value.
%     s          - slack vector.
%     x          - current point; lb/ub bounds; finL/finU finite-bound masks.
%     lb, ub     - lower/upper bounds.
%     finL, finU - logical masks of finite lower/upper bounds.
%     mu         - barrier parameter.
%     rho        - l1 penalty weight.
%     theta      - constraint violation ||[cE; cI+s]||_1.
%
%   Outputs:
%     phi - merit value f - mu*sum(log barriers) + rho*theta.
phi = barrierObj(f, s, x, lb, ub, finL, finU, mu) + rho * theta;
end

function phi = barrierObj(f, s, x, lb, ub, finL, finU, mu)
%BARRIEROBJ  Log-barrier objective (no penalty term).
%   Returns f - mu*(sum log s + sum log(x-lb) + sum log(ub-x)) over the
%   applicable slacks and finite bounds.
%
%   Inputs:
%     f          - objective value.
%     s          - slack vector (may be empty).
%     x          - current point.
%     lb, ub     - lower/upper bounds.
%     finL, finU - logical masks of finite lower/upper bounds.
%     mu         - barrier parameter.
%
%   Outputs:
%     phi - barrier objective value.
% Log-barrier objective f - mu*sum(log barriers) (no penalty term).
b = 0;
if ~isempty(s),  b = b + sum(log(s)); end
if any(finL),    b = b + sum(log(x(finL) - lb(finL))); end
if any(finU),    b = b + sum(log(ub(finU) - x(finU))); end
phi = f - mu * b;
end

function [phi, theta] = phiThetaEq(ev, x, dx, a)
%PHITHETAEQ  Filter coordinates (objective, violation) for the equality core.
%   Evaluates the objective and the l1 constraint violation at x + a*dx; passed
%   as a probe handle to the filter line search.
%
%   Inputs:
%     ev - Evaluator for objective/constraint values.
%     x  - current point.
%     dx - search direction.
%     a  - step length.
%
%   Outputs:
%     phi   - objective value f(x + a*dx).
%     theta - constraint violation ||cE(x + a*dx)||_1.
% Filter coordinates (objective, violation) at x + a*dx (equality core).
xt = x + a * dx;
phi = ev.objective(xt);
[cEt, ~] = ev.constraints(xt);
theta = norm(cEt, 1);
end

function [phi, theta] = phiThetaIP(ev, x, s, dx, ds, lb, ub, finL, finU, mu, a)
%PHITHETAIP  Filter coordinates (barrier objective, violation) for the IP core.
%   Evaluates the log-barrier objective and the l1 violation ||[cE; cI+s]||_1 at
%   the trial point (x + a*dx, s + a*ds); passed as a probe handle to the filter
%   line search.
%
%   Inputs:
%     ev         - Evaluator for objective/constraint values.
%     x, s       - current point and slacks.
%     dx, ds     - search directions for x and s.
%     lb, ub     - bounds; finL/finU finite-bound masks.
%     finL, finU - logical masks of finite lower/upper bounds.
%     mu         - barrier parameter.
%     a          - step length.
%
%   Outputs:
%     phi   - barrier objective at the trial point.
%     theta - constraint violation ||[cE; cI+s]||_1 at the trial point.
% Filter coordinates (barrier objective, violation) at the trial IP point.
xt = x + a * dx;  st = s + a * ds;
ft = ev.objective(xt);
[cEt, cIt] = ev.constraints(xt);
phi = barrierObj(ft, st, xt, lb, ub, finL, finU, mu);
theta = norm([cEt; cIt + st], 1);
end

function filt = makeFilter(opts, theta0)
%MAKEFILTER  Construct a Filter object when filter globalization is selected.
%   Returns a Filter seeded with an upper violation bound scaled from theta0, or
%   [] when the merit-function globalization is in use.
%
%   Inputs:
%     opts   - resolved options struct (uses globalization).
%     theta0 - initial constraint violation used to size the filter bound.
%
%   Outputs:
%     filt - Filter object, or [] when not using filter globalization.
import adamnlopt.*
if strcmpi(opts.globalization, 'filter')
    % thetaMax caps the violation of any filter-acceptable trial.  The former
    % 1e4*max(1,theta0) had a floor of 1e4 regardless of the problem, so on a
    % well-scaled solve starting at theta0 ~ 0.1 it sat five orders above
    % anything the iteration would ever legitimately visit and never rejected
    % anything.  Scale it from the ACTUAL initial violation, with a floor tied to
    % feasTol so a problem started at (or very near) a feasible point still has
    % room to move.  It is a coarse backstop -- the per-step growth veto
    % (kappaThetaGrow) is the primary guard.
    filt = Filter([], [], max(1e4 * theta0, 1e6 * opts.feasTol));
else
    filt = [];
end
end

function cap = thetaGrowCap(theta0, opts)
%THETAGROWCAP  Absolute ceiling on the violation of an accepted trial step.
%   cap = thetaGrowCap(theta0, opts) returns kappaThetaGrow * max(theta0,
%   feasTol), the most a single accepted line-search step may raise the
%   constraint violation above its current value.  The feasTol floor keeps the
%   cap from collapsing to zero as theta0 -> 0 near a feasible point.  Returns
%   inf when kappaThetaGrow is inf (veto disabled).
%
%   Inputs:
%     theta0 - constraint violation at the current iterate.
%     opts   - resolved options struct (uses kappaThetaGrow, feasTol).
%
%   Outputs:
%     cap - scalar violation ceiling passed to globalize_filterLineSearch.
if ~isfinite(opts.kappaThetaGrow)
    cap = inf;
else
    cap = opts.kappaThetaGrow * max(theta0, opts.feasTol);
end
end

function d = sumBarrierDir(dv, v)
%SUMBARRIERDIR  Directional derivative of a log-barrier term, sum(dv ./ v).
%   Helper for the barrier merit's directional derivative; returns 0 for an
%   empty direction.
%
%   Inputs:
%     dv - direction increment for the barrier argument.
%     v  - current barrier argument (e.g. s, x-lb, or ub-x).
%
%   Outputs:
%     d - sum(dv ./ v), or 0 when dv is empty.
if isempty(dv), d = 0; else, d = sum(dv ./ v); end
end

% ------------------------------------------------------------------------
function c = dualStepCoeff(baseCoeff, dlamE, lamE, opts)
%DUALSTEPCOEFF  Fix B: dual step-size safeguard for the equality multipliers.
%   c = dualStepCoeff(baseCoeff, dlamE, lamE, opts) returns a step coefficient
%   c <= baseCoeff such that ||c*dlamE||_inf <= opts.dualStepMax*max(1,||lamE||).
%   This is a scale-relative dual trust region: it bounds how much a single step
%   may grow the equality multipliers, taming the dlamE blowup produced by a
%   near-singular Schur complement (S = JE*W^{-1}*JE') even in the residual
%   near-null direction that no finite dual regularization can fully remove.  It
%   is inert near the solution (dlamE -> 0) and on well-posed problems (small
%   ||dlamE||), and it touches ONLY the equality-multiplier increment -- primal,
%   slack, and bound/inequality steps keep their own step lengths.  Companion to
%   the scale-aware dual regularization (Fix A) in kkt_inertiaCorrection.
c = baseCoeff;
if isempty(opts) || ~isfield(opts, 'dualStepMax'), return; end
cap = opts.dualStepMax;
if isempty(cap) || ~isfinite(cap) || cap <= 0, return; end
stepNorm = baseCoeff * norm(dlamE, inf);
lim = cap * max(1, norm(lamE, inf));
if stepNorm > lim && stepNorm > 0
    c = baseCoeff * (lim / stepNorm);
end
end

% ------------------------------------------------------------------------
function [d, idx, ksolve] = solveStep(state, res, n, mE, opts, ksolve)
%SOLVESTEP  Solve the (regularized) Newton-KKT system for the primal-dual step.
%   Dispatches to a matrix-free Krylov solve (large systems or when requested)
%   or a direct inertia-corrected factorization. The direct path warm-starts the
%   regularization (delta, gamma) from the previous iteration, decaying it 10x
%   per iteration to avoid over-regularizing.
%
%   Inputs:
%     state  - iterate state struct (H, JE, x, lamE, ...).
%     res    - residual struct (rStat, rFeasE, ...).
%     n      - number of primal variables.
%     mE     - number of equality constraints.
%     opts   - resolved options struct (linearSolver, krylovAutoDim, ...).
%     ksolve - persistent solver-state struct (Fprev, etaPrev, reg).
%
%   Outputs:
%     d      - stacked step [dx; dlamE].
%     idx    - struct with index ranges idx.x and idx.lamE into d.
%     ksolve - updated solver-state struct.
import adamnlopt.*
if nargin < 6 || isempty(ksolve)
    ksolve = struct('Fprev', [], 'etaPrev', [], 'reg', []);
end
useKrylov = strcmpi(opts.linearSolver, 'krylov') || ...
    (strcmpi(opts.linearSolver, 'auto') && (n + mE) > opts.krylovAutoDim);
if useKrylov
    [d, idx, ksolve] = solveStepKrylov(state, res, n, mE, opts, ksolve);
else
    % Direct inertia-corrected KKT solve (see kkt_inertiaCorrection for the
    % delta/gamma growth that certifies inertia (n, mE, 0)).
    % Warm-start regularization from the previous iteration (IPOPT-style):
    % decay by 10x each iteration so we don't over-regularize, but avoid
    % restarting from zero when the problem consistently needs gamma > 0.
    reg0 = [];
    if isfield(ksolve, 'reg'), reg0 = ksolve.reg; end
    if ~isempty(reg0)
        if reg0.delta > 0, reg0.delta = reg0.delta / 10; end
        if reg0.gamma > 0, reg0.gamma = reg0.gamma / 10; end
    end
    [d, idx, info, reg] = kkt_inertiaCorrection(state, res, n, mE, reg0, opts);
    ksolve.reg  = reg;
    ksolve.last = packSolveInfo('direct', info, reg, d, idx, state, res);
    if isfield(info, 'triesExhausted') && info.triesExhausted
        ksolve = warnSilentFailure(ksolve, opts, 'inertiaCorrectionExhausted', ...
            ['Inertia correction hit its 40-try cap without certifying the ' ...
             'KKT inertia (delta = %.3e, gamma = %.3e); the returned step is ' ...
             'not a certified descent direction.  Further occurrences are ' ...
             'not reported -- see output.trace.triesExhausted.'], ...
            reg.delta, reg.gamma);
    end
end
end

% ------------------------------------------------------------------------
function s = packSolveInfo(path, info, reg, d, idx, state, res)
%PACKSOLVEINFO  Flatten one KKT solve's diagnostics into a scalar struct.
%   Every field here is a by-product of a solve that has already happened; this
%   only copies them somewhere the main loop can see. Nothing is read back to
%   make a solver decision, so recording it cannot move a single floating-point
%   result -- the property tests/tIterTrace asserts across trace levels.
%
%   FEASROWRES is the one quantity computed rather than copied. The regularized
%   feasibility row is JE*dx - gamma*dlamE = -cE, so ||JE*dx + rFeasE||_inf is
%   exactly how far the accepted step misses the unregularized linearized
%   constraint -- and it should track gamma*||dlamE||. That identity is what
%   distinguishes "the dual regularization is perturbing the feasibility row"
%   from "the dual regularization is present but inert", which no measurement
%   in this solver could previously tell apart. The cost is one mE-by-n matvec
%   against a factorization that already cost O((n+mE)^3/3).
%
%   STEPSOURCE names which of the four code paths produced the step: 0 the
%   normal KKT solve, 1 the degeneracy regularized recovery, 2 the elastic
%   step. The two recovery paths return before ever reaching a KKT solve, so
%   without their own record the trace would carry the PREVIOUS iteration's
%   conditioning under this iteration's row -- worse than recording nothing.
%
%   Inputs:
%     path  - 'direct' or 'krylov', identifying which core produced the step.
%     info  - info struct from kkt_inertiaCorrection (direct) or [] (krylov).
%     reg   - accepted regularization struct (delta, gamma).
%     d     - stacked step [dx; dlamE].
%     idx   - index struct with fields x and lamE.
%     state - iterate state struct (needs JE for the feasibility residual).
%     res   - residual struct (needs rFeasE for the feasibility residual).
%
%   Outputs:
%     s - scalar struct of diagnostics, ready for IterTrace.record.
s = struct('pathDirect', strcmp(path, 'direct'), 'stepSource', 0, ...
           'delta', NaN, 'gamma', NaN, 'gammaFixA', NaN, ...
           'tries', NaN, 'triesExhausted', NaN, ...
           'inertiaPos', NaN, 'inertiaNeg', NaN, 'inertiaZero', NaN, ...
           'rankDeficient', NaN, 'solved', NaN, ...
           'minAbsPivot', NaN, 'medAbsPivot', NaN, 'maxAbsPivot', NaN, ...
           'pivotSpread', NaN, 'nearlySingular', NaN, ...
           'schurRan', NaN, 'schurCond', NaN, 'schurSMax', NaN, ...
           'schurSMin', NaN, 'schurCaught', NaN, 'schurSkipReason', NaN, ...
           'normDx', NaN, 'normDlamE', NaN, 'feasRowRes', NaN, ...
           'krylovFlag', NaN, 'krylovIters', NaN, 'krylovRelres', NaN);

if ~isempty(reg) && isstruct(reg)
    s.delta = reg.delta;
    s.gamma = reg.gamma;
end
if ~isempty(info) && isstruct(info)
    s = copyIfPresent(s, info, {'tries', 'triesExhausted', 'gammaFixA', ...
                                'rankDeficient', 'solved', 'minAbsPivot', ...
                                'medAbsPivot', 'maxAbsPivot', ...
                                'pivotSpread', 'nearlySingular'});
    if isfield(info, 'inertia') && numel(info.inertia) == 3
        s.inertiaPos  = info.inertia(1);
        s.inertiaNeg  = info.inertia(2);
        s.inertiaZero = info.inertia(3);
    end
    if isfield(info, 'schur') && isstruct(info.schur)
        sc = info.schur;
        s.schurRan        = sc.ran;
        s.schurCond       = sc.cond;
        s.schurSMax       = sc.sMax;
        s.schurSMin       = sc.sMin;
        s.schurCaught     = sc.caught;
        s.schurSkipReason = sc.skipReason;
    end
end

if ~isempty(d) && ~isempty(idx)
    dx    = d(idx.x);
    dlamE = d(idx.lamE);
    s.normDx    = norm(dx, inf);
    s.normDlamE = norm(dlamE, inf);
    JE = getStateField(state, 'JE', []);
    if ~isempty(JE) && isfield(res, 'rFeasE') && ~isempty(res.rFeasE) ...
            && size(JE, 1) == numel(res.rFeasE) && size(JE, 2) == numel(dx)
        s.feasRowRes = norm(JE * dx + res.rFeasE, inf);
    end
end
end

function ksolve = warnSilentFailure(ksolve, opts, id, fmt, varargin)
%WARNSILENTFAILURE  Emit an opt-in warning for a failure the solver swallows.
%   Three conditions -- the inertia correction exhausting its 40 tries, MINRES
%   returning without converging, and the BFGS conditioning recovery flattening
%   the model to a scaled identity -- were previously invisible from outside a
%   solve. The trace now records all three, but a caller who is not reading the
%   trace still gets nothing, which is how they went unnoticed for so long.
%
%   Off by default and at most ONCE PER SOLVE per condition. Both matter: a
%   10000-iteration run that warns every iteration is unreadable, and the tests
%   that convert warnings to errors (tDegeneracy) must stay unaffected. Note
%   this does NOT re-enable MATLAB's own RCOND warnings -- those stay silenced,
%   and pivotSpread is their continuous replacement.
%
%   The once-per-solve state lives on KSOLVE rather than in a PERSISTENT: a
%   persistent would leak across solves and make the suite order-dependent,
%   silently suppressing a warning in one test because an earlier test tripped
%   the same condition.
%
%   Inputs:
%     ksolve   - solver-state struct carrying the already-warned set.
%     opts     - resolved options (warnOnSilentFailure gates everything here).
%     id       - warning identifier suffix, used bare as the state field name.
%     fmt, ... - sprintf-style message.
%
%   Outputs:
%     ksolve - updated state struct with ID marked as warned.
if ~isfield(opts, 'warnOnSilentFailure') || isempty(opts.warnOnSilentFailure) ...
        || ~opts.warnOnSilentFailure
    return;
end
if ~isfield(ksolve, 'warned') || ~isstruct(ksolve.warned)
    ksolve.warned = struct();
end
if isfield(ksolve.warned, id), return; end
ksolve.warned.(id) = true;
warning(['adamnlopt:' id], fmt, varargin{:});
end

function s = copyIfPresent(s, src, names)
%COPYIFPRESENT  Copy the named scalar fields from SRC into S when they exist.
%   Absent fields keep S's NaN sentinel, which is how "never measured" stays
%   distinguishable from "measured to be zero".
for i = 1:numel(names)
    if isfield(src, names{i})
        v = src.(names{i});
        if isscalar(v) && (isnumeric(v) || islogical(v))
            s.(names{i}) = double(v);
        end
    end
end
end

% ------------------------------------------------------------------------
function [d, idx, ksolve] = solveStepKrylov(state, res, n, mE, opts, ksolve)
%SOLVESTEPKRYLOV Inexact-Newton KKT solve (iterative, forcing-sequence tol).
%   The regularization (delta, gamma) is chosen by the same inertia logic as
%   the direct path (kkt_inertiaCorrection), so the Krylov path solves an
%   identically regularized -- and therefore identically descent-certified --
%   system. The step itself is then computed by preconditioned MINRES/GMRES to
%   the Eisenstat-Walker forcing tolerance: only as accurately as the current
%   nonlinear progress warrants, which is the point of an inexact Newton method
%   on large systems. The KKT operator is applied matrix-free, so H may be an
%   operator; only the inertia probe touches an assembled factorization.
%
%   Inputs:
%     state  - iterate state struct (H, JE, x, lamE, ...).
%     res    - residual struct (rStat, rFeasE, ...).
%     n      - number of primal variables.
%     mE     - number of equality constraints.
%     opts   - resolved options struct (forcing-sequence and Krylov settings).
%     ksolve - persistent solver-state struct (Fprev, etaPrev, reg).
%
%   Outputs:
%     d      - stacked step [dx; dlamE].
%     idx    - struct with index ranges idx.x and idx.lamE into d.
%     ksolve - updated solver-state struct (refreshed Fprev, etaPrev).
import adamnlopt.*

idx.x    = 1:n;
idx.lamE = n + (1:mE);
rhs = -[res.rStat; res.rFeasE];

% Inertia-consistent regularization from the direct machinery (reg reused).
[~, ~, kinfo, reg] = kkt_inertiaCorrection(state, res, n, mE, [], opts);

Fk  = norm(rhs);
eta = linalg_forcingSequence(Fk, ksolve.Fprev, ksolve.etaPrev, opts);

% The Eisenstat-Walker term caps the early (loose) solves; a residual-
% proportional floor drives the tolerance to zero near the solution so the
% inexact Newton step becomes asymptotically exact and the tight KKT
% tolerances are attainable.
tol = min(eta, max(opts.forcingEtaMin, 0.1 * Fk));

op = kkt_KKTOperator(state, reg);
applyP = linalg_preconditioner(op, opts);
[d, kryinfo] = linalg_solveKKTkrylov(op, rhs, tol, applyP, opts);

ksolve.Fprev   = Fk;
ksolve.etaPrev = eta;

% MINRES/GMRES non-convergence was previously invisible: the info output was
% discarded at the call site, so an unconverged step entered the line search
% indistinguishably from a converged one.
ksolve.last = packSolveInfo('krylov', kinfo, reg, d, idx, state, res);
ksolve.last.krylovFlag   = kryinfo.flag;
ksolve.last.krylovIters  = kryinfo.iters;
ksolve.last.krylovRelres = kryinfo.relres;
if kryinfo.flag ~= 0
    ksolve = warnSilentFailure(ksolve, opts, 'krylovNotConverged', ...
        ['Krylov KKT solve did not converge (flag %d, %d iterations, ' ...
         'relres %.3e against tol %.3e).  Further occurrences are not ' ...
         'reported -- see output.trace.krylovFlag.'], ...
        kryinfo.flag, kryinfo.iters, kryinfo.relres, tol);
end
end

% ------------------------------------------------------------------------
function hmodel = makeHessianModel(opts, n)
%MAKEHESSIANMODEL  Construct the secant Hessian model, or defer to exact/FD.
%   Dispatches on opts.hessianApprox:
%     'lbfgs' -> LBFGSHessian(n, opts.lbfgsMemory), limited memory.
%     'bfgs'  -> BFGSHessian(n), full memory and dense; lbfgsMemory is ignored.
%   Anything else ('exact', 'fd'), or an explicit HessianFcn, returns [] so the
%   caller routes through lagrangianHessian instead.
%
%   The two secant models are genuinely distinct. 'bfgs' previously aliased to
%   LBFGSHessian, so it silently delivered a limited-memory model with the
%   default memory of 10 pairs.
%
%   Inputs:
%     opts - resolved options struct (HessianFcn, hessianApprox, lbfgsMemory).
%     n    - problem dimension.
%
%   Outputs:
%     hmodel - HessianModel handle object, or [] for exact/FD Hessians.
import adamnlopt.*
hmodel = [];
if ~isempty(opts.HessianFcn)
    return;
end
switch lower(strtrim(char(opts.hessianApprox)))
    case 'lbfgs'
        hmodel = LBFGSHessian(n, opts.lbfgsMemory);
    case 'bfgs'
        hmodel = BFGSHessian(n);
        if isfield(opts, 'bfgsGammaCurvCap') && ~isempty(opts.bfgsGammaCurvCap)
            hmodel.gammaCurvCap = opts.bfgsGammaCurvCap;
        end
        % B0-refresh trigger.  Option name -> property name, since the option
        % prefix disambiguates among Hessian models and the property does not.
        b0Map = {'bfgsB0Refresh',           'b0Refresh'; ...
                 'bfgsB0RefreshWindow',     'b0RefreshWindow'; ...
                 'bfgsB0RefreshFactor',     'b0RefreshFactor'; ...
                 'bfgsB0RefreshRefractory', 'b0RefreshRefractory'; ...
                 'bfgsB0RefreshMaxDrop',    'b0RefreshMaxDrop'; ...
                 'bfgsB0RefreshMinLearned', 'b0RefreshMinLearned'; ...
                 'bfgsResetMaxDrop',        'resetMaxDrop'; ...
                 'bfgsCondMax',             'condMax'};
        for iB0 = 1:size(b0Map, 1)
            if isfield(opts, b0Map{iB0,1}) && ~isempty(opts.(b0Map{iB0,1}))
                hmodel.(b0Map{iB0,2}) = opts.(b0Map{iB0,1});
            end
        end
end
end

function H = currentHessian(hmodel, ev, x, lamE, lamI, opts)
%CURRENTHESSIAN  Return the current Lagrangian Hessian (model or exact/FD).
%   Reads the matrix from the secant model when present, otherwise evaluates the
%   Lagrangian Hessian at (x, lamE, lamI) via lagrangianHessian.
%
%   Inputs:
%     hmodel - HessianModel handle, or [] for exact/FD Hessians.
%     ev     - Evaluator (used for the exact/FD path).
%     x      - current point.
%     lamE   - equality multipliers.
%     lamI   - inequality multipliers.
%     opts   - resolved options struct.
%
%   Outputs:
%     H - n-by-n Hessian (approximation) of the Lagrangian.
import adamnlopt.*
if isempty(hmodel)
    H = lagrangianHessian(ev, x, lamE, lamI, opts);
else
    H = hmodel.getMatrix();
end
end

function hinfo = updateHessianModel(hmodel, gOld, JEold, JIold, gNew, JEnew, JInew, ...
                                    lamE, lamI, sVec)
%UPDATEHESSIANMODEL  Feed a constrained secant pair to the Hessian model.
%   Forms y = gradL(x+, lam+) - gradL(x, lam+), evaluated with the *new*
%   multipliers at both points (Nocedal & Wright, 18.13), and updates the model
%   with the pair (sVec, y). No-op when hmodel is [].
%
%   HINFO reports what the update did. The ACCEPTED flag in particular was
%   computed by BFGSHessian.update and then dropped at this call site, so a
%   model that was silently rejecting most of its curvature pairs (Powell
%   damping failing, s'y at the noise floor) looked identical from outside to
%   one accumulating curvature normally. RESETFIRED is the same story for the
%   conditioning recovery, which flattens B to a scaled identity: nResets was
%   readable only at exit, as a total, with no way to tell which iterations it
%   happened on.
%
%   Inputs:
%     hmodel               - HessianModel handle, or [] (no-op).
%     gOld, JEold, JIold   - objective gradient and Jacobians at the old point.
%     gNew, JEnew, JInew   - objective gradient and Jacobians at the new point.
%     lamE, lamI           - equality and inequality multipliers (new values).
%     sVec                 - primal step x+ - x (i.e. alpha*dx).
%
%   Outputs:
%     hinfo - scalar struct of diagnostics: bfgsAccepted, bfgsResetFired,
%             bfgsNResets, bfgsNUpdates, bfgsGammaLast, bfgsGammaBase,
%             bfgsRebaseFired, condB, secantNormS, secantNormY, secantSY.
%             Fields the model does not expose (LBFGSHessian has no reset
%             counter) stay NaN rather than erroring, so both models share one
%             column set.
%   The model is otherwise updated in place.
%
%   The field names are the TRACE COLUMN names, not the model's property names,
%   because the caller folds this struct into the row wholesale -- a field that
%   does not match a column is silently dropped, which reads as "the model never
%   reported it" rather than as a wiring mistake.
hinfo = struct('bfgsAccepted', NaN, 'bfgsResetFired', NaN, ...
               'bfgsNResets', NaN, 'bfgsNUpdates', NaN, ...
               'bfgsGammaLast', NaN, 'bfgsGammaBase', NaN, ...
               'bfgsRebaseFired', NaN, 'condB', NaN, ...
               'secantNormS', NaN, 'secantNormY', NaN, 'secantSY', NaN);
if isempty(hmodel), return; end
% Constrained secant update: y = gradL(x+, lam+) - gradL(x, lam+), evaluated
% with the *new* multipliers at both points (Nocedal & Wright, 18.13).
gLold = gOld;  gLnew = gNew;
if ~isempty(JEold)
    gLold = gLold + JEold.' * lamE;  gLnew = gLnew + JEnew.' * lamE;
end
if ~isempty(JIold)
    gLold = gLold + JIold.' * lamI;  gLnew = gLnew + JInew.' * lamI;
end
yVec = gLnew - gLold;
% Snapshot the reset counter before the update so resetFired reports THIS
% update's recovery rather than the cumulative total.
nResetsBefore  = readModelProp(hmodel, 'nResets');
nRebasesBefore = readModelProp(hmodel, 'nRebases');
accepted = hmodel.update(sVec, yVec);

hinfo.secantNormS = norm(sVec);
hinfo.secantNormY = norm(yVec);
hinfo.secantSY    = sVec.' * yVec;
if ~isempty(accepted) && isscalar(accepted)
    hinfo.bfgsAccepted = double(accepted);
end
hinfo.bfgsNResets   = readModelProp(hmodel, 'nResets');
hinfo.bfgsNUpdates  = readModelProp(hmodel, 'nUpdates');
hinfo.bfgsGammaLast = readModelProp(hmodel, 'gammaLast');
hinfo.bfgsGammaBase = readModelProp(hmodel, 'gammaBase');
hinfo.condB         = readModelProp(hmodel, 'condLast');
if ~isnan(hinfo.bfgsNResets) && ~isnan(nResetsBefore)
    hinfo.bfgsResetFired = double(hinfo.bfgsNResets > nResetsBefore);
end
% Rebases are counted separately from resets: a reset is a conditioning fault,
% a rebase is a deliberate response to a curvature-regime shift, and a run that
% conflated them would read as unhealthy exactly when the trigger is working.
nRebasesNow = readModelProp(hmodel, 'nRebases');
if ~isnan(nRebasesNow) && ~isnan(nRebasesBefore)
    hinfo.bfgsRebaseFired = double(nRebasesNow > nRebasesBefore);
end
end

function ksolve = warnBfgsReset(ksolve, opts, hinfo, iter)
%WARNBFGSRESET  Report the first BFGS conditioning recovery of the solve.
%   Emitted from here rather than from inside BFGSHessian so the class's public
%   surface -- and tBFGSHessian, which asserts exact nUpdates and nResets == 0 --
%   stays untouched, and so the message can name the iteration.
%
%   A reset is not a failure of the linear algebra; it is the model discarding
%   every curvature pair it has accumulated and falling back to a scaled
%   identity. Steps after one are gradient-like, which looks from the outside
%   exactly like a solver that has stopped making progress.
if isempty(hinfo) || ~isstruct(hinfo) || ~isfield(hinfo, 'bfgsResetFired')
    return;
end
if hinfo.bfgsResetFired == 1
    ksolve = warnSilentFailure(ksolve, opts, 'bfgsReset', ...
        ['BFGS model reset to a scaled identity at iteration %d ' ...
         '(cond(B) = %.3e exceeded the ceiling); accumulated curvature was ' ...
         'discarded.  Further resets are not reported -- see ' ...
         'output.trace.bfgsResetFired.'], iter, hinfo.condB);
end
end

function s = modelSnapshot(hmodel)
%MODELSNAPSHOT  Cumulative Hessian-model counters, without touching the model.
%   The terminal trace row is recorded before any secant update can happen on
%   that iterate, so it would otherwise carry NaN for the reset and update
%   counts -- and the last row is exactly where a reader cross-checks the trace
%   against output.hessianModel. These are cumulative state, so reporting them
%   at the final iterate is honest, not a fabrication.
s = struct('bfgsNResets', NaN, 'bfgsNUpdates', NaN, ...
           'bfgsGammaLast', NaN, 'bfgsGammaBase', NaN, 'condB', NaN);
if isempty(hmodel), return; end
s.bfgsNResets   = readModelProp(hmodel, 'nResets');
s.bfgsNUpdates  = readModelProp(hmodel, 'nUpdates');
s.bfgsGammaLast = readModelProp(hmodel, 'gammaLast');
s.bfgsGammaBase = readModelProp(hmodel, 'gammaBase');
s.condB         = readModelProp(hmodel, 'condLast');
end

function v = readModelProp(hmodel, name)
%READMODELPROP  Read a scalar diagnostic property, NaN when absent.
%   The two Hessian models expose different diagnostics -- LBFGSHessian has no
%   conditioning recovery and therefore no nResets -- so guard with isprop and
%   let the trace column stay NaN rather than making the caller branch on the
%   model class. Mirrors the guard in bfgsDescentProbe.
v = NaN;
if isprop(hmodel, name)
    p = hmodel.(name);
    if isscalar(p) && (isnumeric(p) || islogical(p))
        v = double(p);
    end
end
end

% ------------------------------------------------------------------------
function [alpha, rho] = lineSearch(ev, x, dx, f, g, cE, lamNew, rho)
%LINESEARCH  Backtracking Armijo line search on the l1 merit (equality core).
%   Minimizes phi = f + rho*||cE||_1 along dx, raising rho so the regularized
%   KKT step is a descent direction (rho must dominate the multipliers and make
%   the predicted directional derivative negative; Nocedal & Wright, 18.36).
%
%   Inputs:
%     ev     - Evaluator for trial objective/constraint values.
%     x      - current point.
%     dx     - search direction.
%     f, g   - current objective value and gradient.
%     cE     - current equality constraint values.
%     lamNew - trial multipliers used to lower-bound rho.
%     rho    - current l1 penalty weight.
%
%   Outputs:
%     alpha - accepted step length in (0, 1].
%     rho   - possibly increased l1 penalty weight.
% Backtracking Armijo line search on the l1 merit phi = f + rho*||cE||_1.
% The regularized (inertia-corrected) KKT step is a descent direction for
% this merit provided rho exceeds the multiplier magnitude; the l1 merit --
% unlike the KKT-residual 2-norm -- stays consistent when H is regularized.
theta = norm(cE, 1);
gd = g.' * dx;

% Penalty update (Nocedal & Wright, 18.36): rho must dominate the
% multipliers and make the predicted directional derivative negative.
rho = max(rho, norm(lamNew, inf) + 1e-2);
if theta > 0
    rho = max(rho, gd / theta + 1e-2);
end

phi0 = f + rho * theta;
dphi = gd - rho * theta;   % guaranteed <= 0 by the rho update

alpha = 1;  amin = 1e-10;  c = 1e-4;
while alpha > amin
    xt = x + alpha * dx;
    ft = ev.objective(xt);
    [cEt, ~] = ev.constraints(xt);
    phit = ft + rho * norm(cEt, 1);
    if phit <= phi0 + c * alpha * dphi
        return;
    end
    alpha = 0.5 * alpha;
end
alpha = max(alpha, amin);
end

% ------------------------------------------------------------------------
function [dx, dlamE, predRed] = computeNTStep(H, g, JE, cE, Delta, lamE)
%COMPUTENTSTEP Byrd-Omojokun normal+tangential step bounded by trust-region Delta.
%   The normal step v reduces linearized constraint violation; the tangential
%   step u reduces the quadratic model of the objective in null(JE). For the
%   interior-point path, pass the condensed Hessian W as H and the condensed
%   stationarity residual r1 as g so the tangential step correctly optimizes
%   the condensed barrier objective.
%
%   Inputs:
%     H     - Hessian (or condensed W) of the quadratic model.
%     g     - gradient (or condensed r1) of the quadratic model.
%     JE    - equality Jacobian (possibly augmented with active inequalities).
%     cE    - equality constraint values matching JE.
%     Delta - trust-region radius.
%     lamE  - current equality multipliers (sets the returned dlamE length).
%
%   Outputs:
%     dx      - combined normal + tangential step.
%     dlamE   - least-squares multiplier update (first numel(lamE) entries).
%     predRed - predicted reduction of the quadratic model.
import adamnlopt.*
v      = step_normalStep(JE, cE, Delta);
u      = step_tangentialStep(H, g, JE, v, Delta);
dx     = v + u;
% Least-squares multiplier estimate at the trial point.
% Take only the first numel(lamE) entries so augmented JE rows (from Gap 4
% mode switching) do not widen dlamE beyond the caller's expected size.
nLam  = numel(lamE);
lamNew = step_multiplierUpdate(g + H * dx, JE);
dlamE  = lamNew(1:nLam) - lamE;
% Predicted reduction of the quadratic model.
predRed = -(g.' * dx + 0.5 * dx.' * (H * dx));
end

% ------------------------------------------------------------------------
function [d, idx, ksolve] = detectStep(state, res, n, mE, opts, ksolve)
%DETECTSTEP Compute KKT step with optional degeneracy detection and recovery.
%   When opts.enableDegeneracyDetection is true, inspect the active constraint
%   Jacobian before solving; if rank-deficient, route to a regularized recovery
%   step; if constraints appear locally inconsistent, try an elastic step first.
%
%   Inputs:
%     state  - iterate state struct (H, JE, cE, JI, cI, x, lamE, ...).
%     res    - residual struct (rStat, rFeasE, ...).
%     n      - number of primal variables.
%     mE     - number of equality constraints.
%     opts   - resolved options struct (enableDegeneracyDetection, ...).
%     ksolve - persistent solver-state struct.
%
%   Outputs:
%     d      - stacked step [dx; dlamE].
%     idx    - struct with index ranges idx.x and idx.lamE into d.
%     ksolve - updated solver-state struct.
import adamnlopt.*
if opts.enableDegeneracyDetection
    flags = degeneracy_detectDegeneracy(state, opts);
    if flags.linDepE || flags.linDepActive
        % Rank-deficient active Jacobian: use floor-gamma regularized recovery.
        % Note the output order: regularizedRecovery returns [d, idx, reg, info].
        [d, idx, rreg, rinfo] = degeneracy_regularizedRecovery(state, res, n, mE);
        ksolve.last = packSolveInfo('direct', rinfo, rreg, d, idx, state, res);
        ksolve.last.stepSource = 1;
        return;
    end
    cE_loc = getStateField(state, 'cE', zeros(0,1));
    JE_loc = getStateField(state, 'JE', zeros(0,n));
    cI_loc = getStateField(state, 'cI', zeros(0,1));
    JI_loc = getStateField(state, 'JI', zeros(0,n));
    if norm(cE_loc, 1) > 100 * opts.feasTol && mE > 0
        [dx_e, einfo] = degeneracy_elasticVariables(cE_loc, JE_loc, cI_loc, JI_loc);
        if ~einfo.feasible
            % Linearized equality system is locally inconsistent; use elastic step.
            d = [dx_e; zeros(mE,1)];
            idx.x = 1:n;  idx.lamE = n + (1:mE);
            ksolve.last = packSolveInfo('direct', [], [], d, idx, state, res);
            ksolve.last.stepSource = 2;
            return;
        end
    end
end
[d, idx, ksolve] = solveStep(state, res, n, mE, opts, ksolve);
end

% ------------------------------------------------------------------------
function [JE_eff, cE_eff] = augmentForNearBoundary(JE, cE, JI, cI, advice, state, opts)
%AUGMENTFORNEARBOUNDARY Augment equality system with high-confidence active inequalities.
%   When opts.modeNearBdryAugJE, opts.modeSwitch, and opts.useNTdecomp are all
%   true and the mode controller signals 'nearBoundary', the normal step is also
%   asked to satisfy active inequalities whose per-constraint active-set confidence
%   >= 0.8. The full barrier system for those inequalities is kept intact.
%
%   Inputs:
%     JE     - equality Jacobian.
%     cE     - equality constraint values.
%     JI     - inequality Jacobian (candidate rows to promote).
%     cI     - inequality constraint values.
%     advice - mode-controller advice struct (must be 'nearBoundary' to act).
%     state  - iterate state struct (for active-set confidence).
%     opts   - resolved options struct (mode/augmentation flags).
%
%   Outputs:
%     JE_eff - JE, possibly augmented with high-confidence active inequality rows.
%     cE_eff - cE, augmented consistently with JE_eff.
import adamnlopt.*
JE_eff = JE;  cE_eff = cE;
if ~opts.modeNearBdryAugJE || ~opts.modeSwitch || ~opts.useNTdecomp
    return;
end
if ~strcmp(advice.mode, 'nearBoundary') || isempty(JI)
    return;
end
try
    [~, asinfo] = control_activeSetConfidence(state, opts);
    promote = asinfo.perConstraint >= 0.8;
    if any(promote)
        JE_eff = [JE; JI(promote, :)];
        cE_eff = [cE; cI(promote)];
    end
catch
    % Fall through: leave JE_eff, cE_eff as original.
end
end

% ------------------------------------------------------------------------
function lbl = modeLabel(am, base)
%MODELABEL  Map a mode-controller mode to a short display label.
%   Translates the advice mode into the tag shown in the iteration log.
%
%   Inputs:
%     am   - advice mode string ('nearBoundary', 'feasibility', or other).
%     base - fallback label ('eq' or 'ip') for the standard mode.
%
%   Outputs:
%     lbl - display label ('sqp', 'feas', or base).
switch am
    case 'nearBoundary', lbl = 'sqp';
    case 'feasibility',  lbl = 'feas';
    otherwise,           lbl = base;
end
end

function v = getStateField(s, f, dflt)
%GETSTATEFIELD  Read a state-struct field with a default fallback.
%   Returns s.(f) when present and non-empty, otherwise dflt.
%
%   Inputs:
%     s    - struct to read from.
%     f    - field name (char).
%     dflt - default value returned when the field is absent or empty.
%
%   Outputs:
%     v - the field value or the default.
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = dflt;
end
end

% ------------------------------------------------------------------------
function state = makeState(x, lamE, f, g, cE, JE, JI, iter, nFun, alpha)
%MAKESTATE  Bundle the current equality-core iterate into a state struct.
%   Builds the state consumed by the mode controller, residual assembly,
%   termination test, and logger. Inequality-related fields are empty and mu = 0
%   (the equality core carries no barrier).
%
%   Inputs:
%     x     - primal variables.
%     lamE  - equality multipliers.
%     f, g  - objective value and gradient.
%     cE    - equality constraint values.
%     JE    - equality Jacobian.
%     JI    - inequality Jacobian (may be present but unused by this core).
%     iter  - iteration index.
%     nFun  - cumulative objective evaluation count.
%     alpha - last accepted step length.
%
%   Outputs:
%     state - struct with the above fields plus empty s/lamI/cI, mu = 0,
%             mode = 'eq'.
state = struct();
state.x = x;  state.s = zeros(0,1);
state.lamE = lamE;  state.lamI = zeros(0,1);
state.f = f;  state.g = g;
state.cE = cE;  state.cI = zeros(0,1);
state.JE = JE;  state.JI = JI;
state.iter = iter;  state.nFunEvals = nFun;  state.alpha = alpha;
state.mu = 0;  state.mode = 'eq';
end

function logState(state, res, opts, elapsed, dbg)
%LOGSTATE  Emit one iteration line to the solver logger.
%   Packs the display fields from the current state and residuals and forwards
%   them to util_logger.
%
%   Inputs:
%     state   - iterate state struct (iter, f, mu, alpha, mode, nFunEvals).
%     res     - residual struct (feas, opt, comp).
%     opts    - resolved options struct (Display level, LogFile).
%     elapsed - elapsed wall time in seconds since the core's first iteration.
%     dbg     - (optional) struct of extra diagnostic fields (optRaw, optScaled,
%               normLamE, gateRatio, nActiveBnd, lsAdopted) merged into the
%               logger data; only printed when Display is 'iter-debug', and a
%               field left NaN is shown as a dash.  Pass [] or omit to log only
%               the standard columns.
%
%   Outputs:
%     (none) a line is written to the command window and, when opts.LogFile is
%     set, appended to that file.
import adamnlopt.*
d.iter = state.iter;  d.f = state.f;
d.rFeas = res.feas;  d.rStat = res.opt;  d.rComp = res.comp;
d.mu = state.mu;  d.alpha = state.alpha;  d.mode = state.mode;
d.nFun = state.nFunEvals;  d.elapsed = elapsed;
if nargin >= 5 && ~isempty(dbg)
    fn = fieldnames(dbg);
    for i = 1:numel(fn)
        d.(fn{i}) = dbg.(fn{i});
    end
end
util_logger('iter', opts.Display, d, opts.LogFile);
end

function [x, fval, exitflag, output, lambda, grad, hessian] = ...
        allFixedResult(problem, fx, opts)
%ALLFIXEDRESULT  Answer a problem in which every variable is fixed (lb == ub).
%   With no free variables there is nothing to optimize: x is fully determined by
%   the bounds, and the only remaining question is whether that point is
%   feasible.  The solver cores cannot be run at n = 0 (the KKT system is empty
%   and every residual norm degenerates), so this evaluates the constraints once
%   and reports the verdict directly.
%
%   EXITFLAG is 1 when the forced point satisfies every constraint to feasTol and
%   -2 (local infeasibility -- the flag the cores use when no feasible point can
%   be reached) when it does not.  Reporting 1 on an infeasible forced point
%   would repeat exactly the failure this whole change exists to remove.
%
%   Inputs:
%     problem - the original validated problem struct.
%     fx      - reduction map from REDUCEPROBLEM (fx.nr == 0 here).
%     opts    - resolved options struct.
%
%   Outputs:
%     x, fval, exitflag, output, lambda, grad, hessian - as for SOLVE. grad and
%     hessian follow the same rule as EXPANDRESULT: analytic when available,
%     NaN otherwise, never a fabricated zero.
import adamnlopt.*

x = fx.xFull;
ev = Evaluator(problem, opts);

grad = NaN(fx.n, 1);
gradKnown = false;
if problem.hasObjGrad
    [fval, gAll] = problem.objFun(x);
    gAll = gAll(:);
    if numel(gAll) == fx.n
        grad = gAll;
        gradKnown = true;
    end
else
    fval = problem.objFun(x);
end
hessian = NaN(fx.n, fx.n);

% Feasibility of the forced point, over every constraint class.
[cE, cI] = ev.constraints(x);
feas = 0;
if ~isempty(cE), feas = max(feas, max(abs(cE))); end
if ~isempty(cI), feas = max(feas, max(max(cI), 0)); end

if feas <= opts.feasTol
    exitflag = 1;
    msg = sprintf(['All %d variables are fixed by lb == ub. The forced point is ' ...
                   'feasible (max violation %g); no optimization was performed.'], ...
                  fx.n, feas);
else
    exitflag = -2;
    msg = sprintf(['All %d variables are fixed by lb == ub and the forced point ' ...
                   'is infeasible (max violation %g > feasTol %g). No free ' ...
                   'variable remains to correct it.'], ...
                  fx.n, feas, opts.feasTol);
end

output = struct();
output.iterations      = 0;
output.funcCount       = ev.nFun + 1;
output.firstOrderOpt   = 0;      % no free direction exists to be stationary in
output.constrViolation = feas;
output.complementarity = 0;
output.exitflag        = exitflag;
output.message         = msg;
output.scaling         = struct('applied', false, 'mode', 'none');
output.fdCalibration   = [];
output.fixedVars = struct( ...
    'applied',        true, ...
    'idxFixed',       fx.idxFixed, ...
    'values',         fx.xF, ...
    'nFixed',         fx.nFixed, ...
    'nFree',          0, ...
    'nDropEqLin',     0, ...
    'nDropIneqLin',   0, ...
    'gradKnown',      gradKnown, ...
    'traceIsReduced', false);

% Bound multipliers absorb the whole gradient: with both bounds active at every
% variable, stationarity is g_i = zL_i - zU_i and the sign picks the side (the
% same fmincon convention EXPANDRESULT documents).
zL = zeros(fx.n, 1);  zU = zeros(fx.n, 1);
if gradKnown
    pos = grad > 0;
    zL(pos)  =  grad(pos);
    zU(~pos) = -grad(~pos);
end
lambda = struct('lower', zL, 'upper', zU, ...
                'eqlin', zeros(size(problem.Aeqlin,1),1), ...
                'eqnonlin', zeros(problem.mEnl,1), ...
                'ineqlin', zeros(size(problem.Aineq,1),1), ...
                'ineqnonlin', zeros(problem.mInl,1));

util_logger('final', opts.Display, output, opts.LogFile);
end

% ------------------------------------------------------------------------
function output = makeOutput(state, res, ev, exitflag, msg)
%MAKEOUTPUT  Assemble the fmincon-style OUTPUT struct.
%   Collects iteration counts, function evaluations, and the reported optimality,
%   feasibility, and complementarity measures at termination.
%
%   Inputs:
%     state    - final iterate state struct (iter).
%     res      - final residual struct (opt, feas, comp).
%     ev       - Evaluator (for the cumulative function count).
%     exitflag - termination code.
%     msg      - termination message string.
%
%   Outputs:
%     output - struct with iterations, funcCount, firstOrderOpt,
%              constrViolation, complementarity, exitflag, message. Callers may
%              attach hessianModel (the HessianModel handle) for diagnostics.
output = struct();
output.iterations       = state.iter;
output.funcCount        = ev.nFun;
output.firstOrderOpt    = res.opt;
output.constrViolation  = res.feas;
output.complementarity  = res.comp;
output.exitflag         = exitflag;
output.message          = msg;
end

% ------------------------------------------------------------------------
function T = makeTrace(opts, nIterMax)
%MAKETRACE  Construct the per-iteration diagnostic trace, or [] when disabled.
%   T = makeTrace(opts, nIterMax) returns an IterTrace preallocated for one row
%   per iteration plus the initial point, or [] when opts.traceLevel is 0 (in
%   which case every recordTrace call below is a single isempty test).
%
%   The column list is shared by both solver cores. A core records whichever
%   subset it has and the rest stay NaN, which is why IterTrace ignores unknown
%   fields and defaults missing ones -- the equality core has no barrier
%   parameter, the IP core has no trust-region radius in its default path, and
%   neither should have to know about the other's columns.
%
%   Inputs:
%     opts     - resolved options struct (traceLevel, traceMaxRows).
%     nIterMax - maximum iteration count, used to size the preallocation.
%
%   Outputs:
%     T - IterTrace handle, or [] when tracing is off.
import adamnlopt.*
level = 1;
if isfield(opts, 'traceLevel') && ~isempty(opts.traceLevel)
    level = opts.traceLevel;
end
if level <= 0
    T = [];
    return;
end
maxRows = 20000;
if isfield(opts, 'traceMaxRows') && ~isempty(opts.traceMaxRows)
    maxRows = opts.traceMaxRows;
end
cap = max(1, min(nIterMax + 1, maxRows));
T = IterTrace(traceColumns(), cap, level);
end

function cols = traceColumns()
%TRACECOLUMNS  The trace's fixed column list, grouped by what it answers.
%   Grouped by the question each block settles, because a flat list of fifty
%   names is unreadable and the groups are exactly the competing explanations
%   for a convergence plateau: is it the model, the linear algebra, the metric,
%   or the globalization?
cols = { ...
    ... % --- identity and headline numbers (the printed table, machine-readable)
    'iter', 'nFun', 'f', 'mu', 'feas', 'comp', ...
    ... % --- three optimality metrics side by side.  optPrinted is Fix-F masked
    ... % and Dx-weighted (what the log shows), optScaled is what
    ... % terminationCheck actually gates on, optRaw is neither.  These have
    ... % never appeared in the same table, so a metric artefact -- which has
    ... % precedent on this problem -- was indistinguishable from a real stall.
    'optPrinted', 'optRaw', 'optScaled', 'nActiveBnd', ...
    ... % --- step and multiplier magnitudes
    'aP', 'aD', 'aLamE', 'aBiteRatio', 'normDx', 'normDlamE', ...
    'normLamE', 'normX', 'rho', 'Delta', 'tau', ...
    ... % --- H1: is the Hessian model the problem?
    'bfgsAccepted', 'bfgsResetFired', 'bfgsNResets', 'bfgsNUpdates', ...
    'bfgsGammaLast', 'condB', 'secantSY', 'secantNormS', 'secantNormY', ...
    ... % gammaBase is the scale B actually sits on; gamma0 is the frozen
    ... % first-pair value.  Their ratio is the regime drift the B0-refresh
    ... % trigger acts on, and it is invisible from either one alone.
    'bfgsGammaBase', 'bfgsRebaseFired', ...
    ... % --- H2: is the KKT linear algebra the problem?
    'delta', 'gamma', 'gammaFixA', 'tries', 'triesExhausted', ...
    'inertiaPos', 'inertiaNeg', 'inertiaZero', 'rankDeficient', 'solved', ...
    'minAbsPivot', 'medAbsPivot', 'maxAbsPivot', 'pivotSpread', ...
    'nearlySingular', 'schurRan', 'schurCond', 'schurSMax', 'schurSMin', ...
    'schurCaught', 'schurSkipReason', 'feasRowRes', 'stepSource', ...
    'pathDirect', 'nSolves', 'socAdopted', ...
    'krylovFlag', 'krylovIters', 'krylovRelres', ...
    ... % --- H3: is the multiplier/metric machinery the problem?  lsFired and
    ... % lsAdopted in particular had no signal whatsoever: the costate refresh
    ... % could be running and being discarded every single iteration and
    ... % nothing outside the loop body could tell.
    'lsFired', 'lsAdopted', 'lsOptCur', 'lsOptNew', ...
    ... % --- globalization and the barrier gate
    'lsFailed', 'filterSize', 'structStall', 'statErr', 'gateBase', ...
    'gateRatio', 'Emu', 'feasStallCount', 'objStallCount', 'optGateCount', ...
    'feasRegressCount', 'restorationFired', ...
    ... % --- level 2 only
    'condK'};
end

function sd = kktScaleFactor(state)
%KKTSCALEFACTOR  The smax multiplier scaling terminationCheck divides opt by.
%   Duplicated from terminationCheck rather than exported from it, deliberately:
%   the trace must record what the termination test would compute WITHOUT the
%   trace being able to alter the termination test. Any drift between the two is
%   caught by tIterTrace, which checks the last trace row against the reported
%   firstOrderOpt. See TERMINATIONCHECK for the rationale of the scaling itself.
smax  = 100;
nMult = numel(state.lamE) + numel(state.lamI);
sumMult = sum(abs(state.lamE)) + sum(abs(state.lamI));
if isfield(state, 'zL')
    nMult   = nMult + nnz(state.zL) + nnz(state.zU);
    sumMult = sumMult + sum(state.zL) + sum(state.zU);
end
sd = max(smax, sumMult / max(1, nMult)) / smax;
end

function k = filterCardinality(filt)
%FILTERCARDINALITY  Number of entries in the globalization filter, or NaN.
%   A filter that grows without bound is a globalization pathology (every past
%   iterate forbidding the region around it), and one that stays at a couple of
%   entries through hundreds of iterations says the opposite. Neither was
%   observable from outside makeFilter. Returns NaN when globalization is not
%   filter-based, so the column stays honest rather than reporting a zero.
k = NaN;
if ~isempty(filt) && isprop(filt, 'entries')
    k = size(filt.entries, 1);
end
end

function recordTrace(T, s)
%RECORDTRACE  Append a row to the trace when tracing is enabled.
%   A single guarded call so the main loops read as one line and the disabled
%   case costs one isempty test per iteration.
if ~isempty(T)
    T.record(s);
end
end

function s = finishTraceRow(s, solveInfo, hinfo, aP, aD, aLamE, rho, Delta, ...
                            lsFailed, nSolves, socAdopted, restorationFired)
%FINISHTRACEROW  Fold the end-of-iteration quantities into the row being built.
%   One function rather than a dozen assignments at each of the loop's three
%   exits, so a column added here reaches every exit at once. The alternative --
%   inline assignment blocks -- is how a trace acquires rows that are complete on
%   the ordinary path and quietly truncated on the restoration and early-stop
%   paths, which are the ones worth reading.
%
%   Inputs:
%     s                - partially built row struct (headline fields already set).
%     solveInfo        - packSolveInfo struct for the ADOPTED step, or [].
%     hinfo            - updateHessianModel diagnostics, or [] when no update ran.
%     aP, aD, aLamE    - primal, dual, and equality-costate step fractions.
%     rho, Delta       - merit penalty and trust-region radius.
%     lsFailed         - logical line-search failure flag.
%     nSolves          - number of KKT solves this iteration (1 + SOC retries).
%     socAdopted       - 1 when a second-order correction replaced the step.
%     restorationFired - 1 on the restoration path.
%
%   Outputs:
%     s - the completed row struct, ready for recordTrace.
s = mergeInto(s, solveInfo);
s = mergeInto(s, hinfo);
s.aP = aP;  s.aD = aD;  s.aLamE = aLamE;
% The Fix-B bite ratio: 1 means the cap was inert, < 1 means it actually
% throttled the costate increment. Without the ratio, aLamE alone cannot say
% which, because aD is not always 1 either.
s.aBiteRatio = aLamE / max(aD, realmin);
s.rho = rho;  s.Delta = Delta;
s.lsFailed = double(lsFailed);
s.nSolves = nSolves;
s.socAdopted = socAdopted;
s.restorationFired = restorationFired;
end

function s = mergeInto(s, extra)
%MERGEINTO  Copy the scalar fields of EXTRA into S, overwriting.
%   Used to fold packSolveInfo's and updateHessianModel's diagnostic structs
%   into the row being assembled, without naming every field at the call site.
if isempty(extra) || ~isstruct(extra), return; end
nm = fieldnames(extra);
for i = 1:numel(nm)
    s.(nm{i}) = extra.(nm{i});
end
end

function c = traceCondK(T, state, reg)
%TRACECONDK  Level-2 condition estimate of the assembled KKT matrix.
%   Returns NaN unless the trace is at level 2, so the O(n^3) estimate is never
%   paid for a level-1 run. This is the first caller of linalg_conditionEstimate,
%   which has been built and tested since the package's early days but was wired
%   to nothing.
import adamnlopt.*
c = NaN;
if isempty(T) || T.level < 2, return; end
try
    res0 = struct('rStat', zeros(size(state.H, 1), 1), ...
                  'rFeasE', zeros(size(state.JE, 1), 1));
    K = kkt_assemble(state, res0, reg);
    c = linalg_conditionEstimate(K);
catch
    c = NaN;   % a diagnostic must never be able to break the solve
end
end

function lambda = makeLambda(ev, lamE, lamI, zL, zU)
%MAKELAMBDA  Split internal multipliers into the fmincon LAMBDA struct.
%   Separates the stacked equality/inequality multipliers into their linear and
%   nonlinear blocks using the Evaluator's constraint counts.
%
%   Inputs:
%     ev   - Evaluator providing mElin/mIlin constraint counts.
%     lamE - stacked equality multipliers [linear; nonlinear].
%     lamI - stacked inequality multipliers [linear; nonlinear].
%     zL   - lower-bound multipliers.
%     zU   - upper-bound multipliers.
%
%   Outputs:
%     lambda - struct with fields lower, upper, eqlin, eqnonlin, ineqlin,
%              ineqnonlin.
lambda = struct();
lambda.lower = zL;  lambda.upper = zU;
lambda.eqlin      = lamE(1:ev.mElin);
lambda.eqnonlin   = lamE(ev.mElin+1:end);
lambda.ineqlin    = lamI(1:ev.mIlin);
lambda.ineqnonlin = lamI(ev.mIlin+1:end);
end

function warned = firePlots(warned, opts, info)
%FIREPLOTS  Invoke the per-iteration plot hooks, tolerating their failures.
%   Runs the built-in plot (opts.Plot) and every user PlotFcn (a single handle
%   or a cell array) in a try/catch so a plotting bug can never abort, stall,
%   or change the result of a solve.  The first failure in a solve is reported
%   once with the error message; subsequent failures are swallowed silently
%   (the solve keeps running, the plot just stops drawing).  The built-in plot
%   shares the same protective wrapper, so a stale/deleted figure cannot break
%   the solve either.
%
%   Inputs:
%     warned - logical; true once a plot-hook error has been reported this
%              solve.
%     opts   - resolved options struct (Plot, PlotFcn).
%     info   - per-iteration info struct from PLOTINFO.
%
%   Outputs:
%     warned - updated flag.
import adamnlopt.*

if opts.Plot
    [warned] = safePlotCall(warned, @plotIteration, info, 'built-in plot');
end
if ~isempty(opts.PlotFcn)
    fcn = opts.PlotFcn;
    if ~iscell(fcn), fcn = {fcn}; end
    for i = 1:numel(fcn)
        [warned] = safePlotCall(warned, fcn{i}, info, ...
            sprintf('PlotFcn{%d} (%s)', i, func2str(fcn{i})));
    end
end
end

function [warned, stop, info] = fireIterationFcns(warned, opts, info)
%FIREITERATIONFCNS  Invoke the user iteration functions, tolerating failures.
%   Runs every user IterationFcn (a single handle or a cell array, in array
%   order) in a try/catch so a callback bug can never abort, stall, or change
%   the result of a solve.  The first failure in a solve is reported once with
%   the error message; subsequent failures are swallowed silently (the solve
%   keeps running, the callback just stops firing).  The warning is issued
%   independently of any plot-hook warning: a broken IterationFcn cannot
%   suppress the report of a broken PlotFcn, or vice versa.
%
%   A callback may request an early stop of the solve by returning truthy as
%   its first output (stop = IterationFcn(info)).  On a request the remaining
%   handles in the cell array are still called -- they see the request via
%   info.stop = true, info.exitflag = -1, and info.message -- and the solve
%   then terminates at the current iterate (see the cores).  A request on an
%   iteration the solver is already stopping on is a no-op: the natural
%   stop/exitflag/message stay in place.
%
%   Inputs:
%     warned - logical; true once an iteration-function error has been reported
%              this solve.
%     opts   - resolved options struct (IterationFcn).
%     info   - per-iteration info struct from ITERATIONINFO.
%
%   Outputs:
%     warned - updated flag.
%     stop   - logical; true when a callback requested termination.
%     info   - the input struct, with stop/exitflag/message updated when a
%              callback requested termination on a non-terminal iteration.
stop = false;
if ~isempty(opts.IterationFcn)
    fcn = opts.IterationFcn;
    if ~iscell(fcn), fcn = {fcn}; end
    stop = false;
    for i = 1:numel(fcn)
        [warned, stopNow] = safeHookCall(warned, fcn{i}, info, ...
            sprintf('IterationFcn{%d} (%s)', i, func2str(fcn{i})), ...
            'adamnlopt:IterationFcnFailed', 'iteration-function calls');
        if stopNow && ~info.stop
            % First stop request: record it on the info the later callbacks
            % see, and remember it for the core's termination branch.
            stop = true;
            info.stop = true;
            info.exitflag = -1;
            info.message = 'Stopped: the iteration function requested a stop.';
        end
    end
end
end

function warned = safePlotCall(warned, fcn, info, label)
%SAFEPLOTCALL  Call one plot hook, reporting its first failure per solve.
%   Wraps FCN(INFO) in try/catch: the error is printed once (as a warning,
%   which the caller's error policy can turn into an exception as usual) and
%   then suppressed for the rest of the solve so a broken hook does not spam.
%   A hard error is never raised by the plotting path.
%
%   Inputs:
%     warned - logical; true once a plot-hook error has been reported.
%     fcn    - handle to call with INFO.
%     info   - per-iteration info struct from PLOTINFO.
%     label  - human-readable hook name for the warning text.
%
%   Outputs:
%     warned - updated flag.
warned = safeHookCall(warned, fcn, info, label, ...
    'adamnlopt:PlotFcnFailed', 'plot calls');
end

function [warned, stop] = safeHookCall(warned, fcn, info, label, warnId, noun)
%SAFEHOOKCALL  Call one per-iteration hook, reporting its first failure.
%   Wraps FCN(INFO) in try/catch: the error is printed once (as a warning,
%   which the caller's error policy can turn into an exception as usual) and
%   then the hook is not called again for the rest of the solve, so a broken
%   hook neither spams nor burns time on every iteration.  A hard error is
%   never raised by the hook path.
%
%   STOP is the hook's first output when it returns one: truthy requests a
%   user stop of the solve (see FIREITERATIONFCNS).  A hook with no declared
%   outputs is record-only -- it cannot request a stop -- and is detected by
%   the MATLAB:TooManyOutputs the output probe raises at the call boundary,
%   before the body runs.
%
%   Inputs:
%     warned - logical; true once a hook error has been reported.
%     fcn    - handle to call with INFO.
%     info   - per-iteration info struct (PLOTINFO or ITERATIONINFO).
%     label  - human-readable hook name for the warning text.
%     warnId - MATLAB warning identifier to issue on the first failure.
%     noun   - noun phrase for the warning text ('plot calls').
%
%   Outputs:
%     warned - updated flag.
%     stop   - logical; true when the hook requested a stop.
stop = false;
if warned
    return;
end
try
    stop = fcn(info);
    stop = ~isempty(stop) && stop;
catch err
    if strcmp(err.identifier, 'MATLAB:TooManyOutputs') ...
            || strcmp(err.identifier, 'MATLAB:maxlhs')
        % Record-only hook: it declares no outputs, so it cannot request a
        % stop.  Requesting an output from a zero-output function raises
        % TooManyOutputs at the call boundary, before the body runs; an
        % anonymous function whose expression yields none (e.g.
        % @(info) disp(...)) raises maxlhs the same way.  Run the hook
        % plain.  Either error raised BY the body is a genuine callback
        % failure and is reported below.
        try
            fcn(info);
        catch err2
            warned = true;
            warning(warnId, ...
                ['%s failed at iteration %d; disabling further %s for ' ...
                 'this solve (the solve itself is unaffected).\n  %s: %s'], ...
                label, info.iteration, noun, err2.identifier, err2.message);
        end
        return;
    end
    warned = true;
    warning(warnId, ...
        ['%s failed at iteration %d; disabling further %s for ' ...
         'this solve (the solve itself is unaffected).\n  %s: %s'], ...
        label, info.iteration, noun, err.identifier, err.message);
end
end
