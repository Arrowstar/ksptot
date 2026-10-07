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
%            H = opts.HessianFcn(x, lambda) is used, otherwise forward
%            differences of the Lagrangian gradient are used. A valid
%            opts.HessPattern (n-by-n) is honoured: its columns are greedily
%            coloured so structurally independent ones are differenced
%            together, costing one gradient per colour instead of one per
%            variable, and entries outside the pattern stay exactly zero.
%
%   Outputs:
%     H - n-by-n symmetric Hessian of the Lagrangian at x.
%
%   See also LBFGSHESSIAN, HESSIANVECPRODUCT, SPARSITYCOLORING.

if ~isempty(opts.HessianFcn)
    % lamE/lamI are STACKED [linear; nonlinear] (see Evaluator.jacobian and
    % solve>makeLambda).  fmincon's HessianFcn contract gives eqnonlin and
    % ineqnonlin the NONLINEAR multipliers only, so strip the linear rows; a
    % linear constraint has a zero Hessian, so dropping them is exact.  ev may
    % be empty (unit callers with no linear constraints): strip nothing then.
    nLinE = 0;  nLinI = 0;
    if ~isempty(ev) && isprop(ev, 'mElin'), nLinE = ev.mElin;  nLinI = ev.mIlin; end
    lambda.eqnonlin   = lamE(nLinE+1:end);
    lambda.ineqnonlin = lamI(nLinI+1:end);
    H = opts.HessianFcn(x, lambda);
    H = (H + H.') / 2;
    return;
end

import adamnlopt.sparsityColoring

n = numel(x);
gL = @(z) lagGrad(ev, z, lamE, lamI);
g0 = gL(x);
% FORWARD differences, so the step must be the forward-difference optimum
% sqrt(eps) -- not eps^(1/3), which minimizes the CENTRAL-difference error.  At
% eps^(1/3) ~ 6e-6 the O(h) truncation term dominates by three orders of
% magnitude; the whole point of differencing an analytic gradient is to get a
% Hessian better than that.
h = sqrt(eps);
H = zeros(n, n);

% Honour HessPattern.  reduceProblem already sub-selects it onto the free
% variables, and ignoring it here threw that away and paid n gradient
% evaluations unconditionally.  Columns with disjoint row supports can be
% perturbed simultaneously, so a coloured pattern costs one gradient per colour
% instead of one per variable -- the usual order-of-magnitude saving on a banded
% or block-diagonal Lagrangian.
P = hessPatternOf(opts, n);
if isempty(P)
    groups = 1:n;                       % no pattern: every column its own group
else
    groups = sparsityColoring(P);
end

for c = 1:max(groups)
    cols = find(groups == c);
    hj = h * max(1, abs(x(cols)));
    xp = x;  xp(cols) = xp(cols) + hj;
    dg = (gL(xp) - g0);
    for k = 1:numel(cols)
        j = cols(k);
        if isempty(P)
            H(:, j) = dg / hj(k);
        else
            rows = P(:, j);
            H(rows, j) = dg(rows) / hj(k);
        end
    end
end
H = (H + H.') / 2;
end

% ------------------------------------------------------------------
function P = hessPatternOf(opts, n)
%HESSPATTERNOF  Validated n-by-n logical Hessian sparsity pattern, or [].
%   Returns [] (meaning "dense, difference every column separately") when no
%   pattern was supplied or the supplied one is the wrong size -- a mis-sized
%   pattern must not silently zero out real entries. The pattern is symmetrized
%   because the recovery below reads it by column while the result is
%   symmetrized by row.
P = [];
if ~isfield(opts, 'HessPattern') || isempty(opts.HessPattern)
    return;
end
if ~isequal(size(opts.HessPattern), [n n])
    return;
end
P = logical(opts.HessPattern);
P = P | P.';
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
