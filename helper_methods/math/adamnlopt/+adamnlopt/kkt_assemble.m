function [K, rhs, idx] = kkt_assemble(state, res, reg)
%KKT_ASSEMBLE  Assemble the (regularized) Newton-KKT system.
%   [K, rhs, idx] = adamnlopt.kkt_assemble(state, res, reg) builds the
%   symmetric saddle-point system for the primal step dx and equality-
%   multiplier step dlamE:
%
%       [ H + delta*I     JE' ] [dx    ]   [ -rStat  ]
%       [ JE          -gamma*I ] [dlamE ] = [ -rFeasE ]
%
%   REG is a struct with fields delta (primal) and gamma (dual) regularization
%   (default 0). IDX returns index ranges so callers can unpack the solution.
%   This equality-core assembly is extended with slack/bound blocks in the
%   interior-point stage.
%
%   Inputs:
%     state - iterate struct. Fields used: H (n-by-n Lagrangian Hessian or
%             approximation), JE (mE-by-n equality Jacobian), x (n-by-1 primal
%             point, for sizing n), lamE (mE-by-1 equality multipliers, for
%             sizing mE).
%     res   - residual struct from kkt_residual; fields rStat (n-by-1) and
%             rFeasE (mE-by-1) form the right-hand side.
%     reg   - (optional) regularization struct with scalar fields delta
%             (primal) and gamma (dual); defaults to zeros when empty/omitted.
%
%   Outputs:
%     K   - (n+mE)-by-(n+mE) symmetric saddle-point KKT matrix.
%     rhs - (n+mE)-by-1 right-hand side -[rStat; rFeasE].
%     idx - struct with index ranges idx.x (1:n) and idx.lamE (n+(1:mE)) for
%           unpacking the solution vector.
%
%   See also KKT_RESIDUAL, KKT_KKTOPERATOR, KKT_INERTIACORRECTION.

if nargin < 3 || isempty(reg)
    reg = struct('delta', 0, 'gamma', 0);
end

H  = state.H;
JE = state.JE;
n  = numel(state.x);
mE = numel(state.lamE);

H = H + reg.delta * eye(n);

K = [ H,        JE.'; ...
      JE,      -reg.gamma * eye(mE) ];

rhs = -[ res.rStat; res.rFeasE ];

idx.x    = 1:n;
idx.lamE = n + (1:mE);
end
