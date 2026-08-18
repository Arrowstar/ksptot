function op = kkt_KKTOperator(state, reg)
%KKT_KKTOPERATOR  Matrix-free symmetric KKT operator.
%   op = adamnlopt.kkt_KKTOperator(state, reg) returns a struct describing the
%   saddle-point operator
%
%       K = [ H + delta*I     JE' ]
%           [ JE          -gamma*I ]
%
%   without forming K. op.apply(v) computes K*v for v = [vx; vy] (length n+mE).
%   H may be a dense matrix or any adamnlopt.hessianVecProduct-compatible
%   operator, so the same code drives large matrix-free problems. Fields:
%       .apply(v)  symmetric mat-vec product K*v
%       .n, .mE    primal / dual block sizes
%       .diag      diagonal of K (for Jacobi preconditioning), or [] when H is
%                  an operator whose diagonal is unavailable (a dense-matrix H
%                  and a BFGSHessian both supply one; an LBFGSHessian does not)
%   This mirrors kkt_assemble exactly (same H, JE, delta, gamma), so the direct
%   and Krylov paths solve the identical regularized system.
%
%   Inputs:
%     state - iterate struct. Fields used: H (n-by-n Hessian matrix or a
%             hessianVecProduct-compatible operator), JE (mE-by-n equality
%             Jacobian), x (n-by-1 primal point, for sizing n), lamE (mE-by-1
%             equality multipliers, for sizing mE).
%     reg   - (optional) regularization struct with scalar fields delta
%             (primal) and gamma (dual); defaults to zeros when empty/omitted.
%
%   Outputs:
%     op - struct with fields apply (function handle v -> K*v), n (primal block
%          size), mE (dual block size), and diag ((n+mE)-by-1 diagonal of K
%          when H is numeric or a model that can supply diag(H), or [] when no
%          cheap diagonal exists).
%
%   See also KKT_ASSEMBLE, HESSIANVECPRODUCT, KKT_INERTIACORRECTION.

import adamnlopt.*

if nargin < 2 || isempty(reg)
    reg = struct('delta', 0, 'gamma', 0);
end

H  = state.H;
JE = state.JE;
n  = numel(state.x);
mE = numel(state.lamE);
delta = reg.delta;
gamma = reg.gamma;

op = struct();
op.n = n;
op.mE = mE;
op.apply = @applyK;

% Jacobi diagonal, when one is cheaply available.  A dense Hessian model
% (BFGSHessian) stores B explicitly and can supply it; a limited-memory model
% cannot, and returns [] so the preconditioner falls back to the identity.
if isnumeric(H) && ~isempty(H)
    dH = full(diag(H));
elseif isa(H, 'adamnlopt.HessianModel')
    dH = H.diagonal();
else
    dH = [];
end
if isempty(dH)
    op.diag = [];   % no cheap diagonal
else
    op.diag = [dH(:) + delta; -gamma * ones(mE, 1)];
end

    function w = applyK(v)
    %APPLYK  Symmetric KKT mat-vec product K*v.
    %   w = applyK(v) computes K*v for the operator captured from the enclosing
    %   function, splitting v into its primal block vx and dual block vy and
    %   applying H (via hessianVecProduct), delta, JE, and gamma. The dual block
    %   is empty when there are no equality constraints (mE == 0).
    %
    %   Inputs:
    %     v - (n+mE)-by-1 vector [vx; vy] to multiply by K.
    %
    %   Outputs:
    %     w - (n+mE)-by-1 product K*v.
        vx = v(1:n);
        vy = v(n + (1:mE));
        wx = hessianVecProduct(H, vx) + delta * vx;
        if mE > 0
            wx = wx + JE.' * vy;
            wy = JE * vx - gamma * vy;
        else
            wy = zeros(0, 1);
        end
        w = [wx; wy];
    end
end
