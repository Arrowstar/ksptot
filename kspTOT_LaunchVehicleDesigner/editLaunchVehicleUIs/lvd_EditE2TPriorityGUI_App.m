classdef lvd_EditE2TPriorityGUI_App < matlab.apps.AppBase
    %lvd_EditE2TPriorityGUI_App Editor for engine-to-tank flow priority.
    %   Programmatic uifigure window in the style of
    %   lvd_EditLimitedThrottleModelGUI_App.  Launched as:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditE2TPriorityGUI_App(conn, output);
    %
    %   On Save the connection's priority and flow weight are written in
    %   place (blank weight = NaN = even split) and output.output is
    %   {true}; Cancel leaves the connection untouched ({false}).

    properties (Access = public)
        UIFigure
        GridLayout
        TitleLabel
        PriorityLabel
        PriorityText
        WeightLabel
        WeightText
        WeightHintLabel
        ButtonGrid
        SaveCloseButton
        CancelButton
    end

    properties (Access = private)
        conn EngineToTankConnection
        output AppDesignerGUIOutput
    end

    methods (Access = public)
        function app = lvd_EditE2TPriorityGUI_App(varargin)
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
        function startupFcn(app, conn, output)
            app.conn = conn;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            app.UIFigure.Name = sprintf('Edit Flow Priority - %s', conn.getName());
            app.TitleLabel.Text = sprintf('Flow priority: %s', conn.getName());
            app.PriorityText.Value = num2str(conn.priority);
            if(isnan(conn.flowWeight))
                app.WeightText.Value = '';
            else
                app.WeightText.Value = num2str(conn.flowWeight);
            end

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function onSave(app, ~, ~)
            prio = str2double(strtrim(app.PriorityText.Value));
            if(isnan(prio) || ~isfinite(prio))
                uialert(app.UIFigure, 'Priority must be a finite number (higher drains first).', 'Invalid Priority');
                return;
            end

            wStr = strtrim(app.WeightText.Value);
            if(isempty(wStr))
                w = NaN;
            else
                w = str2double(wStr);
                if(isnan(w) || ~isfinite(w) || w <= 0)
                    uialert(app.UIFigure, 'Flow weight must be blank (even split) or a positive number.', 'Invalid Weight');
                    return;
                end
            end

            app.conn.priority = prio;
            app.conn.flowWeight = w;

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
            app.UIFigure = uifigure('Visible', 'off', 'Position', [100 100 400 200], ...
                'Name', 'Edit Flow Priority', 'Tag', 'lvd_EditE2TPriorityGUI', ...
                'CloseRequestFcn', @(src,evt) onCancel(app,src,evt));
            setappdata(app.UIFigure, 'LvdEditApp', app);

            app.GridLayout = uigridlayout(app.UIFigure, [5, 2], ...
                'RowHeight', {28, 28, 28, 20, 40}, ...
                'ColumnWidth', {120, '1x'}, 'Padding', [10 10 10 10]);

            app.TitleLabel = uilabel(app.GridLayout, 'Text', 'Flow priority', 'FontWeight', 'bold');
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = [1 2];

            app.PriorityLabel = uilabel(app.GridLayout, 'Text', 'Priority');
            app.PriorityLabel.Layout.Row = 2;
            app.PriorityLabel.Layout.Column = 1;
            app.PriorityText = uieditfield(app.GridLayout, 'text', 'Value', '0');
            app.PriorityText.Layout.Row = 2;
            app.PriorityText.Layout.Column = 2;

            app.WeightLabel = uilabel(app.GridLayout, 'Text', 'Flow weight');
            app.WeightLabel.Layout.Row = 3;
            app.WeightLabel.Layout.Column = 1;
            app.WeightText = uieditfield(app.GridLayout, 'text', 'Value', '', ...
                'Placeholder', 'blank = even');
            app.WeightText.Layout.Row = 3;
            app.WeightText.Layout.Column = 2;

            app.WeightHintLabel = uilabel(app.GridLayout, ...
                'Text', 'Higher priority drains first; weight splits ties.', ...
                'FontAngle', 'italic');
            app.WeightHintLabel.Layout.Row = 4;
            app.WeightHintLabel.Layout.Column = [1 2];

            app.ButtonGrid = uigridlayout(app.GridLayout, [1, 2], 'Padding', [0 0 0 0]);
            app.ButtonGrid.Layout.Row = 5;
            app.ButtonGrid.Layout.Column = [1 2];
            app.SaveCloseButton = uibutton(app.ButtonGrid, 'Text', 'Save', ...
                'ButtonPushedFcn', @(src,evt) onSave(app,src,evt));
            app.CancelButton = uibutton(app.ButtonGrid, 'Text', 'Cancel', ...
                'ButtonPushedFcn', @(src,evt) onCancel(app,src,evt));
        end
    end
end
