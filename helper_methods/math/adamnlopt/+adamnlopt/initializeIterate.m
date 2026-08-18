function state = initializeIterate(ev, problem, opts)
%INITIALIZEITERATE  Build the initial iterate state.
%   state = adamnlopt.initializeIterate(ev, problem, opts) projects x0 strictly
%   inside finite bounds, initializes positive slacks for inequalities, and
%   seeds multipliers from the barrier parameter. A barrier variable is never
%   started exactly at 0.
%
%   Each x0 component is pushed into the strict interior with a relative margin
%   (kappa = 1e-2) so bound-barrier terms are finite. Inequality slacks are set
%   to max(-cI, sMin) with sMin = 1e-2, ensuring strict positivity. Inequality
%   multipliers are seeded as mu0/s and the bound multipliers (zL, zU) as
%   mu0/distance-to-bound via the local barrierMult helper. Equality
%   multipliers start at zero. The remaining fields prime the barrier, trust
%   region, and bookkeeping counters for the main solve loop.
%
%   Inputs:
%     ev      - Evaluator object; ev.constraints(x) returns [cE, cI] and ev.mE
%               is the number of equality constraints.
%     problem - validated problem struct (uses n, lb, ub, x0).
%     opts    - options struct (uses mu0, delta0).
%
%   Outputs:
%     state - initial iterate struct with fields x, s, lamE, lamI, zL, zU, mu,
%             rho, Delta, iter, mode, alpha, nFunEvals.
%
%   See also VALIDATEPROBLEM, DEFAULTOPTIONS, STEP_MULTIPLIERUPDATE.

n  = problem.n;
lb = problem.lb;  ub = problem.ub;
mu0 = opts.mu0;

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
        margin = kappa * (ub(i) - lb(i));
        x(i) = min(max(x(i), lb(i) + margin), ub(i) - margin);
    elseif isfinite(lb(i))
        x(i) = max(x(i), lb(i) + kappa * max(1, abs(lb(i))));
    elseif isfinite(ub(i))
        x(i) = min(x(i), ub(i) - kappa * max(1, abs(ub(i))));
    end
end

[~, cI] = ev.constraints(x);
sMin = 1e-2;
s = max(-cI, sMin);

state = struct();
state.x = x;
state.s = s;
state.lamE = zeros(ev.mE, 1);
state.lamI = mu0 ./ max(s, sMin);
state.zL = barrierMult(lb, x, mu0, +1);
state.zU = barrierMult(ub, x, mu0, -1);
state.mu = mu0;
state.rho = 1;
state.Delta = opts.delta0;
state.iter = 0;
state.mode = 'ip';
state.alpha = 0;
state.nFunEvals = 0;
end

function z = barrierMult(bound, x, mu, sgn)
%BARRIERMULT  Seed bound multipliers from the barrier parameter.
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
