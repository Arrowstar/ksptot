function H = lagrangianHessian(ev, x, lamE, lamI, opts)
%LAGRANGIANHESSIAN  Hessian of the Lagrangian wrt x.
%   H = adamnlopt.lagrangianHessian(ev, x, lamE, lamI, opts) returns the
%   symmetric Hessian of L = f + lamE'*cE + lamI'*cI. If opts.HessianFcn is
%   supplied it is used directly; otherwise the Hessian is approximated by
%   finite differences of the Lagrangian gradient. (Stage 3 adds L-BFGS.)
%
%   Inputs:
%     ev   - evaluator object exposing objective(x) -> [f, g] and
%            jacobian(x) -> [JE, JI].
%     x    - n-by-1 point at which the Hessian is evaluated.
%     lamE - mE-by-1 equality-constraint multipliers.
%     lamI - mI-by-1 inequality-constraint multipliers.
%     opts - options struct; when opts.HessianFcn is a nonempty handle
%            H = opts.HessianFcn(x, lambda) is used, otherwise finite
%            differences of the Lagrangian gradient are used.
%
%   Outputs:
%     H - n-by-n symmetric Hessian of the Lagrangian at x.
%
%   See also LBFGSHESSIAN, HESSIANVECPRODUCT.

if ~isempty(opts.HessianFcn)
    lambda.eqnonlin   = lamE;
    lambda.ineqnonlin = lamI;
    H = opts.HessianFcn(x, lambda);
    H = (H + H.') / 2;
    return;
end

n = numel(x);
gL = @(z) lagGrad(ev, z, lamE, lamI);
g0 = gL(x);
h = eps^(1/3);
H = zeros(n, n);
for j = 1:n
    hj = h * max(1, abs(x(j)));
    xp = x;  xp(j) = xp(j) + hj;
    H(:, j) = (gL(xp) - g0) / hj;
end
H = (H + H.') / 2;
end

function g = lagGrad(ev, x, lamE, lamI)
%LAGGRAD  Gradient of the Lagrangian wrt x.
%   g = lagGrad(ev, x, lamE, lamI) returns grad(f) + JE'*lamE + JI'*lamI, the
%   gradient of L whose finite differences build the Hessian above.
%
%   Inputs:
%     ev   - evaluator object exposing objective(x) and jacobian(x).
%     x    - n-by-1 point at which the gradient is evaluated.
%     lamE - mE-by-1 equality-constraint multipliers.
%     lamI - mI-by-1 inequality-constraint multipliers.
%
%   Outputs:
%     g - n-by-1 gradient of the Lagrangian at x.
[~, g] = ev.objective(x);
[JE, JI] = ev.jacobian(x);
if ~isempty(JE), g = g + JE.' * lamE; end
if ~isempty(JI), g = g + JI.' * lamI; end
end
