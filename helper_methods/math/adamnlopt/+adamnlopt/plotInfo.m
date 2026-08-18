function info = plotInfo(state, res, sc, fx, problem, opts, elapsed, stepsize, stop, exitflag, message)
%PLOTINFO  Assemble the per-iteration plot info struct for a solver core.
%   info = adamnlopt.plotInfo(state, res, sc, fx, problem, opts, elapsed,
%   stepsize, stop, exitflag, message) packs everything a plot callback needs
%   at one iterate into a scalar struct, with every quantity mapped back to
%   PHYSICAL units and indexed over the ORIGINAL variables.  Called by the two
%   solver cores once per iteration, immediately after the termination test, so
%   the terminal iterate carries its stop/exitflag/message.
%
%   The inverse scaling is exact and free: the solver has already evaluated the
%   objective and constraints at the current iterate, so plotInfo only divides
%   the folded (scaled) values by their row scales (Dc/Di), multiplies the
%   reduced variables by Dx, and expands fixed variables with fx.  No user
%   function is called, so a plot hook costs the same whether the user supplied
%   analytic derivatives or not, and the plotted constraint values are the very
%   values the iterate was judged on -- not a re-evaluation at a nearby point.
%
%   The termination metrics (criteria) are reproduced from the same numbers
%   terminationCheck gates on: the smax-scaled optimality res.opt/sd, the
%   feasibility norm res.feas, and the smax-scaled complementarity res.comp/sd,
%   each against its tolerance, plus the plateau counters, iteration/function-
%   evaluation/time budgets.  Each criterion carries a CLOSENESS in [0,1] -- the
%   fraction of the way to its "satisfied" point -- which is the indicator the
%   built-in plot (PLOTITERATION) draws.  The three KKT metric criteria carry an
%   additional CLOSENESSLOG: the same notion measured in LOG10 decades over a
%   fixed span, so a value two decades above its tolerance reads visibly "on
%   the way" rather than as the near-zero raw ratio; the counter criteria
%   (plateau windows, iterations, function evaluations, wall time) keep
%   closenessLog = NaN because their linear closeness is the meaningful one.
%
%   Inputs:
%     state    - iterate state struct from the solver core (x, f, g, cE, cI,
%                s, lamE, lamI, zL, zU, iter, nFunEvals, alpha, mu, mode, and
%                the IP-only plateau counters objStallCount/optGateCount).
%     res      - residual struct (opt, feas, comp).
%     sc       - scaling struct from COMPUTESCALING (identity values when
%                scaling is off, so the unscaling formulas are uniform).
%     fx       - fixed-variable reduction map from REDUCEPROBLEM (identity when
%                nothing is fixed).
%     problem  - the ORIGINAL validated problem struct, used for the full
%                linear rows and bounds.
%     opts     - resolved options struct (optTol, feasTol, compTol, the
%                plateau window options, maxIter, maxFunEvals, maxTime).
%     elapsed  - wall seconds since the core started.
%     stepsize - physical-unit norm of the last accepted step (0 at iter 0).
%     stop     - logical; true on the terminal iteration.
%     exitflag - termination code on the terminal iteration.
%     message  - termination message on the terminal iteration.
%
%   Outputs:
%     info - scalar struct documented in DEFAULTOPTIONS (opts.PlotFcn).
%
%   See also PLOTITERATION, UNSCALERESULT, EXPANDRESULT, TERMINATIONCHECK.

% --- Variables: reduced scaled -> reduced physical -> full problem indexing ---
xRed = state.x(:);
if sc.applied
    xRed = sc.Dx .* xRed;
end
xFull = xRed;
if fx.applied
    xFull = fx.xFull;
    xFull(fx.free) = xRed;
end

% --- Objective and gradient (unscaled) ---
fval = state.f / sc.wf;
if ~isempty(state.g)
    grad = state.g(:);
    if sc.applied
        grad = grad ./ (sc.wf * sc.Dx);
    end
    if fx.applied
        gFull = NaN(size(xFull));
        gFull(fx.free) = grad;
        grad = gFull;
    end
else
    grad = [];
end

% --- Constraint values: fold is [linear rows; nonlinear rows], all scaled ---
% The row scales Dc/Di are the exact inverse of the forward scaling (cS =
% Dc.*c), so dividing is exact.  When scaling is off the scales are all ones.
cE = state.cE(:);  cI = state.cI(:);
cEphys = cE;  cIphys = cI;
if ~isempty(cE), cEphys = cE ./ sc.Dc; end
if ~isempty(cI), cIphys = cI ./ sc.Di; end
ceqNl  = cEphys(sc.mElin+1:end);
cNl    = cIphys(sc.mIlin+1:end);

% Linear rows re-derived from the ORIGINAL problem at the full point: this
% re-inserts any rows reduceProblem dropped as vacuous (exactly zero there) and
% costs only two matrix-vector products.
linEq   = problem.Aeqlin * xFull - problem.beqlin;
linIneq = problem.Aineq  * xFull - problem.bineq;
finL = isfinite(problem.lb);
finU = isfinite(problem.ub);
boundLb = xFull(finL) - problem.lb(finL);
boundUb = problem.ub(finU) - xFull(finU);

% --- Physical constraint violation (unscaled max over every constraint class) ---
viol = [abs(linEq); max(linIneq, 0); abs(ceqNl); max(cNl, 0); ...
        boundLb; boundUb];
if isempty(viol)
    constrviolationPhys = 0;
else
    constrviolationPhys = max(viol);
end

% --- Termination metrics, reproduced exactly as terminationCheck sees them ---
sd = kktScaleFactor(state);
optScaled  = res.opt  / sd;
compScaled = res.comp / sd;

criteria = struct('name', {}, 'value', {}, 'limit', {}, 'kind', {}, ...
                  'satisfied', {}, 'closeness', {}, 'closenessLog', {});
criteria = addCriterion(criteria, 'First-order optimality', ...
    optScaled, opts.optTol, 'below', true);
criteria = addCriterion(criteria, 'Constraint violation', ...
    res.feas, opts.feasTol, 'below', true);
criteria = addCriterion(criteria, 'Complementarity', ...
    compScaled, opts.compTol, 'below', true);
% The objective-plateau exit is interior-point only; the equality core's state
% carries no plateau counters, so the criteria are simply absent there rather
% than fabricated.
if isfield(state, 'objStallCount')
    criteria = addCriterion(criteria, 'Objective plateau (stall count)', ...
        state.objStallCount, opts.objPlateauWindow, 'above');
    criteria = addCriterion(criteria, 'Plateau stationarity gate', ...
        state.optGateCount, opts.objPlateauOptWindow, 'above');
end
criteria = addCriterion(criteria, 'Iterations', ...
    state.iter, opts.maxIter, 'above');
criteria = addCriterion(criteria, 'Function evaluations', ...
    state.nFunEvals, opts.maxFunEvals, 'above');
if isfinite(opts.maxTime)
    criteria = addCriterion(criteria, 'Wall time', ...
        elapsed, opts.maxTime, 'above');
end

% --- Assemble the info struct (field list documented in defaultOptions) ---
info = struct();
info.iteration  = state.iter;
info.iter       = state.iter;
info.funcCount  = state.nFunEvals;
info.elapsed    = elapsed;
info.x          = xFull;
info.fval       = fval;
info.grad       = grad;
info.c          = cNl;
info.ceq        = ceqNl;
info.linIneq    = linIneq;
info.linEq      = linEq;
info.boundLb    = boundLb;
info.boundUb    = boundUb;
info.slacks     = state.s;
info.alpha      = state.alpha;
info.mu         = state.mu;
info.stepsize   = stepsize;
info.constrviolation     = res.feas;
info.constrviolationPhys = constrviolationPhys;
info.firstorderopt  = optScaled;
info.optPrinted     = res.opt;
info.complementarity = compScaled;
info.x0         = initialPointFull(problem, fx);
info.lb         = problem.lb(:);
info.ub         = problem.ub(:);
info.mode       = state.mode;
info.criteria   = criteria;
info.stop       = stop;
info.exitflag   = exitflag;
info.message    = message;
end

% ------------------------------------------------------------------------
function criteria = addCriterion(criteria, name, value, limit, kind, logMetric)
%ADDCRITERION  Append one convergence/exit criterion to the criteria array.
%   A criterion is a (value, limit) pair with a KIND saying which side of the
%   limit counts as satisfied, plus a CLOSENESS in [0,1]: the fraction of the
%   way to the satisfied point, where 1 means satisfied.  For a 'below'
%   criterion closeness is limit/value (so a value an order of magnitude under
%   its tolerance reads 1, and one an order over reads 0.1); for an 'above'
%   criterion it is value/limit.  Criteria whose limit is not finite (a budget
%   set to Inf, or a plateau window disabled with Inf) are not applicable and
%   are skipped rather than reported as unsatisfied forever.
%
%   LOGMETRIC (default false) marks the KKT metric criteria (optimality,
%   feasibility, complementarity): those get an additional CLOSENESSLOG
%   computed over log10 decades by LOGCLOSENESS, so the built-in plot can
%   show how many orders of magnitude remain instead of the raw ratio.
%   Counter criteria keep closenessLog = NaN (their linear closeness is the
%   meaningful one).
if nargin < 6
    logMetric = false;
end
if ~isfinite(limit)
    return;
end
if ~isfinite(value)
    % NaN/Inf quantity (e.g. a diverged residual): closeness is unknown, and
    % NaN is the honest indicator -- the plot draws it as "nowhere near".
    closeness = NaN;
    satisfied = false;
elseif strcmp(kind, 'below')
    satisfied = value <= limit;
    closeness = min(1, limit / max(value, realmin));
else
    satisfied = value >= limit;
    closeness = min(1, value / limit);
end
if logMetric
    closenessLog = logCloseness(value, limit, kind);
else
    closenessLog = NaN;
end
k = numel(criteria) + 1;
criteria(k).name         = name;
criteria(k).value        = value;
criteria(k).limit        = limit;
criteria(k).kind         = kind;
criteria(k).satisfied    = satisfied;
criteria(k).closeness    = closeness;
criteria(k).closenessLog = closenessLog;
end

% ------------------------------------------------------------------------
function cl = logCloseness(value, limit, kind)
%LOGCLOSENESS  Log-decade closeness of a metric criterion to its tolerance.
%   The fraction of the way to the tolerance measured in LOG10 space over a
%   fixed DECADES-wide span (6: from the tolerance up to 1e0 when the
%   tolerance is 1e-6).  A value exactly at its tolerance reads 1; one two
%   decades above (1e-4 against 1e-6) reads 1 - 2/6 = 0.667 -- visibly "on
%   the way" -- while the linear closeness would be 0.01.  Values more than
%   DECADES decades away clamp to 0; satisfied values clamp to 1; a
%   non-positive value sits at the extreme (1 for a 'below' criterion, which
%   is satisfied, 0 for 'above'); a non-finite quantity reads NaN (unknown).
DECADES = 6;
if ~isfinite(value) || ~isfinite(limit) || limit <= 0
    cl = NaN;
elseif value <= 0
    if strcmp(kind, 'below'), cl = 1; else, cl = 0; end
else
    d = log10(value) - log10(limit);
    if strcmp(kind, 'below')
        cl = min(1, max(0, 1 - d / DECADES));
    else
        cl = min(1, max(0, 1 + d / DECADES));
    end
end
end

% ------------------------------------------------------------------------
function x0 = initialPointFull(problem, fx)
%INITIALPOINTFULL  The user's initial point, unscaled and fully indexed.
%   problem.x0 is physical and full-length already, so only the fixed-variable
%   reduction needs undoing (the fixed values, which the caller may have left
%   off the fixed coordinates, are replaced by the values the solve used).
%   The interior projection of the starting point is not reconstructible here;
%   the caller's (clipped) point is the right reference for a plot anyway.
x0 = problem.x0(:);
if fx.applied
    x0 = fx.xFull;
    x0(fx.free) = problem.x0(fx.free);
end
end

% ------------------------------------------------------------------------
function sd = kktScaleFactor(state)
%KKTSCALEFACTOR  The smax multiplier scaling terminationCheck divides by.
%   Reproduced here so the reported criteria match the termination test exactly
%   (see terminationCheck and the identical copy in solve.m's kktScaleFactor).
smax  = 100;
nMult = numel(state.lamE) + numel(state.lamI);
sumMult = sum(abs(state.lamE)) + sum(abs(state.lamI));
if isfield(state, 'zL')
    nMult   = nMult + nnz(state.zL) + nnz(state.zU);
    sumMult = sumMult + sum(state.zL) + sum(state.zU);
end
sd = max(smax, sumMult / max(1, nMult)) / smax;
end