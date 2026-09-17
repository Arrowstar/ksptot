classdef lvd_EditEphemerisFilePointGUI_App < matlab.apps.AppBase
    %lvd_EditEphemerisFilePointGUI_App Editor dialog for EphemerisFilePoint
    %objects.  Programmatic uifigure sibling of lvd_EditFixedInFramePointGUI_App
    %(same panels, display controls and Save/Cancel behaviour) with a file
    %chooser and a referenceFrameSelectComp for the ephemeris frame.
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditEphemerisFilePointGUI_App(point, lvdData, output);

    properties (Access = public)
        UIFigure               matlab.ui.Figure
        GridLayout             matlab.ui.container.GridLayout
        TitleLabel             matlab.ui.control.Label
        ButtonGrid             matlab.ui.container.GridLayout
        saveAndCloseButton     matlab.ui.control.Button
        cancelButton           matlab.ui.control.Button
        MainPanel              matlab.ui.container.Panel
        MainGrid               matlab.ui.container.GridLayout
        NamePanel              matlab.ui.container.Panel
        NameGrid               matlab.ui.container.GridLayout
        NameLabel              matlab.ui.control.Label
        pointNameText          matlab.ui.control.EditField
        FilePanel              matlab.ui.container.Panel
        FileGrid               matlab.ui.container.GridLayout
        FileLabel              matlab.ui.control.Label
        filePathText           matlab.ui.control.EditField
        browseButton           matlab.ui.control.Button
        FileStatusLabel        matlab.ui.control.Label
        FrameLabel             matlab.ui.control.Label
        FrameSelector          referenceFrameSelectComp
        DisplayPanel           matlab.ui.container.Panel
        DisplayGrid            matlab.ui.container.GridLayout
        MarkerLabel            matlab.ui.control.Label
        TrajLabel              matlab.ui.control.Label
        pointColorCombo        matlab.ui.control.DropDown
        pointMarkerShapeCombo  matlab.ui.control.DropDown
        pointLineColorCombo    matlab.ui.control.DropDown
        pointLineSpecCombo     matlab.ui.control.DropDown
        dispTrajCheckbox       matlab.ui.control.CheckBox
        ColorImage             matlab.ui.control.Image
        LineImage              matlab.ui.control.Image
    end

    properties (Access = private)
        point EphemerisFilePoint
        lvdData LvdData
        output AppDesignerGUIOutput

        %Table loaded from the currently entered file path (not yet saved
        %to the point until Save & Close).
        loadedFilePath(1,:) char = '';
        loadedTimes(1,:) double = [];
        loadedRvVects(6,:) double = zeros(6,0);
    end

    methods (Access = public)
        function app = lvd_EditEphemerisFilePointGUI_App(varargin)
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
        function startupFcn(app, point, lvdData, output)
            app.point = point;
            app.lvdData = lvdData;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            app.pointNameText.Value = app.point.getName();

            app.loadedFilePath = app.point.filePath;
            app.loadedTimes = app.point.times;
            app.loadedRvVects = app.point.rvVects;
            app.filePathText.Value = app.point.filePath;
            updateFileStatus(app);

            app.FrameSelector.initializeWithFrames(app.lvdData);
            if(not(isempty(app.point.frame)))
                app.FrameSelector.setSelectedFrame(app.point.frame);
            end

            app.pointColorCombo.Items = ColorSpecEnum.getListboxStr();
            app.pointColorCombo.Value = app.point.markerColor.name;

            app.pointMarkerShapeCombo.Items = MarkerStyleEnum.getListboxStr();
            app.pointMarkerShapeCombo.Value = app.point.markerShape.name;

            app.pointLineColorCombo.Items = ColorSpecEnum.getListboxStr();
            app.pointLineColorCombo.Value = app.point.trkLineColor.name;

            app.pointLineSpecCombo.Items = LineSpecEnum.getListboxStr();
            app.pointLineSpecCombo.Value = app.point.trkLineSpec.name;

            app.dispTrajCheckbox.Value = app.point.plotTrkLine;
        end

        function updateFileStatus(app)
            if(isempty(app.loadedTimes))
                app.FileStatusLabel.Text = 'No ephemeris loaded.';
            else
                app.FileStatusLabel.Text = sprintf('%u rows loaded, UT %s to %s sec.', numel(app.loadedTimes), ...
                                                   fullAccNum2Str(app.loadedTimes(1)), fullAccNum2Str(app.loadedTimes(end)));
            end
        end

        function [ok, errMsg] = loadFileIfNeeded(app)
            ok = true;
            errMsg = '';

            filePath = strtrim(app.filePathText.Value);
            if(strcmp(filePath, app.loadedFilePath) && not(isempty(app.loadedTimes)))
                return;
            end

            try
                [t, rv] = lvd_readEphemerisCsv(filePath);
            catch ME
                ok = false;
                errMsg = sprintf('Could not read the ephemeris file: %s', ME.message);
                return;
            end

            app.loadedFilePath = filePath;
            app.loadedTimes = t;
            app.loadedRvVects = rv;
            updateFileStatus(app);
        end

        function browseButton_Callback(app, ~)
            [fileName, pathName] = uigetfile({'*.csv;*.txt', 'Ephemeris Files (*.csv, *.txt)'; '*.*', 'All Files'}, 'Select Ephemeris File');
            figure(app.UIFigure); %uigetfile can push the modal dialog behind the main window

            if(isequal(fileName, 0))
                return;
            end

            app.filePathText.Value = fullfile(pathName, fileName);
            [ok, errMsg] = loadFileIfNeeded(app);
            if(not(ok))
                uialert(app.UIFigure, errMsg, 'Ephemeris Load Error', 'Icon','error');
            end
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(isempty(strtrim(app.filePathText.Value)))
                errMsg{end+1} = 'An ephemeris file must be selected.';
            else
                [ok, loadErr] = loadFileIfNeeded(app);
                if(not(ok))
                    errMsg{end+1} = loadErr;
                end
            end

            if(isempty(strtrim(app.pointNameText.Value)))
                errMsg{end+1} = 'Point name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.point.setName(app.pointNameText.Value);
            app.point.frame = app.FrameSelector.getSelectedFrame();

            app.point.filePath = app.loadedFilePath;
            app.point.times = app.loadedTimes;
            app.point.rvVects = app.loadedRvVects;

            app.point.markerColor = ColorSpecEnum.getEnumForListboxStr(app.pointColorCombo.Value);
            app.point.markerShape = MarkerStyleEnum.getEnumForListboxStr(app.pointMarkerShapeCombo.Value);
            app.point.trkLineColor = ColorSpecEnum.getEnumForListboxStr(app.pointLineColorCombo.Value);
            app.point.trkLineSpec = LineSpecEnum.getEnumForListboxStr(app.pointLineSpecCombo.Value);
            app.point.plotTrkLine = logical(app.dispTrajCheckbox.Value);

            app.output.output = {true};
            delete(app.UIFigure);
        end

        function saveAndCloseButton_Callback(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Invalid Point Inputs', 'Icon','error');
            end
        end

        function cancelButton_Callback(app, ~)
            delete(app.UIFigure);
        end

        function windowKeyPress(app, event)
            switch(event.Key)
                case {'return', 'enter'}
                    saveAndCloseButton_Callback(app, event);
                case 'escape'
                    delete(app.UIFigure);
            end
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [680 957 470 470];
            app.UIFigure.Name = 'Edit Point';
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
            app.TitleLabel.Text = 'Edit Point';

            app.ButtonGrid = uigridlayout(app.GridLayout);
            app.ButtonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.ColumnSpacing = 5;
            app.ButtonGrid.RowSpacing = 5;
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 3;
            app.ButtonGrid.Layout.Column = 1;

            app.saveAndCloseButton = uibutton(app.ButtonGrid, 'push');
            app.saveAndCloseButton.ButtonPushedFcn = @(~,evt) saveAndCloseButton_Callback(app, evt);
            app.saveAndCloseButton.Icon = 'save-file.png';
            app.saveAndCloseButton.FontSize = 10.6666666666667;
            app.saveAndCloseButton.Layout.Row = 1;
            app.saveAndCloseButton.Layout.Column = 2;
            app.saveAndCloseButton.Text = 'Save & Close';

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
            app.MainGrid.RowHeight = {50, 150, 140};
            app.MainGrid.ColumnSpacing = 5;
            app.MainGrid.RowSpacing = 5;
            app.MainGrid.Padding = [5 5 5 5];

            app.NamePanel = uipanel(app.MainGrid);
            app.NamePanel.Title = 'Name';
            app.NamePanel.Layout.Row = 1;
            app.NamePanel.Layout.Column = 1;
            app.NamePanel.FontWeight = 'bold';
            app.NamePanel.FontSize = 10.6666666666667;

            app.NameGrid = uigridlayout(app.NamePanel);
            app.NameGrid.ColumnWidth = {100, '1x'};
            app.NameGrid.RowHeight = {'1x'};
            app.NameGrid.ColumnSpacing = 5;
            app.NameGrid.RowSpacing = 5;
            app.NameGrid.Padding = [5 5 5 5];

            app.NameLabel = uilabel(app.NameGrid);
            app.NameLabel.HorizontalAlignment = 'right';
            app.NameLabel.WordWrap = 'on';
            app.NameLabel.FontSize = 10.6666666666667;
            app.NameLabel.Layout.Row = 1;
            app.NameLabel.Layout.Column = 1;
            app.NameLabel.Text = 'Point Name';

            app.pointNameText = uieditfield(app.NameGrid, 'text');
            app.pointNameText.HorizontalAlignment = 'center';
            app.pointNameText.FontSize = 10.6666666666667;
            app.pointNameText.Layout.Row = 1;
            app.pointNameText.Layout.Column = 2;

            app.FilePanel = uipanel(app.MainGrid);
            app.FilePanel.Title = 'Ephemeris';
            app.FilePanel.Layout.Row = 2;
            app.FilePanel.Layout.Column = 1;
            app.FilePanel.FontWeight = 'bold';
            app.FilePanel.FontSize = 10.6666666666667;

            app.FileGrid = uigridlayout(app.FilePanel);
            app.FileGrid.ColumnWidth = {100, '1x', 80};
            app.FileGrid.RowHeight = {20, 20, 60};
            app.FileGrid.ColumnSpacing = 5;
            app.FileGrid.RowSpacing = 5;
            app.FileGrid.Padding = [5 5 5 5];

            app.FileLabel = uilabel(app.FileGrid);
            app.FileLabel.HorizontalAlignment = 'right';
            app.FileLabel.FontSize = 10.6666666666667;
            app.FileLabel.Layout.Row = 1;
            app.FileLabel.Layout.Column = 1;
            app.FileLabel.Text = 'Ephemeris File';

            app.filePathText = uieditfield(app.FileGrid, 'text');
            app.filePathText.FontSize = 10.6666666666667;
            app.filePathText.Tooltip = 'A text file with rows of: UT (sec), x, y, z (km), vx, vy, vz (km/s), separated by commas or whitespace.  Header lines are skipped.';
            app.filePathText.Layout.Row = 1;
            app.filePathText.Layout.Column = 2;

            app.browseButton = uibutton(app.FileGrid, 'push');
            app.browseButton.ButtonPushedFcn = @(~,evt) browseButton_Callback(app, evt);
            app.browseButton.Icon = 'folder.png';
            app.browseButton.FontSize = 10.6666666666667;
            app.browseButton.Layout.Row = 1;
            app.browseButton.Layout.Column = 3;
            app.browseButton.Text = 'Browse';

            app.FileStatusLabel = uilabel(app.FileGrid);
            app.FileStatusLabel.HorizontalAlignment = 'left';
            app.FileStatusLabel.FontSize = 10.6666666666667;
            app.FileStatusLabel.FontAngle = 'italic';
            app.FileStatusLabel.Layout.Row = 2;
            app.FileStatusLabel.Layout.Column = [2 3];
            app.FileStatusLabel.Text = 'No ephemeris loaded.';

            app.FrameLabel = uilabel(app.FileGrid);
            app.FrameLabel.HorizontalAlignment = 'right';
            app.FrameLabel.VerticalAlignment = 'top';
            app.FrameLabel.FontSize = 10.6666666666667;
            app.FrameLabel.Layout.Row = 3;
            app.FrameLabel.Layout.Column = 1;
            app.FrameLabel.Text = 'Ephemeris Frame';

            app.FrameSelector = referenceFrameSelectComp(app.FileGrid);
            app.FrameSelector.Layout.Row = 3;
            app.FrameSelector.Layout.Column = [2 3];

            app.DisplayPanel = uipanel(app.MainGrid);
            app.DisplayPanel.Title = 'Display';
            app.DisplayPanel.Layout.Row = 3;
            app.DisplayPanel.Layout.Column = 1;
            app.DisplayPanel.FontWeight = 'bold';
            app.DisplayPanel.FontSize = 10.6666666666667;

            app.DisplayGrid = uigridlayout(app.DisplayPanel);
            app.DisplayGrid.ColumnWidth = {20, '1x', '1x'};
            app.DisplayGrid.RowHeight = {15, 20, 20, 20};

            app.MarkerLabel = uilabel(app.DisplayGrid);
            app.MarkerLabel.HorizontalAlignment = 'center';
            app.MarkerLabel.VerticalAlignment = 'top';
            app.MarkerLabel.WordWrap = 'on';
            app.MarkerLabel.FontSize = 10.6666666666667;
            app.MarkerLabel.FontWeight = 'bold';
            app.MarkerLabel.Layout.Row = 1;
            app.MarkerLabel.Layout.Column = 2;
            app.MarkerLabel.Text = 'Point Marker';

            app.pointColorCombo = uidropdown(app.DisplayGrid);
            app.pointColorCombo.Items = {};
            app.pointColorCombo.Tooltip = 'The color of the point marker on the display.';
            app.pointColorCombo.FontSize = 10.6666666666667;
            app.pointColorCombo.BackgroundColor = [1 1 1];
            app.pointColorCombo.Layout.Row = 2;
            app.pointColorCombo.Layout.Column = 2;

            app.pointMarkerShapeCombo = uidropdown(app.DisplayGrid);
            app.pointMarkerShapeCombo.Items = {};
            app.pointMarkerShapeCombo.Tooltip = 'The shape of the point marker on the display.';
            app.pointMarkerShapeCombo.FontSize = 10.6666666666667;
            app.pointMarkerShapeCombo.BackgroundColor = [1 1 1];
            app.pointMarkerShapeCombo.Layout.Row = 3;
            app.pointMarkerShapeCombo.Layout.Column = 2;

            app.TrajLabel = uilabel(app.DisplayGrid);
            app.TrajLabel.HorizontalAlignment = 'center';
            app.TrajLabel.VerticalAlignment = 'top';
            app.TrajLabel.WordWrap = 'on';
            app.TrajLabel.FontSize = 10.6666666666667;
            app.TrajLabel.FontWeight = 'bold';
            app.TrajLabel.Layout.Row = 1;
            app.TrajLabel.Layout.Column = 3;
            app.TrajLabel.Text = 'Point Trajectory';

            app.pointLineColorCombo = uidropdown(app.DisplayGrid);
            app.pointLineColorCombo.Items = {};
            app.pointLineColorCombo.Tooltip = 'The color of the point track line on the display.';
            app.pointLineColorCombo.FontSize = 10.6666666666667;
            app.pointLineColorCombo.BackgroundColor = [1 1 1];
            app.pointLineColorCombo.Layout.Row = 2;
            app.pointLineColorCombo.Layout.Column = 3;

            app.pointLineSpecCombo = uidropdown(app.DisplayGrid);
            app.pointLineSpecCombo.Items = {};
            app.pointLineSpecCombo.Tooltip = 'The style of the line of the point track line on the display.';
            app.pointLineSpecCombo.FontSize = 10.6666666666667;
            app.pointLineSpecCombo.BackgroundColor = [1 1 1];
            app.pointLineSpecCombo.Layout.Row = 3;
            app.pointLineSpecCombo.Layout.Column = 3;

            app.dispTrajCheckbox = uicheckbox(app.DisplayGrid);
            app.dispTrajCheckbox.Text = 'Display Trajectory';
            app.dispTrajCheckbox.FontSize = 10.6666666666667;
            app.dispTrajCheckbox.Layout.Row = 4;
            app.dispTrajCheckbox.Layout.Column = 3;

            app.ColorImage = uiimage(app.DisplayGrid);
            app.ColorImage.Layout.Row = 2;
            app.ColorImage.Layout.Column = 1;
            app.ColorImage.ImageSource = 'color_wheel.png';

            app.LineImage = uiimage(app.DisplayGrid);
            app.LineImage.Layout.Row = 3;
            app.LineImage.Layout.Column = 1;
            app.LineImage.ImageSource = 'line.png';
        end
    end
end
