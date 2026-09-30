classdef lvd_EditEngineMixtureGUI_App < matlab.apps.AppBase
    %lvd_EditEngineMixtureGUI_App Editor for an engine propellant mixture.
    %   Programmatic uifigure window in the style of
    %   lvd_EditLimitedThrottleModelGUI_App.  Launched as:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditEngineMixtureGUI_App(engine, output);
    %
    %   On Save the engine's mixture is replaced via setMixture() (or
    %   cleared back to the legacy single pool) and output.output is
    %   {true}; Cancel leaves the engine untouched ({false}).  All edits
    %   apply to a working copy until Save, so Cancel is side-effect free.

    properties (Access = public)
        UIFigure
        GridLayout
        TitleLabel
        MixtureTable
        ButtonGrid
        AddRowButton
        RemoveRowButton
        SaveCloseButton
        ClearMixtureButton
        CancelButton
        SumLabel
    end

    properties (Access = private)
        engine LaunchVehicleEngine
        output AppDesignerGUIOutput
        fluidNames cell = {};
    end

    methods (Access = public)
        function app = lvd_EditEngineMixtureGUI_App(varargin)
            createComponents(app);
            registerApp(app, app.UIFigure);
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}));

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end

    methods (Access = private)
        function startupFcn(app, engine, output)
            app.engine = engine;
            app.output = output;

            lv = engine.lvdData.launchVehicle;
            app.fluidNames = {lv.tankTypes.types.name};

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            app.UIFigure.Name = sprintf('Edit Mixture - %s', app.engine.name);
            app.TitleLabel.Text = sprintf('Propellant mixture for engine "%s"', app.engine.name);
            app.MixtureTable.ColumnFormat{1} = app.fluidNames;

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            [types, fracs] = app.engine.getMixtureSpec();
            if(app.engine.hasCustomMixture())
                data = cell(length(types), 2);
                for(i=1:length(types))
                    data{i,1} = types(i).name;
                    data{i,2} = fracs(i);
                end
            else
                data = {types(1).name, 1};
            end
            app.MixtureTable.Data = data;
            updateSumLabel(app);
        end

        function updateSumLabel(app)
            data = app.MixtureTable.Data;
            if(isempty(data))
                app.SumLabel.Text = 'Sum: - (no rows)';
                return;
            end
            vals = cellfun(@(c) str2double(num2str(c)), data(:,2));
            if(any(isnan(vals)))
                app.SumLabel.Text = 'Sum: - (non-numeric fraction)';
            else
                app.SumLabel.Text = sprintf('Sum: %.9g (must be 1)', sum(vals));
            end
        end

        function onTableEdit(app, ~, ~)
            updateSumLabel(app);
        end

        function onAddRow(app, ~, ~)
            data = app.MixtureTable.Data;
            data(end+1,:) = {app.fluidNames{1}, 0};
            app.MixtureTable.Data = data;
            updateSumLabel(app);
        end

        function onRemoveRow(app, ~, ~)
            data = app.MixtureTable.Data;
            if(size(data,1) <= 1)
                uialert(app.UIFigure, 'A mixture needs at least one row. Use Clear Mixture for legacy behavior.', 'Cannot Remove');
                return;
            end
            data(end,:) = [];
            app.MixtureTable.Data = data;
            updateSumLabel(app);
        end

        function onSave(app, ~, ~)
            data = app.MixtureTable.Data;
            lv = app.engine.lvdData.launchVehicle;

            types = TankFluidType.empty(1,0);
            fracs = [];
            for(i=1:size(data,1))
                idx = find(strcmp(app.fluidNames, strtrim(string(data{i,1}))), 1);
                if(isempty(idx))
                    uialert(app.UIFigure, sprintf('Row %u names an unknown fluid type.', i), 'Invalid Mixture');
                    return;
                end
                types(end+1) = lv.tankTypes.getTypeForInd(idx); %#ok<AGROW>
                fracs(end+1) = str2double(num2str(data{i,2})); %#ok<AGROW>
            end

            try
                app.engine.setMixture(types, fracs);
            catch ME
                uialert(app.UIFigure, ME.message, 'Invalid Mixture');
                return;
            end

            app.output.output = {true};
            uiresume(app.UIFigure);
            delete(app);
        end

        function onClear(app, ~, ~)
            app.engine.clearMixture();
            app.output.output = {true};
            uiresume(app.UIFigure);
            delete(app);
        end

        function onCancel(app, ~, ~)
            app.output.output = {false};
            uiresume(app.UIFigure);
            delete(app);
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 420 340], ...
                'Name', 'Edit Engine Mixture', 'Tag', 'lvd_EditEngineMixtureGUI', ...
                'CloseRequestFcn', @(src,evt) onCancel(app,src,evt));
            setappdata(app.UIFigure, 'LvdEditApp', app);

            app.GridLayout = uigridlayout(app.UIFigure, [4, 1], ...
                'RowHeight', {28, '1x', 22, 40}, 'Padding', [10 10 10 10]);

            app.TitleLabel = uilabel(app.GridLayout, 'Text', 'Propellant mixture', ...
                'FontWeight', 'bold');
            app.TitleLabel.Layout.Row = 1;

            app.MixtureTable = uitable(app.GridLayout, ...
                'ColumnName', {'Fluid Type', 'Fraction'}, ...
                'ColumnFormat', {'char', 'numeric'}, ...
                'ColumnEditable', [true, true], ...
                'CellEditCallback', @(src,evt) onTableEdit(app,src,evt));
            app.MixtureTable.Layout.Row = 2;

            app.SumLabel = uilabel(app.GridLayout, 'Text', 'Sum: -');
            app.SumLabel.Layout.Row = 3;

            app.ButtonGrid = uigridlayout(app.GridLayout, [1, 5], 'Padding', [0 0 0 0]);
            app.ButtonGrid.Layout.Row = 4;
            app.AddRowButton = uibutton(app.ButtonGrid, 'Text', 'Add', ...
                'ButtonPushedFcn', @(src,evt) onAddRow(app,src,evt));
            app.RemoveRowButton = uibutton(app.ButtonGrid, 'Text', 'Remove', ...
                'ButtonPushedFcn', @(src,evt) onRemoveRow(app,src,evt));
            app.SaveCloseButton = uibutton(app.ButtonGrid, 'Text', 'Save', ...
                'ButtonPushedFcn', @(src,evt) onSave(app,src,evt));
            app.ClearMixtureButton = uibutton(app.ButtonGrid, 'Text', 'Legacy', ...
                'Tooltip', 'Clear the mixture and return to the legacy single-pool behavior.', ...
                'ButtonPushedFcn', @(src,evt) onClear(app,src,evt));
            app.CancelButton = uibutton(app.ButtonGrid, 'Text', 'Cancel', ...
                'ButtonPushedFcn', @(src,evt) onCancel(app,src,evt));
        end
    end
end
