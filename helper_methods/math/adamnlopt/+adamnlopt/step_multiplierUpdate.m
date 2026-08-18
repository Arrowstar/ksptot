function lamE = step_multiplierUpdate(g, JE, w)
%STEP_MULTIPLIERUPDATE  Least-squares estimate of equality multipliers.
%   lamE = adamnlopt.step_multiplierUpdate(g, JE) returns the multipliers that
%   minimize ||g + JE'*lamE||, i.e. the first-order (Lagrange) estimate used to
%   seed the iteration and to refresh the costates. Returns empty when there
%   are no equality constraints. A rank-deficient JE (e.g. parallel constraint
%   gradients when LICQ fails) still yields a usable least-squares seed; the
%   associated cosmetic warnings are suppressed locally.
%
%   lamE = adamnlopt.step_multiplierUpdate(g, JE, w) minimizes the WEIGHTED norm
%   ||w .* (g + JE'*lamE)|| instead.  With w = 1./Dx (the scale-consistent
%   optimality weight) the fit is measured in physical-gradient units, so a wide
%   variable-scale spread does not let the large-scale rows dominate the estimate
%   and abandon the reduced gradient at a small-scale variable.  Omitting w (or
%   passing []) recovers the unweighted estimate.
%
%   Inputs:
%     g   - n-by-1 gradient of the objective (or of the Lagrangian term being
%           balanced) at the current point.
%     JE  - mE-by-n Jacobian of the equality constraints. Pass empty when there
%           are no equality constraints.
%     w   - (optional) n-by-1 row weight applied to (g + JE'*lamE) before the
%           least-squares fit; defaults to all ones (unweighted).
%
%   Outputs:
%     lamE - mE-by-1 least-squares equality multipliers, or a 0-by-1 empty
%            vector when JE is empty.
%
%   See also STEP_NORMALSTEP, KKT_RESIDUAL.

if isempty(JE)
    lamE = zeros(0, 1);
    return;
end
% Solve JE' * lamE ~= -g (optionally row-weighted) in the least-squares sense. A
% rank-deficient JE (e.g. parallel constraint gradients when LICQ fails at the
% start point) only produces an advisory warning; the backslash least-squares
% estimate is still a usable seed, so silence the cosmetic warning locally.
ws1 = warning('off', 'MATLAB:rankDeficientMatrix');
ws2 = warning('off', 'MATLAB:singularMatrix');
ws3 = warning('off', 'MATLAB:illConditionedMatrix');
cleanup = onCleanup(@() warning([ws1, ws2, ws3]));
if nargin < 3 || isempty(w)
    lamE = JE.' \ (-g);
else
    w = w(:);
    lamE = (JE.' .* w) \ (-(w .* g));
end
end
