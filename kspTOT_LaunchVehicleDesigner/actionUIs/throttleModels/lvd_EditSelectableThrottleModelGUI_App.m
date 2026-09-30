classdef lvd_EditSelectableThrottleModelGUI_App < matlab.apps.AppBase
    %lvd_EditSelectableThrottleModelGUI_App Editor for SelectableThrottleModel.
    %   Programmatic uifigure window that follows the look of the other
    %   throttle model editors.  Launched the same way they are:
    %
    %       output = AppDesignerGUIOutput({false, model});
    %       lvd_EditSelectableThrottleModelGUI_App(model, lv, useContinuity, output);
    %
    %   The selectable math branches are edited inline with throttle-native
    %   units (raw 0-1 fractions).  The steering branch sub-dialogs are NOT
    %   reused: they display and accept every coefficient in degrees.
    %
    %   On Save the SelectableThrottleModel handle is mutated in place and
    %   output.output is set to {true, model}; Cancel leaves output false.
    %   (Like the steering editors, field edits apply to the live model as
    %   they are made; Save only validates.)

    % Framework components
    properties (Access = public)
        UIFigure
        GridLayout
        TitleLabel
        ButtonGrid
        SaveCloseButton
        CancelButton
    end

    % Math model selection panel
    properties (Access = public)
        MathModelPanel
        MathModelGrid
        MathModelLabel
        MathModelCombo
        MathModelDescLabel
        ContinuityCheckbox
    end

    % Polynomial branch panel
    properties (Access = public)
        PolyPanel
        PolyGrid
        PolyConstLabel
        PolyConstText
        PolyTermsTable
        PolyButtonGrid
        AddPolyTermButton
        RemovePolyTermButton
    end

    % Sum of sines branch panel
    properties (Access = public)
        SinesPanel
        SinesGrid
        SinesConstLabel
        SinesConstText
        SinesTable
        SinesButtonGrid
        AddSineButton
        RemoveSineButton
    end

    % Linear tangent branch panel
    properties (Access = public)
        LinTanPanel
        LinTanGrid
        LinTanALabel
        LinTanAText
        LinTanADotLabel
        LinTanADotText
        LinTanBLabel
        LinTanBText
        LinTanBDotLabel
        LinTanBDotText
    end

    properties (Access = private)
        model SelectableThrottleModel
        useContinuity(1,1) logical = true;
        output AppDesignerGUIOutput
    end

    methods (Access = public)
        function app = lvd_EditSelectableThrottleModelGUI_App(varargin)
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
        function startupFcn(app, model, ~, useContinuity, output)
            app.model = model;
            app.useContinuity = useContinuity;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            %Only the non-FitNet math models are offered for throttle.
            enums = [SteerMathModelTypeEnum.GenericPoly, ...
                     SteerMathModelTypeEnum.SumOfSines, ...
                     SteerMathModelTypeEnum.LinearTangent];
            app.MathModelCombo.Items = {enums.name};
            app.MathModelCombo.ItemsData = enums;
            app.MathModelCombo.Value = app.model.selModel;
            app.MathModelDescLabel.Text = app.getMathModelDesc(app.model.selModel);

            app.ContinuityCheckbox.Value = app.model.throttleContinuity;
            app.ContinuityCheckbox.Visible = matlab.lang.OnOffSwitchState(app.useContinuity);

            app.refreshBranchPanels();
        end

        function desc = getMathModelDesc(~, enum)
            switch enum
                case SteerMathModelTypeEnum.GenericPoly
                    desc = 'Throttle is a constant offset plus a sum of polynomial terms in time.  Values are raw 0-1 fractions (clamped at run time).';

                case SteerMathModelTypeEnum.SumOfSines
                    desc = 'Throttle is a constant offset plus a sum of sine waves in time.  Values are raw 0-1 fractions (clamped at run time).';

                case SteerMathModelTypeEnum.LinearTangent
                    desc = 'Throttle follows atan(a(t)*dt + b(t)) with linearly varying a and b.  Output is clamped to [0, 1] at run time.';

                otherwise
                    desc = '';
            end
        end

        function refreshBranchPanels(app)
            selModel = app.model.selModel;
            app.PolyPanel.Visible = matlab.lang.OnOffSwitchState(selModel == SteerMathModelTypeEnum.GenericPoly);
            app.SinesPanel.Visible = matlab.lang.OnOffSwitchState(selModel == SteerMathModelTypeEnum.SumOfSines);
            app.LinTanPanel.Visible = matlab.lang.OnOffSwitchState(selModel == SteerMathModelTypeEnum.LinearTangent);

            app.MathModelDescLabel.Text = app.getMathModelDesc(selModel);

            switch selModel
                case SteerMathModelTypeEnum.GenericPoly
                    app.refreshPolyPanel();

                case SteerMathModelTypeEnum.SumOfSines
                    app.refreshSinesPanel();

                case SteerMathModelTypeEnum.LinearTangent
                    app.refreshLinTanPanel();
            end
        end

        function refreshPolyPanel(app)
            branch = app.model.polyModel;
            app.PolyConstText.Value = fullAccNum2Str(branch.const);

            data = cell(numel(branch.terms), 2);
            for(i=1:numel(branch.terms))
                data{i,1} = fullAccNum2Str(branch.terms(i).coeff);
                data{i,2} = fullAccNum2Str(branch.terms(i).exponent);
            end
            app.PolyTermsTable.Data = data;
        end

        function refreshSinesPanel(app)
            branch = app.model.sinesModel;
            app.SinesConstText.Value = fullAccNum2Str(branch.const);

            data = cell(numel(branch.sines), 3);
            for(i=1:numel(branch.sines))
                data{i,1} = fullAccNum2Str(branch.sines(i).amp);
                data{i,2} = fullAccNum2Str(branch.sines(i).period);
                data{i,3} = fullAccNum2Str(branch.sines(i).phase);
            end
            app.SinesTable.Data = data;
        end

        function refreshLinTanPanel(app)
            branch = app.model.linTanModel;
            app.LinTanAText.Value = fullAccNum2Str(branch.a);
            app.LinTanADotText.Value = fullAccNum2Str(branch.a_dot);
            app.LinTanBText.Value = fullAccNum2Str(branch.b);
            app.LinTanBDotText.Value = fullAccNum2Str(branch.b_dot);
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            switch app.model.selModel
                case SteerMathModelTypeEnum.GenericPoly
                    errMsg = validateNumber(str2double(app.PolyConstText.Value), 'Polynomial Constant Offset', -Inf, Inf, false, errMsg, app.PolyConstText.Value);

                case SteerMathModelTypeEnum.SumOfSines
                    errMsg = validateNumber(str2double(app.SinesConstText.Value), 'Sum Of Sines Constant Offset', -Inf, Inf, false, errMsg, app.SinesConstText.Value);
                    for(i=1:numel(app.model.sinesModel.sines))
                        if(app.model.sinesModel.sines(i).period == 0)
                            errMsg{end+1} = sprintf('Sine %u period must not be zero.', i); %#ok<AGROW>
                        end
                    end

                case SteerMathModelTypeEnum.LinearTangent
                    errMsg = validateNumber(str2double(app.LinTanAText.Value), 'Linear Tangent A', -Inf, Inf, false, errMsg, app.LinTanAText.Value);
                    errMsg = validateNumber(str2double(app.LinTanADotText.Value), 'Linear Tangent A Dot', -Inf, Inf, false, errMsg, app.LinTanADotText.Value);
                    errMsg = validateNumber(str2double(app.LinTanBText.Value), 'Linear Tangent B', -Inf, Inf, false, errMsg, app.LinTanBText.Value);
                    errMsg = validateNumber(str2double(app.LinTanBDotText.Value), 'Linear Tangent B Dot', -Inf, Inf, false, errMsg, app.LinTanBDotText.Value);
            end
        end

        function saveAndClose(app)
            if(app.useContinuity)
                app.model.throttleContinuity = logical(app.ContinuityCheckbox.Value);
            end

            app.output.output = {true, app.model};
            close(app.UIFigure);
        end

        %% Callbacks
        function MathModelComboValueChanged(app, event)
            app.model.selModel = event.Value;
            app.refreshBranchPanels();
        end

        function ContinuityCheckboxValueChanged(~, ~)
            %Applied on Save; nothing to do live.
        end

        function PolyConstTextValueChanged(app, event)
            event.Source.Value = attemptStrEval(event.Source.Value);
            value = str2double(event.Source.Value);
            if(not(isnan(value)))
                app.model.polyModel.const = value;
            end
        end

        function SinesConstTextValueChanged(app, event)
            event.Source.Value = attemptStrEval(event.Source.Value);
            value = str2double(event.Source.Value);
            if(not(isnan(value)))
                app.model.sinesModel.const = value;
            end
        end

        function LinTanTextValueChanged(app, event)
            event.Source.Value = attemptStrEval(event.Source.Value);
            value = str2double(event.Source.Value);
            if(isnan(value))
                return;
            end

            branch = app.model.linTanModel;
            if(event.Source == app.LinTanAText)
                branch.a = value;
            elseif(event.Source == app.LinTanADotText)
                branch.a_dot = value;
            elseif(event.Source == app.LinTanBText)
                branch.b = value;
            elseif(event.Source == app.LinTanBDotText)
                branch.b_dot = value;
            end
        end

        function PolyTermsTableCellEdit(app, event)
            row = event.Indices(1);
            col = event.Indices(2);
            value = str2double(event.NewData);

            if(isnan(value))
                uialert(app.UIFigure, 'Polynomial term entries must be numeric.', 'Invalid Input', 'Icon', 'error');
                app.refreshPolyPanel();
                return;
            end

            term = app.model.polyModel.getTermAtInd(row);
            if(isempty(term))
                app.refreshPolyPanel();
                return;
            end

            if(col == 1)
                term.coeff = value;
            else
                term.exponent = value;
            end
            app.refreshPolyPanel();
        end

        function SinesTableCellEdit(app, event)
            row = event.Indices(1);
            col = event.Indices(2);
            value = str2double(event.NewData);

            if(isnan(value))
                uialert(app.UIFigure, 'Sine entries must be numeric.', 'Invalid Input', 'Icon', 'error');
                app.refreshSinesPanel();
                return;
            end

            sine = app.model.sinesModel.getSineAtInd(row);
            if(isempty(sine))
                app.refreshSinesPanel();
                return;
            end

            switch col
                case 1
                    sine.amp = value;
                case 2
                    sine.period = value;
                case 3
                    sine.phase = value;
            end
            app.refreshSinesPanel();
        end

        function AddPolyTermButtonPushed(app, ~)
            branch = app.model.polyModel;
            branch.addTerm(PolynominalTermModel(branch.getT0(), 0, 1));
            app.refreshPolyPanel();
        end

        function RemovePolyTermButtonPushed(app, ~)
            branch = app.model.polyModel;
            if(branch.getNumTerms() <= 1)
                uialert(app.UIFigure, 'The polynomial must keep at least one term.', 'Cannot Remove Term', 'Icon', 'warning');
                return;
            end

            sel = app.PolyTermsTable.Selection;
            if(isempty(sel))
                row = branch.getNumTerms();
            else
                row = sel(1);
            end
            branch.removeTerm(branch.getTermAtInd(row));
            app.refreshPolyPanel();
        end

        function AddSineButtonPushed(app, ~)
            branch = app.model.sinesModel;
            branch.addSine(SineModel(branch.getT0(), 0, 2*pi/100, 0));
            app.refreshSinesPanel();
        end

        function RemoveSineButtonPushed(app, ~)
            branch = app.model.sinesModel;
            if(branch.getNumSines() <= 1)
                uialert(app.UIFigure, 'The sum of sines must keep at least one sine.', 'Cannot Remove Sine', 'Icon', 'warning');
                return;
            end

            sel = app.SinesTable.Selection;
            if(isempty(sel))
                row = branch.getNumSines();
            else
                row = sel(1);
            end
            branch.removeSine(branch.getSineAtInd(row));
            app.refreshSinesPanel();
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
            app.UIFigure.Position = [100 100 470 560];
            app.UIFigure.Name = 'Edit Selectable Throttle Model';
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.WindowStyle = 'modal';
            app.UIFigure.WindowKeyPressFcn = createCallbackFcn(app, @UIFigureWindowKeyPress, true);

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {24, 130, 320, 29};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.WordWrap = 'on';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;
            app.TitleLabel.Text = 'Edit Selectable Throttle Model';

            %Math model selection panel
            app.MathModelPanel = uipanel(app.GridLayout);
            app.MathModelPanel.Title = 'Math Model';
            app.MathModelPanel.FontWeight = 'bold';
            app.MathModelPanel.FontSize = 10.666;
            app.MathModelPanel.Layout.Row = 2;
            app.MathModelPanel.Layout.Column = 1;

            app.MathModelGrid = uigridlayout(app.MathModelPanel);
            app.MathModelGrid.ColumnWidth = {100, '1x'};
            app.MathModelGrid.RowHeight = {24, '1x', 24};
            app.MathModelGrid.ColumnSpacing = 5;
            app.MathModelGrid.RowSpacing = 5;
            app.MathModelGrid.Padding = [5 5 5 5];

            app.MathModelLabel = uilabel(app.MathModelGrid);
            app.MathModelLabel.HorizontalAlignment = 'right';
            app.MathModelLabel.FontSize = 10.6666666666667;
            app.MathModelLabel.Layout.Row = 1;
            app.MathModelLabel.Layout.Column = 1;
            app.MathModelLabel.Text = 'Math Model';

            app.MathModelCombo = uidropdown(app.MathModelGrid);
            app.MathModelCombo.ValueChangedFcn = createCallbackFcn(app, @MathModelComboValueChanged, true);
            app.MathModelCombo.FontSize = 10.6666666666667;
            app.MathModelCombo.BackgroundColor = [1 1 1];
            app.MathModelCombo.Tooltip = 'The time function used to compute the throttle (clamped to [0, 1] at run time).';
            app.MathModelCombo.Layout.Row = 1;
            app.MathModelCombo.Layout.Column = 2;

            app.MathModelDescLabel = uilabel(app.MathModelGrid);
            app.MathModelDescLabel.VerticalAlignment = 'top';
            app.MathModelDescLabel.WordWrap = 'on';
            app.MathModelDescLabel.FontSize = 10.666;
            app.MathModelDescLabel.Layout.Row = 2;
            app.MathModelDescLabel.Layout.Column = [1 2];

            app.ContinuityCheckbox = uicheckbox(app.MathModelGrid);
            app.ContinuityCheckbox.ValueChangedFcn = createCallbackFcn(app, @ContinuityCheckboxValueChanged, true);
            app.ContinuityCheckbox.Text = 'Use throttle continuity (seed constant from prior state)';
            app.ContinuityCheckbox.FontSize = 10.6666666666667;
            app.ContinuityCheckbox.Tooltip = 'When on, the constant offset is set from the throttle at the end of the previous event on propagation.';
            app.ContinuityCheckbox.Layout.Row = 3;
            app.ContinuityCheckbox.Layout.Column = [1 2];

            %Polynomial branch panel
            app.PolyPanel = uipanel(app.GridLayout);
            app.PolyPanel.Title = 'Polynomial Terms (throttle fractions, not degrees)';
            app.PolyPanel.FontWeight = 'bold';
            app.PolyPanel.FontSize = 10.666;
            app.PolyPanel.Layout.Row = 3;
            app.PolyPanel.Layout.Column = 1;

            app.PolyGrid = uigridlayout(app.PolyPanel);
            app.PolyGrid.ColumnWidth = {'1x'};
            app.PolyGrid.RowHeight = {28, '1x', 29};
            app.PolyGrid.ColumnSpacing = 5;
            app.PolyGrid.RowSpacing = 5;
            app.PolyGrid.Padding = [5 5 5 5];

            polyConstGrid = uigridlayout(app.PolyGrid);
            polyConstGrid.ColumnWidth = {130, '1x'};
            polyConstGrid.RowHeight = {'1x'};
            polyConstGrid.Padding = [0 0 0 0];
            polyConstGrid.Layout.Row = 1;
            polyConstGrid.Layout.Column = 1;

            app.PolyConstLabel = uilabel(polyConstGrid);
            app.PolyConstLabel.HorizontalAlignment = 'right';
            app.PolyConstLabel.FontSize = 10.6666666666667;
            app.PolyConstLabel.Layout.Row = 1;
            app.PolyConstLabel.Layout.Column = 1;
            app.PolyConstLabel.Text = 'Constant Offset';

            app.PolyConstText = uieditfield(polyConstGrid, 'text');
            app.PolyConstText.ValueChangedFcn = createCallbackFcn(app, @PolyConstTextValueChanged, true);
            app.PolyConstText.HorizontalAlignment = 'center';
            app.PolyConstText.FontSize = 10.6666666666667;
            app.PolyConstText.Tooltip = 'Constant throttle offset as a 0-1 fraction.';
            app.PolyConstText.Layout.Row = 1;
            app.PolyConstText.Layout.Column = 2;

            app.PolyTermsTable = uitable(app.PolyGrid);
            app.PolyTermsTable.ColumnName = {'Coefficient', 'Exponent'};
            app.PolyTermsTable.ColumnEditable = [true true];
            app.PolyTermsTable.CellEditCallback = createCallbackFcn(app, @PolyTermsTableCellEdit, true);
            app.PolyTermsTable.FontSize = 10.6666666666667;
            app.PolyTermsTable.Tooltip = 'Each row adds coefficient * (dt ^ exponent) to the throttle.';
            app.PolyTermsTable.Layout.Row = 2;
            app.PolyTermsTable.Layout.Column = 1;

            app.PolyButtonGrid = uigridlayout(app.PolyGrid);
            app.PolyButtonGrid.ColumnWidth = {'1x', '1x'};
            app.PolyButtonGrid.RowHeight = {'1x'};
            app.PolyButtonGrid.Padding = [0 0 0 0];
            app.PolyButtonGrid.Layout.Row = 3;
            app.PolyButtonGrid.Layout.Column = 1;

            app.AddPolyTermButton = uibutton(app.PolyButtonGrid, 'push');
            app.AddPolyTermButton.ButtonPushedFcn = createCallbackFcn(app, @AddPolyTermButtonPushed, true);
            app.AddPolyTermButton.FontSize = 10.6666666666667;
            app.AddPolyTermButton.Layout.Row = 1;
            app.AddPolyTermButton.Layout.Column = 1;
            app.AddPolyTermButton.Text = 'Add Term';

            app.RemovePolyTermButton = uibutton(app.PolyButtonGrid, 'push');
            app.RemovePolyTermButton.ButtonPushedFcn = createCallbackFcn(app, @RemovePolyTermButtonPushed, true);
            app.RemovePolyTermButton.FontSize = 10.6666666666667;
            app.RemovePolyTermButton.Layout.Row = 1;
            app.RemovePolyTermButton.Layout.Column = 2;
            app.RemovePolyTermButton.Text = 'Remove Term';

            %Sum of sines branch panel
            app.SinesPanel = uipanel(app.GridLayout);
            app.SinesPanel.Title = 'Sine Terms (amplitudes are throttle fractions, not degrees)';
            app.SinesPanel.FontWeight = 'bold';
            app.SinesPanel.FontSize = 10.666;
            app.SinesPanel.Layout.Row = 3;
            app.SinesPanel.Layout.Column = 1;

            app.SinesGrid = uigridlayout(app.SinesPanel);
            app.SinesGrid.ColumnWidth = {'1x'};
            app.SinesGrid.RowHeight = {28, '1x', 29};
            app.SinesGrid.ColumnSpacing = 5;
            app.SinesGrid.RowSpacing = 5;
            app.SinesGrid.Padding = [5 5 5 5];

            sinesConstGrid = uigridlayout(app.SinesGrid);
            sinesConstGrid.ColumnWidth = {130, '1x'};
            sinesConstGrid.RowHeight = {'1x'};
            sinesConstGrid.Padding = [0 0 0 0];
            sinesConstGrid.Layout.Row = 1;
            sinesConstGrid.Layout.Column = 1;

            app.SinesConstLabel = uilabel(sinesConstGrid);
            app.SinesConstLabel.HorizontalAlignment = 'right';
            app.SinesConstLabel.FontSize = 10.6666666666667;
            app.SinesConstLabel.Layout.Row = 1;
            app.SinesConstLabel.Layout.Column = 1;
            app.SinesConstLabel.Text = 'Constant Offset';

            app.SinesConstText = uieditfield(sinesConstGrid, 'text');
            app.SinesConstText.ValueChangedFcn = createCallbackFcn(app, @SinesConstTextValueChanged, true);
            app.SinesConstText.HorizontalAlignment = 'center';
            app.SinesConstText.FontSize = 10.6666666666667;
            app.SinesConstText.Tooltip = 'Constant throttle offset as a 0-1 fraction.';
            app.SinesConstText.Layout.Row = 1;
            app.SinesConstText.Layout.Column = 2;

            app.SinesTable = uitable(app.SinesGrid);
            app.SinesTable.ColumnName = {'Amplitude', 'Period (s)', 'Phase Shift (s)'};
            app.SinesTable.ColumnEditable = [true true true];
            app.SinesTable.CellEditCallback = createCallbackFcn(app, @SinesTableCellEdit, true);
            app.SinesTable.FontSize = 10.6666666666667;
            app.SinesTable.Tooltip = 'Each row adds amplitude * sin((2*pi/period) * (dt + phase)) to the throttle.';
            app.SinesTable.Layout.Row = 2;
            app.SinesTable.Layout.Column = 1;

            app.SinesButtonGrid = uigridlayout(app.SinesGrid);
            app.SinesButtonGrid.ColumnWidth = {'1x', '1x'};
            app.SinesButtonGrid.RowHeight = {'1x'};
            app.SinesButtonGrid.Padding = [0 0 0 0];
            app.SinesButtonGrid.Layout.Row = 3;
            app.SinesButtonGrid.Layout.Column = 1;

            app.AddSineButton = uibutton(app.SinesButtonGrid, 'push');
            app.AddSineButton.ButtonPushedFcn = createCallbackFcn(app, @AddSineButtonPushed, true);
            app.AddSineButton.FontSize = 10.6666666666667;
            app.AddSineButton.Layout.Row = 1;
            app.AddSineButton.Layout.Column = 1;
            app.AddSineButton.Text = 'Add Sine';

            app.RemoveSineButton = uibutton(app.SinesButtonGrid, 'push');
            app.RemoveSineButton.ButtonPushedFcn = createCallbackFcn(app, @RemoveSineButtonPushed, true);
            app.RemoveSineButton.FontSize = 10.6666666666667;
            app.RemoveSineButton.Layout.Row = 1;
            app.RemoveSineButton.Layout.Column = 2;
            app.RemoveSineButton.Text = 'Remove Sine';

            %Linear tangent branch panel
            app.LinTanPanel = uipanel(app.GridLayout);
            app.LinTanPanel.Title = 'Linear Tangent Parameters';
            app.LinTanPanel.FontWeight = 'bold';
            app.LinTanPanel.FontSize = 10.666;
            app.LinTanPanel.Layout.Row = 3;
            app.LinTanPanel.Layout.Column = 1;

            app.LinTanGrid = uigridlayout(app.LinTanPanel);
            app.LinTanGrid.ColumnWidth = {130, '1x'};
            app.LinTanGrid.RowHeight = {28, 28, 28, 28};
            app.LinTanGrid.ColumnSpacing = 5;
            app.LinTanGrid.RowSpacing = 5;
            app.LinTanGrid.Padding = [5 5 5 5];

            app.LinTanALabel = uilabel(app.LinTanGrid);
            app.LinTanALabel.HorizontalAlignment = 'right';
            app.LinTanALabel.FontSize = 10.6666666666667;
            app.LinTanALabel.Layout.Row = 1;
            app.LinTanALabel.Layout.Column = 1;
            app.LinTanALabel.Text = 'A';

            app.LinTanAText = uieditfield(app.LinTanGrid, 'text');
            app.LinTanAText.ValueChangedFcn = createCallbackFcn(app, @LinTanTextValueChanged, true);
            app.LinTanAText.HorizontalAlignment = 'center';
            app.LinTanAText.FontSize = 10.6666666666667;
            app.LinTanAText.Layout.Row = 1;
            app.LinTanAText.Layout.Column = 2;

            app.LinTanADotLabel = uilabel(app.LinTanGrid);
            app.LinTanADotLabel.HorizontalAlignment = 'right';
            app.LinTanADotLabel.FontSize = 10.6666666666667;
            app.LinTanADotLabel.Layout.Row = 2;
            app.LinTanADotLabel.Layout.Column = 1;
            app.LinTanADotLabel.Text = 'A Dot';

            app.LinTanADotText = uieditfield(app.LinTanGrid, 'text');
            app.LinTanADotText.ValueChangedFcn = createCallbackFcn(app, @LinTanTextValueChanged, true);
            app.LinTanADotText.HorizontalAlignment = 'center';
            app.LinTanADotText.FontSize = 10.6666666666667;
            app.LinTanADotText.Layout.Row = 2;
            app.LinTanADotText.Layout.Column = 2;

            app.LinTanBLabel = uilabel(app.LinTanGrid);
            app.LinTanBLabel.HorizontalAlignment = 'right';
            app.LinTanBLabel.FontSize = 10.6666666666667;
            app.LinTanBLabel.Layout.Row = 3;
            app.LinTanBLabel.Layout.Column = 1;
            app.LinTanBLabel.Text = 'B';

            app.LinTanBText = uieditfield(app.LinTanGrid, 'text');
            app.LinTanBText.ValueChangedFcn = createCallbackFcn(app, @LinTanTextValueChanged, true);
            app.LinTanBText.HorizontalAlignment = 'center';
            app.LinTanBText.FontSize = 10.6666666666667;
            app.LinTanBText.Layout.Row = 3;
            app.LinTanBText.Layout.Column = 2;

            app.LinTanBDotLabel = uilabel(app.LinTanGrid);
            app.LinTanBDotLabel.HorizontalAlignment = 'right';
            app.LinTanBDotLabel.FontSize = 10.6666666666667;
            app.LinTanBDotLabel.Layout.Row = 4;
            app.LinTanBDotLabel.Layout.Column = 1;
            app.LinTanBDotLabel.Text = 'B Dot';

            app.LinTanBDotText = uieditfield(app.LinTanGrid, 'text');
            app.LinTanBDotText.ValueChangedFcn = createCallbackFcn(app, @LinTanTextValueChanged, true);
            app.LinTanBDotText.HorizontalAlignment = 'center';
            app.LinTanBDotText.FontSize = 10.6666666666667;
            app.LinTanBDotText.Layout.Row = 4;
            app.LinTanBDotText.Layout.Column = 2;

            %Buttons
            app.ButtonGrid = uigridlayout(app.GridLayout);
            app.ButtonGrid.ColumnWidth = {'1x', '2x', '2x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.ColumnSpacing = 5;
            app.ButtonGrid.RowSpacing = 5;
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 4;
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
