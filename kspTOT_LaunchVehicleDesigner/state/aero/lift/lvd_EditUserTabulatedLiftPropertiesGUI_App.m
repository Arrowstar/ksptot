classdef lvd_EditUserTabulatedLiftPropertiesGUI_App < matlab.apps.AppBase
    %lvd_EditUserTabulatedLiftPropertiesGUI_App Edit UserTabulatedLiftModel CSV file.
    %   Programmatic dialog (no .mlapp) mirroring
    %   lvd_EditKosDragPropertiesGUI_App: pick the CSV file
    %   (mach, AoA_deg, sideslip_deg, ClS_m2), preview Cl*S at a Mach
    %   number, Save & Close writes back to the model.
    %
    %       lvd_EditUserTabulatedLiftPropertiesGUI_App(liftModel, lvdData, out)

    properties (Access = public)
        EditLiftPropertiesUIFigure  matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        TitleLabel                  matlab.ui.control.Label
        ButtonGrid                  matlab.ui.container.GridLayout
        saveCloseButton             matlab.ui.control.Button
        cancelButton                matlab.ui.control.Button
        MainGrid                    matlab.ui.container.GridLayout
        FilePanel                   matlab.ui.container.Panel
        FileGrid                    matlab.ui.container.GridLayout
        FileSelector                wt.FileSelector
        DataPanel                   matlab.ui.container.Panel
        DataGrid                    matlab.ui.container.GridLayout
        DataAxes                    matlab.ui.control.UIAxes
        SliderGrid                  matlab.ui.container.GridLayout
        MachNumberLabel             matlab.ui.control.Label
        MachNumSlider               matlab.ui.control.Slider
    end

    properties (Access = private)
        output AppDesignerGUIOutput
        lvdData LvdData
        liftModel UserTabulatedLiftModel
        dummyModel UserTabulatedLiftModel
    end

    methods (Access = public)
        function app = lvd_EditUserTabulatedLiftPropertiesGUI_App(varargin)
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
        function startupFcn(app, liftModel, lvdData, out)
            centerUIFigure(app.EditLiftPropertiesUIFigure);
            applySelectedThemeToApp(app);

            app.lvdData = lvdData;
            app.liftModel = liftModel;
            app.output = out;

            app.FileSelector.Value = liftModel.dataFile;
            try
                app.FileSelector.DefaultDirectory = pwd;
            catch
            end

            if(~isempty(liftModel.machNum) && ~isempty(liftModel.aoa) && ~isempty(liftModel.sideslip))
                app.plotData();
            end

            app.EditLiftPropertiesUIFigure.Visible = 'on';
            uiwait(app.EditLiftPropertiesUIFigure);
        end

        function plotData(app)
            if(app.FileSelector.ValueIsValidPath)
                try
                    dataFile = app.FileSelector.FullPath;
                    app.dummyModel = UserTabulatedLiftModel(dataFile);

                    allMach = app.dummyModel.machNum;
                    limits = [min(allMach), max(allMach)];
                    if(limits(1) == limits(2))
                        limits(2) = limits(1) + 1;
                    end
                    app.MachNumSlider.Limits = limits;

                    curMach = app.MachNumSlider.Value;
                    if(curMach >= limits(1) && curMach <= limits(2))
                        app.MachNumSlider.Value = curMach;
                    else
                        app.MachNumSlider.Value = limits(1);
                    end

                    app.dummyModel.plotLiftEnvelope(app.DataAxes, app.MachNumSlider.Value);
                catch
                    app.liftModel.plotLiftEnvelope(app.DataAxes, app.MachNumSlider.Value);
                end
            else
                if(~isempty(app.liftModel.giClS))
                    app.liftModel.plotLiftEnvelope(app.DataAxes, app.MachNumSlider.Value);
                end
            end
        end

        function errMsg = validateInputs(app)
            errMsg = {};

            if(~app.FileSelector.ValueIsValidPath)
                errMsg{end+1} = 'The selected lift coefficient data file does not exist.';
            else
                try
                    app.liftModel.dataFile = app.FileSelector.FullPath;
                    app.liftModel.clearData();
                    app.liftModel.createGriddedInterpFromFile();
                catch ME
                    errMsg{end+1} = sprintf("Import of the lift coefficient data failed.  Message: \n\n%s", ME.message);
                end
            end
        end

        function saveAndClose(app)
            app.liftModel.dataFile = app.FileSelector.FullPath;
            app.liftModel.clearData();
            app.liftModel.createGriddedInterpFromFile();

            app.output.output{1} = true;
            close(app.EditLiftPropertiesUIFigure);
        end

        function saveCloseButtonPushed(app, ~)
            errMsg = validateInputs(app);

            if(isempty(errMsg))
                saveAndClose(app);
            else
                uialert(app.EditLiftPropertiesUIFigure, errMsg, 'Errors were found while editing lift properties.', "Icon","error");
            end
        end

        function cancelButtonPushed(app, ~)
            app.output.output = {false};
            close(app.EditLiftPropertiesUIFigure);
        end

        function FileSelectorValueChanged(app, ~)
            app.plotData();
        end

        function MachNumSliderValueChanged(app, ~)
            machNum = app.MachNumSlider.Value;

            if(~isempty(app.dummyModel) && ~isempty(app.dummyModel.giClS))
                app.dummyModel.plotLiftEnvelope(app.DataAxes, machNum);
            elseif(~isempty(app.liftModel.giClS))
                app.liftModel.plotLiftEnvelope(app.DataAxes, machNum);
            end
        end

        function createComponents(app)
            app.EditLiftPropertiesUIFigure = uifigure('Visible', 'off');
            app.EditLiftPropertiesUIFigure.Position = [100 100 426 500];
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

            app.MainGrid = uigridlayout(app.GridLayout);
            app.MainGrid.ColumnWidth = {'1x'};
            app.MainGrid.RowHeight = {50, '1x'};
            app.MainGrid.Padding = [5 5 5 5];
            app.MainGrid.Layout.Row = 2;
            app.MainGrid.Layout.Column = 1;

            app.FilePanel = uipanel(app.MainGrid);
            app.FilePanel.Title = 'Lift Coefficient CSV File';
            app.FilePanel.FontWeight = 'bold';
            app.FilePanel.Layout.Row = 1;
            app.FilePanel.Layout.Column = 1;

            app.FileGrid = uigridlayout(app.FilePanel);
            app.FileGrid.ColumnWidth = {'1x'};
            app.FileGrid.RowHeight = {'1x'};
            app.FileGrid.Padding = [5 5 5 5];

            app.FileSelector = wt.FileSelector(app.FileGrid);
            app.FileSelector.ValueChangedFcn = @(src,evt) app.FileSelectorValueChanged(evt);
            app.FileSelector.Layout.Row = 1;
            app.FileSelector.Layout.Column = 1;

            app.DataPanel = uipanel(app.MainGrid);
            app.DataPanel.Title = 'Tabulated Lift Data (mach, AoA_deg, sideslip_deg, ClS_m2)';
            app.DataPanel.FontWeight = 'bold';
            app.DataPanel.Layout.Row = 2;
            app.DataPanel.Layout.Column = 1;

            app.DataGrid = uigridlayout(app.DataPanel);
            app.DataGrid.ColumnWidth = {'1x'};
            app.DataGrid.RowHeight = {'1x', 50};
            app.DataGrid.Padding = [5 5 5 5];

            app.DataAxes = uiaxes(app.DataGrid);
            title(app.DataAxes, 'Cl*S');
            xlabel(app.DataAxes, 'AoA [deg]');
            ylabel(app.DataAxes, 'Sideslip [deg]');
            app.DataAxes.Layout.Row = 1;
            app.DataAxes.Layout.Column = 1;

            app.SliderGrid = uigridlayout(app.DataGrid);
            app.SliderGrid.ColumnWidth = {100, '1x'};
            app.SliderGrid.RowHeight = {'1x'};
            app.SliderGrid.Padding = [0 0 0 0];
            app.SliderGrid.Layout.Row = 2;
            app.SliderGrid.Layout.Column = 1;

            app.MachNumberLabel = uilabel(app.SliderGrid);
            app.MachNumberLabel.HorizontalAlignment = 'center';
            app.MachNumberLabel.Layout.Row = 1;
            app.MachNumberLabel.Layout.Column = 1;
            app.MachNumberLabel.Text = 'Mach Number';

            app.MachNumSlider = uislider(app.SliderGrid);
            app.MachNumSlider.Limits = [0 10];
            app.MachNumSlider.ValueChangedFcn = @(src,evt) app.MachNumSliderValueChanged(evt);
            app.MachNumSlider.Tooltip = {'This slider adjusts the Mach number at which the lift data is plotted.'};
            app.MachNumSlider.Layout.Row = 1;
            app.MachNumSlider.Layout.Column = 2;

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
