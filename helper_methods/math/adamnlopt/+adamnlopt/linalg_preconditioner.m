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
%     op   - kkt_KKTOperator; op.diag supplies the KKT matrix diagonal (empty
%            when unavailable, e.g. a matrix-free Hessian).
%     opts - (optional) options struct; field .precondition selects the mode
%            ('jacobi' default, or 'none' for the identity).
%
%   Outputs:
%     applyP - function handle applyP(r) approximating K\r. Jacobi mode scales
%              by the reciprocal absolute diagonal (guarded against tiny pivots);
%              otherwise the identity @(r) r.
%
%   See also LINALG_SOLVEKKTKRYLOV, KKT_KKTOPERATOR.

if nargin < 2 || isempty(opts) || ~isfield(opts, 'precondition')
    mode = 'jacobi';
else
    mode = opts.precondition;
end

if strcmpi(mode, 'none') || isempty(op.diag)
    applyP = @(r) r;
    return;
end

d = abs(op.diag);
d(d < 1e-12) = 1e-12;      % guard tiny/zero pivots
applyP = @(r) r ./ d;
end
