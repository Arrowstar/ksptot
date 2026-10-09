function state = initializeIterate(ev, problem, opts, fx, sc)
%INITIALIZEITERATE  Build the initial iterate state.
%   state = adamnlopt.initializeIterate(ev, problem, opts) projects x0 strictly
%   inside finite bounds, initializes positive slacks for inequalities, and
%   seeds multipliers from the barrier parameter. A barrier variable is never
%   started exactly at 0.
%
%   state = adamnlopt.initializeIterate(ev, problem, opts, fx, sc) additionally
%   honours a warm start (A3): opts.lambda0, a fmincon-style multiplier struct
%   in physical, full-space units (as a previous solve returned), is mapped
%   onto the reduced, scaled space via initWarmStart instead of seeding from
%   zero/mu0.  fx/sc are the REDUCEPROBLEM map and COMPUTESCALING struct for
%   the problem/ev at hand; omitted (or mismatched) they silently fall back
%   to the cold start.
%
%   Each x0 component is pushed into the strict interior with a relative margin
%   (kappa = 1e-2) so bound-barrier terms are finite. Inequality slacks are set
%   to max(-cI, sMin) with sMin = max(1e-2*||cI||_inf, 1e-10) -- a floor
%   relative to the inequality scale actually present, so the natural slack is
%   preserved on a problem whose residuals are small -- ensuring strict
%   positivity. Inequality multipliers are seeded as mu0/s and the bound
%   multipliers (zL, zU) as mu0/distance-to-bound via the local barrierMult
%   helper. Equality multipliers start at zero; the interior-point core
%   replaces that seed with a least-squares estimate as soon as it has the
%   gradient and Jacobian in hand. The remaining fields prime the barrier,
%   trust region, and bookkeeping counters for the main solve loop.
%
%   Inputs:
%     ev      - Evaluator object; ev.constraints(x) returns [cE, cI] and ev.mE
%               is the number of equality constraints.
%     problem - validated problem struct (uses n, lb, ub, x0).
%     opts    - options struct (uses mu0, delta0, and lambda0/muWarm for A3).
%     fx      - (optional) reduction map for the warm-start mapping.
%     sc      - (optional) scaling struct for the warm-start mapping.
%
%   Outputs:
%     state - initial iterate struct with fields x, s, lamE, lamI, zL, zU, mu,
%             rho, Delta, iter, mode, alpha, nFunEvals.
%
%   See also VALIDATEPROBLEM, DEFAULTOPTIONS, STEP_MULTIPLIERUPDATE, INITWARMSTART.

n  = problem.n;
lb = problem.lb;  ub = problem.ub;
mu0 = opts.mu0;
if nargin < 4, fx = []; end
if nargin < 5, sc = []; end

% Warm-shape pre-check (A3): a well-formed lambda0 means x0 is (meant to be)
% a previous solution, possibly sitting ON its bounds.  The standard 1%
% projection below would move it a hundredth of the box off the solution and
% the relative slack floor would restart the barrier near mu0 -- together
% they discard everything the warm start carries.  A well-formed warm start
% instead gets a micro-projection (just enough for finite barrier terms) and
% slacks consistent with the warm multipliers; anything else keeps the
% standard treatment bit-for-bit.  The s0 vector is a dummy: only the ok flag
% and the multipliers are used here, mu is derived after the real slacks.
[~, ~, ~, ~, ~, warmShapeOk] = adamnlopt.initWarmStart( ...
    getWarmOpt(opts, 'lambda0'), [], [], fx, sc, ev, zeros(ev.mI, 1));

% Strict interior projection with a relative margin.
kappa = 1e-2;
x = problem.x0;
for i = 1:n
    if isfinite(lb(i)) && isfinite(ub(i))
        % Margin must be a FRACTION of the box width, never an absolute floor.
        % max(1, ub-lb) would push a narrow variable (range < 1) by up to the
        % full width of its own box: with lb=0, ub=1e-2 the margin came out at
        % 1e-2, so the clamp min(max(x,lb+1e-2), ub-1e-2) collapsed x onto
        % ub-margin = 0 -- exactly the lower bound, making mu/(x-lb) infinite
        % and poisoning the barrier Hessian with Inf/NaN on the first solve.
        % Cap the two-sided push at kappa of the range so the interval
        % [lb+margin, ub-margin] is always non-empty and strictly interior.
        if warmShapeOk
            margin = 1e-9 * max(1, ub(i) - lb(i));
        else
            margin = kappa * (ub(i) - lb(i));
        end
        x(i) = min(max(x(i), lb(i) + margin), ub(i) - margin);
    elseif isfinite(lb(i))
        if warmShapeOk
            x(i) = max(x(i), lb(i) + 1e-9 * max(1, abs(lb(i))));
        else
            x(i) = max(x(i), lb(i) + kappa * max(1, abs(lb(i))));
        end
    elseif isfinite(ub(i))
        if warmShapeOk
            x(i) = min(x(i), ub(i) - 1e-9 * max(1, abs(ub(i))));
        else
            x(i) = min(x(i), ub(i) - kappa * max(1, abs(ub(i))));
        end
    end
end

[~, cI] = ev.constraints(x);
if warmShapeOk
    % Slacks consistent with the warm multipliers: just cover the violation
    % (and positivity), not the cold 1%-of-scale floor, so that s.*lamI at a
    % resumed solution still reads the converged mu rather than restarting it.
    if isempty(cI)
        s = zeros(0, 1);
    else
        s = max(-cI(:), 1e-10);
    end
    sMin = 1e-10;
else
    % Relative strict-positivity floor; shared with the post-restoration re-seed in
    % solve, which promises to re-seed "exactly as at start-up" and used to carry
    % its own drifted copy of this formula.
    [s, sMin] = adamnlopt.initSlackSeed(cI);
end

state = struct();
state.x = x;
state.s = s;
muFloor = opts.muMin;
if isempty(muFloor), muFloor = 0.1 * opts.optTol; end   % as resolved in solve
[lamEw, lamIw, zLw, zUw, muW, warmOk] = adamnlopt.initWarmStart( ...
    getWarmOpt(opts, 'lambda0'), getWarmOpt(opts, 'muWarm'), ...
    muFloor, fx, sc, ev, s);
if warmOk
    state.lamE = lamEw;
    state.lamI = lamIw;
    state.zL = zLw;
    state.zU = zUw;
    if isempty(muW) || ~isfinite(muW), muW = mu0; end
    state.mu = muW;
else
    state.lamE = zeros(ev.mE, 1);
    state.lamI = mu0 ./ max(s, sMin);
    state.zL = barrierMult(lb, x, mu0, +1);
    state.zU = barrierMult(ub, x, mu0, -1);
    state.mu = mu0;
end
state.rho = 1;
state.Delta = opts.delta0;
state.iter = 0;
state.mode = 'ip';
state.alpha = 0;
state.nFunEvals = 0;
end

function v = getWarmOpt(opts, name)
%GETWARMOPT  opts.(name) when present, else [] (cold start).
%   Direct callers (including unit tests) may hand-build opts without the A3
%   fields; a missing field is simply no warm start, never an error.
v = [];
if isstruct(opts) && isfield(opts, name)
    v = opts.(name);
end
end

function z = barrierMult(bound, x, mu, sgn)%BARRIERMULT  Seed bound multipliers from the barrier parameter.
%   z_i = mu / distance to the (finite) bound, and 0 for infinite bounds. The
%   distance is floored at 1e-8 to avoid division by zero for points on a bound.
%
%   Inputs:
%     bound - n-by-1 bound vector (lb for a lower bound, ub for an upper bound).
%     x     - n-by-1 current point (already projected into the interior).
%     mu    - scalar barrier parameter.
%     sgn   - +1 for a lower bound (distance x-lb), -1 for an upper bound (ub-x).
%
%   Outputs:
%     z - n-by-1 bound multipliers; 0 where the bound is infinite.
% z_i = mu / distance to (finite) bound, 0 for infinite bounds.
n = numel(x);
z = zeros(n, 1);
for i = 1:n
    if isfinite(bound(i))
        d = sgn * (x(i) - bound(i));    % x-lb (+1) or x-ub (-1) -> positive distance
        z(i) = mu / max(d, 1e-8);
    end
end
end
