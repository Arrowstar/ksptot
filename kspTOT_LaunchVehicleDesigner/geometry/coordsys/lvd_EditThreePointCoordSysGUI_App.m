classdef lvd_EditThreePointCoordSysGUI_App < matlab.apps.AppBase
    %lvd_EditThreePointCoordSysGUI_App Editor dialog for ThreePointCoordSystem objects.
    %   Programmatic uifigure sibling of lvd_EditAlignedConstrainedCoordSysGUI_App
    %   (same panels: name, geometry inputs with axis selectors, Save/Cancel).
    %   Launched the same way:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditThreePointCoordSysGUI_App(coordSys, lvdData, output);

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
        coordSysNameText       matlab.ui.control.EditField
        PointsPanel            matlab.ui.container.Panel
        PointsGrid             matlab.ui.container.GridLayout
        OriginImage            matlab.ui.control.Image
        PrimaryImage           matlab.ui.control.Image
        PlaneImage             matlab.ui.control.Image
        OriginLabel            matlab.ui.control.Label
        PrimaryLabel           matlab.ui.control.Label
        PlaneLabel             matlab.ui.control.Label
        originPointCombo       matlab.ui.control.DropDown
        primaryPointCombo      matlab.ui.control.DropDown
        planePointCombo        matlab.ui.control.DropDown
        AxesPanel              matlab.ui.container.Panel
        AxesGrid               matlab.ui.container.GridLayout
        PrimaryAxisLabel       matlab.ui.control.Label
        NormalAxisLabel        matlab.ui.control.Label
        primaryAxisCombo       matlab.ui.control.DropDown
        normalAxisCombo        matlab.ui.control.DropDown
        NoteLabel              matlab.ui.control.Label
    end

    properties (Access = private)
        coordSys ThreePointCoordSystem
        lvdData LvdData
        output AppDesignerGUIOutput
        allPoints AbstractGeometricPoint
    end

    methods (Access = public)
        function app = lvd_EditThreePointCoordSysGUI_App(varargin)
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
        function startupFcn(app, coordSys, lvdData, output)
            app.coordSys = coordSys;
            app.lvdData = lvdData;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            app.coordSysNameText.Value = app.coordSys.getName();

            [pointsListBoxStr, points] = app.lvdData.geometry.points.getListboxStr();
            app.allPoints = points;

            combos = [app.originPointCombo, app.primaryPointCombo, app.planePointCombo];
            selPoints = [app.coordSys.originPoint, app.coordSys.primaryAxisPoint, app.coordSys.planePoint];

            for(i=1:numel(combos)) %#ok<*NO4LP>
                combos(i).Items = pointsListBoxStr;
                combos(i).ItemsData = 1:numel(points);

                ind = find(points == selPoints(i), 1, 'first');
                if(not(isempty(points)))
                    if(isempty(ind)), ind = min(i, numel(points)); end
                    combos(i).Value = ind;
                end
            end

            axesListBoxStr = AlignedConstrainedCoordSysAxesEnum.getListBoxStr();

            app.primaryAxisCombo.Items = axesListBoxStr;
            app.primaryAxisCombo.Value = app.coordSys.primaryAxis.name;

            app.normalAxisCombo.Items = axesListBoxStr;
            app.normalAxisCombo.Value = app.coordSys.normalAxis.name;
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(numel(app.allPoints) < 3)
                errMsg{end+1} = 'There must be at least three geometric points available.';
            else
                inds = [app.originPointCombo.Value, app.primaryPointCombo.Value, app.planePointCombo.Value];
                if(numel(unique(inds)) < 3)
                    errMsg{end+1} = 'The origin, primary axis and plane points must be three different points.';
                end
            end

            primaryAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(app.primaryAxisCombo.Value);
            normalAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(app.normalAxisCombo.Value);
            if(primaryAxis == normalAxis || strcmpi(primaryAxis.baseAxis, normalAxis.baseAxis))
                errMsg{end+1} = 'The primary axis and normal axis must be different and not opposite.';
            end

            if(isempty(strtrim(app.coordSysNameText.Value)))
                errMsg{end+1} = 'Coordinate system name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.coordSys.setName(app.coordSysNameText.Value);
            app.coordSys.originPoint = app.allPoints(app.originPointCombo.Value);
            app.coordSys.primaryAxisPoint = app.allPoints(app.primaryPointCombo.Value);
            app.coordSys.planePoint = app.allPoints(app.planePointCombo.Value);
            app.coordSys.primaryAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(app.primaryAxisCombo.Value);
            app.coordSys.normalAxis = AlignedConstrainedCoordSysAxesEnum.getEnumForListboxStr(app.normalAxisCombo.Value);

            app.output.output = {true};
            delete(app.UIFigure);
        end

        function saveAndCloseButton_Callback(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Invalid Coordinate System Inputs', 'Icon','error');
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
            app.UIFigure.Position = [680 957 450 395];
            app.UIFigure.Name = 'Edit Coordinate System';
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
            app.TitleLabel.Text = 'Edit Three Point Coordinate System';

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
            app.MainGrid.RowHeight = {50, 100, 105};
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
            app.NameGrid.ColumnWidth = {20, 120, '1x'};
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
            app.NameLabel.Text = 'Coord. System Name';

            app.coordSysNameText = uieditfield(app.NameGrid, 'text');
            app.coordSysNameText.HorizontalAlignment = 'center';
            app.coordSysNameText.FontSize = 10.6666666666667;
            app.coordSysNameText.Layout.Row = 1;
            app.coordSysNameText.Layout.Column = 3;

            app.PointsPanel = uipanel(app.MainGrid);
            app.PointsPanel.Title = 'Points';
            app.PointsPanel.Layout.Row = 2;
            app.PointsPanel.Layout.Column = 1;
            app.PointsPanel.FontWeight = 'bold';
            app.PointsPanel.FontSize = 10.6666666666667;

            app.PointsGrid = uigridlayout(app.PointsPanel);
            app.PointsGrid.ColumnWidth = {20, 120, '1x'};
            app.PointsGrid.RowHeight = {20, 20, 20};
            app.PointsGrid.ColumnSpacing = 5;
            app.PointsGrid.RowSpacing = 5;
            app.PointsGrid.Padding = [5 5 5 5];

            app.OriginLabel = uilabel(app.PointsGrid);
            app.OriginLabel.HorizontalAlignment = 'right';
            app.OriginLabel.FontSize = 10.6666666666667;
            app.OriginLabel.Layout.Row = 1;
            app.OriginLabel.Layout.Column = 2;
            app.OriginLabel.Text = 'Origin Point';

            app.PrimaryLabel = uilabel(app.PointsGrid);
            app.PrimaryLabel.HorizontalAlignment = 'right';
            app.PrimaryLabel.FontSize = 10.6666666666667;
            app.PrimaryLabel.Layout.Row = 2;
            app.PrimaryLabel.Layout.Column = 2;
            app.PrimaryLabel.Text = 'Primary Axis Point';

            app.PlaneLabel = uilabel(app.PointsGrid);
            app.PlaneLabel.HorizontalAlignment = 'right';
            app.PlaneLabel.FontSize = 10.6666666666667;
            app.PlaneLabel.Layout.Row = 3;
            app.PlaneLabel.Layout.Column = 2;
            app.PlaneLabel.Text = 'Plane Point';

            app.originPointCombo = uidropdown(app.PointsGrid);
            app.originPointCombo.Items = {};
            app.originPointCombo.Tooltip = 'The point the axes emanate from.  Pair this coordinate system with the same point in a "Coordinate System and Point" reference frame to get a full frame.';
            app.originPointCombo.FontSize = 10.6666666666667;
            app.originPointCombo.BackgroundColor = [1 1 1];
            app.originPointCombo.Layout.Row = 1;
            app.originPointCombo.Layout.Column = 3;

            app.primaryPointCombo = uidropdown(app.PointsGrid);
            app.primaryPointCombo.Items = {};
            app.primaryPointCombo.Tooltip = 'The primary axis points from the origin point toward this point.';
            app.primaryPointCombo.FontSize = 10.6666666666667;
            app.primaryPointCombo.BackgroundColor = [1 1 1];
            app.primaryPointCombo.Layout.Row = 2;
            app.primaryPointCombo.Layout.Column = 3;

            app.planePointCombo = uidropdown(app.PointsGrid);
            app.planePointCombo.Items = {};
            app.planePointCombo.Tooltip = 'Fixes the plane of the first two axes.  The normal axis is perpendicular to the plane of the three points (right-hand rule from the primary axis point to this point); the remaining axis lies in that plane on this point''s side.';
            app.planePointCombo.FontSize = 10.6666666666667;
            app.planePointCombo.BackgroundColor = [1 1 1];
            app.planePointCombo.Layout.Row = 3;
            app.planePointCombo.Layout.Column = 3;

            app.OriginImage = uiimage(app.PointsGrid);
            app.OriginImage.Layout.Row = 1;
            app.OriginImage.Layout.Column = 1;
            app.OriginImage.ImageSource = 'red-arrow.png';

            app.PrimaryImage = uiimage(app.PointsGrid);
            app.PrimaryImage.Layout.Row = 2;
            app.PrimaryImage.Layout.Column = 1;
            app.PrimaryImage.ImageSource = 'green-arrow.png';

            app.PlaneImage = uiimage(app.PointsGrid);
            app.PlaneImage.Layout.Row = 3;
            app.PlaneImage.Layout.Column = 1;
            app.PlaneImage.ImageSource = 'layers.png';

            app.AxesPanel = uipanel(app.MainGrid);
            app.AxesPanel.Title = 'Axes';
            app.AxesPanel.Layout.Row = 3;
            app.AxesPanel.Layout.Column = 1;
            app.AxesPanel.FontWeight = 'bold';
            app.AxesPanel.FontSize = 10.6666666666667;

            app.AxesGrid = uigridlayout(app.AxesPanel);
            app.AxesGrid.ColumnWidth = {20, 120, '1x'};
            app.AxesGrid.RowHeight = {20, 20, 20};
            app.AxesGrid.ColumnSpacing = 5;
            app.AxesGrid.RowSpacing = 5;
            app.AxesGrid.Padding = [5 5 5 5];

            app.PrimaryAxisLabel = uilabel(app.AxesGrid);
            app.PrimaryAxisLabel.HorizontalAlignment = 'right';
            app.PrimaryAxisLabel.FontSize = 10.6666666666667;
            app.PrimaryAxisLabel.Layout.Row = 1;
            app.PrimaryAxisLabel.Layout.Column = 2;
            app.PrimaryAxisLabel.Text = 'Primary Axis';

            app.NormalAxisLabel = uilabel(app.AxesGrid);
            app.NormalAxisLabel.HorizontalAlignment = 'right';
            app.NormalAxisLabel.FontSize = 10.6666666666667;
            app.NormalAxisLabel.Layout.Row = 2;
            app.NormalAxisLabel.Layout.Column = 2;
            app.NormalAxisLabel.Text = 'Plane Normal Axis';

            app.primaryAxisCombo = uidropdown(app.AxesGrid);
            app.primaryAxisCombo.Items = {};
            app.primaryAxisCombo.Tooltip = 'The coordinate system axis that points from the origin point toward the primary axis point.';
            app.primaryAxisCombo.FontSize = 10.6666666666667;
            app.primaryAxisCombo.BackgroundColor = [1 1 1];
            app.primaryAxisCombo.Layout.Row = 1;
            app.primaryAxisCombo.Layout.Column = 3;

            app.normalAxisCombo = uidropdown(app.AxesGrid);
            app.normalAxisCombo.Items = {};
            app.normalAxisCombo.Tooltip = 'The coordinate system axis that is normal to the plane of the three points.  Must not be the primary axis or its opposite.';
            app.normalAxisCombo.FontSize = 10.6666666666667;
            app.normalAxisCombo.BackgroundColor = [1 1 1];
            app.normalAxisCombo.Layout.Row = 2;
            app.normalAxisCombo.Layout.Column = 3;

            app.NoteLabel = uilabel(app.AxesGrid);
            app.NoteLabel.HorizontalAlignment = 'center';
            app.NoteLabel.WordWrap = 'on';
            app.NoteLabel.FontSize = 10.6666666666667;
            app.NoteLabel.FontAngle = 'italic';
            app.NoteLabel.Layout.Row = 3;
            app.NoteLabel.Layout.Column = [1 3];
            app.NoteLabel.Text = 'The third axis completes a right-handed set in the plane of the points.';
        end
    end
end
