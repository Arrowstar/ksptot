function info = iterationInfo(info, state, res, problem, opts, extras)
%ITERATIONINFO  Extend the per-iteration info struct with the raw solver state.
%   info = adamnlopt.iterationInfo(info, state, res, problem, opts, extras)
%   takes the per-iteration struct from PLOTINFO (every quantity unscaled and
%   indexed over the ORIGINAL variables) and appends the raw INTERNAL state of
%   the iteration that just finished: the scaled/reduced-space variables and
%   residuals, the multipliers, the step that produced the current iterate, the
%   trust-region/barrier state, the mode advice, and the resolved options.
%   Called by the two solver cores once per iteration when opts.IterationFcn is
%   set, so an iteration function sees every quantity the solver itself
%   computed at that iterate -- nothing is reconstructed or re-evaluated, and
%   the callback costs the same whether the user supplied analytic derivatives
%   or not.  A callback may return truthy as its first output to request an
%   early stop of the solve (exitflag -1; see DEFAULTOPTIONS, opts.IterationFcn).
%
%   Inputs:
%     info    - the PLOTINFO struct (unscaled, full-indexed quantities).
%     state   - raw iterate state struct from the solver core (internal
%               scaled/reduced space; see makeState/ipState in SOLVE).
%     res     - raw residual struct (rStat/rFeasE/rFeasI/rComp and norms).
%     problem - the ORIGINAL validated problem struct (physical bounds and
%               initial point).
%     opts    - resolved options struct (see MAPOPTIONS).
%     extras  - struct of raw loop quantities the cores pass through: dx,
%               dlamE, ds, dlamI, dzL, dzU, aP, aD, aLamE, Delta, tau, rho,
%               advice, nActiveBnd, lsAdopted, lsFired.  Directions/lengths
%               that do not exist in the active core are empty/NaN (see
%               DEFAULTOPTIONS, opts.IterationFcn).
%
%   Outputs:
%     info - the extended struct documented in DEFAULTOPTIONS (opts.IterationFcn).
%
%   See also PLOTINFO, DEFAULTOPTIONS, SOLVE.

import adamnlopt.*

% --- Raw iterate state and residual (the solver's internal scaled space) ---
info.state  = state;
info.res    = res;
info.optRaw = util_norms(res.rStat);   % unweighted stationarity inf-norm

% Explicit aliases so a callback does not have to dig into state/res.
info.xScaled  = state.x(:);
info.fScaled  = state.f;
info.gScaled  = state.g(:);
info.cEScaled = state.cE(:);
info.cIScaled = state.cI(:);
info.rStat    = res.rStat;
info.rFeasE   = res.rFeasE;
info.rFeasI   = res.rFeasI;
info.rComp    = res.rComp;

% --- Multipliers and dimensions of the internal solve ---
% The equality-core state carries no bound multipliers (no barrier), so zL/zU
% are empty there rather than fabricated.
if isfield(state, 'zL'), zL = state.zL; else, zL = zeros(0,1); end
if isfield(state, 'zU'), zU = state.zU; else, zU = zeros(0,1); end
info.lambda = struct('lamE', state.lamE, 'lamI', state.lamI, ...
                     'zL', zL, 'zU', zU);
info.n  = numel(state.x);
info.mE = numel(state.lamE);
info.mI = numel(state.lamI);
info.lb = problem.lb(:);
info.ub = problem.ub(:);

% --- The step that produced the current iterate (scaled space) ---
% aP/aD/aLamE are the primal/dual/equality-dual step lengths actually taken;
% Delta and tau are the trust-region radius and fraction-to-boundary factor
% after their last update; rho is the l1-merit penalty parameter.  Directions
% that do not exist in a core (ds/dlamI/dzL/dzU in the equality core) are
% empty; lengths that do not exist (aD/tau there) are NaN rather than
% fabricated.  At iteration 0 every direction is zero (no step taken yet).
info.step = struct('dx', extras.dx, 'dlamE', extras.dlamE, ...
                   'ds', extras.ds, 'dlamI', extras.dlamI, ...
                   'dzL', extras.dzL, 'dzU', extras.dzU, ...
                   'aP', extras.aP, 'aD', extras.aD, 'aLamE', extras.aLamE, ...
                   'stepsize', info.stepsize, 'Delta', extras.Delta, ...
                   'tau', extras.tau, 'rho', extras.rho);

% --- Mode advice and interior-point bookkeeping ---
info.advice     = extras.advice;
info.nActiveBnd = extras.nActiveBnd;   % IP core only; 0 in the equality core
info.lsAdopted  = extras.lsAdopted;    % 0/1: costate refresh adopted
info.lsFired    = extras.lsFired;      % 0/1: costate refresh gate fired

% --- The resolved options the iterate was judged against ---
info.opts = opts;
end