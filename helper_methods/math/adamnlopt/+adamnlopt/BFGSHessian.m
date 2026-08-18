classdef BFGSHessian < adamnlopt.HessianModel
%BFGSHESSIAN  Full-memory (dense) BFGS approximation of the Lagrangian Hessian.
%   Maintains a dense n-by-n SPD matrix B by the rank-2 BFGS update
%       B <- B - (B*s)(B*s)'/(s'*B*s) + y*y'/(y'*s)
%   from the constrained secant pair
%       s = x_{k+1} - x_k,   y = gradL(x_{k+1}, lam) - gradL(x_k, lam)
%   supplied by the caller. Curvature accumulates in EVERY direction ever
%   sampled and is never evicted, unlike the limited-memory LBFGSHessian.
%
%   Cost trade against LBFGSHessian(n, m):
%     update    - O(n^2) here, fixed;  O(n*m) there.
%     getMatrix - O(1) here (B is stored);  O(n^2*m) + O(m^3) there, because
%                 the compact representation is rebuilt on every call.
%   Since solve.m calls getMatrix once per iteration and every consumer
%   (kkt_assemble, kkt_inertiaCorrection, the condensed Newton system) needs a
%   real n-by-n matrix anyway, full BFGS is usually the cheaper model whenever a
%   dense B fits at all -- which is implied by the solver already forming a
%   dense (n+mE)-by-(n+mE) KKT matrix.
%
%   B0 = gamma0*I is scaled ONCE from the first curvature pair (Nocedal &
%   Wright 6.20) and never rescaled thereafter; see the update method for why
%   the curvature cap inherited from LBFGSHessian matters more here than there.
%   The b0Refresh trigger rebases that scale when the measured curvature regime
%   moves away from it -- see REBASE.  This class property defaults to false so
%   a directly-constructed model keeps the plain textbook behaviour; solve.m
%   forwards opts.bfgsB0Refresh, which has defaulted to TRUE since 2026-08-12
%   (see defaultOptions for the measurements that justified the flip).
%
%   Properties:
%     n            - problem dimension.
%     gammaMin     - floor on the one-shot B0 scaling.
%     gammaMax     - ceiling on the one-shot B0 scaling (absolute backstop).
%     gammaCurvCap - ceiling on B0 relative to the sampled directional curvature.
%     powellEta    - Powell-damping threshold (fraction of s'Bs).
%     autoScaleB0  - scale B0 from the first pair (true) or leave B0 = I.
%     condMax      - condition-number ceiling before B is rebuilt.
%     warnDim      - dimension above which the dense storage is warned about.
%
%   B0-refresh trigger (all inert unless b0Refresh is true):
%     b0Refresh           - enable curvature-regime rebasing of B0.
%     b0RefreshWindow     - pairs in the rolling geometric-median window.
%     b0RefreshFactor     - drift ratio from gammaBase that fires a rebase.
%     b0RefreshRefractory - minimum pairs between two rebases.
%     b0RefreshMaxDrop    - largest single-rebase reduction in gammaBase.
%     b0RefreshMinLearned - block a rebase once this fraction of n has been
%                           learned since the last one (inf disables the gate).
%
%   Read-only diagnostics:
%     gamma0    - the FIRST-PAIR B0 scaling; frozen for the life of the object.
%     gammaBase - the B0 scaling B currently sits on (moves with rebase).
%     gammaLast - most recent sampled curvature (s'y)/(s's).
%     nUpdates  - accepted secant pairs since construction or reset.
%     nResets   - internal conditioning recoveries; should be 0 on a clean run.
%     nRebases  - curvature-regime rebases; distinct from nResets, not a fault.
%     condLast  - condition estimate from the most recent health check.
%     scaled    - whether B0 has been scaled yet.
%
%   Methods:
%     BFGSHessian - construct an approximation for an n-dimensional problem.
%     reset       - discard B entirely and return to B = I.
%     rebase      - re-centre B on a new scalar curvature scale.
%     update      - add a curvature pair (s, y) with Powell damping.
%     getMatrix   - return the dense SPD matrix B.
%     apply       - compute the Hessian-vector product B*v.
%     diagonal    - diag(B), for the Jacobi preconditioner.
%
%   See also LBFGSHESSIAN, HESSIANMODEL, LAGRANGIANHESSIAN, HESSIANVECPRODUCT.

    properties
        n            = 0
        gammaMin     = 1e-8   % floor on the one-shot B0 scaling
        gammaMax     = 1e8    % ceiling on the B0 scaling (absolute backstop)
        gammaCurvCap = 1e4    % ceiling on B0 relative to directional curvature
        powellEta    = 0.2    % Powell-damping threshold (fraction of s'Bs)
        autoScaleB0  = true   % scale B0 once from the first curvature pair
        condMax      = 1e12   % rebuild B when its condition estimate exceeds this
        warnDim      = 5000   % warn about dense storage above this dimension

        b0Refresh           = false % rebase B0 when the curvature regime moves
        b0RefreshWindow     = 8     % pairs in the rolling geometric median
        b0RefreshFactor     = 3     % drift ratio from gammaBase that fires
        b0RefreshRefractory = 5     % minimum pairs between two rebases
        b0RefreshMaxDrop    = 100   % largest single-rebase reduction in gammaBase
        b0RefreshMinLearned = 0.20  % block a rebase past this fraction of n learned
        resetMaxDrop        = inf   % largest single-reset reduction in gammaBase
    end
    properties (SetAccess = private)
        gamma0    = 1        % first-pair B0 scaling; frozen for the object's life
        gammaBase = 1        % B0 scaling B currently sits on (moves with rebase)
        gammaLast = 1        % most recent sampled curvature (s'y)/(s's)
        nUpdates  = 0        % accepted pairs since construction or reset
        nResets   = 0        % internal conditioning recoveries (health signal)
        nRebases  = 0        % curvature-regime rebases (not a fault signal)
        condLast  = NaN      % cond(B) at the most recent health check
        scaled    = false    % has B0 been scaled yet?
    end
    properties (Access = private)
        B          = []      % n-by-n dense SPD approximation
        sinceCheck = 0       % iterations since the last conditioning check
        gammaWin   = []      % rolling window of recent gammaLast values
        sinceRebase = 0      % accepted pairs since the last rebase/flatten
    end

    methods
        function obj = BFGSHessian(n)
        %BFGSHESSIAN  Construct a full-memory BFGS Hessian model.
        %   obj = BFGSHessian(n) creates the model for an n-dimensional problem,
        %   starting from B = eye(n). There is deliberately no memory argument:
        %   full BFGS retains every accepted pair, so opts.lbfgsMemory is
        %   meaningless here and its absence documents that at the call site.
        %
        %   Inputs:
        %     n - problem dimension (length of the s and y vectors).
        %
        %   Outputs:
        %     obj - the constructed BFGSHessian handle object.
            obj.n = n;
            obj.B = eye(n);
            if n > obj.warnDim
                warning('adamnlopt:bfgsLargeN', ...
                    ['Full BFGS stores a dense %d-by-%d Hessian (%.1f GB). ' ...
                     'Consider hessianApprox=''lbfgs'' instead.'], ...
                    n, n, 8 * n^2 / 2^30);
            end
        end

        function reset(obj)
        %RESET  Discard the accumulated curvature and its scale.
        %   reset(obj) restores B = eye(n) and clears gamma0, so the next pair
        %   re-derives the B0 scaling from scratch. Called by solve.m after a
        %   restoration phase, which jumps both x and lam discontinuously and
        %   therefore invalidates the curvature AND the scale it was measured
        %   at; re-deriving gamma0 costs one iteration and is more honest than
        %   carrying a pre-jump scale forward.
        %
        %   This is distinct from the internal conditioning recovery, which
        %   keeps the scale (the iterate did not jump, only B went bad).
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %
        %   Outputs:
        %     (none) obj is modified in place.
            obj.B           = eye(obj.n);
            obj.gamma0      = 1;
            obj.gammaBase   = 1;
            obj.gammaLast   = 1;
            obj.scaled      = false;
            obj.nUpdates    = 0;
            obj.sinceCheck  = 0;
            obj.gammaWin    = [];
            obj.sinceRebase = 0;
        end

        function gUsed = rebase(obj, g)
        %REBASE  Re-centre B on a new scalar curvature scale.
        %   gUsed = rebase(obj, g) discards the accumulated curvature and
        %   restarts from B = gUsed*eye(n), where gUsed is g clamped to
        %   [gammaMin, gammaMax]. gamma0 is deliberately NOT touched: it is the
        %   frozen first-pair diagnostic, and callers compare against it to see
        %   how far the regime has moved. gammaBase tracks the live value.
        %
        %   WHY A FULL DISCARD RATHER THAN A SPECTRAL CORRECTION.  The stale
        %   scale survives specifically in the directions the secant pairs never
        %   sampled, so the obvious repair is to shift only the eigenvalues still
        %   pinned at the old scale. That was measured on a real 457-dimensional
        %   plateau iterate and does not work: no clustering tolerance both
        %   catches every pinned direction and leaves B positive definite -- a
        %   loose tolerance drives min(eig(B)) negative, a tight one leaves a
        %   sixth of the nullspace untouched. Nor can B be re-based additively as
        %   gNew*I + (B - gamma0*I), because that second term is itself
        %   indefinite. Discarding is cheap in practice: on that iterate only 10
        %   of 148 nullspace directions carried learned curvature at all, and the
        %   flat model recovered 55% of the attainable quadratic decrease against
        %   0.03% for the accumulated one.
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %     g   - the new scalar curvature scale (clamped before use).
        %
        %   Outputs:
        %     gUsed - the clamped scale actually applied.
            gUsed = min(max(g, obj.gammaMin), obj.gammaMax);
            obj.setScale(gUsed);   % also clears the window and re-arms the refractory
            obj.nRebases = obj.nRebases + 1;
        end

        function accepted = update(obj, s, y)
        %UPDATE  Add a curvature pair (s, y) to the dense BFGS approximation.
        %   accepted = update(obj, s, y) scales B0 on the first usable pair,
        %   applies Powell damping to y, and performs the rank-2 BFGS update.
        %
        %   B0 SCALING (once, then never again).  The textbook estimate
        %   g = (y'y)/(s'y) is the largest directional curvature the pair
        %   carries; the curvature actually sampled along the step is
        %   gCurv = (s'y)/(s's). Capping g at gammaCurvCap*gCurv keeps B0 within
        %   a bounded factor of real curvature. That cap matters MORE here than
        %   in LBFGSHessian: there gamma is refreshed every iteration, so one
        %   bad pair poisons one iteration, whereas here gamma0 is permanent and
        %   survives in every direction the secant pairs never sample. On a
        %   problem whose equality constraints leave a wide nullspace, a gamma0
        %   that pinned at gammaMax would sit in the model for the entire solve
        %   -- the observed source of an earlier limit cycle.
        %
        %   WHY THE SCALING PAIR IS NOT DAMPED.  By Cauchy-Schwarz
        %   (y'y)/(s'y) >= (s'y)/(s's), so gamma0 >= gCurv and s'B0s >= s'y
        %   always. When the curvature cap binds -- i.e. s and y are nearly
        %   orthogonal -- s'B0s = gammaCurvCap*s'y, so the Powell test
        %   s'y >= eta*s'B0s fails by a factor of ~1/(eta*gammaCurvCap) and
        %   damping would replace the only curvature sample available with B0*s,
        %   degenerating the first update to nothing. Damping exists to restore
        %   positive definiteness when s'y <= eta*s'Bs, but B0 was constructed
        %   FROM this pair and the plain update is provably PD whenever s'y > 0
        %   (s'B1s = gamma0*(s's - s's) + (s'y)^2/(s'y) = s'y > 0), so damping
        %   there is circular. It is fully active from the second pair on.
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %     s   - n-by-1 step x_{k+1} - x_k.
        %     y   - n-by-1 Lagrangian-gradient change gradL(x_{k+1}) - gradL(x_k).
        %
        %   Outputs:
        %     accepted - logical; true if the (possibly damped) pair was
        %                incorporated, false if it was rejected as degenerate or
        %                of insufficient curvature.
            s = s(:);  y = y(:);
            ss = s.' * s;
            accepted = false;
            if ~(ss > 0) || ~all(isfinite(s)) || ~all(isfinite(y))
                return;   % degenerate/invalid step: nothing to learn
            end

            % One-shot B0 scaling, applied BEFORE the first update.
            firstScaled = false;
            if ~obj.scaled && obj.autoScaleB0
                syRaw = s.' * y;
                if syRaw > 0
                    g     = (y.' * y) / syRaw;
                    gCurv = syRaw / ss;                  % sampled curvature > 0
                    g     = min(g, obj.gammaCurvCap * gCurv);
                    g     = min(max(g, obj.gammaMin), obj.gammaMax);
                    obj.B       = g * eye(obj.n);
                    obj.gamma0  = g;      % frozen from here on
                    obj.gammaBase = g;    % live scale, may move under rebase
                    obj.scaled  = true;
                    firstScaled = true;
                end
                % syRaw <= 0: keep B0 = I and retry the scaling on a later pair.
            end

            % Powell damping toward the current model (Nocedal & Wright 18.2).
            % B*s is a direct dense multiply here -- no compact-form rebuild.
            Bs  = obj.B * s;
            sBs = s.' * Bs;
            sy  = s.' * y;
            if ~firstScaled && sBs > 0 && sy < obj.powellEta * sBs
                phi = (1 - obj.powellEta) * sBs / (sBs - sy);
                phi = min(max(phi, 0), 1);          % numerical safety
                y   = phi * y + (1 - phi) * Bs;     % damped y-bar
                sy  = s.' * y;                      % now >= eta*sBs > 0
            end

            if ~(sy > 0) || ~(sBs > 0) || ~all(isfinite(Bs)) || ~all(isfinite(y))
                return;   % damping could not restore curvature; skip the pair
            end
            % Relative floor on s'y: refuse to divide by numerical noise, which
            % would otherwise inject an enormous y*y'/sy rank-1 term.
            if sy <= eps(sy) * max(1, abs(s.' * y) + norm(y) * sqrt(ss))
                return;
            end

            % Rank-2 BFGS update.  (B+B')/2 is exactly symmetric in IEEE
            % arithmetic, so issymmetric(getMatrix()) holds and the downstream
            % ldl factorization never sees a skewed matrix.
            obj.B = obj.B - (Bs * Bs.') / sBs + (y * y.') / sy;
            obj.B = (obj.B + obj.B.') / 2;

            obj.nUpdates  = obj.nUpdates + 1;
            obj.gammaLast = sy / ss;
            accepted      = true;
            obj.healthCheck();
            obj.b0RefreshCheck();
        end

        function B = getMatrix(obj)
        %GETMATRIX  Return the dense SPD Hessian approximation B.
        %   B = getMatrix(obj) is O(1): B is maintained explicitly, so unlike
        %   the limited-memory model there is nothing to reconstruct. Callers
        %   immediately add regularization and barrier terms to the result, so
        %   MATLAB's copy-on-write hands them their own copy at that point.
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %
        %   Outputs:
        %     B - n-by-n symmetric positive-definite Hessian approximation.
            B = obj.B;
        end

        function Bv = apply(obj, v)
        %APPLY  Hessian-vector product B*v.
        %   Bv = apply(obj, v) multiplies by the stored matrix directly.
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %     v   - n-by-1 vector to multiply by B.
        %
        %   Outputs:
        %     Bv - n-by-1 product B*v.
            Bv = obj.B * v(:);
        end

        function d = diagonal(obj)
        %DIAGONAL  Exact diagonal of B, for the Jacobi preconditioner.
        %   d = diagonal(obj) is cheap and exact because B is stored, so
        %   kkt_KKTOperator can populate op.diag and the Krylov path gets real
        %   Jacobi preconditioning instead of the identity fallback that a
        %   limited-memory model is limited to.
        %
        %   Inputs:
        %     obj - the BFGSHessian handle object.
        %
        %   Outputs:
        %     d - n-by-1 diagonal of B.
            d = diag(obj.B);
        end
    end

    methods (Access = private)
        function healthCheck(obj)
        %HEALTHCHECK  Detect and repair a B that has drifted indefinite.
        %   Full BFGS accumulates rounding over hundreds of updates, so unlike
        %   the limited-memory model -- which rebuilds B from at most m pairs
        %   every call and thus cannot drift -- it needs an explicit guard. A
        %   Cholesky factorization both tests definiteness and yields a free
        %   condition estimate from its diagonal.
        %
        %   This is not redundant with kkt_inertiaCorrection: that masks a bad
        %   Hessian by growing delta, permanently, whereas resetting lets the
        %   model recover and rebuild genuine curvature. nResets is exposed so a
        %   run can be checked for silent reliance on this path.
        %
        %   Cost at n = 457: chol is ~3.2e7 flops (~2 ms) against ~20 s per
        %   solver iteration on the target problem, hence the per-update check
        %   for moderate n and the decimated check above n = 1000.
        %
        %   KAPPA is recorded in condLast rather than discarded: it is the exact
        %   quantity that decides whether B is flattened back to a scaled
        %   identity, and a run where that happens repeatedly is following a
        %   curvature-free model while appearing to use full BFGS. Reading the
        %   reset counter at exit cannot distinguish "never close" from
        %   "perpetually just under the ceiling".
            obj.sinceCheck = obj.sinceCheck + 1;
            if obj.n > 1000
                period = 10;
            else
                period = 1;
            end
            if obj.sinceCheck < period
                return;
            end
            obj.sinceCheck = 0;

            if ~all(isfinite(obj.B(:)))
                obj.condLast = inf;
                obj.resetToScaled();  return;
            end
            [R, p] = chol(obj.B);
            if p ~= 0
                obj.condLast = inf;   % not SPD: no finite estimate to report
                obj.resetToScaled();  return;
            end
            dR = abs(diag(R));
            kappa = (max(dR) / max(min(dR), realmin))^2;   % cond(B) from the factor
            obj.condLast = kappa;
            if ~isfinite(kappa) || kappa > obj.condMax
                obj.resetToScaled();
            end
        end

        function resetToScaled(obj)
        %RESETTOSCALED  Rebuild B from the most recent curvature, keeping scale.
        %   Unlike the public reset, this leaves scaled = true and gamma0 alone:
        %   the iterate did not jump, only the accumulated matrix went bad, so
        %   the curvature scale is still the best information available.
        %
        %   Shares setScale with rebase -- the two differ only in what provoked
        %   them (a conditioning fault here, a regime shift there) and in which
        %   counter they bump, which is why they must stay separately countable.
        %
        %   RESETMAXDROP MIRRORS B0REFRESHMAXDROP, AND THE ASYMMETRY IS THE POINT.
        %   b0RefreshCheck will not soften gammaBase by more than a bounded factor
        %   in one move, because "too soft a B0 gives too long a step" is a
        %   measured divergence mode (see that method's comment). It reaches a new
        %   scale only through b0RefreshWindow agreeing samples reduced by a
        %   geometric median. This path had none of that: it takes ONE unfiltered
        %   gammaLast, floored only at gammaMin, and installs it. The deliberate
        %   path was guarded and the fault path was not, even though the fault path
        %   fires precisely when the curvature sample is least trustworthy -- B has
        %   just gone non-SPD or exceeded condMax.
        %
        %   Measured on the 2002-iteration orbit run (oscTrace.mat): 57 resets, all
        %   57 on a condB = Inf iteration. 24 of them cut gammaBase by more than
        %   100x, the largest by 1.57e+05. Those 24 are followed by normDx median
        %   4.83e+01 and aP < 1e-3 on 100% of iterations, against 9.52e-03 and 39%
        %   for the 33 bounded ones; Spearman log(drop) vs log next-normDx = +0.849.
        %   gammaBase reaches 1.71e-08, i.e. gammaMin, making B numerically zero and
        %   the Newton step effectively unbounded.
        %
        %   The apparent post-reset improvement in opt (-0.0626 over five iterations
        %   against +0.0145 for bounded resets) is REGRESSION TO THE MEAN, not a
        %   benefit: opt has already risen +0.3492 in the five iterations INTO a
        %   big-drop reset, so the net across the window is +0.3164 versus +0.0470.
        %   Check the run-up before reading a recovery as a gain.
        %
        %   Default inf preserves the historical behaviour exactly, because the
        %   correlation above cannot separate "the unbounded drop causes the long
        %   step" from "genuinely tiny curvature causes both". Only an A/B can.
            gNew = max(obj.gammaLast, obj.gammaMin);
            if isfinite(obj.resetMaxDrop) && obj.resetMaxDrop >= 1 && obj.scaled
                gNew = max(gNew, obj.gammaBase / obj.resetMaxDrop);
            end
            obj.setScale(gNew);
            obj.nResets = obj.nResets + 1;
        end

        function b0RefreshCheck(obj)
        %B0REFRESHCHECK  Rebase B0 when the curvature regime has moved.
        %   gamma0 is measured once, from the first secant pair, and because
        %   BFGS updates are rank-2 it survives untouched in every direction the
        %   run never samples. On a long solve the regime that pair was taken in
        %   is gone: on the orbit-raising problem the first pair lands at
        %   mu = 1e-1 and the run then spends a hundred iterations at mu = 2e-6,
        %   where the measured tangential curvature is four orders smaller. Every
        %   unsampled direction stays stiff by that factor and the step collapses
        %   -- the model gave up 99.97% of the attainable decrease on a measured
        %   plateau iterate while pointing in very nearly the right direction.
        %
        %   The trigger is a rolling GEOMETRIC median of gammaLast. Geometric
        %   because gammaLast spans three orders across a single run and an
        %   arithmetic mean is owned by its spikes; a median because a single
        %   anomalous pair should not rebase the model. Firing on a barrier-
        %   parameter decrease instead was tried and rejected: mu freezes early
        %   and stops firing exactly where the drift becomes worst.
        %
        %   THE FLOOR IS LOAD-BEARING. Too soft a B0 gives too long a step: a
        %   fixed-cap sweep on the same problem diverged outright (feasibility
        %   4.6e+02 by iteration 16) once B0 fell just below the true maximum
        %   tangential curvature. b0RefreshMaxDrop bounds a single rebase so one
        %   anomalous window cannot cross that cliff in one move; repeated fires
        %   still reach a soft scale, but only through measurements that agree.
            if ~obj.b0Refresh
                return;
            end
            obj.sinceRebase = obj.sinceRebase + 1;
            g = obj.gammaLast;
            if ~isfinite(g) || g <= 0
                return;   % nothing meaningful to add to the window
            end
            obj.gammaWin(end+1) = g;
            w = max(1, round(obj.b0RefreshWindow));
            if numel(obj.gammaWin) > w
                obj.gammaWin = obj.gammaWin(end-w+1:end);
            end
            if numel(obj.gammaWin) < w || obj.sinceRebase < obj.b0RefreshRefractory
                return;   % not enough evidence yet, or still in the refractory
            end
            % THE LEARNED-FRACTION GATE.  A rebase costs whatever B has learned,
            % and rank(B - gammaBase*I) <= 2*sinceRebase, so pairs-since-rebase
            % relative to n measures how much the discard throws away. Cheap when
            % the model has sampled a sliver of the space, ruinous when it has
            % saturated: on a 20-variable problem where dense BFGS was converging
            % superlinearly, ungated rebases at 22 pairs (1.10*n) turned ef=1 in
            % 34 iterations with opt 3.8e-07 into ef=2 in 70 with opt 8.5e-05 --
            % same minimiser, rate destroyed. On the 457-variable orbit problem
            % every rebase lands at 0.018-0.033*n and is the fix.
            %
            % GATING ON OPTIMALITY PROGRESS INSTEAD DOES NOT WORK.  Three forms
            % were measured against both real traces and all three failed. The
            % ratio opt(k)/opt(k-5) is 2.94 at the single most damaging rebase --
            % opt is RISING there, so "suppress while descending" lets the worst
            % one through. A trailing log-slope (windows 5 to 20) puts the harmful
            % rebases at -0.188..+0.001 and the plateau that must still fire at
            % -0.109..+0.082, overlapping ranges. A best-opt stall counter gives
            % harmful [4 12 0 6 0] against useful [7 15 4 4 16 24 33 8 17 32]:
            % max harmful exceeds min useful, so no threshold separates them. opt
            % is a symptom both cases share; the learned fraction is the thing
            % that actually differs, and it separates them by 12x.
            if obj.n > 0 && obj.sinceRebase >= obj.b0RefreshMinLearned * obj.n
                return;   % too much accumulated curvature to be worth discarding
            end

            gMed  = exp(median(log(obj.gammaWin)));
            drift = max(gMed / obj.gammaBase, obj.gammaBase / gMed);
            if ~isfinite(drift) || drift <= obj.b0RefreshFactor
                return;
            end
            % Bound the descent, not the ascent: an over-stiff B0 shortens the
            % step and merely wastes iterations, whereas an over-soft one is the
            % measured divergence mode.
            gNew = max(gMed, obj.gammaBase / max(obj.b0RefreshMaxDrop, 1));
            obj.rebase(gNew);
        end

        function setScale(obj, g)
        %SETSCALE  Restart B from g*eye(n), recording the live scale.
        %   The single place B is flattened to a scalar multiple of the
        %   identity. sinceCheck is cleared because a scaled identity is
        %   trivially well conditioned and re-checking it is wasted work.
        %
        %   THE WINDOW AND THE COUNTER BELONG HERE, NOT IN REBASE.  Both callers
        %   flatten B, so after either one the rolling median describes a regime
        %   that no longer exists and the model has learned nothing since. When
        %   only rebase cleared them, a conditioning reset moved gammaBase (via
        %   this method) while leaving a stale window behind, so the very next
        %   drift test compared a fresh, possibly spiky gammaBase against a
        %   pre-reset median -- firing a spurious rebase or suppressing a
        %   warranted one. That path is unexercised on every run measured so far
        %   (nResets = 0 throughout), which is exactly why it needed fixing
        %   before something tripped it rather than after.
            obj.B           = g * eye(obj.n);
            obj.gammaBase   = g;
            obj.sinceCheck  = 0;
            obj.gammaWin    = [];   % the window described the pre-flatten regime
            obj.sinceRebase = 0;    % re-learning restarts: gate and refractory alike
        end
    end
end
