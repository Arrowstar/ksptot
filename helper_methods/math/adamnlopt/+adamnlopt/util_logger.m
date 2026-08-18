function util_logger(action, level, data, logFile)
%UTIL_LOGGER Iteration display for adamnlopt.
%   adamnlopt.util_logger(action, level, data, logFile) prints solver progress to
%   the command window and, when LOGFILE is non-empty, appends the same text to
%   that file. The ACTION string selects which record is printed and LEVEL gates
%   whether anything is emitted:
%     util_logger('header', level)        - print the column header, but only
%                                           for an iterative level ('iter' or
%                                           'iter-debug').
%     util_logger('iter', level, data)    - print one per-iteration row, but
%                                           only for an iterative level. DATA
%                                           supplies iter, f, rFeas, rStat,
%                                           rComp, mu, alpha, mode, nFun, and
%                                           elapsed (cumulative function
%                                           evaluations and elapsed seconds).
%     util_logger('final', level, data)   - print the termination summary for
%                                           an iterative or 'final' level. DATA
%                                           supplies message, iterations,
%                                           constrViolation, and firstOrderOpt.
%   With level 'off' (or any unrecognized action) nothing is printed.
%
%   DEBUG COLUMNS.  When LEVEL is 'iter-debug' the header and every iteration row
%   are AUGMENTED, to the right of the standard table, with the six diagnostics
%   most useful for tracking down why a solve will not converge (the standard
%   columns are unchanged, so any tool parsing the leading columns still works):
%     optRaw - the unmasked, unweighted stationarity inf-norm.  A large optRaw
%              beside a tiny printed opt means the Fix-F active-bound masking (or
%              the scale weighting) is hiding a real residual, not that the point
%              is converged.
%     optScl - the SCALED stationarity terminationCheck actually gates on
%              (opt / kktScaleFactor); the printed opt differs from it by the
%              multiplier-magnitude scaling.
%     |lamE| - inf-norm of the equality multipliers (costates); a runaway value
%              is the multiplier-blowup failure mode.
%     gateR  - barrier-stall ratio opt/(kappaMu*mu): how far the stationarity
%              block exceeds the Fiacco-McCormick gate that lets mu shrink.  A
%              value that sits at 1e2-1e3 for many iterations is a frozen barrier
%              (interior-point core only; '-' in the equality core).
%     nAB    - number of variables pinned at a bound this iteration (interior-
%              point core only; '-' in the equality core).
%     lsA    - 1 when the least-squares costate refresh was ADOPTED this
%              iteration (interior-point core only; '-' in the equality core).
%   These are read from the correspondingly named fields of DATA (optRaw,
%   optScaled, normLamE, gateRatio, nActiveBnd, lsAdopted); a field that is
%   absent, empty, or NaN prints as a right-aligned dash rather than a number.
%   The debug columns are display-only and never influence the solve.
%
%   Every record is written to disk as it is produced, so a long solve that is
%   interrupted or errors out still leaves a log of the iterations it completed.
%   This is why the solver logs here rather than at the caller: wrapping a solve
%   in evalc to capture its output defers ALL of it -- command window and file
%   alike -- until the solve returns, which shows nothing for hours on a long
%   run and nothing at all if it is interrupted.
%
%   Inputs:
%     action  - char selecting the record: 'header', 'iter', or 'final'.
%     level   - verbosity gate: 'off', 'iter', 'iter-debug', or 'final'.
%     data    - iterate/termination state struct (unused for 'header'); fields
%               consumed depend on ACTION as listed above.
%     logFile - (optional) char path to append the same text to; '' or omitted
%               disables file logging.
%
%   Outputs:
%     (none) output is written to the command window and optionally to LOGFILE.
%
%   See also TERMINATIONCHECK, UTIL_LOGAPPEND, DIAGNOSE.

import adamnlopt.*
if nargin < 4, logFile = ''; end

% An iterative level prints the table; 'iter-debug' additionally appends the
% debug columns.  Keeping the two flags separate means the base table is
% byte-identical between the two levels.
isIter  = any(strcmp(level, {'iter', 'iter-debug'}));
isDebug = strcmp(level, 'iter-debug');

txt = '';
switch action
    case 'header'
        if isIter
            txt = sprintf(['%5s %14s %11s %11s %11s %10s %8s %6s' ...
                           ' %8s %9s'], ...
                'iter', 'f', 'feas', 'opt', 'comp', 'mu', 'step', 'mode', ...
                'nFun', 'time(s)');
            if isDebug
                txt = [txt, sprintf(' %11s %11s %11s %10s %5s %4s', ...
                    'optRaw', 'optScl', '|lamE|', 'gateR', 'nAB', 'lsA')];
            end
            txt = [txt, newline];
        end
    case 'iter'
        if isIter
            txt = sprintf(['%5d %14.6e %11.3e %11.3e %11.3e %10.2e' ...
                           ' %8.1e %6s %8d %9.1f'], ...
                data.iter, data.f, data.rFeas, data.rStat, data.rComp, ...
                data.mu, data.alpha, data.mode, data.nFun, data.elapsed);
            if isDebug
                txt = [txt, ...
                    ' ', dbgCol(data, 'optRaw',     '%11.3e', 11), ...
                    ' ', dbgCol(data, 'optScaled',  '%11.3e', 11), ...
                    ' ', dbgCol(data, 'normLamE',   '%11.3e', 11), ...
                    ' ', dbgCol(data, 'gateRatio',  '%10.2e', 10), ...
                    ' ', dbgCol(data, 'nActiveBnd', '%5d',     5), ...
                    ' ', dbgCol(data, 'lsAdopted',  '%4d',     4)];
            end
            txt = [txt, newline];
        end
    case 'final'
        if any(strcmp(level, {'iter', 'iter-debug', 'final'}))
            txt = sprintf('\n%s\n  iterations: %d   feas = %.2e   opt = %.2e\n', ...
                data.message, data.iterations, data.constrViolation, ...
                data.firstOrderOpt);
        end
end

if isempty(txt)
    return;
end
fprintf('%s', txt);
util_logAppend(logFile, txt);
end

% ------------------------------------------------------------------------
function s = dbgCol(data, field, fmt, width)
%DBGCOL  Format one debug column, or a right-aligned dash when it is unavailable.
%   A quantity that does not exist in the active solver core (the barrier ratio,
%   active-bound count, and costate refresh flag are all interior-point-only) is
%   passed as NaN and shown as '-' rather than as a misleading number, so an
%   equality-core row reads honestly.  WIDTH matches the field width in FMT so
%   the dash lines up under the header.
if ~isfield(data, field)
    v = NaN;
else
    v = data.(field);
end
if isempty(v) || ~isscalar(v) || ~isnumeric(v) || isnan(v)
    s = sprintf('%*s', width, '-');
else
    s = sprintf(fmt, v);
end
end
