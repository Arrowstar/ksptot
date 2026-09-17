function hAx = lvd_plotConstraintHistoryTile(tLayout, recorder, tileNum)
%LVD_PLOTCONSTRAINTHISTORYTILE Plots per-constraint violation history in a tile.
%
%   hAx = lvd_plotConstraintHistoryTile(tLayout, recorder, tileNum) draws one
%   line per constraint (inequalities as max(0,c), equalities as abs(ceq))
%   against iteration number in tile tileNum of the TiledChartLayout and
%   returns the axes.  Returns an empty graphics array and leaves the layout
%   untouched when the recorder has no constraint history yet, or when the
%   layout has fewer than tileNum rows (a TiledChartLayout cannot be resized
%   once it holds axes, which is why the LVD optimizers size the observe
%   window layout up front from recorder.expectConstraintHistory; see
%   lvd_numObserveTiles).
%
%   The legend lists at most the eight constraints with the largest
%   violation at the last iteration; the y axis switches to log scale when
%   every plotted value is positive and the data span at least a decade.

    arguments
        tLayout(1,1) matlab.graphics.layout.TiledChartLayout
        recorder(1,1) ma_OptimRecorder
        tileNum(1,1) double = 4
    end

    hAx = matlab.graphics.axis.Axes.empty(1,0);

    if(not(recorder.hasConstraintHistory()))
        return;
    end

    [violations, names, iters] = recorder.getConstraintViolationHistory();
    if(isempty(violations) || all(isnan(violations(:))))
        return;
    end

    if(prod(tLayout.GridSize) < tileNum)
        return;
    end

    hAx = nexttile(tLayout, tileNum);

    numC = size(violations, 2);
    lastRow = violations(end, :);
    lastRow(isnan(lastRow)) = -Inf;
    [~, order] = sort(lastRow, 'descend');
    numLegend = min(8, numC);
    legendInds = order(1:numLegend);

    cla(hAx);
    hold(hAx, 'on');
    hLines = gobjects(1, numC);
    for(k = 1:numC) %#ok<*NO4LP>
        hLines(k) = plot(hAx, iters, violations(:, k), '-', 'LineWidth', 1);
    end
    hold(hAx, 'off');

    positiveVals = violations(violations > 0 & isfinite(violations));
    if(not(isempty(positiveVals)) && all(violations(isfinite(violations)) > 0) && max(positiveVals) / min(positiveVals) >= 10)
        set(hAx, 'YScale', 'log');
    else
        set(hAx, 'YScale', 'linear');
    end

    title(hAx, sprintf('Constraint Violations (worst: %s)', names{order(1)}), 'Interpreter', 'none');
    xlabel(hAx, 'Iteration', 'Interpreter', 'none');
    ylabel(hAx, 'Violation', 'Interpreter', 'none');
    grid(hAx, 'on');
    grid(hAx, 'minor');

    if(numC > 0)
        legend(hAx, hLines(legendInds), names(legendInds), 'Interpreter', 'none', 'Location', 'northeastoutside', 'FontSize', 7);
    end
end
