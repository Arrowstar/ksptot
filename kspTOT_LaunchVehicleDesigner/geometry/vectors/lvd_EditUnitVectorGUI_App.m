classdef lvd_EditUnitVectorGUI_App < matlab.apps.AppBase
    %lvd_EditUnitVectorGUI_App Editor dialog for UnitVector geometry objects.
    %   Programmatic uifigure sibling of lvd_EditVectorDifferenceVectorGUI_App
    %   (same size, panels and controls).  Launched the same way:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditUnitVectorGUI_App(vector, lvdData, output);
    %
    %   The vector is a handle and is mutated in place on Save & Close, at
    %   which point output.output is set to {true}.

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
        vectorNameText         matlab.ui.control.EditField
        VectorPanel            matlab.ui.container.Panel
        VectorGrid             matlab.ui.container.GridLayout
        VectorImage            matlab.ui.control.Image
        VectorLabel            matlab.ui.control.Label
        vectorCombo            matlab.ui.control.DropDown
        DisplayPanel           matlab.ui.container.Panel
        DisplayGrid            matlab.ui.container.GridLayout
        DisplayLabel           matlab.ui.control.Label
        ColorImage             matlab.ui.control.Image
        LineImage              matlab.ui.control.Image
        vectorLineColorCombo   matlab.ui.control.DropDown
        vectorLineSpecCombo    matlab.ui.control.DropDown
    end

    properties (Access = private)
        vector UnitVector
        lvdData LvdData
        output AppDesignerGUIOutput
        allVectors AbstractGeometricVector
    end

    methods (Access = public)
        function app = lvd_EditUnitVectorGUI_App(varargin)
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
        function startupFcn(app, vector, lvdData, output)
            app.vector = vector;
            app.lvdData = lvdData;
            app.output = output;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            populateGUI(app);

            app.UIFigure.Visible = 'on';
            uiwait(app.UIFigure);
        end

        function populateGUI(app)
            app.vectorNameText.Value = app.vector.getName();

            [vectorsListBoxStr, vectors] = app.lvdData.geometry.vectors.getListboxStr();
            bool = vectors == app.vector;
            vectorsListBoxStr(bool) = [];
            vectors(bool) = [];
            app.allVectors = vectors;

            app.vectorCombo.Items = vectorsListBoxStr;
            app.vectorCombo.ItemsData = 1:numel(vectors);
            ind = find(vectors == app.vector.vector, 1, 'first');
            if(isempty(ind) && not(isempty(vectors)))
                ind = 1;
            end
            if(not(isempty(ind)))
                app.vectorCombo.Value = ind;
            end

            app.vectorLineColorCombo.Items = ColorSpecEnum.getListboxStr();
            app.vectorLineColorCombo.Value = app.vector.lineColor.name;

            app.vectorLineSpecCombo.Items = LineSpecEnum.getListboxStr();
            app.vectorLineSpecCombo.Value = app.vector.lineSpec.name;
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(isempty(app.allVectors))
                errMsg{end+1} = 'There must be at least one other geometric vector available to build a unit vector from.';
            end

            if(isempty(strtrim(app.vectorNameText.Value)))
                errMsg{end+1} = 'Vector name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.vector.setName(app.vectorNameText.Value);
            app.vector.vector = app.allVectors(app.vectorCombo.Value);
            app.vector.lineColor = ColorSpecEnum.getEnumForListboxStr(app.vectorLineColorCombo.Value);
            app.vector.lineSpec = LineSpecEnum.getEnumForListboxStr(app.vectorLineSpecCombo.Value);

            app.output.output = {true};
            delete(app.UIFigure);
        end

        function saveAndCloseButton_Callback(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Invalid Vector Inputs', 'Icon','error');
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
            app.UIFigure.Position = [680 957 430 326];
            app.UIFigure.Name = 'Edit Vector';
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
            app.TitleLabel.Text = 'Edit Vector';

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
            app.NameGrid.RowHeight = {'1x'};
            app.NameGrid.ColumnSpacing = 5;
            app.NameGrid.RowSpacing = 5;
            app.NameGrid.Padding = [5 5 5 5];

            app.NameLabel = uilabel(app.NameGrid);
            app.NameLabel.HorizontalAlignment = 'right';
            app.NameLabel.WordWrap = 'on';
            app.NameLabel.FontSize = 10.6666666666667;
            app.NameLabel.Layout.Row = 1;
            app.NameLabel.Layout.Column = 2;
            app.NameLabel.Text = 'Vector Name';

            app.vectorNameText = uieditfield(app.NameGrid, 'text');
            app.vectorNameText.HorizontalAlignment = 'center';
            app.vectorNameText.FontSize = 10.6666666666667;
            app.vectorNameText.Layout.Row = 1;
            app.vectorNameText.Layout.Column = 3;

            app.VectorPanel = uipanel(app.MainGrid);
            app.VectorPanel.Title = 'Vector';
            app.VectorPanel.Layout.Row = 2;
            app.VectorPanel.Layout.Column = 1;
            app.VectorPanel.FontWeight = 'bold';
            app.VectorPanel.FontSize = 10.6666666666667;

            app.VectorGrid = uigridlayout(app.VectorPanel);
            app.VectorGrid.ColumnWidth = {20, 100, '1x'};
            app.VectorGrid.RowHeight = {20, 20};
            app.VectorGrid.ColumnSpacing = 5;
            app.VectorGrid.RowSpacing = 5;
            app.VectorGrid.Padding = [5 5 5 5];

            app.VectorLabel = uilabel(app.VectorGrid);
            app.VectorLabel.HorizontalAlignment = 'right';
            app.VectorLabel.WordWrap = 'on';
            app.VectorLabel.FontSize = 10.6666666666667;
            app.VectorLabel.Layout.Row = 1;
            app.VectorLabel.Layout.Column = 2;
            app.VectorLabel.Text = 'Input Vector';

            app.vectorCombo = uidropdown(app.VectorGrid);
            app.vectorCombo.Items = {};
            app.vectorCombo.Tooltip = {'The vector to normalize.  The output has unit length and points along this vector (or is zero if this vector is zero).'};
            app.vectorCombo.FontSize = 10.6666666666667;
            app.vectorCombo.BackgroundColor = [1 1 1];
            app.vectorCombo.Layout.Row = 1;
            app.vectorCombo.Layout.Column = 3;

            app.VectorImage = uiimage(app.VectorGrid);
            app.VectorImage.Layout.Row = 1;
            app.VectorImage.Layout.Column = 1;
            app.VectorImage.ImageSource = 'green-arrow.png';

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
            app.DisplayLabel.Text = 'Vector Line';

            app.vectorLineColorCombo = uidropdown(app.DisplayGrid);
            app.vectorLineColorCombo.Items = {};
            app.vectorLineColorCombo.Tooltip = 'The color of the vector''s line on the display.';
            app.vectorLineColorCombo.FontSize = 10.6666666666667;
            app.vectorLineColorCombo.BackgroundColor = [1 1 1];
            app.vectorLineColorCombo.Layout.Row = 2;
            app.vectorLineColorCombo.Layout.Column = 3;

            app.vectorLineSpecCombo = uidropdown(app.DisplayGrid);
            app.vectorLineSpecCombo.Items = {};
            app.vectorLineSpecCombo.Tooltip = 'The style of the vector''s line on the display.';
            app.vectorLineSpecCombo.FontSize = 10.6666666666667;
            app.vectorLineSpecCombo.BackgroundColor = [1 1 1];
            app.vectorLineSpecCombo.Layout.Row = 3;
            app.vectorLineSpecCombo.Layout.Column = 3;

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
