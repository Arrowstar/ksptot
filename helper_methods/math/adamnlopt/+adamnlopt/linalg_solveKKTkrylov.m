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
    % min(nAll, 10*nAll) is just nAll for nAll >= 0, so the intended 10x
    % headroom was a no-op and MINRES was capped at max(20, n+mE) iterations.
    % The Krylov path exists for problems too large to factor, where an
    % indefinite saddle-point system in finite precision routinely needs more
    % than n+mE iterations -- it loses orthogonality and has to rebuild it --
    % so the cap was silently returning unconverged steps.  Give the headroom
    % the expression was written to give, bounded so a huge problem cannot turn
    % one linear solve into an unbounded one.
    maxit = max(20, min(10 * nAll, nAll + 1000));
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

% MATLAB's gmres/minres test convergence on the PRECONDITIONED residual but
% report the TRUE relative residual in relres, so flag == 0 does not actually
% mean the returned step solves K*d = rhs to tol.  On HS71 with
% krylovMethod = 'gmres', gmres returned flag 0 (converged) at true relres
% 1.66, 3.57 and, on one iteration, 2.1e+07 -- a "solution" orders of magnitude
% worse than d = 0 -- and the caller, which only inspects flag, fed it straight
% into the line search.  The result was a solve that ran 300 iterations and
% stalled at f = 17.130 against the true 17.0140175.  Believe the number, not
% the flag.  The 10x band absorbs the genuine preconditioned-versus-true norm
% mismatch, which is a small constant factor, without absorbing a failure; the
% floor keeps a numerically exact solve from being rejected when tol is tiny.
if flag == 0 && relres > max(10 * tol, 1e-8)
    flag = 4;   % distinct from MATLAB's 1..3 -- "reported converged, did not"
end

info = struct('iters', iters, 'relres', relres, 'flag', flag, 'method', method);
end
