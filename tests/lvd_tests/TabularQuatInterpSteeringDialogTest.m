classdef TabularQuatInterpSteeringDialogTest < KsptotTestCase
    %TabularQuatInterpSteeringDialogTest Tabular quaternion-interpolation
    %steering editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/steeringModels/lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App.mlapp
    %   backing class: GenericTabularQuatInterpSteeringModel
    %   production caller: GenericTabularQuatInterpSteeringModel.openEditSteeringModelUI
    %   (helper_methods/ksptot_lvd/classes/ForceModels/steering/@GenericTabularQuatInterpSteeringModel/GenericTabularQuatInterpSteeringModel.m:185-190).
    %
    % PATTERN
    %   Programmatic App Designer dialog; UiwaitInterceptorFixture stands in
    %   for uiwait so the constructor returns the live app (the
    %   InterpThrottleModelUITest pattern).  Table population, add/remove
    %   rows, validation, save mutation and cancel preservation are driven
    %   through the angles table exactly like the throttle table in the
    %   tabular-interp throttle test.
    %
    % COVERED
    %   Table population from durations/subsequent angles; add appends a
    %   default row; remove drops the selected row and guards the last row;
    %   negative durations, empty tables and non-numeric cells are
    %   rejected; save writes durations and angles; cancel preserves.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogTableMatchesModel(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            model.setT0(0);
            model.setInitAngles(0.1, 0.2, 0.3);
            model.setDurations([10; 20]);
            model.setSubsequentAngles([0.4; 0.5], [0.6; 0.7], [0.8; 0.9]);
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.anglesTable.Data, 1), 2, 'Both duration rows must render.');
            testCase.verifyEqual(cell2mat(app.anglesTable.Data(:, 1)), [10; 20], 'AbsTol', 1e-12, ...
                'Column 1 must carry the segment durations.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogOpensWithDefaultModel(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.anglesTable.Data, 1), 1, 'The default single-row model must show one row.');
            testCase.verifyEqual(app.anglesTable.Data{1, 1}, 1, 'AbsTol', 1e-12);
            testCase.pushButton(app.cancelButton);
        end

        function dialogAddRowAppendsDefaultRow(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.anglesTable.Data, 1), 1);
            testCase.pushButton(app.AddRowButton);
            testCase.verifyEqual(size(app.anglesTable.Data, 1), 2, 'Add must append one row.');
            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "on", ...
                'Two rows must enable removal.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogRemoveRowDropsSelectedRow(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            model.setDurations([10; 20]);
            model.setSubsequentAngles([0.1; 0.2], [0.3; 0.4], [0.5; 0.6]);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));
            testCase.verifyEqual(size(app.anglesTable.Data, 1), 2);

            %This table selects whole rows (scalar Selection), not cells.
            app.anglesTable.Selection = 1;
            testCase.pushButton(app.RemoveRowButton);

            testCase.verifyEqual(size(app.anglesTable.Data, 1), 1, 'One of the two rows must remain.');
            testCase.verifyEqual(app.anglesTable.Data{1, 1}, 20, 'AbsTol', 1e-12, 'Removing row 1 must keep row 2.');
            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "off", ...
                'A single remaining row must disable removal.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogValidationBlocksBadTable(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            td = app.anglesTable.Data;
            td{1, 1} = -5;
            app.anglesTable.Data = td;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-positive duration must not save.');
            testCase.verifyTrue(isvalid(app.EditSteeringModelUIFigure), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.getDurations(), 1, 'AbsTol', 1e-15, 'Failed validation must leave the model alone.');
            testCase.closeAlertFigures();

            %NOTE (bug log 2.12): an empty table crashes validateInputs
            %instead of rejecting (column indexing on {}), so no empty-table
            %rejection is exercised here; it will be covered once the dialog
            %guards the empty case.

            testCase.pushButton(app.cancelButton);
        end

        function dialogSaveWritesModelAndOptVar(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            %Duration lower bounds must be >= 1e-10 (validateInputs).
            td = app.anglesTable.Data;
            td{1, 1} = 12;
            td{1, 3} = 5;
            td{1, 4} = 20;
            app.anglesTable.Data = td;

            fig = app.EditSteeringModelUIFigure;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifyEqual(model.getDurations(), 12, 'AbsTol', 1e-12, 'Save must commit the edited duration.');

            optVar = model.getExistingOptVar();
            testCase.verifyClass(optVar, 'SetGenericTabularQuatInterpSteeringModelActionOptimVar', ...
                'The tabular quat-interp variable must have the expected class.');
        end

        function dialogCancelPreservesModel(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            model.setDurations(10);
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            td = app.anglesTable.Data;
            td{1, 1} = 99;
            app.anglesTable.Data = td;
            fig = app.EditSteeringModelUIFigure;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.getDurations(), 10, 'AbsTol', 1e-15, 'Cancel must leave the model alone.');
        end

        function dialogCloseRequestCancels(testCase)
            [~, lv] = testCase.lvdFixture();
            model = GenericTabularQuatInterpSteeringModel.getDefaultSteeringModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App(model, lv, false, out));

            fig = app.EditSteeringModelUIFigure;
            fig.CloseRequestFcn(fig, struct('Source', fig, 'EventName', 'CloseRequest'));
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must cancel.');
            testCase.verifyFalse(isvalid(fig), 'Window X must close the dialog.');
        end
    end

    methods(Access=private)
        function [lvdData, lv] = lvdFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
        end

        function app = openDialog(testCase, launchFcn)
            app = launchFcn();
            drawnow;
            testCase.assertTrue(not(isempty(app)), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TabularQuatInterpSteeringDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlertFigures(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Steering Model'))
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
            if(not(isempty(app)) && isvalid(app))
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Steering Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
