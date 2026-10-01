function u = step_tangentialStep(H, g, JE, v, Delta)
%STEP_TANGENTIALSTEP  Byrd-Omojokun tangential (optimality) step.
%   u = adamnlopt.step_tangentialStep(H, g, JE, v, Delta) reduces the
%   quadratic model of the objective within the null space of the constraint
%   Jacobian, on top of the normal step v:
%       min_u  (g + H*v)'*u + 0.5*u'*H*u   s.t.  JE*u = 0,  ||v + u|| <= Delta.
%   The null-space constraint is enforced with an orthonormal basis Z of
%   null(JE) (from a rank-revealing QR of JE'); the reduced problem
%   min_w gRed'*w + 0.5*w'*(Z'HZ)*w over ||w|| <= sqrt(Delta^2 - ||v||^2) is
%   solved by the Steihaug-CG routine (step_trustRegionSubproblem). Because v
%   is orthogonal to null(JE), ||v + u||^2 = ||v||^2 + ||u||^2, so the reduced
%   radius is exact. H may be a dense matrix or any
%   adamnlopt.hessianVecProduct-compatible operator; the operator case forms
%   Z'HZ one basis vector at a time rather than requiring the product H*Z.
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

n = numel(g);
Z = nullBasis(JE, n);

if isempty(Z)
    u = zeros(n, 1);  return;   % constraints pin every direction
end

DeltaT = sqrt(max(Delta^2 - (v.' * v), 0));
if DeltaT <= 0
    u = zeros(n, 1);  return;
end

gRed = Z.' * (g + hessianVecProduct(H, v));
% Reduced Hessian Z'*H*Z.  H*Z is only defined when H is a matrix; the
% docstring promises operator support, so route the operator case through
% hessianVecProduct one basis vector at a time (the only thing an operator
% exposes).  Dense H keeps the single matrix product -- one BLAS call beats
% size(Z,2) separate ones.
if isnumeric(H)
    HZ = H * Z;
else
    HZ = zeros(n, size(Z, 2));
    for k = 1:size(Z, 2)
        HZ(:, k) = hessianVecProduct(H, Z(:, k));
    end
end
Hred = Z.' * HZ;
Hred = (Hred + Hred.') / 2;

w = step_trustRegionSubproblem(Hred, gRed, DeltaT);
u = Z * w;
end

% ------------------------------------------------------------------------
function Z = nullBasis(A, n)
%NULLBASIS  Orthonormal basis of null(A), from a column-pivoted QR of A'.
%   Equivalent to null(A) but built from a rank-revealing QR instead of a full
%   SVD: same orthonormality and same relative rank tolerance, roughly a third
%   of the flops, and it exploits any structure in A'. The trailing columns of
%   Q from qr(A') span the orthogonal complement of range(A') = null(A).
%
%   Inputs:
%     A - m-by-n matrix (empty for an unconstrained null space).
%     n - column count of A, supplied so the empty case still sizes correctly.
%
%   Outputs:
%     Z - n-by-(n-rank(A)) orthonormal basis of null(A); n-by-n identity when A
%         is empty, and n-by-0 when A has full column rank.
if isempty(A)
    Z = eye(n);  return;
end
[Q, R, ~] = qr(full(A).', 'vector');   % A' is n-by-m; pivoted so |diag(R)| decays
% Pull the diagonal from the leading square block.  diag(R) alone is wrong for
% a single-constraint problem: R is then n-by-1, and diag() of a VECTOR builds
% a matrix instead of extracting a diagonal, so the rank count came back as a
% row vector and the basis slice errored.
p  = min(size(R));
dR = abs(diag(R(1:p, 1:p)));
if isempty(dR) || dR(1) == 0
    r = 0;
else
    % Same relative tolerance null() applies to the singular values.
    r = sum(dR > max(size(A)) * eps * dR(1));
end
Z = Q(:, r+1:n);
end
