function [x, info] = degeneracy_restorationPhase(ev, x, lb, ub, opts)
%DEGENERACY_RESTORATIONPHASE Feasibility restoration by violation minimization.
%   [x, info] = adamnlopt.degeneracy_restorationPhase(ev, x, lb, ub, opts) is
%   invoked when the main iteration stalls at an infeasible point: it minimizes
%   the l1 constraint violation
%       theta(x) = ||cE(x)||_1 + ||max(cI(x), 0)||_1
%   by Gauss-Newton steps on the active violation, with Armijo backtracking on
%   theta, and returns a strictly more feasible point for the main solver to
%   resume from. INFO reports .iters, .theta0, .theta, and .reduced.
%
%   The Gauss-Newton trial points are PROJECTED onto the variable bounds
%   [LB, UB] before evaluation, so restoration never leaves the box (e.g. it
%   cannot drive a throttle outside [0,1] or the time-of-flight negative).
%   Backtracking on the projected point keeps the sufficient-decrease test
%   valid: for small step lengths the projection is inactive and the raw
%   Gauss-Newton descent direction is recovered.  The direction is additionally
%   capped in norm relative to ||x||, so a near-rank-deficient Jacobian cannot
%   produce an arbitrarily long jump that the Armijo-on-theta test would still
%   accept.
%
%   Only the currently violated inequalities enter the Gauss-Newton model, so
%   the step attacks exactly the constraints that are infeasible. This is a
%   robust local restoration; it does not attempt to certify global
%   infeasibility (the caller does that when restoration fails to help).
%
%   Inputs:
%     ev   - problem evaluator; uses ev.constraints(x) -> [cE, cI] and
%            ev.jacobian(x) -> [JE, JI] to build the Gauss-Newton model.
%     x    - n-by-1 starting point (projected onto the box before use).
%     lb   - (optional) n-by-1 lower bounds; defaults to -inf.
%     ub   - (optional) n-by-1 upper bounds; defaults to +inf.
%     opts - options struct; uses opts.feasTol to stop once feasibility is met
%            and opts.maxFunEvals to bound the evaluations spent here.
%
%   Outputs:
%     x    - n-by-1 restored (strictly more feasible) point within [lb, ub].
%     info - struct with .iters (iterations taken), .theta0 (initial l1
%            violation), .theta (final l1 violation), .reduced (true if the
%            violation decreased), .evals (user-function calls consumed) and
%            .budgetHit (true when maxFunEvals, not convergence, ended it).
%
%   See also DEGENERACY_ELASTICVARIABLES, DEGENERACY_REGULARIZEDRECOVERY.

if nargin < 3 || isempty(lb), lb = -inf(size(x)); end
if nargin < 4 || isempty(ub), ub =  inf(size(x)); end

maxIt = 50;
restTrustRadius = 10;             % ||dx|| <= this * max(1, ||x||) per GN step
aMin  = 1e-6;                     % Armijo floor: 20 halvings, not 33
x = min(max(x, lb), ub);          % ensure we start inside the box
evStart = ev.totalEvals();        % before theta0: that call is restoration's too
theta0 = viol(ev, x);
theta  = theta0;

% Restoration spends the user's evaluation budget like any other phase, and on a
% black-box problem it is the most expensive phase there is: each of up to 50
% Gauss-Newton iterations costs one constraint evaluation, one JACOBIAN (n or 2n
% nlcon calls when it is finite-differenced), and up to 20 more evaluations
% backtracking.  Nothing here consulted maxFunEvals, so a solve that fell into
% restoration could blow through the budget several times over inside a single
% call and only notice on return.  Stop at the budget and say so in info.
if isfield(opts, 'maxFunEvals') && ~isempty(opts.maxFunEvals)
    evCap = opts.maxFunEvals;
else
    evCap = Inf;
end

% Fully populated up front: every break below used to leave some subset of these
% fields unset, so a first-iteration exit returned an INFO struct with no .iters
% at all and any caller that read it errored.
info = struct('iters', 0, 'theta0', theta0, 'theta', theta0, ...
              'reduced', false, 'evals', 0, 'budgetHit', false, 'stationary', false, ...
              'fdRecalibrated', false);

% A7 in restoration: re-calibrate the FD step at most once per call.
canRecal = isfield(opts, 'autoFDStep') && opts.autoFDStep && ~ev.hasConGrad && ...
    isprop(ev, 'fdStep');
nStag = 0;
for it = 1:maxIt
    if ev.totalEvals() >= evCap
        info.budgetHit = true;
        break;
    end
    [cE, cI] = ev.constraints(x);
    [JE, JI] = ev.jacobian(x);
    act  = cI > 0;
    cvec = [cE; cI(act)];
    J    = [JE; JI(act, :)];

    if isempty(cvec) || norm(cvec) < 1e-12
        break;
    end

    % Local-infeasibility certificate (D20): a stationary point of
    % 0.5*||c||^2 with c ~= 0.  This, not a failed Armijo test, is what should
    % ground the caller's exitflag -2.
    gc = J.' * cvec;
    nc2 = norm(cvec);
    % Bound-aware: a variable ON a bound whose descent component -gc points out
    % of the box is held fixed, and both the step and the certificate use the
    % free variables only.  The bound-blind step projected onto the box was not
    % a descent direction: on lvdExample_MunarFlybyContinuityConstraint one
    % variable at its bound carried 69% of dx, the projected step predicted a
    % 1.7% INCREASE of ||c||^2, every Armijo trial failed, and the ratio test
    % below certified local infeasibility on a feasible problem.
    free = ~((x <= lb & gc > 0) | (x >= ub & gc < 0));
    J(:, ~free) = 0;
    gc(~free)   = 0;
    nJ  = norm(J, 'fro');
    % Scale-free stationarity: the cosine between c and range(J) (free part).
    statRatio = norm(gc) / max(realmin, nJ * nc2);
    if statRatio <= 1e-8
        info.stationary = true;
        break;
    end
    % Proximal (Levenberg-Marquardt) step on 0.5*||c||^2 (A6):
    % dx = -(J'J + zeta*I) \ J'c with zeta = ||J'c|| (Fan-Yuan), floored at
    % 1e-6*||J||_F^2.  It damps the near-null directions of an ill-conditioned
    % J far from stationarity and fades as J'c -> 0.  Measured alternatives:
    % plain Gauss-Newton took 11.8-long steps along the near-null direction of
    % a nearly rank-1 J and crept at alpha ~ 1e-4 for 50 iterations; zeta =
    % ||c||_2 stays large at an infeasible point and made the step linearly
    % convergent there.
    zeta = max(1e-6 * nJ^2, norm(gc));
    dx = -((J.' * J + zeta * eye(size(J, 2))) \ gc);
    if ~all(isfinite(dx))
        dx = lsqminnorm(J, -cvec);
    end
    if norm(dx) < 1e-14
        break;
    end
    % Trust-region cap, relative to the size of the current iterate.  Bound
    % projection and the Armijo test below are the only other limits on dx, and
    % neither bounds its MAGNITUDE: on a near-rank-deficient J -- exactly the
    % regime that sends a stiff multiple-shooting problem into restoration --
    % lsqminnorm can return an enormous direction, and the Armijo test will
    % accept it as long as the l1 violation drops, teleporting the iterate far
    % from where the main solver's secant history and multipliers are valid.
    % Scaling (rather than rejecting) preserves the descent direction.
    dxCap = restTrustRadius * max(1, norm(x));
    if norm(dx) > dxCap
        dx = dx * (dxCap / norm(dx));
    end

    % Armijo on the 2-NORM of the active violation (D20).  The step is a
    % descent direction for 0.5*||c||_2^2, not for the l1 theta: on a
    % rank-deficient J the l1 directional derivative has no sign guarantee, so
    % every trial could fail and restoration returned "not reduced" on a
    % solvable problem.  info.theta stays l1 for the caller.
    a = 1;  accepted = false;
    while a >= aMin
        xt  = min(max(x + a * dx, lb), ub);   % projected trial point
        [tht, th2t] = viol(ev, xt);
        if th2t < (1 - 1e-4 * a) * nc2
            x = xt;  theta = tht;  accepted = true;  break;
        end
        if ev.totalEvals() >= evCap
            info.budgetHit = true;
            break;
        end
        a = 0.5 * a;
    end

    info.iters = it;
    % A7: no sufficient decrease along a direction the Jacobian says is a
    % STRONG descent direction (c far from orthogonal to range(J)) means the
    % Jacobian disagrees with the function -- on a simulation-based constraint,
    % an FD step below the noise floor.  Measured on lvdExample_SpinLaunch-
    % Optimization: constraint noise ~1e-5, calibrated forward step 5e-7 from x0,
    % FD Jacobian 100% off; with a central step >= 1e-5 the same step cut ||c||
    % 0.177 -> 0.111.  Re-calibrate here (the step persists for the main
    % iteration, which differenced the same constraints) and retry.
    if ~accepted && statRatio > 1e-2 && canRecal && ~info.fdRecalibrated
        ev.calibrateStep(x);
        info.fdRecalibrated = true;
        continue;
    end
    % No sufficient decrease along a descent direction for ||c||^2: if c is
    % also nearly orthogonal to range(J), this is the infeasible stationary
    % point (the Armijo test gives up there long before ||J'c|| reaches 0).
    % (1e-2, not tighter: with FD Jacobians the ratio floors near 4e-3 at a
    % genuine infeasible stationary point.)
    if ~accepted && statRatio <= 1e-2
        info.stationary = true;
    end
    % Stagnation: three accepted steps in a row each cutting ||c|| by under
    % 1e-6 relative are not progress.
    if accepted && th2t > (1 - 1e-6) * nc2
        nStag = nStag + 1;
    else
        nStag = 0;
    end
    if nStag >= 3
        info.stationary = statRatio <= 1e-2;
        break;
    end
    if ~accepted || theta < opts.feasTol || info.budgetHit
        break;
    end
end

info.theta   = theta;
info.reduced = theta < theta0;
info.evals   = ev.totalEvals() - evStart;
end

function [t, t2] = viol(ev, x)
%VIOL  Total l1 constraint violation at a point.
%   t = viol(ev, x) evaluates theta(x) = ||cE(x)||_1 + ||max(cI(x), 0)||_1, the
%   merit function minimized during restoration.
%
%   Inputs:
%     ev - problem evaluator providing ev.constraints(x) -> [cE, cI].
%     x  - n-by-1 point at which to measure violation.
%
%   Outputs:
%     t  - scalar total l1 constraint violation.
%     t2 - 2-norm of [cE; max(cI,0)], the quantity the restoration step reduces.
[cE, cI] = ev.constraints(x);
t = 0;
if ~isempty(cE), t = t + norm(cE, 1); end
if ~isempty(cI), t = t + norm(max(cI, 0), 1); end
t2 = norm([cE; max(cI, 0)]);
end
