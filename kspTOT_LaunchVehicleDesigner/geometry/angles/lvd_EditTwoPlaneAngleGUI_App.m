classdef lvd_EditTwoPlaneAngleGUI_App < matlab.apps.AppBase
    %lvd_EditTwoPlaneAngleGUI_App Editor dialog for TwoPlaneAngle objects.
    %   Programmatic uifigure sibling of lvd_EditVectorPlaneAngleGUI_App
    %   (same size, panels and controls).  Launched the same way:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditTwoPlaneAngleGUI_App(angle, lvdData, output);

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
        nameText               matlab.ui.control.EditField
        PlanesPanel            matlab.ui.container.Panel
        PlanesGrid             matlab.ui.container.GridLayout
        Plane1Image            matlab.ui.control.Image
        Plane2Image            matlab.ui.control.Image
        Plane1Label            matlab.ui.control.Label
        Plane2Label            matlab.ui.control.Label
        plane1Combo            matlab.ui.control.DropDown
        plane2Combo            matlab.ui.control.DropDown
        DisplayPanel           matlab.ui.container.Panel
        DisplayGrid            matlab.ui.container.GridLayout
        DisplayLabel           matlab.ui.control.Label
        ColorImage             matlab.ui.control.Image
        LineImage              matlab.ui.control.Image
        lineColorCombo         matlab.ui.control.DropDown
        lineSpecCombo          matlab.ui.control.DropDown
    end

    properties (Access = private)
        angle TwoPlaneAngle
        lvdData LvdData
        output AppDesignerGUIOutput
        allPlanes AbstractGeometricPlane
    end

    methods (Access = public)
        function app = lvd_EditTwoPlaneAngleGUI_App(varargin)
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
        function startupFcn(app, angle, lvdData, output)
            app.angle = angle;
            app.lvdData = lvdData;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            app.nameText.Value = app.angle.getName();

            [planesListBoxStr, planes] = app.lvdData.geometry.planes.getListboxStr();
            app.allPlanes = planes;

            app.plane1Combo.Items = planesListBoxStr;
            app.plane1Combo.ItemsData = 1:numel(planes);
            app.plane2Combo.Items = planesListBoxStr;
            app.plane2Combo.ItemsData = 1:numel(planes);

            ind1 = find(planes == app.angle.plane1, 1, 'first');
            ind2 = find(planes == app.angle.plane2, 1, 'first');
            if(not(isempty(planes)))
                if(isempty(ind1)), ind1 = 1; end
                if(isempty(ind2)), ind2 = min(2, numel(planes)); end
                app.plane1Combo.Value = ind1;
                app.plane2Combo.Value = ind2;
            end

            app.lineColorCombo.Items = ColorSpecEnum.getListboxStr();
            app.lineColorCombo.Value = app.angle.lineColor.name;

            app.lineSpecCombo.Items = LineSpecEnum.getListboxStr();
            app.lineSpecCombo.Value = app.angle.lineSpec.name;
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(numel(app.allPlanes) < 2)
                errMsg{end+1} = 'There must be at least two geometric planes available.';
            elseif(app.plane1Combo.Value == app.plane2Combo.Value)
                errMsg{end+1} = 'The two planes must be different.';
            end

            if(isempty(strtrim(app.nameText.Value)))
                errMsg{end+1} = 'Angle name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.angle.setName(app.nameText.Value);
            app.angle.plane1 = app.allPlanes(app.plane1Combo.Value);
            app.angle.plane2 = app.allPlanes(app.plane2Combo.Value);
            app.angle.lineColor = ColorSpecEnum.getEnumForListboxStr(app.lineColorCombo.Value);
            app.angle.lineSpec = LineSpecEnum.getEnumForListboxStr(app.lineSpecCombo.Value);

            app.output.output = {true};
            delete(app.UIFigure);
        end

        function saveAndCloseButton_Callback(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Invalid Angle Inputs', 'Icon','error');
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
            app.UIFigure.Position = [680 957 430 325];
            app.UIFigure.Name = 'Edit Angle';
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
            app.TitleLabel.Text = 'Edit Angle';

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
            app.MainGrid.RowHeight = {50, 75, 95};
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
            app.NameGrid.ColumnWidth = {20, 100, '1x'};
            app.NameGrid.RowHeight = {20};
            app.NameGrid.ColumnSpacing = 5;
            app.NameGrid.RowSpacing = 5;
            app.NameGrid.Padding = [5 5 5 5];

            app.NameLabel = uilabel(app.NameGrid);
            app.NameLabel.HorizontalAlignment = 'right';
            app.NameLabel.WordWrap = 'on';
            app.NameLabel.FontSize = 10.6666666666667;
            app.NameLabel.Layout.Row = 1;
            app.NameLabel.Layout.Column = 2;
            app.NameLabel.Text = 'Angle Name';

            app.nameText = uieditfield(app.NameGrid, 'text');
            app.nameText.HorizontalAlignment = 'center';
            app.nameText.FontSize = 10.6666666666667;
            app.nameText.Layout.Row = 1;
            app.nameText.Layout.Column = 3;

            app.PlanesPanel = uipanel(app.MainGrid);
            app.PlanesPanel.Title = 'Planes';
            app.PlanesPanel.Layout.Row = 2;
            app.PlanesPanel.Layout.Column = 1;
            app.PlanesPanel.FontWeight = 'bold';
            app.PlanesPanel.FontSize = 10.6666666666667;

            app.PlanesGrid = uigridlayout(app.PlanesPanel);
            app.PlanesGrid.ColumnWidth = {20, 100, '1x'};
            app.PlanesGrid.RowHeight = {20, 20};
            app.PlanesGrid.ColumnSpacing = 5;
            app.PlanesGrid.RowSpacing = 5;
            app.PlanesGrid.Padding = [5 5 5 5];

            app.Plane1Label = uilabel(app.PlanesGrid);
            app.Plane1Label.HorizontalAlignment = 'right';
            app.Plane1Label.WordWrap = 'on';
            app.Plane1Label.FontSize = 10.6666666666667;
            app.Plane1Label.Layout.Row = 1;
            app.Plane1Label.Layout.Column = 2;
            app.Plane1Label.Text = 'Plane 1';

            app.Plane2Label = uilabel(app.PlanesGrid);
            app.Plane2Label.HorizontalAlignment = 'right';
            app.Plane2Label.WordWrap = 'on';
            app.Plane2Label.FontSize = 10.6666666666667;
            app.Plane2Label.Layout.Row = 2;
            app.Plane2Label.Layout.Column = 2;
            app.Plane2Label.Text = 'Plane 2';

            app.plane1Combo = uidropdown(app.PlanesGrid);
            app.plane1Combo.Items = {};
            app.plane1Combo.Tooltip = 'The first plane.  The measured (dihedral) angle is the angle between the two plane normal vectors, in [0, 180] deg.';
            app.plane1Combo.FontSize = 10.6666666666667;
            app.plane1Combo.BackgroundColor = [1 1 1];
            app.plane1Combo.Layout.Row = 1;
            app.plane1Combo.Layout.Column = 3;

            app.plane2Combo = uidropdown(app.PlanesGrid);
            app.plane2Combo.Items = {};
            app.plane2Combo.Tooltip = 'The second plane.  The measured (dihedral) angle is the angle between the two plane normal vectors, in [0, 180] deg.';
            app.plane2Combo.FontSize = 10.6666666666667;
            app.plane2Combo.BackgroundColor = [1 1 1];
            app.plane2Combo.Layout.Row = 2;
            app.plane2Combo.Layout.Column = 3;

            app.Plane1Image = uiimage(app.PlanesGrid);
            app.Plane1Image.Layout.Row = 1;
            app.Plane1Image.Layout.Column = 1;
            app.Plane1Image.ImageSource = 'layers.png';

            app.Plane2Image = uiimage(app.PlanesGrid);
            app.Plane2Image.Layout.Row = 2;
            app.Plane2Image.Layout.Column = 1;
            app.Plane2Image.ImageSource = 'layers.png';

            app.DisplayPanel = uipanel(app.MainGrid);
            app.DisplayPanel.Title = 'Display';
            app.DisplayPanel.Layout.Row = 3;
            app.DisplayPanel.Layout.Column = 1;
            app.DisplayPanel.FontWeight = 'bold';
            app.DisplayPanel.FontSize = 10.6666666666667;

            app.DisplayGrid = uigridlayout(app.DisplayPanel);
            app.DisplayGrid.ColumnWidth = {'1x', 20, '3x', 20, '1x'};
            app.DisplayGrid.RowHeight = {15, 20, 20};
            app.DisplayGrid.ColumnSpacing = 5;
            app.DisplayGrid.RowSpacing = 5;
            app.DisplayGrid.Padding = [5 5 5 5];

            app.DisplayLabel = uilabel(app.DisplayGrid);
            app.DisplayLabel.HorizontalAlignment = 'center';
            app.DisplayLabel.VerticalAlignment = 'top';
            app.DisplayLabel.WordWrap = 'on';
            app.DisplayLabel.FontSize = 10.6666666666667;
            app.DisplayLabel.FontWeight = 'bold';
            app.DisplayLabel.Layout.Row = 1;
            app.DisplayLabel.Layout.Column = 3;
            app.DisplayLabel.Text = 'Angle Line';

            app.lineColorCombo = uidropdown(app.DisplayGrid);
            app.lineColorCombo.Items = {};
            app.lineColorCombo.Tooltip = 'The color of the angle''s line on the display.';
            app.lineColorCombo.FontSize = 10.6666666666667;
            app.lineColorCombo.BackgroundColor = [1 1 1];
            app.lineColorCombo.Layout.Row = 2;
            app.lineColorCombo.Layout.Column = 3;

            app.lineSpecCombo = uidropdown(app.DisplayGrid);
            app.lineSpecCombo.Items = {};
            app.lineSpecCombo.Tooltip = 'The style of the angle''s line on the display.';
            app.lineSpecCombo.FontSize = 10.6666666666667;
            app.lineSpecCombo.BackgroundColor = [1 1 1];
            app.lineSpecCombo.Layout.Row = 3;
            app.lineSpecCombo.Layout.Column = 3;

            app.ColorImage = uiimage(app.DisplayGrid);
            app.ColorImage.Layout.Row = 2;
            app.ColorImage.Layout.Column = 2;
            app.ColorImage.ImageSource = 'color_wheel.png';

            app.LineImage = uiimage(app.DisplayGrid);
            app.LineImage.Layout.Row = 3;
            app.LineImage.Layout.Column = 2;
            app.LineImage.ImageSource = 'line.png';
        end
    end
end
