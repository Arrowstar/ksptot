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
%   finite to arm it. The non-finite exit is always active.
%
%   Inputs:
%     state - solver state struct with fields lamE, lamI (multipliers), iter,
%             nFunEvals, and optionally zL, zU (bound multipliers) used to size
%             the smax scaling, objStallCount and optGateCount
%             (objective-plateau exit), and feasRegressCount / bestFeas
%             (divergence exit).
%     res   - residual struct with fields opt (stationarity), feas
%             (feasibility), and comp (complementarity).
%     opts  - options struct with fields optTol, feasTol, compTol, maxIter,
%             maxFunEvals, divergeFactor, and divergeWindow.
%
%   Outputs:
%     stop     - logical; true when any stopping condition is met.
%     exitflag - 1 on convergence, 2 on the objective plateau, -3 on divergence,
%                0 on a limit-reached stop.
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

stop = false;  exitflag = 0;  msg = '';
if optScaled <= opts.optTol && res.feas <= opts.feasTol && compScaled <= opts.compTol
    stop = true;  exitflag = 1;
    msg = 'Converged: first-order optimality, feasibility, and complementarity within tolerances.';
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
        res.feas <= opts.feasTol && compScaled <= opts.compTol
    stop = true;  exitflag = 2;
    msg = sprintf(['Converged: objective stalled for %d iterations at a feasible, ' ...
        'complementary point (opt = %.2e <= %.1e, held for %d iterations).'], ...
        state.objStallCount, optScaled, opts.objPlateauOptTol, ...
        gateHeldCount(state, opts));
    return;
end
% Non-finite guard: once the objective or a residual goes NaN/Inf every
% subsequent comparison is meaningless and no other exit can ever fire, so the
% run would spin until maxIter.
if ~isfinite(res.opt) || ~isfinite(res.feas) || ...
        (isfield(state, 'f') && ~isfinite(state.f))
    stop = true;  exitflag = -3;
    msg = 'Stopped: objective or KKT residual is not finite (diverged).';
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
