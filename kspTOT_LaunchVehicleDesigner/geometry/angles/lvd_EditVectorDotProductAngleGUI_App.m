classdef lvd_EditVectorDotProductAngleGUI_App < matlab.apps.AppBase
    %lvd_EditVectorDotProductAngleGUI_App Editor dialog for VectorDotProductAngle objects.
    %   Programmatic uifigure sibling of lvd_EditTwoPlaneAngleGUI_App, minus
    %   the Display panel: a dot product is a scalar with nothing to draw.
    %   Launched the same way:
    %
    %       output = AppDesignerGUIOutput({false});
    %       lvd_EditVectorDotProductAngleGUI_App(angle, lvdData, output);

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
        VectorsPanel           matlab.ui.container.Panel
        VectorsGrid            matlab.ui.container.GridLayout
        Vector1Image           matlab.ui.control.Image
        Vector2Image           matlab.ui.control.Image
        Vector1Label           matlab.ui.control.Label
        Vector2Label           matlab.ui.control.Label
        vector1Combo           matlab.ui.control.DropDown
        vector2Combo           matlab.ui.control.DropDown
        NoteLabel              matlab.ui.control.Label
    end

    properties (Access = private)
        angle VectorDotProductAngle
        lvdData LvdData
        output AppDesignerGUIOutput
        allVectors AbstractGeometricVector
    end

    methods (Access = public)
        function app = lvd_EditVectorDotProductAngleGUI_App(varargin)
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

            [vectorsListBoxStr, vectors] = app.lvdData.geometry.vectors.getListboxStr();
            app.allVectors = vectors;

            app.vector1Combo.Items = vectorsListBoxStr;
            app.vector1Combo.ItemsData = 1:numel(vectors);
            app.vector2Combo.Items = vectorsListBoxStr;
            app.vector2Combo.ItemsData = 1:numel(vectors);

            ind1 = find(vectors == app.angle.vector1, 1, 'first');
            ind2 = find(vectors == app.angle.vector2, 1, 'first');
            if(not(isempty(vectors)))
                if(isempty(ind1)), ind1 = 1; end
                if(isempty(ind2)), ind2 = min(2, numel(vectors)); end
                app.vector1Combo.Value = ind1;
                app.vector2Combo.Value = ind2;
            end
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(isempty(app.allVectors))
                errMsg{end+1} = 'There must be at least one geometric vector available.';
            end

            if(isempty(strtrim(app.nameText.Value)))
                errMsg{end+1} = 'Angle name must contain more than white space and must not be empty.';
            end
        end

        function saveAndClose(app)
            app.angle.setName(app.nameText.Value);
            app.angle.vector1 = app.allVectors(app.vector1Combo.Value);
            app.angle.vector2 = app.allVectors(app.vector2Combo.Value);

            app.output.output = {true};
            delete(app.UIFigure);
        end

        function saveAndCloseButton_Callback(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                app.saveAndClose();
            else
                uialert(app.UIFigure, errMsg, 'Invalid Dot Product Inputs', 'Icon','error');
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
            app.UIFigure.Position = [680 957 430 270];
            app.UIFigure.Name = 'Edit Dot Product';
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
            app.TitleLabel.Text = 'Edit Dot Product';

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
            app.MainGrid.RowHeight = {50, 100};
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
            app.NameLabel.Text = 'Name';

            app.nameText = uieditfield(app.NameGrid, 'text');
            app.nameText.HorizontalAlignment = 'center';
            app.nameText.FontSize = 10.6666666666667;
            app.nameText.Layout.Row = 1;
            app.nameText.Layout.Column = 3;

            app.VectorsPanel = uipanel(app.MainGrid);
            app.VectorsPanel.Title = 'Vectors';
            app.VectorsPanel.Layout.Row = 2;
            app.VectorsPanel.Layout.Column = 1;
            app.VectorsPanel.FontWeight = 'bold';
            app.VectorsPanel.FontSize = 10.6666666666667;

            app.VectorsGrid = uigridlayout(app.VectorsPanel);
            app.VectorsGrid.ColumnWidth = {20, 100, '1x'};
            app.VectorsGrid.RowHeight = {20, 20, 20};
            app.VectorsGrid.ColumnSpacing = 5;
            app.VectorsGrid.RowSpacing = 5;
            app.VectorsGrid.Padding = [5 5 5 5];

            app.Vector1Label = uilabel(app.VectorsGrid);
            app.Vector1Label.HorizontalAlignment = 'right';
            app.Vector1Label.WordWrap = 'on';
            app.Vector1Label.FontSize = 10.6666666666667;
            app.Vector1Label.Layout.Row = 1;
            app.Vector1Label.Layout.Column = 2;
            app.Vector1Label.Text = 'Vector 1';

            app.Vector2Label = uilabel(app.VectorsGrid);
            app.Vector2Label.HorizontalAlignment = 'right';
            app.Vector2Label.WordWrap = 'on';
            app.Vector2Label.FontSize = 10.6666666666667;
            app.Vector2Label.Layout.Row = 2;
            app.Vector2Label.Layout.Column = 2;
            app.Vector2Label.Text = 'Vector 2';

            app.vector1Combo = uidropdown(app.VectorsGrid);
            app.vector1Combo.Items = {};
            app.vector1Combo.Tooltip = 'The first vector of the dot product.  The result has the product of the two vectors'' units (km^2 for two position vectors); use Unit Vector inputs to get the cosine of the angle between them.';
            app.vector1Combo.FontSize = 10.6666666666667;
            app.vector1Combo.BackgroundColor = [1 1 1];
            app.vector1Combo.Layout.Row = 1;
            app.vector1Combo.Layout.Column = 3;

            app.vector2Combo = uidropdown(app.VectorsGrid);
            app.vector2Combo.Items = {};
            app.vector2Combo.Tooltip = 'The second vector of the dot product.  The same vector may be selected twice to get its squared magnitude.';
            app.vector2Combo.FontSize = 10.6666666666667;
            app.vector2Combo.BackgroundColor = [1 1 1];
            app.vector2Combo.Layout.Row = 2;
            app.vector2Combo.Layout.Column = 3;

            app.Vector1Image = uiimage(app.VectorsGrid);
            app.Vector1Image.Layout.Row = 1;
            app.Vector1Image.Layout.Column = 1;
            app.Vector1Image.ImageSource = 'red-arrow.png';

            app.Vector2Image = uiimage(app.VectorsGrid);
            app.Vector2Image.Layout.Row = 2;
            app.Vector2Image.Layout.Column = 1;
            app.Vector2Image.ImageSource = 'green-arrow.png';

            app.NoteLabel = uilabel(app.VectorsGrid);
            app.NoteLabel.HorizontalAlignment = 'center';
            app.NoteLabel.WordWrap = 'on';
            app.NoteLabel.FontSize = 10.6666666666667;
            app.NoteLabel.FontAngle = 'italic';
            app.NoteLabel.Layout.Row = 3;
            app.NoteLabel.Layout.Column = [1 3];
            app.NoteLabel.Text = 'The dot product is a dimensionless scalar; it is not drawn in the 3D view.';
        end
    end
end
