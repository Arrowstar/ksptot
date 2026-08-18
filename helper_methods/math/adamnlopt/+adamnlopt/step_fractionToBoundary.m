function alpha = step_fractionToBoundary(v, dv, tau)
%STEP_FRACTIONTOBOUNDARY  Largest step keeping a positive variable interior.
%   alpha = adamnlopt.step_fractionToBoundary(v, dv, tau) returns the largest
%   alpha in (0, 1] such that  v + alpha*dv >= (1 - tau)*v  componentwise, i.e.
%   the fraction-to-the-boundary rule for a strictly positive vector v with
%   search direction dv. Only negative-direction components can bind. Pass the
%   slacks/bound-distances (primal) or the multipliers (dual) as v.
%
%   Inputs:
%     v   - k-by-1 strictly positive vector (slacks/bound-distances or
%           multipliers) whose positivity must be preserved.
%     dv  - k-by-1 search direction for v.
%     tau - scalar in (0, 1) fraction-to-the-boundary parameter; the step keeps
%           each component at least (1 - tau) of its current value.
%
%   Outputs:
%     alpha - scalar in [0, 1] largest step preserving v + alpha*dv interior.
%
%   See also STEP_NORMALSTEP, STEP_TANGENTIALSTEP.

alpha = 1;
neg = dv < 0;
if any(neg)
    alpha = min(alpha, min(-tau * v(neg) ./ dv(neg)));
end
alpha = max(alpha, 0);
end
