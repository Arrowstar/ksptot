function [d, idx, reg, info] = degeneracy_regularizedRecovery(state, res, n, mE)
%DEGENERACY_REGULARIZEDRECOVERY Stabilized Newton-KKT step for degenerate iterates.
%   [d, idx, reg, info] = adamnlopt.degeneracy_regularizedRecovery(state, res,
%   n, mE) computes a bounded step when the constraint Jacobian is
%   rank-deficient (LICQ failure) by imposing a positive floor on the dual
%   regularization gamma -- a proximal term on the multiplier step, exactly the
%   stabilized-SQP regularization of Wright / Hager. With gamma > 0 the
%   saddle-point matrix is nonsingular and has the correct inertia even when JE
%   loses rank, so the step stays bounded instead of blowing up along the null
%   space of JE'. The floor is tied to the current KKT residual so it vanishes
%   as the iterate converges, preserving the asymptotic Newton rate.
%
%   Delegates the geometric delta/gamma growth to kkt_inertiaCorrection, warm-
%   started from the proximal floor. REG returns the regularization used.
%
%   Inputs:
%     state - current iterate struct passed through to kkt_inertiaCorrection.
%     res   - KKT residual struct; uses res.rStat (stationarity) and res.rFeasE
%             (equality feasibility) to size the dual-regularization floor.
%     n     - number of primal variables.
%     mE    - number of equality constraints.
%
%   Outputs:
%     d    - primal-dual Newton-KKT step from kkt_inertiaCorrection.
%     idx  - index/bookkeeping data returned by kkt_inertiaCorrection.
%     reg  - struct of the regularization actually used (.delta, .gamma).
%     info - diagnostics from kkt_inertiaCorrection, augmented with the
%            proximal floor in info.gammaMin.
%
%   See also DEGENERACY_DETECTDEGENERACY, DEGENERACY_DROPCONSTRAINTS.

import adamnlopt.*

resNorm = norm([res.rStat; res.rFeasE]);
gammaMin = min(1e-2, max(1e-8, 1e-2 * resNorm));
reg0 = struct('delta', 0, 'gamma', gammaMin);

[d, idx, info, reg] = kkt_inertiaCorrection(state, res, n, mE, reg0);
info.gammaMin = gammaMin;
end
