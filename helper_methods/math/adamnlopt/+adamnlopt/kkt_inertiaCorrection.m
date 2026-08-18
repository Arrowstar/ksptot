function [d, idx, info, reg] = kkt_inertiaCorrection(state, res, n, mE, reg0, opts)
%KKT_INERTIACORRECTION  Solve the Newton-KKT system with inertia correction.
%   [d, idx, info, reg] = adamnlopt.kkt_inertiaCorrection(state, res, n, mE)
%   assembles and factorizes the saddle-point system, growing the primal
%   regularization delta (and, on a singular equality block, the dual
%   regularization gamma) until the KKT matrix has inertia (n, mE, 0):
%   n positive eigenvalues (primal), mE negative (dual), none zero. That
%   inertia certifies the step is a descent/minimization direction; a
%   nonconvex Lagrangian Hessian yields a negative reduced Hessian and the
%   wrong inertia even when the matrix is nonsingular, so delta is grown
%   geometrically from ~1e-8 (IPOPT-style).
%
%   REG0 (optional) warm-starts delta from a previous iteration so a problem
%   that needed regularization once does not restart the search from zero.
%   REG (returned) reports the delta/gamma that succeeded, ready to be fed
%   back in as REG0 next iteration.
%
%   The loop also regularizes when the LDL' factor's smallest-magnitude pivot
%   falls below a tolerance (near-singular Schur complement), because that can
%   produce correct inertia yet an enormous, divergent dual step. Iteration is
%   capped at 40 tries.
%
%   BEFORE that loop runs, a scale-aware dual pre-regularization (Fix A) sizes an
%   initial gamma in ONE shot from the conditioning of the reduced dual system
%   S = JE*W^{-1}*JE' (the Schur complement).  The range-space elimination that
%   condenses onto the equality multipliers squares JE's conditioning, so a
%   merely ill-conditioned JE yields a genuinely near-singular S and a divergent
%   dlamE even though the KKT pivots (dominated by the primal block) look
%   healthy.  The pivot-based test above cannot see that; the explicit
%   conditioning probe can.  gamma is set to sigma_max(S)/opts.dualCondMax so
%   cond(S+gamma*I) is bounded at dualCondMax, keeping the factorization honest
%   while perturbing the feasibility row only by a bounded O(gamma*dlamE).  The
%   probe is O(mE^2*n) and is skipped when mE exceeds opts.dualCondProbeMaxDim
%   (then only the pivot gate acts).  Companion magnitude bound: solve caps the
%   accepted multiplier increment (Fix B, opts.dualStepMax).
%
%   Inputs:
%     state - iterate struct passed through to kkt_assemble (fields H, JE, x,
%             lamE).
%     res   - residual struct from kkt_residual (fields rStat, rFeasE) forming
%             the right-hand side.
%     n     - number of primal variables (expected positive inertia count).
%     mE    - number of equality constraints (expected negative inertia count).
%     reg0  - (optional) warm-start regularization struct with scalar fields
%             delta and gamma; defaults to zeros when empty/omitted.
%     opts  - (optional) options struct; fields dualCondMax and
%             dualCondProbeMaxDim govern the scale-aware dual pre-regularization
%             (Fix A). Omitted/empty -> Fix A disabled (pivot gate only).
%
%   Outputs:
%     d    - (n+mE)-by-1 solution [dx; dlamE] of the regularized KKT system.
%     idx  - struct of index ranges (idx.x, idx.lamE) from kkt_assemble.
%     info - solver info struct from linalg_solveKKTdirect (fields include
%            solved, inertia, rankDeficient, minAbsPivot, pivotSpread),
%            augmented here with a record of the correction itself:
%              .tries          - number of regularize-and-refactorize retries.
%              .triesExhausted - logical; true when the 40-try cap was hit, in
%                                which case D is the step from a factorization
%                                that never reached the required inertia. This
%                                had NO signal of any kind before: an invalid
%                                step was returned indistinguishably from a
%                                valid one.
%              .gammaFixA      - the one-shot Fix A dual regularization, kept
%                                separate from the loop's escalated gamma so
%                                the two causes can be told apart.
%              .schur          - struct from the Fix A probe (see below).
%              .reg            - the accepted regularization (delta, gamma).
%     reg  - regularization struct (delta, gamma) that produced the accepted
%            factorization, suitable for reuse as REG0 next iteration.
%
%   See also KKT_ASSEMBLE, LINALG_SOLVEKKTDIRECT, KKT_RESIDUAL.

import adamnlopt.*

if nargin < 5 || isempty(reg0)
    reg = struct('delta', 0, 'gamma', 0);
else
    reg = reg0;
end
if nargin < 6
    opts = [];
end

% --- Fix A: scale-aware dual pre-regularization -------------------------------
% Seed gamma from the conditioning of the reduced dual (Schur) system
% S = JE*W^{-1}*JE' so that cond(S + gamma*I) <= dualCondMax.  This is a ONE-shot
% estimate before the inertia/pivot loop -- it targets the Schur near-singularity
% the pivot gate is blind to (K's pivots are dominated by the primal block, so a
% near-null S produces correct inertia and healthy-looking pivots yet a divergent
% dlamE).  Only the DUAL block is touched, so primal descent is unchanged.
[gammaScale, schurInfo] = dualRegFromSchur(state, mE, opts);
if gammaScale > reg.gamma
    reg.gamma = gammaScale;
end

[K, rhs, idx] = kkt_assemble(state, res, reg);
[d, info] = linalg_solveKKTdirect(K, rhs);

% Also regularize when the LDL' pivot is tiny: a near-singular Schur
% complement (JE * W^{-1} * JE^T ~ 0) keeps inertia correct but makes
% dlamE = S^{-1}*rpE enormous, causing dual divergence.
%
% The near-singularity test is RELATIVE to the factor's MEDIAN pivot, not an
% absolute constant and not the largest pivot.  An absolute pivotTol=1e-3
% mistook a merely small-magnitude constraint pivot (e.g. the stiff orbit's
% Schur pivots ride at ~1e-4 in scaled space) for near-singular, firing every
% iteration and -- since the feasibility row is JE*dx - gamma*dlamE = -cE --
% injecting dual regularization that corrupts JE*dx = -cE (observed feasRowRes
% stuck ~ 6.6e-3 instead of ~0).  Dividing by maxAbsPivot fails the mirror
% case: on a problem with anisotropic PRIMAL curvature (extended Rosenbrock,
% Hessian eigenvalues ~1e9) a perfectly healthy constraint pivot looks tiny
% next to the largest primal pivot, so min/max misfired 96% of the time.  The
% median pivot is a robust central scale -- invariant to overall magnitude and
% not dominated by a few large primal eigenvalues -- so minAbsPivot <
% pivotRelTol*medAbsPivot flags only a genuine pivot-spread singularity.
pivotRelTol = 1e-12;   % near-singular when min pivot is this far below the median
tries = 0;
while (~inertiaOK(info, n, mE) || pivotTooSmall(info, pivotRelTol)) && tries < 40
    if info.rankDeficient || (inertiaOK(info, n, mE) && pivotTooSmall(info, pivotRelTol))
        % Near-singular constraint block: grow dual regularization.
        if reg.gamma == 0
            reg.gamma = 1e-8;
        else
            reg.gamma = reg.gamma * 10;
        end
    end
    if ~inertiaOK(info, n, mE)
        % Wrong inertia: grow primal regularization.
        if reg.delta == 0
            reg.delta = 1e-8;
        else
            reg.delta = reg.delta * 10;
        end
    end
    [K, rhs, idx] = kkt_assemble(state, res, reg);
    [d, info] = linalg_solveKKTdirect(K, rhs);
    tries = tries + 1;
end

% Record what the correction did. Purely observational -- nothing below is read
% back by this function or by its callers to make a decision.
info.tries          = tries;
info.triesExhausted = tries >= 40 && ...
                      (~inertiaOK(info, n, mE) || pivotTooSmall(info, pivotRelTol));
info.gammaFixA      = gammaScale;
info.schur          = schurInfo;
info.reg            = reg;
end

function tooSmall = pivotTooSmall(info, pivotRelTol)
%PIVOTTOOSMALL  Relative near-singularity test on the LDL' pivots.
%   tooSmall = pivotTooSmall(info, pivotRelTol) returns true when the smallest
%   pivot magnitude is negligible RELATIVE to the MEDIAN pivot, i.e.
%   minAbsPivot < pivotRelTol*medAbsPivot -- a magnitude-invariant indicator of
%   a near-singular Schur complement.  The median (not the max) is the
%   denominator so a few large primal-Hessian eigenvalues do not make a healthy
%   constraint pivot look singular. Falls back to an absolute floor when
%   medAbsPivot is unavailable (older info structs) or non-finite.
if ~isfield(info, 'medAbsPivot') || ~isfinite(info.medAbsPivot) || info.medAbsPivot <= 0
    tooSmall = info.minAbsPivot < 1e-3;   % legacy absolute fallback
    return;
end
tooSmall = info.minAbsPivot < pivotRelTol * info.medAbsPivot;
end

function [gamma, sinfo] = dualRegFromSchur(state, mE, opts)
%DUALREGFROMSCHUR  Scale-aware dual regularization from the Schur complement.
%   [gamma, sinfo] = dualRegFromSchur(state, mE, opts) forms the reduced dual system
%   S = JE*W^{-1}*JE' (W = state.H, JE = state.JE) and returns the smallest
%   gamma such that cond(S + gamma*I) <= opts.dualCondMax, i.e.
%   gamma = max(0, sigma_max(S)/dualCondMax - sigma_min(S)).  Returns 0 (no dual
%   regularization) when Fix A is disabled or inapplicable:
%     - opts empty / dualCondMax not finite / dualCondMax <= 0  -> disabled,
%     - mE == 0 (no equality block) or mE > dualCondProbeMaxDim -> skipped
%       (the O(mE^2*n) probe is too costly; the pivot gate acts instead),
%     - S ill-formed / singular W / non-finite svd                -> skipped.
%   Only sigma_max and sigma_min of S are needed, but for the moderate mE this
%   solver targets a dense svd is simplest and robust; the cost guard bounds it.
%
%   SINFO reports what the probe saw: ran, sMax, sMin, cond (= sMax/sMin), gamma,
%   caught (the try/catch fired), and skipReason (0 ran | 1 disabled | 2 mE==0 |
%   3 over the dimension cap | 4 non-finite svd | 5 caught). sMax and sMin are
%   computed exactly here every iteration and were, until now, discarded -- so
%   the conditioning trajectory of the reduced dual system, which is precisely
%   what Fix A exists to bound, had never been observed on any problem.
gamma = 0;
sinfo = struct('ran', false, 'sMax', NaN, 'sMin', NaN, 'cond', NaN, ...
               'gamma', 0, 'caught', false, 'skipReason', 1);
if isempty(opts)
    return;
end
if mE == 0
    sinfo.skipReason = 2;
    return;
end
condMax   = getField(opts, 'dualCondMax', inf);
probeMax  = getField(opts, 'dualCondProbeMaxDim', 400);
if ~isfinite(condMax) || condMax <= 0
    sinfo.skipReason = 1;
    return;
end
if mE > probeMax
    sinfo.skipReason = 3;
    return;
end
% A rank-deficient or singular W (degenerate iterate) makes the W\JE' solve
% advisory-warn; the probe already degrades gracefully to gamma=0 via the catch,
% so silence the cosmetic RCOND/singular warnings locally (mirrors
% linalg_solveKKTdirect).  Restored on any exit by onCleanup.
ws1 = warning('off', 'MATLAB:nearlySingularMatrix');
ws2 = warning('off', 'MATLAB:singularMatrix');
ws3 = warning('off', 'MATLAB:illConditionedMatrix');
cleanup = onCleanup(@() warning([ws1, ws2, ws3]));
try
    W  = full(state.H);
    JE = full(state.JE);
    % S = JE * W^{-1} * JE'.  Solve W \ JE' rather than inverting W.
    WiJEt = W \ JE.';
    S = JE * WiJEt;
    S = (S + S.') / 2;                 % symmetrize (kills round-off asymmetry)
    sv = svd(S);
    sMax = sv(1);
    sMin = sv(end);
    sinfo.sMax = sMax;
    sinfo.sMin = sMin;
    if sMin > 0
        sinfo.cond = sMax / sMin;
    else
        sinfo.cond = inf;
    end
    if ~isfinite(sMax) || ~isfinite(sMin) || sMax <= 0
        sinfo.skipReason = 4;
    else
        sinfo.ran = true;
        sinfo.skipReason = 0;
        target = sMax / condMax;       % floor the smallest singular value here
        if sMin < target
            gamma = target - sMin;     % shift so cond(S+gamma*I) <= condMax
        end
    end
catch
    gamma = 0;                          % never let the probe break the solve
    sinfo.ran        = false;
    sinfo.caught     = true;
    sinfo.skipReason = 5;
end
if ~isfinite(gamma) || gamma < 0
    gamma = 0;
end
sinfo.gamma = gamma;
end

function v = getField(s, name, default)
%GETFIELD  Struct field read with a default (local helper).
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = default;
end
end

function ok = inertiaOK(info, n, mE)
%INERTIAOK  Test whether the factorization has the desired KKT inertia.
%   ok = inertiaOK(info, n, mE) returns true when the factorization succeeded
%   and the matrix inertia is exactly (n positive, mE negative, 0 zero), the
%   signature of a well-posed saddle-point system.
%
%   Inputs:
%     info - solver info struct with fields solved (logical) and inertia
%            (1-by-3 [pos, neg, zero] eigenvalue counts).
%     n    - expected number of positive eigenvalues (primal block).
%     mE   - expected number of negative eigenvalues (dual block).
%
%   Outputs:
%     ok - logical; true if solved and the inertia matches (n, mE, 0).
ok = info.solved && info.inertia(1) == n && info.inertia(2) == mE ...
     && info.inertia(3) == 0;
end
