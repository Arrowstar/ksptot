function [d, info] = linalg_solveKKTdirect(A, rhs)
%LINALG_SOLVEKKTDIRECT Direct LDL' solve of the symmetric KKT system A*d = rhs.
%   [d, info] = adamnlopt.linalg_solveKKTdirect(A, rhs) returns the step d and
%   an info struct with the matrix inertia (n+, n-, n0) and a rank-warning flag.
%   Inertia is reported so the caller (inertiaCorrection) can regularize.
%
%   Inputs:
%     A   - N-by-N symmetric (typically sparse) KKT matrix to factorize.
%     rhs - N-by-1 right-hand side of the KKT system.
%
%   Outputs:
%     d    - N-by-1 solution (step) of A*d = rhs. When A is rank deficient,
%            a minimum-norm least-squares step is returned instead.
%     info - struct describing the factorization:
%              .inertia        - [n+, n-, n0] counts of positive, negative and
%                                zero eigenvalues of the block-diagonal D.
%              .minAbsPivot    - smallest absolute eigenvalue of D.
%              .maxAbsPivot    - largest absolute eigenvalue of D.
%              .medAbsPivot    - median absolute eigenvalue of D.
%              .pivotSpread    - maxAbsPivot/minAbsPivot, a lower bound on
%                                cond(D) and the continuous quantity the
%                                suppressed RCOND warning below proxies for.
%              .nearlySingular - logical; true when the pivot spread exceeds
%                                1/eps, i.e. the factorization is as
%                                ill-conditioned as MATLAB's advisory warning
%                                would report were it not silenced.
%              .rankDeficient  - logical; true when n0 > 0.
%              .solved         - logical; true for a full LDL' solve, false when
%                                the least-squares fallback was used.
%
%   PIVOTSPREAD and NEARLYSINGULAR exist because the RCOND/singular-matrix
%   warnings are deliberately silenced below (see the comment there) and were
%   therefore the only record that a factorization had gone bad -- a record
%   nothing could read. A ratio is strictly more informative than the boolean
%   warning was: it shows the approach to singularity, not just the arrival.
%
%   See also KKT_INERTIACORRECTION, LINALG_SOLVEKKTKRYLOV, KKT_ASSEMBLE.

[L, D, p] = ldl(A, 'vector');

% Inertia from the block-diagonal D (1x1 and 2x2 blocks).
[npos, nneg, nzero, minAbsPivot, maxAbsPivot, medAbsPivot] = blockInertia(D);
info.inertia = [npos, nneg, nzero];
info.minAbsPivot = minAbsPivot;
info.maxAbsPivot = maxAbsPivot;
info.medAbsPivot = medAbsPivot;
info.rankDeficient = (nzero > 0);
% Continuous surrogates for the suppressed near-singularity warning. Guard the
% divide so a genuinely zero pivot reports Inf rather than NaN -- Inf is the
% honest answer and stays comparable, NaN would silently drop out of every
% subsequent max/mean over the trace.
if minAbsPivot > 0
    info.pivotSpread = maxAbsPivot / minAbsPivot;
else
    info.pivotSpread = inf;
end
info.nearlySingular = info.pivotSpread > 1 / eps;

d = zeros(size(rhs));
info.factors = [];
info.resRel  = NaN;
if info.rankDeficient
    % Signal caller to regularize; return a minimum-norm least-squares step
    % in the meantime (lsqminnorm avoids the singular-matrix warning).
    d(p) = lsqminnorm(A(p,p), rhs(p));
    info.solved = false;
    return;
end

% Solve L*D*L' * d(p) = rhs(p) entirely in permuted space; scattering the
% intermediates by p mid-solve would mis-order the triangular substitutions.
% A near-singular (but inertia-consistent) D at a degenerate iterate triggers
% only an advisory RCOND warning here; inertia is already reported for the
% caller's regularization decision, and the merit line search vets the step,
% so silence the cosmetic warnings locally. Degeneracy detection and
% stabilized recovery live in the +adamnlopt degeneracy_* modules.
ws1 = warning('off', 'MATLAB:nearlySingularMatrix');
ws2 = warning('off', 'MATLAB:singularMatrix');
ws3 = warning('off', 'MATLAB:illConditionedMatrix');
cleanup = onCleanup(@() warning([ws1, ws2, ws3]));
yv = L \ rhs(p);
zv = D \ yv;
wv = L.' \ zv;
d(p) = wv;
% Relative residual, as a diagnostic.  Iterative refinement was evaluated here
% (review D16) and rejected by measurement: on dense and on sparse
% (MA57, threshold-pivoted) KKT systems with pivot spreads to 1e12 the LDL'
% solve is already backward stable (backward error 1e-17..1e-18), and two
% refinement steps changed neither the residual nor the forward error.  The
% 1e-5 relative residuals seen on such systems are rounding in forming A*d.
info.resRel = norm(rhs - A * d, inf) / max(1, norm(rhs, inf));
% Keep the factorization so a caller can re-solve with a new right-hand side
% (second-order correction) without re-factoring (A9): linalg_resolveKKT.
info.factors = struct('L', L, 'D', D, 'p', p);
% A non-finite step is not a solution, whatever the inertia says (D30).
info.solved = all(isfinite(d));
end

function [npos, nneg, nzero, minAbsPivot, maxAbsPivot, medAbsPivot] = blockInertia(D)
%BLOCKINERTIA  Inertia of a block-diagonal LDL' factor D.
%   [npos, nneg, nzero, minAbsPivot, maxAbsPivot] = blockInertia(D) walks the
%   1x1 and 2x2 diagonal blocks of D, taking each 2x2 block's eigenvalues, and
%   counts the eigenvalues that are positive, negative and (numerically) zero
%   against a tolerance RELATIVE to the largest pivot, 10*eps*maxAbsPivot, so
%   the reported inertia is invariant to a rescaling of the KKT system.
%
%   Inputs:
%     D - block-diagonal factor from ldl, with 1x1 and 2x2 diagonal blocks.
%
%   Outputs:
%     npos        - number of eigenvalues greater than tol.
%     nneg        - number of eigenvalues less than -tol.
%     nzero       - number of eigenvalues with magnitude <= tol.
%     minAbsPivot - smallest absolute eigenvalue over all blocks.
%     maxAbsPivot - largest absolute eigenvalue over all blocks (pivot scale,
%                   used by callers to form a RELATIVE near-singularity test).
n = size(D, 1);
ev = zeros(n, 1);
k = 0;
i = 1;
while i <= n
    if i < n && D(i+1, i) ~= 0
        % 2x2 block: use eigenvalues.
        blk = full(D(i:i+1, i:i+1));
        e = eig(blk);
        ev(k+1:k+2) = e;
        k = k + 2;  i = i + 2;
    else
        k = k + 1;  ev(k) = D(i, i);
        i = i + 1;
    end
end
ev = ev(1:k);
absEv = abs(ev);
maxAbsPivot = max(absEv);
% RELATIVE zero-pivot tolerance.  The inertia computed here IS the descent
% certificate -- kkt_inertiaCorrection grows delta/gamma until it reads
% (n, mE, 0) -- so a fixed 1e-14 made that certificate depend on the units the
% problem is posed in.  Scale the KKT system down by 1e-8 and every pivot falls
% under the threshold: nzero = N, rankDeficient on every iteration, every step
% from the lsqminnorm fallback, and the correction loop unable to certify
% anything no matter how far it grows the regularization.  Scale it up and the
% opposite: a genuinely singular direction reads as a healthy pivot and is
% never regularized at all.  maxAbsPivot was already computed and already
% documented below as the scale "used by callers to form a RELATIVE
% near-singularity test" -- the test inside this very function was the one that
% did not use it.
%
% 10*eps*max rather than k*eps*max (D16).  k*eps*sigma_max is the SVD RANK
% tolerance; the question here is whether the factorization is usable, and on
% an anisotropic N = 600 KKT system (primal pivots ~1e9) the k-scaled version
% counted a healthy 1e-4 constraint pivot as zero, sending the solve to a dense
% lsqminnorm and growing both regularizations on a step that was fine.
tol = 10 * eps * maxAbsPivot;
npos  = sum(ev >  tol);
nneg  = sum(ev < -tol);
nzero = sum(absEv <= tol);
minAbsPivot = min(absEv);
medAbsPivot = median(absEv);
end
