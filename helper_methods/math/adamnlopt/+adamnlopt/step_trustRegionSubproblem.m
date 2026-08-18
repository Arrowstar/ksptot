function [p, info] = step_trustRegionSubproblem(H, g, Delta, tol, maxIter)
%STEP_TRUSTREGIONSUBPROBLEM  Steihaug-Toint truncated CG for the TR subproblem.
%   [p, info] = adamnlopt.step_trustRegionSubproblem(H, g, Delta) approximately
%   solves
%       min_p  m(p) = g'*p + 0.5*p'*H*p   s.t.  ||p|| <= Delta
%   by preconditioner-free conjugate gradients (Steihaug 1983). CG proceeds
%   until (a) it converges inside the trust region, (b) it hits the boundary,
%   or (c) it encounters a direction of nonpositive curvature -- in cases (b)
%   and (c) the iterate is pushed to the trust-region boundary along the
%   current search direction. H may be a dense matrix or any object accepted
%   by adamnlopt.hessianVecProduct (e.g. an LBFGSHessian operator), so the
%   solve is matrix-free.
%
%   INFO reports .iter, .boundary (hit the TR wall), .negCurv (nonpositive
%   curvature encountered), and .predRed (predicted reduction -m(p) >= 0).
%
%   Inputs:
%     H       - n-by-n Hessian model (dense symmetric matrix or an object
%               accepted by adamnlopt.hessianVecProduct).
%     g       - n-by-1 gradient of the model at p = 0.
%     Delta   - scalar trust-region radius bounding ||p||.
%     tol     - (optional) residual tolerance for CG convergence; defaults to
%               min(0.5, sqrt(norm(g)))*norm(g).
%     maxIter - (optional) maximum CG iterations; defaults to 2*n + 10.
%
%   Outputs:
%     p    - n-by-1 approximate minimizer with ||p|| <= Delta.
%     info - struct with fields .iter (CG iterations), .boundary (true if the
%            step reached the TR wall), .negCurv (true if nonpositive curvature
%            was encountered), and .predRed (predicted reduction -m(p) >= 0).
%
%   See also STEP_TANGENTIALSTEP, STEP_NORMALSTEP, HESSIANVECPRODUCT.

import adamnlopt.*

g = g(:);
n = numel(g);
if nargin < 4 || isempty(tol),     tol = min(0.5, sqrt(norm(g))) * norm(g); end
if nargin < 5 || isempty(maxIter), maxIter = 2 * n + 10; end

p = zeros(n, 1);
info = struct('iter', 0, 'boundary', false, 'negCurv', false, 'predRed', 0);

if norm(g) <= tol
    return;
end

r = g;              % residual = grad of model at p = 0
dvec = -r;          % initial search direction
rr = r.' * r;

for k = 1:maxIter
    Hd = hessianVecProduct(H, dvec);
    dHd = dvec.' * Hd;

    if dHd <= 0
        % Nonpositive curvature: run to the trust-region boundary.
        p = toBoundary(p, dvec, Delta);
        info.negCurv = true;  info.boundary = true;  info.iter = k;
        info.predRed = predRed(H, g, p);
        return;
    end

    alpha = rr / dHd;
    pNext = p + alpha * dvec;

    if norm(pNext) >= Delta
        p = toBoundary(p, dvec, Delta);
        info.boundary = true;  info.iter = k;
        info.predRed = predRed(H, g, p);
        return;
    end

    p = pNext;
    r = r + alpha * Hd;
    rrNew = r.' * r;
    if sqrt(rrNew) <= tol
        info.iter = k;
        info.predRed = predRed(H, g, p);
        return;
    end
    beta = rrNew / rr;
    dvec = -r + beta * dvec;
    rr = rrNew;
end

info.iter = maxIter;
info.predRed = predRed(H, g, p);
end

function p = toBoundary(p, dvec, Delta)
%TOBOUNDARY  Extend a CG iterate to the trust-region boundary.
%   p = toBoundary(p, dvec, Delta) returns p + tau*dvec where tau >= 0 is the
%   largest step with ||p + tau*dvec|| = Delta (the positive root of the
%   boundary quadratic).
%
%   Inputs:
%     p     - n-by-1 current iterate strictly inside the trust region.
%     dvec  - n-by-1 search direction along which to reach the boundary.
%     Delta - scalar trust-region radius.
%
%   Outputs:
%     p - n-by-1 iterate lying on the trust-region boundary.
% Largest tau >= 0 with ||p + tau*d|| = Delta (positive root of the quadratic).
a = dvec.' * dvec;
b = 2 * (p.' * dvec);
c = (p.' * p) - Delta^2;
tau = (-b + sqrt(max(b^2 - 4*a*c, 0))) / (2*a);
p = p + tau * dvec;
end

function pr = predRed(H, g, p)
%PREDRED  Predicted reduction of the quadratic model at step p.
%   pr = predRed(H, g, p) returns -m(p) = -(g'*p + 0.5*p'*H*p), the model
%   decrease achieved by the step p (>= 0 for a descent step).
%
%   Inputs:
%     H - n-by-n Hessian model (dense matrix or hessianVecProduct operator).
%     g - n-by-1 gradient of the model at p = 0.
%     p - n-by-1 step at which to evaluate the predicted reduction.
%
%   Outputs:
%     pr - scalar predicted reduction -m(p).
import adamnlopt.*
pr = -(g.' * p + 0.5 * (p.' * hessianVecProduct(H, p)));
end
