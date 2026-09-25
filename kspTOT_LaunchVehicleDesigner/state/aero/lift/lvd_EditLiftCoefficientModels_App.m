classdef lvd_EditLiftCoefficientModels_App < matlab.apps.AppBase
    %lvd_EditLiftCoefficientModels_App Select the LVD lift coefficient model.
    %   Programmatic dialog replacing the former .mlapp of the same name
    %   (rewritten to add the D4 user-tabulated lift model without editing
    %   App Designer binaries). Behavior for the KSP cylinder model is
    %   unchanged.
    %
    %       lvd_EditLiftCoefficientModels_App(liftCoeffModel, lvdData, out)

    properties (Access = public)
        EditLiftPropertiesUIFigure     matlab.ui.Figure
        GridLayout                     matlab.ui.container.GridLayout
        TitleLabel                     matlab.ui.control.Label
        ButtonGrid                     matlab.ui.container.GridLayout
        saveCloseButton                matlab.ui.control.Button
        cancelButton                   matlab.ui.control.Button
        LiftCoefficientModelPanel      matlab.ui.container.Panel
        PanelGrid                      matlab.ui.container.GridLayout
        LiftCoeffModelCombo            matlab.ui.control.DropDown
        ModelDescLabel                 matlab.ui.control.Label
        EditLiftCoefficientModelButton matlab.ui.control.Button
    end

    properties (Access = private)
        output AppDesignerGUIOutput
        lvdData LvdData
        liftCoeffModel LiftCoeffModel
    end

    methods (Access = public)
        function app = lvd_EditLiftCoefficientModels_App(varargin)
            createComponents(app);
            registerApp(app, app.EditLiftPropertiesUIFigure);
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}));

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.EditLiftPropertiesUIFigure);
        end
    end

    methods (Access = private)
        function startupFcn(app, liftCoeffModel, lvdData, out)
            centerUIFigure(app.EditLiftPropertiesUIFigure);
            applySelectedThemeToApp(app);

            app.lvdData = lvdData;
            app.liftCoeffModel = liftCoeffModel;
            app.output = out;

            populateGUI(app);

            app.EditLiftPropertiesUIFigure.Visible = 'on';
            uiwait(app.EditLiftPropertiesUIFigure);
        end

        function populateGUI(app)
            [listBoxStr, m] = LiftCoefficientModelEnum.getListBoxStr();
            app.LiftCoeffModelCombo.Items = listBoxStr;
            app.LiftCoeffModelCombo.ItemsData = m;
            app.LiftCoeffModelCombo.Value = app.liftCoeffModel.liftCoeffObj.enum;

            app.ModelDescLabel.Text = app.liftCoeffModel.liftCoeffObj.enum.desc;
        end

        function saveAndClose(app)
            enum = app.LiftCoeffModelCombo.Value;
            switch enum
                case LiftCoefficientModelEnum.KSPCylinder
                    app.liftCoeffModel.liftCoeffObj = app.liftCoeffModel.cylinderModel;

                case LiftCoefficientModelEnum.UserTabulated
                    app.liftCoeffModel.liftCoeffObj = app.liftCoeffModel.tabularLiftModel;

                otherwise
                    error('Unknown lift coefficient model type: %s', enum.name);
            end

            app.output.output{1} = true;
            close(app.EditLiftPropertiesUIFigure);
        end

        function saveCloseButtonPushed(app, ~)
            saveAndClose(app);
        end

        function cancelButtonPushed(app, ~)
            app.output.output = {false};
            close(app.EditLiftPropertiesUIFigure);
        end

        function EditLiftCoefficientModelButtonPushed(app, ~)
            enum = app.LiftCoeffModelCombo.Value;
            switch enum
                case LiftCoefficientModelEnum.KSPCylinder
                    app.liftCoeffModel.cylinderModel.openEditDialog(app.lvdData);

                case LiftCoefficientModelEnum.UserTabulated
                    app.liftCoeffModel.tabularLiftModel.openEditDialog(app.lvdData);

                otherwise
                    error('Unknown lift coefficient model type: %s', enum.name);
            end
        end

        function LiftCoeffModelComboValueChanged(app, ~)
            value = app.LiftCoeffModelCombo.Value;
            app.ModelDescLabel.Text = value.desc;
        end

        function createComponents(app)
            app.EditLiftPropertiesUIFigure = uifigure('Visible', 'off');
            app.EditLiftPropertiesUIFigure.Position = [100 100 389 254];
            app.EditLiftPropertiesUIFigure.Name = 'Edit Lift Properties';
            app.EditLiftPropertiesUIFigure.WindowStyle = 'modal';

            app.GridLayout = uigridlayout(app.EditLiftPropertiesUIFigure);
            app.GridLayout.ColumnWidth = {'1x'};
            app.GridLayout.RowHeight = {24, '1x', 29};

            app.TitleLabel = uilabel(app.GridLayout);
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;
            app.TitleLabel.Text = 'Edit Lift Properties';

            app.LiftCoefficientModelPanel = uipanel(app.GridLayout);
            app.LiftCoefficientModelPanel.Title = 'Lift Coefficient Model';
            app.LiftCoefficientModelPanel.FontWeight = 'bold';
            app.LiftCoefficientModelPanel.Layout.Row = 2;
            app.LiftCoefficientModelPanel.Layout.Column = 1;

            app.PanelGrid = uigridlayout(app.LiftCoefficientModelPanel);
            app.PanelGrid.ColumnWidth = {'1x'};
            app.PanelGrid.RowHeight = {22, '1x', 29};
            app.PanelGrid.Padding = [5 5 5 5];

            app.LiftCoeffModelCombo = uidropdown(app.PanelGrid);
            app.LiftCoeffModelCombo.ValueChangedFcn = @(src,evt) app.LiftCoeffModelComboValueChanged(evt);
            app.LiftCoeffModelCombo.Layout.Row = 1;
            app.LiftCoeffModelCombo.Layout.Column = 1;

            app.ModelDescLabel = uilabel(app.PanelGrid);
            app.ModelDescLabel.VerticalAlignment = 'top';
            app.ModelDescLabel.WordWrap = 'on';
            app.ModelDescLabel.Layout.Row = 2;
            app.ModelDescLabel.Layout.Column = 1;

            app.EditLiftCoefficientModelButton = uibutton(app.PanelGrid, 'push');
            app.EditLiftCoefficientModelButton.ButtonPushedFcn = @(src,evt) app.EditLiftCoefficientModelButtonPushed(evt);
            app.EditLiftCoefficientModelButton.Layout.Row = 3;
            app.EditLiftCoefficientModelButton.Layout.Column = 1;
            app.EditLiftCoefficientModelButton.Text = 'Edit Lift Coefficient Model';

            app.ButtonGrid = uigridlayout(app.GridLayout);
            app.ButtonGrid.ColumnWidth = {'1x', '2x', '2x', '1x'};
            app.ButtonGrid.RowHeight = {'1x'};
            app.ButtonGrid.Padding = [0 0 0 0];
            app.ButtonGrid.Layout.Row = 3;
            app.ButtonGrid.Layout.Column = 1;

            app.saveCloseButton = uibutton(app.ButtonGrid, 'push');
            app.saveCloseButton.ButtonPushedFcn = @(src,evt) app.saveCloseButtonPushed(evt);
            app.saveCloseButton.Layout.Row = 1;
            app.saveCloseButton.Layout.Column = 2;
            app.saveCloseButton.Text = 'Save & Close';

            app.cancelButton = uibutton(app.ButtonGrid, 'push');
            app.cancelButton.ButtonPushedFcn = @(src,evt) app.cancelButtonPushed(evt);
            app.cancelButton.Layout.Row = 1;
            app.cancelButton.Layout.Column = 3;
            app.cancelButton.Text = 'Cancel';

            app.EditLiftPropertiesUIFigure.Visible = 'on';
        end
    end
end
