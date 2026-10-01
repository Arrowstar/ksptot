function rdMetric = util_projectedGradient(rd, zL, zU, activeL, activeU)
%UTIL_PROJECTEDGRADIENT  Bound-projected dual residual for the optimality metric.
%   rdMetric = adamnlopt.util_projectedGradient(rd, zL, zU, activeL, activeU)
%   returns the stationarity residual with the rows of bound-active variables
%   replaced by their projected gradient, which is the first-order optimality
%   measure that respects the sign of an active bound.
%
%   rd is the full dual residual g + JE'*lamE + JI'*lamI - zL + zU, so the
%   reduced gradient without the bound duals is rdFree = rd + zL - zU.
%   First-order optimality at a variable pinned at its LOWER bound is
%   rdFree_i >= 0 and at one pinned at its UPPER bound rdFree_i <= 0, so the
%   violations are min(rdFree_i, 0) and max(rdFree_i, 0) respectively. A free
%   variable keeps its full row.
%
%   This replaces masking the pinned rows out of the metric, which failed two
%   ways: masking EVERY row (every variable pinned) produced an identically
%   zero metric and so an unconditional convergence report at an arbitrary
%   point, and masking accepted a row of either sign, hiding a variable pinned
%   against the gradient -- a genuine first-order violation. The projection
%   gives exactly zero for a pinned variable that IS optimal (what the mask was
%   reaching for) and the full magnitude for one pinned the wrong way (what the
%   mask hid), with no all-masked special case to guard.
%
%   Inputs:
%     rd      - n-by-1 dual residual (stationarity row) including the bound
%               multiplier terms -zL + zU.
%     zL, zU  - n-by-1 lower/upper bound multipliers (0 where the bound is
%               infinite).
%     activeL - n-by-1 logical; true where the variable is pinned at its lower
%               bound.
%     activeU - n-by-1 logical; true where the variable is pinned at its upper
%               bound.
%
%   Outputs:
%     rdMetric - n-by-1 residual for the optimality norm. Identical to rd on
%                free rows; projected on active ones; exactly zero where a
%                variable is pinned at both bounds (any sign is stationary when
%                the variable cannot move).
%
%   See also KKT_RESIDUAL, TERMINATIONCHECK, UTIL_NORMS.

rdMetric = rd;
if ~any(activeL | activeU)
    return;
end
rdFree = rd + zL - zU;
rdMetric(activeL) = min(rdFree(activeL), 0);
rdMetric(activeU) = max(rdFree(activeU), 0);
rdMetric(activeL & activeU) = 0;
end
