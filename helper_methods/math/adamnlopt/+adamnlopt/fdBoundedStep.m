function [hs, sgn, twoSided] = fdBoundedStep(x, hWant, lb, ub)
%FDBOUNDEDSTEP  Per-coordinate finite-difference steps that stay inside bounds.
%   [hs, sgn, twoSided] = adamnlopt.fdBoundedStep(x, hWant, lb, ub) takes the
%   desired per-coordinate step magnitudes hWant and returns steps that keep
%   every probe point x + sgn.*hs (and x - hs where twoSided) inside [lb, ub].
%
%   The rule, applied independently per coordinate, is:
%     1. If the forward step fits (x_i + hWant_i <= ub_i), take it: sgn = +1.
%     2. Otherwise, if the same step fits downward (x_i - hWant_i >= lb_i), FLIP
%        to a backward difference: sgn = -1, magnitude unchanged.  This costs the
%        same one evaluation, is the same first order of accuracy, and still
%        reuses the base value f(x) -- so nothing is lost but the direction.
%     3. Only when neither side has room does the step SHRINK, to the larger of
%        the two gaps.  Shrinking is the last resort because it raises the
%        cancellation error, whereas flipping does not.
%     4. A coordinate with no room at all (lb_i == ub_i) is a fixed variable:
%        hs = 0 and sgn = 0.  Callers must read that as "derivative along the
%        feasible set is zero" rather than dividing by the step -- previously
%        such a variable produced a 0/0 gradient entry and the solve returned
%        x = NaN with exitflag 1, a converged status on an all-NaN answer.
%   twoSided reports whether BOTH x_i + hs_i and x_i - hs_i are in the box, i.e.
%   whether a central difference is available for that coordinate; central
%   callers degrade the rest to one-sided per coordinate rather than shrinking
%   the step globally.
%
%   Passing empty (or all-infinite) bounds is the identity: hs = hWant, sgn = +1,
%   twoSided = true, which reproduces the unbounded differencing exactly.  That
%   is how opts.HonorBounds = false is implemented at the call sites.
%
%   Inputs:
%     x     - n-by-1 point at which the derivative is being approximated.
%     hWant - desired step magnitude; scalar or n-by-1, positive.
%     lb    - n-by-1 lower bounds (may be -Inf), or empty for none.
%     ub    - n-by-1 upper bounds (may be +Inf), or empty for none.
%
%   Outputs:
%     hs       - n-by-1 step magnitudes, >= 0 (0 only for a fixed variable).
%     sgn      - n-by-1 of +1 (forward), -1 (backward), or 0 (fixed variable).
%     twoSided - n-by-1 logical; true where a central difference fits in the box.
%
%   See also FINITEDIFFGRADIENT, FINITEDIFFJACOBIAN, PARALLEL_PARALLELFINITEDIFF.

x = x(:);
n = numel(x);
if isscalar(hWant)
    hs = repmat(hWant, n, 1);
else
    hs = hWant(:);
end
sgn = ones(n, 1);

if isempty(lb) && isempty(ub)
    twoSided = true(n, 1);
    return;
end
if isempty(lb), lb = -Inf(n, 1); else, lb = lb(:); end
if isempty(ub), ub =  Inf(n, 1); else, ub = ub(:); end

% Room on each side.  Clamp at 0 so an x already outside the box (which
% HonorBounds prevents at x0, but a caller-supplied evaluation point could still
% be) never produces a negative step.
roomUp = max(ub - x, 0);
roomDn = max(x - lb, 0);

fitsUp = hs <= roomUp;
fitsDn = hs <= roomDn;

flip = ~fitsUp & fitsDn;                 % rule 2: same magnitude, other direction
sgn(flip) = -1;

squeeze_ = ~fitsUp & ~fitsDn;            % rule 3: neither side fits, take the larger gap
if any(squeeze_)
    useUp = roomUp(squeeze_) >= roomDn(squeeze_);
    room  = max(roomUp(squeeze_), roomDn(squeeze_));
    s     = -ones(nnz(squeeze_), 1);
    s(useUp) = 1;
    hs(squeeze_)  = room;
    sgn(squeeze_) = s;
end

fixed = hs <= 0;                         % rule 4: lb == ub, no room in either direction
hs(fixed)  = 0;
sgn(fixed) = 0;

twoSided = (hs <= roomUp) & (hs <= roomDn) & ~fixed;
end
