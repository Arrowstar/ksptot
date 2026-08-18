function sc = util_scaling(ev, x0, opts)
%UTIL_SCALING Objective and constraint scaling factors evaluated at x0.
%   sc = util_scaling(ev, x0, opts) returns a struct with
%       sc.objFactor        scalar scaling for the objective gradient
%       sc.conFactorE       per-row scaling for equality constraints
%       sc.conFactorI       per-row scaling for inequality constraints
%   Each factor caps large gradients so the KKT system, inertia correction,
%   and filter margins see O(1) quantities (gradient-based scaling, capped).
%   The objective factor is min(1, gmax/max(1, ||g||_inf)) with gmax = 100, so
%   small gradients are left untouched and only large ones are scaled down; the
%   constraint factors apply the same rule per Jacobian row (see rowScale).
%
%   Inputs:
%     ev   - evaluator object exposing ev.objective(x) -> [f, g] and
%            ev.jacobian(x) -> [JE, JI] (equality and inequality Jacobians).
%     x0   - n-by-1 point at which the scaling gradients/Jacobians are sampled.
%     opts - options struct (accepted for interface consistency; unused here).
%
%   Outputs:
%     sc - struct with fields objFactor (scalar objective-gradient scaling),
%          conFactorE (mE-by-1 per-row equality scaling), and conFactorI
%          (mI-by-1 per-row inequality scaling).
%
%   See also UTIL_NORMS, KKT_RESIDUAL.

gmax = 100;   % cap: never scale UP small gradients, only scale DOWN large ones
[~, g] = ev.objective(x0);
sc.objFactor = min(1, gmax / max(1, norm(g, Inf)));

[JE, JI] = ev.jacobian(x0);
sc.conFactorE = rowScale(JE, gmax);
sc.conFactorI = rowScale(JI, gmax);
end

function s = rowScale(J, gmax)
%ROWSCALE  Per-row capped scaling factors for a constraint Jacobian.
%   s = rowScale(J, gmax) returns min(1, gmax./max(1, rn)) where rn is the
%   infinity norm of each row of J, so rows with large gradients are scaled
%   down toward O(1) while small rows are left unscaled. Returns a 0-by-1
%   empty when J is empty.
%
%   Inputs:
%     J    - m-by-n constraint Jacobian (empty allowed).
%     gmax - scalar cap above which row norms are scaled down.
%
%   Outputs:
%     s    - m-by-1 per-row scaling factors (0-by-1 empty when J is empty).
if isempty(J)
    s = zeros(0, 1);  return;
end
rn = max(abs(J), [], 2);
s = min(1, gmax ./ max(1, rn));
end
