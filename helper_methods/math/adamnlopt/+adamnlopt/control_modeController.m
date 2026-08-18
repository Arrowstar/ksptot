function advice = control_modeController(state, res, history, opts)
%CONTROL_MODECONTROLLER  Level-1 rule-based adaptive parameter adjustment.
%   advice = adamnlopt.control_modeController(state, res, history, opts)
%   inspects the current iterate (STATE, RES) and the recent iteration
%   HISTORY to emit a lightweight advice struct that the solver can use to
%   tune its inner parameters for the next iteration:
%
%     .muFactor        multiplier on the barrier-update denominator (1 = normal)
%     .deltaFactor     multiplier on the trust-region radius (1 = normal)
%     .suggestRestore  true when the controller detects stagnation in theta
%     .mode            'standard' | 'feasibility' | 'nearBoundary'
%
%   All adjustments are advisory; the solver is free to ignore them. When
%   opts.modeSwitch is false the caller should skip this function entirely
%   (but it still returns sensible defaults for robustness).
%
%   Level-1 rules (heuristic, no learning):
%     R1 Feasibility priority: if feas > 100*feasTol → mode='feasibility',
%        slow barrier (muFactor=0.5), preserve trust region.
%     R2 Near convergence: if opt < 100*optTol and activeSetConf >= 0.8
%        → mode='nearBoundary', boost barrier (muFactor=2), small delta OK.
%     R3 Stagnation detection: if |theta_now - theta_old| < 1e-4*theta_now
%        for stagnWindow consecutive iters → suggestRestore=true.
%     R4 Trust-region growth: if last step was full (alpha~1) for 2 iters
%        → deltaFactor=2 (encourage larger steps).
%
%   R1/R2 test the inf-norm optimality/feasibility residuals (res.opt, res.feas)
%   that both solver cores populate and that the termination test uses -- NOT the
%   l1 constraint norm (theta) or res.kktNorm.  Using theta made R1's fixed
%   100*feasTol threshold grow with the constraint count m, latching many-
%   constraint problems permanently in 'feasibility' mode; and res.kktNorm was
%   never populated, so R2's isfinite(kktNorm) guard was always false and the
%   'nearBoundary' endgame could never fire.  The inf-norm residuals are
%   m-independent and consistent with terminationCheck, so the endgame engages
%   exactly when the reported opt/feas say it should.
%
%   Inputs:
%     state   - iterate struct read via the local getf; fields used include
%               theta (constraint violation) and, when theta is 0, cE, cI, s
%               to recompute it, plus the fields consumed downstream by
%               control_activeSetConfidence.
%     res     - residual struct; field kktNorm gives the current KKT error.
%     history - struct of per-iteration logs; fields theta and alpha (vectors)
%               drive the stagnation (R3) and full-step-growth (R4) rules.
%     opts    - options struct with fields feasTol, optTol, modeSwitch, and
%               modeSwitchStagnWindow.
%
%   Outputs:
%     advice - struct with fields muFactor (barrier-update multiplier),
%              deltaFactor (trust-region multiplier), suggestRestore (logical),
%              and mode ('standard' | 'feasibility' | 'nearBoundary').
%
%   See also CONTROL_ACTIVESETCONFIDENCE, CONTROL_BARRIERUPDATE,
%   CONTROL_TRUSTREGIONUPDATE.

stagnWindow = opts.modeSwitchStagnWindow;

advice.muFactor       = 1.0;
advice.deltaFactor    = 1.0;
advice.suggestRestore = false;
advice.mode           = 'standard';

feasTol = opts.feasTol;
optTol  = opts.optTol;

% Inf-norm residuals populated by both solver cores (kkt_residual / ipRes).
% These are the same quantities the termination test uses; unlike the l1
% constraint norm they do not scale with the constraint count.
optNorm  = getf(res, 'opt',  inf);
feasNorm = getf(res, 'feas', 0);

% theta (l1 constraint violation) is retained only for the R3 stagnation test,
% whose threshold is relative (1e-4*theta) and therefore m-robust.
theta   = getf(state, 'theta', 0);
if theta == 0
    cE = getf(state, 'cE', zeros(0,1));
    cI = getf(state, 'cI', zeros(0,1));
    s  = getf(state, 's',  zeros(0,1));
    theta = norm(cE, 1);
    if ~isempty(cI) && ~isempty(s)
        theta = theta + norm(cI + s, 1);
    elseif ~isempty(cE)
        theta = norm(cE, 1);
    end
end

% Active-set confidence (for inequalities).
conf = 0.5;
if isfield(opts, 'modeSwitch') && opts.modeSwitch
    try
        [conf, ~] = adamnlopt.control_activeSetConfidence(state, opts);
    catch
        conf = 0.5;
    end
end

% R1: Feasibility priority (inf-norm feasibility, m-independent).
if feasNorm > 100 * feasTol
    advice.mode      = 'feasibility';
    advice.muFactor  = 0.5;   % slow barrier reduction; focus on feasibility
    advice.deltaFactor = 1.0;
end

% R2: Near convergence with stable active set.  Fires when feasibility is under
% control (so we are genuinely near the boundary, not mid feasibility drive) and
% the inf-norm optimality residual is within 100*optTol.  Evaluated after R1 so
% it takes precedence once feas is small.
%
% P1: additionally gated on complementarity still being out of tolerance.  Once
% comp <= compTol, mu has no remaining job -- boosting its reduction only
% re-derives the duals (z ~ mu/gap) inconsistently and perturbs the iterate,
% feeding the opt 2-cycle at the endgame.  Inert in the equality core, where
% res.comp is 0 and mu does not exist.
compNorm = getf(res, 'comp', inf);
if feasNorm <= 100 * feasTol && optNorm < 100 * optTol && conf >= 0.8 && ...
        compNorm > getf(opts, 'compTol', opts.optTol)
    advice.mode     = 'nearBoundary';
    advice.muFactor = 2.0;   % accelerate barrier reduction
end

% R3: Stagnation in theta.
if ~isempty(history) && numel(history.theta) >= stagnWindow
    recent = history.theta(end-stagnWindow+1:end);
    thetaDrop = max(recent) - min(recent);
    if thetaDrop < 1e-4 * max(theta, 1e-10) && theta > feasTol
        advice.suggestRestore = true;
    end
end

% R4: Consecutive full steps → allow trust-region growth hint.
if ~isempty(history) && numel(history.alpha) >= 2
    if all(history.alpha(end-1:end) >= 0.9)
        advice.deltaFactor = 2.0;
    end
end
end

function v = getf(s, f, dflt)
%GETF  Fetch a struct field with a default fallback.
%   v = getf(s, f, dflt) returns s.(f) when field f exists and is non-empty,
%   otherwise returns dflt. Used to read optional state/res/history fields
%   safely.
%
%   Inputs:
%     s    - struct to read from.
%     f    - char field name to look up.
%     dflt - value returned when the field is absent or empty.
%
%   Outputs:
%     v - the field value s.(f), or dflt.
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = dflt;
end
end
