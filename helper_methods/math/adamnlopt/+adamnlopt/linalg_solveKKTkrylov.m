function [d, info] = linalg_solveKKTkrylov(op, rhs, tol, applyP, opts)
%LINALG_SOLVEKKTKRYLOV Iterative (matrix-free) solve of the KKT system K*d=rhs.
%   [d, info] = adamnlopt.linalg_solveKKTkrylov(op, rhs, tol, applyP, opts)
%   solves the symmetric indefinite KKT system to relative residual tol using
%   MINRES (default) or GMRES, with the SPD preconditioner applyP. OP is a
%   kkt_KKTOperator; only mat-vecs op.apply are used, so K is never formed.
%   INFO reports .iters, .relres, .flag (0 = converged), and .method.
%
%   MINRES is the natural choice for a symmetric indefinite system; GMRES is
%   offered as a fallback for cases where a non-symmetric preconditioner is
%   introduced later.
%
%   Inputs:
%     op     - kkt_KKTOperator exposing op.apply(v) for the matrix-vector
%              product K*v; the KKT matrix K is never assembled.
%     rhs    - N-by-1 right-hand side of the KKT system.
%     tol    - (optional) relative residual tolerance; defaults to 1e-8.
%     applyP - (optional) SPD preconditioner handle applyP(r) ~ K\r; defaults to
%              the identity @(r) r.
%     opts   - (optional) options struct; fields .krylovMethod ('minres' or
%              'gmres') and .krylovMaxIter override the defaults.
%
%   Outputs:
%     d    - N-by-1 computed step.
%     info - struct with .iters, .relres, .flag (0 = converged), and .method.
%
%   See also LINALG_PRECONDITIONER, LINALG_SOLVEKKTDIRECT, KKT_KKTOPERATOR.

if nargin < 3 || isempty(tol),    tol = 1e-8;            end
if nargin < 4 || isempty(applyP), applyP = @(r) r;       end
if nargin < 5 || isempty(opts),   opts = struct();       end

method = 'minres';
if isfield(opts, 'krylovMethod') && ~isempty(opts.krylovMethod)
    method = lower(opts.krylovMethod);
end

nAll = numel(rhs);
if isfield(opts, 'krylovMaxIter') && ~isempty(opts.krylovMaxIter)
    maxit = opts.krylovMaxIter;
else
    maxit = max(20, min(nAll, 10 * nAll));
end

afun = @(v) op.apply(v);
% MINRES/GMRES call the preconditioner as M\r; wrap the handle so they can pass
% it as a function.
mfun = @(r) applyP(r);

ws = warning('off', 'MATLAB:minres:tooSmallTolerance');
cleanup = onCleanup(@() warning(ws));

switch method
    case 'gmres'
        restart = min(nAll, 50);
        outer = min(nAll, max(1, ceil(maxit / restart)));
        [d, flag, relres, iterv] = gmres(afun, rhs, restart, tol, outer, mfun);
        iters = (iterv(1) - 1) * restart + iterv(2);
    otherwise   % minres
        [d, flag, relres, iters] = minres(afun, rhs, tol, maxit, mfun);
end

info = struct('iters', iters, 'relres', relres, 'flag', flag, 'method', method);
end
