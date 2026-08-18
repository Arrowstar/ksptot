function u = step_tangentialStep(H, g, JE, v, Delta)
%STEP_TANGENTIALSTEP  Byrd-Omojokun tangential (optimality) step.
%   u = adamnlopt.step_tangentialStep(H, g, JE, v, Delta) reduces the
%   quadratic model of the objective within the null space of the constraint
%   Jacobian, on top of the normal step v:
%       min_u  (g + H*v)'*u + 0.5*u'*H*u   s.t.  JE*u = 0,  ||v + u|| <= Delta.
%   The null-space constraint is enforced with an orthonormal basis Z of
%   null(JE); the reduced problem min_w gRed'*w + 0.5*w'*(Z'HZ)*w over
%   ||w|| <= sqrt(Delta^2 - ||v||^2) is solved by the Steihaug-CG routine
%   (step_trustRegionSubproblem). Because v is orthogonal to null(JE),
%   ||v + u||^2 = ||v||^2 + ||u||^2, so the reduced radius is exact. H may be a
%   dense matrix or any adamnlopt.hessianVecProduct-compatible operator.
%
%   Inputs:
%     H     - n-by-n Hessian model of the objective (dense symmetric matrix or
%             an adamnlopt.hessianVecProduct-compatible operator).
%     g     - n-by-1 gradient of the objective at the current point.
%     JE    - mE-by-n Jacobian of the equality constraints. Pass empty for an
%             unconstrained null space (Z = I).
%     v     - n-by-1 normal step (from step_normalStep), orthogonal to null(JE).
%     Delta - scalar total trust-region radius bounding ||v + u||.
%
%   Outputs:
%     u - n-by-1 tangential step lying in null(JE) with ||v + u|| <= Delta.
%
%   See also STEP_NORMALSTEP, STEP_TRUSTREGIONSUBPROBLEM, HESSIANVECPRODUCT.

import adamnlopt.*

n = size(H, 1);
if isempty(JE)
    Z = eye(n);
else
    Z = null(JE);               % orthonormal basis of null(JE)
end

if isempty(Z)
    u = zeros(n, 1);  return;   % constraints pin every direction
end

DeltaT = sqrt(max(Delta^2 - (v.' * v), 0));
if DeltaT <= 0
    u = zeros(n, 1);  return;
end

gRed = Z.' * (g + hessianVecProduct(H, v));
Hred = Z.' * (H * Z);
Hred = (Hred + Hred.') / 2;

w = step_trustRegionSubproblem(Hred, gRed, DeltaT);
u = Z * w;
end
