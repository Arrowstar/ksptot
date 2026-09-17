classdef lvd_ConstraintTableGUI_App < matlab.apps.AppBase
    %lvd_ConstraintTableGUI_App Status table of every LVD optimization constraint.
    %   Programmatic App Designer (uifigure) window in the style of
    %   lvd_editAdamNlOptOptionsGUI_App.  Launched from the LVD main window as
    %
    %       lvd_ConstraintTableGUI_App(lvdData);
    %
    %   The window is NOT modal and does not block.  It shows the values,
    %   bounds and violations recorded by the most recent constraint
    %   evaluation (lvdData.optimizer.constraints.lastRunValues) and refreshes
    %   itself whenever the script finishes propagating.  "Evaluate Now"
    %   re-evaluates the constraints against the current state log without
    %   propagating.  The Active column is editable in place.
    %
    %   Violation cells are green when the constraint is satisfied within the
    %   optimizer's tolerance (scaled violation <= 1e-6), amber when the scaled
    %   violation is small (< 1e-3) and red otherwise.  For a state comparison
    %   (Y == X between two events) the status depends only on the difference,
    %   never on how large Y and X are.
    %
    %   lvd_ConstraintTableGUI_App(lvdData, false) builds the window hidden,
    %   which the unit tests use.

    % Framework components
    properties (Access = public)
        UIFigure
        MainGrid
        TitleLabel
        ConstrTable
        ButtonGrid
        RefreshButton
        EvaluateButton
        CopyButton
        CloseButton
        StatusLabel
    end

    properties (Access = private)
        LvdData
        RowMeta
        Listeners
    end

    properties (Constant, Access = private)
        OkColor       = [0.78 0.93 0.78];
        MarginalColor = [1.00 0.93 0.75];
        ViolatedColor = [0.98 0.75 0.75];

        %The highlight backgrounds are light, so the text on them is pinned
        %dark; a dark theme's default (light) font would vanish otherwise.
        HighlightFontColor = [0.10 0.10 0.10];
    end

    methods (Access = public)
        function app = lvd_ConstraintTableGUI_App(varargin)
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}));

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            for(i=1:numel(app.Listeners)) %#ok<*NO4LP>
                if(isvalid(app.Listeners{i}))
                    delete(app.Listeners{i});
                end
            end
            app.Listeners = {};

            if(not(isempty(app.UIFigure)) && isvalid(app.UIFigure))
                delete(app.UIFigure);
            end
        end

        function refresh(app)
            %refresh Rebuilds the table from the constraint set's last run values.
            if(isempty(app.LvdData) || not(isvalid(app.ConstrTable)))
                return;
            end

            [data, meta] = LvdOptimTableModel.getConstraintRows(app.LvdData);
            app.RowMeta = meta;

            app.ConstrTable.Data = data;

            violCol = find(strcmp(LvdOptimTableModel.ConstrColumns, 'Violation'), 1);
            scaledViolCol = find(strcmp(LvdOptimTableModel.ConstrColumns, 'Scaled Violation'), 1);

            removeStyle(app.ConstrTable);

            %Row style first so the cell highlights (added later, therefore
            %on top) keep their own legible font colour on inactive rows.
            inactiveRows = find(not(cellfun(@(c) c.active, {meta.const})));
            if(not(isempty(inactiveRows)))
                addStyle(app.ConstrTable, uistyle('FontColor', [0.55 0.55 0.55]), 'row', inactiveRows(:));
            end

            statuses = {meta.status};
            app.styleCells(find(strcmp(statuses, 'ok')),       app.OkColor,       [violCol, scaledViolCol]);
            app.styleCells(find(strcmp(statuses, 'marginal')), app.MarginalColor, [violCol, scaledViolCol]);
            app.styleCells(find(strcmp(statuses, 'violated')), app.ViolatedColor, [violCol, scaledViolCol]);

            numViolated = nnz(strcmp(statuses, 'violated'));
            numMarginal = nnz(strcmp(statuses, 'marginal'));
            numUnknown = nnz(strcmp(statuses, 'unknown'));
            if(isempty(meta))
                app.StatusLabel.Text = 'The mission has no constraints.';
            elseif(numUnknown == numel(meta))
                app.StatusLabel.Text = 'Constraints have not been evaluated yet.  Run the script or press "Evaluate Now".';
            else
                app.StatusLabel.Text = sprintf('%u constraint(s): %u violated, %u marginal, %u not evaluated.', ...
                                               numel(meta), numViolated, numMarginal, numUnknown);
            end
        end

        function data = getTableData(app)
            data = app.ConstrTable.Data;
        end

        function meta = getRowMeta(app)
            meta = app.RowMeta;
        end

        function [ok, msg] = applyCellEdit(app, rowInd, colInd, newValue, prevValue)
            %applyCellEdit Shared body of the table CellEditCallback; also
            %the entry point the tests drive directly.
            ok = false;
            msg = '';

            if(rowInd < 1 || rowInd > numel(app.RowMeta))
                return;
            end

            columnName = LvdOptimTableModel.ConstrColumns{colInd};
            [ok, msg] = LvdOptimTableModel.applyConstraintEdit(app.LvdData, app.RowMeta(rowInd), columnName, newValue);

            if(not(ok))
                if(nargin >= 5 && isvalid(app.ConstrTable))
                    app.ConstrTable.Data{rowInd, colInd} = prevValue;
                end

                if(isvalid(app.UIFigure) && strcmp(app.UIFigure.Visible, 'on'))
                    uialert(app.UIFigure, msg, 'Invalid Entry');
                end
            end

            refresh(app);
        end

        function [ok, msg] = evaluateNow(app)
            [ok, msg] = LvdOptimTableModel.evaluateConstraintsNow(app.LvdData);

            if(not(ok) && isvalid(app.UIFigure) && strcmp(app.UIFigure.Visible, 'on'))
                uialert(app.UIFigure, msg, 'Constraint Evaluation');
            end

            refresh(app);

            if(not(ok))
                app.StatusLabel.Text = msg;
            end
        end

        function txt = copyToClipboard(app)
            txt = LvdOptimTableModel.toClipboardText(LvdOptimTableModel.ConstrColumns, app.ConstrTable.Data);

            try
                clipboard('copy', txt);
            catch
                %clipboard is unavailable in some headless sessions; the
                %text is still returned to the caller
            end

            app.StatusLabel.Text = 'Table copied to the clipboard.';
        end
    end

    methods (Access = private)
        function startupFcn(app, lvdData, showFigure)
            arguments
                app
                lvdData(1,1) LvdData
                showFigure(1,1) logical = true
            end

            app.LvdData = lvdData;
            app.Listeners = {};

            app.Listeners{end+1} = addlistener(lvdData.script, 'ScriptPropagationFinished', @(~,~) refresh(app));

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            refresh(app);

            if(showFigure)
                app.UIFigure.Visible = 'on';
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1060 460];
            app.UIFigure.Name = 'LVD Constraint Status';
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);

            app.MainGrid = uigridlayout(app.UIFigure, [4 1]);
            app.MainGrid.RowHeight = {28, '1x', 'fit', 34};
            app.MainGrid.ColumnWidth = {'1x'};

            app.TitleLabel = uilabel(app.MainGrid);
            app.TitleLabel.Text = 'Constraint Status';
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;

            app.ConstrTable = uitable(app.MainGrid);
            app.ConstrTable.ColumnName = LvdOptimTableModel.ConstrColumns;
            app.ConstrTable.ColumnEditable = LvdOptimTableModel.ConstrColumnEditable;
            app.ConstrTable.ColumnWidth = {'auto', 55, 'auto', 100, 100, 100, 100, 90, 55, 110, 'auto'};
            app.ConstrTable.ColumnSortable = true;
            app.ConstrTable.RowName = {};
            app.ConstrTable.CellEditCallback = @(src, evt) onCellEdit(app, evt);
            app.ConstrTable.Tooltip = {'Values come from the most recent constraint evaluation.  For a state comparison the bound columns show the other event''s value.  Violation cells are green when satisfied within the optimizer tolerance (scaled violation <= 1e-6), amber when the scaled violation is below 1e-3, red otherwise.  The Active column may be edited in place.'};
            app.ConstrTable.Layout.Row = 2;
            app.ConstrTable.Layout.Column = 1;

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Text = '';
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = 1;

            app.ButtonGrid = uigridlayout(app.MainGrid, [1 4]);
            app.ButtonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 4;
            app.ButtonGrid.Layout.Column = 1;

            app.RefreshButton = uibutton(app.ButtonGrid, 'push');
            app.RefreshButton.Text = 'Refresh';
            app.RefreshButton.ButtonPushedFcn = @(~,~) refresh(app);
            app.RefreshButton.Layout.Row = 1;
            app.RefreshButton.Layout.Column = 1;

            app.EvaluateButton = uibutton(app.ButtonGrid, 'push');
            app.EvaluateButton.Text = 'Evaluate Now';
            app.EvaluateButton.Tooltip = {'Re-evaluates every constraint against the current state log (no propagation).'};
            app.EvaluateButton.ButtonPushedFcn = @(~,~) evaluateNow(app);
            app.EvaluateButton.Layout.Row = 1;
            app.EvaluateButton.Layout.Column = 2;

            app.CopyButton = uibutton(app.ButtonGrid, 'push');
            app.CopyButton.Text = 'Copy to Clipboard';
            app.CopyButton.ButtonPushedFcn = @(~,~) copyToClipboard(app);
            app.CopyButton.Layout.Row = 1;
            app.CopyButton.Layout.Column = 3;

            app.CloseButton = uibutton(app.ButtonGrid, 'push');
            app.CloseButton.Text = 'Close';
            app.CloseButton.ButtonPushedFcn = @(~,~) delete(app);
            app.CloseButton.Layout.Row = 1;
            app.CloseButton.Layout.Column = 4;
        end

        function onCellEdit(app, evt)
            %evt.Indices are indices into Data (not the sorted display), so
            %they map straight onto RowMeta even when a column is sorted.
            applyCellEdit(app, evt.Indices(1), evt.Indices(2), evt.NewData, evt.PreviousData);
        end

        function styleCells(app, rows, color, cols)
            rows = rows(:);
            if(isempty(rows))
                return;
            end

            cells = [];
            for(i=1:numel(cols))
                cells = [cells; rows, repmat(cols(i), numel(rows), 1)]; %#ok<AGROW>
            end

            addStyle(app.ConstrTable, uistyle('BackgroundColor', color, 'FontColor', app.HighlightFontColor), 'cell', cells);
        end
    end
end
