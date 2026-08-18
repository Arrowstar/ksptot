function rep = diagnose(output, logFile)
%DIAGNOSE  Explain a solve outcome and recommend option changes.
%   rep = adamnlopt.diagnose(output) inspects the OUTPUT struct returned by
%   adamnlopt.solve and prints a plain-language convergence diagnosis with
%   concrete, actionable recommendations, then returns them in a struct. It is
%   the reusable form of the hand-written KKT-plateau analysis that solver users
%   otherwise re-invent for every hard problem.
%
%   It is called automatically (short form) by solve when a run does not
%   converge and Display is not 'off'; call it directly on any OUTPUT for the
%   full report.
%
%   The analysis uses the termination diagnostics attached by the interior-point
%   core (output.diag: rd, rpE, JE, lamE, zL, zU, mu, x, lb, ub) plus the summary
%   fields (firstOrderOpt, constrViolation, complementarity, iterations,
%   funcCount, exitflag) and output.scaling. When scaling was applied the KKT
%   quantities are in the solver's scaled space (this is noted in the report).
%
%   Inputs:
%     output  - the OUTPUT struct from adamnlopt.solve.
%     logFile - (optional) char path to append the report to, in addition to
%               printing it. '' or omitted prints to the command window only.
%
%   Outputs:
%     rep - struct with fields:
%             exitflag        - copied termination code.
%             messages        - cellstr of findings (what was observed).
%             recommendations - cellstr of suggested actions.
%             flags           - struct of booleans (hitBudget, infeasible,
%                               illConditioned, rankDeficient, barrierFrozen,
%                               boundsHeavy, imbalanced).
%             condJE          - constraint-Jacobian condition estimate (NaN if
%                               unavailable).
%             mu              - final barrier parameter (NaN if unavailable).
%
%   See also SOLVE, DEFAULTOPTIONS.

if nargin < 2, logFile = ''; end

msgs = {};
recs = {};
flags = struct('hitBudget',false,'infeasible',false,'illConditioned',false, ...
               'rankDeficient',false,'barrierFrozen',false,'boundsHeavy',false, ...
               'imbalanced',false,'diverged',false);
condJE = NaN;
muFinal = NaN;

exitflag = getf(output, 'exitflag', NaN);
scaled = isfield(output,'scaling') && isstruct(output.scaling) && ...
         isfield(output.scaling,'applied') && output.scaling.applied;

emit(logFile,'\n=== adamnlopt convergence advisor ===\n');
if isfield(output,'message') && ~isempty(output.message)
    emit(logFile,'  exitflag %g: %s\n', exitflag, strtrim(output.message));
else
    emit(logFile,'  exitflag %g\n', exitflag);
end
emit(logFile,'  iters=%s  funcCount=%s  opt=%s  feas=%s  comp=%s%s\n', ...
    num2str(getf(output,'iterations',NaN)), num2str(getf(output,'funcCount',NaN)), ...
    fmt(getf(output,'firstOrderOpt',NaN)), fmt(getf(output,'constrViolation',NaN)), ...
    fmt(getf(output,'complementarity',NaN)), tern(scaled,'   (KKT metrics in scaled space)',''));

if exitflag == 1
    emit(logFile,'  Converged: first-order optimality, feasibility and complementarity all met.\n');
    rep = pack(exitflag, msgs, recs, flags, condJE, muFinal);
    return;
end

% A user stop (iteration function returned true) is intentional, not a
% pathology: report it and skip the KKT diagnostics, whose findings would
% otherwise read as recommendations against a stop the caller asked for.
if exitflag == -1
    emit(logFile,'  Stopped by the iteration function (user request); no pathology implied.\n');
    rep = pack(exitflag, msgs, recs, flags, condJE, muFinal);
    return;
end

% --- Exit-code level findings ---
if exitflag == 0
    flags.hitBudget = true;
    msgs{end+1} = 'Stopped on the iteration/function-evaluation budget, not at a KKT point.';
    recs{end+1} = 'Raise maxIter / maxFunEvals; if progress had stalled, see the block findings below.';
elseif exitflag == -2
    flags.infeasible = true;
    msgs{end+1} = 'No feasible point found (local infeasibility).';
    recs{end+1} = 'Check the constraints are consistent near x0; try enableRestoration=true (default on) and a different x0. Persistent infeasibility usually means the formulation, not a hyperparameter.';
elseif exitflag == -3
    flags.diverged = true;
    msgs{end+1} = 'Feasibility diverged: the iteration blew up and did not recover (the returned point is the best iterate seen, not the last).';
    recs{end+1} = 'The guard stopped a run that would otherwise have burned the whole iteration budget. Tighten kappaThetaGrow (default 100) to veto smaller feasibility increases, or lower divergeFactor/divergeWindow to stop sooner. A blow-up this late usually means a near-singular constraint Jacobian -- see the conditioning report below.';
end

% --- Detailed KKT diagnostics (interior-point core only) ---
if isfield(output,'diag') && isstruct(output.diag)
    d = output.diag;
    if isfield(d,'mu'), muFinal = d.mu; end

    % Constraint-Jacobian conditioning / rank.
    if isfield(d,'JE') && ~isempty(d.JE)
        try
            sv = svd(full(d.JE));
            if ~isempty(sv)
                smax = sv(1);  smin = sv(end);
                condJE = smax / max(smin, eps);
                nNull = sum(sv < 1e-8 * smax);
                emit(logFile,'  constraint Jacobian JE: %dx%d  cond=%s  #near-null sv=%d\n', ...
                    size(d.JE,1), size(d.JE,2), fmt(condJE), nNull);
                if condJE > 1e8
                    flags.illConditioned = true;
                    msgs{end+1} = sprintf('Constraint Jacobian is ill-conditioned (cond=%s).', fmt(condJE));
                    if scaled
                        recs{end+1} = 'Auto-scaling is on but conditioning is still poor: the constraints may be genuinely stiff/redundant. Try enableDegeneracyDetection=true.';
                    else
                        recs{end+1} = 'Enable auto-scaling (autoScale=''gradient'', the default) or normalise the constraints; consider enableDegeneracyDetection=true.';
                    end
                end
                if nNull > 0
                    flags.rankDeficient = true;
                    msgs{end+1} = sprintf('%d near-null singular direction(s): constraints are locally rank-deficient.', nNull);
                    recs{end+1} = 'Remove redundant constraints or set enableDegeneracyDetection=true.';
                end
            end
        catch
            % conditioning probe is best-effort
        end
    end

    % Barrier parameter frozen high while not converged.
    if ~isnan(muFinal) && muFinal > 1e-3
        flags.barrierFrozen = true;
        msgs{end+1} = sprintf('Barrier parameter mu is still large at exit (mu=%s): the central-path march stalled.', fmt(muFinal));
        if scaled
            recs{end+1} = 'Relax the barrier gate: increase kappaMu (e.g. 10 -> 100).';
        else
            recs{end+1} = 'Turn on auto-scaling (autoScale=''gradient'') and/or increase kappaMu (e.g. 10 -> 100).';
        end
    end

    % Localise the dual infeasibility by variable index.
    if isfield(d,'rd') && ~isempty(d.rd)
        [rdMax, ix] = max(abs(d.rd));
        emit(logFile,'  dual infeasibility ||rd||_inf=%s at variable index %d\n', fmt(rdMax), ix);
        msgs{end+1} = sprintf('Optimality residual dominated by variable index %d (|rd|=%s).', ix, fmt(rdMax));
    end

    % Variables pinned at a bound (drives complementarity).
    if isfield(d,'x') && isfield(d,'lb') && isfield(d,'ub')
        x = d.x(:);  lb = d.lb(:);  ub = d.ub(:);
        tol = 1e-6 * max(1, abs(x));
        atLb = isfinite(lb) & (abs(x - lb) <= tol);
        atUb = isfinite(ub) & (abs(x - ub) <= tol);
        nAt = sum(atLb | atUb);
        if nAt > 0
            emit(logFile,'  %d of %d variables sit at a bound.\n', nAt, numel(x));
            if nAt >= 0.5 * numel(x)
                flags.boundsHeavy = true;
                msgs{end+1} = sprintf('%d of %d variables are pinned at bounds, dominating complementarity.', nAt, numel(x));
                recs{end+1} = 'Verify the bounds are physical; a highly bound-active solution can slow the barrier endgame.';
            end
        end
    end
end

% --- Feasibility vs optimality imbalance ---
feas = getf(output,'constrViolation',NaN);
opt  = getf(output,'firstOrderOpt',NaN);
if isfinite(feas) && isfinite(opt) && feas > 0 && opt > 0
    ratio = feas / opt;
    if ratio > 1e3
        flags.imbalanced = true;
        msgs{end+1} = 'Feasibility lags optimality by orders of magnitude.';
        recs{end+1} = 'Prioritise feasibility: tighten feasTol or (with modeSwitch=true) let the feasibility-priority rule drive mu down.';
    elseif ratio < 1e-3
        flags.imbalanced = true;
        msgs{end+1} = 'Optimality lags feasibility by orders of magnitude.';
        recs{end+1} = ['Dual residual dominates: try lsMultiplierRefresh=true, or a richer Hessian model if using lbfgs ' ...
                       '(hessianApprox=''bfgs'' for full-memory BFGS, or ''exact'').'];
    end
end

% --- Emit findings + recommendations ---
if isempty(msgs)
    emit(logFile,'  No specific pathology detected. Consider raising the iteration budget or supplying analytic derivatives.\n');
else
    emit(logFile,'  Findings:\n');
    for i = 1:numel(msgs), emit(logFile,'    - %s\n', msgs{i}); end
end
if ~isempty(recs)
    emit(logFile,'  Recommendations:\n');
    for i = 1:numel(recs), emit(logFile,'    * %s\n', recs{i}); end
end
emit(logFile,'=====================================\n');

rep = pack(exitflag, msgs, recs, flags, condJE, muFinal);
end

% ------------------------------------------------------------------------
function rep = pack(exitflag, msgs, recs, flags, condJE, muFinal)
rep = struct('exitflag', exitflag, 'messages', {msgs}, 'recommendations', {recs}, ...
             'flags', flags, 'condJE', condJE, 'mu', muFinal);
end

function emit(logFile, fmtStr, varargin)
%EMIT  Print one report line and mirror it to the run log.
txt = sprintf(fmtStr, varargin{:});
fprintf('%s', txt);
adamnlopt.util_logAppend(logFile, txt);
end

function v = getf(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end

function s = fmt(v)
if isnan(v), s = 'NaN'; else, s = sprintf('%.3e', v); end
end

function s = tern(cond, a, b)
if cond, s = a; else, s = b; end
end
