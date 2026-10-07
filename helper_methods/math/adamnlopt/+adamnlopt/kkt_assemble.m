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
%             (primal) and gamma (dual); each defaults to zero when the struct
%             is empty, omitted, or does not carry that particular field.
%
%   Outputs:
%     K   - (n+mE)-by-(n+mE) symmetric saddle-point KKT matrix.
%     rhs - (n+mE)-by-1 right-hand side -[rStat; rFeasE].
%     idx - struct with index ranges idx.x (1:n) and idx.lamE (n+(1:mE)) for
%           unpacking the solution vector.
%
%   See also KKT_RESIDUAL, KKT_KKTOPERATOR, KKT_INERTIACORRECTION.

if nargin < 3
    reg = [];
end
delta = regTerm(reg, 'delta');
gamma = regTerm(reg, 'gamma');

H  = state.H;
JE = state.JE;
n  = numel(state.x);
mE = numel(state.lamE);

% Regularize the diagonal IN PLACE.  `H + delta*eye(n)` materializes a dense
% n-by-n identity and, added to a sparse H, hands back a DENSE K -- destroying
% the one property the LDL' factorization downstream depends on, and doing it
% up to 40 times per iteration because kkt_inertiaCorrection re-assembles on
% every correction try.  It happened even at delta = 0, where the whole term is
% a no-op.  solve.m:1154 already takes exactly this care building W; the care
% was thrown away one call later.
if issparse(H)
    if delta ~= 0
        H = H + delta * speye(n);
    end
else
    H(1:n+1:end) = H(1:n+1:end) + delta;
end

% Same reasoning for the dual block: keep it sparse whenever either block it
% joins is sparse, so a zero gamma costs O(mE) rather than an mE-by-mE dense
% allocation per assembly.
% A dense H with a sparse JE used to concatenate into a SPARSE K with a dense
% (1,1) block (D16): ldl then runs MA57 on an essentially dense pattern, slower
% than LAPACK and with threshold pivoting that can report a different inertia
% for the same matrix.  The BFGS/L-BFGS models always return a dense H, so make
% the whole system dense in that case.
if ~issparse(H) && issparse(JE)
    JE = full(JE);
end
if issparse(H) || issparse(JE)
    G = -gamma * speye(mE);
else
    G = -gamma * eye(mE);
end

K = [ H,   JE.'; ...
      JE,  G ];

rhs = -[ res.rStat; res.rFeasE ];

idx.x    = 1:n;
idx.lamE = n + (1:mE);
end

function v = regTerm(reg, name)
%REGTERM  One regularization term from REG, or 0 when it is not supplied.
%   The defaults used to be applied only when REG was entirely empty or
%   omitted, so a partially populated struct -- delta set, gamma not -- errored
%   on the missing field instead of taking the documented default of zero.
if isstruct(reg) && isfield(reg, name) && ~isempty(reg.(name))
    v = reg.(name);
else
    v = 0;
end
end
