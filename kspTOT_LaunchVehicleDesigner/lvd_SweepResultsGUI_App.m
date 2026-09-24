classdef lvd_SweepResultsGUI_App < matlab.apps.AppBase
    %lvd_SweepResultsGUI_App Shared viewer for sweep and Monte Carlo results.
    %   Programmatic App Designer (uifigure) window in the style of
    %   lvd_ViewPlaybackGUI_App.  Launched with
    %
    %       lvd_SweepResultsGUI_App(results);
    %
    %   where results is an LvdSweepResults (as saved under the variable
    %   sweepResults by LvdSweepResults.writeMat).  The window is NOT modal.
    %
    %   Three tabs:
    %     Data       - one row per case (inputs, outputs, status); CSV export.
    %     Scatter    - X/Y/colour dropdowns; scatter for sampled runs, plus a
    %                  carpet (iso-lines of one input over the other) when the
    %                  run is a two-input full-factorial grid.
    %     Statistics - per-response histogram and empirical CDF, percentile
    %                  table (defaults +/-1,2,3 sigma plus the median, with a
    %                  user-entered override), and a two-response scatter with
    %                  1/2/3 sigma covariance error ellipses.  This one view
    %                  serves insertion error ellipses, dV margin, max-q and
    %                  landing footprint alike.
    %
    %   lvd_SweepResultsGUI_App(results, false) builds the window hidden,
    %   which the unit tests use.  The public methods below the constructor
    %   are the test seam and never open a dialog.

    properties (Access = public)
        UIFigure
        MainGrid
        TitleLabel
        TabGroup

        DataTab
        DataGrid
        DataTable
        DataButtonGrid
        ExportCsvButton
        CopyDataButton
        DataStatusLabel

        ScatterTab
        ScatterGrid
        ScatterControlGrid
        XDropDownLabel
        XDropDown
        YDropDownLabel
        YDropDown
        ColorDropDownLabel
        ColorDropDown
        UpdateScatterButton
        ScatterAxes
        ScatterStatusLabel

        StatsTab
        StatsGrid
        StatsControlGrid
        RespDropDownLabel
        RespDropDown
        PctLevelsLabel
        PctLevelsEdit
        ApplyPctButton
        StatsTable
        HistAxes
        CdfAxes
        EllipsePanel
        EllipseGrid
        EllipseXLabel
        EllipseXDropDown
        EllipseYLabel
        EllipseYDropDown
        EllipseAxes
        StatsStatusLabel

        StatusLabel
    end

    properties (Access = private)
        Results LvdSweepResults
        AllNames cell = {};
        NumInputs double = 0;
    end

    methods (Access = public)
        function app = lvd_SweepResultsGUI_App(varargin)
            createComponents(app);

            %Deliberately NOT registerApp(app, app.UIFigure): the LVD main
            %window is a GUIDE-migrated app whose callbacks fetch their
            %handles through AppManagementService.getFigure (see
            %lvd_ViewPlaybackGUI_App).  Reproduce the two things registerApp
            %does that matter here.
            addlistener(app.UIFigure, 'ObjectBeingDestroyed', @(~,~) delete(app));
            app.startupFcn(varargin{:});

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if(not(isempty(app.UIFigure)) && isvalid(app.UIFigure))
                delete(app.UIFigure);
            end
        end

        function T = getDataTable(app)
            %getDataTable The results as a MATLAB table (test seam).
            T = app.Results.toTable();
        end

        function S = getStatsStruct(app, pctLevels)
            %getStatsStruct Per-response statistics (test seam).
            if(nargin < 2 || isempty(pctLevels))
                pctLevels = LvdSweepResults.DefaultPercentiles;
            end
            S = app.Results.getStatistics(pctLevels);
        end

        function [ex, ey] = getEllipsePoints(app, respIndA, respIndB, nSigma)
            %getEllipsePoints Points of the nSigma covariance ellipse of two
            %responses about their joint mean (test seam).
            [C, validTf] = app.Results.getResponseCovariance(respIndA, respIndB);
            a = app.Results.outputs(validTf, respIndA);
            b = app.Results.outputs(validTf, respIndB);
            center = [mean(a), mean(b)];
            [ex, ey] = LvdSweepResults.getErrorEllipse(C, center, nSigma);
        end

        function setScatterSelections(app, xName, yName, colorName)
            %setScatterSelections Drive the scatter dropdowns (test seam).
            app.setDropDownByText(app.XDropDown, xName);
            app.setDropDownByText(app.YDropDown, yName);
            app.setDropDownByText(app.ColorDropDown, colorName);
            app.updateScatter();
        end

        function [x, y, c] = getScatterData(app)
            %getScatterData The vectors the scatter plot was drawn from.
            [x, y, c] = app.computeScatterVectors();
        end

        function exportCsv(app, filePath)
            %exportCsv Writes the data table without a dialog (test seam).
            arguments
                app
                filePath(1,:) char
            end
            writetable(app.Results.toTable(), filePath);
            app.StatusLabel.Text = sprintf('Wrote %s', filePath);
        end
    end

    methods (Access = private)
        function startupFcn(app, results, showFigure)
            arguments
                app
                results(1,1) LvdSweepResults
                showFigure(1,1) logical = true
            end

            app.Results = results;
            app.NumInputs = width(results.inputs);

            app.buildNameLists();
            app.populateDropDowns();

            app.refreshDataTab();
            app.refreshStatsTab();
            app.updateScatter();
            app.drawEllipseView();

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            if(showFigure)
                app.UIFigure.Visible = 'on';
            end
        end

        function buildNameLists(app)
            r = app.Results;
            nIn = width(r.inputs);
            nOut = width(r.outputs);

            names = {};
            for(i=1:nIn)
                if(i <= numel(r.paramLabels) && not(isempty(r.paramLabels{i})))
                    names{end+1} = r.paramLabels{i}; %#ok<AGROW>
                else
                    names{end+1} = sprintf('Input %u', i); %#ok<AGROW>
                end
            end
            for(j=1:nOut)
                if(j <= numel(r.responseLabels) && not(isempty(r.responseLabels{j})))
                    lbl = r.responseLabels{j};
                    if(j <= numel(r.responseUnits) && not(isempty(r.responseUnits{j})))
                        lbl = sprintf('%s (%s)', lbl, r.responseUnits{j});
                    end
                    names{end+1} = lbl; %#ok<AGROW>
                else
                    names{end+1} = sprintf('Response %u', j); %#ok<AGROW>
                end
            end
            app.AllNames = names;
        end

        function populateDropDowns(app)
            names = app.AllNames;
            if(isempty(names))
                names = {'(no data)'};
            end

            for(kk=1:3)
                ddList = {app.XDropDown, app.YDropDown, app.ColorDropDown};
                dd = ddList{kk};
                dd.Items = names;
            end
            app.ColorDropDown.Items = [{'(none)'}, names];

            nIn = app.NumInputs;
            nTot = numel(names);
            if(nTot >= 1)
                app.XDropDown.Value = names{min(nIn+1, nTot)};
            end
            if(nTot >= 2)
                app.YDropDown.Value = names{min(nIn+2, nTot)};
            end
            app.ColorDropDown.Value = '(none)';

            %Statistics tab dropdowns list responses only.
            r = app.Results;
            respNames = {};
            for(j=1:width(r.outputs))
                if(j <= numel(r.responseLabels) && not(isempty(r.responseLabels{j})))
                    respNames{end+1} = r.responseLabels{j}; %#ok<AGROW>
                else
                    respNames{end+1} = sprintf('Response %u', j); %#ok<AGROW>
                end
            end
            if(isempty(respNames))
                respNames = {'(no responses)'};
            end
            app.RespDropDown.Items = respNames;
            app.EllipseXDropDown.Items = respNames;
            app.EllipseYDropDown.Items = respNames;
            if(numel(respNames) >= 2)
                app.EllipseYDropDown.Value = respNames{2};
            end

            app.PctLevelsEdit.Value = strjoin(compose('%.2f', LvdSweepResults.DefaultPercentiles), ' ');
        end

        function setDropDownByText(~, dd, txt)
            if(any(strcmp(dd.Items, txt)))
                dd.Value = txt;
            end
        end

        function refreshDataTab(app)
            T = app.Results.toTable();
            app.DataTable.Data = table2cell(T);
            app.DataTable.ColumnName = T.Properties.VariableNames;
            app.DataStatusLabel.Text = sprintf('%u case(s).', height(T));
            app.StatusLabel.Text = sprintf('Run "%s": %u case(s), %u response(s).', ...
                app.Results.runName, app.Results.getNumCases(), width(app.Results.outputs));
        end

        function [x, y, c] = computeScatterVectors(app)
            %computeScatterVectors Resolves the dropdown selections to column
            %vectors, aligned row-wise: rows where X or Y is NaN (a case that
            %could not produce that response) are dropped from both, so an
            %input still lines up with the response of its own case.
            r = app.Results;

            xf = app.columnForName(r, app.XDropDown.Value);
            yf = app.columnForName(r, app.YDropDown.Value);

            if(strcmp(app.ColorDropDown.Value, '(none)'))
                cf = [];
            else
                cf = app.columnForName(r, app.ColorDropDown.Value);
            end

            n = max([numel(xf), numel(yf), numel(cf)]);
            xf(end+1:n, 1) = NaN;
            yf(end+1:n, 1) = NaN;
            if(not(isempty(cf)))
                cf(end+1:n, 1) = NaN;
            end

            keep = isfinite(xf) & isfinite(yf);
            if(not(isempty(cf)))
                keep = keep & isfinite(cf);
            end

            x = xf(keep);
            y = yf(keep);
            if(isempty(cf))
                c = [];
            else
                c = cf(keep);
            end
        end

        function v = columnForName(~, r, name)
            %columnForName Full-length values of one AllNames entry: every
            %input row (inputs are always valid), or the response column
            %with NaN wherever that case could not produce it.
            idx = find(strcmp(r.paramLabels, name), 1, 'first');
            if(not(isempty(idx)) && idx <= width(r.inputs))
                v = r.inputs(:, idx);
                v = v(:);
                return;
            end
            %Response labels may carry a unit suffix in AllNames; match the
            %bare label too.
            for(j=1:width(r.outputs))
                bare = '';
                if(j <= numel(r.responseLabels))
                    bare = r.responseLabels{j};
                end
                if(strcmp(name, bare) || startsWith(name, [bare, ' (']))
                    v = r.outputs(:, j);
                    v = v(:);
                    return;
                end
            end
            v = [];
        end

        function updateScatter(app, ~, ~)
            [x, y, c] = app.computeScatterVectors();
            ax = app.ScatterAxes;
            cla(ax);

            app.refreshScatterBanner(numel(x));

            if(isempty(x) || isempty(y))
                title(ax, 'Select X and Y columns');
                return;
            end

            n = min(numel(x), numel(y));
            x = x(1:n);
            y = y(1:n);

            if(isempty(c))
                scatter(ax, x, y, 18, 'filled');
            else
                c = c(1:min(numel(c), n));
                if(numel(c) < n)
                    scatter(ax, x, y, 18, 'filled');
                else
                    scatter(ax, x, y, 18, c, 'filled');
                    colorbar(ax);
                end
            end
            xlabel(ax, app.XDropDown.Value, 'Interpreter', 'none');
            ylabel(ax, app.YDropDown.Value, 'Interpreter', 'none');
            grid(ax, 'on');

            app.drawCarpetIfGrid(ax);
        end

        function refreshScatterBanner(app, numPlotted)
            %refreshScatterBanner "N of M plotted (K excluded)" so failed
            %or unevaluable cases are visibly absent, never silently so.
            total = app.Results.getNumCases();
            excluded = max(total - numPlotted, 0);

            if(excluded == 0)
                app.ScatterStatusLabel.Text = sprintf('%u of %u cases plotted.', numPlotted, total);
            else
                app.ScatterStatusLabel.Text = sprintf(['%u of %u cases plotted ', ...
                    '(%u excluded: failed, unpropagated or unevaluable responses).'], ...
                    numPlotted, total, excluded);
            end
        end

        function drawCarpetIfGrid(app, ax)
            %drawCarpetIfGrid Iso-lines of the Y input over the two swept
            %inputs, when the run is a two-input full-factorial grid and X
            %and Y are those inputs.  Anything else is a plain scatter.
            r = app.Results;
            if(r.samplingMode ~= LvdSweepSamplingEnum.FullFactorial)
                return;
            end
            if(app.NumInputs ~= 2)
                return;
            end
            xi = find(strcmp(r.paramLabels, app.XDropDown.Value), 1, 'first');
            yi = find(strcmp(r.paramLabels, app.YDropDown.Value), 1, 'first');
            if(isempty(xi) || isempty(yi) || xi > 2 || yi > 2 || xi == yi)
                return;
            end
            try
                a = r.inputs(:, xi);
                b = r.inputs(:, yi);
                ua = unique(a);
                ub = unique(b);
                if(numel(ua) < 2 || numel(ub) < 2 || numel(ua)*numel(ub) ~= height(r.inputs))
                    return;
                end
                hold(ax, 'on');
                for(k=1:numel(ub))
                    sel = b == ub(k);
                    [as, ord] = sort(a(sel));
                    bsel = b(sel);
                    plot(ax, as, bsel(ord), '-', 'LineWidth', 1);
                end
                hold(ax, 'off');
            catch
            end
        end

        function refreshStatsTab(app, ~, ~)
            r = app.Results;
            if(width(r.outputs) < 1)
                app.StatsTable.Data = {};
                app.refreshStatsBanner();
                return;
            end

            pctLevels = app.readPctLevels();
            S = r.getStatistics(pctLevels);

            hdr = {'Response', 'n', 'nValid', 'Mean', 'Std', 'Min', 'Max'};
            for(p=pctLevels)
                hdr{end+1} = sprintf('%.2f%%', p); %#ok<AGROW>
            end
            data = cell(numel(S), numel(hdr));
            for(i=1:numel(S))
                data{i,1} = S(i).label;
                data{i,2} = S(i).n;
                data{i,3} = S(i).nValid;
                data{i,4} = S(i).mean;
                data{i,5} = S(i).std;
                data{i,6} = S(i).min;
                data{i,7} = S(i).max;
                for(k=1:numel(pctLevels))
                    data{i,7+k} = S(i).pctValues(k);
                end
            end
            app.StatsTable.Data = data;
            app.StatsTable.ColumnName = hdr;

            app.drawHistCdf();
            app.drawEllipseView();
            app.refreshStatsBanner();
        end

        function refreshStatsBanner(app)
            %refreshStatsBanner Valid-sample count for the plotted response,
            %so histogram/CDF/percentiles are read knowing what they leave
            %out.  Mirrors drawHistCdf's selection.
            r = app.Results;
            total = r.getNumCases();

            if(width(r.outputs) < 1)
                app.StatsStatusLabel.Text = 'No responses in these results.';
                return;
            end

            sel = find(strcmp(app.RespDropDown.Items, app.RespDropDown.Value), 1, 'first');
            if(isempty(sel))
                sel = 1;
            end

            valid = nnz(r.getValidMask(sel));
            excluded = total - valid;

            if(sel >= 1 && sel <= numel(r.responseLabels) && not(isempty(r.responseLabels{sel})))
                lbl = r.responseLabels{sel};
            else
                lbl = sprintf('Response %u', sel);
            end

            if(excluded == 0)
                app.StatsStatusLabel.Text = sprintf('%s: all %u samples valid.', lbl, total);
            else
                app.StatsStatusLabel.Text = sprintf(['%s: %u of %u valid ', ...
                    '(%u excluded: failed, unpropagated or unevaluable).'], ...
                    lbl, valid, total, excluded);
            end
        end

        function pctLevels = readPctLevels(app)
            toks = strsplit(strtrim(app.PctLevelsEdit.Value));
            vals = str2double(toks);
            vals = vals(isfinite(vals) & vals >= 0 & vals <= 100);
            if(isempty(vals))
                vals = LvdSweepResults.DefaultPercentiles;
                app.PctLevelsEdit.Value = strjoin(compose('%.2f', vals), ' ');
            end
            pctLevels = unique(vals);
        end

        function drawHistCdf(app)
            r = app.Results;
            cla(app.HistAxes);
            cla(app.CdfAxes);
            if(width(r.outputs) < 1)
                return;
            end
            sel = find(strcmp(app.RespDropDown.Items, app.RespDropDown.Value), 1, 'first');
            if(isempty(sel))
                sel = 1;
            end
            v = r.outputs(isfinite(r.outputs(:, sel)), sel);
            if(isempty(v))
                title(app.HistAxes, 'No valid samples');
                return;
            end
            histogram(app.HistAxes, v);
            xlabel(app.HistAxes, app.RespDropDown.Value, 'Interpreter', 'none');
            ylabel(app.HistAxes, 'Count');
            grid(app.HistAxes, 'on');

            vs = sort(v);
            n = numel(vs);
            plot(app.CdfAxes, vs, (1:n)/n*100, '-', 'LineWidth', 1.5);
            xlabel(app.CdfAxes, app.RespDropDown.Value, 'Interpreter', 'none');
            ylabel(app.CdfAxes, 'Cumulative %');
            grid(app.CdfAxes, 'on');
        end

        function drawEllipseView(app, ~, ~)
            cla(app.EllipseAxes);
            r = app.Results;
            if(width(r.outputs) < 2)
                title(app.EllipseAxes, 'Two responses required');
                return;
            end
            ia = find(strcmp(app.EllipseXDropDown.Items, app.EllipseXDropDown.Value), 1, 'first');
            ib = find(strcmp(app.EllipseYDropDown.Items, app.EllipseYDropDown.Value), 1, 'first');
            if(isempty(ia))
                ia = 1;
            end
            if(isempty(ib))
                ib = min(2, width(r.outputs));
            end
            [C, validTf] = r.getResponseCovariance(ia, ib);
            a = r.outputs(validTf, ia);
            b = r.outputs(validTf, ib);
            if(isempty(a))
                title(app.EllipseAxes, 'No valid samples');
                return;
            end
            scatter(app.EllipseAxes, a, b, 12, 'filled', 'MarkerFaceAlpha', 0.4);
            hold(app.EllipseAxes, 'on');
            center = [mean(a), mean(b)];
            for(k=[1 2 3])
                [ex, ey] = LvdSweepResults.getErrorEllipse(C, center, k);
                if(not(isempty(ex)))
                    plot(app.EllipseAxes, ex, ey, '-', 'LineWidth', 1.2);
                end
            end
            hold(app.EllipseAxes, 'off');
            xlabel(app.EllipseAxes, app.EllipseXDropDown.Value, 'Interpreter', 'none');
            ylabel(app.EllipseAxes, app.EllipseYDropDown.Value, 'Interpreter', 'none');
            legend(app.EllipseAxes, {'samples', '1\sigma', '2\sigma', '3\sigma'}, 'Location', 'best');
            grid(app.EllipseAxes, 'on');
        end

        function exportCsvButtonPushed(app, ~, ~)
            [fileName, pathName, filterInd] = uiputfile({'*.csv', 'CSV Files (*.csv)'}, 'Export Results', 'sweep_results.csv');
            figure(app.UIFigure);
            if(filterInd == 0)
                return;
            end
            try
                app.exportCsv(fullfile(pathName, fileName));
            catch ME
                uialert(app.UIFigure, sprintf('CSV export failed: %s', ME.message), 'Export Error', 'Icon', 'error');
            end
        end

        function copyDataButtonPushed(app, ~, ~)
            try
                T = app.Results.toTable();
                txt = '';
                txt = [txt, strjoin(T.Properties.VariableNames, '\t'), newline];
                C = table2cell(T);
                for(i=1:size(C,1))
                    row = cell(1, size(C,2));
                    for(j=1:size(C,2))
                        v = C{i,j};
                        if(ischar(v))
                            row{j} = v;
                        elseif(isstring(v))
                            row{j} = char(v);
                        elseif(isnumeric(v))
                            row{j} = num2str(v);
                        else
                            try
                                row{j} = char(v);
                            catch
                                row{j} = '';
                            end
                        end
                    end
                    txt = [txt, strjoin(row, '\t'), newline]; %#ok<AGROW>
                end
                clipboard('copy', txt);
                app.StatusLabel.Text = 'Table copied to the clipboard.';
            catch
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 980 620];
            app.UIFigure.Name = 'Sweep / Monte Carlo Results';
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.HandleVisibility = 'callback';
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);

            app.MainGrid = uigridlayout(app.UIFigure, [3 1]);
            app.MainGrid.RowHeight = {28, '1x', 22};
            app.MainGrid.ColumnWidth = {'1x'};

            app.TitleLabel = uilabel(app.MainGrid);
            app.TitleLabel.Text = 'Sweep / Monte Carlo Results';
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;

            app.TabGroup = uitabgroup(app.MainGrid);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = 1;

            % ---- Data tab ----
            app.DataTab = uitab(app.TabGroup, 'Title', 'Data');
            app.DataGrid = uigridlayout(app.DataTab, [3 1]);
            app.DataGrid.RowHeight = {'1x', 34, 22};
            app.DataGrid.ColumnWidth = {'1x'};

            app.DataTable = uitable(app.DataGrid);
            app.DataTable.RowName = {};
            app.DataTable.ColumnSortable = true;
            app.DataTable.Tooltip = 'One row per case: swept inputs, harvested responses, and the run status.';
            app.DataTable.Layout.Row = 1;
            app.DataTable.Layout.Column = 1;

            app.DataButtonGrid = uigridlayout(app.DataGrid, [1 2]);
            app.DataButtonGrid.ColumnWidth = {'1x', '1x'};
            app.DataButtonGrid.RowHeight = {'1x'};
            app.DataButtonGrid.Padding = [0 0 0 0];
            app.DataButtonGrid.Layout.Row = 2;
            app.DataButtonGrid.Layout.Column = 1;

            app.ExportCsvButton = uibutton(app.DataButtonGrid, 'push');
            app.ExportCsvButton.Text = 'Export CSV...';
            app.ExportCsvButton.ButtonPushedFcn = @(src,evt) app.exportCsvButtonPushed(src,evt);
            app.ExportCsvButton.Tooltip = 'Writes the data table to a CSV file.';
            app.ExportCsvButton.Layout.Row = 1;
            app.ExportCsvButton.Layout.Column = 1;

            app.CopyDataButton = uibutton(app.DataButtonGrid, 'push');
            app.CopyDataButton.Text = 'Copy to Clipboard';
            app.CopyDataButton.ButtonPushedFcn = @(src,evt) app.copyDataButtonPushed(src,evt);
            app.CopyDataButton.Tooltip = 'Copies the data table to the clipboard.';
            app.CopyDataButton.Layout.Row = 1;
            app.CopyDataButton.Layout.Column = 2;

            app.DataStatusLabel = uilabel(app.DataGrid);
            app.DataStatusLabel.HorizontalAlignment = 'center';
            app.DataStatusLabel.FontAngle = 'italic';
            app.DataStatusLabel.Layout.Row = 3;
            app.DataStatusLabel.Layout.Column = 1;

            % ---- Scatter tab ----
            app.ScatterTab = uitab(app.TabGroup, 'Title', 'Scatter / Carpet');
            app.ScatterGrid = uigridlayout(app.ScatterTab, [3 1]);
            app.ScatterGrid.RowHeight = {60, '1x', 22};
            app.ScatterGrid.ColumnWidth = {'1x'};

            app.ScatterControlGrid = uigridlayout(app.ScatterGrid, [2 4]);
            app.ScatterControlGrid.ColumnWidth = {40, '1x', 40, '1x'};
            app.ScatterControlGrid.RowHeight = {22, 22};
            app.ScatterControlGrid.Padding = [0 0 0 0];
            app.ScatterControlGrid.Layout.Row = 1;
            app.ScatterControlGrid.Layout.Column = 1;

            app.XDropDownLabel = uilabel(app.ScatterControlGrid);
            app.XDropDownLabel.Text = 'X';
            app.XDropDownLabel.HorizontalAlignment = 'right';
            app.XDropDownLabel.Layout.Row = 1;
            app.XDropDownLabel.Layout.Column = 1;

            app.XDropDown = uidropdown(app.ScatterControlGrid);
            app.XDropDown.Items = {};
            app.XDropDown.ValueChangedFcn = @(src,evt) app.updateScatter(src,evt);
            app.XDropDown.Tooltip = 'Horizontal axis: any swept input or harvested response.';
            app.XDropDown.Layout.Row = 1;
            app.XDropDown.Layout.Column = 2;

            app.YDropDownLabel = uilabel(app.ScatterControlGrid);
            app.YDropDownLabel.Text = 'Y';
            app.YDropDownLabel.HorizontalAlignment = 'right';
            app.YDropDownLabel.Layout.Row = 1;
            app.YDropDownLabel.Layout.Column = 3;

            app.YDropDown = uidropdown(app.ScatterControlGrid);
            app.YDropDown.Items = {};
            app.YDropDown.ValueChangedFcn = @(src,evt) app.updateScatter(src,evt);
            app.YDropDown.Tooltip = 'Vertical axis: any swept input or harvested response.';
            app.YDropDown.Layout.Row = 1;
            app.YDropDown.Layout.Column = 4;

            app.ColorDropDownLabel = uilabel(app.ScatterControlGrid);
            app.ColorDropDownLabel.Text = 'Colour';
            app.ColorDropDownLabel.HorizontalAlignment = 'right';
            app.ColorDropDownLabel.Layout.Row = 2;
            app.ColorDropDownLabel.Layout.Column = 1;

            app.ColorDropDown = uidropdown(app.ScatterControlGrid);
            app.ColorDropDown.Items = {};
            app.ColorDropDown.ValueChangedFcn = @(src,evt) app.updateScatter(src,evt);
            app.ColorDropDown.Tooltip = 'Point colour: any column, or none for a plain scatter.';
            app.ColorDropDown.Layout.Row = 2;
            app.ColorDropDown.Layout.Column = 2;

            app.UpdateScatterButton = uibutton(app.ScatterControlGrid, 'push');
            app.UpdateScatterButton.Text = 'Update Plot';
            app.UpdateScatterButton.ButtonPushedFcn = @(src,evt) app.updateScatter(src,evt);
            app.UpdateScatterButton.Tooltip = 'Redraws the scatter from the current selections.';
            app.UpdateScatterButton.Layout.Row = 2;
            app.UpdateScatterButton.Layout.Column = 4;

            app.ScatterAxes = uiaxes(app.ScatterGrid);
            app.ScatterAxes.Layout.Row = 2;
            app.ScatterAxes.Layout.Column = 1;

            app.ScatterStatusLabel = uilabel(app.ScatterGrid);
            app.ScatterStatusLabel.HorizontalAlignment = 'center';
            app.ScatterStatusLabel.FontAngle = 'italic';
            app.ScatterStatusLabel.Layout.Row = 3;
            app.ScatterStatusLabel.Layout.Column = 1;

            % ---- Statistics tab ----
            app.StatsTab = uitab(app.TabGroup, 'Title', 'Statistics');
            app.StatsGrid = uigridlayout(app.StatsTab, [5 1]);
            app.StatsGrid.RowHeight = {30, 120, '1x', '1x', 22};
            app.StatsGrid.ColumnWidth = {'1x'};

            app.StatsControlGrid = uigridlayout(app.StatsGrid, [1 6]);
            app.StatsControlGrid.ColumnWidth = {70, '1.5x', 110, '1.5x', 90, 70};
            app.StatsControlGrid.RowHeight = {'1x'};
            app.StatsControlGrid.Padding = [0 0 0 0];
            app.StatsControlGrid.Layout.Row = 1;
            app.StatsControlGrid.Layout.Column = 1;

            app.RespDropDownLabel = uilabel(app.StatsControlGrid);
            app.RespDropDownLabel.Text = 'Response';
            app.RespDropDownLabel.HorizontalAlignment = 'right';
            app.RespDropDownLabel.Layout.Row = 1;
            app.RespDropDownLabel.Layout.Column = 1;

            app.RespDropDown = uidropdown(app.StatsControlGrid);
            app.RespDropDown.Items = {};
            app.RespDropDown.ValueChangedFcn = @(src,evt) app.refreshStatsTab(src,evt);
            app.RespDropDown.Tooltip = 'Response summarized by the histogram, CDF and percentile table.';
            app.RespDropDown.Layout.Row = 1;
            app.RespDropDown.Layout.Column = 2;

            app.PctLevelsLabel = uilabel(app.StatsControlGrid);
            app.PctLevelsLabel.Text = 'Percentiles';
            app.PctLevelsLabel.HorizontalAlignment = 'right';
            app.PctLevelsLabel.Tooltip = 'Space-separated percentile levels between 0 and 100.';
            app.PctLevelsLabel.Layout.Row = 1;
            app.PctLevelsLabel.Layout.Column = 3;

            app.PctLevelsEdit = uieditfield(app.StatsControlGrid, 'text');
            app.PctLevelsEdit.Tooltip = 'Space-separated percentile levels between 0 and 100.';
            app.PctLevelsEdit.Layout.Row = 1;
            app.PctLevelsEdit.Layout.Column = 4;

            app.ApplyPctButton = uibutton(app.StatsControlGrid, 'push');
            app.ApplyPctButton.Text = 'Apply';
            app.ApplyPctButton.ButtonPushedFcn = @(src,evt) app.refreshStatsTab(src,evt);
            app.ApplyPctButton.Tooltip = 'Recomputes the percentile table with the entered levels.';
            app.ApplyPctButton.Layout.Row = 1;
            app.ApplyPctButton.Layout.Column = 5;

            app.StatsTable = uitable(app.StatsGrid);
            app.StatsTable.RowName = {};
            app.StatsTable.ColumnSortable = true;
            app.StatsTable.Tooltip = 'Per-response summary: sample counts, moments and the requested percentiles.';
            app.StatsTable.Layout.Row = 2;
            app.StatsTable.Layout.Column = 1;

            statsPlotGrid = uigridlayout(app.StatsGrid, [1 2]);
            statsPlotGrid.ColumnWidth = {'1x', '1x'};
            statsPlotGrid.RowHeight = {'1x'};
            statsPlotGrid.Padding = [0 0 0 0];
            statsPlotGrid.Layout.Row = 3;
            statsPlotGrid.Layout.Column = 1;

            app.HistAxes = uiaxes(statsPlotGrid);
            app.HistAxes.Title.String = 'Histogram';
            app.HistAxes.Layout.Row = 1;
            app.HistAxes.Layout.Column = 1;

            app.CdfAxes = uiaxes(statsPlotGrid);
            app.CdfAxes.Title.String = 'Empirical CDF';
            app.CdfAxes.Layout.Row = 1;
            app.CdfAxes.Layout.Column = 2;

            app.EllipsePanel = uipanel(app.StatsGrid);
            app.EllipsePanel.Title = 'Two-Response Error Ellipse (1/2/3 sigma)';
            app.EllipsePanel.FontWeight = 'bold';
            app.EllipsePanel.Layout.Row = 4;
            app.EllipsePanel.Layout.Column = 1;

            app.EllipseGrid = uigridlayout(app.EllipsePanel, [1 5]);
            app.EllipseGrid.ColumnWidth = {40, '1x', 40, '1x', '1.5x'};
            app.EllipseGrid.RowHeight = {'1x'};

            app.EllipseXLabel = uilabel(app.EllipseGrid);
            app.EllipseXLabel.Text = 'X';
            app.EllipseXLabel.HorizontalAlignment = 'right';
            app.EllipseXLabel.Layout.Row = 1;
            app.EllipseXLabel.Layout.Column = 1;

            app.EllipseXDropDown = uidropdown(app.EllipseGrid);
            app.EllipseXDropDown.Items = {};
            app.EllipseXDropDown.ValueChangedFcn = @(src,evt) app.drawEllipseView(src,evt);
            app.EllipseXDropDown.Tooltip = 'Horizontal response of the error-ellipse plot.';
            app.EllipseXDropDown.Layout.Row = 1;
            app.EllipseXDropDown.Layout.Column = 2;

            app.EllipseYLabel = uilabel(app.EllipseGrid);
            app.EllipseYLabel.Text = 'Y';
            app.EllipseYLabel.HorizontalAlignment = 'right';
            app.EllipseYLabel.Layout.Row = 1;
            app.EllipseYLabel.Layout.Column = 3;

            app.EllipseYDropDown = uidropdown(app.EllipseGrid);
            app.EllipseYDropDown.Items = {};
            app.EllipseYDropDown.ValueChangedFcn = @(src,evt) app.drawEllipseView(src,evt);
            app.EllipseYDropDown.Tooltip = 'Vertical response of the error-ellipse plot.';
            app.EllipseYDropDown.Layout.Row = 1;
            app.EllipseYDropDown.Layout.Column = 4;

            app.EllipseAxes = uiaxes(app.EllipseGrid);
            app.EllipseAxes.Layout.Row = 1;
            app.EllipseAxes.Layout.Column = 5;

            app.StatsStatusLabel = uilabel(app.StatsGrid);
            app.StatsStatusLabel.HorizontalAlignment = 'center';
            app.StatsStatusLabel.FontAngle = 'italic';
            app.StatsStatusLabel.Layout.Row = 5;
            app.StatsStatusLabel.Layout.Column = 1;

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = 1;
        end
    end
end
