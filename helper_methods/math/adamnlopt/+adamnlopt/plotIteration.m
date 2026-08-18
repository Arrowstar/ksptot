function plotIteration(info)
%PLOTITERATION  Built-in per-iteration convergence plot (uifigure-based).
%   adamnlopt.plotIteration(info) updates a 2x2 uifigure of uiaxes tracking a
%   solve in progress, one call per iteration:
%
%     1. Variables   - a bar per variable showing the CURRENT value scaled to
%                      the variable's own [lb,ub] interval (x axis = variable
%                      index; no history).  The interval is mapped onto a
%                      symmetric axis where the LOWER bound sits at -1 and
%                      the UPPER bound at +1 (fraction 1/2 = the midpoint,
%                      at 0).  Every bar starts on the shared baseline at 0,
%                      so a variable pinned at its lower bound draws a bar
%                      DOWN to -1, one pinned at its upper bound a bar UP to
%                      +1, and a mid-range variable a short bar around 0 --
%                      which end a variable is stuck against is obvious at a
%                      glance even when its range is tiny compared with the
%                      others (1e-6 vs 1e6, both mapped onto the same axis).
%                      The allowed interval is drawn as a thin grey
%                      background segment behind each bar when there are few
%                      variables; past ~40 variables the panel switches to a
%                      compact display: two full-width reference lines at -1
%                      and +1, thin bars (about one pixel per variable), no
%                      per-variable backgrounds -- a 450-variable problem
%                      reads as a continuous profile instead of a wall of
%                      pegs.  A variable without finite bounds on both sides
%                      (or a fixed variable, lb == ub) is scaled to the range
%                      of values the solve has visited so far, with an amber
%                      background instead, so no bar ever disappears against
%                      a squashing axis; in the compact display, where there
%                      are no per-variable backgrounds, the unbounded/fixed
%                      bars themselves are drawn amber so a bar pinned at the
%                      edge of its visited range cannot be mistaken for one
%                      sitting on a real bound.  With at most 12 variables
%                      every bar is annotated with its physical value.  A
%                      problem without ANY bounds falls back to the raw
%                      unscaled values (no interval background).
%     2. Feasibility - the max constraint violation (info.constrviolation,
%                      the solver's FEAS metric that terminationCheck compares
%                      against feasTol) versus iteration, on a log scale, with
%                      the feasibility tolerance marked as a dashed line.
%     3. Objective   - the UNSCALED objective value versus iteration.
%     4. Criteria    - every convergence/exit criterion as a horizontal bar of
%                      CLOSENESS to its satisfied point (the bar reaching 1.0,
%                      marked by the dashed line, means the criterion passes).
%                      The bars are green when satisfied, red when not, grey
%                      when the quantity is not finite; each bar is annotated
%                      with its current value against its limit.  The three
%                      KKT metric criteria (first-order optimality, constraint
%                      violation, complementarity) use the LOG-DECADE closeness
%                      (info.criteria(k).closenessLog): the bar length shows
%                      how many orders of magnitude remain to the tolerance,
%                      so 1e-4 against a 1e-6 tolerance reads 2/6 of the way
%                      instead of the near-invisible linear ratio.  The
%                      counter criteria (plateau windows, iterations, function
%                      evaluations, wall time) keep their linear closeness.
%
%   The bars in panels 1 and 4 are drawn as THICK LINE SEGMENTS rather than
%   bar-series graphics: bar/barh series are not reliably rendered by the
%   uifigure web renderer (this MATLAB build draws none of them), while line
%   primitives render everywhere.  Each bar is one horizontal (or vertical)
%   segment of a Line object; the variables panel packs all n bars into a
%   single Line via interleaved (x,y) points, with the [lb,ub] interval
%   backgrounds in one further Line per class (grey = bounds, amber =
%   visited range; two full-width reference lines in the compact large-n
%   display), the criteria panel uses one Line per criterion so each bar
%   keeps its own colour.
%
%   INFO is the per-iteration struct built by PLOTINFO (the same struct passed
%   to opts.PlotFcn).  The figure (Tag 'adamnlopt.plotIteration') is created on
%   the first call and its handle kept in a persistent, so later calls --
%   including later solves -- update the SAME window; if the user closes it,
%   the next call simply opens a fresh one.  The plot's history resets when a
%   new solve starts (iteration 0) or the problem dimensions change.
%
%   GUI elements are only ever CREATED when the figure is built or a new solve
%   starts (one Line per bar, one feasibility line, one tolerance reference,
%   one objective line, one text per criterion).  Within a solve every update
%   is data-only: XData/YData of the variable-bar Line, XData/YData of the
%   feasibility/objective lines, XData/Color of the criteria-bar Lines, and
%   the String/Position of the annotation texts.  Nothing is deleted and
%   nothing is recreated between iterations, which keeps a long solve cheap
%   even with hundreds of plotted quantities.  The figure is always created
%   in the light theme (see the persistent figure block), so the bars,
%   reference lines, and annotations render with the classic light look no
%   matter what the desktop theme is.
%
%   This function is the implementation behind opts.Plot = true, and because
%   it is a public PlotFcn itself it can also be attached directly:
%   opts.PlotFcn = @adamnlopt.plotIteration.
%
%   Inputs:
%     info - scalar struct from PLOTINFO (fields x, fval, constrviolation,
%            iteration, stop, exitflag, message, criteria, lb, ub).  Missing
%            optional fields are tolerated; missing x / fval / iteration /
%            criteria are not.  Without lb/ub (a hand-built info struct) the
%            variables panel falls back to raw unscaled values.
%
%   Outputs:
%     (none) the uifigure is created or updated in place.
%
%   See also PLOTINFO, DEFAULTOPTIONS, SOLVE.

persistent fig
if isempty(fig) || ~isvalid(fig)
    % Drop any leftover windows with this tag (e.g. from an older version of
    % this function that may still be on screen) so the user never stares at
    % a stale plot.
    delete(findall(groot, 'Type', 'Figure', 'Tag', 'adamnlopt.plotIteration'));
    % First call of the session, or the user closed the window in between:
    % create the figure and its 2x2 grid once and keep the handle.  The plot
    % ALWAYS uses the classic light appearance ('Theme','light') regardless
    % of the desktop theme: on a dark theme the uiaxes content -- in
    % particular the criteria bars -- can render effectively invisible.
    fig = uifigure('Name', 'adamnlopt iteration plot', ...
        'Tag', 'adamnlopt.plotIteration', 'Position', [100 60 1280 780], ...
        'Theme', 'light');
    g = uigridlayout(fig, [2 2], ...
        'RowHeight', {'1x', '1x'}, 'ColumnWidth', {'1x', '1x'});
    ax = [uiaxes(g), uiaxes(g), uiaxes(g), uiaxes(g)];
    for i = 1:4
        ax(i).XLabel.String = 'iteration';
        ax(i).Box = 'on';
        ax(i).FontSize = 9;
        ax(i).Color = 'w';
        ax(i).XColor = [0.15 0.15 0.15];
        ax(i).YColor = [0.15 0.15 0.15];
        ax(i).GridColor = [0.8 0.8 0.8];
    end
    ud = struct('ax', ax, 'iterHist', [], 'xLine', gobjects(1), ...
        'xLineU', gobjects(1), 'nVars', 0, ...
        'feasHist', [], 'feasLine', gobjects(1), 'tolLine', gobjects(1), ...
        'fHist', [], 'fLine', gobjects(1), ...
        'critLines', gobjects(1, 0), 'critLine', gobjects(1), ...
        'critText', gobjects(0), 'critN', 0, ...
        'normMode', false, 'lb', [], 'ub', [], 'isBounded', [], ...
        'dispMin', [], 'dispMax', [], ...
        'bndLine', gobjects(1), 'dispLine', gobjects(1), 'vText', gobjects(0));
    fig.UserData = ud;
else
    ud = fig.UserData;
end

k = info.iteration;
n = numel(info.x);

% A new solve (iteration 0) or a changed dimension starts a fresh trace.  The
% dimension tests also cover a figure left over from a DIFFERENT problem being
% reused by mistake, where reinterpreting the old handles would misdraw.
if k == 0 || ud.nVars ~= n ...
        || (numel(ud.iterHist) > 0 && ud.iterHist(end) ~= k - 1)
    ud.iterHist = k;
    ud.fHist    = info.fval;
    ud.feasHist = feasValue(info);
    ud = initPanels(ud, info);
else
    ud.iterHist = [ud.iterHist, k];
    ud.fHist    = [ud.fHist, info.fval];
    ud.feasHist = [ud.feasHist, feasValue(info)];
    % Data-only updates: set the data of the EXISTING graphics objects.  The
    % variable bars show only the current iterate (no history), so the bar
    % Line's interleaved segment data is replaced wholesale; the
    % feasibility/objective traces extend in place and the tolerance
    % reference is extended to cover the new iteration.
    if ud.normMode
        % Bounds present: each bar is the fraction of the variable's own
        % [lb,ub] interval (or of the range visited so far, when unbounded),
        % mapped onto the symmetric axis where lb = -1 and ub = +1.  Every
        % bar starts on the shared baseline at 0: one at its lower bound
        % points DOWN to -1, one at its upper bound points UP to +1.
        [f, ud.dispMin, ud.dispMax] = barFractions(info.x, ud.lb, ud.ub, ...
            ud.isBounded, ud.dispMin, ud.dispMax);
        yc = barCoord(f);
        % Two bar Lines: bounded variables (blue) and unbounded/fixed ones
        % (amber in the compact display, where there is no per-variable
        % background to tell them apart); each carries zero-length segments
        % for the other class.
        ycB = yc;  ycB(~ud.isBounded) = 0;
        ycU = yc;  ycU(ud.isBounded) = 0;
        set(ud.xLine, 'YData', interleaveBarY(ycB, 0));
        set(ud.xLineU, 'YData', interleaveBarY(ycU, 0));
        for i = 1:numel(ud.vText)
            set(ud.vText(i), 'Position', [i yc(i) + 0.03 0], ...
                'String', fmtValue(info.x(i)));
        end
    else
        % No bounds: raw unscaled values, one bar per variable.
        set(ud.xLine, 'XData', reshape([1:n; 1:n], [], 1), ...
            'YData', interleaveBarY(info.x, 0));
    end
    set(ud.feasLine, 'XData', ud.iterHist, 'YData', ud.feasHist);
    set(ud.tolLine, 'XData', [0 k]);
    set(ud.fLine, 'XData', ud.iterHist, 'YData', ud.fHist);
end

% Criteria panel: rebuilt only when the criterion COUNT changes (i.e. at a new
% solve, since the count is fixed within one); otherwise updated data-only.
if numel(info.criteria) ~= ud.critN
    ud = initCriteria(ud, info);
else
    updateCriteria(ud, info);
end
fig.UserData = ud;

if info.stop
    drawnow;                    % final frame: flush the render
else
    drawnow limitrate;          % cap the redraw rate on long solves
end
end

% ------------------------------------------------------------------------
function v = feasValue(info)
%FEASVALUE  The feasibility metric to plot, floored for the log scale.
%   The solver's FEAS metric (info.constrviolation) is the max constraint
%   violation in the scaled space -- exactly the quantity terminationCheck
%   compares against feasTol.  At a converged point it can be exactly zero,
%   which the log axis cannot show, so the plotted value is floored at 1e-20
%   (log10 = -20, visually "bottomed out").  Missing field -> NaN (gap).
if isfield(info, 'constrviolation') && isfinite(info.constrviolation)
    v = max(info.constrviolation, 1e-20);
else
    v = NaN;
end
end

% ------------------------------------------------------------------------
function ud = initPanels(ud, info)
%INITPANELS  (Re)build the variable, feasibility, and objective panels.
%   Called at the start of a solve or when the problem dimensions change:
%   clears the three data panels and creates the variable-bar Line (all
%   bars in one interleaved Line, plus the [lb,ub] interval backgrounds when
%   the problem has bounds), the feasibility trace with its tolerance
%   reference, and the objective trace.  Every subsequent iteration only
%   SETs their data (see plotIteration).
%
%   Inputs:
%     ud   - figure user-data struct (ax, iterHist, feasHist, fHist).
%     info - the current per-iteration info struct.
%
%   Outputs:
%     ud - ud with the new handles (xLine, xLineU, bndLine, dispLine, vText,
%          feasLine, tolLine, fLine) and the display-mode bookkeeping
%          (normMode, lb, ub, isBounded, dispMin, dispMax).
ax1 = ud.ax(1);
cla(ax1);  hold(ax1, 'on');  grid(ax1, 'on');
n = numel(info.x);
cols = themeColors(ax1);
ud.vText = gobjects(0);
ud.bndLine = gobjects(1);  ud.dispLine = gobjects(1);

% Display mode: when at least one variable has both finite bounds, every bar
% is scaled to its own [lb,ub] interval (fraction between the bounds, 0 = lb,
% 1 = ub) so ranges of very different sizes stay comparable on one axis;
% otherwise the raw unscaled values are drawn (no interval background).
[lb, ub] = boundVectors(info, n);
ud.lb = lb;  ud.ub = ub;
ud.isBounded = isfinite(lb) & isfinite(ub) & ub > lb;
ud.normMode = ~isempty(lb) && any(ud.isBounded);

% One bar per variable, current value only (no history): x axis is the
% variable index, y axis the bar height.  All n bars live in ONE Line object
% as interleaved (x,y) segments -- bar-series graphics do not render on
% uiaxes in this build, thick line segments do.  Later calls set the segment
% data wholesale (see plotIteration).
if ud.normMode
    % The visited range of the unbounded/fixed variables, extended as the
    % solve moves; the fraction of every bar is recomputed each iteration.
    ud.dispMin = info.x(:);
    ud.dispMax = info.x(:);
    [f, ud.dispMin, ud.dispMax] = barFractions(info.x, lb, ub, ...
        ud.isBounded, ud.dispMin, ud.dispMax);
    % The fraction between the bounds is mapped onto the symmetric axis
    % where lb = -1 and ub = +1 (midpoint at 0); every bar starts on the
    % shared baseline at 0 and points down toward the lower bound or up
    % toward the upper bound.
    yc = barCoord(f);
    % With few variables the allowed interval is drawn as a thin grey
    % background segment from -1 to +1 behind each bar (amber where it is
    % only the visited range of an unbounded/fixed variable).  With many
    % variables those per-variable segments render as a wall of pegs, so
    % the display goes compact: two full-width reference lines at -1 and +1
    % instead, and bars thinned to roughly one pixel per variable.
    compact = n > 40;
    barW = max(1, min(9, round(520 / n, 1)));
    if compact
        ud.bndLine = plot(ax1, [0.5 n + 0.5], [-1 -1], '-', ...
            'LineWidth', 1.2, 'Color', cols.bnd);
        ud.dispLine = plot(ax1, [0.5 n + 0.5], [1 1], '-', ...
            'LineWidth', 1.2, 'Color', cols.bnd);
    else
        if any(ud.isBounded)
            k = find(ud.isBounded);
            ud.bndLine = plot(ax1, reshape([k; k], [], 1), ...
                reshape([-ones(1, numel(k)); ones(1, numel(k))], [], 1), '-', ...
                'LineWidth', 1.6, 'Color', cols.bnd);
        end
        if any(~ud.isBounded)
            k = find(~ud.isBounded);
            ud.dispLine = plot(ax1, reshape([k; k], [], 1), ...
                reshape([-ones(1, numel(k)); ones(1, numel(k))], [], 1), '-', ...
                'LineWidth', 1.6, 'Color', cols.disp);
        end
    end
    ycB = yc;  ycB(~ud.isBounded) = 0;
    ycU = yc;  ycU(ud.isBounded) = 0;
    ud.xLine = plot(ax1, reshape([1:n; 1:n], [], 1), ...
        interleaveBarY(ycB, 0), '-', 'LineWidth', barW, 'Color', cols.data);
    % Unbounded/fixed bars: amber in the compact display (no per-variable
    % amber background there), blue in the full display where the amber band
    % behind them already identifies them.
    if compact
        ud.xLineU = plot(ax1, reshape([1:n; 1:n], [], 1), ...
            interleaveBarY(ycU, 0), '-', 'LineWidth', barW, 'Color', cols.disp);
    else
        ud.xLineU = plot(ax1, reshape([1:n; 1:n], [], 1), ...
            interleaveBarY(ycU, 0), '-', 'LineWidth', barW, 'Color', cols.data);
    end
    ud.nVars = n;
    % With few variables the physical value of each bar is annotated; with
    % many the labels would collide, so they are omitted.
    if n <= 12
        tt = gobjects(1, n);
        for i = 1:n
            tt(i) = text(ax1, i, yc(i) + 0.03, fmtValue(info.x(i)), ...
                'FontSize', 7, 'Color', cols.line, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
        end
        ud.vText = tt;
    end
    ax1.YLim = [-1.2 1.2];
    ax1.YTick = [-1 0 1];
    ax1.YTickLabel = {'lb', '0', 'ub'};
    if n <= 20
        ax1.XTick = 1:n;
    else
        ax1.XTickMode = 'auto';
    end
    ttl = sprintf(...
        'Variables: fraction between bounds (lb = -1, ub = 1), n = %d', n);
    if any(~ud.isBounded)
        ttl = sprintf('%s  (amber: unbounded/fixed, scaled to visited range)', ttl);
    end
    title(ax1, ttl);
    xlabel(ax1, 'variable index');
    ylabel(ax1, 'fraction of [lb, ub]');
else
    ud.xLine = plot(ax1, reshape([1:n; 1:n], [], 1), ...
        interleaveBarY(info.x, 0), '-', ...
        'LineWidth', 9, 'Color', cols.data);
    ud.nVars = n;
    % Reset the axes to automatic scaling in case a previous solve (with
    % bounds) left manual limits/ticks behind on the reused figure.
    ax1.XTickMode = 'auto';  ax1.YTickMode = 'auto';  ax1.YLimMode = 'auto';
    title(ax1, sprintf('Variables (unscaled), n = %d', n));
    xlabel(ax1, 'variable index');
    ylabel(ax1, 'x_i');
end

ax2 = ud.ax(2);
cla(ax2);  hold(ax2, 'on');  grid(ax2, 'on');
ax2.YScale = 'log';
% The feasibility metric itself, plus the tolerance it must fall below.
ud.feasLine = plot(ax2, ud.iterHist, ud.feasHist, '-', 'LineWidth', 1.2);
tol = feasTolFromCriteria(info);
ud.tolLine = gobjects(1);
if isfinite(tol)
    cols = themeColors(ax2);
    ud.tolLine = plot(ax2, [0 max(ud.iterHist, 1)], [tol tol], '--', ...
        'LineWidth', 1.1, 'Color', cols.line);
end
title(ax2, sprintf('Feasibility: max constraint violation (feasTol = %s)', ...
    fmtValue(tol)));
ylabel(ax2, 'max violation');

ax3 = ud.ax(3);
cla(ax3);  hold(ax3, 'on');  grid(ax3, 'on');
ud.fLine = plot(ax3, ud.iterHist, ud.fHist, 'o-', 'LineWidth', 1.5, ...
    'MarkerSize', 3);
title(ax3, 'Objective (unscaled)');
ylabel(ax3, 'f(x)');
end

% ------------------------------------------------------------------------
function [lb, ub] = boundVectors(info, n)
%BOUNDVECTORS  The full-length bound vectors from the info struct, or [].
%   Returns [],[] when the fields are missing (a hand-built info struct) or
%   their lengths do not match the variable count, so the caller can fall
%   back to the raw unscaled display.
%
%   Inputs:
%     info - per-iteration info struct.
%     n    - number of variables.
%
%   Outputs:
%     lb - n-by-1 lower bounds (-Inf where unbounded); [] when unavailable.
%     ub - n-by-1 upper bounds (+Inf where unbounded); [] when unavailable.
lb = [];  ub = [];
if isfield(info, 'lb') && isfield(info, 'ub')
    lb = info.lb(:);  ub = info.ub(:);
    if numel(lb) ~= n || numel(ub) ~= n
        lb = [];  ub = [];
    end
end
end

% ------------------------------------------------------------------------
function [f, dispMin, dispMax] = barFractions(x, lb, ub, isBounded, dispMin, dispMax)
%BARFRACTIONS  Bar height of every variable: fraction of its display range.
%   A bounded variable (both bounds finite, ub > lb) is scaled to its own
%   [lb,ub] interval, so ranges of very different sizes (1e-6 and 1e6) all
%   read against 0 = lb and 1 = ub on one axis; a value outside the bounds
%   (infeasible iterate) simply shows a bar beyond 1 or below 0.  A variable
%   without finite bounds on both sides -- or a fixed variable, lb == ub --
%   is scaled to the range of values the solve has visited so far (dispMin,
%   dispMax, extended in place with the new x); when that range is still a
%   single point, a symmetric margin of max(1, |x|)/2 around it is used so
%   the bar always has a visible scale.  NaN x propagates (bar invisible).
%
%   Inputs:
%     x         - n-by-1 current variables.
%     lb, ub    - n-by-1 bound vectors (-Inf/+Inf where unbounded).
%     isBounded - n-by-1 logical: variable scaled to its true bounds.
%     dispMin   - n-by-1 running minimum of the visited values.
%     dispMax   - n-by-1 running maximum of the visited values.
%
%   Outputs:
%     f       - n-by-1 bar heights in [0,1] (bounded variables) or around it
%               (display-range variables), NaN for NaN x.
%     dispMin - dispMin extended with x (display-range variables only).
%     dispMax - dispMax extended with x (display-range variables only).
n = numel(x);
f = NaN(n, 1);
b = isBounded;
if any(b)
    f(b) = (x(b) - lb(b)) ./ (ub(b) - lb(b));
end
d = ~b;
if any(d)
    xd = x(d);
    dispMin(d) = min(dispMin(d), xd);
    dispMax(d) = max(dispMax(d), xd);
    lo = dispMin(d);  hi = dispMax(d);
    z = hi - lo <= 0;                    % fixed variable / single visited value
    if any(z)
        half = max(max(1, abs(xd)), abs(lo)) / 2;
        lo(z) = xd(z) - half(z);
        hi(z) = xd(z) + half(z);
    end
    f(d) = (xd - lo) ./ (hi - lo);
end
end

% ------------------------------------------------------------------------
function y = barCoord(f)
%BARCOORD  Display coordinate of a bound-fraction value.
%   Maps the [0,1] fraction between the bounds onto the symmetric axis
%   [-1, 1]: the LOWER bound sits at -1, the UPPER bound at +1, and the
%   midpoint at 0.  Bars drawn from the 0 baseline then point DOWN toward
%   the lower bound and UP toward the upper bound.
y = 2 * f - 1;
end

% ------------------------------------------------------------------------
function y = interleaveBarY(f, base)
%INTERLEAVEBARY  Interleaved (base, f_i) segment data for the bar Line.
%   One bar per variable, each a segment from (i, base) to (i, f_i); the
%   bars are packed into a single Line whose XData is the interleaved
%   indices (see the callers) and YData the interleaved (base, f_i) pairs.
%   The bound display uses base = 0 (the midpoint of the lb/ub axis, so a
%   variable at its lower bound draws a downward bar to -1 and one at its
%   upper bound an upward bar to +1); the raw display also uses 0.
y = reshape([base * ones(1, numel(f)); f(:)'], [], 1);
end

% ------------------------------------------------------------------------
function tol = feasTolFromCriteria(info)
%FEASFOLFROMCRITERIA  The feasibility tolerance from the criteria array.
%   The 'Constraint violation' criterion carries value = feas and limit =
%   feasTol; the tolerance is what the dashed reference line in the
%   feasibility panel marks.  NaN when the criterion is not present (a
%   hand-built info struct): the reference line is simply omitted.
tol = NaN;
crit = info.criteria;
for i = 1:numel(crit)
    if strcmp(crit(i).name, 'Constraint violation')
        tol = crit(i).limit;
        return;
    end
end
end

% ------------------------------------------------------------------------
function ud = initCriteria(ud, info)
%INITCRITERIA  (Re)build the exit-criteria bar panel.
%   Called when the figure is created or the criterion count changes (a new
%   solve).  Creates one thick-Line bar per criterion, the "satisfied"
%   dashed line and label, and one annotation text per criterion -- all of
%   which are then only UPDATED in place by UPDATECRITERIA for the rest of
%   the solve.
%
%   Inputs:
%     ud   - figure user-data struct (ax).
%     info - per-iteration info struct (criteria, stop, exitflag, message).
%
%   Outputs:
%     ud - ud with the criteria handles (critLines, critLine, critText) and
%          the current criterion count (critN).
ax = ud.ax(4);
cla(ax);  hold(ax, 'on');
crit = info.criteria;
ud.critN = numel(crit);
if isempty(crit)
    ud.critLines = gobjects(1, 0);  ud.critText = gobjects(0);
    ax.Title.String = 'Exit criteria: (none reported)';
    return;
end

vals = arrayfun(@(i) barValue(crit, i), 1:numel(crit));
cols = themeColors(ax);
% One horizontal bar per criterion: a THICK LINE SEGMENT from x=0 to the
% closeness value, one Line per criterion so each bar carries its own
% colour (bar-series graphics are not rendered by the uifigure web renderer
% in this build; line segments are).  Later calls only set XData/Color.
ud.critLines = gobjects(1, numel(crit));
for i = 1:numel(crit)
    ud.critLines(i) = plot(ax, [0 vals(i)], [i i], '-', ...
        'LineWidth', 11, 'Color', critColor(crit, vals, i, cols));
end

% The satisfied line at closeness 1, drawn as a plain line (xline is not
% guaranteed on uiaxes across releases), in a theme-visible colour.
ud.critLine = plot(ax, [1 1], [0 numel(crit) + 1.5], '--', ...
    'LineWidth', 1.2, 'Color', cols.line);
text(ax, 1.005, numel(crit) + 1.5, 'satisfied', ...
    'VerticalAlignment', 'bottom', 'FontSize', 8, 'Color', cols.line);

tt = gobjects(1, numel(crit));
for i = 1:numel(crit)
    tt(i) = text(ax, 0, i, '', 'FontSize', 7, ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', ...
        'Color', cols.line);
end
ud.critText = tt;

ax.YTick = 1:numel(crit);
ax.XLim  = [0 1.45];
ax.XTick = [0 0.5 1];

updateCriteria(ud, info);   % fill colors, annotation strings, and title
end

% ------------------------------------------------------------------------
function updateCriteria(ud, info)
%UPDATECRITERIA  Refresh the criteria bars and annotations data-only.
%   Updates the EXISTING criterion-bar Lines (XData = bar length, Color =
%   satisfaction state), the existing annotation texts (String/Position),
%   the Y tick labels, and the title.  No children are created or deleted.
%
%   Inputs:
%     ud   - figure user-data struct (critLines, critText).
%     info - per-iteration info struct (criteria, stop, exitflag, message).
%
%   Outputs:
%     (none) the existing graphics objects are modified in place.
ax = ud.ax(4);
crit = info.criteria;
if isempty(crit)
    ax.Title.String = 'Exit criteria: (none reported)';
    return;
end

vals = arrayfun(@(i) barValue(crit, i), 1:numel(crit));
cols = themeColors(ax);
for i = 1:numel(crit)
    set(ud.critLines(i), 'XData', [0 vals(i)], ...
        'Color', critColor(crit, vals, i, cols));
end
ax.YTickLabel = {crit.name};

for i = 1:numel(crit)
    set(ud.critText(i), 'Position', [max(vals(i), 0) + 0.005, i, 0], ...
        'String', sprintf('%s / %s', fmtValue(crit(i).value), ...
        fmtValue(crit(i).limit)));
end
ax.Title.String = criteriaTitle(info);
end

% ------------------------------------------------------------------------
function v = barValue(crit, i)
%BARVALUE  Bar length for one criterion.
%   The log-decade closeness (CLOSENESSLOG) when the criterion carries one --
%   the three KKT metric criteria -- so the bar shows how many orders of
%   magnitude remain to the tolerance; the linear closeness otherwise (the
%   counter criteria).  NaN propagates (the grey "unknown" bar).
if isfield(crit, 'closenessLog') && isfinite(crit(i).closenessLog)
    v = crit(i).closenessLog;
else
    v = crit(i).closeness;
end
end

% ------------------------------------------------------------------------
function col = critColor(crit, vals, i, cols)
%CRITCOLOR  Colour of one criterion bar: green satisfied, red not, grey NaN.
%   Inputs:
%     crit - the criteria struct array; vals - [crit.closeness]; i - index;
%     cols - palette from THEMECOLORS.
%   Outputs:
%     col - 1x3 RGB triplet.
if isnan(vals(i))
    col = cols.grey;
elseif crit(i).satisfied
    col = cols.green;
else
    col = cols.red;
end
end

% ------------------------------------------------------------------------
function cols = themeColors(ax)
%THEMECOLORS  Palette chosen from the axes background luminance.
%   Returns a struct of RGB triplets for the criterion bars, the dashed
%   reference lines, the annotation texts, and the variable bars.  On a dark
%   axes background (dark desktop theme, luminance < 0.5) the palette is
%   bright; on a light background the classic mid-tone palette is used.
%
%   Inputs:
%     ax - the axes whose background decides the theme.
%
%   Outputs:
%     cols - struct with fields green, red, grey (criterion bars), line
%            (dashed lines and annotation text), data (variable bars), bnd
%            (bound-interval background), disp (visited-range background).
bg = get(ax, 'Color');
if strcmpi(bg, 'none')
    bg = get(ancestor(ax, 'figure'), 'Color');
end
if 0.2126 * bg(1) + 0.7152 * bg(2) + 0.0722 * bg(3) < 0.5
    cols.green = [0.30 0.90 0.42];
    cols.red   = [1.00 0.45 0.30];
    cols.grey  = [0.68 0.68 0.68];
    cols.line  = [0.85 0.85 0.85];
    cols.data  = [0.35 0.60 1.00];
    cols.bnd   = [0.52 0.52 0.52];
    cols.disp  = [1.00 0.75 0.15];
else
    cols.green = [0.20 0.65 0.25];
    cols.red   = [0.80 0.20 0.15];
    cols.grey  = [0.55 0.55 0.55];
    cols.line  = [0.00 0.00 0.00];
    cols.data  = [0.00 0.45 0.74];
    cols.bnd   = [0.80 0.80 0.80];
    cols.disp  = [0.93 0.69 0.13];
end
end

% ------------------------------------------------------------------------
function ttl = criteriaTitle(info)
%CRITERIATITLE  Panel title, with the termination notice on the last call.
ttl = 'Exit criteria (closeness; KKT metrics in log decades)';
if isfield(info, 'stop') && info.stop
    msg = '';
    if isfield(info, 'message') && ~isempty(info.message)
        msg = info.message;
    end
    ef = 0;
    if isfield(info, 'exitflag'), ef = info.exitflag; end
    ttl = sprintf('%s  --  STOP (exitflag %d): %s', ttl, ef, msg);
end
end

% ------------------------------------------------------------------------
function s = fmtValue(v)
%FMTVALUE  Compact rendering of a criterion value or limit.
%   Integers (iteration/function counters, plateau windows) print exactly;
%   everything else prints in %.1e.  NaN/Inf print literally.
if ~isfinite(v)
    if isnan(v), s = 'NaN'; else, s = 'Inf'; end
elseif v == round(v) && abs(v) < 1e6
    s = sprintf('%.0f', v);
else
    s = sprintf('%.1e', v);
end
end