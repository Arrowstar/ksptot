function g = finiteDiffGradient(f, x, f0, h, type, lb, ub)
%FINITEDIFFGRADIENT  Finite-difference gradient of a scalar function.
%   g = adamnlopt.finiteDiffGradient(f, x, f0, h, type) approximates grad f(x).
%   f0 is f(x) (used for forward differences), h the base step, type is
%   'forward' or 'central'. Steps are scaled by max(1,|x_i|), so each per-
%   coordinate perturbation is hi = h*max(1,abs(x(i))). Forward differences cost
%   one extra evaluation per coordinate and reuse f0; central differences cost
%   two per coordinate but are second-order accurate.
%
%   g = adamnlopt.finiteDiffGradient(f, x, f0, h, type, lb, ub) additionally
%   keeps every probe point inside [lb, ub] via FDBOUNDEDSTEP: a coordinate
%   whose forward step would leave the box flips to a backward difference (same
%   cost and order, still reusing f0), and only a coordinate with room on
%   neither side has its step shrunk. A central difference degrades to one-sided
%   per coordinate where the box will not hold both probes, rather than shrinking
%   the step for every coordinate. Omitting lb/ub (or passing empty) restores the
%   unbounded behaviour exactly, which is how opts.HonorBounds = false works.
%
%   Inputs:
%     f    - function handle @(x) returning a scalar objective value.
%     x    - n-by-1 point at which the gradient is approximated.
%     f0   - scalar f(x); used as the base value for forward differences
%            (and for any coordinate that degrades to one-sided).
%     h    - base finite-difference step size (scaled per coordinate).
%     type - 'forward' or 'central' difference scheme.
%     lb   - (optional) n-by-1 lower bounds; empty or omitted for none.
%     ub   - (optional) n-by-1 upper bounds; empty or omitted for none.
%
%   Outputs:
%     g - n-by-1 finite-difference approximation of grad f(x). An entry whose
%         variable is fixed (lb == ub) is 0: there is no feasible direction to
%         difference along.
%
%   See also FINITEDIFFJACOBIAN, FDBOUNDEDSTEP, EVALUATOR.

if nargin < 6, lb = []; end
if nargin < 7, ub = []; end

n = numel(x);
g = zeros(n, 1);
central = strcmp(type, 'central');

hWant = h * max(1, abs(x(:)));
[hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x, hWant, lb, ub);

for i = 1:n
    hi = hs(i);
    if hi == 0
        g(i) = 0;                       % fixed variable: no feasible direction
        continue;
    end
    si = sgn(i);
    xp = x;  xp(i) = xp(i) + si*hi;
    if central && twoSided(i)
        xm = x;  xm(i) = xm(i) - si*hi;
        g(i) = (f(xp) - f(xm)) / (2*si*hi);
    else
        g(i) = (f(xp) - f0) / (si*hi);
    end
end
end
