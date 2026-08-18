function opts = defaultOptions()
%DEFAULTOPTIONS  Default options struct for adamnlopt.solve.
%   opts = adamnlopt.defaultOptions() returns a struct of default settings.
%   Fields may be overridden by passing a struct (or an optimoptions object)
%   as the final argument to adamnlopt.solve. fmincon option names are also
%   recognized and mapped onto these fields (see mapFminconOptions).
%
%   The returned struct groups the tunable parameters that govern every stage
%   of the interior-point / SQP solver. The main groups are:
%     Derivatives      - gradient/Hessian supply flags, FD step and type,
%                         and sparsity patterns (SpecifyObjectiveGradient,
%                         SpecifyConstraintGradient, HessianFcn, HessPattern,
%                         JacobPattern, FiniteDifferenceStepSize/Type).
%     Bound honoring   - HonorBounds keeps x0 and every finite-difference and
%                         calibration probe inside [lb,ub]; ON by default.
%     Termination      - stopping tolerances and budgets (optTol, feasTol,
%                         compTol, stepTol, maxIter, maxFunEvals, maxTime).
%     Hessian model    - hessianApprox ('exact'|'fd'|'lbfgs' limited-memory|
%                         'bfgs' full-memory dense) and lbfgsMemory ('lbfgs'
%                         only).
%     Linear algebra   - direct vs Krylov KKT solves, forcing sequence, and
%                         preconditioning (linearSolver, krylovMethod, etc.).
%     Scaling          - automatic problem scaling (autoScale); ON by default.
%     Globalization    - filter vs merit line search (globalization).
%     Barrier schedule - central-path parameters (mu0, muMin, muGamma, muBeta,
%                         kappaMu, tau).
%     Trust region     - radius control (delta0, deltaMax, trEta1/2, trShrink,
%                         trExpand, useNTdecomp, trMaxInner).
%     Adaptive/extras  - mode switching, restoration, parallelism, second-order
%                         correction, least-squares multiplier refresh,
%                         degeneracy detection, and Broyden Jacobian updates.
%     Output           - Display ('off'|'iter'|'iter-debug'|'final'), LogFile,
%                         and which iterate a limit exit returns (returnIterate).
%
%   Inputs:
%     (none)
%
%   Outputs:
%     opts - scalar struct of default solver options. See the grouped comments
%            in the body for the exact fields, allowed values, and meaning.
%
%   See also MAPOPTIONS, VALIDATEPROBLEM, INITIALIZEITERATE.

opts = struct();

% --- Derivatives (fmincon-compatible flags mirrored below) ---
opts.SpecifyObjectiveGradient  = false;  % fun returns [f,g]
opts.SpecifyConstraintGradient = false;  % nonlcon returns [c,ceq,gc,gceq]
opts.HessianFcn                = [];      % @(x,lambda) Hessian of Lagrangian
opts.HessPattern               = [];      % sparsity pattern of Hessian
opts.JacobPattern              = [];      % sparsity pattern of nonlinear c Jacobian
opts.FiniteDifferenceStepSize  = sqrt(eps);
opts.FiniteDifferenceType      = 'forward'; % 'forward' | 'central'

% --- Keep every evaluation inside the bounds (ON by default) ---
% The accepted ITERATES have always stayed strictly inside [lb,ub]: x0 is
% projected in by initializeIterate and every step is capped by the
% fraction-to-boundary rule.  The EVALUATIONS were not: three separate paths
% called fun/nonlcon outside the box, measured 2026-08-13.
%   (1) x0 was passed through unclipped.  validateProblem only checked lb<=ub, so
%       the scaling probe, the FD-step calibration, and the first objective and
%       constraint evaluations all happened at the raw x0 -- BEFORE
%       initializeIterate projected it in.  On tests/tHohmannTransfer, whose z0(1)
%       = 0.40*v1c = 3.0184 sits against ub(1) = 2.9914, that is a 0.027 km/s
%       overshoot, and it is the true origin of the overshoot the test's
%       transferOrbit comment attributes to the interior-point iterates.
%   (2) The autoFDStep V-curve sweeps h = 1e-1 .. 1e-9 along a full-length probe
%       direction from x0 with no bound awareness.  On a box 1e-3 wide the probes
%       landed 92 BOX WIDTHS outside it.
%   (3) The finite-difference gradient/Jacobian probes step sqrt(eps)*max(1,|x|)
%       with no bound awareness.  The barrier drives an active variable to within
%       mu/z of its bound, which goes BELOW the FD step, so the probe crosses: at
%       optTol = 1e-10 the iterate sat 2.5e-12 from ub and probes went 1.49e-8
%       over.
% That matters whenever fun/nonlcon is only real-valued (or only defined) inside
% the box -- see tests/tHohmannTransfer, where an out-of-branch value reaches the
% KKT matrix and the solve dies inside ldl with "Matrix must have real diagonal"
% rather than returning a bad exitflag.
%
% When HonorBounds is true: x0 is clipped into [lb,ub] (with a warning), the
% calibration sweep is clamped to steps that keep both probe endpoints in the
% box, and every finite-difference probe is kept inside the box -- flipping a
% forward difference to a BACKWARD one where the forward step would not fit
% (same cost, same order of accuracy, still reusing the base value), and
% shrinking the step only where neither side has room.
%
% Note this is NOT free: near an active bound the flipped difference reaches back
% into the interior across a region where the objective may be steeper, so the
% gradient stays first-order correct but is not the same number as before.  Set
% false to recover the pre-2026-08-13 behaviour bit-for-bit (the FD path then
% runs with infinite bounds, so it takes exactly the legacy steps).
%
% The name and default match fmincon's HonorBounds option, and the fmincon name
% is accepted by mapOptions.
opts.HonorBounds = true;

% --- Automatic finite-difference step calibration (ON by default) ---
% The default step sqrt(eps) assumes the objective/constraints are evaluated to
% machine precision.  Simulation-based problems (ODE integration, iterative
% solvers) have a much larger noise floor eps_f; with the tiny default step the
% differencing error eps_f/h then dominates the gradient and stalls the solver
% at a noisy-optimality plateau.  When autoFDStep is true, solve measures a
% V-curve of the finite-difference error versus step at x0 (see
% Evaluator.calibrateStep) and sets FiniteDifferenceStepSize and
% FiniteDifferenceType to the bottom of that curve, overriding the two options
% above.  The error is measured RELATIVE to a Richardson reference, so the choice
% is invariant to how the problem is scaled (raw or pre-normalised).  Blocks that
% supply analytic derivatives are skipped, and forward differences are kept
% (rather than promoting to central) whenever they already meet optTol.
opts.autoFDStep = true;   % calibrate the FD step/type from a V-curve at x0

% --- Termination tolerances ---
opts.optTol   = 1e-6;   % stationarity (first-order optimality)
opts.feasTol  = 1e-6;   % primal feasibility (equality + inequality + bounds)
opts.compTol  = [];     % complementarity; [] ties it to optTol in solve (see there)
opts.stepTol  = 1e-12;  % minimum step norm before restoration/stall
opts.maxIter  = 300;
opts.maxFunEvals = 1e5;
opts.maxTime  = Inf;    % seconds

% --- Objective-plateau termination (ON by default; see terminationCheck/solve) ---
% A secondary convergence signal for the SQP/interior endgame.  On stiff problems
% with a nearly flat objective direction near the solution (e.g. a free-final-time
% transcription: the thrust-effort objective is almost independent of TOF at the
% optimum, so its costate has a tiny gradient and relaxes only in slow BFGS
% steps), the standard test can spend hundreds of iterations grinding the
% stationarity residual down to optTol while the objective no longer moves.  When
% the objective has been flat (relative change <= objPlateauFtol) for
% objPlateauWindow consecutive iterations AND the point is fully feasible
% (feas<=feasTol) and complementary (comp<=compTol) AND stationarity is already
% within objPlateauOptTol, declare convergence with exitflag 2.  Set
% objPlateauWindow=Inf to disable.
%
% objPlateauOptTol WAS 1e-4 (100x optTol), and that was measured to be wrong.
% The claim it rested on -- "the objective no longer moves, so the tail is pure
% wasted precision on an already-converged point" -- was checked directly on
% orbitRaiseTest by disabling ONLY this exit (objPlateauWindow=Inf, maxIter 2000)
% and letting the same solve run to completion.  It reached exitflag 1 at
% iteration 1006 (opt 9.26e-07, feas 7.83e-10).  Against that reference point the
% old setting exited at iteration 592 having stopped
%     1.5479e-04 ABOVE the true optimum  (1.26e-03 relative, f agreeing to only
%     two significant figures), with opt 8.18e-05 = 82x optTol.
% So the objective was still genuinely descending, and the exit was a loosened
% tolerance after all -- precisely what the guards were supposed to prevent.  The
% mechanism: objPlateauFtol gates the PER-ITERATION change, so a drift of ~1e-6
% per step never resets the counter yet accumulates to 1.26e-03 over 414
% iterations.  Tightening this tolerance is what bounds the resulting objective
% error, and the two track each other closely -- measured |f - f*| at the first
% eligible iterate: 1e-4 -> 3.1e-04, 1e-5 -> 1.6e-04, 3e-6 -> 5.0e-07,
% 2e-6 -> 1.0e-07.
%
% Two rules were tried first and REFUTED against this run's trace; do not
% re-propose them without new evidence:
%   - cumulative-drift window (anchor f at the window start instead of testing
%     per-iteration change): fires at iteration 364, the SAME iteration as the
%     current rule, because the drift comes in occasional jumps rather than
%     spread evenly across the window.
%   - trailing log10(opt) slope: cannot separate the cases.  The false exit at
%     592 has slope +0.0277 decades/iter and the genuinely converged point at
%     1006 has +0.0236 -- indistinguishable, because opt oscillates in a band
%     here rather than descending monotonically.
% Bounding the stationarity gate is necessary but was measured NOT to be
% sufficient.  Re-running orbitRaiseTest at 3e-6 with the exit ON still reported
% exitflag 2, at iteration 815 -- and the trace shows why chasing the number
% lower is the wrong move.  Over iterations 800..1005 opt does not sit on a
% plateau at all: it OSCILLATES across 1.06e-06 .. 2.67e-04 (median 1.22e-05).
% Iteration 815 is a downward SPIKE (3.61e-05 at 810 -> 2.14e-06 at 815 ->
% 6.23e-06 at 820), and the run went on to reach exitflag 1 at 1006.  Because the
% gate must be looser than optTol to mean anything, some spike will always dip
% under it first, so any fixed threshold preempts exitflag 1 on an oscillating
% endgame.
%
% The flat-objective guard cannot compensate, and the trace says so
% quantitatively: 95% of iterations past 300 satisfy |df|/max(1,|f|) <= 1e-5.
% That is structural, not a bad tolerance -- f is quadratically flat near a
% minimizer while opt is only linearly small, so in ANY endgame the f-test is
% nearly always true and the rule degenerates to "opt <= objPlateauOptTol".
%
% objPlateauOptWindow fixes that by requiring the stationarity gate to be
% SUSTAINED for consecutive iterations rather than touched once.  On this trace
% the longest run of consecutive iterations under 3e-6 before convergence is 4,
% so any window >= 5 blocks every false exit while the genuine plateau the exit
% exists for -- where opt is flat, not spiking -- still satisfies it easily.
% Default 10 sits 2x above the measured 4 and well below the ~40-iteration
% plateaus the exit is meant to catch.
%
% A no-new-best-opt stall counter (mirroring feasStallCount) was also simulated
% and works only at window >= 60 against a max observed stall of 83 -- too close
% to the data to be anything but a curve fit.  The sustained-gate rule has a
% mechanism behind it, so prefer it.
opts.objPlateauWindow = 40;     % consecutive flat-objective iters required
opts.objPlateauFtol   = 1e-5;   % "flat" = |df| <= this * max(1,|f|)
opts.objPlateauOptTol = 3e-6;   % stationarity gate for the plateau exit (3x optTol)
opts.objPlateauOptWindow = 10;  % consecutive iters the gate must hold (1 = touch once)

% --- Hessian model ---
% 'exact' (finite-difference Hessian of the Lagrangian, or opts.HessianFcn)
% is the default: it converges quadratically and certifies the tight KKT
% tolerances on small/medium problems.  The two secant models are distinct:
%
%   'lbfgs' stores lbfgsMemory recent pairs and rebuilds B from the compact
%           representation on every call -- O(n^2*k) per iteration, with
%           curvature known only in the span of the stored pairs.  Use it when
%           n is large enough that a dense n-by-n B is not affordable.
%   'bfgs'  maintains a FULL dense n-by-n B by the rank-2 BFGS update: a fixed
%           O(n^2) per iteration however long the solve runs, curvature
%           accumulated in every direction ever sampled, and getMatrix is O(1).
%           opts.lbfgsMemory is IGNORED.  Prefer it whenever a dense n-by-n
%           matrix fits, which the direct KKT solve implies anyway since that
%           forms a dense (n+mE)-by-(n+mE) system.
%
% Both converge superlinearly and may stall just above optTol on hard problems.
opts.hessianApprox = 'bfgs';  % 'exact' | 'fd' | 'lbfgs' | 'bfgs'

% Ceiling on the one-shot B0 scaling, relative to the curvature actually
% sampled by the first pair: gamma0 <= bfgsGammaCurvCap*(s'y)/(s's).  See
% BFGSHessian.m for why the cap exists at all -- an uncapped gamma0 pinned at
% gammaMax produced a limit cycle, because gamma0 is PERMANENT and survives in
% every direction the secant pairs never sample.
%
% The default is the class default, so this option changes nothing until it is
% set.  It is exposed because it was previously reachable only by editing the
% class: on a problem with a wide equality nullspace (orbit N=50: 148 of 457
% dimensions) the tangential block of B measures ~4.24e+02 against a true
% tangential curvature of ~4.96e-02, and the cap was for a while the only lever
% on it.  The cap is a workaround -- it can only make the FIRST pair's estimate
% less wrong, and the first pair is measured in a regime the run leaves.  It is
% also sharp in the wrong direction: a sweep on the orbit problem improved
% steadily down to cap = 1e2 and then diverged outright at cap = 3 (feasibility
% 4.6e+02 by iteration 16) when gamma0 fell just below the true maximum
% tangential curvature.  bfgsB0Refresh below addresses the same defect at its
% source and is the preferred lever.
opts.bfgsGammaCurvCap = 1e4;

% Curvature-regime rebasing of B0 (full BFGS only; 'lbfgs' already refreshes its
% scale every update and does not have this defect).
%
% gamma0 is measured once, from the first secant pair, and rank-2 updates leave
% it untouched in every direction the run never samples.  On a long solve that
% is a scale from a regime that no longer exists: on orbit N=50 the first pair
% is taken at mu = 1e-1 and the run then spends ~110 iterations at mu = 1.8e-6,
% where gamma0 sits 8543x above the true tangential curvature.  Measured on a
% plateau iterate, the accumulated model recovered 0.03% of the attainable
% quadratic decrease while pointing within 22 degrees of the true step -- the
% direction was right and the step was ~7600x too short.
%
% When enabled, a rolling geometric median of the sampled curvature (s'y)/(s's)
% is compared against the live scale, and B is re-centred on the median when
% they diverge by more than bfgsB0RefreshFactor.  Replayed against a recorded
% 40-pair plateau trace this fires three times and walks the scale to 1.45x the
% true curvature.  See BFGSHessian.b0RefreshCheck for why the trigger is not
% keyed off a barrier decrease (mu freezes before the drift gets bad) and why
% the rebase discards B rather than correcting its spectrum.
%
% A rebase discards the accumulated curvature, so it must not fire on a model
% that is already working.  bfgsB0RefreshMinLearned blocks it once the pairs
% learned since the last rebase exceed that fraction of n, on the reasoning that
% rank(B - gammaBase*I) <= 2*sinceRebase bounds what the discard costs.  A
% same-session A/B with this option defaulted ON and NO gate measured the damage:
% a 20-variable problem converging superlinearly (ef=1, 34 iterations, opt
% 3.8e-07) rebased at 22 pairs = 1.10*n and finished ef=2 at 70 iterations with
% opt 8.5e-05 -- the same minimiser to 3e-07, at twice the cost.  Every orbit
% rebase, by contrast, lands at 0.018-0.033*n.  The default 0.20 blocks the
% former with 2x margin and allows the latter with 6x.  Gating on optimality
% progress instead was tried in three forms and none separates the two cases;
% see BFGSHessian.b0RefreshCheck for the measurements.
%
% ON by default as of 2026-08-12, after the gate above made it safe and a
% 1000-iteration A\B\C on the real orbit-raising harness (N=50, nz=457) measured
% what it is worth.  All three arms ran from one call, same session, same code:
%
%   arm                        ef   iters   f          opt        feas       rebases
%   refresh OFF                -2     899   2.189e-01  6.82e-01   5.51e-02         0
%   refresh ON, gate disabled   2     592   1.177e-01  1.43e-05   4.86e-07        39
%   refresh ON, gate at 0.20    2     592   1.177e-01  1.43e-05   4.86e-07        39
%
% OFF does not merely converge more slowly -- it FAILS: "no feasible point found
% (local infeasibility)".  It was healthy through iteration 700 (feas 2.7e-07),
% then feasibility collapsed five orders to 4.3e-02 between 700 and 750, opt
% spiked to 1.94e+02 by 850, and it stalled on 4.7e-06 steps with 44 of 457
% variables at a bound.  Both ON arms converged at iteration 592 to a feasible,
% complementary point with a 46% better objective.  There is no wall-clock cost:
% all three arms took ~2570 s, the ON arms having stopped at 592 iterations while
% OFF burned 899 failing.
%
% The two ON arms are BIT-IDENTICAL -- same 39 rebases, same f to the last digit
% -- which is the measurement that says the gate is inert on a wide problem: at
% n = 457 it cannot engage until 92 pairs since a rebase, and every rebase here
% landed far below that.  So the gate buys the 20-variable case above without
% costing the case this feature exists for.
%
% Set false to recover the pre-2026-08-12 behaviour.  Worth trying if a solve
% regresses in a way that correlates with a nonzero rebase count (out.hessianModel
% .nRebases), though the gate is designed to make that unlikely on large problems.
opts.bfgsB0Refresh           = true;
opts.bfgsB0RefreshWindow     = 8;    % pairs in the rolling geometric median
opts.bfgsB0RefreshFactor     = 3;    % drift ratio from the live scale that fires
opts.bfgsB0RefreshRefractory = 5;    % minimum pairs between two rebases
opts.bfgsB0RefreshMaxDrop    = 100;  % largest single-rebase reduction in scale
opts.bfgsB0RefreshMinLearned = 0.20; % block a rebase past this fraction of n learned

% bfgsResetMaxDrop bounds the OTHER path that flattens B to a scaled identity:
% the conditioning-fault reset (BFGSHessian.resetToScaled), which fires when B
% goes non-SPD or exceeds condMax.  bfgsB0RefreshMaxDrop above guards the
% deliberate rebase because too soft a B0 gives too long a step; the fault path
% was unguarded, taking a SINGLE unfiltered gammaLast floored only at gammaMin
% (1e-8), even though it fires exactly when the curvature sample is least
% trustworthy.  On the 2002-iteration orbit run all 57 resets landed on a
% condB = Inf iteration, 24 cut gammaBase by more than 100x (max 1.57e+05), and
% those 24 were followed by normDx median 4.83e+01 with aP < 1e-3 on 100% of
% iterations, against 9.52e-03 and 39% for the 33 bounded ones.
%
% DEFAULT inf = the historical behaviour, bit-for-bit.  The evidence above is
% correlational and cannot distinguish "the unbounded drop causes the long step"
% from "genuinely tiny curvature causes both", so the value is left to an A/B
% rather than assumed.  Set 100 to mirror bfgsB0RefreshMaxDrop.
opts.bfgsResetMaxDrop        = inf;

% bfgsCondMax is the conditioning ceiling that triggers that same fault reset.
% DEFAULT 1e12 = the historical BFGSHessian.condMax, unchanged; this option only
% makes the property reachable, which it previously was not.
%
% THE CEILING NEVER FIRES AT ITS DEFAULT.  Over the 2002-iteration orbit run it
% fired ZERO times: max finite condB was 1.193e+11 and p95 was 6.98e+07, so all
% 57 resets came from the OTHER branch, chol failing, i.e. loss of positive
% definiteness at cond ~ 5e7 -- four orders below the guard meant to catch a
% degrading B.  Read condB = Inf as "indefinite", never as "ill-conditioned".
%
% The degradation is progressive and visible in advance, median log10(condB)
% into a fault running 4.66 (k-10) -> 5.36 (k-3) -> 6.37 (k-2) -> 7.68 (k-1)
% against a 2.91 baseline, so a lower ceiling is a usable early trigger:
% 1e7 would pre-empt 74.6% of the faults and 1e6 88.9%.
%
% DO NOT LOWER THIS ALONE.  An early reset still takes one unfiltered gammaLast,
% and at condB > 1e7 that drop has p90 1.55e+04 and max 1.43e+05 with 39.3%
% exceeding 100x.  Firing more resets without a finite bfgsResetMaxDrop just buys
% more of the pathology the option above exists to bound.
opts.bfgsCondMax             = 1e12;
opts.lbfgsMemory   = 10;       % 'lbfgs' only; ignored by 'bfgs'

% --- Linear algebra ---
opts.linearSolver = 'direct';  % 'direct' | 'krylov' | 'auto'
opts.krylovMethod = 'minres';  % 'minres' | 'gmres'
opts.krylovAutoDim = 500;      % 'auto' switches to krylov when n+mE exceeds this
opts.krylovMaxIter = [];       % [] -> problem-size default inside the solver
opts.forcingEtaMax = 0.9;      % inexact-Newton forcing sequence upper clamp
opts.forcingEtaMin = 1e-8;     % forcing sequence lower clamp
opts.forcingGamma  = 1.0;      % Eisenstat-Walker choice-2 coefficient
opts.forcingAlpha  = 1.618;    % Eisenstat-Walker choice-2 exponent
opts.precondition  = 'jacobi'; % 'none' | 'jacobi' preconditioner for krylov

% --- Automatic problem scaling (ON by default) ---
% Poorly scaled problems are the single most common cause of a "stuck" solve:
% when variables/constraints span many orders of magnitude the KKT residual is
% dominated by the large blocks, so the barrier-update gate  Emu <= kappaMu*mu
% never fires and mu (hence the whole central-path march) freezes.  To avoid
% forcing users to hand-normalise their problem (units, residual weights, etc.),
% the solver measures scale factors once at x0 and runs internally in a scaled
% space, transforming every input (x0, bounds, linear rows, objective and
% constraint handles) and unscaling every output (x, fval, grad, hessian,
% multipliers) transparently.  Modes:
%   'gradient' - (default) variable scaling from bounds/x0 magnitude, plus
%                constraint-row scaling from the Jacobian probed at x0
%                (IPOPT-style gradient-based row scaling). The objective is left
%                unscaled so the reported optimality stays in its own units.
%   'curvature' - 'gradient' plus a curvature-based objective scale: the
%                objective's diagonal Hessian is probed once at x0 (2n central
%                second differences) and wf caps the scaled objective curvature
%                at autoScaleCurvGate per constraint, so a curvature-dominated
%                objective cannot collapse the reduced dual system
%                S = JEs*Ws^{-1}*JEs' toward zero (dual-step divergence).
%                Never magnifies, and is inert -- exactly wf = 1, identical to
%                'gradient' -- whenever the problem is unconstrained, larger
%                than autoScaleCurvProbeMaxDim, or already well-balanced.
%   'bounds'   - variable scaling only (from bounds/x0); no derivative probe.
%   'none'     - disable scaling entirely (bit-for-bit legacy behaviour).
opts.autoScale = 'gradient';  % 'gradient' | 'curvature' | 'bounds' | 'none'

% Largest permitted spread max(Dx)/min(Dx) in the variable scaling.
%
% Dx is taken from the bound range, which measures how WIDE a variable's box is
% -- not how CURVED the objective is along it.  Those coincide often enough for
% the rule to be a good default, but when they diverge the scaling actively
% harms the solve: the transform x = Dx.*xs maps the Hessian to Dx.*H.*Dx', so a
% spread of s in Dx multiplies the condition number by up to s^2.  On a box like
% lb=[0;0], ub=[1e6;1e-2] the raw spread is 1e8, and a perfectly conditioned
% H = 2*I (cond 1) is mapped to cond 1e16 -- numerically singular.  The Newton
% step in the narrow variable then underflows relative to the wide one and the
% iteration stalls at a non-stationary point, so 'gradient'/'bounds' converge to
% a WORSE answer than 'none' on precisely the badly-scaled problems the feature
% exists to fix.
%
% Capping the spread keeps the useful part of the rule (variables are brought
% into a common range, which is what unfreezes the barrier march) while bounding
% the conditioning damage at cap^2.  The cap is applied geometrically about the
% geometric mean of Dx, so no variable is singled out and the compression is
% symmetric in log-space.  1e4 bounds the induced conditioning at 1e8 -- still
% well inside double precision -- and leaves every previously-passing case
% unchanged, since their raw spreads are already below it.  Set Inf to restore
% the uncapped bound-range rule.
opts.autoScaleMaxSpread = 1e4;

% Per-constraint cap on the scaled objective curvature in 'curvature' mode.
%
% The objective-scale rule (see COMPUTESCALING/CURVATUREOBJSCALE) caps the
% largest diagonal entry of the variable-scaled Hessian Dx.*H(x0).*Dx' at
% autoScaleCurvGate*max(1,mE+mI). The cap is what makes the probe safe: a
% curvature below it is left untouched (wf = 1, so well-scaled problems are
% bit-identical to 'gradient'), and the noise floor of second differences on
% noisy objectives (which bias LOW, not high) stays far below it. Set Inf to
% disable the objective leg entirely (equivalent to 'gradient').
opts.autoScaleCurvGate = 1e4;

% Largest problem size (n) for which 'curvature' mode runs the curvature probe.
%
% The probe costs 2n extra objective evaluations at x0 (two per variable), so
% it is skipped above this dimension and the mode degrades gracefully to
% 'gradient' (wf = 1).
opts.autoScaleCurvProbeMaxDim = 400;

% --- Globalization ---
opts.globalization = 'filter'; % 'filter' | 'merit'

% Constraint-violation growth veto for the filter line search.  The
% Waechter-Biegler theta-type acceptance rule takes a trial when EITHER
% feasibility improves OR the objective improves by gammaPhi*theta0.  With
% gammaPhi = 1e-5 and a small theta0 the second disjunct degenerates: at
% theta0 = 5.26e-4 it reads phiT <= phi0 - 5.3e-9, so an infinitesimal objective
% decrease buys an UNBOUNDED feasibility increase.  On the N=50 orbit case that
% accepted a single step taking feas 5.26e-4 -> 4.26 (four orders) for an f drop
% of 0.0066, and the solver then spent every subsequent iteration happily
% minimizing f from a grossly infeasible point -- it could never recover, because
% each new iterate still beat the stored filter entries on phi.  Cap how far a
% single accepted step may raise theta; backtracking simply continues past a
% vetoed trial.  The floor at feasTol keeps the cap from becoming vanishingly
% tight as theta0 -> 0 near a feasible solution (a step from theta0 = 1e-12 must
% still be allowed to move).
%
% 100 is deliberately loose.  This is a blow-up guard, not a feasibility policy:
% the filter itself already prices ordinary theta increases, and a healthy solve
% routinely takes a step that worsens theta by a modest factor on its way to a
% better objective.  Tightening to 10 vetoed exactly such a benign trial on the
% 20-variable L-BFGS reference (costing a backtrack for no gain), while the orbit
% blow-up this guard exists to stop grew theta by 8090x -- so 100 still rejects it
% with ~80x of margin.  Set kappaThetaGrow = Inf to disable.
opts.kappaThetaGrow = 100;     % veto trials with theta > this * max(theta0, feasTol)

% --- Divergence guard ---
% terminationCheck previously had no way to stop a diverged run: its only exits
% are KKT convergence, the objective plateau, maxIter, and maxFunEvals.  When the
% orbit solve blew up at iteration 676 it was configured with maxIter = 10000 and
% maxFunEvals = Inf, so ~9300 further iterations of infeasible descent were queued
% and the run had to be killed by hand.  Stop instead once feasibility has stayed
% divergeFactor times worse than the best feasibility ever achieved for
% divergeWindow consecutive iterations, and return the best iterate seen rather
% than the diverged one.  Both thresholds are deliberately loose -- this is a
% blow-up detector, not a progress test, and a solver legitimately working its way
% back down from a bad patch must not trip it.  Set divergeWindow = Inf to disable.
%
% DISABLED BY DEFAULT (divergeWindow = Inf).  Even at factor 1e3 / window 5 the
% test proved to be a false-positive machine on healthy runs: a solve sitting at
% feas = 1e-6 that takes an ordinary excursion to 5e-3 is already 5000x above its
% own best, and five such iterations in a row is not a blow-up -- it is a normal
% endgame wobble on an ill-conditioned problem.  The bestFeas-relative threshold
% has no floor other than feasTol, so the better a run does the more easily it
% trips, which is exactly backwards.  The whole mechanism is retained (the
% feasRegressCount tracker still runs and is still logged in the trace, the
% exit still lives in terminationCheck, the best-iterate rollback is unchanged)
% -- set divergeWindow to a finite value, e.g. 5, to arm it for a run that really
% is running away.  Note that the non-finite (NaN/Inf) exit in terminationCheck is
% a separate guard and remains active, as does the kappaThetaGrow line-search
% veto above, which bounds a single step rather than terminating the solve.
opts.divergeFactor = 1e3;      % feas > this * max(bestFeas, feasTol) counts as regressed
opts.divergeWindow = Inf;      % consecutive regressed iters before declaring divergence (Inf = off)

% --- Which iterate to return on a limit exit ---
% 'last'    - return the iterate the loop ended on (DEFAULT).
% 'bestKKT' - return the feasible iterate with the smallest scaled stationarity
%             seen during the run, when that is strictly better than the last one.
%
% Only limit exits (exitflag 0: maxIter, maxFunEvals, maxTime) are affected.  A
% convergence exit (1 or 2) always returns its final iterate -- that point is the
% answer by definition, and rolling back would contradict the test that just
% fired.  The divergence/non-finite exit (-3) always rolls back to the most
% feasible iterate seen regardless of this option: that rollback ranks on
% feasibility, not stationarity, and exists so a blown-up run hands back
% something usable rather than a diverged point.
%
% 'bestKKT' is worth setting on an oscillating run, where the endpoint of a
% capped solve is an arbitrary sample of a wandering sequence: on the orbit
% proxy the solver reaches scaled opt = 4.6e-04 at a feasible iterate around
% iteration 81 and has drifted back to 1.6e-03 by the cap, so the last iterate
% discards a strictly better answer the run already found (up to 2.06x on that
% case).  'last' is the default because it is what the caller asked for -- the
% state after N iterations -- and because it keeps the returned point, the final
% trace row, and any warm-start continuation describing the same iterate.
opts.returnIterate = 'last';   % 'last' | 'bestKKT'

% --- Barrier / interior-point schedule ---
opts.mu0     = 0.1;
opts.muMin   = [];     % default tied to optTol in solve (0.1*optTol)
opts.muGamma = 0.2;    % linear reduction factor
opts.muBeta  = 1.5;    % superlinear exponent: mu^(1+beta)
opts.kappaMu = 10;     % reduce mu when kkt_mu <= kappaMu*mu
opts.tau     = 0.995;  % fraction-to-boundary base

% --- Trust region ---
opts.delta0   = 1.0;
opts.deltaMax = 1e6;
opts.trEta1   = 0.1;    % accept step when actual/predicted reduction exceeds this
opts.trEta2   = 0.75;   % expand radius above this ratio (on a boundary step)
opts.trShrink = 0.25;   % radius shrink factor on rejection
opts.trExpand = 2.0;    % radius growth factor on a very good step

% --- Adaptive extensions ---
opts.modeSwitch             = true;   % Level-1 adaptive control (Stage 9); ON by default
opts.modeSwitchStagnWindow  = 5;      % consecutive iters to detect theta stagnation
opts.enableRestoration      = true;   % feasibility restoration (Stage 5)
opts.restStallWindow        = 5;      % consecutive feas-stall iters before a bare
                                      % line-search collapse (aP<=1e-10) is allowed
                                      % to trigger restoration / a local-infeasibility
                                      % exit (see solve: restoration trigger)
opts.parallel               = 'off';  % 'off' | 'finitediff' | 'async' (Stage 10)

% --- Automatic barrier-stall detection (ON by default; see solve) ---
% The barrier parameter mu only shrinks once the mu-perturbed KKT error Emu falls
% within kappaMu*mu.  On a stiff/poorly-costated problem Emu is chronically
% dominated by the stationarity block (lagging equality multipliers) that mu
% cannot reduce, so the gate never fires and the whole central-path march freezes
% at mu0 -- the failure that previously forced users to hand-tune kappaMu upward.
% solve detects this structurally each iteration: when complementarity AND
% feasibility are already within the standard gate but the stationarity block
% ||rd|| is not, it is a mu-curable structural stall (reducing mu lets throttled
% bound duals grow toward their true active multipliers, clearing ||rd||).  solve
% then widens kappaMu by exactly the factor that releases the gate this iteration
% (||rd||/(kappaMu*mu)), capped by barrierStallFactor.  A far-from-solution
% nonconvex iterate has large feasibility, so the discriminator fails and mu is
% left high to keep globalizing; on a well-conditioned problem all blocks fall
% together and this never triggers.  Active regardless of modeSwitch.  The cap
% must stay modest: it is NOT free headroom.  Releasing the gate drops mu one
% superlinear step, but doing so before the throttled duals have actually caught
% up pushes the iterate off the central path -- on HS37 a cap of 1000 lets the
% override collapse mu prematurely and strands opt at ~6e-4 (400 iters, ef=0),
% whereas a cap of 10 converges in 78 iters (opt 1e-7).  So 10 is the largest
% cap that does not regress the HS set (problems with active inequality or bound
% complementarity, where a premature mu drop starves s.*lamI = mu before the
% active duals have grown).
opts.barrierStallFactor = 10;   % CAP on the auto-computed effective-kappaMu widening

% There is deliberately NO option here that forces mu down when the gate above
% holds it still for a long stretch.  It is tempting to add one: on the N=50 orbit
% case mu pinned at 1.845e-6 for 641 consecutive iterations while f crawled at
% 1.5e-4 per iteration, which reads exactly like a barrier that has seized.  It is
% not.  Warm-starting that case from its own plateau and re-solving under
% kappaMu = 1e3 and 1e6 (both of which widen the gate directly),
% barrierStallFactor = 1e4, and muMin = 1e-12 moves opt after 60 iterations only
% between 1.25e-3 and 2.6e-3, against 1.61e-3 for the default -- and the most
% aggressive setting is the worst of the five (muMin=1e-12: opt 2.6e-3, feas
% 3.1e-5, 2.4x the wall time).  During the freeze statErr/gateBase measures
% 150-900x, so the gate is behaving correctly: it declines to advance the central
% path while stationarity is still three orders from converged.  The frozen mu is
% a SYMPTOM of that plateau, not its cause, and forcing mu down only pushes the
% iterate off the central path.  Fix the plateau where it lives (the near-singular
% Schur conditioning wall), not at the barrier.
%
% Feasibility admission for the stall detector.  The detector requires
% feasibility to be "already within the standard gate" before it will blame the
% stall on mu, but testing feasErr <= kappaMu*mu makes that admission tighten in
% lockstep with mu.  At mu = 1.845e-6 the test demanded feas <= 1.84e-5 -- and it
% excluded 131 of 569 logged iterations that were otherwise perfectly valid
% structural stalls (402 admitted; 516 with this relaxation).  Floor the admission
% at a fixed multiple of feasTol so it stops chasing mu downward.  100*feasTol
% matches the threshold the mode controller already uses to declare 'feasibility'
% mode (control_modeController R1), so the two agree on what "feasibility is under
% control" means.
opts.feasAdmitFactor = 100;     % stall admission floor: feasErr <= max(gateBase, this*feasTol)

% --- Dual-step stabilization (ON by default; see kkt_inertiaCorrection/solve) ---
% On stiff multiple-shooting / adjoint problems the range-space elimination that
% condenses the KKT system onto the equality multipliers forms the Schur
% complement  S = JE*W^{-1}*JE'.  This SQUARES the conditioning of JE, so a
% merely ill-conditioned equality Jacobian (cond ~1e3-1e4) produces a genuinely
% near-singular S (cond ~1e7-1e10, smallest singular value ~1e-13) even though JE
% itself is full row rank.  The dual step dlamE = S^{-1}*rpE then blows up along
% S's near-null direction (observed norms ~1e4-1e5 on the orbit endgame),
% wrecking the equality multipliers and driving the iterate into restoration /
% local-infeasibility.  Two cooperating safeguards tame this:
%
%   Fix A (dualCondMax) -- scale-aware dual regularization.  When the reduced
%   dual system is ill-conditioned, kkt_inertiaCorrection adds gamma_d*I to the
%   dual block sized in ONE shot to bound cond(S+gamma_d*I) at dualCondMax
%   (gamma_d ~= sigma_max(S)/dualCondMax), rather than the all-or-nothing pivot
%   trigger that cannot see the Schur singularity through K's large primal
%   pivots.  This keeps the FACTORIZATION numerically honest; it perturbs the
%   feasibility row only by a bounded O(gamma_d*dlamE).  Inert on well-
%   conditioned S (gamma_d ~ 0).  Set dualCondMax = inf to disable Fix A.
%
%   Fix B (dualStepMax) -- dual step-size safeguard (the load-bearing bound).
%   The equality-multiplier increment (aD*dlamE) is capped so no single step can
%   grow ||lamE|| by more than dualStepMax times its current scale
%   max(1,||lamE||).  This is a dual trust region: scale-relative (no magic
%   tolerance), inert near the solution where dlamE -> 0, and it bounds the
%   multiplier blowup even in the residual direction that no finite dual
%   regularization can fully remove.  Set dualStepMax = inf to disable Fix B.
%
% dualCondProbeMaxDim caps the cost of Fix A's conditioning probe: forming S and
% estimating sigma_max/sigma_min is O(mE^2*n); above this equality-count the
% probe is skipped and Fix A falls back to the median-relative pivot gate alone
% (Fix B still applies).  The orbit tests run at mE=45 (N=6) to mE~300 (N=50).
% dualStepMax is O(1), not large: a healthy dual Newton step has
% ||dlamE|| <~ ||lamE|| (the correction is a modest fraction of the current
% multiplier), so the ratio ||dlamE||/max(1,||lamE||) is < 1 near a good step and
% the cap is inert.  The Schur-singularity blowups sit at ratio 1e2-1e4, so a cap
% of 10 cleanly separates them: it never touches a legitimate step yet refuses
% any single step that would grow the equality multipliers by more than 10x their
% current scale.  A looser cap (1e2) lets lamE random-walk upward across
% iterations -- the multipliers keep drifting and opt keeps spiking even though
% each individual step "looks" bounded -- so the ceiling must be tight.  Note the
% cond-based dual regularization (Fix A) CANNOT substitute for this: when
% sigma_max(S) is itself tiny (~1e-2 on the orbit endgame), no bound on cond(S)
% bounds ||S^{-1}*rpE||, so the magnitude cap is the load-bearing safeguard.
opts.dualStepMax        = 10;    % Fix B: max ||aD*dlamE|| / max(1,||lamE||) per step
opts.dualCondMax        = 1e8;   % Fix A: target ceiling on cond(S) after dual reg
opts.dualCondProbeMaxDim = 400;  % skip Fix A's Schur probe when mE exceeds this

% --- Normal/tangential step decomposition + trust-region (Gap 1+2) ---
opts.useNTdecomp  = false;  % false = existing KKT+linesearch; true = NT+TR inner loop
opts.trMaxInner   = 20;     % max trust-region inner iterations before fallback to linesearch

% --- Second-order correction (Waechter-Biegler) for the filter line search ---
% On strongly nonlinear constraints the full KKT step is rejected because
% constraint curvature raises theta (Maratos effect), collapsing the step to
% amin.  When the accepted step falls below socThreshold*aMax, retry with a
% corrected direction that also cancels the constraint value at the full trial
% point (re-solving the condensed KKT system with RHS c_soc = alpha*c + c(x+ad)).
opts.useSOC       = true;   % enable second-order correction in the IP filter line search
opts.socMax       = 4;      % max successive SOC re-solves per iteration
opts.socThreshold = 0.1;    % trigger SOC when linesearch alpha < socThreshold * aMax

% --- Least-squares equality-multiplier refresh ---
% Near the central-path floor the Newton-accumulated equality multipliers
% (costates) can lag the moving primal iterate, leaving the dual infeasibility
% dominated by (JE'*lamE) in the variable blocks the objective does not touch.
% When enabled, lamE is re-estimated each iteration as the least-squares
% multipliers that best cancel the current reduced gradient (holding bound and
% inequality multipliers fixed), adopted only if it does not raise opt.  Cheap
% and stabilising when JE is full row rank; leave off for ill-conditioned JE.
% Gate: fire only when the dual residual dominates primal feasibility
% (opt > lsRefreshDomRatio*feas) -- i.e. a costate-lag stall is what holds the
% KKT residual up.  This replaces an earlier absolute feasibility threshold
% (lsRefreshFeasTol) that could deadlock: the refresh could not fire until feas
% fell below the threshold, but with frozen costates opt stayed large so the
% barrier stayed high and the solver never drove feas low enough to unlock it.
% The dominance test is scale-relative (no magic tolerance) and stays quiet
% during a genuine feasibility drive (feas dominates), protecting the secant.
opts.lsMultiplierRefresh = true;   % ON by default (dominance-gated; see below)
opts.lsRefreshDomRatio   = 10;     % refresh when opt > this * feas (costate-lag stall)
opts.lsRefreshFeasTol    = 1e-3;   % legacy; no longer the primary gate

% Adoption DEADBAND (P3): the re-fit must beat the current weighted dual
% infeasibility by at least lsRefreshDeadband (a factor < 1).  Without it, any
% noise-level dip -- however tiny -- adopts and toggles lamE between two
% nearly-equal fits iteration to iteration.  In the low-feas endgame the
% dominance gate fires every iteration (opt > 10*feas is trivially true), so
% the deadband is what keeps the costates from jumping at the noise floor.
opts.lsRefreshDeadband = 0.9;     % adopt a re-fit only when it beats opt by this factor

% The costate least-squares fit  argmin ||optW.*(bLS + JE'*lamE)||  is itself
% ill-posed when JE is near-rank-deficient -- e.g. a stiff multiple-shooting
% adjoint, whose state-transition sensitivities over long segments make JE'
% near-singular even at full row rank.  The plain minimum-residual fit then loads
% enormous components onto JE's near-null right-singular directions: costates of
% norm 1e5-1e6 that contribute ~0 to JE'*lamE (so they do NOT lower opt) yet
% wreck a near-converged iterate (observed on the orbit endgame: a healthy
% ||lamE||~250 iterate is replaced by a ||lamE||~4e5 one, opt jumps 1e-3 -> 4.4,
% and restoration then reports local infeasibility).  Two cooperating safeguards
% keep the refresh honest (both ON; set to inf to disable):
%   dualFitCondMax -- truncated fit.  Solve the weighted LS via a minimum-norm
%     solve that discards singular directions below sigma_max/dualFitCondMax
%     (lsqminnorm tolerance).  This keeps the part of lamE that genuinely cancels
%     the reduced gradient (JE's well-conditioned range) and drops the near-null
%     part that only inflates ||lamE||.  Set just ABOVE the healthy cond(JE):
%     the orbit's JE rides at cond~4.6e3, so 1e4 admits the true range and cuts
%     the ~1e7-conditioned near-null tail.  On a well-conditioned JE every
%     direction survives and the fit is identical to the plain LS solve.  The
%     truncation protects a near-null TAIL, which only a large equality system
%     can have: below dualFitCondMinEq equalities the plain minimum-norm fit is
%     used instead.  On a small, ill-conditioned JE (e.g. the 3x3 Hohmann
%     costate fit at cond~4e6) sigma_max/dualFitCondMax keeps only the top
%     singular direction, the fit then needs enormous costates to cancel a
%     residual spread across the dropped directions, and the refresh ratchets
%     ||lamE|| 1e3 -> 2.4e6 with the solve failing ef=-2; the plain fit
%     converges there.  (Set to inf to disable truncation everywhere.)
%   dualFitGrowthMax -- adoption guard (backstop).  Even a truncated fit is
%     adopted only if it BOTH lowers the weighted dual infeasibility AND does not
%     grow ||lamE||_inf beyond dualFitGrowthMax*max(1,||lamE_prev||).  Scale-
%     relative; refuses any single refresh that would replace a modest costate
%     with a runaway one, independent of conditioning estimates.  It must be tight
%     because the blowup COMPOUNDS: the guard references the previous ||lamE||, so
%     a loose factor lets the costate ratchet up over several sub-cap steps until
%     it reaches 1e6-1e7 and corrupts the BFGS secant (lamE enters the Lagrangian
%     gradient), poisoning the Hessian and the primal step.  On the orbit endgame
%     legitimate costate growth during the feasibility drive is <=~7x per step,
%     while every toxic re-fit jumps >=25x, so a cap of 10 admits the real growth
%     and bites at the FIRST toxic step, stopping the ratchet before it starts.
opts.dualFitCondMax   = 1e4;   % truncate costate-fit singular values below smax/this
opts.dualFitCondMinEq = 8;     % min equalities before the truncated fit applies
opts.dualFitGrowthMax = 10;    % reject a refresh that grows ||lamE|| beyond this factor

% --- Active-bound row exclusion (Fix F; ON by default; set gap tol to 0 to disable) ---
% When a variable is pinned at a bound (a bang-bang/bang-off optimal control, e.g.
% a throttle coasting at 0), its stationarity row  g_i - zL_i + zU_i = 0  is
% satisfied by the BOUND multiplier, NOT the equality costate.  But as the gap
% x_i-lb_i collapses (observed to 1e-11 on the orbit throttle), the barrier bound
% dual zL_i = mu/(x_i-lb_i) lags its true active value, so that row carries a
% large residual.  Two places then mis-handle it:
%   (1) the costate least-squares refresh tries to cancel that residual with the
%       EQUALITY costate, which lives in JE's left-null space for that direction
%       -> lamE blows to 1e6 (proven: excluding the pinned row collapses the fit
%       residual 27 -> 1e-3 and the costate 3e6 -> 3e2 at every diverging iter);
%   (2) the reported opt = ||optW.*rd||_inf is dominated by that same lagging-dual
%       row, reporting O(1e3) dual infeasibility over a genuinely feasible,
%       active-bound KKT point (a metric artefact, not a real stationarity gap).
% Fix F excludes rows whose variable is within activeBoundGapTol (relative) of a
% bound from BOTH the refresh fit and the opt/stationarity metric.  It is inert on
% any variable not at a bound, so unconstrained / interior problems are untouched.
% terminationCheck still gates independently on feas AND comp, and at a genuine
% active bound (x-lb).*zL -> 0 automatically, so masking the row cannot cause a
% false convergence.
opts.activeBoundGapTol       = 1e-3;  % detection: var within this relative gap of a bound is "pinned" (0 disables Fix F)
opts.excludeActiveBoundRows  = true;  % Fix F: drop pinned-var rows from the costate fit & the opt/stationarity metric

% --- Degeneracy detection in main loop (Gap 3) ---
opts.enableDegeneracyDetection = false;  % call degeneracy_detectDegeneracy each iteration

% --- True mode switching (Gap 4; meaningful only with modeSwitch=true) ---
opts.modeNearBdryAugJE = false;  % promote high-confidence active inequalities to equalities in nearBoundary mode

% --- Broyden rank-1 Jacobian updates for expensive evaluations (Gap 5) ---
opts.enableBroyden    = false;  % use Broyden rank-1 updates between exact Jacobian refreshes
opts.broydenMaxStale  = 20;     % steps before mandatory exact Jacobian refresh
opts.broydenTol       = 0.1;    % Broyden model-error tolerance (triggers early refresh)
opts.costThreshold    = 0.1;    % seconds: avg FD Jacobian time before auto-enabling Broyden

% --- Per-iteration diagnostic trace ---
% output.trace is a struct-of-arrays with one row per iteration, recording the
% quantities the solver already computes internally and previously discarded:
% the exact singular values of the Schur complement S = JE*W^{-1}*JE' (computed
% every iteration by Fix A's probe and thrown away, so its trajectory had never
% been observed on any problem), the LDL' inertia and pivot spread, the
% inertia-correction retry count, the BFGS reset flag and condition estimate,
% the three optimality metrics side by side, and the step/multiplier
% magnitudes.  The trace is strictly OBSERVATIONAL -- nothing recorded is read
% back to make a solver decision -- so a run takes bit-identical steps at any
% trace level, a property tests/tIterTrace asserts on every run.
%
% Level 1 is ON by default because every quantity in it is a by-product that
% already exists; recording it is a struct read and an indexed assignment
% against an iteration costing 1.5 s (analytic Jacobian) to 20 s (finite
% differences).  Level 2 adds probes that genuinely cost something and is
% opt-in: a Lanczos/condest estimate of cond(K) via linalg_conditionEstimate.
%
% This does NOT replace the printed iteration table (that stays the human
% channel, and its column format is parsed by the existing probes) or
% output.hessianModel / output.diag (terminal snapshots).  The trace is the
% trajectory -- the machine channel that makes regex-parsing a log unnecessary.
opts.traceLevel   = 1;      % 0 = off | 1 = free quantities | 2 = + costly probes
opts.traceMaxRows = 20000;  % preallocation hint; the trace grows past it if needed

% warnOnSilentFailure surfaces conditions the solver currently absorbs without
% any signal: the inertia correction exhausting its 40 tries (which returns a
% step from a factorization that never reached the required inertia), MINRES
% failing to converge, and the BFGS conditioning recovery flattening B to a
% scaled identity.  Off by default and emitted at most once per solve per
% condition, because a long run would otherwise produce thousands of warnings.
% Note this does NOT re-enable MATLAB's near-singular/RCOND warnings, which stay
% suppressed -- tests/tDegeneracy converts those IDs to errors and asserts none
% escape a solve.  The continuous surrogates (trace.pivotSpread,
% trace.schurCond) carry that information instead, and carry more of it.
opts.warnOnSilentFailure = false;

% --- Plotting (OFF by default) ---
% Plot: built-in convergence plot on a uifigure with a 2x2 grid of uiaxes:
%   1) the variables per iteration, each scaled to its own [lb,ub] interval
%      (fraction between the bounds, with the interval drawn behind the bar;
%      unbounded or fixed variables are scaled to the range visited so far);
%   2) the UNSCALED constraint values (nonlinear c/ceq, linear rows, bounds);
%   3) the UNSCALED objective;
%   4) every convergence/exit criterion as a closeness bar against its
%      "satisfied" line (1.0), so one glance shows how close each quantity is
%      to passing its own test.
% The figure (Tag 'adamnlopt.plotIteration') is created on the first iteration,
% reused across solves, and each new solve resets its history.  Set true to
% enable; the plot draws through the same path as opts.PlotFcn below and never
% errors the solve (a plotting failure is reported once and then suppressed).
opts.Plot = false;

% PlotFcn: user-defined per-iteration plot callback ([] = off).
%   PlotFcn(info) is called at every iteration, including the terminal one,
%   with INFO a scalar struct of everything the solver knows at that iterate.
%   All quantities are UNSCALED and indexed over the ORIGINAL variables --
%   fixed variables (lb == ub) hold their fixed value -- so a callback can plot
%   or record without understanding the solver's internal scaling or reduction:
%     iteration / iter - 0-based iteration index.
%     funcCount        - cumulative objective evaluation count.
%     elapsed          - wall seconds since the first iteration.
%     x                - n-by-1 variables (unscaled, full problem).
%     fval             - scalar objective (unscaled).
%     grad             - n-by-1 objective gradient (unscaled; NaN on fixed
%                        rows with no analytic gradient).
%     c, ceq           - nonlinear inequality/equality values (unscaled).
%     linIneq, linEq   - linear inequality/equality residuals A*x-b, Aeq*x-beq.
%     boundLb, boundUb - distances to the finite bounds (x-lb, ub-x).
%     lb, ub           - the n-by-1 bound vectors (unscaled, full problem;
%                        -Inf/+Inf where unbounded).  The built-in plot
%                        scales every bounded variable to its [lb,ub]
%                        interval, so ranges of very different sizes stay
%                        comparable on one axis.
%     slacks           - inequality slacks s (empty without inequalities).
%     alpha            - last accepted primal step length.
%     mu               - barrier parameter (0 in the equality core).
%     stepsize         - physical-unit norm of the last accepted step.
%     constrviolation  - max constraint violation in the SOLVER's scaled space
%                        (the metric terminationCheck compares to feasTol).
%     constrviolationPhys - max |ceq|, max(0,c), |linEq|, max(0,linIneq) and
%                        bound distances in physical units.
%     firstorderopt    - scaled first-order optimality (termination metric).
%     optPrinted       - the optimality value printed in the iteration table.
%     complementarity  - scaled complementarity residual (termination metric).
%     x0               - initial point (unscaled, full problem).
%     mode             - solver mode label ('ip', 'eq', 'sqp', 'feas').
%     criteria         - struct array, one element per convergence/exit
%                        criterion, with fields:
%                          name      - criterion name.
%                          value     - current value of the measured quantity.
%                          limit     - the value at which it is "satisfied".
%                          kind      - 'below' (value <= limit) or 'above'.
%                          satisfied - logical.
%                          closeness - scalar in [0,1]: 1 = satisfied,
%                                      0 = nowhere near; NaN when the
%                                      quantity is not finite.  This is the
%                                      indicator the built-in plot draws.
%                          closenessLog - log-decade closeness in [0,1] for
%                                      the three KKT metric criteria (first-
%                                      order optimality, constraint violation,
%                                      complementarity): the fraction of the
%                                      way to the tolerance measured over 6
%                                      log10 decades, so a value two decades
%                                      above its tolerance reads 2/6 of the
%                                      way rather than the raw ratio.  NaN
%                                      for the counter criteria (plateau
%                                      windows, iterations, function
%                                      evaluations, wall time), whose linear
%                                      closeness is the meaningful one.
%     stop             - logical; true on the terminal iteration.
%     exitflag         - termination code on the terminal iteration (0 else).
%     message          - termination message on the terminal iteration ('').
% The built-in plot is itself a PlotFcn: opts.PlotFcn = @adamnlopt.plotIteration
% draws the same 2x2 figure as opts.Plot = true.  A cell array of handles is
% allowed and each is called.  Errors raised by a PlotFcn are caught, reported
% once per solve, and never stop or alter the solve.
opts.PlotFcn = [];

% IterationFcn: user-defined per-iteration callback ([] = off).
%   IterationFcn(info) is called after every iteration -- including the
%   terminal one, whose info carries its stop/exitflag/message -- with INFO a
%   scalar struct describing the state of the iteration that just finished.
%   Accepts a single function handle or a cell array of handles; a cell array
%   is evaluated in array order, one call per handle per iteration.
%
%   This is the same firing cadence as PlotFcn, but the info struct is strictly
%   richer: it carries everything PlotFcn's info carries (all quantities
%   unscaled and indexed over the ORIGINAL variables; see the list above) PLUS
%   the solver's raw INTERNAL state for the iterate, so a callback can inspect
%   or record exactly what the solve computed without understanding the
%   scaling/reduction machinery:
%     state            - the raw iterate state struct: x, f, g, cE, cI, s,
%                        lamE, lamI, zL, zU, JE, JI (all in the solver's
%                        internal scaled/reduced space), iter, nFunEvals,
%                        alpha, mu, mode, and the interior-point plateau
%                        counters (objStallCount, optGateCount,
%                        feasRegressCount, bestFeas) when present.
%     res              - the raw residual struct: rStat (stationarity vector),
%                        rFeasE (equality feasibility), rFeasI (inequality
%                        feasibility with slacks), rComp (complementarity
%                        vector), and the scalar norms opt/feas/comp.
%     optRaw           - the unweighted stationarity inf-norm max(abs(rStat)),
%                        before the scale-consistent weighting that
%                        info.firstorderopt/info.optPrinted apply.
%     xScaled, fScaled, gScaled, cEScaled, cIScaled - the state's values under
%                        explicit aliases (scaled/reduced space).
%     rStat, rFeasE, rFeasI, rComp - the residual vectors under explicit
%                        aliases (same as res.*).
%     lambda           - struct with lamE, lamI, zL, zU (raw multipliers in
%                        the scaled solve; empty when the class is absent).
%     n, mE, mI        - problem dimensions of the internal (reduced, scaled)
%                        solve the core actually ran.
%     lb, ub           - physical bounds over the ORIGINAL variables.
%     step             - the step that produced the current iterate, in the
%                        scaled space: the search directions dx, dlamE, ds,
%                        dlamI, dzL, dzU; the accepted lengths aP (primal,
%                        equal to info.alpha), aD (dual), aLamE (equality-dual);
%                        the physical stepsize; the trust-region radius Delta;
%                        the fraction-to-boundary factor tau (after its last
%                        update, 0 in the equality core); and the l1-merit
%                        penalty rho.  Directions that do not exist in the
%                        active core are empty; lengths that do not exist are
%                        NaN.  At iteration 0 every direction is zero (no step
%                        has been taken yet).
%     advice           - mode-controller advice struct (muFactor, deltaFactor,
%                        suggestRestore, mode) in effect at the iterate.
%     nActiveBnd       - number of variables pinned at a bound (interior-point
%                        core only; 0 in the equality core).
%     lsAdopted, lsFired - 0/1 flags of the least-squares equality-multiplier
%                        refresh (interior-point core; 0 elsewhere).
%     opts             - the fully resolved options struct in effect, so a
%                        callback can read the tolerances/budgets the iterate
%                        was judged against.
%   Nothing in the struct is reconstructed or re-evaluated: every quantity is
%   what the solver itself computed at that iterate.  A callback may request
%   an early stop of the solve by returning truthy as its first output:
%   stop = IterationFcn(info).  The solver then terminates at the current
%   iterate with exitflag -1 and message 'Stopped: the iteration function
%   requested a stop.'; the remaining handles in a cell array are still called
%   and see the request in info (stop = true, exitflag = -1, message set).  A
%   stop request on an iteration the solver is already terminating on is a
%   no-op -- the natural exitflag/message stand.  Returning false or nothing
%   continues the solve.  Errors raised by an IterationFcn are caught,
%   reported once per solve, and never stop or alter the solve -- the same
%   policy as PlotFcn.
opts.IterationFcn = [];

% --- Output ---
% 'iter-debug' prints the same table as 'iter' plus extra diagnostic columns
% (unmasked/scaled optimality, ||lamE||, the barrier-stall ratio, active-bound
% count, and the costate-refresh flag) to help debug a non-converging solve;
% see util_logger.  Display-only -- the solve is identical at any Display level.
opts.Display = 'iter';  % 'off' | 'iter' | 'iter-debug' | 'final'
% LogFile: path to append the iteration table, final summary, and convergence
% advisor to as they are produced.  '' (default) disables file logging.  Each
% record is flushed on write, so an interrupted or errored long solve still
% leaves a usable log -- unlike capturing the solve with evalc/diary, which
% defers or loses everything.  Honoured only when Display is not 'off'.
opts.LogFile = '';
end
