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
%   capped at 40 tries AND at a regularization magnitude of 1e20, past which no
%   useful step can exist (the step underflows to zero) and further escalation
%   only hides the failure.
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
%              .regCapped      - logical; true when escalation stopped because
%                                delta or gamma reached the 1e20 ceiling rather
%                                than because the inertia came right.
%              .triesExhausted - logical; true when either cap (40 tries or the
%                                1e20 magnitude ceiling) was hit, in
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

% D15: the FIRST factorization always tries delta = 0 (IPOPT Algorithm IC).
% reg0 -- the previous iteration's accepted regularization -- only seeds the
% first RETRY.  Applying it up front perturbed every later Newton step once any
% iteration had needed regularization: the old /10-per-iteration decay kept
% delta and gamma in the matrix for hundreds of iterations, degrading the local
% rate and offsetting the feasibility row by gamma*dlamE.
deltaLast = 0;
if nargin >= 5 && ~isempty(reg0) && isfield(reg0, 'delta') && ~isempty(reg0.delta)
    deltaLast = reg0.delta;
end
reg = struct('delta', 0, 'gamma', 0);
% An explicit dual floor (reg0.gammaFloor) is a different thing from a stale
% previous-iteration gamma: degeneracy_regularizedRecovery asks for it on
% purpose, sized from the current residual, so honour it from the first try.
if nargin >= 5 && ~isempty(reg0) && isfield(reg0, 'gammaFloor') && ~isempty(reg0.gammaFloor)
    reg.gamma = reg0.gammaFloor;
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
% D15: tie the Fix-A shift to how far from feasible the iterate is.  The
% feasibility row is JE*dx - gamma*dlamE = -cE; in the near-null direction of S,
% gamma*dlamE -> that component of cE, so a gamma set from cond(S) alone (which
% depends on geometry, not on convergence) left feasibility stuck at
% ~gamma*||dlamE|| for the rest of the run.  Capping it at kappaG*||cE||_inf
% lets it vanish as feasibility is reached, as IPOPT's delta_c ~ mu^0.25 does.
kappaG = getField(opts, 'dualRegFeasFactor', 1);
if gammaScale > 0 && isfinite(kappaG) && isfield(res, 'rFeasE') && ~isempty(res.rFeasE)
    gammaScale = min(gammaScale, max(1e-8, kappaG * norm(res.rFeasE, inf)));
end
if gammaScale > reg.gamma
    reg.gamma = gammaScale;
end

[K, rhs, idx] = kkt_assemble(state, res, reg);
% A non-finite K or RHS (an Inf barrier term after an iterate reached a bound)
% used to spin all 40 regularization tries and return a NaN step (D30).
if ~all(isfinite(nonzeros(K))) || ~all(isfinite(rhs))
    d = zeros(size(rhs));
    info = struct('inertia', [0 0 0], 'minAbsPivot', NaN, 'maxAbsPivot', NaN, ...
        'medAbsPivot', NaN, 'rankDeficient', true, 'pivotSpread', NaN, ...
        'nearlySingular', true, 'factors', [], 'resRel', NaN, 'solved', false);
    info.tries = 0;  info.regCapped = false;  info.triesExhausted = true;
    info.nonFinite = true;  info.gammaFixA = gammaScale;  info.schur = schurInfo;
    info.reg = reg;  info.dualCapGrows = 0;
    return;
end
[d, info] = linalg_solveKKTdirect(K, rhs);
rankDefFirst = info.rankDeficient;   % JE (or K) singular at the unregularized solve

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
% Cap the escalation.  An unbounded x10 ladder from 1e-8 reaches delta = 1e31
% after 40 tries, and long before that the regularization has stopped meaning
% anything: past ~1e20 the (1,1) block is numerically delta*I, the step is
% dx ~ -rStat/delta which underflows to zero, and the loop goes on factorizing
% a matrix it has already destroyed.  A zero step is then handed to the line
% search, which "accepts" it, and the solver stalls for the rest of its
% iteration budget with no diagnostic.  Stop at a value past which no useful
% step can exist and report it instead (info.triesExhausted / info.regCapped).
regMax = 1e20;
maxTries = 40;
tries = 0;
capped = false;
while (~inertiaOK(info, n, mE) || pivotTooSmall(info, pivotRelTol)) && tries < maxTries
    grew = false;
    if info.rankDeficient || (inertiaOK(info, n, mE) && pivotTooSmall(info, pivotRelTol))
        % Near-singular constraint block: grow dual regularization.
        if reg.gamma == 0
            newGamma = 1e-8;
        else
            newGamma = reg.gamma * 10;
        end
        if newGamma <= regMax
            reg.gamma = newGamma;  grew = true;
        else
            capped = true;
        end
    end
    if ~inertiaOK(info, n, mE)
        % Wrong inertia: grow primal regularization.  First retry from the
        % previous iteration's value / 3 when there is one (D15, IPOPT
        % kappa_w^- = 1/3), else 1e-8; then grow x8 (kappa_w^+).
        if reg.delta == 0
            if deltaLast > 0
                newDelta = max(1e-20, deltaLast / 3);
            else
                newDelta = 1e-8;
            end
        else
            newDelta = reg.delta * 8;
        end
        if newDelta <= regMax
            reg.delta = newDelta;  grew = true;
        else
            capped = true;
        end
    end
    if ~grew
        % Both knobs are at the cap; another factorization would return the
        % same answer, so stop rather than spin.
        break;
    end
    [K, rhs, idx] = kkt_assemble(state, res, reg);
    [d, info] = linalg_solveKKTdirect(K, rhs);
    tries = tries + 1;
end

% D5.2: enforce the dual-step cap THROUGH the regularization.  When the dual
% block is already regularized (gamma > 0: near-singular or rank-deficient JE)
% the step can still carry dlamE ~ cE/gamma; solve.m's Fix B then caps the
% multiplier increment, but the primal step was solved together with the
% uncapped dlamE (W*dx = -r - JE'*dlamE) and keeps its amplification.  On the
% unit circle from x0 = 0 with FD gradients that amplified a 1e-8 FD error into
% an O(1) step toward the constrained MAXIMUM.  Grow gamma until the coupled
% solve itself respects the cap, so dx and dlamE stay consistent.
%
% Only when the first, unregularized factorization was RANK-DEFICIENT -- the
% degenerate-Jacobian case D5 is about -- and only when opts.dualCapViaGamma is
% true (solve.m resolves the default 'equality' to true in the equality core
% only).  In the IP core, on lvdExample_MunarFlybyContinuityConstraint
% (30 iterations) the cap took the final violation from 4.3e-2 (dualStepMax =
% Inf) to 0.40; that JE is genuinely rank-deficient (cond ~1e17), so the
% rank gate alone does not help (0.48).  A gate that separates that case from
% the FD-noise unit circle is still open.
dualCapGrows = 0;
capFac = getField(opts, 'dualStepMax', inf);
if rankDefFirst && isequal(getField(opts, 'dualCapViaGamma', false), true) && ...
        reg.gamma > 0 && isfinite(capFac) && capFac > 0 && mE > 0 && info.solved
    lamE0 = zeros(mE, 1);
    if isfield(state, 'lamE') && numel(state.lamE) == mE, lamE0 = state.lamE(:); end
    cap = capFac * max(1, norm(lamE0, inf));
    while dualCapGrows < 6
        nd = norm(d(idx.lamE), inf);
        if ~(nd > cap), break; end
        newGamma = reg.gamma * max(10, nd / cap);
        if newGamma > regMax, break; end
        reg.gamma = newGamma;
        [K, rhs, idx] = kkt_assemble(state, res, reg);
        [d, info] = linalg_solveKKTdirect(K, rhs);
        dualCapGrows = dualCapGrows + 1;
        if ~info.solved, break; end
    end
end

% Record what the correction did. Purely observational -- nothing below is read
% back by this function or by its callers to make a decision.
info.dualCapGrows   = dualCapGrows;
info.tries          = tries;
info.regCapped      = capped;
info.triesExhausted = (capped || tries >= maxTries) && ...
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
%   gamma = max(0, lambda_max(S)/dualCondMax - lambda_min(S)).  Returns 0 (no dual
%   regularization) when Fix A is disabled or inapplicable:
%     - opts empty / dualCondMax not finite / dualCondMax <= 0  -> disabled,
%     - mE == 0 (no equality block) or mE > dualCondProbeMaxDim -> skipped
%       (the O(mE^2*n) probe is too costly; the pivot gate acts instead),
%     - S ill-formed / singular W / non-finite spectrum           -> skipped,
%     - S indefinite (possible when W is an indefinite secant Hessian) -> skipped,
%       since no positive shift bounds the condition number of an indefinite S.
%   Only the extreme eigenvalues of S are needed, but for the moderate mE this
%   solver targets a dense eig is simplest and robust; the cost guard bounds it.
%
%   SINFO reports what the probe saw: ran, sMax, sMin, cond (= sMax/sMin), gamma,
%   caught (the try/catch fired), and skipReason (0 ran | 1 disabled | 2 mE==0 |
%   3 over the dimension cap | 4 non-finite spectrum | 5 caught |
%   6 indefinite S). sMax and sMin are reported as MAGNITUDES (max|lambda| and
%   min|lambda|) so cond stays meaningful on the indefinite branch too; the
%   shift itself uses the signed minimum. They are
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
    % EIGENVALUES, not singular values.  The shift below is S -> S + gamma*I,
    % which moves every EIGENvalue up by gamma; "cond(S + gamma*I) <= condMax"
    % only follows from sigma_max/sigma_min when S is positive semidefinite, and
    % S is NOT guaranteed PSD here: in the equality core W = state.H is the raw
    % secant Lagrangian Hessian, which is indefinite away from a solution (that
    % is precisely why the inertia correction exists).  With an indefinite S,
    % svd reports |lambda|, so a near-zero NEGATIVE eigenvalue -sMin would be
    % shifted to gamma - sMin -- TOWARD zero, making the reduced dual system
    % more singular than it was.  Reading the signed spectrum lets us both apply
    % the shift to the right quantity and decline the probe outright when S has
    % a negative eigenvalue, where no positive shift can bound the condition
    % number and the pivot gate must act instead.
    evS = eig(S);
    evS = real(evS);                   % symmetric: imaginary parts are round-off
    sMax = max(abs(evS));
    sMinSigned = min(evS);
    sMin = min(abs(evS));
    sinfo.sMax = sMax;
    sinfo.sMin = sMin;
    if sMin > 0
        sinfo.cond = sMax / sMin;
    else
        sinfo.cond = inf;
    end
    if ~all(isfinite(evS)) || sMax <= 0
        sinfo.skipReason = 4;
    elseif sMinSigned < 0
        sinfo.skipReason = 6;          % indefinite S: a positive shift cannot help
    else
        sinfo.ran = true;
        sinfo.skipReason = 0;
        target = sMax / condMax;       % floor the smallest eigenvalue here
        if sMinSigned < target
            gamma = target - sMinSigned;   % shift so cond(S+gamma*I) <= condMax
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
