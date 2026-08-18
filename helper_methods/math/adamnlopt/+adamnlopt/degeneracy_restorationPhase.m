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
%     opts - options struct; uses opts.feasTol to stop once feasibility is met.
%
%   Outputs:
%     x    - n-by-1 restored (strictly more feasible) point within [lb, ub].
%     info - struct with .iters (iterations taken), .theta0 (initial l1
%            violation), .theta (final l1 violation), and .reduced (true if the
%            violation decreased).
%
%   See also DEGENERACY_ELASTICVARIABLES, DEGENERACY_REGULARIZEDRECOVERY.

if nargin < 3 || isempty(lb), lb = -inf(size(x)); end
if nargin < 4 || isempty(ub), ub =  inf(size(x)); end

maxIt = 50;
restTrustRadius = 10;             % ||dx|| <= this * max(1, ||x||) per GN step
x = min(max(x, lb), ub);          % ensure we start inside the box
theta0 = viol(ev, x);
theta  = theta0;

for it = 1:maxIt
    [cE, cI] = ev.constraints(x);
    [JE, JI] = ev.jacobian(x);
    act  = cI > 0;
    cvec = [cE; cI(act)];
    J    = [JE; JI(act, :)];

    if isempty(cvec) || norm(cvec) < 1e-12
        break;
    end

    dx = lsqminnorm(J, -cvec);      % Gauss-Newton feasibility direction
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

    a = 1;  accepted = false;
    while a > 1e-10
        xt  = min(max(x + a * dx, lb), ub);   % projected trial point
        tht = viol(ev, xt);
        if tht < (1 - 1e-4 * a) * theta
            x = xt;  theta = tht;  accepted = true;  break;
        end
        a = 0.5 * a;
    end

    info.iters = it;
    if ~accepted || theta < opts.feasTol
        break;
    end
end

if ~exist('it', 'var'), info.iters = 0; end
info.theta0  = theta0;
info.theta   = theta;
info.reduced = theta < theta0;
end

function t = viol(ev, x)
%VIOL  Total l1 constraint violation at a point.
%   t = viol(ev, x) evaluates theta(x) = ||cE(x)||_1 + ||max(cI(x), 0)||_1, the
%   merit function minimized during restoration.
%
%   Inputs:
%     ev - problem evaluator providing ev.constraints(x) -> [cE, cI].
%     x  - n-by-1 point at which to measure violation.
%
%   Outputs:
%     t - scalar total l1 constraint violation.
[cE, cI] = ev.constraints(x);
t = 0;
if ~isempty(cE), t = t + norm(cE, 1); end
if ~isempty(cI), t = t + norm(max(cI, 0), 1); end
end
