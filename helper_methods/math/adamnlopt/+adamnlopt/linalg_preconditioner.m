function applyP = linalg_preconditioner(op, opts)
%LINALG_PRECONDITIONER SPD preconditioner for the Krylov KKT solve.
%   applyP = adamnlopt.linalg_preconditioner(op, opts) returns a function
%   handle applyP(r) approximating K\r. For MINRES the preconditioner must be
%   symmetric positive definite, so the Jacobi preconditioner uses the absolute
%   value of the operator diagonal (the (2,2) block of an indefinite KKT matrix
%   is negative). Falls back to the identity when the diagonal is unavailable
%   (matrix-free H) or a non-Jacobi mode is requested.
%
%   Inputs:
%     op   - kkt_KKTOperator; op.precondDiag supplies the positive Jacobi
%            diagonal (primal pivots plus a Schur-complement estimate for the
%            dual block), falling back to abs(op.diag) for a hand-built
%            operator struct. Both empty when no cheap diagonal exists (e.g. a
%            matrix-free Hessian).
%     opts - (optional) options struct; field .precondition selects the mode
%            ('jacobi' default, or 'none' for the identity).
%
%   Outputs:
%     applyP - function handle applyP(r) approximating K\r. Jacobi mode scales
%              by the reciprocal diagonal, with pivots floored RELATIVE to the
%              largest one; otherwise the identity @(r) r.
%
%   See also LINALG_SOLVEKKTKRYLOV, KKT_KKTOPERATOR.

if nargin < 2 || isempty(opts) || ~isfield(opts, 'precondition')
    mode = 'jacobi';
else
    mode = opts.precondition;
end

if strcmpi(mode, 'none')
    applyP = @(r) r;
    return;
end

% Prefer the operator's purpose-built positive diagonal.  abs(diag(K)) is NOT a
% usable Jacobi diagonal for a saddle-point system: the (2,2) block is
% -gamma*I, gamma is 0 whenever the inertia correction did not fire, and the
% old absolute guard below then turned every zero dual pivot into 1e-12 and
% divided by it -- amplifying the dual residual by 1e12 and making MINRES
% converge on the wrong thing.  op.precondDiag carries a Schur-complement
% estimate for that block instead.  The abs(op.diag) path is kept only for
% callers that build a bare operator struct by hand.
if isfield(op, 'precondDiag') && ~isempty(op.precondDiag)
    d = op.precondDiag;
elseif isempty(op.diag)
    applyP = @(r) r;
    return;
else
    d = abs(op.diag);
end

% Relative, not absolute: a legitimately well-scaled problem in small units can
% have every diagonal entry below 1e-12, and clamping those to 1e-12 flattened
% the preconditioner to a constant.  Anything more than 12 orders below the
% largest pivot carries no usable information, so pin it at that floor.
dRef = max(d(isfinite(d)));
if isempty(dRef) || ~(dRef > 0), dRef = 1; end
d(~isfinite(d) | d < dRef * 1e-12) = dRef * 1e-12;
applyP = @(r) r ./ d;
end
