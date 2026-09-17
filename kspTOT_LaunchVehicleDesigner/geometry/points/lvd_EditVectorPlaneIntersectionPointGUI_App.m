classdef lvd_EditVectorPlaneIntersectionPointGUI_App < matlab.apps.AppBase
    %lvd_EditVectorPlaneIntersectionPointGUI_App Editor dialog for
    %VectorPlaneIntersectionPoint objects.  Programmatic uifigure sibling of
    %lvd_EditFixedInFramePointGUI_App (same panels, display controls and
    %Save/Cancel behaviour).  Launched the same way:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditVectorPlaneIntersectionPointGUI_App(point, lvdData, output);

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
        GeometryPanel          matlab.ui.container.Panel
        GeometryGrid           matlab.ui.container.GridLayout
        OriginImage            matlab.ui.control.Image
        VectorImage            matlab.ui.control.Image
        PlaneImage             matlab.ui.control.Image
        OriginLabel            matlab.ui.control.Label
        VectorLabel            matlab.ui.control.Label
        PlaneLabel             matlab.ui.control.Label
        originPointCombo       matlab.ui.control.DropDown
        vectorCombo            matlab.ui.control.DropDown
        planeCombo             matlab.ui.control.DropDown
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
        point VectorPlaneIntersectionPoint
        lvdData LvdData
        output AppDesignerGUIOutput
        allPoints AbstractGeometricPoint
        allVectors AbstractGeometricVector
        allPlanes AbstractGeometricPlane
    end

    methods (Access = public)
        function app = lvd_EditVectorPlaneIntersectionPointGUI_App(varargin)
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

            [pointsListBoxStr, points] = app.lvdData.geometry.points.getListboxStr();
            bool = points == app.point;
            pointsListBoxStr(bool) = [];
            points(bool) = [];
            app.allPoints = points;

            [vectorsListBoxStr, vectors] = app.lvdData.geometry.vectors.getListboxStr();
            app.allVectors = vectors;

            [planesListBoxStr, planes] = app.lvdData.geometry.planes.getListboxStr();
            app.allPlanes = planes;

            app.originPointCombo.Items = pointsListBoxStr;
            app.originPointCombo.ItemsData = 1:numel(points);
            ind = find(points == app.point.originPoint, 1, 'first');
            if(not(isempty(points)))
                if(isempty(ind)), ind = 1; end
                app.originPointCombo.Value = ind;
            end

            app.vectorCombo.Items = vectorsListBoxStr;
            app.vectorCombo.ItemsData = 1:numel(vectors);
            ind = find(vectors == app.point.vector, 1, 'first');
            if(not(isempty(vectors)))
                if(isempty(ind)), ind = 1; end
                app.vectorCombo.Value = ind;
            end

            app.planeCombo.Items = planesListBoxStr;
            app.planeCombo.ItemsData = 1:numel(planes);
            ind = find(planes == app.point.plane, 1, 'first');
            if(not(isempty(planes)))
                if(isempty(ind)), ind = 1; end
                app.planeCombo.Value = ind;
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

        function errMsg = validateInputs(app)
            errMsg = {};

            if(isempty(app.allPoints))
                errMsg{end+1} = 'There must be at least one other geometric point available to use as the line origin.';
            end

            if(isempty(app.allVectors))
                errMsg{end+1} = 'There must be at least one geometric vector available to use as the line direction.';
            end

            if(isempty(app.allPlanes))
                errMsg{end+1} = 'There must be at least one geometric plane available.';
            end

            if(isempty(strtrim(app.pointNameText.Value)))
                errMsg{end+1} = 'Point name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.point.setName(app.pointNameText.Value);
            app.point.originPoint = app.allPoints(app.originPointCombo.Value);
            app.point.vector = app.allVectors(app.vectorCombo.Value);
            app.point.plane = app.allPlanes(app.planeCombo.Value);

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
            app.UIFigure.Position = [680 957 430 420];
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
            app.MainGrid.RowHeight = {50, 105, 140};
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

            app.GeometryPanel = uipanel(app.MainGrid);
            app.GeometryPanel.Title = 'Line and Plane';
            app.GeometryPanel.Layout.Row = 2;
            app.GeometryPanel.Layout.Column = 1;
            app.GeometryPanel.FontWeight = 'bold';
            app.GeometryPanel.FontSize = 10.6666666666667;

            app.GeometryGrid = uigridlayout(app.GeometryPanel);
            app.GeometryGrid.ColumnWidth = {20, 100, '1x'};
            app.GeometryGrid.RowHeight = {20, 20, 20};
            app.GeometryGrid.ColumnSpacing = 5;
            app.GeometryGrid.RowSpacing = 5;
            app.GeometryGrid.Padding = [5 5 5 5];

            app.OriginLabel = uilabel(app.GeometryGrid);
            app.OriginLabel.HorizontalAlignment = 'right';
            app.OriginLabel.FontSize = 10.6666666666667;
            app.OriginLabel.Layout.Row = 1;
            app.OriginLabel.Layout.Column = 2;
            app.OriginLabel.Text = 'Line Origin Point';

            app.VectorLabel = uilabel(app.GeometryGrid);
            app.VectorLabel.HorizontalAlignment = 'right';
            app.VectorLabel.FontSize = 10.6666666666667;
            app.VectorLabel.Layout.Row = 2;
            app.VectorLabel.Layout.Column = 2;
            app.VectorLabel.Text = 'Line Direction';

            app.PlaneLabel = uilabel(app.GeometryGrid);
            app.PlaneLabel.HorizontalAlignment = 'right';
            app.PlaneLabel.FontSize = 10.6666666666667;
            app.PlaneLabel.Layout.Row = 3;
            app.PlaneLabel.Layout.Column = 2;
            app.PlaneLabel.Text = 'Plane';

            app.originPointCombo = uidropdown(app.GeometryGrid);
            app.originPointCombo.Items = {};
            app.originPointCombo.Tooltip = 'The point the line passes through.';
            app.originPointCombo.FontSize = 10.6666666666667;
            app.originPointCombo.BackgroundColor = [1 1 1];
            app.originPointCombo.Layout.Row = 1;
            app.originPointCombo.Layout.Column = 3;

            app.vectorCombo = uidropdown(app.GeometryGrid);
            app.vectorCombo.Items = {};
            app.vectorCombo.Tooltip = 'The direction of the line.  The line extends in both directions from the origin point.';
            app.vectorCombo.FontSize = 10.6666666666667;
            app.vectorCombo.BackgroundColor = [1 1 1];
            app.vectorCombo.Layout.Row = 2;
            app.vectorCombo.Layout.Column = 3;

            app.planeCombo = uidropdown(app.GeometryGrid);
            app.planeCombo.Items = {};
            app.planeCombo.Tooltip = 'The plane the line intersects.  The point is undefined (NaN) when the line is parallel to the plane.';
            app.planeCombo.FontSize = 10.6666666666667;
            app.planeCombo.BackgroundColor = [1 1 1];
            app.planeCombo.Layout.Row = 3;
            app.planeCombo.Layout.Column = 3;

            app.OriginImage = uiimage(app.GeometryGrid);
            app.OriginImage.Layout.Row = 1;
            app.OriginImage.Layout.Column = 1;
            app.OriginImage.ImageSource = 'red-arrow.png';

            app.VectorImage = uiimage(app.GeometryGrid);
            app.VectorImage.Layout.Row = 2;
            app.VectorImage.Layout.Column = 1;
            app.VectorImage.ImageSource = 'green-arrow.png';

            app.PlaneImage = uiimage(app.GeometryGrid);
            app.PlaneImage.Layout.Row = 3;
            app.PlaneImage.Layout.Column = 1;
            app.PlaneImage.ImageSource = 'layers.png';

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
