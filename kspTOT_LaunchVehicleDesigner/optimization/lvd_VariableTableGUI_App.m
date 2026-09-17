classdef lvd_VariableTableGUI_App < matlab.apps.AppBase
    %lvd_VariableTableGUI_App Table of every LVD optimization variable.
    %   Programmatic App Designer (uifigure) window in the style of
    %   lvd_editAdamNlOptOptionsGUI_App.  Launched from the LVD main window as
    %
    %       lvd_VariableTableGUI_App(lvdData);
    %
    %   The window is NOT modal and does not block, so it can sit next to the
    %   main window while the mission is edited.  It refreshes itself whenever
    %   a variable is added to or removed from the mission and whenever the
    %   script finishes propagating.  Lower Bound, Upper Bound and Active are
    %   editable in place; edits are written straight onto the variable
    %   objects (in stored units) through LvdOptimTableModel.
    %
    %   lvd_VariableTableGUI_App(lvdData, false) builds the window hidden,
    %   which the unit tests use.

    % Framework components
    properties (Access = public)
        UIFigure
        MainGrid
        TitleLabel
        VarTable
        ButtonGrid
        RefreshButton
        CopyButton
        CloseButton
        StatusLabel
    end

    properties (Access = private)
        LvdData
        RowMeta
        Listeners
    end

    methods (Access = public)
        function app = lvd_VariableTableGUI_App(varargin)
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
            %refresh Rebuilds the table from the mission's variable set.
            if(isempty(app.LvdData) || not(isvalid(app.VarTable)))
                return;
            end

            [data, meta] = LvdOptimTableModel.getVariableRows(app.LvdData);
            app.RowMeta = meta;

            app.VarTable.Data = data;

            removeStyle(app.VarTable);
            inactiveRows = find(not([meta.inX]));
            if(not(isempty(inactiveRows)))
                addStyle(app.VarTable, uistyle('FontColor', [0.55 0.55 0.55]), 'row', inactiveRows(:));
            end
            onBoundRows = find([meta.onBound]);
            if(not(isempty(onBoundRows)))
                %light highlight, so the text on it is pinned dark for any theme
                addStyle(app.VarTable, uistyle('BackgroundColor', [1.00 0.93 0.75], 'FontColor', [0.10 0.10 0.10]), 'row', onBoundRows(:));
            end

            numInX = nnz([meta.inX]);
            app.StatusLabel.Text = sprintf('%u variable element(s), %u in the optimization vector, %u on a bound.', ...
                                           numel(meta), numInX, numel(onBoundRows));
        end

        function data = getTableData(app)
            data = app.VarTable.Data;
        end

        function [ok, msg] = applyCellEdit(app, rowInd, colInd, newValue, prevValue)
            %applyCellEdit Shared body of the table CellEditCallback; also
            %the entry point the tests drive directly.
            ok = false;
            msg = '';

            if(rowInd < 1 || rowInd > numel(app.RowMeta))
                return;
            end

            columnName = LvdOptimTableModel.VarColumns{colInd};
            [ok, msg] = LvdOptimTableModel.applyVariableEdit(app.LvdData, app.RowMeta(rowInd), columnName, newValue);

            if(not(ok))
                if(nargin >= 5 && isvalid(app.VarTable))
                    app.VarTable.Data{rowInd, colInd} = prevValue;
                end

                if(isvalid(app.UIFigure) && strcmp(app.UIFigure.Visible, 'on'))
                    uialert(app.UIFigure, msg, 'Invalid Entry');
                end
            end

            refresh(app);
        end

        function txt = copyToClipboard(app)
            txt = LvdOptimTableModel.toClipboardText(LvdOptimTableModel.VarColumns, app.VarTable.Data);

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

            app.Listeners{end+1} = addlistener(lvdData.optimizer.vars, 'VarsListUpdatedAddedVar', @(~,~) refresh(app));
            app.Listeners{end+1} = addlistener(lvdData.optimizer.vars, 'VarsListUpdatedRemovedVar', @(~,~) refresh(app));
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
            app.UIFigure.Position = [100 100 960 460];
            app.UIFigure.Name = 'LVD Optimization Variables';
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);

            app.MainGrid = uigridlayout(app.UIFigure, [4 1]);
            app.MainGrid.RowHeight = {28, '1x', 'fit', 34};
            app.MainGrid.ColumnWidth = {'1x'};

            app.TitleLabel = uilabel(app.MainGrid);
            app.TitleLabel.Text = 'Optimization Variables';
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;

            app.VarTable = uitable(app.MainGrid);
            app.VarTable.ColumnName = LvdOptimTableModel.VarColumns;
            app.VarTable.ColumnEditable = LvdOptimTableModel.VarColumnEditable;
            app.VarTable.ColumnWidth = {70, 'auto', 110, 110, 110, 55, 90, 'auto'};
            app.VarTable.ColumnSortable = true;
            app.VarTable.RowName = {};
            app.VarTable.CellEditCallback = @(src, evt) onCellEdit(app, evt);
            app.VarTable.Tooltip = {'Lower Bound, Upper Bound and Active may be edited in place.  Values are shown in display units (deg, %, m).  Rows highlighted in amber sit on a bound.'};
            app.VarTable.Layout.Row = 2;
            app.VarTable.Layout.Column = 1;

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Text = '';
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = 1;

            app.ButtonGrid = uigridlayout(app.MainGrid, [1 3]);
            app.ButtonGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 4;
            app.ButtonGrid.Layout.Column = 1;

            app.RefreshButton = uibutton(app.ButtonGrid, 'push');
            app.RefreshButton.Text = 'Refresh';
            app.RefreshButton.ButtonPushedFcn = @(~,~) refresh(app);
            app.RefreshButton.Layout.Row = 1;
            app.RefreshButton.Layout.Column = 1;

            app.CopyButton = uibutton(app.ButtonGrid, 'push');
            app.CopyButton.Text = 'Copy to Clipboard';
            app.CopyButton.ButtonPushedFcn = @(~,~) copyToClipboard(app);
            app.CopyButton.Layout.Row = 1;
            app.CopyButton.Layout.Column = 2;

            app.CloseButton = uibutton(app.ButtonGrid, 'push');
            app.CloseButton.Text = 'Close';
            app.CloseButton.ButtonPushedFcn = @(~,~) delete(app);
            app.CloseButton.Layout.Row = 1;
            app.CloseButton.Layout.Column = 3;
        end

        function onCellEdit(app, evt)
            %evt.Indices are indices into Data (not the sorted display), so
            %they map straight onto RowMeta even when a column is sorted.
            applyCellEdit(app, evt.Indices(1), evt.Indices(2), evt.NewData, evt.PreviousData);
        end
    end
end
