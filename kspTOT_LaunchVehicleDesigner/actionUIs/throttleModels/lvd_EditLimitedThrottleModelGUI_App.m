classdef lvd_EditLimitedThrottleModelGUI_App < matlab.apps.AppBase
    %lvd_EditLimitedThrottleModelGUI_App Editor for LimitedThrottleModel.
    %   Programmatic uifigure window that follows the look of the other
    %   throttle model editors.  Launched the same way they are:
    %
    %       output = AppDesignerGUIOutput({false, model});
    %       lvd_EditLimitedThrottleModelGUI_App(model, lv, useContinuity, output);
    %
    %   On Save the LimitedThrottleModel handle is mutated in place and
    %   output.output is set to {true, model}; Cancel leaves the model
    %   untouched and output.output{1} false.

    % Framework components
    properties (Access = public)
        UIFigure
        GridLayout
        TitleLabel
        ButtonGrid
        SaveCloseButton
        CancelButton
    end

    % Base model panel
    properties (Access = public)
        BaseModelPanel
        BaseModelGrid
        BaseModelLabel
        BaseModelCombo
        BaseModelDescLabel
        EditBaseModelButton
    end

    % Dynamic pressure limit panel
    properties (Access = public)
        DynPressPanel
        DynPressGrid
        EnableDynPressCheckbox
        MaxDynPressLabel
        MaxDynPressText
        MaxDynPressUnitLabel
        RampFracLabel
        RampFracText
        RampFracUnitLabel
        MinThrottleLabel
        MinThrottleText
        MinThrottleUnitLabel
    end

    % Acceleration limit panel
    properties (Access = public)
        AccelPanel
        AccelGrid
        EnableAccelCheckbox
        MaxAccelLabel
        MaxAccelText
        MaxAccelUnitLabel
    end

    properties (Access = private)
        model LimitedThrottleModel
        lv LaunchVehicle
        useContinuity(1,1) logical = true;
        output AppDesignerGUIOutput

        %Candidate base models keyed by ThrottleModelEnum member name, so
        %switching the base type and back does not lose edits.
        baseCandidates struct = struct();
    end

    methods (Access = public)
        function app = lvd_EditLimitedThrottleModelGUI_App(varargin)
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
        function startupFcn(app, model, lv, useContinuity, output)
            app.model = model;
            app.lv = lv;
            app.useContinuity = useContinuity;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            [~, enums] = ThrottleModelEnum.getThrottleModelTypeNameStrs();
            enums = enums(enums ~= ThrottleModelEnum.Limited);
            app.BaseModelCombo.Items = {enums.nameStr};
            app.BaseModelCombo.ItemsData = enums;

            baseEnum = app.model.baseModel.getThrottleModelTypeEnum();
            app.baseCandidates = struct();
            app.baseCandidates.(char(baseEnum)) = app.model.baseModel;
            app.BaseModelCombo.Value = baseEnum;
            app.BaseModelDescLabel.Text = baseEnum.desc;

            app.EnableDynPressCheckbox.Value = app.model.enableDynPressLimit;
            app.MaxDynPressText.Value = fullAccNum2Str(app.model.maxDynPress);
            app.RampFracText.Value = fullAccNum2Str(app.model.dynPressRampFrac);
            app.MinThrottleText.Value = fullAccNum2Str(app.model.dynPressMinThrottle);

            app.EnableAccelCheckbox.Value = app.model.enableAccelLimit;
            app.MaxAccelText.Value = fullAccNum2Str(app.model.maxAccel);

            updateEnableStates(app);
        end

        function updateEnableStates(app)
            if(app.EnableDynPressCheckbox.Value)
                dynState = 'on';
            else
                dynState = 'off';
            end
            app.MaxDynPressText.Enable = dynState;
            app.RampFracText.Enable = dynState;
            app.MinThrottleText.Enable = dynState;

            if(app.EnableAccelCheckbox.Value)
                accelState = 'on';
            else
                accelState = 'off';
            end
            app.MaxAccelText.Enable = accelState;
        end

        function baseModel = getSelectedBaseModel(app)
            enum = app.BaseModelCombo.Value;
            key = char(enum);

            if(not(isfield(app.baseCandidates, key)))
                switch enum
                    case ThrottleModelEnum.PolyModel
                        app.baseCandidates.(key) = ThrottlePolyModel.getDefaultThrottleModel();

                    case ThrottleModelEnum.T2WModel
                        app.baseCandidates.(key) = T2WThrottleModel.getDefaultThrottleModel();

                    case ThrottleModelEnum.InterpThrottle
                        app.baseCandidates.(key) = ThrottleInterpolatedModel.getDefaultThrottleModel();

                    otherwise
                        error('Unknown base throttle model type: %s', enum.nameStr);
                end
            end

            baseModel = app.baseCandidates.(key);
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(app.EnableDynPressCheckbox.Value)
                errMsg = validateNumber(str2double(app.MaxDynPressText.Value), 'Maximum Dynamic Pressure', 0, Inf, false, errMsg, app.MaxDynPressText.Value);
                errMsg = validateNumber(str2double(app.RampFracText.Value), 'Dynamic Pressure Ramp Fraction', 0, 1, false, errMsg, app.RampFracText.Value);
                errMsg = validateNumber(str2double(app.MinThrottleText.Value), 'Minimum Throttle at Maximum Dynamic Pressure', 0, 1, false, errMsg, app.MinThrottleText.Value);
            end

            if(app.EnableAccelCheckbox.Value)
                errMsg = validateNumber(str2double(app.MaxAccelText.Value), 'Maximum Acceleration', 0, Inf, false, errMsg, app.MaxAccelText.Value);
            end
        end

        function saveAndClose(app)
            app.model.setBaseModel(app.getSelectedBaseModel());

            app.model.enableDynPressLimit = logical(app.EnableDynPressCheckbox.Value);
            if(app.model.enableDynPressLimit)
                app.model.maxDynPress = str2double(app.MaxDynPressText.Value);
                app.model.dynPressRampFrac = str2double(app.RampFracText.Value);
                app.model.dynPressMinThrottle = str2double(app.MinThrottleText.Value);
            end

            app.model.enableAccelLimit = logical(app.EnableAccelCheckbox.Value);
            if(app.model.enableAccelLimit)
                app.model.maxAccel = str2double(app.MaxAccelText.Value);
            end

            app.output.output = {true, app.model};
            close(app.UIFigure);
        end

        %% Callbacks
        function BaseModelComboValueChanged(app, ~)
            app.BaseModelDescLabel.Text = app.BaseModelCombo.Value.desc;
        end

        function EditBaseModelButtonPushed(app, ~)
            baseModel = app.getSelectedBaseModel();
            [~, editedModel] = baseModel.openEditThrottleModelUI(app.lv, app.useContinuity);

            if(not(isempty(editedModel)))
                app.baseCandidates.(char(app.BaseModelCombo.Value)) = editedModel;
            end
        end

        function EnableCheckboxValueChanged(app, ~)
            updateEnableStates(app);
        end

        function NumericTextValueChanged(~, event)
            event.Source.Value = attemptStrEval(event.Source.Value);
        end

        function SaveCloseButtonPushed(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Errors were found while editing the throttle model.', 'Icon','error');
            end
        end

        function CancelButtonPushed(app, ~)
            app.output.output{1} = false;
            close(app.UIFigure);
        end

        function UIFigureWindowKeyPress(app, event)
            switch(event.Key)
                case {'return', 'enter'}
                    SaveCloseButtonPushed(app, event);
                case 'escape'
                    CancelButtonPushed(app, event);
            end
        end

        %% Components
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 450 470];
            app.UIFigure.Name = 'Edit Limited Throttle Model';
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.WindowStyle = 'modal';
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @UIFigureWindowKeyPress, true);

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {24, 135, 125, 70, 29};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.WordWrap = 'on';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;
            app.TitleLabel.Text = 'Edit Limited Throttle Model';

            %Base model panel
            app.BaseModelPanel = uipanel(app.GridLayout);
            app.BaseModelPanel.Title = 'Base Throttle Model';
            app.BaseModelPanel.FontWeight = 'bold';
            app.BaseModelPanel.FontSize = 10.666;
            app.BaseModelPanel.Layout.Row = 2;
            app.BaseModelPanel.Layout.Column = 1;

            app.BaseModelGrid = uigridlayout(app.BaseModelPanel);
            app.BaseModelGrid.ColumnWidth = {100, '1x'};
            app.BaseModelGrid.RowHeight = {24, '1x', 29};
            app.BaseModelGrid.ColumnSpacing = 5;
            app.BaseModelGrid.RowSpacing = 5;
            app.BaseModelGrid.Padding = [5 5 5 5];

            app.BaseModelLabel = uilabel(app.BaseModelGrid);
            app.BaseModelLabel.HorizontalAlignment = 'right';
            app.BaseModelLabel.FontSize = 10.6666666666667;
            app.BaseModelLabel.Layout.Row = 1;
            app.BaseModelLabel.Layout.Column = 1;
            app.BaseModelLabel.Text = 'Base Model';

            app.BaseModelCombo = uidropdown(app.BaseModelGrid);
            app.BaseModelCombo.ValueChangedFcn = createCallbackFcn(app, @BaseModelComboValueChanged, true);
            app.BaseModelCombo.FontSize = 10.6666666666667;
            app.BaseModelCombo.BackgroundColor = [1 1 1];
            app.BaseModelCombo.Tooltip = 'The throttle law that produces the commanded throttle before any limits are applied.';
            app.BaseModelCombo.Layout.Row = 1;
            app.BaseModelCombo.Layout.Column = 2;

            app.BaseModelDescLabel = uilabel(app.BaseModelGrid);
            app.BaseModelDescLabel.VerticalAlignment = 'top';
            app.BaseModelDescLabel.WordWrap = 'on';
            app.BaseModelDescLabel.FontSize = 10.666;
            app.BaseModelDescLabel.Layout.Row = 2;
            app.BaseModelDescLabel.Layout.Column = [1 2];

            app.EditBaseModelButton = uibutton(app.BaseModelGrid, 'push');
            app.EditBaseModelButton.ButtonPushedFcn = createCallbackFcn(app, @EditBaseModelButtonPushed, true);
            app.EditBaseModelButton.Icon = 'throttle.png';
            app.EditBaseModelButton.FontSize = 10.6666666666667;
            app.EditBaseModelButton.Layout.Row = 3;
            app.EditBaseModelButton.Layout.Column = [1 2];
            app.EditBaseModelButton.Text = 'Edit Base Model';

            %Dynamic pressure panel
            app.DynPressPanel = uipanel(app.GridLayout);
            app.DynPressPanel.Title = 'Dynamic Pressure Limit';
            app.DynPressPanel.FontWeight = 'bold';
            app.DynPressPanel.FontSize = 10.666;
            app.DynPressPanel.Layout.Row = 3;
            app.DynPressPanel.Layout.Column = 1;

            app.DynPressGrid = uigridlayout(app.DynPressPanel);
            app.DynPressGrid.ColumnWidth = {170, '1x', 45};
            app.DynPressGrid.RowHeight = {20, 20, 20, 20};
            app.DynPressGrid.ColumnSpacing = 5;
            app.DynPressGrid.RowSpacing = 5;
            app.DynPressGrid.Padding = [5 5 5 5];

            app.EnableDynPressCheckbox = uicheckbox(app.DynPressGrid);
            app.EnableDynPressCheckbox.ValueChangedFcn = createCallbackFcn(app, @EnableCheckboxValueChanged, true);
            app.EnableDynPressCheckbox.Text = 'Enable dynamic pressure limit';
            app.EnableDynPressCheckbox.FontSize = 10.6666666666667;
            app.EnableDynPressCheckbox.Tooltip = 'Caps the commanded throttle with a linear ramp as dynamic pressure approaches the maximum.';
            app.EnableDynPressCheckbox.Layout.Row = 1;
            app.EnableDynPressCheckbox.Layout.Column = [1 3];

            app.MaxDynPressLabel = uilabel(app.DynPressGrid);
            app.MaxDynPressLabel.HorizontalAlignment = 'right';
            app.MaxDynPressLabel.FontSize = 10.6666666666667;
            app.MaxDynPressLabel.Layout.Row = 2;
            app.MaxDynPressLabel.Layout.Column = 1;
            app.MaxDynPressLabel.Text = 'Max. Dynamic Pressure';

            app.MaxDynPressText = uieditfield(app.DynPressGrid, 'text');
            app.MaxDynPressText.ValueChangedFcn = createCallbackFcn(app, @NumericTextValueChanged, true);
            app.MaxDynPressText.HorizontalAlignment = 'center';
            app.MaxDynPressText.FontSize = 10.6666666666667;
            app.MaxDynPressText.Tooltip = 'Dynamic pressure at which the throttle reaches its minimum value.';
            app.MaxDynPressText.Layout.Row = 2;
            app.MaxDynPressText.Layout.Column = 2;

            app.MaxDynPressUnitLabel = uilabel(app.DynPressGrid);
            app.MaxDynPressUnitLabel.HorizontalAlignment = 'center';
            app.MaxDynPressUnitLabel.FontSize = 10.6666666666667;
            app.MaxDynPressUnitLabel.Layout.Row = 2;
            app.MaxDynPressUnitLabel.Layout.Column = 3;
            app.MaxDynPressUnitLabel.Text = 'kPa';

            app.RampFracLabel = uilabel(app.DynPressGrid);
            app.RampFracLabel.HorizontalAlignment = 'right';
            app.RampFracLabel.FontSize = 10.6666666666667;
            app.RampFracLabel.Layout.Row = 3;
            app.RampFracLabel.Layout.Column = 1;
            app.RampFracLabel.Text = 'Ramp Fraction';

            app.RampFracText = uieditfield(app.DynPressGrid, 'text');
            app.RampFracText.ValueChangedFcn = createCallbackFcn(app, @NumericTextValueChanged, true);
            app.RampFracText.HorizontalAlignment = 'center';
            app.RampFracText.FontSize = 10.6666666666667;
            app.RampFracText.Tooltip = 'Fraction of the maximum dynamic pressure over which the throttle ramps down.  The ramp begins at (1 - fraction) x maximum.';
            app.RampFracText.Layout.Row = 3;
            app.RampFracText.Layout.Column = 2;

            app.RampFracUnitLabel = uilabel(app.DynPressGrid);
            app.RampFracUnitLabel.HorizontalAlignment = 'center';
            app.RampFracUnitLabel.FontSize = 10.6666666666667;
            app.RampFracUnitLabel.Layout.Row = 3;
            app.RampFracUnitLabel.Layout.Column = 3;
            app.RampFracUnitLabel.Text = '';

            app.MinThrottleLabel = uilabel(app.DynPressGrid);
            app.MinThrottleLabel.HorizontalAlignment = 'right';
            app.MinThrottleLabel.FontSize = 10.6666666666667;
            app.MinThrottleLabel.Layout.Row = 4;
            app.MinThrottleLabel.Layout.Column = 1;
            app.MinThrottleLabel.Text = 'Min. Throttle at Max. Q';

            app.MinThrottleText = uieditfield(app.DynPressGrid, 'text');
            app.MinThrottleText.ValueChangedFcn = createCallbackFcn(app, @NumericTextValueChanged, true);
            app.MinThrottleText.HorizontalAlignment = 'center';
            app.MinThrottleText.FontSize = 10.6666666666667;
            app.MinThrottleText.Tooltip = 'Throttle floor applied at and above the maximum dynamic pressure (0 to 1).';
            app.MinThrottleText.Layout.Row = 4;
            app.MinThrottleText.Layout.Column = 2;

            app.MinThrottleUnitLabel = uilabel(app.DynPressGrid);
            app.MinThrottleUnitLabel.HorizontalAlignment = 'center';
            app.MinThrottleUnitLabel.FontSize = 10.6666666666667;
            app.MinThrottleUnitLabel.Layout.Row = 4;
            app.MinThrottleUnitLabel.Layout.Column = 3;
            app.MinThrottleUnitLabel.Text = '';

            %Acceleration panel
            app.AccelPanel = uipanel(app.GridLayout);
            app.AccelPanel.Title = 'Acceleration Limit';
            app.AccelPanel.FontWeight = 'bold';
            app.AccelPanel.FontSize = 10.666;
            app.AccelPanel.Layout.Row = 4;
            app.AccelPanel.Layout.Column = 1;

            app.AccelGrid = uigridlayout(app.AccelPanel);
            app.AccelGrid.ColumnWidth = {170, '1x', 45};
            app.AccelGrid.RowHeight = {20, 20};
            app.AccelGrid.ColumnSpacing = 5;
            app.AccelGrid.RowSpacing = 5;
            app.AccelGrid.Padding = [5 5 5 5];

            app.EnableAccelCheckbox = uicheckbox(app.AccelGrid);
            app.EnableAccelCheckbox.ValueChangedFcn = createCallbackFcn(app, @EnableCheckboxValueChanged, true);
            app.EnableAccelCheckbox.Text = 'Enable acceleration limit';
            app.EnableAccelCheckbox.FontSize = 10.6666666666667;
            app.EnableAccelCheckbox.Tooltip = 'Lowers the throttle so the thrust acceleration never exceeds the maximum.';
            app.EnableAccelCheckbox.Layout.Row = 1;
            app.EnableAccelCheckbox.Layout.Column = [1 3];

            app.MaxAccelLabel = uilabel(app.AccelGrid);
            app.MaxAccelLabel.HorizontalAlignment = 'right';
            app.MaxAccelLabel.FontSize = 10.6666666666667;
            app.MaxAccelLabel.Layout.Row = 2;
            app.MaxAccelLabel.Layout.Column = 1;
            app.MaxAccelLabel.Text = 'Max. Acceleration';

            app.MaxAccelText = uieditfield(app.AccelGrid, 'text');
            app.MaxAccelText.ValueChangedFcn = createCallbackFcn(app, @NumericTextValueChanged, true);
            app.MaxAccelText.HorizontalAlignment = 'center';
            app.MaxAccelText.FontSize = 10.6666666666667;
            app.MaxAccelText.Tooltip = 'Maximum thrust acceleration (thrust divided by vehicle mass).';
            app.MaxAccelText.Layout.Row = 2;
            app.MaxAccelText.Layout.Column = 2;

            app.MaxAccelUnitLabel = uilabel(app.AccelGrid);
            app.MaxAccelUnitLabel.HorizontalAlignment = 'center';
            app.MaxAccelUnitLabel.FontSize = 10.6666666666667;
            app.MaxAccelUnitLabel.Layout.Row = 2;
            app.MaxAccelUnitLabel.Layout.Column = 3;
            app.MaxAccelUnitLabel.Text = 'm/s^2';

            %Buttons
            app.ButtonGrid = uigridlayout(app.GridLayout);
            app.ButtonGrid.ColumnWidth = {'1x', '2x', '2x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.ColumnSpacing = 5;
            app.ButtonGrid.RowSpacing = 5;
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 5;
            app.ButtonGrid.Layout.Column = 1;

            app.SaveCloseButton = uibutton(app.ButtonGrid, 'push');
            app.SaveCloseButton.ButtonPushedFcn = createCallbackFcn(app, @SaveCloseButtonPushed, true);
            app.SaveCloseButton.Icon = 'save-file.png';
            app.SaveCloseButton.FontSize = 10.6666666666667;
            app.SaveCloseButton.Layout.Row = 1;
            app.SaveCloseButton.Layout.Column = 2;
            app.SaveCloseButton.Text = 'Save & Close';

            app.CancelButton = uibutton(app.ButtonGrid, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.Icon = 'cancel.png';
            app.CancelButton.FontSize = 10.6666666666667;
            app.CancelButton.Layout.Row = 1;
            app.CancelButton.Layout.Column = 3;
            app.CancelButton.Text = 'Cancel';
        end
    end
end
