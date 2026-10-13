classdef TwoDKwtDragDialogTest < KsptotTestCase
    %TwoDKwtDragDialogTest Full round-trip UI tests for the 2-D Kerbal Wind
    %Tunnel drag editor (Phase 4: state/aero/SRP).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/state/aero/drag/lvd_Edit2DKerbalWindTunnelDragPropertiesGUI_App.mlapp
    %   ('Edit Drag Properties'; programmatic, ctor (dragCoeffModel, lvdData, out))
    %   backing class: TwoDimKspWindTunnelDragCoeffModel
    %   production caller: TwoDimKspWindTunnelDragCoeffModel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/ForceModels/aero/drag/two_dim_kerbal_wind_tunnel/@TwoDimKspWindTunnelDragCoeffModel/TwoDimKspWindTunnelDragCoeffModel.m:128-132).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  The model is the default
    %   mission's 2-D wind-tunnel slot; envelope CSVs are synthetic
    %   fixtures (first row holds speeds in m/s, first column altitudes in
    %   m, matching TwoDimKspWindTunnelDragCoeffModel.createGriddedInterpFromFile).
    %
    % COVERED
    %   Open shows the stored envelope file; Save & Close loads the picked
    %   file into the model; saving an already-loaded envelope round-trips;
    %   a missing file is rejected and leaves the model alone; Cancel and
    %   window-X preserve the model.
    %
    % NOTE
    %   validateInputs reloads the model while validating, so a corrupt
    %   (but existing) file can mutate the model even though the save is
    %   rejected (see bug list); the rejection test below pins the
    %   missing-file path, which leaves the model alone.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredDataFile(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            model.dataFile = csvPath;
            model.createGriddedInterpFromFile();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            testCase.verifyEqual(app.EditDragPropertiesUIFigure.Name, 'Edit Drag Properties');
            testCase.verifyEqual(string(app.FileSelector.Value), string(csvPath), ...
                'The selector must show the stored envelope file.');
        end

        function saveAndCloseLoadsSelectedFile(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.FileSelector.Value = csvPath;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(string(model.dataFile), string(csvPath));
            testCase.verifyEqual(model.speed, [0 1], 'AbsTol', 0);
            testCase.verifyEqual(model.altitude, [0; 1], 'AbsTol', 0);
            testCase.verifyTrue(isfinite(model.gi(0.5, 0.5)) && model.gi(0.5, 0.5) > 0, ...
                'Save must build a usable interpolant from the file.');
        end

        function saveKeepsPreloadedEnvelope(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            model.dataFile = csvPath;
            model.createGriddedInterpFromFile();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyEqual(string(model.dataFile), string(csvPath));
            testCase.verifyEqual(model.data, [1 2; 1.5 2.5], 'AbsTol', 0, ...
                'Saving an unchanged envelope must keep its data.');
        end

        function missingFileIsRejected(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            model.dataFile = csvPath;
            model.createGriddedInterpFromFile();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);

            app.FileSelector.Value = fullfile(tempdir(), 'definitely-not-a-kwt-file.csv');
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyFalse(out.output{1}, 'A missing envelope file must not save.');
            testCase.verifyTrue(isvalid(app.EditDragPropertiesUIFigure), ...
                'The dialog must stay open for correction.');
            testCase.verifyEqual(string(model.dataFile), string(csvPath), ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            otherPath = testCase.writeOtherKwtCsv();
            model.dataFile = csvPath;
            model.createGriddedInterpFromFile();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.FileSelector.Value = otherPath;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(string(model.dataFile), string(csvPath), ...
                'Cancel must leave the model alone.');
            testCase.verifyEqual(model.data(1, 1), 1, 'AbsTol', 0);
        end

        function windowXPreservesModel(testCase)
            [model, lvdData] = testCase.fixture();
            csvPath = testCase.writeKwtCsv();
            otherPath = testCase.writeOtherKwtCsv();
            model.dataFile = csvPath;
            model.createGriddedInterpFromFile();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(model, lvdData, out);
            fig = app.EditDragPropertiesUIFigure;

            app.FileSelector.Value = otherPath;
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must not report success.');
            testCase.verifyEqual(string(model.dataFile), string(csvPath), ...
                'Window X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [model, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = lvdData.initStateModel.aero.dragCoeffModel.twoDimWindTunnelDragModel;
        end

        function app = openDialog(testCase, model, lvdData, out)
            if(nargin < 4 || isempty(out))
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_Edit2DKerbalWindTunnelDragPropertiesGUI_App(model, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TwoDKwtDragDialogTest.deleteIfValid(app));
        end

        function csvPath = writeKwtCsv(~)
            csvPath = [tempname(), '.csv'];
            writematrix([0, 0, 1000; 0, 1, 2; 1000, 1.5, 2.5], csvPath);
        end

        function csvPath = writeOtherKwtCsv(~)
            csvPath = [tempname(), '.csv'];
            writematrix([0, 0, 1000; 0, 9, 9; 1000, 9, 9], csvPath);
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Drag Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(~isempty(app) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Drag Properties')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
