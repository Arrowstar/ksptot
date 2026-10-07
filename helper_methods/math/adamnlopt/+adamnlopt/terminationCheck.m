function [stop, exitflag, msg] = terminationCheck(state, res, opts)
%TERMINATIONCHECK KKT-based stopping test.
%   [stop, exitflag, msg] = adamnlopt.terminationCheck(state, res, opts) checks
%   the unscaled, barrier-free KKT residual against the requested tolerances.
%   smax-style scaling divides stationarity/complementarity by the average
%   multiplier magnitude so large multipliers do not mask convergence. The
%   scaled optimality and complementarity residuals must fall below optTol and
%   compTol and the feasibility residual below feasTol for convergence
%   (exitflag 1); otherwise the iteration-count and function-evaluation caps are
%   checked and reported with exitflag 0.
%
%   Two failure exits share exitflag -3: a non-finite objective/residual, and a
%   feasibility blow-up sustained for divergeWindow iterations (measured against
%   the best feasibility the run achieved). Neither can be caught by the
%   convergence tests, which simply never fire from a diverged point. The second
%   of those is OFF by default (divergeWindow = Inf) because a bestFeas-relative
%   threshold false-positives on ordinary endgame excursions; set divergeWindow
%   finite to arm it. The non-finite exit is always active, and is tested FIRST,
%   ahead of every convergence test -- nothing can be concluded from residuals
%   computed on a NaN iterate.
%
%   The step-size exit fires when the last accepted step is smaller than
%   opts.stepTol relative to ||x|| at a feasible point, and reports exitflag 2
%   (fmincon's StepTolerance code) only when stationarity also satisfies
%   objPlateauOptTol; a step that collapses at a feasible but non-stationary
%   point is a stall and reports exitflag 0. Exitflag 0 is likewise returned when
%   opts.maxTime of wall clock has elapsed. Both exits depend on the caller
%   supplying state.stepNorm and state.elapsed; absent either field the
%   corresponding test is skipped.
%
%   Inputs:
%     state - solver state struct with fields lamE, lamI (multipliers), iter,
%             nFunEvals, x, and optionally zL, zU (bound multipliers) used to
%             size the smax scaling, objStallCount and optGateCount
%             (objective-plateau exit), feasRegressCount / bestFeas
%             (divergence exit), stepNorm (inf-norm of the last accepted primal
%             step, for the step-size exit) and elapsed (seconds since the
%             solve started, for the wall-clock exit).
%     res   - residual struct with fields opt (stationarity), feas
%             (feasibility), and comp (complementarity).
%     opts  - options struct with fields optTol, feasTol, compTol, stepTol,
%             maxIter, maxFunEvals, maxTime, divergeFactor, and divergeWindow.
%
%   Outputs:
%     stop     - logical; true when any stopping condition is met.
%     exitflag - 1 on convergence, 2 on the objective plateau or the step-size
%                exit, -3 on divergence, 0 on a limit-reached stop (iterations,
%                function evaluations, or wall-clock time).
%     msg      - human-readable description of the stopping reason ('' if none).
%
%   See also UTIL_NORMS, KKT_RESIDUAL, UTIL_LOGGER.

smax = 100;
nMult = numel(state.lamE) + numel(state.lamI);
if isfield(state, 'zL'), nMult = nMult + nnz(state.zL) + nnz(state.zU); end
sumMult = sum(abs(state.lamE)) + sum(abs(state.lamI));
if isfield(state, 'zL'), sumMult = sumMult + sum(state.zL) + sum(state.zU); end
sd = max(smax, sumMult / max(1, nMult)) / smax;

optScaled  = res.opt  / sd;
compScaled = res.comp / sd;

% compTol defaults to [] in defaultOptions and is resolved to optTol by solve
% AFTER mapOptions, so that a caller who tightens optTol gets the tied value.
% Every other reader has to cope with the unresolved sentinel: control_modeController
% already does, via getf(opts,'compTol',opts.optTol). This one did not, and the
% failure mode was invisible because of short-circuiting -- `compScaled <= []`
% yields [], which is not a logical scalar, but it is the THIRD operand of the
% convergence test, so it is only ever evaluated once optScaled and res.feas have
% both passed. In other words a caller driving terminationCheck with a plain
% defaultOptions() struct runs fine right up until the iterate converges, and
% then errors with MATLAB:nonLogicalConditional instead of returning exitflag 1.
compTol = opts.compTol;
if isempty(compTol), compTol = opts.optTol; end

stop = false;  exitflag = 0;  msg = '';
% Non-finite guard, FIRST.  This used to sit below the three convergence exits,
% on the reasoning that "once the objective or a residual goes NaN/Inf every
% subsequent comparison is meaningless and no other exit can ever fire" -- which
% is exactly backwards.  The comparisons ABOVE it were the meaningless ones, and
% they fire first: a constant-NaN objective reaches here with res.opt = 0,
% res.feas = 0 and res.comp = 0, passes the exitflag-1 test on the first call,
% and the solve returns fval = NaN with exitflag 1 and the message "Converged:
% first-order optimality, feasibility, and complementarity within tolerances."
% A NaN objective is never a converged solve, and a caller checking exitflag > 0
% -- which is the documented contract -- has no way to find out.  Nothing can be
% concluded from residuals computed on a non-finite iterate, so test finiteness
% before anything reads them.
if ~isfinite(res.opt) || ~isfinite(res.feas) || ...
        (isfield(state, 'f') && ~isfinite(state.f))
    stop = true;  exitflag = -3;
    msg = 'Stopped: objective or KKT residual is not finite (diverged).';
    return;
end
% Physical-units feasibility (D3).  res.feas is measured on the row-scaled
% constraints, where a steep row reads small; every exit that certifies a
% FEASIBLE point also requires the violation in the caller's own units to be
% within constrViolTol.  Callers that do not supply res.feasPhys (unit tests
% driving this directly) or constrViolTol keep the scaled-only behaviour.
cvTol = Inf;
if isfield(opts, 'constrViolTol') && ~isempty(opts.constrViolTol), cvTol = opts.constrViolTol; end
physFeasOK = ~isfield(res, 'feasPhys') || res.feasPhys <= cvTol;
if optScaled <= opts.optTol && res.feas <= opts.feasTol && physFeasOK && compScaled <= compTol
    stop = true;  exitflag = 1;
    msg = 'Converged: first-order optimality, feasibility, and complementarity within tolerances.';
    return;
end
% Acceptable-point convergence (exitflag 2, A5): the iterate has held the
% acceptable levels (see defaultOptions) for acceptableIter consecutive
% iterations.  The cores maintain state.acceptCount; a caller that does not
% supply it skips the test.
if isfield(state, 'acceptCount') && isfield(opts, 'acceptableIter') && ...
        ~isempty(opts.acceptableIter) && opts.acceptableIter > 0 && ...
        state.acceptCount >= opts.acceptableIter
    stop = true;  exitflag = 2;
    msg = sprintf(['Converged to an acceptable level: scaled optimality %.2e ' ...
        '(acceptableTol %.1e) at a feasible point for %d consecutive iterations; ' ...
        'optTol %.1e was not reached.'], optScaled, opts.acceptableTol, ...
        state.acceptCount, opts.optTol);
    return;
end
% Objective-plateau convergence (exitflag 2): the objective has been flat for
% objPlateauWindow consecutive iterations at a point that is fully feasible,
% complementary, and within the stationarity gate objPlateauOptTol.  The
% exitflag-1 test above still owns first-order convergence; this exit exists for
% the flat-objective endgame where opt descends far more slowly than f.
%
% Two independent guards, because neither alone is enough:
%
%   objStallCount measures only the PER-ITERATION objective change, so a drift
%   small enough to look flat each step can still accumulate without ever
%   resetting the counter -- at the former objPlateauOptTol=1e-4 this exit
%   stopped orbitRaiseTest 1.55e-04 above the true optimum (1.26e-03 relative)
%   while the run, allowed to continue, reached exitflag 1.  So do not loosen
%   objPlateauOptTol on the theory that the flat-objective guard will catch the
%   difference: it will not.  Worse, the f-test is close to vacuous here by
%   construction -- f is quadratically flat near a minimizer while opt is only
%   linearly small, and 95% of orbitRaiseTest iterations past 300 read as flat.
%
%   optGateCount is therefore what actually qualifies the exit: the stationarity
%   gate must hold for objPlateauOptWindow CONSECUTIVE iterations.  An endgame
%   whose opt oscillates will dip a spike under any threshold looser than optTol,
%   and the exit must not mistake that for convergence -- measured, iteration 815
%   spiked to 2.14e-06 between 3.61e-05 and 6.23e-06 and the run went on to a
%   genuine exitflag 1 at 1006.
%
% Absent optGateCount (a caller driving this directly) the sustained test is
% skipped rather than failed, so the rule degrades to the single-touch behaviour
% instead of silently never firing.
gateHeld = ~isfield(state, 'optGateCount') || ...
    state.optGateCount >= opts.objPlateauOptWindow;
if isfield(state, 'objStallCount') && isfinite(opts.objPlateauWindow) && ...
        state.objStallCount >= opts.objPlateauWindow && ...
        optScaled <= opts.objPlateauOptTol && gateHeld && ...
        res.feas <= opts.feasTol && physFeasOK && compScaled <= compTol
    stop = true;  exitflag = 2;
    msg = sprintf(['Converged: objective stalled for %d iterations at a feasible, ' ...
        'complementary point (opt = %.2e <= %.1e, held for %d iterations).'], ...
        state.objStallCount, optScaled, opts.objPlateauOptTol, ...
        gateHeldCount(state, opts));
    return;
end
% Step-size exit (exitflag 2 -- fmincon's StepTolerance code, shared with the
% objective plateau above because fmincon reports both as 2). The last accepted
% step moved x by less than stepTol relative to ||x||, at a point that already
% satisfies the feasibility tolerance: no further progress is available and the
% run would otherwise grind to maxIter. Before this, stepTol had NO effect on
% any live code path -- its only reference in the package was inside the
% default-off NT fallback -- so a stalled iteration simply ran out its budget.
%
% The feasibility precondition matters: a line search collapsing to alpha ~ 0 at
% an INFEASIBLE point is a restoration trigger, not a solution, and must not be
% reported as one. Callers that do not supply stepNorm (iteration 0, or a caller
% driving this directly) skip the test rather than failing it.
%
% Feasibility alone is NOT enough to call the result converged, though, and this
% branch used to return 2 on feasibility only -- with no optimality gate at all,
% unlike the objective-plateau exit directly above, which gates on
% objPlateauOptTol. On an objective unbounded below (f = -1/||x||^2) the step
% collapsed at iteration 23 and the solve returned exitflag 2 with
% fval = -6.1e22 and "Converged: step size 6.532e-15 is below StepTolerance
% 1.0e-12 at a feasible point (opt = 2.85e+34)" -- a positive, converged flag at
% a stationarity residual 34 orders of magnitude above tolerance. The message
% formatted optScaled and then ignored it.
%
% A tiny step at a feasible but grossly non-stationary point is a STALL, not a
% solution. Still stop -- that is the whole point of the exit, and the run would
% otherwise grind to maxIter -- but report it as a limit-reached stop (0) rather
% than a convergence (2), so exitflag > 0 keeps meaning what it says. The gate is
% objPlateauOptTol, shared with the plateau exit above so the two agree on what
% counts as close enough to stationary to call converged.
%
% And the BARRIER must be finished (D33).  In the interior-point core a zero
% step only says the current barrier subproblem is solved; while complementarity
% is above compTol and mu can still fall, the next barrier update moves the
% iterate.  Without this gate a quadratic whose Newton step is exact stopped
% after two iterations with exitflag 2 at comp = 2e-2 (tolerance 1e-6), and the
% returned multipliers carried that barrier bias (lamE 4.018 vs 4).  Once mu has
% reached muMin nothing can lower comp further, so the exit is allowed again.
muFloor = 0;
if isfield(opts, 'muMin') && ~isempty(opts.muMin), muFloor = opts.muMin; end
barrierDone = compScaled <= compTol || ~isfield(state, 'mu') || ...
    isempty(state.mu) || state.mu <= muFloor;
if isfield(state, 'stepNorm') && ~isempty(state.stepNorm) && ...
        isfinite(state.stepNorm) && state.iter > 0 && opts.stepTol > 0 && ...
        state.stepNorm <= opts.stepTol * (1 + norm(state.x, inf)) && ...
        res.feas <= opts.feasTol && physFeasOK && barrierDone
    stop = true;
    if optScaled <= opts.objPlateauOptTol
        exitflag = 2;
        msg = sprintf(['Converged: step size %.3e is below StepTolerance %.1e at a ' ...
            'feasible point (opt = %.2e).'], state.stepNorm, opts.stepTol, optScaled);
    elseif isfield(state, 'acceptCount') && state.acceptCount >= 1
        % A5: the step collapsed at a point that meets the acceptable levels
        % (see defaultOptions).  No further progress is available, and the
        % point is as good as an acceptable-point exit would have returned.
        exitflag = 2;
        msg = sprintf(['Converged to an acceptable level: step size %.3e is below ' ...
            'StepTolerance %.1e at an acceptable point (scaled optimality %.2e, ' ...
            'acceptableTol %.1e; optTol %.1e was not reached).'], state.stepNorm, ...
            opts.stepTol, optScaled, opts.acceptableTol, opts.optTol);
    else
        exitflag = 0;
        msg = sprintf(['Stopped: step size %.3e is below StepTolerance %.1e at a ' ...
            'feasible point, but first-order optimality %.2e is above %.1e -- the ' ...
            'iteration stalled short of a stationary point.'], ...
            state.stepNorm, opts.stepTol, optScaled, opts.objPlateauOptTol);
    end
    return;
end
% Divergence exit: feasibility has stayed orders of magnitude worse than the best
% value achieved for divergeWindow consecutive iterations.  Without this the
% solver has no way to stop a blow-up -- the convergence tests cannot fire from a
% grossly infeasible point, so the run grinds on to maxIter (or forever, when
% maxFunEvals is Inf) minimizing the objective from a useless iterate.  The
% caller rolls the iterate back to the best point seen on this exitflag.
% Disabled unless the caller sets a finite divergeWindow -- see defaultOptions
% for why the default is Inf.
if isfield(state, 'feasRegressCount') && isfinite(opts.divergeWindow) && ...
        state.feasRegressCount >= opts.divergeWindow
    stop = true;  exitflag = -3;
    bestF = opts.feasTol;
    if isfield(state, 'bestFeas'), bestF = max(state.bestFeas, opts.feasTol); end
    msg = sprintf(['Stopped: feasibility diverged (%.3e is more than %.0gx the best ' ...
        '%.3e) for %d consecutive iterations.'], ...
        res.feas, opts.divergeFactor, bestF, state.feasRegressCount);
    return;
end
% Wall-clock limit. maxTime was a documented, settable option that nothing in
% the solve loop ever read -- the only reference anywhere in the package was
% plotInfo's progress bar -- so a user who set it got no time limit at all.
% Checked alongside the other budget exits (exitflag 0) and skipped when the
% caller does not supply an elapsed time.
if isfield(state, 'elapsed') && ~isempty(state.elapsed) && ...
        isfinite(opts.maxTime) && state.elapsed >= opts.maxTime
    stop = true;  exitflag = 0;
    msg = sprintf('Stopped: maximum time reached (%.1f s of %.1f s allowed).', ...
        state.elapsed, opts.maxTime);
    return;
end
if state.iter >= opts.maxIter
    stop = true;  exitflag = 0;
    msg = 'Stopped: maximum iterations reached.';
    return;
end
if state.nFunEvals >= opts.maxFunEvals
    stop = true;  exitflag = 0;
    msg = 'Stopped: maximum function evaluations reached.';
end
end

% ------------------------------------------------------------------
function k = gateHeldCount(state, opts)
%GATEHELDCOUNT  Iterations the stationarity gate has held, for the exit message.
%   Reports the window itself when the caller supplies no counter, which is the
%   only sense in which the sustained test was satisfied on that path.
if isfield(state, 'optGateCount')
    k = state.optGateCount;
else
    k = opts.objPlateauOptWindow;
end
end
