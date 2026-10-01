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
%       .diag      diagonal of K, or [] when H is an operator whose diagonal is
%                  unavailable (a dense-matrix H and a BFGSHessian both supply
%                  one; an LBFGSHessian does not)
%       .precondDiag  strictly positive Jacobi preconditioner diagonal: the
%                  primal block clamped relative to its own scale, and a
%                  SCHUR-COMPLEMENT estimate for the dual block, which is what
%                  abs(diag(K)) cannot give because the (2,2) block is -gamma*I
%                  and gamma is 0 unless the inertia correction fired
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
%          size), mE (dual block size), diag ((n+mE)-by-1 diagonal of K when H
%          is numeric or a model that can supply diag(H), or [] when no cheap
%          diagonal exists), and precondDiag (the strictly positive Jacobi
%          preconditioner diagonal described above, [] in the same case).
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
    op.diag = [];          % no cheap diagonal
    op.precondDiag = [];
else
    dP = dH(:) + delta;
    op.diag = [dP; -gamma * ones(mE, 1)];

    % Separate POSITIVE diagonal for the Jacobi preconditioner.  abs(op.diag) is
    % not usable as one: the (2,2) block is -gamma*I and gamma is ZERO on every
    % iteration the inertia correction does not fire (its default reg is
    % delta = gamma = 0), so the whole dual block of the preconditioner diagonal
    % is exactly 0.  The preconditioner's small-pivot guard then replaced each
    % one with 1e-12 and divided by it, multiplying every dual residual
    % component by 1e12 -- MINRES minimizes the PRECONDITIONED residual, so it
    % spends its whole iteration budget on the dual block and returns a step
    % whose primal part is essentially unconverged, on the large problems that
    % are exactly the ones routed to the Krylov path.
    %
    % The right scalar for a dual row is its Schur-complement diagonal,
    %   (JE * (H+delta*I)^-1 * JE')_ii + gamma  ~  sum_j JE(i,j)^2 / dP(j) + gamma,
    % which is the magnitude the dual block of K actually acts at.  It costs one
    % elementwise square and a row sum.
    dRef = max(abs(dP));
    if ~(dRef > 0) || ~isfinite(dRef), dRef = 1; end
    dPp = abs(dP);
    dPp(~isfinite(dPp) | dPp < dRef * 1e-12) = dRef * 1e-12;
    if mE > 0
        dS = full(sum((JE .^ 2) ./ dPp.', 2)) + gamma;
        sRef = max(dS);
        if ~(sRef > 0) || ~isfinite(sRef), sRef = dRef; end
        dS(~isfinite(dS) | dS <= 0) = sRef;
    else
        dS = zeros(0, 1);
    end
    op.precondDiag = [dPp; dS];
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
