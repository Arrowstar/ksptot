function sc = computeScaling(problem, ev0, opts)
%COMPUTESCALING  Measure variable/objective/constraint scale factors at x0.
%   sc = adamnlopt.computeScaling(problem, ev0, opts) returns a scaling struct
%   used by SCALEPROBLEM and UNSCALERESULT so the solver can run in a well-scaled
%   space transparently. The scaling is measured once, at the initial point x0,
%   from the objective gradient and the folded constraint Jacobian.
%
%   Modes (opts.autoScale):
%     'none'      - identity scaling (sc.applied = false); the caller skips
%                   wrapping entirely, preserving bit-for-bit legacy behaviour.
%     'bounds'    - variable scaling Dx only (from finite bounds range, else the
%                   x0 magnitude); no gradient/Jacobian probe.
%     'gradient'  - (default) Dx as in 'bounds', plus constraint-row scales Dc
%                   (equalities) / Di (inequalities) from the Jacobian probed at
%                   x0, so each scaled row is O(1) (IPOPT-style gradient-based row
%                   scaling; factors never magnify, capped at 1). This is what
%                   cures the frozen-barrier failure mode, where an
%                   ill-conditioned Jacobian drives ||J'*lambda|| huge.
%     'curvature' - 'gradient' plus a curvature-based objective scale: the
%                   objective's diagonal Hessian is probed once at x0 (2n central
%                   second differences) and wf caps the scaled objective
%                   curvature at autoScaleCurvGate per constraint, so a
%                   curvature-dominated objective cannot collapse the reduced
%                   dual system S = JEs*Ws^{-1}*JEs' toward zero (dual-step
%                   divergence). Never magnifies; see CURVATUREOBJSCALE.
%
%   In 'gradient' (and 'bounds') mode the objective is deliberately NOT rescaled
%   (wf stays 1): a gradient-based objective factor is polluted by
%   distance-to-optimum and blind at stationary points, so it loosens the
%   reported first-order optimality without reliably improving conditioning.
%   'curvature' exists for the cases the variable/row rules cannot reach -- the
%   objective's curvature, not the constraint rows, is the stiff quantity. wf is
%   always retained in the struct so the transform code (scaleProblem/
%   unscaleResult) stays general.
%
%   KNOWN LIMITATION: all factors are measured once at x0 and frozen for the
%   whole solve. A constraint row whose gradient vanishes AT x0 (e.g. c = x1*x2
%   started at x1 = 0) keeps d = 1 even if it grows later, since d = min(1,1/r)
%   never magnifies and no x0-probe can see the future row. This is self
%   -limiting in practice: at a solution with bounded objective gradient, a
%   large row forces a correspondingly tiny multiplier (lambda ~ -df/dc), so the
%   scaled stationarity residual JEs'*lambda_s stays O(1) -- the mis-scale
%   cancels in the quantities the Newton system balances (verified empirically
%   up to row scale 1e12). Only adaptive mid-solve re-scaling could cure it, and
%   the observed damage is bounded by the KKT backstops (pivot gating, Fix A/B).
%
%   The scaled space is defined by  x = Dx .* xs  with Dx > 0, so the transforms
%   applied elsewhere are:
%     fs(xs) = wf*f(Dx.*xs),   cEs = Dc.*cE(Dx.*xs),   cIs = Di.*cI(Dx.*xs).
%
%   Inputs:
%     problem - validated problem struct (see VALIDATEPROBLEM): fields x0, lb,
%               ub, n, and the folded constraint counts via ev0.
%     ev0     - Evaluator built from the (unscaled) problem, used to probe the
%               gradient and folded Jacobian at x0 in 'gradient' mode.
%     opts    - options struct; opts.autoScale selects the mode.
%
%   Outputs:
%     sc - scaling struct with fields:
%            mode    - the resolved autoScale mode char.
%            applied - logical; false only for 'none'.
%            Dx      - n-by-1 positive variable scale (x = Dx.*xs).
%            wf      - scalar objective scale (fs = wf*f).
%            Dc      - mE-by-1 equality-row scale (linear rows first).
%            Di      - mI-by-1 inequality-row scale (linear rows first).
%            mElin, mIlin - linear equality/inequality row counts (for splitting
%                     Dc/Di into linear and nonlinear blocks downstream).
%
%   See also SCALEPROBLEM, UNSCALERESULT, DEFAULTOPTIONS.

n  = problem.n;
mE = ev0.mE;
mI = ev0.mI;

mode = 'gradient';
if isfield(opts, 'autoScale') && ~isempty(opts.autoScale)
    mode = lower(char(opts.autoScale));
end

sc = struct();
sc.mode    = mode;
sc.applied = ~strcmp(mode, 'none');
sc.mElin   = ev0.mElin;
sc.mIlin   = ev0.mIlin;
sc.Dx = ones(n, 1);
sc.wf = 1;
sc.Dc = ones(mE, 1);
sc.Di = ones(mI, 1);

if ~sc.applied
    return;
end

% Clamp bounds keep any scale factor inside a numerically safe range.
loClamp = 1e-8;
hiClamp = 1e8;

% --- Variable scaling Dx (both 'bounds' and 'gradient') ---
% Prefer the bound range when both bounds are finite (maps the box to unit
% width); otherwise fall back to the x0 magnitude, floored at 1 so tiny/zero
% components are not blown up.
x0 = problem.x0;
lb = problem.lb;
ub = problem.ub;
Dx = max(1, abs(x0));
bothFinite = isfinite(lb) & isfinite(ub);
rng = ub - lb;
useRange = bothFinite & (rng > 0);
Dx(useRange) = rng(useRange);
Dx = min(hiClamp, max(loClamp, Dx));

% Bound the spread max(Dx)/min(Dx).  The bound range measures box WIDTH, not
% objective CURVATURE; where they disagree the transform x = Dx.*xs maps H to
% Dx.*H.*Dx' and multiplies cond(H) by up to spread^2, so an unbounded spread
% can turn a well-conditioned problem into a numerically singular one and stall
% the solve at a non-stationary point.  Compress geometrically about the
% geometric mean so the correction is symmetric in log-space and no variable is
% privileged.  See opts.autoScaleMaxSpread for the full rationale.
maxSpread = 1e4;
if isfield(opts, 'autoScaleMaxSpread') && ~isempty(opts.autoScaleMaxSpread)
    maxSpread = opts.autoScaleMaxSpread;
end
if isfinite(maxSpread) && maxSpread >= 1 && max(Dx) > maxSpread * min(Dx)
    gm  = exp(mean(log(Dx)));            % geometric centre of the scale set
    lim = sqrt(maxSpread);               % half the spread each side of gm
    Dx  = gm * min(max(Dx / gm, 1 / lim), lim);
    Dx  = min(hiClamp, max(loClamp, Dx));
end
sc.Dx = Dx;

if strcmp(mode, 'bounds')
    return;
end

% --- Constraint-row scaling (gradient-based) ---
% Probe the folded Jacobian at x0. Guard against evaluation failure by falling
% back to variable-only scaling rather than erroring the whole solve. The
% objective is intentionally left unscaled (wf = 1); see the header.
try
    [JE0, JI0] = ev0.jacobian(x0);
catch
    sc.mode = 'bounds';
    return;
end

% Constraint rows measured in the variable-scaled space (row_i(J) .* Dx), so the
% scaled Jacobian JEs = Dc.*JE*diag(Dx) has O(1) rows.
sc.Dc = rowScales(JE0, sc.Dx, loClamp, hiClamp);
sc.Di = rowScales(JI0, sc.Dx, loClamp, hiClamp);

% --- Objective scaling (curvature-based; 'curvature' mode only) ---
% The row rules balance the constraint block, but a curvature-dominated
% OBJECTIVE still collapses the reduced dual system S = JEs*Ws^{-1}*JEs' toward
% zero (S ~ 1/||Ws||), and a gradient-based wf cannot measure it. Probe the
% diagonal of the variable-scaled Hessian at x0 and cap it; inert (wf = 1)
% unless there is a dual system to balance.
if strcmp(mode, 'curvature')
    sc.wf = curvatureObjScale(problem, ev0, opts, sc.Dx, mE, mI);
end
end

% ------------------------------------------------------------------------
function d = rowScales(J, Dx, loClamp, hiClamp)
%ROWSCALES  Per-row scale factors making J*diag(Dx) rows O(1).
%   d_i = min(1, 1/||row_i(J).*Dx||_inf), clamped to [loClamp,hiClamp]; rows that
%   are all zero (or non-finite) get a unit factor.
%
%   Inputs:
%     J       - m-by-n Jacobian block (folded: linear rows first).
%     Dx      - n-by-1 variable scale.
%     loClamp - lower clamp on the returned factors.
%     hiClamp - upper clamp on the returned factors.
%
%   Outputs:
%     d - m-by-1 row scale factors.
m = size(J, 1);
d = ones(m, 1);
if m == 0
    return;
end
rowInf = max(abs(J) .* Dx.', [], 2);   % ||row_i(J).*Dx||_inf
for i = 1:m
    r = rowInf(i);
    if isfinite(r) && r > 0
        d(i) = min(1, 1 / r);
    end
end
d = min(hiClamp, max(loClamp, d));
end

% ------------------------------------------------------------------------
function wf = curvatureObjScale(problem, ev0, opts, Dx, mE, mI)
%CURVATUREOBJSCALE  Objective scale from a diagonal curvature probe at x0.
%   Measures the largest diagonal entry of the variable-scaled Hessian
%   Dx.*H(x0).*Dx' by central second differences (2n extra objective
%   evaluations) and caps it at autoScaleCurvGate relative to the constraint
%   block, so a curvature-dominated objective cannot collapse the reduced dual
%   system S = JEs*Ws^{-1}*JEs' toward zero (dual-step divergence):
%
%       maxCurv = max_i |Dx(i)^2 * Hii(x0)|,   wf = min(1, cap/max(1, maxCurv))
%       cap     = autoScaleCurvGate * max(1, mE + mI)
%
%   The rule is INERT (wf = 1) unless there are constraints (nothing to
%   balance), the problem is larger than autoScaleCurvProbeMaxDim (the probe
%   costs 2n evaluations), the probe fails or returns non-finite curvature, or
%   the measured curvature is already below the cap -- so well-scaled problems
%   and noisy objectives (whose second differences are biased toward noise, and
%   the 1e4 gate absorbs them) are untouched, bit-identical to 'gradient'.
%
%   The step h = 1e-2*max(1,|x0|) is a deliberate order-of-magnitude choice:
%   roundoff error ~ eps*|f|/h^2 is negligible and the truncation term h^2/12
%   vanishes for quadratics, which are the case the probe exists for; the gate
%   absorbs the sloppiness on non-smooth objectives (their second differences
%   scale like 1/h = 1e2, far below the gate).  When the objective supplies an
%   analytic gradient (problem.hasObjGrad) the curvature is probed instead from
%   central differences of g_i: half the evaluations (n, not 2n) and machine
%   accuracy, since the gradient itself is exact.
%
%   Inputs:
%     problem - validated problem struct (fields x0, n).
%     ev0     - Evaluator built from the unscaled problem (probes f at x0).
%     opts    - options struct (autoScaleCurvGate, autoScaleCurvProbeMaxDim).
%     Dx      - n-by-1 variable scale (the FINAL, spread-compressed scale).
%     mE, mI  - equality/inequality row counts (folded, linear rows first).
%
%   Outputs:
%     wf - scalar objective scale factor in (0,1]; 1 when inert.

gate = 1e4;
if isfield(opts, 'autoScaleCurvGate') && ~isempty(opts.autoScaleCurvGate)
    gate = opts.autoScaleCurvGate;
end
maxDim = 400;
if isfield(opts, 'autoScaleCurvProbeMaxDim') && ~isempty(opts.autoScaleCurvProbeMaxDim)
    maxDim = opts.autoScaleCurvProbeMaxDim;
end

wf = 1;
if mE + mI <= 0, return; end          % no dual system to balance
n  = problem.n;
if n > maxDim, return; end            % probe cost 2n evals; skip huge problems

x0 = problem.x0;
h  = 1e-2 * max(1, abs(x0));          % relative central step (order-of-magnitude probe)
maxCurv = 0;
try
    if problem.hasObjGrad
        % Analytic gradient: Hii from central differences of g_i -- n
        % evaluations, machine-accurate (roundoff ~ eps*|g|/h is negligible).
        for i = 1:n
            xp = x0;  xp(i) = x0(i) + h(i);
            xm = x0;  xm(i) = x0(i) - h(i);
            [~, gp] = ev0.objective(xp);
            [~, gm] = ev0.objective(xm);
            c = (gp(i) - gm(i)) / (2 * h(i));
            maxCurv = max(maxCurv, abs(c) * Dx(i)^2);
        end
    else
        % Finite-difference objective: central second difference of f -- 2n
        % evaluations; the noise floor ~ eta/h^2 is absorbed by the gate.
        f0 = ev0.objective(x0);       % reference value (also re-caches at x0)
        for i = 1:n
            xp = x0;  xp(i) = x0(i) + h(i);
            xm = x0;  xm(i) = x0(i) - h(i);
            c  = (ev0.objective(xp) - 2 * f0 + ev0.objective(xm)) / h(i)^2;
            maxCurv = max(maxCurv, abs(c) * Dx(i)^2);
        end
    end
catch
    return;                           % probe failure: stay inert (wf = 1)
end
if ~isfinite(maxCurv) || maxCurv <= 0
    return;                           % non-finite/zero curvature: stay inert
end
wf = min(1, (gate * max(1, mE + mI)) / max(1, maxCurv));
end
