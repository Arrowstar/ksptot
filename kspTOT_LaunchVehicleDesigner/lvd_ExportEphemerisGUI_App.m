classdef lvd_ExportEphemerisGUI_App < matlab.apps.AppBase
    %lvd_ExportEphemerisGUI_App Dialog that writes the current state log as a
    %Cartesian ephemeris (CSV or CCSDS-OEM-style) via lvd_exportEphemeris.
    %   Programmatic uifigure dialog in the style of the LVD geometry editors.
    %
    %       lvd_ExportEphemerisGUI_App(lvdData);

    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        TitleLabel             matlab.ui.control.Label
        ButtonGrid             matlab.ui.container.GridLayout
        exportButton           matlab.ui.control.Button
        cancelButton           matlab.ui.control.Button
        MainPanel              matlab.ui.container.Panel
        MainGrid               matlab.ui.container.GridLayout
        FramePanel             matlab.ui.container.Panel
        FrameGrid              matlab.ui.container.GridLayout
        FrameSelector          referenceFrameSelectComp
        OptionsPanel           matlab.ui.container.Panel
        OptionsGrid            matlab.ui.container.GridLayout
        FormatLabel            matlab.ui.control.Label
        formatCombo            matlab.ui.control.DropDown
        StepLabel              matlab.ui.control.Label
        stepSizeText           matlab.ui.control.EditField
        StepUnitLabel          matlab.ui.control.Label
        ObjectNameLabel        matlab.ui.control.Label
        objectNameText         matlab.ui.control.EditField
        includeMassCheckbox    matlab.ui.control.CheckBox
        NoteLabel              matlab.ui.control.Label
    end

    properties (Access = private)
        lvdData LvdData
    end

    properties (Constant, Access = private)
        formatNames = {'CSV (comma separated)', 'CCSDS OEM (text)'};
        formatKeys = {'csv', 'oem'};
    end

    methods (Access = public)
        function app = lvd_ExportEphemerisGUI_App(varargin)
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
        function startupFcn(app, lvdData)
            app.lvdData = lvdData;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            app.FrameSelector.initializeWithFrames(lvdData);
            app.FrameSelector.setSelectedFrame(lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame());

            app.formatCombo.Items = app.formatNames;
            app.formatCombo.ItemsData = app.formatKeys;
            app.formatCombo.Value = 'csv';

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function [errMsg, stepSize] = validateInputs(app)
            errMsg = {};
            stepSize = [];

            stepStr = strtrim(app.stepSizeText.Value);
            if(not(isempty(stepStr)))
                stepSize = str2double(stepStr);
                errMsg = validateNumber(stepSize, 'Step Size', eps, Inf, false, errMsg, stepStr);
            end

            if(app.lvdData.stateLog.getNumberOfEntries() == 0)
                errMsg{end+1} = 'The state log is empty.  Propagate the mission script before exporting an ephemeris.';
            end
        end

        function exportButton_Callback(app, ~)
            [errMsg, stepSize] = validateInputs(app);

            if(not(isempty(errMsg)))
                uialert(app.UIFigure, errMsg, 'Invalid Export Inputs', 'Icon','error');
                return;
            end

            formatKey = app.formatCombo.Value;
            switch formatKey
                case 'csv'
                    filterSpec = {'*.csv', 'CSV Files (*.csv)'};
                    defaultName = 'lvd_ephemeris.csv';
                otherwise
                    filterSpec = {'*.oem;*.txt', 'OEM Files (*.oem, *.txt)'};
                    defaultName = 'lvd_ephemeris.oem';
            end

            [fileName, pathName, filterInd] = uiputfile(filterSpec, 'Export Ephemeris', defaultName);
            figure(app.UIFigure); %uiputfile can push the modal dialog behind the main window

            if(filterInd == 0)
                return;
            end

            filePath = fullfile(pathName, fileName);

            opts = struct();
            opts.format = formatKey;
            opts.stepSize = stepSize;
            opts.includeMass = logical(app.includeMassCheckbox.Value);
            opts.objectName = strtrim(app.objectNameText.Value);

            frame = app.FrameSelector.getSelectedFrame();

            try
                numRows = lvd_exportEphemeris(app.lvdData.stateLog, frame, filePath, opts);
            catch ME
                uialert(app.UIFigure, sprintf('Ephemeris export failed: %s', ME.message), 'Export Error', 'Icon','error');
                return;
            end

            msg = sprintf('%u ephemeris rows written to:\n\n%s', numRows, filePath);
            uialert(app.UIFigure, msg, 'Ephemeris Exported', 'Icon','success', 'CloseFcn', @(~,~) delete(app.UIFigure));
        end

        function cancelButton_Callback(app, ~)
            delete(app.UIFigure);
        end

        function windowKeyPress(app, event)
            switch(event.Key)
                case 'escape'
                    delete(app.UIFigure);
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [680 957 470 330];
            app.UIFigure.Name = 'Export Ephemeris';
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.WindowKeyPressFcn = @(~,evt) windowKeyPress(app, evt);
            app.UIFigure.HandleVisibility = 'callback';
            app.UIFigure.WindowStyle = 'modal';

            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {24, '1x', 29};
            app.GridLayout.ColumnSpacing = 5;
            app.GridLayout.RowSpacing = 5;

            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.WordWrap = 'on';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;
            app.TitleLabel.Text = 'Export Ephemeris';

            app.ButtonGrid = uigridlayout(app.GridLayout);
            app.ButtonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.ColumnSpacing = 5;
            app.ButtonGrid.RowSpacing = 5;
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 3;
            app.ButtonGrid.Layout.Column = 1;

            app.exportButton = uibutton(app.ButtonGrid, 'push');
            app.exportButton.ButtonPushedFcn = @(~,evt) exportButton_Callback(app, evt);
            app.exportButton.Icon = 'save-file.png';
            app.exportButton.FontSize = 10.6666666666667;
            app.exportButton.Layout.Row = 1;
            app.exportButton.Layout.Column = 2;
            app.exportButton.Text = 'Export...';

            app.cancelButton = uibutton(app.ButtonGrid, 'push');
            app.cancelButton.ButtonPushedFcn = @(~,evt) cancelButton_Callback(app, evt);
            app.cancelButton.Icon = 'cancel.png';
            app.cancelButton.FontSize = 10.6666666666667;
            app.cancelButton.Layout.Row = 1;
            app.cancelButton.Layout.Column = 3;
            app.cancelButton.Text = 'Cancel';

            app.MainPanel = uipanel(app.GridLayout);
            app.MainPanel.Layout.Row = 2;
            app.MainPanel.Layout.Column = 1;
            app.MainPanel.FontSize = 10.6666666666667;

            app.MainGrid = uigridlayout(app.MainPanel);
            app.MainGrid.ColumnWidth = {'1x'};
            app.MainGrid.RowHeight = {90, '1x'};
            app.MainGrid.ColumnSpacing = 5;
            app.MainGrid.RowSpacing = 5;
            app.MainGrid.Padding = [5 5 5 5];

            app.FramePanel = uipanel(app.MainGrid);
            app.FramePanel.Title = 'Output Reference Frame';
            app.FramePanel.Layout.Row = 1;
            app.FramePanel.Layout.Column = 1;
            app.FramePanel.FontWeight = 'bold';
            app.FramePanel.FontSize = 10.6666666666667;

            app.FrameGrid = uigridlayout(app.FramePanel);
            app.FrameGrid.ColumnWidth = {'1x'};
            app.FrameGrid.RowHeight = {'1x'};
            app.FrameGrid.Padding = [5 5 5 5];

            app.FrameSelector = referenceFrameSelectComp(app.FrameGrid);
            app.FrameSelector.Layout.Row = 1;
            app.FrameSelector.Layout.Column = 1;

            app.OptionsPanel = uipanel(app.MainGrid);
            app.OptionsPanel.Title = 'Output Options';
            app.OptionsPanel.Layout.Row = 2;
            app.OptionsPanel.Layout.Column = 1;
            app.OptionsPanel.FontWeight = 'bold';
            app.OptionsPanel.FontSize = 10.6666666666667;

            app.OptionsGrid = uigridlayout(app.OptionsPanel);
            app.OptionsGrid.ColumnWidth = {100, '1x', 40};
            app.OptionsGrid.RowHeight = {20, 20, 20, 20, 'fit'};
            app.OptionsGrid.ColumnSpacing = 5;
            app.OptionsGrid.RowSpacing = 5;
            app.OptionsGrid.Padding = [5 5 5 5];

            app.FormatLabel = uilabel(app.OptionsGrid);
            app.FormatLabel.HorizontalAlignment = 'right';
            app.FormatLabel.FontSize = 10.6666666666667;
            app.FormatLabel.Layout.Row = 1;
            app.FormatLabel.Layout.Column = 1;
            app.FormatLabel.Text = 'File Format';

            app.formatCombo = uidropdown(app.OptionsGrid);
            app.formatCombo.Items = {};
            app.formatCombo.Tooltip = 'CSV writes one row per epoch with an event number column.  OEM writes a minimal CCSDS Orbit Ephemeris Message style text file.';
            app.formatCombo.FontSize = 10.6666666666667;
            app.formatCombo.BackgroundColor = [1 1 1];
            app.formatCombo.Layout.Row = 1;
            app.formatCombo.Layout.Column = [2 3];

            app.StepLabel = uilabel(app.OptionsGrid);
            app.StepLabel.HorizontalAlignment = 'right';
            app.StepLabel.FontSize = 10.6666666666667;
            app.StepLabel.Layout.Row = 2;
            app.StepLabel.Layout.Column = 1;
            app.StepLabel.Text = 'Step Size';

            app.stepSizeText = uieditfield(app.OptionsGrid, 'text');
            app.stepSizeText.HorizontalAlignment = 'center';
            app.stepSizeText.FontSize = 10.6666666666667;
            app.stepSizeText.Tooltip = 'Leave blank to write the raw state log epochs.  Enter a positive number to resample onto a uniform grid (interpolated within each continuous segment; the final epoch is always included).';
            app.stepSizeText.Layout.Row = 2;
            app.stepSizeText.Layout.Column = 2;
            app.stepSizeText.Value = '';

            app.StepUnitLabel = uilabel(app.OptionsGrid);
            app.StepUnitLabel.FontSize = 10.6666666666667;
            app.StepUnitLabel.Layout.Row = 2;
            app.StepUnitLabel.Layout.Column = 3;
            app.StepUnitLabel.Text = 'sec';

            app.ObjectNameLabel = uilabel(app.OptionsGrid);
            app.ObjectNameLabel.HorizontalAlignment = 'right';
            app.ObjectNameLabel.FontSize = 10.6666666666667;
            app.ObjectNameLabel.Layout.Row = 3;
            app.ObjectNameLabel.Layout.Column = 1;
            app.ObjectNameLabel.Text = 'Object Name';

            app.objectNameText = uieditfield(app.OptionsGrid, 'text');
            app.objectNameText.HorizontalAlignment = 'center';
            app.objectNameText.FontSize = 10.6666666666667;
            app.objectNameText.Tooltip = 'Written to the OEM header as OBJECT_NAME.';
            app.objectNameText.Layout.Row = 3;
            app.objectNameText.Layout.Column = [2 3];
            app.objectNameText.Value = 'LVD Vehicle';

            app.includeMassCheckbox = uicheckbox(app.OptionsGrid);
            app.includeMassCheckbox.Text = 'Include total vehicle mass column (CSV only)';
            app.includeMassCheckbox.FontSize = 10.6666666666667;
            app.includeMassCheckbox.Layout.Row = 4;
            app.includeMassCheckbox.Layout.Column = [2 3];

            app.NoteLabel = uilabel(app.OptionsGrid);
            app.NoteLabel.WordWrap = 'on';
            app.NoteLabel.FontSize = 10.6666666666667;
            app.NoteLabel.FontAngle = 'italic';
            app.NoteLabel.Layout.Row = 5;
            app.NoteLabel.Layout.Column = [1 3];
            app.NoteLabel.Text = 'Positions in km, velocities in km/s, epochs in KSP universal time (sec).';
        end
    end
end
