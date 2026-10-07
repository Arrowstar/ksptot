# AdamNlOpt Package Review: Defects and Algorithm Improvements

**Date:** 2026-10-07
**Scope:** `helper_methods/math/adamnlopt/+adamnlopt/` (71 files, 14,142 lines), the LVD wrapper layer (`@AdamNlOptOptimizer`, `@AdamNlOptOptions`, the option enums, `lvd_editAdamNlOptOptionsGUI_App.m`, the adamnlopt branch of `lvd_executeOptimProblem.m`) and the existing test suite `tests/unit_tests/adamnlopt/`.
**Baseline:** HEAD of `v1.6.11` after commit `517d42b3` ("Fix 61 defects in AdamNlOpt and add a contract test suite"). Everything that commit fixed and pinned with a test is excluded here.

All file paths below are relative to `helper_methods/math/adamnlopt/+adamnlopt/` unless they start with `LVD:` (the wrapper layer) or `tests/`.

---

## 0. How this review was done

1. `solve.m` (3,500 lines, both solver cores and every helper) was read end to end by the lead reviewer. The remaining 70 files were split into four groups (KKT/linear algebra/steps; globalization/control/degeneracy/termination; Evaluator/derivatives/Hessian models/parallel; setup/scaling/options/IO/LVD wrapper) and each group was read completely by a dedicated reviewer who also traced every call site in `solve.m`. Cross-group findings were de-duplicated and the highest-impact claims were re-verified against the source by the lead.
2. The solver was exercised in a live MATLAB session on 25 adversarial problems (bounds-only, equality-only, mixed, degenerate Jacobians, infeasible, non-convex with exact Hessian, noisy objectives, a 600-variable sparse problem, fixed variables, LP, Rosenbrock n=10 with and without analytic gradients, `maxIter`/`maxTime` exits). Several findings below were discovered or confirmed only by these runs; where that is the case the observed numbers are quoted.
3. The existing suite was run twice: **619 of 620 tests pass** in 23 s. The one non-passing test, `AdamNlOptSolveTest/testOptionsStructAndOptimoptionsObjectAgree`, is **Incomplete, not Failed**: it guards on `license('test','Optimization_Toolbox')`, which returns 1 on this machine, but `optimoptions` then cannot check out a license. That is an environment issue; see T1 for a one-line hardening of the guard.

**Severity scale.** *Critical*: wrong answers or silent loss of the feature's purpose on the default LVD configuration. *High*: wrong or misleading results on reachable configurations, or large wasted cost on every solve. *Medium*: robustness or efficiency defects on specific but realistic problem classes. *Low*: inconsistencies, dead code, latent traps.

---

## 1. Executive summary (ranked)

| # | Sev. | Finding | Where |
|---|------|---------|-------|
| D1 | Critical | Broyden secant Jacobian silently auto-enables on every LVD solve (any FD Jacobian slower than 0.1 s) and convergence is certified against the approximate Jacobian | `Evaluator.m:672`, `defaultOptions.m:768`, LVD `AdamNlOptOptions.m:126` |
| D2 | Critical | Saving the LVD options dialog without touching anything disables automatic FD-step calibration (float round-trip breaks an exact `== sqrt(eps)` test) | `Evaluator.m:148`, LVD `AdamNlOptOptions.m:33` |
| D3 | Critical | Feasibility is tested, reported, and shown in the LVD GUI only in the solver's row-scaled space; rows are shrunk by `1/r` rather than IPOPT's `100/r`, so a physical violation up to `1/Dc` times `feasTol` is declared feasible | `terminationCheck.m:95`, `computeScaling.m:185`, `solve.m:3123`, LVD `AdamNlOptOptimizer.m:220-274` |
| D4 | Critical | Row scaling is measured from a Jacobian differenced with the uncalibrated `sqrt(eps)` step, before the FD calibration runs; on noisy ODE functions the scale factors are noise | `solve.m:122` vs `solve.m:171` |
| D5 | High | Degenerate or near-zero constraint Jacobian at the start plus FD noise yields an O(1) garbage step (reproduced: solver converges to the *maximizer* of `x1+x2` on the unit circle from `x0 = 0`) | `kkt_inertiaCorrection.m:139-145,291-294`, `degeneracy_detectDegeneracy.m:117-126`, `step_multiplierUpdate.m:44` |
| D6 | High | A failed line search (alpha = 1e-10) still feeds BFGS/L-BFGS a curvature pair; with FD gradients `y` is pure noise and the model is corrupted without tripping any guard | `solve.m:1572-1604`, `solve.m:532-543`, `BFGSHessian.m:240,299` |
| D7 | High | FD-step calibration normalises the probe direction so the chosen step is ~‖x‖ times too large in physical units (reproduced: 300x worse gradient at x0 = [1e4 2e4 1e3]) | `Evaluator.m:351-357` |
| D8 | High | `hessianApprox = 'exact'` without a `HessianFcn` costs n Jacobians (n² user evaluations) per iteration, differences an FD gradient with h = `sqrt(eps)`, and finite-differences even an *empty* constraint set (reproduced: 2.16 million calls on a bounds-only n = 600 problem) | `lagrangianHessian.m:45,111-112`, `Evaluator.m:601`, `finiteDiffJacobian.m:50-67` |
| D9 | High | User `HessianFcn` receives the stacked (linear + nonlinear) multipliers as `eqnonlin/ineqnonlin`, and is evaluated in scaled space with no transform | `lagrangianHessian.m:28-29`, `scaleProblem.m` |
| D10 | High | Equality core still clears the filter after restoration and fires restoration on the eager trigger; the IP core's two fixes from 517d42b3 were not ported | `solve.m:499-527` |
| D11 | High | The Krylov path always performs the full direct factorization first, so `linearSolver = 'krylov'/'auto'` is strictly more expensive than `'direct'`; LVD ships Krylov forcing defaults the package explicitly abandoned | `solve.m:2349`, LVD `AdamNlOptOptions.m:56-57` |
| D12 | High | Start-up pays for the x0 Jacobian and gradient twice (physical probe, then scaled Evaluator) and `jacobian()` ignores the constraints cache: ~n+2 wasted propagations per solve plus 1 per iteration | `solve.m:112-129, 609-611`, `Evaluator.m:563,601` |
| D13 | Medium | Barrier-stall relief condition (c) compares the *mu-perturbed* complementarity against `compTol`, so the relief is unreachable on a well-centred iterate (the case it was written for); barrier gate also uses unscaled error while termination uses scaled | `solve.m:1131`, `solve.m:1074` vs `terminationCheck.m:58-60` |
| D14 | Medium | No κ_Σ safeguard on the bound/slack multipliers after the dual step | `solve.m:1585-1587` |
| D15 | Medium | Warm-started regularization δ, γ is applied *before* the first factorization and the Fix-A γ never vanishes, so Newton is perturbed on every later iteration and feasibility plateaus at γ·‖Δλ‖ | `solve.m:2160-2165`, `kkt_inertiaCorrection.m:84,291-294` |
| D16 | Medium | No iterative refinement after the LDL solve; `blockInertia` zero-pivot tolerance is `N·eps·max` (too strict by N) | `linalg_solveKKTdirect.m:79-82,136` |
| D17 | Medium | SOC and inertia retries re-assemble and re-factor K from scratch; SOC corrects only the equality rows and evaluates along the uncorrected direction | `solve.m:1383-1453`, `kkt_inertiaCorrection.m:97` |
| D18 | Medium | Filter line search: theta-growth veto also gates f-type trials; `thetaMin` recomputed from current theta; no WB α_min (33 wasted trials per stall) | `globalize_filterLineSearch.m:68,84-88` |
| D19 | Medium | NT trust-region inner loop never shrinks when the globalization rejects a step; fallback bypasses the filter; radius can never expand under fraction-to-boundary | `solve.m:455-457, 1276-1313` |
| D20 | Medium | Restoration can declare local infeasibility (-2) on a feasible problem (cross-restoration θ comparison; GN direction accepted on an l1 Armijo test) | `solve.m:508-509, 1520-1521`, `degeneracy_restorationPhase.m:89,110` |
| D21 | Medium | A scalar `NaN` from a failed LVD propagation crashes the solve ("incompatible sizes") instead of being rejected as a trial point | `Evaluator.m:704`, LVD `ConstraintSet.m:171` |
| D22 | Medium | Full dual step taken on an iteration whose primal line search failed; equality multipliers always take the dual fraction `aD`, not the primal `aP` | `solve.m:1583-1587` |
| D23 | Medium | Penalty parameter ρ can only grow, for the whole solve, and is unbounded as θ → 0 | `solve.m:1921-1923, 2635-2637`, `control_penaltyUpdate.m` |
| D24 | Medium | `returnIterate = 'bestKKT'` is ignored on a user stop (LVD Cancel button) | `solve.m:1040` |
| D25 | Medium | Broyden refresh test is scaled by constraint value, so it never fires near feasibility | `eval_BroydenJacobian.m:117` |
| D26 | Low | Returned `hessian` is the model *before* the last secant update (verified numerically) | `solve.m:413, 1168` |
| D27 | Low | Armijo/merit test accepts an increase when θ0 = 0 and gd ≥ 0 | `globalize_filterLineSearch.m:109-117`, `solve.m:1922-1926, 2636-2641` |
| D28 | Low | Normal step takes the full trust radius (no ζ = 0.8), starving the tangential step | `solve.m:2692`, `step_tangentialStep.m:39` |
| D29 | Low | `stepNorm` stale after restoration; IP restoration does not re-seed `lamE`; `plotInfo` counts distance *inside* bounds as violation | `solve.m:525-527,1566-1568,1548-1552`, `plotInfo.m:103` |
| D30 | Low | Non-finite K spins 40 factorizations and returns a NaN step with no guard | `kkt_inertiaCorrection.m:135`, `solve.m` (no `isfinite(d)` check) |
| D31 | Low | Option hygiene: `lsRefreshFeasTol` dead but exposed in GUI; selector strings unvalidated; NaN bounds accepted; `util_scaling.m`, `estimateNoise.m`, `parallel_async*/batch*` dead; `diagnose` gives inverted advice; filter margin applied twice; absolute multiplier scale in active-set confidence; degeneracy detection in the IP core sees a state without `cE/cI/JI` | various |

**Algorithm improvements** (Section 3): FD-accuracy-aware termination and automatic forward→central promotion (A1, reproduced: Rosenbrock n=10 with FD gradients returns exitflag 0 at f = 2e-10 because `optTol` is below the FD noise floor); one combined FD sweep for gradient + Jacobian (A2, halves LVD propagations); warm start from a previous LVD run (A3); watchdog and IPOPT filter-reset heuristic (A4); acceptable-point termination (A5); WB-style proximal restoration (A6); FD re-calibration on repeated line-search failure (A7); derivative checker (A8); factor reuse and cheaper Schur probe (A9); LVD-specific defaults (A10).

---

## 2. Defects

### D1. [Critical] Broyden secant Jacobian auto-enables on every LVD solve; convergence is certified against it

**Where.**
- `Evaluator.m:672`: `v = obj.enableBroyden || obj.costModel.tooExpensive(obj.costThreshold);`
- `Evaluator.m:624`: `obj.costModel.tick(toc(t0));` ticks the wall time of the whole exact FD Jacobian (n user calls).
- `defaultOptions.m:768`: `opts.costThreshold = 0.1;  % seconds`; LVD `AdamNlOptOptions.m:126` repeats `0.1`.
- `solve.m` contains no reference to Broyden, `jacExact`, or any approximate-Jacobian flag. `kkt_residual.m:42` and `ipRes` form `rStat = g + JE'*lamE + JI'*lamI` from whatever `ev.jacobian` returned, and `terminationCheck` declares exitflag 1 on that.

**What happens.** LVD's default `gradAlgo = BuiltIn` hands the solver bare handles (`hasConGrad = false`). One FD Jacobian is n propagations, i.e. seconds to minutes. After the first exact Jacobian `avgTime > 0.1` is true forever (the window only ever contains exact refreshes), so from iteration 1 on, for up to `broydenMaxStale = 20` consecutive iterations, the KKT matrix, the costate least-squares refresh, the NT normal step, and the termination residual all use a rank-1 secant approximation of JE/JI. Nothing in `output` or the trace records this; `enableBroyden = false` reads as "off". Reproduced with `costThreshold = 0` on the unit-disk constraint: `jacobian(x1)` returned `[2.1 3.95]` against an exact `[2.2 3.9]` and was accepted.

**Cost.** (a) `optTol = 1e-6` cannot be certified with a Jacobian carrying 1e-2 relative error: the solver either reports exitflag 1 on a wrong `firstOrderOpt` or circles. (b) Local convergence degrades from superlinear to linear. (c) Each Broyden iteration also costs 2 nlcon calls where 1 suffices (D12), so the "cheap" iteration is not cheap.

**Fix (three parts).**
1. `defaultOptions.m:768` and LVD `AdamNlOptOptions.m:126`: `costThreshold = Inf`. Broyden becomes opt-in via `enableBroyden`. Update `AdamNlOptProblemSetupTest.m:1420` (default table).
2. Add to `Evaluator.m` a private logical `lastJacBroyden_` (set true on the Broyden return path at `:585`, false on the exact path at `:628`), a public `jacobianIsApprox()` getter, and
   ```matlab
   function [JE, JI] = jacobianExact(obj, x)
   %JACOBIANEXACT  Exact Jacobian at x, bypassing any Broyden model and re-anchoring it.
       saved = obj.enableBroyden;  savedCost = obj.costThreshold;
       obj.enableBroyden = false;  obj.costThreshold = Inf;
       obj.xj = [];                             % force the exact path
       [JE, JI] = obj.jacobian(x);
       obj.enableBroyden = saved;  obj.costThreshold = savedCost;
   end
   ```
   In both cores of `solve.m`, when `terminationCheck` returns `stop` with `ef > 0`, insert before the `if stop` branch:
   ```matlab
   if stop && ef > 0 && ev.jacobianIsApprox()
       [JE, JI] = ev.jacobianExact(x);  state.JE = JE;  state.JI = JI;
       res = kkt_residual(state);  res.opt = util_norms(optW .* res.rStat);   % IP core: rebuild rd/ipRes the same way
       [stop, ef, m] = terminationCheck(state, res, opts);
   end
   ```
   Also force `jacobianExact` after restoration (`solve.m:517`, `:1537`): the secant anchor is meaningless after a projected Gauss–Newton jump.
3. Trace/output: `trow.jacExact = double(~ev.jacobianIsApprox())` in `finishTraceRow`, and an `output.broydenIterations` count.

**Tests.** `AdamNlOptEvaluatorTest`: with `costThreshold = 0`, `jacobian(x0); jacobian(x1)` → `jacobianIsApprox()` true; `jacobianExact(x1)` equals `finiteDiffJacobian` to 1e-12 and clears the flag. `AdamNlOptSolveTest`: solve the unit-disk fixture with `enableBroyden = true`; recompute `firstOrderOpt` from an exact Jacobian at the returned x and assert it is ≤ `optTol`.

---

### D2. [Critical] Saving the LVD options dialog silently disables automatic FD-step calibration

**Where.**
- `Evaluator.m:148`: `obj.fdStepUserSet = opts.FiniteDifferenceStepSize ~= sqrt(eps);` (exact float equality).
- LVD `AdamNlOptOptions.m:33`: `finDiffStepSize(1,1) double = sqrt(eps);` always written to `FiniteDifferenceStepSize` (`:164`, no NaN sentinel).
- LVD GUI `lvd_editAdamNlOptOptionsGUI_App.m:725-743`: `numToStr → fullAccNum2Str`, `strToNum → str2double`.

**What happens.** Verified in MATLAB: `str2double(fullAccNum2Str(sqrt(eps)))` differs from `sqrt(eps)` by 4.3e-23. Opening the dialog and pressing Save with no edits stores a value ≠ `sqrt(eps)`, `fdStepUserSet` becomes true, and `Evaluator.setFd` (`:854-866`) never applies the calibrated step. Every LVD run after a GUI save differences with h = 1.5e-8 on functions with 1e-8..1e-6 relative noise, which is exactly the "noisy-gradient optimality plateau" `defaultOptions.m:97-109` describes as the reason `autoFDStep` exists. The `FiniteDifferenceType` test (`:149`) is immune because it compares strings.

**Fix (root cause, two lines).**
- `Evaluator.m:148`: `obj.fdStepUserSet = abs(opts.FiniteDifferenceStepSize - sqrt(eps)) > 1e-6 * sqrt(eps);`
- LVD `AdamNlOptOptions.m:33`: `finDiffStepSize(1,1) double = NaN;  % NaN = solver default (sqrt(eps)); keeps autoFDStep armed`. It is already in `numericMap`, so NaN is skipped on output. Update the GUI tooltip default text (`formatDefault` already renders NaN as "automatic").

**Test.** `o = AdamNlOptOptions(); o.finDiffStepSize = str2double(fullAccNum2Str(sqrt(eps))); opts = o.getOptionsForOptimizer([]); ev = adamnlopt.Evaluator(problem, opts); assert(~ev.fdStepUserSet)`. Add an `AdamNlOptSolveTest` arm asserting `output.fdCalibration.flag == 'set'` after that round trip.

---

### D3. [Critical] Feasibility is gated, reported and displayed only in row-scaled space

**Where.**
- `kkt_residual.m:63` / `solve.m:1799`: `res.feas = util_norms(rFeasE, rFeasI)` on `cE = Dc.*cE_phys`, `cI + s`.
- `terminationCheck.m:95`: `... && res.feas <= opts.feasTol && ...` (same scaled quantity at `:133` and `:173`).
- `solve.m:3123`: `output.constrViolation = res.feas;` — `unscaleResult.m` never touches it. fmincon's `output.constrviolation` is physical.
- `computeScaling.m:185`: `d(i) = min(1, 1 / r);` — IPOPT uses `min(1, gmax/r)` with `nlp_scaling_max_gradient = 100`; here every row with gradient > 1 is shrunk, including LVD's already normalised rows.
- LVD `AdamNlOptOptimizer.m:220-223, 243, 274`: `info.constrviolation` (documented at `defaultOptions.m:848` as scaled) goes to the progress label, the fmincon-style `optimValues.constrviolation`, and `recorder.maxCVal`, the slot the fmincon/IPOPT wrappers fill with the physical violation, and the scorecard (`ma_OptimRecorder.getIterWithLowestFVal`) ranks on it.

**Failure.** A constraint row with `‖row.*Dx‖∞ = 1e4` (a km-scale position row against [-1,1] variables) gets `Dc = 1e-4`; a physical violation of 1e-2 reads as 1e-6 and the solve returns exitflag 1 while the LVD GUI shows "Constraint Violation = 9e-7". Combined with D4 the factor is unpredictable per row and per run. The stationarity side was already made scale-consistent in 517d42b3 (`optW`); the feasibility side was not.

**Fix.**
1. `solve.m` after `optScaleW` (line 204): `solveProblem.feasScaleW = struct('E', 1./[sc.Dc], 'I', 1./[sc.Di]);` (all ones when scaling is off). In both cores, after the residual is formed: `res.feasPhys = util_norms(wE .* rpE, wI .* max(rpI_cI, 0))` where for the IP core the inequality part uses `cI` (not `cI + s`), i.e. `max(cI ./ Di, 0)`.
2. New option `opts.constrViolTol` (IPOPT `constr_viol_tol`, default `1e-4`, documented as physical units). `terminationCheck.m:95,133,173`: add `&& (~isfield(res,'feasPhys') || res.feasPhys <= opts.constrViolTol)`.
3. `makeOutput` (`solve.m:3123`): `output.constrViolation = res.feasPhys` when present; keep `output.constrViolationScaled = res.feas`. `plotInfo.m:166`: `constrviolation` physical, add `constrviolationScaled`. The wrapper then needs no change.
4. `computeScaling.m:185`: `d(i) = min(1, gmax / r)` with new `opts.autoScaleMaxGradient = 100`, mirrored in LVD options/GUI.

**Test.** `min x1 s.t. 1e4*(x1 - 1) = 0`, autoScale on, `feasTol = 1e-6`: assert `|1e4*(x-1)| <= constrViolTol` and `output.constrViolation` is the physical value. Assert an IterationFcn sees a physical `info.constrviolation`. Assert `constrViolTol = Inf` reproduces today's behaviour so the goldens are unaffected.

---

### D4. [Critical] Row scaling is measured before FD-step calibration

**Where.** `solve.m:122` `sc = computeScaling(solveProblem0, evProbe, opts);` calls `ev0.jacobian(x0)` (`computeScaling.m:140`) with `evProbe.fdStep = sqrt(eps)`. Only at `solve.m:171` does `evProbe.calibrateStep` set the step the noise level demands.

**Why wrong.** In LVD BuiltIn mode the probe Jacobian is a forward difference with h = 1.49e-8 on functions with absolute noise 1e-8..1e-6 (normalised constraints are O(1)). FD error ≈ 2·noise/h ≈ 1.3 … 130 per entry against true derivatives O(1..10). Row norms are inflated by up to 100x, `Dc` shrunk by the same factor, and since `feasTol` is applied to `Dc.*c` (D3) the solver declares feasibility at violations 10–100x looser than requested, randomly per row and per run. The calibration that exists to fix this runs after the one probe that most needs it. (The curvature probe uses its own h = 1e-2 and is unaffected.)

**Fix.** Move the `autoFDStep` block (`solve.m:169-190`) above line 122, split so `calibrateStep` runs on `evProbe` first and the `fdStepTransfer` part runs after `sc` exists:
```matlab
output_calib = [];
if isfield(opts,'autoFDStep') && opts.autoFDStep
    try, output_calib = evProbe.calibrateStep(solveProblem0.x0); catch, output_calib = []; end
end
sc = computeScaling(solveProblem0, evProbe, opts);          % probe now uses the calibrated step
if sc.applied, solveProblem = scaleProblem(solveProblem0, sc);  ev = Evaluator(solveProblem, opts);
else,          solveProblem = solveProblem0;                 ev = evProbe;  end
if isstruct(output_calib)
    if strcmp(output_calib.flag, 'set'), [fdFactor, fdSpread] = fdStepTransfer(solveProblem0.x0, sc);
    else, fdFactor = 1;  fdSpread = 1;  end
    ev.fdStep = evProbe.fdStep * fdFactor;  ev.fdType = evProbe.fdType;
    output_calib.scaleFactor = fdFactor;  output_calib.scaleSpread = fdSpread;  output_calib.fdStepScaled = ev.fdStep;
end
```
`calibrateStep` is physical-space and does not read `sc`, so the swap is safe. This also makes D12's cache seeding valid (the probe Jacobian becomes the one the solver would compute).

**Test.** Seeded noisy constraint `c(x) = 1e3*x(1) + 1e-7*randn`, bounds [-1,1]: assert `output.scaling.Dc(1)` is within 2x of `1/(1e3*2)`. On HEAD it is off by more than 10x.

---

### D5. [High] Degenerate constraint Jacobian at the start plus FD noise produces an O(1) garbage step

**Reproduction.** `min x1 + x2  s.t.  x1² + x2² = 1`, `x0 = [0; 0]`, FD constraint gradient (default). JE at x0 is analytically `[0 0]`; forward differencing returns `[1.49e-8 1.49e-8]` (truncation error h). Trace of the first step: `delta = gamma = 1e-8`, `normDx = 1.49`, `aP = 0.5`, f rises 0 → 1.49. The solver converges in 2 iterations to `(+0.707, +0.707)`, f = +1.414, exitflag 1: the **maximizer**. With an analytic constraint gradient it converges to the minimizer `(-0.707, -0.707)`; starting at `(1e-9, 1e-9)` or adding harmless bounds (IP core) reproduces the wrong answer.

**Mechanism.** With JE rank-deficient the inertia loop raises `gamma` to 1e-8 (`kkt_inertiaCorrection.m:139-145`). The dual row `JE dx − γ dλ = −cE` then gives `dλ = cE/γ = −1e8`, and the primal row `W dx = −r1 − JE' dλ` receives `−JE' dλ = +1.49` from the FD-noise Jacobian. The Fix-B cap (`dualStepMax`) caps the *multiplier* increment afterwards but not the primal `dx` that already contains `W⁻¹JE'dλ`. The step is then accepted because θ drops from 1 to 0.11. Degeneracy detection (`degeneracy_detectDegeneracy.m:117-126`) did not fire: its rank tolerance `max(N·eps·dmax, 1e-12·dmax)` is purely relative to the matrix, so a single near-zero row always has rank 1. `step_multiplierUpdate.m:44` (`JE.' \ (-g)`) likewise returns a *basic* solution with warnings suppressed on rank-deficient JE, and `computeNTStep` (`solve.m:2699`) calls it without the `optW` weight every other caller passes.

**Why it matters for LVD.** Constraints that are insensitive to every variable at x0 (a terminal condition on a coast that no variable yet influences, a constraint on an inactive stage) are common, and all LVD derivatives are FD.

**Fix.**
1. **Absolute floor on the degeneracy test.** In `matrixRank` (`degeneracy_detectDegeneracy.m:125-126`) accept a scale: `tolAbs = fdNoise * max(1, norm(x, inf))` with `fdNoise = ev.fdStep` when `~hasConGrad` (else `sqrt(eps)`), and `r = sum(dR > max(tol, 1e-12*dmax, tolAbs))`. Rows with `‖JE_i‖∞ < tolAbs` are then "dependent" and the regularized-recovery path (`stepSource = 1`) is taken. Pass `ev` (or the step) through `state`.
2. **Cap the dual step inside the solve, then recompute dx.** In `kkt_inertiaCorrection` after the solve (`:102`), when `reg.gamma > 0`: if `norm(dlamE, inf) > dualStepMax*max(1, norm(lamE, inf))`, scale `dlamE` and re-solve the primal block `W dx = −r1 − JE' dlamE` (one more solve with the existing factors; see A9). This removes the amplification regardless of detection.
3. **Minimum-norm multipliers everywhere.** `step_multiplierUpdate.m:44,47`: `lamE = lsqminnorm(JE.' .* w, -(w .* g));` with `w = ones` when omitted; pass `optW` through `computeNTStep`.
4. Tie the Fix-A γ to convergence (D15) so γ cannot stay at `sMax/condMax` on a problem whose Schur complement is permanently ill-conditioned.

**Tests.** The reproduction above must return `f = −1.414` with FD gradients; `JE = [1e-8 1e-8]` with `fdStep = 1.5e-8` must be flagged `linDepE`; `JE = [1 0 0; 1 0 0]`, `g = [1;2;3]` → `lamE = [-0.5; -0.5]`.

---

### D6. [High] A failed line search still updates the quasi-Newton model with a noise pair

**Where.** `solve.m:1947` (IP merit search returns `alpha = min(amin, aMax)` = 1e-10), `solve.m:2654` (eq core), `globalize_filterLineSearch.m:132`; the step is then accepted at `solve.m:1572-1573` / `:532` and `updateHessianModel(..., aP*dx)` runs unconditionally (`:1603`, `:542`). The only guards are `ss > 0` (`BFGSHessian.m:240`) and the scale-free cosine floor `s'y > sqrt(eps)‖s‖‖y‖` (`:299`); `LBFGSHessian.m:117,137` are the same.

**What happens.** `s = 1e-10·dx`, `y = gFD(x+s) − gFD(x)`: two FD gradients differenced over a distance far below the FD probe step carry no curvature; `y` is the FD-noise difference (‖y‖ ~ 1e-6..1e-4 on LVD). `s'y > 0` half the time, the cosine floor passes for any |cos| > 1.5e-8, Powell damping does not fire because `s'Bs ~ 1e-20` is smaller still, and the rank-1 term `yy'/s'y ~ 1e10·e_g` is injected. Reproduced on n = 50: after one sane pair eig(B) ∈ [2.9, 3.1]; after one pair with `s = 1e-10·dx`, `y = 1e-6·randn` the update was accepted and eig(B) ∈ [0.018, 1.2e5], cond 6.7e6 (below `condMax = 1e12`, so `healthCheck` does nothing). The next step is governed by a 1e5 bogus eigenvalue along a random direction, the "step collapses after a failed line search" signature. In milder form every legitimate step shorter than the FD step teaches the model noise (Shi, Xie, Byrd, Nocedal 2021).

**Fix.** In `updateHessianModel` (`solve.m:2467`), which both cores call with `ev` and `x` in scope (extend the signature):
```matlab
% A pair whose step is shorter than the derivative's own resolution cannot carry curvature.
if ~(ev.hasObjGrad && ev.hasConGrad), sMin = 2 * ev.fdStep * max(1, norm(xNew, inf));
else,                                 sMin = sqrt(eps) * max(1, norm(xNew, inf));  end
if norm(sVec, inf) <= sMin
    hinfo.bfgsAccepted = 0;  hinfo.bfgsSkippedShort = 1;  return;
end
```
and in both cores skip the update outright when `lsFailed` is true or `aP <= 1e-10` (the step was a forced creep, not an accepted sample).

**Tests.** `AdamNlOptHessianModelTest.testATinyNoisyPairDoesNotCorruptTheModel` (n = 50 scenario; cond(B) within 10x of before). `AdamNlOptSolveTest`: noisy Rosenbrock (`f + 1e-8*sin(1e9*sum(x))`) must show no trace row with `bfgsAccepted == 1 && aP <= 1e-9`.

---

### D7. [High] FD-step calibration picks an absolute step along a unit direction but applies it as a relative base step

**Where.** `Evaluator.m:351-355`:
```matlab
svec = p .* max(1, abs(x0));
nsv = norm(svec);  ...  svec = svec / nsv;
```
then `:357` `hSweep = 10.^(-1:-1:-9)` and `setFd(obj, 'forward', hSweep(iF))` stores the winner as `fdStep`, which `finiteDiffGradient.m:43` applies as `h·max(1,|x_i|)`.

**Why wrong.** During calibration coordinate i is displaced by `h·m_i/m_rms` (m = max(1,|x0|)); in use it is displaced by `h·m_i`. They agree only when `m_rms ≈ 1`, i.e. in scaled space. The calibration runs in physical space by design (`solve.m:146-149`), where LVD variables are km and seconds, so the V-curve bottom is found for a displacement `m_rms` times smaller than the one later used.

**Reproduced.** `f = 0.5·Σ(x_i/xref_i)² + 1e-9·sin(1e9·Σ i·x_i)`:
- x0 = [0.7 0.7 0.7]: calibrated central 1e-3, gradient rel-err 4.6e-7.
- x0 = [1e4 2e4 1e3]: calibrated forward 1e-2, gradient rel-err **5.0e-3**; brute-force best forward step 5.6e-5 gives 1.6e-5 (300x better), and central at any h ≤ 1e-2 gives 9.5e-8, so the forward/central decision was also wrong.
- With the fix below: forward pick 1e-5 (rel-err 1.2e-4) and the rule promotes to central (9.5e-8).

**Fix** (`Evaluator.m:351-355`): normalise the random mix first, then weight, so the probe's relative length is exactly h:
```matlab
sRng = rng;  rng(97531, 'twister');  p = randn(nx, 1);  rng(sRng);
np = norm(p);  if ~(np > 0), return; end
svec = (p / np) .* max(1, abs(x0));   % unit RELATIVE step: ||svec ./ max(1,|x0|)|| == 1
```
`maxFeasibleStep` (`:827`) needs no change. Fix the docstrings at `:264-265` ("Richardson-extrapolated reference" — the code uses adjacent change, not Richardson), `:345-350`, and `defaultOptions.m:67`.

**Test.** `testCalibrationIsInvariantToVariableMagnitude`: both x0 above; assert the gradient error at the calibrated (step, type) is within 10x of brute-force best for both, and the chosen `fdStep` differs by < 10x between them.

---

### D8. [High] `hessianApprox = 'exact'` without a `HessianFcn` is an n² evaluation Hessian that also differences empty constraint sets

**Where.** `lagrangianHessian.m:111-112` `lagGrad` calls `ev.objective` and `ev.jacobian` at n (or more) perturbed points; `:45` uses `h = sqrt(eps)`. `Evaluator.jacobian` (`:601`) calls `evalNonlinear` then `finiteDiffJacobian` unconditionally; `finiteDiffJacobian.m:50-67` loops over all n columns even when `m = numel(base) == 0`.

**Reproduced.** Bounds-only n = 600 quadratic with `hessianApprox = 'exact'`: 6 iterations took 51 s; the profile shows `lagrangianHessian` → 3,606 `lagGrad` calls → 3,608 `finiteDiffJacobian` calls → **2,164,800** `evalNonlinearStacked` calls, every one of them differencing an empty constraint vector. The same problem with the default BFGS took 0.76 s.

**Cost on LVD.** With nonlinear constraints and n variables, one 'exact' Hessian is n Jacobians = n(n+1) propagations per iteration. For n = 100 at 0.5 s that is ~1.4 hours per iteration. The LVD GUI exposes `hessianApprox = Exact` with no cost warning. Separately, when the gradient is itself FD (LVD default) its error is ~`fdStep`, and differencing it with h = 1.5e-8 gives Hessian error `fdStep/1.5e-8` ~ 1e3..1e5: pure noise.

**Fix.**
1. `Evaluator.jacobian` (`:600` region): `if obj.mInl + obj.mEnl == 0, Jc = zeros(0, obj.n); Jceq = zeros(0, obj.n); else ... end`. Also `finiteDiffJacobian.m` after line 48: `if m == 0, return; end` (defensive).
2. `lagrangianHessian.m:45`: `if ev.hasObjGrad && ev.hasConGrad, h = sqrt(eps); else, h = max(sqrt(eps), sqrt(ev.fdStep)); end`.
3. Route the probe Jacobians through `jacobianExact` (D1) so each probe column does not perform a Broyden update with a sub-threshold step.
4. `mapOptions`/`validateProblem`: when `hessianApprox` is `'exact'` or `'fd'` and `~(hasObjGrad && hasConGrad)`, issue `warning('adamnlopt:fdHessianCost', 'FD Hessian costs n*(n+1) user evaluations per iteration; consider bfgs/lbfgs')` once. LVD GUI tooltip should state the cost.

**Tests.** Bounds-only problem with `'exact'`: `output.conCount == 0` (today it is ~n² per iteration). `testLagrangianHessianMatchesTheDerivestOracle` with `hasObjGrad = false` and 1e-9 noise: should match to ~1e-2 relative with the new h; fails any reasonable tolerance today.

---

### D9. [High] User `HessianFcn` receives stacked multipliers and is evaluated in scaled space

**Where.** `lagrangianHessian.m:28-29`:
```matlab
lambda.eqnonlin   = lamE;
lambda.ineqnonlin = lamI;
```
`Evaluator.jacobian` stacks `JE = [Aeqlin; d(ceq_nl)/dx]`, `JI = [Aineq; d(c_nl)/dx]` (see `makeLambda`, `solve.m:3333-3336`), so `lamE(1:mElin)` are linear-equality multipliers. fmincon's contract (which `mapOptions` adopts) is that `eqnonlin` has `mEnl` entries. `reduceProblem.m:151-153` asserts the opposite of what the code does. And `scaleProblem.m` never wraps `HessianFcn`, so with the default `autoScale = 'gradient'` the user Hessian is called at scaled x with scaled multipliers and used unscaled (acknowledged as a "known gap" at `reduceProblem.m:154-158`, but live).

**Failure.** Any problem with `Aeq`/`A` rows and a `HessianFcn`: either a dimension error inside the user function or silently wrong curvature. Any scaled problem with a `HessianFcn`: wrong Newton matrix (off by `wf·Dx·Dx'` and the multiplier scaling). Not reachable from LVD (never sets `HessianFcn`), but a trap for the raw API. The only test passes `ev = []` and scalar multipliers.

**Fix.**
```matlab
% lagrangianHessian.m
if ~isempty(opts.HessianFcn)
    nLinE = 0;  nLinI = 0;
    if ~isempty(ev), nLinE = ev.mElin;  nLinI = ev.mIlin; end
    lambda.eqnonlin   = lamE(nLinE+1:end);     % linear rows have zero Hessian; dropping them is exact
    lambda.ineqnonlin = lamI(nLinI+1:end);
    ...
```
and in `solve.m` after `scaleProblem` (line 125):
```matlab
if sc.applied && ~isempty(opts.HessianFcn)
    H0 = opts.HessianFcn;  Dx = sc.Dx;  wf = sc.wf;
    DcNl = sc.Dc(sc.mElin+1:end);  DiNl = sc.Di(sc.mIlin+1:end);
    opts.HessianFcn = @(xs, lam) wf * (Dx*Dx.') .* H0(Dx.*xs, ...
        struct('eqnonlin', DcNl.*lam.eqnonlin/wf, 'ineqnonlin', DiNl.*lam.ineqnonlin/wf));
end
```
(Scaled Lagrangian `wf·f + Σ λ_s·Dc·c` gives `H_s = wf·DxDx' .* H_phys(x, Dc·λ_s/wf)`.) Alternatively refuse `HessianFcn` with `autoScale ~= 'none'`.

**Tests.** Evaluator with one `Aeq` row and one nonlinear equality; `lagrangianHessian(ev, x, [3; 7], [], opts)` with a recording `HessianFcn` → `lambda.eqnonlin == 7`, length 1. Quadratic with analytic Hessian and bounds [0, 1e4] (Dx = 1e4): iterations with `HessianFcn` equal iterations with `hessianApprox = 'exact'` and analytic gradients.

---

### D10. [High] Equality core did not receive the IP core's restoration fixes

**Where.** `solve.m:499-527` (eq core) vs `:1485-1568` (IP core).
- `:525` `if useFilter, filt.reset(); end` — the IP core was changed in 517d42b3 to `filt.augment(thetaPreRest, phiPreRest)` (`:1565`) with a 20-line comment explaining the period-2 limit cycle a reset causes (restore → jump back out → restore …). The eq-core line was left as diff context. The regression test for finding 57 uses an inequality problem, so only the IP core is covered.
- `:499-500` `needRestoration = ... && (alpha <= 1e-10 || advice.suggestRestore)` — no `feasStallCount` gate and `lsFailed` is dropped from the `globalize_filterLineSearch` outputs (`:490`). The IP core comment at `:1463-1484` explains that these eager triggers produced premature exitflag -2 on the orbit case.
- `:507-528` does not call `hmodel.reset()` (the IP core does at `:1553`), does not reset `stepNorm` (D29), and does not re-seed `lamE` with the same guard the IP core uses.

**Fix** (`solve.m:499-528`):
```matlab
thetaPreRest = norm(cE, 1);  phiPreRest = f;
feasGenuinelyStalled = feasStallCount >= opts.restStallWindow;      % add the bestFeas/feasStallCount tracker (copy of :873-878)
needRestoration = opts.enableRestoration && norm(cE, 1) > opts.feasTol && ...
    feasGenuinelyStalled && (lsFailed || alpha <= 1e-10 || advice.suggestRestore);
if needRestoration
    ...
    lamE = step_multiplierUpdate(g, JE, optW);
    if ~isempty(hmodel) && ismethod(hmodel, 'reset'), hmodel.reset(); end
    if useFilter, filt.augment(thetaPreRest, phiPreRest); end         % was filt.reset()
    Delta = opts.delta0;  alpha = 0;  stepNorm = inf;
    continue;
end
```
with `[alpha, augment, rho, lsFailed] = globalize_filterLineSearch(...)` at `:490` and `lsFailed = false` initialised per iteration.

**Test.** Equality-only analogue of the finding-57 fixture (e.g. `min (x1-2)²+(x2-1)² s.t. x1²+x2² = 1` from `x0 = [0.3; 0.2]` with a linear equality that makes the first Newton step overshoot): assert `exitflag > 0` and `sum(output.trace.restorationFired) < 10`; assert `filterSize` does not drop to 0 on the restoration row.

---

### D11. [High] The Krylov path is strictly more expensive than the direct path; LVD ships the abandoned forcing defaults

**Where.** `solve.m:2349` `[dDirect, ~, kinfo, reg] = kkt_inertiaCorrection(state, res, n, mE, [], opts);` then `:2360-2362` builds the operator and runs MINRES/GMRES on the *same* system. `kkt_inertiaCorrection` assembles the dense K (both `BFGSHessian.getMatrix` and `LBFGSHessian.getMatrix` return dense n×n; no matrix-free H reaches this code), runs the O(n³) Fix-A probe (`W \ JE'` + `eig(S)`), and factorizes up to 40 times. The exact step is then in hand, and the Krylov answer (tol ∈ [1e-10, 1e-6]) is preferred unless it fails. Measured: n = 600, 6 iterations, direct 17.9 s, krylov 16.7 s, auto 16.7 s (identical work plus the Krylov solve). Further: `linalg_forcingSequence.m:43-47` safeguard is dead (`forcingEtaMax = 1e-6` makes `etaPrev^1.618 ≤ 1e-9.7`, never > 0.1); `solve.m:2358` `tol = min(eta, max(opts.forcingEtaMin, 0.1*Fk))` uses an *absolute* residual norm as a *relative* tolerance (inert only because eta ≤ 1e-6); `ksolve.Fprev/etaPrev` (`:2364-2365`) are overwritten by SOC re-solves with a different RHS and never reset when mu drops.

LVD `AdamNlOptOptions.m:56-57` carries `forcingEtaMax = 0.9; forcingEtaMin = 1E-8;` while `defaultOptions.m:371-372` is `1e-6 / 1e-10`, and the 25-line comment at `defaultOptions.m:346-370` documents that 0.9 (and even 1e-4) stalls HS71 at `firstOrderOpt 6e6`. LVD writes every non-NaN numeric unconditionally (`:222-228`), so an LVD user who selects Krylov/Auto gets exactly the configuration the package fixed.

**Fix.**
1. Decide what the Krylov path is for. Honest minimal option: make it a true alternative. In `solveStepKrylov` replace the `kkt_inertiaCorrection` call with `reg = ksolve.reg` (carry the last accepted δ, γ; no factorization), build `op`, run MINRES **warm-started** from `ksolve.lastD` (add a 6th argument to `linalg_solveKKTkrylov` and pass it to `minres(afun, rhs, tol, maxit, mfun, [], x0)`), and only on `flag ~= 0` fall back to `kkt_inertiaCorrection`. Replace the forcing sequence with a fixed `krylovTol` unless the filter is made dual-aware (the defaultOptions comment explains why 0.9 broke HS71). Fix `tol = max(opts.forcingEtaMin, eta)`. Decouple SOC from `Fprev`. If this is not worth doing, delete the Krylov path and the `'auto'` switch rather than leave a slower, less accurate branch reachable from the GUI.
2. LVD `AdamNlOptOptions.m:56-57` → `1E-6 / 1E-10`, plus a `loadobj` migration (`if obj.forcingEtaMax == 0.9, obj.forcingEtaMax = 1e-6; end`, likewise 1e-8 → 1e-10) for saved cases.
3. Pin LVD defaults to package defaults with a test: for every non-empty numeric/logical field `f` of `adamnlopt.defaultOptions()`, `isequal(AdamNlOptOptions().getOptionsForOptimizer([]).(f), d.(f))`.

**Test.** `AdamNlOptSolveTest.testEveryKrylovArmTracksTheDirectSolver` already compares x; add an assertion that on an iteration whose MINRES converged the trace shows `pathDirect == 0` and `tries` NaN (no factorization).

---

### D12. [High] Start-up evaluates x0 derivatives twice; `jacobian()` ignores the constraints cache; FD gradient never cached

**Where.**
- `solve.m:112-129`: `evProbe.jacobian(x0)` (n or 2n propagations via `computeScaling.m:140`), then `ev = Evaluator(solveProblem, opts)` with an empty cache, and the core immediately calls `ev.objective/constraints/jacobian(x0s)` (`:609-611`, `:296-298`): the same physical point re-differenced. Measured on n = 20 with FD gradients: 38 objective evaluations within 1e-2 of x0 (one FD gradient = 21). On an LVD case with n = 30 at 1 s/eval that is 30–60 s before iteration 0 prints, on top of the calibration sweep.
- `Evaluator.m:563` (Broyden path) and `:601` (exact path): `[cnl, ceqnl] = obj.evalNonlinear(x)` without consulting `obj.xc/cIVal/cEVal`, which every call site in `solve.m` has just filled with `constraints(x)`. Reproduced: `constraints(x); jacobian(x)` on a 2-variable problem costs 4 nlcon calls where 3 suffice; the Broyden path costs 2 where 1 suffices. That is one wasted propagation per iteration.
- `Evaluator.m:210-226`: the FD gradient branch recomputes `finiteDiffGradient` on every `nargout > 1` call; `hasCachedG/gVal` are maintained only for the analytic branch. `lagrangianHessian.m:111` (`g0 = gL(x)`) and any `IterationFcn` asking for a gradient pay n evaluations again. `numFDevals` (`:224`) is an estimate (n or 2n) while the parallel path counts exactly; with `HonorBounds` one-siding, the serial count over-reports.

**Fix.**
1. `Evaluator.seedCache(xs, f, g, cE, cI, JE, JI)` setting `xf/fVal/hasCachedG`, `xc/cEVal/cIVal`, `xj/JEVal/JIVal`; after `scaleProblem` in `solve.m` call it with the probe's values transformed exactly as `scaleProblem` does (`f*wf`, `Dc.*cE`, `Di.*cI`, `(Dc.*JE).*Dx'`, `(Di.*JI).*Dx'`, `g` only when `hasObjGrad`). Valid only after D4 moves calibration ahead of the probe.
2. One private helper used by both Jacobian paths:
   ```matlab
   function base = nlStackedAt(obj, x)
       if isequal(x, obj.xc)
           base = [obj.cIVal(obj.mIlin+1:end); obj.cEVal(obj.mElin+1:end)];
       else
           [c, ceq] = obj.evalNonlinear(x);  base = [c(:); ceq(:)];
           obj.cIVal = [obj.linIneq(x); c(:)];  obj.cEVal = [obj.linEq(x); ceq(:)];  obj.xc = x;
       end
   end
   ```
3. Wrap the FD gradient branch in the same `hasCachedG` cache as the analytic branch; add `set.fdStep`/`set.fdType` that clear `hasCachedG` and `xj` (solve.m changes them after `evProbe` has cached values). Make `finiteDiffGradient` return the exact evaluation count and delete `numFDevals`.

**Tests.** `output.funcCount` on a 10-variable FD problem drops by exactly n+2 (forward) / 2n+2 (central) after seeding. `constraints(x); jacobian(x)` → `nCon == 1 + n`. `[~,~] = objective(x)` twice with `hasObjGrad = false` → `nFun` unchanged on the second call.

---

### D13. [Medium] Barrier-stall relief is unreachable on a well-centred iterate; barrier gate and termination disagree on scaling

**Where.** `solve.m:1131-1132`:
```matlab
structStall = iter > 0 && mu > opts.muMin && compErr > opts.compTol && ...
              compErr <= gateBase && feasErr <= feasAdmit && statErr > gateBase;
```
`compErr = compInfNorm(..., mu)` (`:1068`) is the **mu-perturbed** complementarity `|s·λ − mu|`, while `compTol` is a tolerance on the **unperturbed** product `s·λ` (`ipRes`, `terminationCheck`). Condition (c) therefore reads "the iterate is off-centre by more than compTol". On a well-centred iterate with mu = 1e-3, `compErr ≈ 0 < compTol`, so (c) fails and the relief never fires, even though unperturbed complementarity is 1e-3 ≫ compTol and mu must still come down. The P1 comment (`:1101-1104`) argues mu "has no remaining job" once comp is within tolerance, but that is true of `res.comp`, not of `compErr`. The relief is thus live only on off-centre iterates, which is the opposite of the "on the central path" admission (a) it is paired with.

Separately, `:1074-1075` builds `Emu` from the unscaled `statW`, while `terminationCheck.m:58-60` divides by `sd = max(100, Σ|λ|/n_λ)/100`. With large multipliers (`sd = 10`) termination accepts `statW ≤ 10·optTol` but the Fiacco–McCormick gate still demands `statW ≤ kappaMu·mu`; near the end mu freezes above `compTol`, `comp` never passes, and the run grinds (the "frozen barrier" the `structStall` code works around). IPOPT uses the same `s_d`-scaled error in both places (eq. 5/7). `control_barrierUpdate.m:22-24` also reduces mu only once per call, where IPOPT loops while `E_mu(mu_new) ≤ kappa·mu_new`.

**Fix.**
- `:1131`: replace `compErr > opts.compTol` with `res.comp > opts.compTol` (the unperturbed quantity already computed in `ipRes`), or simply `mu > opts.compTol`.
- `:1074`: `statW = norm(optW .* rdMetric, inf) / kktScaleFactor(state);` and `compErr = compErr / kktScaleFactor(state);` (`kktScaleFactor` exists at `:3211`).
- `control_barrierUpdate`: let the caller loop `while Emu <= kappaMu*mu && mu > muMin, mu = ...; Emu = max(statW, feasErr, compInfNorm(..., mu)); end` (comp is the only mu-dependent block and is cheap).

**Tests.** A fixture with `s.*lamI == mu` exactly (centred), `mu = 1e-3`, `statErr = 100*gateBase`, `feasErr = 0`: assert `structStall` is true. `termFixture` with `lamE = 1e4*ones` (`sd = 100`): assert the barrier reduces when `statW/sd <= kappaMu*mu`.

---

### D14. [Medium] No κ_Σ safeguard on the bound and slack multipliers

**Where.** `solve.m:1585-1587` updates `lamI`, `zL`, `zU` with no projection. IPOPT (eq. 16, κ_Σ = 1e10) resets `z_i ← max(min(z_i, κ_Σ·mu/(x_i−l_i)), mu/(κ_Σ·(x_i−l_i)))` so `Σ = Z/(X−L)` stays within a factor κ_Σ of the primal barrier Hessian `mu/(x−l)²`. Without it a lagging `z` feeds a wrong Σ into W for many iterations; this is precisely the "lagging bound dual" symptom the `activeBnd` machinery, Fix F and the barrier-stall override (`:671-707`, `:822-850`, `:1084-1140`) were written to paper over.

**Fix** (after `:1587`, with the updated `x`, `s`):
```matlab
kS = 1e10;  dxlN = x - lb;  dxuN = ub - x;
zL(finL) = min(max(zL(finL), mu ./ (kS*dxlN(finL))), kS*mu ./ dxlN(finL));
zU(finU) = min(max(zU(finU), mu ./ (kS*dxuN(finU))), kS*mu ./ dxuN(finU));
lamI     = min(max(lamI, mu ./ (kS*s)), kS*mu ./ s);
```
**Test.** An HS problem with an active bound: assert `max(zL.*dxl)/mu <= kS` on every trace row; compare iteration counts on the orbit case.

---

### D15. [Medium] Warm-started regularization is applied before the first factorization; Fix-A γ never vanishes

**Where.** `solve.m:2160-2163` decays `reg0.delta/10`, `reg0.gamma/10` and passes them in; `kkt_inertiaCorrection.m:84` `reg = reg0;` → `:102` the first `kkt_assemble` already uses them. IPOPT (Alg. IC) always tries δ_w = 0 first; δ_last only seeds the *first retry* (`max(δ_min, δ_last/3)`). Here, once any iteration needed δ, every later iteration carries δ_last/10, /100, … for ~300 iterations, degrading Newton's quadratic rate to linear; a stale γ perturbs the feasibility row `JE dx − γ dλ = −cE` on every subsequent iteration even when K is well-posed. `testCorrectedRegularizationIsReusableAsAWarmStart` pins this behaviour.

`kkt_inertiaCorrection.m:291-294` `gamma = target − sMinSigned` depends only on cond(S), not on convergence. In the near-null direction of S, `dλ ≈ r/(sMin+γ)` so `γ·dλ → r`: that constraint component is not reduced by the step at all, so feasibility plateaus at `feasRowRes ≈ γ‖dλ‖` for the rest of the run on any problem whose Schur complement stays ill-conditioned (the orbit multiple-shooting plateau in the project notes). IPOPT's δ_c = 1e-8·mu^0.25 vanishes with mu; the package's own `degeneracy_regularizedRecovery.m:36` ties its γ floor to the residual norm for the same reason. `dualRegFromSchur` is also O(n³) (`W \ JE'` dense) on every call, gated only on `mE ≤ 400`.

**Fix.**
- `kkt_inertiaCorrection`: factor once with `reg = struct('delta', 0, 'gamma', gammaFixA)`; only if inertia/pivot fails set `reg.delta = max(1e-8, reg0.delta/3)` (else `1e-4·scale`) and grow ×8; drop the /10 decay in `solveStep`. Change the warm-start test to assert `tries <= 1`.
- Scale the Fix-A shift by convergence: `gamma = min(gamma, max(1e-8, kappaG * norm(res.rFeasE, inf)))` (κ_G ≈ 1e-2…1), or multiply by `mu^0.25` in the IP core.
- Replace the dense probe with one that reuses the LDL factors: with γ = 0, `S⁻¹ = −(K⁻¹)₂₂`, obtainable from mE solves against the existing factors, and only extreme eigenvalues are needed (`eigs(..., 1)`).

**Tests.** SPD H, full-rank JE, `reg0 = (1e-2, 1e-2)` → returned `reg == (0, 0)` and `d` equals the unregularized solve. 2-variable, 1-constraint fixture with `JE = [1 1e-5]`, `rFeasE = 1e-9` → `reg.gamma <= 1e-7`.

---

### D16. [Medium] No iterative refinement after the LDL solve; zero-pivot tolerance too strict by a factor N

**Where.** `linalg_solveKKTdirect.m:79-82` solves once and returns; RCOND warnings are silenced (`:75-78`). `:136` `tol = k * eps * maxAbsPivot` with `k = n + mE`.

**Why.** IPOPT performs up to 10 refinement steps gated on `residual_ratio_max = 1e-10`; one step is O(N²) against the O(N³) already paid and routinely recovers 3–6 digits on KKT systems with pivot spread 1e8–1e14, the normal regime here (W contains Σ terms that blow up as mu → 0). `k·eps·σ_max` is the SVD rank tolerance; LDL pivots are not singular values. With N = 500 and primal pivots ~1e9 the tolerance is ~1e-4, so a healthy constraint pivot of 1e-4 (the stiff-orbit case in the `kkt_inertiaCorrection.m:116-118` comment) is counted zero → `rankDeficient` → dense `lsqminnorm` (O(N³) SVD) → the inertia loop grows both δ and γ on a step that was fine.

**Fix** (after `:82`):
```matlab
for it = 1:2
    r = rhs - A*d;
    if norm(r, inf) <= 1e-13 * max(1, norm(rhs, inf)), break; end
    d(p) = d(p) + (L.' \ (D \ (L \ r(p))));
end
info.resRel = norm(rhs - A*d, inf) / max(1, norm(rhs, inf));
```
and `:136` `tol = 10 * eps * maxAbsPivot;`. Also force `K = full(...)` in `kkt_assemble.m:69-70` when `~issparse(H)` (concatenating a dense H with a sparse JE yields a sparse K with a dense block; MA57 is then slower than LAPACK and can report a different inertia).

**Tests.** `K` with `pivotSpread ≈ 1e12` (`H = diag(logspace(0,12,n))`): `norm(K*d - rhs)/norm(rhs) < 1e-12` (today ~1e-5). Saddle system with a 1e-4 constraint pivot and N = 600: `info.rankDeficient == false`.

---

### D17. [Medium] SOC and inertia retries re-factor from scratch; SOC corrects only the equality rows and walks the wrong direction

**Where.** `solve.m:1386-1394`: each SOC iteration builds `cstateS`, `cresS` with only the RHS changed and goes through `detectStep` → `kkt_inertiaCorrection` → `kkt_assemble` + `ldl` + the O(n³) Fix-A probe (`kkt_inertiaCorrection.m:97`). With `reg0 = ksolve.reg/10` the matrix even differs slightly from the one that produced `dx`. `:1387` `xt = x + aFTB * dx` evaluates along the *original* direction for `socIt >= 2` (WB evaluate along the corrected direction `d_cor`). `:1398` `dsC = -rpI - JIdxC` leaves the slack rows uncorrected, so for inequality-dominated curvature (the LVD case) SOC cannot remove the Maratos effect it exists for. The trigger (`:1383`, `aP < 0.1·aMax0`) fires only after the full backtracking collapse (~33 trials) and then runs a *complete* line search per corrected direction, up to 4 times plus 2 extra `ptC` evaluations each: worst case ~140 extra user evaluations per iteration. WB apply SOC when the *first* trial is rejected by θ and accept the corrected step only at its full fraction.

**Fix.**
1. Return the factors from `linalg_solveKKTdirect` (`info.L, info.D, info.p`) and add `linalg_resolveKKT(info, rhs)` (the four lines at `:79-82`). SOC re-solves call it with `-[r1; cSocE]`; cache Fix-A's `gammaScale` on `ksolve` per iteration.
2. `xt = x + aFTB * dxC` for `socIt >= 2`; accumulate `cSocI = aFTB*cSocI + (cIt + sC)` and use `dsC = -cSocI - JIdxC`, feeding `r1` through `JI'*(sigS.*cSocI - rc_s./s)`.
3. Have `globalize_filterLineSearch` return the first trial's `(phiT, thetaT)` and a `firstRejectedByTheta` flag; run SOC immediately after that first rejection, evaluate `ptC(aC)` once and test it with the same acceptance rule (expose it as `globalize_filterTryStep`), and only if all corrections fail continue ordinary backtracking from `0.5·aMax0`.

**Tests.** Trace `nSolves == 1` on an iteration with `socAdopted == 1` once factors are reused. Maratos example `min 2(x1²+x2²−1) − x1 s.t. x1²+x2² = 1` from a point on the circle near the solution: full step accepted after one SOC, `ev.totalEvals()` ≤ baseline/3.

---

### D18. [Medium] Filter line search: veto gates f-type trials, `thetaMin` is not fixed per barrier problem, no WB α_min

**Where.** `globalize_filterLineSearch.m:88` `if thetaT <= thetaCap && filter.isAcceptable(thetaT, phiT)` gates both branches. `:68` `thetaMin = 1e-4 * max(1, theta0)` with `theta0` the *current* violation (WB: `θ_min = 1e-4·max(1, θ(x_0))`, fixed per barrier problem); algebraically `theta0 ≤ thetaMin ⇔ theta0 ≤ 1e-4`, a constant. Same at `solve.m:420` and `:1225`. `:69` `amin = 1e-10` with no WB eq. 23 α_min.

**Why wrong.** WB's answer to "θ-type accepts any φ decrease for a large θ increase" is the switching condition: when `θ0 ≤ θ_min` the trial is judged by Armijo on φ and θ may grow up to θ_max, which is what avoids the Maratos effect. `thetaGrowCap = kappaThetaGrow·max(theta0, feasTol)` collapses to 1e-4 at a feasible iterate, so a full Newton step along a curved equality (`θ_t ~ curvature·‖dx‖² ~ 1e-2` for ‖dx‖ = 0.1) is vetoed, α is cut to ~0.1, and SOC (D17) then runs on every such iteration. With `thetaMin` effectively 1e-4, Case I is unavailable for `θ0 ∈ (1e-4, …)`, so on row-scaled problems where `θ(x0) ~ m` every step before `θ ≤ 1e-4` is θ-type and augments the filter. Without α_min every stalled line search burns ~33 trial evaluations where WB stop after ~20 or far fewer when `gd` is small; for LVD that is 13+ propagations per stall.

**Fix** (`globalize_filterLineSearch.m:84-103`):
```matlab
if nargin < 10 || isempty(thetaMin), thetaMin = 1e-4 * max(1, theta0); end   % new 10th arg: filter.thetaMin
gammaAlpha = 0.05;
if gd < 0
    aminWB = min(filter.gammaTheta, filter.gammaPhi * theta0 / (-gd));
    if theta0 <= thetaMin, aminWB = min(aminWB, delta * theta0^sTheta / (-gd)^sPhi); end
else, aminWB = filter.gammaTheta; end
amin = max(1e-10, gammaAlpha * aminWB);
...
    if filter.isAcceptable(thetaT, phiT)
        switching = gd < 0 && theta0 <= thetaMin && alpha * (-gd)^sPhi > delta * theta0^sTheta;
        if switching
            if phiT <= phi0 + etaPhi * alpha * gd, augment = false; return; end
        elseif thetaT <= thetaCap                                  % veto only theta-type trials
            if thetaT <= (1 - filter.gammaTheta) * theta0 || phiT <= phi0 - filter.gammaPhi * theta0
                augment = true;  return;
            end
        end
    end
```
Add a `thetaMin` property to `Filter.m`, set it in `makeFilter` from `θ(x0)` and re-set it when mu decreases (`solve.m:1164`), and pass `filt.thetaMin` at `solve.m:490`, `:1373`, `:1421`; use the same for `thetaMinNT`/`thetaMinNT_IP`.

**Tests.** `theta0 = 0, gd = -1, phi(a) = 10 - a, theta(a) = 1e-2·a², cap 1e-4` → `alpha = 1, augment = false` (today backtracks to 0.1). Keep `testThetaCapVetoesAFeasibilityBlowUp`. Worse-in-both model with `gd = -1, theta0 = 1`: `phiTheta` call count ≤ 22, not 34; `lsFailed` still true.

---

### D19. [Medium] NT trust-region inner loop (opt-in `useNTdecomp`)

**Where.** `solve.m:455-457` (eq) and `:1276-1278` (IP): `control_trustRegionUpdate` runs *before* `if ok && tr_ok`. When the filter/merit rejects (`ok` false) but the merit ratio is good, Δ is unchanged or expanded; `computeNTStep` is deterministic in Δ, so the remaining `trMaxInner−1` iterations recompute the identical step and re-evaluate the identical trial (19 wasted NT solves). On exit with `~stepAccepted` the IP core (`:1286-1312`) always recomputes a KKT step and accepts it through the merit `ipLineSearch`: a step the filter just rejected is taken by the merit rule and never augmented. In the NT branches `isSwitching → ok = true` skips `filt.isAcceptable` entirely (θ_max and the cap are bypassed for f-type steps); merit mode sets `rho = max(rho, ‖λ‖+1e-2)` without the `gd/θ` term so `dphi` can be positive and `globalize_meritAccept` accepts increases (`control_penaltyUpdate` exists for this and is unused here). `:1278` passes `aP·norm(dx)` so expansion (`pNorm ≥ (1−1e-10)Δ`) is impossible whenever `aP < 1`. `solve.m:2692` passes the full Δ to the normal step, so when `‖v_GN‖ ≥ Δ` the tangential radius is 0 and the step has no objective component (Byrd–Omojokun/KNITRO use `‖v‖ ≤ 0.8Δ`).

**Fix.**
```matlab
if ~ok, Delta = opts.trShrink * Delta;  continue;  end     % globalization rejection shrinks too
[Delta, tr_ok, ~] = control_trustRegionUpdate(Delta, predRedM, actRedM, norm(dx), opts);
```
use `control_penaltyUpdate` for ρ in the merit branch; in the switching branch still require `filt.isAcceptable`; on `~stepAccepted` in the IP core route to `globalize_filterLineSearch` when `useFilter`; `v = step_normalStep(JE, cE, 0.8 * Delta)` in `computeNTStep` (optionally `opts.ntZeta`).

**Test.** Stub `filt.isAcceptable = false`; assert Δ decreases monotonically through the inner loop and the fallback step is filter-checked. `step_normalStep` with `‖v_GN‖ ≫ Δ` → `‖v‖ ≤ 0.8Δ` and `u ≠ 0` on `min x'x s.t. x1+x2 = 10`, Δ = 1.

---

### D20. [Medium] Restoration can declare local infeasibility on a feasible problem

**Where.** (a) `solve.m:508-509` / `:1520-1521`: `rinfo.theta >= restTheta - opts.feasTol` compares against the exit θ of the *previous* restoration, possibly hundreds of iterations earlier at a different point; a second restoration that ends slightly higher than the first kills the solve with -2 even though `rinfo.reduced` is true. (b) `degeneracy_restorationPhase.m:89,110`: `dx = lsqminnorm(J, -cvec)` is a Gauss–Newton (2-norm) direction but acceptance is Armijo on the l1 θ; for rank-deficient J (the degenerate case restoration exists for) `d/da‖c + aJdx‖₁ = −sign(c)'Pc` has no sign guarantee, every `a` can fail, `reduced = false`, and the caller returns -2.

**Fix.** (a) Replace the cross-restoration comparison with a per-call relative requirement plus a consecutive-failure counter: `restFail = restFail + ~(rinfo.theta <= 0.9*rinfo.theta0); if rinfo.theta > feasTol && restFail >= 2, exitflag = -2; end`, resetting `restFail = 0` when `bestFeas` improves. (b) Make the acceptance norm match the model (`norm(cvecTrial) < (1 − 1e-4·a)·norm(cvec)`; GN guarantees descent in the 2-norm), keep `info.theta` in l1 for the caller, and stop with `info.stationary = true` when `‖J'c‖ ≤ 1e-10·max(1,‖c‖)` (a genuine local-infeasibility certificate), so the caller's -2 is grounded in a certificate rather than a failed Armijo.

**Tests.** `restStallWindow = 1` on `unitDiskIneq` from a far start (forces two restorations): `exitflag > 0`. `cE = [x1−1; 2(x1−1); x2+3]` (rank-2 J, consistent) from `[5; 5]`: `info.reduced` and `info.theta < feasTol`; inconsistent `[x1−1; x1−2]`: `info.stationary`.

---

### D21. [Medium] A failed LVD propagation crashes the solve instead of poisoning the trial point

**Where.** LVD `ConstraintSet.m:~165-171` `catch ME; c = NaN; ceq = NaN; return;` (scalars, not `mInl×1`/`mEnl×1`). `Evaluator.m:704-706` `[c, ceq] = obj.nlcon(x); c = c(:); ceq = ceq(:);` has no size check. In `finiteDiffJacobian` (`h(xp) − base`) and `Evaluator.constraints` (`cI + s`) the length mismatch raises "Arrays have incompatible sizes" and nothing catches it (`lvd_executeOptimProblem.m:42` lets it propagate). In the line search a scalar NaN broadcasts and is rejected (all filter comparisons are false on NaN), so the crash is specific to FD probes and accepted steps. ODE failures on FD probes near a bound (impact, negative mass) are routine in LVD.

**Fix** (`Evaluator.m:704`):
```matlab
[c, ceq] = obj.nlcon(x);  c = c(:);  ceq = ceq(:);
if numel(c)   ~= obj.mInl, c   = NaN(obj.mInl, 1); end   % failed / odd-shaped evaluation: poison, do not crash
if numel(ceq) ~= obj.mEnl, ceq = NaN(obj.mEnl, 1); end
```
In `finiteDiffJacobian`/`fdBoundedStep`, when a forward probe returns non-finite, retry the opposite side once before letting a NaN column reach the KKT system (which then exits -3 via `terminationCheck`). Add `isfinite(d)` checks after each `detectStep` in `solve.m` (D30).

**Test.** nonlcon that returns scalar NaN when `x(1) > 0.9`; start at 0.85; assert the solve returns (any exitflag) rather than erroring.

---

### D22. [Medium] Dual step taken in full when the primal line search failed; equality multipliers use `aD`

**Where.** `solve.m:1583-1587`: `aLamE = dualStepCoeff(aD, ...)`, `lamI += aD*dlamI`, `zL/zU += aD*dz`. `aD` is the fraction-to-boundary of the dual variables (≈1), independent of `aP`. On an `lsFailed` iteration that does not meet the restoration gate, `aP = 1e-10` so x does not move, yet every multiplier takes the full Newton dual step computed under the assumption that x moves by `dx`. IPOPT (eq. 14) uses `α_k` for `y` (lamE/lamI) and `α_z` only for bound duals. The comment at `:1575-1582` defends `aD` for lamE on measured grounds for accepted steps; after the step the stationarity residual is `(1−aD)·r1 + (aP−aD)·W·dx`, which with `aP ≪ aD = 1` is ≈ `−W·dx`, not a contraction, and is the lamE jump Fix B was later added to cap.

**Fix (minimal).** `if lsFailed, aD = aP; end` before `:1583`. Optionally offer the IPOPT convention (`lamE/lamI` with `aP`, `z` with `aD`) behind an option and re-run the benchmark battery; keep Fix B either way.

**Test.** Drive one IP iteration with a `phiTheta` stub that rejects everything: `norm(lamE_new − lamE) ≤ 1e-9` and x unchanged.

---

### D23. [Medium] Penalty parameter only grows, unbounded as θ → 0, for the whole solve

**Where.** `solve.m:1921-1923` (`ipLineSearch`), `:2635-2637` (`lineSearch`), `:437`, `:1259` (NT), `control_penaltyUpdate.m:26-29`: `rho = max(rho, gd/theta + 1e-2)`, unbounded as θ → 0 (θ = 1e-12, gd = 1e-3 → ρ = 1e9) and persisting across all later iterations and barrier subproblems (also feeding `rhoTR`). In `globalization = 'merit'` this is the classic over-penalised stall: later trials that trade 1e-9 of θ for objective progress are rejected.

**Fix.** Recompute non-monotonically each iteration (KNITRO / Byrd–Nocedal–Waltz): `rho = max(multInfNorm + buffer, gd/theta + buffer)` without `max(rho, ·)`, or at minimum reset `rho = 1` whenever mu decreases (next to `filt.reset()` at `:1164`). Guard the `gd/theta` term: `if theta > feasTol`.

**Test.** `ipLineSearch` twice: (θ = 1e-12, gd = 1e-3) then (θ = 1, gd = −1); the second ρ is O(‖λ‖), not 1e9.

---

### D24. [Medium] `returnIterate = 'bestKKT'` ignored on a user stop (LVD Cancel)

**Where.** `solve.m:1040` `elseif keepBestKKT && ef == 0 && ...`. The Cancel path (LVD `AdamNlOptOptimizer.m:269` → IterationFcn → exitflag -1) is exactly the "stopped mid-wander" case the option exists for.

**Fix.** `(ef == 0 || ef == -1)`; update `defaultOptions.m:506`. **Test.** IterationFcn returning true at iteration 30 on the oscillating fixture used by `testFiniteDivergeWindowArmsTheDivergenceExit`; returned opt ≤ opt at iteration 30.

---

### D25. [Medium] Broyden refresh test is scaled by constraint value, so it never fires near feasibility

**Where.** `eval_BroydenJacobian.m:117` `resRel = norm(res) / max(1, norm(cNew(:)))` with `res = y − J·s`. As `‖cNew‖ → 0` the denominator pins at 1 and the test becomes absolute on `‖y − Js‖`, tiny simply because y and Js are tiny; the model can be 100% wrong and pass until `maxStale = 20`. With constraints O(1e6) a 10% tolerance admits `‖y − Js‖ ≤ 1e5`.

**Fix.** `scale = max([norm(yy), norm(obj.J_*ss), realmin]); resRel = norm(res)/scale;` drop the `cNew` argument. If Broyden stays (opt-in after D1), also lower `broydenMaxStale` to 5 and restrict it to feasibility-dominated iterations (`feas > lsRefreshDomRatio·opt`), refreshing exactly when switching to the optimality phase.

**Test.** Same (s, y, J) with y and J scaled by 1e6 and 1e-6 gives the same accept/refresh verdict.

---

### D26. [Low] Returned `hessian` is the model before the last secant update

**Where.** `solve.m:413` / `:1168` `hessian = H` is set at the top of the iteration; `updateHessianModel` runs at the foot. Verified: on `f = x'·diag([1 10])·x/2` the returned H was `[1.0023 0.023; 0.023 10.23]` while `output.hessianModel.getMatrix()` at exit was `[1.0029 −0.014; −0.014 10.07]`. After a snapshot rollback the Hessian is from yet another point.

**Fix.** At both core exits: `if ~isempty(hmodel), hessian = hmodel.getMatrix(); end`.

---

### D27. [Low] Armijo/merit tests accept an increase when θ0 = 0 and gd ≥ 0

**Where.** `globalize_filterLineSearch.m:109-117` (merit backup), `solve.m:1922-1926` (`ipLineSearch`), `:2636-2641` (`lineSearch`): the ρ update enforces `dphi < 0` only when `θ > 0`. With `θ0 = 0` and `gd > 0` (indefinite or inexact step), `dphi = gd > 0` and `phit <= phi0 + c·alpha·dphi` accepts a strict increase.

**Fix.** After the ρ update in all three places: `if dphi >= 0, alpha = min(amin, aMax); lsFailed = true; return; end` (eq/IP line searches return `alpha = amin` so the caller's restoration/stall logic fires).

**Test.** `theta0 = 0, gd = +1, phi(a) = 10 + 0.5a, theta(a) = 0`: expect `lsFailed`.

---

### D28. [Low] Normal step takes the full trust radius

See D19 (ζ = 0.8 in `computeNTStep`).

---

### D29. [Low] Stale state after restoration; `plotInfo` bound "violation"

- `solve.m:525-527`, `:1566-1568`: `stepNorm` is not reset, so `terminationCheck.m:170-173` tests the pre-restoration step against the restored iterate and can stop with exitflag 0/2 before a step is tried. Fix: `stepNorm = inf;` in both blocks.
- `solve.m:1543-1552`: IP restoration re-seeds `s, lamI, zL, zU` but not `lamE` (eq core does at `:524`). Fix: `if mE > 0, lamE = step_multiplierUpdate(g − zL + zU + JI.'*lamI, JE, optW); end`.
- `plotInfo.m:99-104`: `viol = [...; boundLb; boundUb]` adds the positive *distance inside* the bounds, so `constrviolationPhys` is 1.0 for a variable mid-box in [-1,1]. Fix: `max(-boundLb, 0); max(-boundUb, 0)`. This also unblocks using it for D3.

---

### D30. [Low] Non-finite K spins 40 factorizations and returns a NaN step unguarded

**Where.** If W contains Inf/NaN (`sigL = zL./dxl` with `dxl = 0` after an external x or restoration), `ldl` returns NaN D, `blockInertia` counts (0,0,0), `kkt_inertiaCorrection.m:135` runs all 40 tries, and `solve.m` never checks `isfinite(d)`; `step_fractionToBoundary` with NaN `dv` gives `aP = 1` → `x = NaN`.

**Fix.** `kkt_inertiaCorrection` after `:102`: `if ~all(isfinite(nonzeros(K))) || ~all(isfinite(rhs)), d = zeros(size(rhs)); info.solved = false; info.triesExhausted = true; info.nonFinite = true; return; end`; `linalg_solveKKTdirect.m:83` `info.solved = all(isfinite(d))`; in `solve.m` after each `detectStep`: `if ~all(isfinite(d)), stop with ef = -3 (or enter restoration); end`.

---

### D31. [Low] Option, dead-code and consistency hygiene

| Item | Where | Fix |
|------|-------|-----|
| `lsRefreshFeasTol` defined, exposed in LVD options/GUI, never read | `defaultOptions.m:683`, LVD `AdamNlOptOptions.m:111,209`, GUI row | Delete from all three (mapOptions warns on unknown names, so together); `loadobj` no-op guard |
| Selector strings unvalidated: `globalization`, `linearSolver`, `precondition`, `autoScale`, `FiniteDifferenceType`, `Display` typos silently change the algorithm (`'fliter'` → merit; `'iter-detailed'` → prints nothing) | `mapOptions.m:111-142` | One `validatestring` loop over the selector table; map fmincon `iter-detailed → iter`, `final-detailed/notify → final` |
| NaN bounds / NaN `b`, `beq` accepted | `validateProblem.m:138` | `any(isnan(lb)) || any(isnan(ub))` → error; `all(isfinite(v))` in `checkLinear` |
| Dead modules: `util_scaling.m`, `estimateNoise.m` + `ecnoiseCore.m` (superseded by `calibrateStep`), `parallel_asyncEvaluator.m`, `parallel_batchEvaluate.m` (`'async'` is folded into `'finitediff'`; `fetch` blocks with no timeout; uses `ver` not `license`) | no production callers | Delete with their tests, or wire `estimateNoise` into A7 |
| `diagnose` advises "tighten feasTol" when feasibility lags | `diagnose.m:172` | "enable restoration, lower `kappaThetaGrow`, start closer to feasibility" |
| Filter margin applied twice (stored shifted corner *and* shifted again on acceptance) | `Filter.m:107-110`, `globalize_filterAccept.m:32-33` | Accept with plain `theta >= thetaJ & phi >= phiJ`; update the two hand-built-entry tests |
| Active-set confidence and weak-activity use absolute scale `max(1, ‖λ‖)`; problems with multipliers ~1e-3 can never reach `nearBoundary` | `control_activeSetConfidence.m:52,59`, `degeneracy_detectDegeneracy.m:83-84` | `lamScale = max(norm(lamI,inf), max(mu, eps))`, or judge by `s_i·λ_i` vs mu |
| IP core passes `cstate = struct('H','JE','x','lamE')` so degeneracy detection and elastic mode never see `cE/cI/JI/lamI` (only `linDepE` can route) | `solve.m:1320-1321` | Pass the full fields (all in scope) |
| Elastic "inconsistent" certificate is penalty-based (`penalty <= 1e-8·n`) and fires on consistent systems with `‖cE‖ ~ 1e4` | `degeneracy_elasticVariables.m:163`, `solve.m:2803-2806` | Decide by residual of the min-norm solve: `norm(cE + JE·lsqminnorm(JE,−cE), inf) > 1e-8·max(1,‖cE‖∞)` |
| `kkt_residual.rComp` omits bound complementarity though `rStat` includes zL/zU | `kkt_residual.m:55-56` | Add the bound terms or document "equality/inequality only" and assert |
| `linalg_preconditioner.m:47` errors on an operator struct without `.diag` | | `isfield(op,'diag') && ~isempty(op.diag)` |
| `output.trace` is in scaled coordinates with no flag | `unscaleResult.m` | `output.scaling.traceIsScaled = sc.applied` |
| Fixed variables: `grad(i) = NaN` and `lambda.lower/upper(i) = 0` when the objective has no analytic gradient (verified: `grad(2) = NaN`, both multipliers 0 on a 4-variable fixture) | `expandResult.m` | One FD evaluation per fixed variable at exit fills `grad` and lets the bound multiplier absorb it, matching fmincon |
| `maxTime` is tested only at the top of an iteration, so one long iteration (FD gradient + Jacobian + line search + SOC) overruns it; found in the baseline: TwoStageToOrbit stopped at 1308 s against `maxTime = 900` | `terminationCheck.m:206-215` | Give the Evaluator a deadline (`ev.deadline = tStart + maxTime`); when a user call starts past it, raise `adamnlopt:timeLimit`, catch it in both cores, and exit 0 at the last accepted iterate |
| Wrong user `JacobPattern` silently yields a wrong Jacobian | `finiteDiffJacobian.m:70-72` | Optional one-shot dense check on the first Jacobian (`CheckJacobPattern`, default on for n ≤ 400) |

### D32. [Medium] LVD cases saved before AdamNlOpt existed share one AdamNlOpt optimizer object

Found while attributing Batch 1's LVD results. `LvdOptimization.m:23` declares `adamNlOptOpt(1,1) AdamNlOptOptimizer = AdamNlOptOptimizer();`. MATLAB evaluates a handle-valued property default once per class load and hands the same object to every instance that does not set its own. The constructor (`:61`) does assign a fresh one, but `load` never runs the constructor, and a `.mat` saved before AdamNlOpt was added has no stored `adamNlOptOpt`. Verified in MATLAB: `lvdExample_MunarLanding` and `lvdExample_TwoStageToOrbit` loaded in one session return the same `AdamNlOptOptimizer` handle and the same `AdamNlOptOptions` handle, while their `fminconOpt` objects are distinct.

**Failure.** With two older cases open, changing an AdamNlOpt option in one changes it in the other, and saving either case writes that value into it. In a headless batch, an option set for one case leaks into every later case.

**Fix.** In `LvdOptimization`, keep the constructor assignment and add to its `loadobj` (create one if absent):
```matlab
function obj = loadobj(obj)
    % A handle default is shared by every instance loaded without its own copy.
    obj.adamNlOptOpt = AdamNlOptOptimizer.cloneFrom(obj.adamNlOptOpt);
end
```
where `cloneFrom` builds a new `AdamNlOptOptimizer` and copies the option property values (a `copy` method on `AdamNlOptOptions`, which is a `SetGet` handle, does this). Check the other optimizer properties declared the same way. Only `adamNlOptOpt` was confirmed shared, but any optimizer added after the example files were saved has the same exposure.

**Test.** Load two pre-AdamNlOpt examples; assert their `adamNlOptOpt` handles differ; set `maxIter` on one and assert the other is unchanged.

### D33. [High] The step-size exit reports convergence before the barrier is finished

Found while landing D3. `terminationCheck.m` step-size exit (exitflag 2, "Converged: step size ... below StepTolerance") required feasibility and `optScaled <= objPlateauOptTol`, but not complementarity. In the interior-point core a zero step only means the current barrier subproblem is solved; while mu can still fall, the next barrier update moves the iterate. On `min (x-3)'(x-3) s.t. x1 + x2 = 2, 0 <= x <= 10` the Newton step is exact, so the step collapses after two iterations. The solve then returned exitflag 2 with complementarity 2e-2 (tolerance 1e-6) and λ = 4.018 against the analytic 4. With the old row scaling it happened to stop at complementarity 2.8e-3, which is why `testNTDecompInteriorPointCoreMatchesDefaultPath` (λ tolerance 1e-2) used to pass.

**Fix (applied in Batch 3).** The step-size exit additionally requires `compScaled <= compTol`, or `mu <= muMin` (when mu can fall no further the exit is allowed again, so a genuine stall still stops). Guard: `testD33StepExitWaitsForTheBarrier` (exitflag > 0, complementarity ≤ 1e-5, λ = 4 ± 1e-4).

### T1. [Test hygiene] `testOptionsStructAndOptimoptionsObjectAgree` is Incomplete under a license-test/checkout mismatch

`license('test', ...)` reports 1 but `optimoptions` cannot check out. Replace the guard with `try, optimoptions('fmincon'); catch, testCase.assumeFail('optimoptions unavailable'); end`.

---

## 3. Algorithm improvements

### A1. FD-accuracy-aware termination and automatic forward → central promotion

**Observed.** Rosenbrock n = 10 from −2 with FD gradients (`autoFDStep` on or off, `fdType` forward): 49 iterations, f = 2.3e-10, then **exitflag 0** with "step size 4.4e-17 below StepTolerance … first-order optimality 3.80e-05 is above 3.0e-06". The point is converged to the accuracy forward differences can deliver (curvature ~1e3 × h = 1.5e-8 → gradient error ~1e-5), but the solver reports failure, which LVD treats as a failed run. The same problem with `FiniteDifferenceType = 'central'` converges with exitflag 1 (opt 3.8e-7), and with analytic gradients in 50 iterations and 116 evaluations. The noisy 5-variable test in Section 0 showed the same pattern (opt 3.03e-6 against a 3.0e-6 gate → exitflag 0).

**Implement.**
1. Expose the gradient error estimate the calibration already computes (`output.fdCalibration.errFwd/errCen`, or `fdStep·max(1,|x|)·‖H‖` when uncalibrated) as `ev.gradErrEst`.
2. In the IP and eq cores, when `stepNorm` collapses (`stepTol` exit path) or `optGateCount` stalls at a feasible point with `res.opt ≤ κ_g·ev.gradErrEst` (κ_g ≈ 10): if `ev.fdType == 'forward'` and `~ev.fdTypeUserSet`, promote to central (`ev.setFd('central', h_c)` with `h_c = sqrt(fdStep)` or the calibration's central pick), clear the gradient cache, reset the BFGS model's scaling (not its pairs), and continue; log `trow.fdPromoted = 1`.
3. If already central (or the user pinned the type) and the same condition holds, stop with **exitflag 2** and a message "converged to finite-difference accuracy (estimated gradient error %.1e > optTol)". This is fmincon's behaviour in spirit and avoids the false "stalled" verdict.

**Test.** Rosenbrock n = 10 with FD gradients returns exitflag > 0 and f < 1e-8; a trace row shows `fdPromoted`.

### A2. One combined FD sweep for gradient and Jacobian (halves LVD propagations)

LVD's `LvdOptimization.propagateForX` is a single-entry same-x cache: `objFun(z)` immediately followed by `nlcon(z)` is one propagation. The Evaluator defeats it: `objective()` walks n perturbed points, then `jacobian()` walks the same n points again → 2n propagations where n suffice. `parallel_parallelFiniteDiff` already supports both handles in one task (`:203-204`) but the Evaluator always passes `[]` for one of them.

**Implement.** When `~hasObjGrad && ~hasConGrad`, difference the stacked vector `v(z) = [objFun(z); evalNonlinearStacked(z)]` once (pattern `[true(1,n); jacPattern]` if a pattern exists; parallel path: both handles) and populate both caches (`gVal/hasCachedG`, `xj/JEVal/JIVal`). Trigger from `objective(x)` with `nargout > 1`, the first derivative request at a new x in every `objective → constraints → jacobian` sequence in `solve.m`, so the later `jacobian(x)` is a cache hit. Counting stays exact (`nFun += nProbes`, `nCon += nProbes`). Expected ~2x per LVD iteration in BuiltIn mode. **Test:** shared counter that increments only on a new z equals n+1 per derivative evaluation.

### A3. Warm start from a previous LVD run

`initializeIterate.m:67-70` always seeds `lamE = 0`, `lamI = mu0./s`, `zL/zU = mu0/dist`, `mu = mu0 = 0.1`; `solve.m:621` already guards the LS seed on `~any(lamE)` "so a future warm start is never overwritten". LVD users re-run the same mission after small edits; every run spends ~10 iterations rebuilding costates and the barrier.

**Implement.** `opts.lambda0 = []` (fmincon-style struct) and `opts.muWarm = []`. In `initializeIterate`: map `eqlin/eqnonlin → lamE`, `ineqlin/ineqnonlin → max(lamI, 1e-8)`, `lower/upper → zL/zU`, scaled with `Dc/wf`, `Di/wf`, `Dx·wf` (inverse of `unscaleResult.m:54-59`) and sub-selected with `fx.free`; `mu = max(muMin, mean(s.*lamI))` when `muWarm` is empty. In the wrapper keep `lambda` from `adamnlopt.solve` (already returned at `lvd_executeOptimProblem.m:42`) in a private property keyed on `numel(x0All)` and `getNumConstraints()`, and pass it when they match. **Test:** re-solve from the solution with `lambda0` → `output.iterations ≤ 2`.

### A4. Watchdog and IPOPT filter-reset heuristic

No non-monotone watchdog exists: after a stall the solver takes a 1e-10 step (D6, D22). A 1–2 step Chamberlain watchdog before declaring `lsFailed` avoids most restoration entries on stiff cases ("steps bottomed out at 6.1e-5" in the `solve.m` comments). IPOPT's `filter_reset_trigger`: count consecutive iterations whose *first* trial was rejected by a stored filter entry (not by the current-iterate test); after 5, reset the filter (bounded `max_filter_resets`). Cheap once `globalize_filterLineSearch` reports which test rejected `cache(1,:)` (D17 needs the same plumbing).

### A5. Acceptable-point termination (IPOPT `acceptable_tol` / `acceptable_iter`)

Exitflag 1 is only at full tolerance; the plateau/step exits (exitflag 2) require `feas ≤ feasTol` and `optScaled ≤ 3·optTol` for 40/10 iterations, and on the orbit case the run grinds to 300 iterations at opt ≈ 1.6e-3. Add `acceptableTol = 100·optTol`, `acceptableIter = 15`: stop with exitflag 2 and a clear message when the acceptable level has held that long. Pair with a stationarity-stagnation rule in `control_modeController` (R3 flags θ stagnation only): no 1% improvement in `optScaled` over `stagnWindow` feeds the same exit, turning "stalled at opt = 1.6e-3" into a terminal diagnosis.

### A6. Restoration as Wächter–Biegler intend

`degeneracy_restorationPhase` minimizes θ only, ignores the filter and the objective, and returns any point with lower l1 violation; that is why the pre-restoration augment (D10, finding 57) is load-bearing. WB minimize `θ(x) + (ζ/2)‖D(x − x_k)‖²` and return a point acceptable to the filter. Minimal step: add the proximal term to the GN normal equations, `dx = (J'J + ζI)⁻¹(−J'c)`, and test filter acceptability of the returned point (loop until acceptable or θ ≤ feasTol). This also fixes D20(b).

### A7. Re-calibrate the FD step when the line search fails repeatedly

`calibrateStep` runs once at x0. On a trajectory problem the noise floor changes with the arc (burn vs coast). When `lsFailed` is true on `restStallWindow` consecutive iterations and `~ev.hasObjGrad`, call `ev.calibrateStep(x)` (≈ 36 evaluations), apply `fdStepTransfer`, clear the gradient cache, record `trow.fdRecalibrated`.

### A8. Derivative checker

LVD's `FiniteDifferences`/`DerivEst` modes hand adamnlopt gradients labelled analytic (`AdamNlOptOptimizer.m:67-70`). A one-shot `CheckGradients` option (default off, cost 2n evaluations): central-difference `finiteDiffGradient`/`finiteDiffJacobian` vs the supplied blocks, relative inf-norm, warning above 1e-3. Catches wiring/orientation bugs that the `transposeOrEmpty` shape check cannot.

### A9. Factor reuse and a cheaper Schur probe

Covered by D15–D17: return the LDL factors from `linalg_solveKKTdirect`, add `linalg_resolveKKT`, reuse them for iterative refinement, SOC re-solves, the dual-step cap of D5(2), and the Schur-complement conditioning probe (`S⁻¹ = −(K⁻¹)₂₂` from mE solves; `eigs` for the extreme eigenvalues). Cache `gammaScale` per iteration on `ksolve`.

### A10. LVD-specific defaults and wrapper economy

- `returnIterate = BestKKT` in LVD options (LVD runs end on `maxIter`/`maxTime`/Cancel far more often than exitflag 1; see D24).
- `objPlateauWindow = 15` (40 iterations × (n+1) propagations is minutes of wall time proving f is flat).
- GUI tooltips: `hessianApprox = Exact/FiniteDiffs` costs n·(n+1) propagations per iteration (D8); `numWorkers` is not read by adamnlopt (pool size comes from `gcp`).
- `AdamNlOptOptimizer.m:284` `[~, stateLog] = objFcn(x)` re-propagates the mission every iteration purely for the state readout, and the same-x cache misses because the last propagation was an FD probe. Propagate only every k-th iteration or on Cancel; saves one propagation per iteration (10–50% of an LVD iteration at n ~ 5–10).
- Wrapper test gap: `tests/lvd_tests/OptimizerSmokeTest.checkAdamNlOptBowl` is the only wrapper test. Add the LVD-defaults-equal-package-defaults pin (D11.3), the GUI numeric round trip (D2), and the physical `info.constrviolation` check (D3).

### Not recommended

- **SR1** for the Hessian model: the IP core assembles `W = H + Σ + JI'ΣJI` and relies on inertia correction to fix indefiniteness; an indefinite SR1 model would push every iteration through the inertia loop. Keep damped BFGS with the noise-aware skip of D6.
- **Structured Gauss–Newton + BFGS** only pays when f is an explicit sum of squares, which LVD objectives are not in general.

---

## 4. Suggested implementation order

Each step is independently shippable; the order front-loads the LVD-visible defects and the cheap ones.

1. **One-line/one-block correctness fixes with no design decisions:** D2 (tolerant `fdStepUserSet`, NaN default), D1.1 (`costThreshold = Inf`), D11.2 (LVD forcing defaults + `loadobj`), D13 (`res.comp` in condition (c)), D24 (`ef == -1`), D26 (return the updated model), D27 (reject `dphi ≥ 0`), D29 (`stepNorm = inf`, re-seed `lamE`, `plotInfo` bounds), D8.1 (empty-constraint short-circuit), D9 (strip linear multipliers), T1. Add the LVD-defaults pin test (D11.3).
2. **Start-up pipeline:** D4 (calibrate before scaling) → D12.1 (seed the scaled cache) → D7 (calibration direction) → D12.2/12.3 (Jacobian/gradient cache) → A2 (combined sweep).
3. **Feasibility semantics:** D3 (physical `feasPhys`, `constrViolTol`, `autoScaleMaxGradient`, wrapper display).
4. **Quasi-Newton hygiene:** D6 (short-pair gate, skip on `lsFailed`), D22 (`aD = aP` on failure), D14 (κ_Σ clamp), D23 (non-monotone ρ).
5. **Equality core parity:** D10 (augment, gated trigger, model reset).
6. **Linear algebra:** A9 factors → D16 (refinement, pivot tolerance, dense K) → D15 (δ first-try zero, γ tied to residual, cheaper probe) → D17.1 (SOC re-solve) → D5.2 (dual-step cap inside the solve) → D5.1/5.3 (absolute degeneracy floor, min-norm multipliers) → D30.
7. **Globalization:** D18 (switching/veto/α_min, fixed `thetaMin`) → D17.2/17.3 (SOC on first rejection, slack rows) → D20 (restoration certificate) → A6 (proximal restoration) → A4 (watchdog, filter reset) → A5 (acceptable termination).
8. **Decide the Krylov path** (D11.1): repair or delete.
9. **FD robustness:** A1 (promotion + exitflag 2 at FD accuracy), A7 (re-calibration), D8.2 (h for FD-of-FD), D8.4 (cost warning), D21 (NaN poisoning), A8 (derivative checker).
10. **Hygiene:** D31 table, D25, D19/D28 (opt-in NT path), A3 (warm start), A10 (LVD defaults and wrapper).

### 4.1 Batch plan (agreed 2026-10-07)

Work happens on branch `adamnlopt-fixes`, cut from `v1.6.11`. Each batch is one commit, or a few commits for the larger ones, so a regression can be bisected. After every batch, re-run the baseline captured before Batch 1 and diff against it:

- the `tests/unit_tests/adamnlopt/` suite and `tests/lvd_tests/OptimizerSmokeTest`;
- the solver benchmark fixtures recorded in the baseline (exitflag, f, physical max violation, iterations, funcCount, wall time);
- any LVD case runs recorded in the baseline.

**Baseline (captured 2026-10-07 from HEAD `c45466d6`).** Tooling and results live outside the repo in `C:\Users\aharden\lvdfix\adamnlopt_baseline\`. To capture a tree, run `adamnlopt_baseline(root, outDir, doLvd)` with `matlab -batch`, from a detached worktree so later edits cannot leak in. To diff two captures, run `adamnlopt_baseline_compare(dirA, dirB)`, which writes `dirB\compare.txt`. The HEAD capture is `base_HEAD\`. It holds per-test status for the adamnlopt suite and `OptimizerSmokeTest`, the 18-problem catalog solved with catalog derivatives and with FD derivatives, 12 reproduction problems, and five LVD examples run through `consoleOptimize` with AdamNlOpt at `maxIter = 30`, `maxTime = 900 s`. At HEAD the LVD cases are a weak spot:

| LVD case | n | exitflag | final max violation | time |
|---|---|---|---|---|
| SimpleHohmannTransfer | 3 | 2 | 2.2e-12 | 39 s |
| SpinLaunchOptimization | 13 | −2 (starts feasible at 1e-8) | 5.5e-3 | 78 s |
| MunarFlybyContinuityConstraint | 9 | 0 | 2.2e-2 | 628 s |
| MunarLanding | 13 | −2 | 1.0 | 168 s |
| TwoStageToOrbit | 14 | 0 (`maxTime` overrun: 1308 s of 900) | 1.8 | 1362 s |

Pre-existing, environment-only failures at HEAD: four `OptimizerSmokeTest/optimizerWiringIsIntact` cases (Fmincon, PatternSearch, Surrogate, SQP) and `testOptionsStructAndOptimoptionsObjectAgree`, all from Optimization Toolbox license checkout on this machine.

A batch is accepted when the suites pass and every baseline difference is either an improvement or is explained in the commit message. Batches 1 and 2 should not change the answer on well-posed problems. Batch 3 and later deliberately can.

**Batch 1: one-liners with no design decisions** (Section 4 step 1). D2, D1.1, D11.2, D24, D26, D27, D29, D8.1, D9, T1, plus the LVD-defaults pin test (D11.3). Regression guards live in `tests/unit_tests/adamnlopt/AdamNlOptReviewFixesTest.m`, one test per finding ID; each was confirmed to fail on the pre-fix code. Two changes from the plan as written:
- *D13 was backed out.* Testing `res.comp` instead of `compErr` in the barrier-stall condition stalled HS71 on the unpreconditioned MINRES arm (exitflag 0 at opt 1.3e-4, against exitflag 1 at 1.3e-7 without it). The old condition does fire on off-centre iterates (6 rows on that run), so "unreachable" in D13 overstates it. D13 moves to Batch 7 item 0, where it must be measured together with the scaled barrier gate.
- *D27 has a second site.* Besides the merit-backup and `ipLineSearch`/`lineSearch` Armijo tests, the filter's θ-type rule `thetaT <= (1-γθ)·theta0` reads `0 <= 0` at a feasible point and accepted any objective increase; it now requires `theta0 > 0` on that branch. Bounds-only problems sit at θ = 0 throughout, so this is the site that actually fires.

*Batch 1 result against the baseline* (`batch1\compare.txt`): all 633 adamnlopt tests pass, including the 13 new guards. The pre-existing license-only failures are unchanged. 0 of 34 catalog rows and 0 of 11 reproduction rows moved in exitflag, iterations, funcCount, f or error. Three LVD cases are bit-identical. SpinLaunchOptimization still exits −2 but ends at violation 3.6e-2 (was 5.5e-3) after 365 s (was 78 s). Re-running it on the Batch 1 code with only `costThreshold = 0.1` restored reproduces the HEAD result to every digit, so the difference is entirely D1: HEAD was solving it on Broyden secant Jacobians and now uses exact FD Jacobians. MunarLanding's small change (−2 both times) is very likely the same cause; that was not separately verified. Wall times between captures vary with machine load (SimpleHohmannTransfer took 39 s, then 20 s, with identical iterates), so treat times as indicative only.

**Batch 2: start-up pipeline** (step 2). D4 → D12.1 → D7 → D12.2/12.3 → A2. Expected effect: fewer evaluations, the same answers. A2 roughly halves propagations per LVD iteration in BuiltIn mode.

*Batch 2 result* (commit `0fef3e39`, `batch2\compare_vs_batch1.txt`). Measured effect of the two calibration fixes, old code against new:

| Probe | Before | After |
|---|---|---|
| D7, calibrated gradient rel-err, variables 1e3..2e4, noise 1e-9 | 2.0e-1 | 1.7e-7 |
| D7, same, variables 1e3, noise 1e-6 | 8.6e+2 | 8.3e-4 |
| D4, row scale / true row scale, 1e-3 noise on a gradient-1e3 row | 0.094 | 1.00 |

On the battery, every changed catalog and reproduction row kept its exitflag, iterations and answer and used 7–16% fewer evaluations (for example HS71 with FD derivatives, 116 → 106). LVD SpinLaunchOptimization still exits −2, at violation 8.0e-3 in 74 s (Batch 1: 3.6e-2, 365 s); the other four LVD cases are unchanged. *Regression found and fixed in Batch 3:* the x0 seeding raised "Arrays have incompatible sizes" on a problem with linear equality rows and no nonlinear equality. Indexing a 1×1 `sc.Dc` with an empty range returns a 1×0 *row* in MATLAB regardless of orientation, and `1x0 .* 0xn` is a size error. Slices are now `reshape(..., [], 1)`; guard `testD12SeedingWithLinearRowsAndNoNonlinearEqualities`.

**Batch 3: physical feasibility** (step 3). D3. This changes results on purpose: runs that reported convergence while their physical violation exceeded tolerance will now iterate further or report infeasible. Review each baseline diff case by case. Open decision: the `constrViolTol` default (proposed `1e-4`, physical units).

*As implemented:* `constrViolTol = 1e-4` (the proposed default; no other value was specified) and `autoScaleMaxGradient = 100`, both exposed in `AdamNlOptOptions` and the LVD options dialog. `output.constrViolation`, `info.constrviolation` (and so the LVD progress display, `optimValues.constrviolation` and the recorder's `maxCVal`) are now physical; the scaled values are `output.constrViolationScaled` and `info.constrviolationScaled`. A new LVD UI test, `tests/lvd_tests/AdamNlOptOptionsDialogTest.m`, opens the dialog headlessly, checks the new controls, and pins that a no-edit Save changes no option (D2 end to end). Landing the row-scaling cap exposed **D33** (below): the step-size exit declared convergence before the barrier was finished. It is fixed in this batch.

*Batch 3 result* (commit `e7fb9e8c`, `batch3\compare_vs_batch2.txt`). Catalog: HS71 takes one more iteration (9 → 10) and `circleEq` 4 more evaluations; every exitflag and answer is unchanged. LVD examples (`maxIter = 30`, `maxTime = 900 s`):

| Case | Batch 2 | Batch 3 |
|---|---|---|
| SimpleHohmannTransfer | exitflag 2 (step-size exit) | exitflag 1 (true convergence; the D33 gate) |
| SpinLaunchOptimization | −2, violation 8.0e-3 | −2, violation 3.0e-4 |
| MunarFlybyContinuityConstraint | 0, violation 2.2e-2, f = −0.009 | 0, violation 3.3e-4, f = −0.145 |
| MunarLanding | −2, violation 1.0 | −2, violation 1.0 |
| TwoStageToOrbit | 0, violation 1.8 | 0, violation 12.9 |

  TwoStageToOrbit is worse at the 30-iteration, time-limited cut-off. It is the one LVD case where Batch 3 hurt, and the likeliest cause is the row-scaling cap (`autoScaleMaxGradient = 100` leaves rows with gradients in [1, 100] unscaled, which changes the conditioning of this 14-variable problem). **Open item:** re-run TwoStageToOrbit to convergence with `autoScaleMaxGradient = 1` against the default before Batch 10 settles LVD defaults. This capture's wall times are not comparable with earlier ones: unit-suite runs shared the machine.

**Batch 4: quasi-Newton and dual-update hygiene.**
- *Items, in commit order:* D6 (short-pair gate in `updateHessianModel` and skip the update when `lsFailed` or `aP <= 1e-10`), D22 (`aD = aP` on a failed line search), D14 (κ_Σ = 1e10 clamp on `zL`, `zU`, `lamI` after the dual step), D23 (non-monotone ρ, or reset ρ on every mu decrease, and guard the `gd/theta` term with `theta > feasTol`).
- *Files:* `solve.m` (`updateHessianModel` signature and both call sites, the dual update block at `:1583-1587`, `ipLineSearch`, `lineSearch`, the NT ρ updates), `control_penaltyUpdate.m`, `BFGSHessian.m`/`LBFGSHessian.m` only if a `minStep` property is preferred over the caller-side gate.
- *New tests:* `testATinyNoisyPairDoesNotCorruptTheModel` (n = 50; cond(B) within 10x), noisy-Rosenbrock trace check (no `bfgsAccepted == 1` with `aP <= 1e-9`), failed-line-search dual freeze (`lamE` unchanged), κ_Σ bound on every trace row, ρ recovery after a tiny-θ iteration.
- *Risk:* D22 and D14 change the dual trajectory on every bounded problem. Run the 18-problem end-to-end battery and the orbit case; compare iteration counts, not only exitflags. If D14 slows a case, try κ_Σ = 1e12 before abandoning it.
- *Depends on:* nothing. Can run in parallel with Batch 3 if needed.
- *As implemented:* all four items. `updateHessianModel` moved out of `solve.m` into its own package file so the gate can be unit-tested. It now takes `(ev, xNew, forcedStep)` and reports a `bfgsSkippedShort` trace column. The κ_Σ value is a new option, `kappaSigma = 1e10`, exposed in `AdamNlOptOptions` and the LVD dialog. ρ resets to 1 on every mu decrease and after restoration. Two observations from writing the tests:
  - At 1e-6 objective noise with FD gradients at `sqrt(eps)`, 51 of 60 iterations take steps of length ≤ 1e-9 *without* `lsFailed` being set: the filter accepts the creep as a θ- or f-type step. Only at 1e-4 noise does the failure flag fire (58 of 60). The D6 short-step gate catches both cases, but the filter accepting 1e-10 steps as progress is the α_min defect D18 addresses in Batch 7.
  - On an objective that is NaN everywhere except x0, the first line search fails, the 1e-10 creep lands on a NaN point, and the solve exits −3 at iteration 1. It should have rejected the creep and stopped (or restored) at x0. Recorded as part of D21 (NaN handling).

**Batch 5: equality-core parity.**
- *Items:* D10 in full: `filt.augment(thetaPreRest, phiPreRest)` instead of `filt.reset()`; capture `lsFailed` from `globalize_filterLineSearch`; add the `bestFeas`/`feasStallCount` tracker and the `feasGenuinelyStalled` gate; reset the Hessian model and `stepNorm` on restoration; re-seed `lamE` with `optW`.
- *Files:* `solve.m:286-560` only.
- *New tests:* the equality-only analogue of the finding-57 fixture (exitflag > 0, fewer than 10 restorations, `filterSize` never drops to 0 on a restoration row); an equality-only problem that previously exited -2 on a transient stall.
- *Risk:* low. The change mirrors code already proven in the IP core. Watch for any equality-only fixture that relied on the eager restoration trigger to escape.
- *Depends on:* D29 from Batch 1 (`stepNorm` reset) already in place.
- *As implemented:* all of D10, plus the equality-core half of D30, pulled forward from Batch 6 because gating the trigger exposed it. Equality-only probes, Batch 4 code against Batch 5:

| Problem | Batch 4 | Batch 5 |
|---|---|---|
| `x1+x2 = 1` and `x1+x2 = 3` (inconsistent, parallel gradients) | −2 at it 0, 134 evals | −2 at it 0, 65 evals |
| same, with the D10 gate but *without* the D30 guard | — | −3 at it 1, f = NaN |
| `min x1+x2` on the unit circle from (0.01, 0) | 1, 11 it, 1 restoration, 159 evals | 1, 15 it, 2 restorations, 201 evals |
| six other equality-only problems | — | bit-identical |

  The inconsistent system gives a NaN KKT step. The old eager trigger restored before the step was used, which hid it. With the stall gate the NaN step was taken, so the guard was needed for Batch 5 to avoid a regression. The guard replaces a non-finite step with a zero step marked `lsFailed` and lets restoration fire immediately. The unit-circle case got slower because the gate delays the first restoration by `restStallWindow` iterations. That is the intended trade, but it is visible on easy near-degenerate starts. The IP-core half of D30 is still in Batch 6.

**Batch 6: linear algebra.** Larger; split into the sub-commits below, in this order.
1. *A9 factor plumbing.* `linalg_solveKKTdirect` returns `info.L, info.D, info.p`; new `linalg_resolveKKT(info, rhs)`. No behaviour change. Test: re-solve with a new RHS equals a fresh solve to 1e-14.
2. *D16.* Two steps of iterative refinement, `info.resRel`; pivot tolerance `10*eps*maxAbsPivot`; force `full(K)` when H is dense. Tests: `pivotSpread ≈ 1e12` system solves to 1e-12 relative residual; 1e-4 constraint pivot at N = 600 is not rank-deficient.
3. *D15.* First factorization always tries δ = 0 with γ = Fix-A only; warm start seeds only the first retry (`/3`, growth ×8); drop the `/10` decay in `solveStep`; tie Fix-A γ to `kappaG*‖rFeasE‖∞` (or `mu^0.25`); replace the dense Schur probe with mE solves against the existing factors plus `eigs`. Update `testCorrectedRegularizationIsReusableAsAWarmStart` to `tries <= 1`. Tests: SPD fixture returns `reg == (0,0)`; `JE = [1 1e-5]`, `rFeasE = 1e-9` gives `gamma <= 1e-7`.
4. *D17.1.* SOC re-solves use `linalg_resolveKKT` on the primary factors; cache `gammaScale` per iteration. Test: `nSolves == 1` factorization on an iteration with `socAdopted == 1`.
5. *D5.2.* Inside `kkt_inertiaCorrection`, when γ > 0 and ‖dλE‖ exceeds the Fix-B cap, scale dλE and re-solve the primal block with the existing factors.
6. *D5.1, D5.3.* Absolute floor in `degeneracy_detectDegeneracy` (`tolAbs = fdStep*max(1,‖x‖∞)` when constraint derivatives are FD); `lsqminnorm` in `step_multiplierUpdate`; pass `optW` through `computeNTStep`. Test: the unit-circle reproduction from x0 = 0 with FD gradients returns f = −√2.
7. *D30.* Non-finite K/RHS short-circuit in `kkt_inertiaCorrection`; `info.solved = all(isfinite(d))`; `isfinite(d)` check after every `detectStep` in `solve.m`.
- *Files:* `linalg_solveKKTdirect.m`, new `linalg_resolveKKT.m`, `kkt_inertiaCorrection.m`, `kkt_assemble.m`, `degeneracy_detectDegeneracy.m`, `step_multiplierUpdate.m`, `solve.m` (`solveStep`, SOC loop, `computeNTStep`, post-`detectStep` checks).
- *Risk:* highest of all batches. D15 changes every Newton step after the first nonconvex iteration, and the orbit-case plateau is sensitive to the dual regularization. Land sub-commits 1–2 first and re-baseline; land 3 alone and compare the orbit case's `feasRowRes`, `gamma` and opt trace columns before and after.
- *Depends on:* Batch 4 (so a dual-update change is not confounded with a regularization change).
- *As implemented* (commits `3f7d0935`, `5d45f7a2`, and 6.3). Every item landed except as noted; guards are in `AdamNlOptReviewFixesTest`, and each failed on the preceding commit.
  - **D16 iterative refinement: rejected by measurement.** On dense KKT systems with a 1e12 pivot spread, and on sparse ones factored by MA57 with threshold pivoting, the LDL' solve was already backward stable (backward error 1e-17 to 1e-18). Two refinement steps changed neither the residual nor the forward error. The 1e-5 relative residuals the review cited are rounding in forming K·d. The loop was removed; `info.resRel` stays as a diagnostic. The pivot tolerance (`10·eps·max` instead of `N·eps·max`) and the dense-K assembly landed.
  - **D15** as specified, plus an explicit `reg0.gammaFloor`. `degeneracy_regularizedRecovery` used `reg0.gamma` as a deliberate, residual-sized floor, and the new "ignore stale reg0" rule must not discard that. New option `dualRegFeasFactor = 1`. *Not done:* replacing the dense O(n³) Fix-A Schur probe with solves against the existing factors. The probe must run before the first factorization because it sets that factorization's γ, so moving it onto the factors costs an extra factorization whenever γ > 0. That is a performance trade to measure on a large problem, not a correctness fix, and is left for later.
  - **D17.1** landed. A new trace column, `nFactorizations`, shows one factorization on iterations with SOC re-solves.
  - **D5.2** landed in a different form from the plan: the cap is enforced by growing γ until the coupled solve itself respects `dualStepMax`, rather than by scaling dλ and re-solving the primal block. The primal block alone can be singular, and growing γ keeps dx and dλ from the same consistent system.
  - **D5.1 and D5.3** need a noise tolerance in the solver's own units. The IP core runs in scaled variables, where a forward-difference Jacobian entry carries truncation error of about h·Dx²·κ. With κ unknown, the tolerance assumes κ = O(1) in the caller's units: `10·fdStep·max(1,‖x‖)·max(Dx)²` for the rank test, and the same times `max(optW)` for the weighted multiplier fit. A first version without the Dx factor fixed the equality core but left the box-scaled IP core converging to the maximum. Result: `min x1+x2` on the unit circle from x0 = 0 with FD gradients converges to f = −√2 in both cores, from all six starts probed. Before, both cores ended at the maximum, +√2.
  - **D30 IP core** landed: a non-finite K or RHS short-circuits the inertia ladder, `info.solved` is false for a non-finite step, and a non-finite step is zeroed, skips the line search, and may trigger restoration at once.
  - *Cost observed:* inconsistent systems are now handled by finite steps whose line searches fail, instead of NaN steps that restored at once. They still exit −2, but slower: `x1+x2 = 1` and `= 3` takes 504 evaluations against 65, and the `infeasible` reproduction 626 against 215. Each failed filter line search spends about 80 trial evaluations; D18's α_min (Batch 7) is the fix.

**Batch 7: globalization.**
0. *D13, barrier gate.* Moved here from Batch 1 (see above). Land the scaled `Emu` (divide `statW` and `compErr` by `kktScaleFactor`) and the multi-step barrier loop first, then retry condition (c) on `res.comp`. Accept only if HS71 converges on every Krylov/preconditioner arm and the orbit case does not regress.
   - *As implemented (7.2):* the scaled gate and the multi-step loop (up to 5 levels per iteration, trace column `nMuSteps`) landed, all gains on the battery: `noisy5` (1e-7-noise objective in a box) now converges, exitflag 0 → 1 in 97 evaluations against 195; `infeasible` 506 → 312 evaluations; the bound/inequality problems take one iteration fewer. Condition (c) on `res.comp` was retried on top. HS71 now converges on every Krylov arm, so the Batch 1 stall is gone, but the retry gained nothing measurable (`diskIneq` one iteration slower, nothing else moved). It was **not** adopted, and condition (c) keeps testing `compErr`.
1. *D18.* *(Landed in 7.1, `51ab7d18`: `thetaMin` fixed from θ(x0) as WB specify, not reset on mu decrease. Battery: `diskIneq` 135 → 39 evaluations, `circleEq` 79 → 57, `infeasible` 626 → 506, no answer changed.)* Add `Filter.thetaMin` (set from θ(x0) in `makeFilter`, reset from the current θ when mu decreases); pass it into `globalize_filterLineSearch` as a 10th argument; apply the `thetaCap` veto only to θ-type trials; WB α_min with γ_α = 0.05; use `filt.thetaMin` for `thetaMinNT`/`thetaMinNT_IP`. Tests: curved-equality full step accepted with `augment = false`; worse-in-both stall uses ≤ 22 trials and still sets `lsFailed`.
2. *D17.2, D17.3.* `globalize_filterLineSearch` returns the first trial and a `firstRejectedByTheta` flag; expose the acceptance rule as `globalize_filterTryStep`; SOC runs immediately after the first θ rejection, one evaluation per correction, along the corrected direction, with slack rows corrected (`cSocI`). Test: Maratos example accepts the full step after one SOC with ≤ 1/3 of baseline evaluations.
3. *D20.* Per-call restoration success test plus a two-failure counter (reset on new `bestFeas`); 2-norm Armijo inside `degeneracy_restorationPhase` with an `info.stationary` certificate (‖J'c‖ ≤ 1e-10·max(1,‖c‖)). Tests: two forced restorations on a feasible problem end with exitflag > 0; rank-2 consistent system restores; inconsistent system reports `stationary`.
4. *A6.* Proximal term `(J'J + ζI)` in the restoration normal equations; loop until the restored point is filter-acceptable or θ ≤ feasTol.
   - *As implemented (7.3, D20 + A6):* restoration takes a Levenberg–Marquardt step with Fan–Yuan damping ζ = max(1e-6‖J‖², ‖J'c‖). Acceptance is Armijo on the 2-norm of the active violation. Restoration reports `info.stationary` when ‖J'c‖/(‖J‖‖c‖) ≤ 1e-8, or ≤ 1e-2 when no sufficient decrease is possible or progress stagnates; with FD Jacobians the ratio floors near 4e-3 at a genuine infeasible stationary point. Both cores exit −2 only on that certificate, or after two consecutive restorations that each fail to cut θ by 10%; progress in the main loop clears that count. Two damping choices were measured and rejected:
     - plain Gauss–Newton (ζ ≈ 0) took steps of length 11.8 along the near-null direction of a nearly rank-1 J and crept at α ≈ 1e-4 for 50 iterations;
     - ζ = ‖c‖₂ stays large at an infeasible point and made the iteration linearly convergent there (4× the evaluations on the `infeasible` case).
   - On the `infeasible` reproduction (linear equality plus disk): −2 in 161 evaluations against 312 at 7.2 (1057 at Batch 3), and the exit message now states that a stationary point of the violation was reached. Restoration alone reaches the least-violation point in 2–4 iterations (about 30 evaluations) from every start probed, including one where the old step crept for 801 evaluations. *Not done:* the filter-acceptability loop on the restored point, because restoration does not have the barrier objective the filter compares; the pre-restoration filter augment covers the cycling case.
5. *A4.* One-to-two-step watchdog before declaring `lsFailed`; IPOPT filter-reset trigger (5 consecutive first-trial rejections by a stored entry, bounded resets).
6. *A5.* `acceptableTol = 100*optTol`, `acceptableIter = 15`, exitflag 2 with an explicit message; stationarity-stagnation rule in `control_modeController`.
- *Files:* `Filter.m`, `globalize_filterLineSearch.m`, new `globalize_filterTryStep.m`, `globalize_filterAccept.m` (L2 margin fix from D31 belongs here), `degeneracy_restorationPhase.m`, `control_modeController.m`, `terminationCheck.m`, `defaultOptions.m` (new options), LVD `AdamNlOptOptions.m` and GUI (expose `acceptableTol`/`acceptableIter`), `solve.m` (both cores' line-search, SOC and restoration blocks).
- *Risk:* D18 and the SOC rewrite change which steps are accepted on every constrained problem. Land 1 alone and re-baseline before 2. A5 changes exit codes, so LVD scorecard behaviour must be checked.
- *Depends on:* Batch 5 (both cores must share the restoration logic before it is rewritten) and Batch 6 sub-commit 4 (SOC re-solve via factors).

**Batches 8–10** follow Section 4 steps 8–10 unchanged. Batch 8 needs the user's decision on the Krylov path; I recommend deletion unless n ≫ 500 is expected.

---

## 5. Verified correct (no action)

Recorded so the next reviewer does not reopen them: KKT sign conventions are consistent across `kkt_residual`/`kkt_assemble`/`kkt_KKTOperator`/`solve.m` (`K = [W JE'; JE −γI]`, `rhs = −[rStat; rFeasE]`, `L = f + λE'cE + λI'(cI+s) − zL'(x−l) − zU'(u−x)`); the IP condensation (W, r1, back-substitution of ds, dλI, dzL, dzU) was re-derived by hand and is algebraically right; fraction-to-boundary is applied to the correct vectors in all six places and λI, zL, zU cannot go negative; the barrier directional derivative in the filter search has the correct signs; filter constants (`sθ = 1.1, sφ = 2.3, δ = 1, ηφ = 1e-4, γ = 1e-5`) match WB; f-type steps do not augment; the filter is reset on each mu decrease; `tau = max(tau0, 1 − mu)`; the termination test runs on the current iterate with mu-free residuals before the barrier update, tests finiteness first, and applies `s_d` to opt and comp; Steihaug-CG, dogleg, pivoted-QR null basis, Eisenstat–Walker safeguard formula, Jacobi diagonal SPD, GMRES iteration accounting; `ecnoiseCore` matches Moré–Wild; Powell damping (N&W 18.2) in both models; BNS compact L-BFGS form; secant pair at `lam+` for both points and at `lamE_pair` on refresh iterations; Broyden never fed rejected trial points; models reset on IP restoration; Shanno–Phua first-pair scaling; parallel FD identical to serial; bound-aware FD rules; `IterTrace` preallocation and growth; every `iterationInfo` field populated by both cores; evaluation accounting matched a user-side counter exactly (262 = 262) on a mixed problem; x0 outside bounds is clipped with a warning; infeasible, duplicate-row, non-convex-with-exact-Hessian, LP, fixed-variable, `maxIter` and `maxTime` cases all return the documented exit codes with `fval == f(x)`.

---

## Appendix: reproduction scripts

Scratch scripts used for the measurements quoted above live in `C:/Users/aharden/AppData/Local/Temp/adamnlopt_review/` (`exp1.m` … `exp5.m`, with `.log` outputs). Each adds `tests/helpers` to the path and calls `ksptotAddProjectPaths()`. They are not part of the repository; the test cases proposed under each finding are the durable form.
