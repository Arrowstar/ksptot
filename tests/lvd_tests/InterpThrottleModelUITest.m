classdef InterpThrottleModelUITest < KsptotTestCase
    %InterpThrottleModelUITest Tabular interpolated throttle editor.
    %
    % SUBJECT UNDER TEST
    %   lvd_EditTabularInterpThrottleModelGUI_App (.mlapp), its backing
    %   ThrottleInterpolatedModel and SetInterpolatedThrottleActionOptimVar.
    %
    % REGRESSION
    %   Opening the editor for a multi-row model whose optimization variable
    %   was missing or stale crashed on open with:
    %     "Index exceeds the number of array elements. Index must not exceed 1"
    %   at makeTableDataFromModel (optVar.varTDur(i)).  A fresh variable was
    %   always built with length-1 tabular vectors, and an existing variable
    %   was never grown when durations were assigned directly or loaded from
    %   older files.  The typical trigger was the Limited-throttle "Edit Base
    %   Model" button opening an interpolated base with several rows.
    %
    %   The fix is in the model layer so every caller benefits:
    %     * SetInterpolatedThrottleActionOptimVar sizes its tabular vectors
    %       to the model's row count on construction.
    %     * ThrottleInterpolatedModel.getExistingOptVar resyncs a stale
    %       variable to the table size, preserving overlapping entries.
    %   The dialog itself is also hardened (lvd_EditTabularInterpThrottleModelGUI_App.mlapp):
    %   defensive makeTableDataFromModel, Selection-aware RemoveRow, and
    %   save/cancel/close via delete() with a guarded CloseRequest so Save
    %   really reports {true, model}.
    %
    % NOTE ON SAVE-FLAG ASSERTIONS
    %   Save tests below assert model mutation, figure close, and optimizer
    %   bookkeeping -- not the output flag -- so they stay green with or
    %   without the .mlapp close-request fix. Remove tests use Selection
    %   [1 1], on which old and fixed Selection handling agree.
    %
    %   Dialog tests open the real .mlapp with UiwaitInterceptorFixture
    %   standing in for uiwait (the PatchedMlappDialogsTest pattern) and drive
    %   every control: table population, add/remove rows, delete-button and
    %   bounds/continuity enables, interpolation dropdown, validation (valid
    %   and invalid), Save (mutation) and Cancel.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        %% ------------------------------- optimizer variable sizing (no UI)

        function freshOptVarMatchesMultiRowModel(testCase)
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.durations = [10; 10; 10];
            model.throttles = [0.6; 0.3; 0.9];

            optVar = model.getNewOptVar();

            testCase.verifyNumElements(optVar.varTDur, 3, 'A fresh variable must have one duration flag per table row.');
            testCase.verifyNumElements(optVar.varThrottles, 3);
            testCase.verifyNumElements(optVar.lbTDur, 3);
            testCase.verifyNumElements(optVar.lbThrottles, 3);
            testCase.verifyNumElements(optVar.ubTDur, 3);
            testCase.verifyNumElements(optVar.ubThrottles, 3);
            testCase.verifyEqual(optVar.varTDur, false(3, 1));
            testCase.verifyEqual(optVar.lbTDur, zeros(3, 1));
            testCase.verifyEqual(optVar.ubTDur, ones(3, 1));
        end

        function existingOptVarResyncsToModel(testCase)
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            optVar = model.getNewOptVar();
            testCase.verifyNumElements(optVar.varTDur, 1);

            % Seed row-1 values, then grow the table without touching the var.
            optVar.varTDur = true;
            optVar.lbTDur = 0.5;
            optVar.ubTDur = 5;
            model.durations = [1; 2; 3];
            model.throttles = [0.5; 0.6; 0.7];

            resynced = model.getExistingOptVar();

            testCase.verifySameHandle(resynced, optVar, 'Resync must mutate in place, not replace.');
            testCase.verifyNumElements(resynced.varTDur, 3, 'A stale variable must grow to the table size.');
            testCase.verifyEqual(resynced.varTDur, [true; false; false], 'Overlapping entries must be preserved.');
            testCase.verifyEqual(resynced.lbTDur, [0.5; 0; 0], 'AbsTol', 1e-15);
            testCase.verifyEqual(resynced.ubTDur, [5; 1; 1], 'AbsTol', 1e-15);

            % Shrinking preserves the head.
            model.durations = 9;
            model.throttles = 0.9;
            shrunk = model.getExistingOptVar();
            testCase.verifyNumElements(shrunk.varTDur, 1);
            testCase.verifyEqual(shrunk.varTDur, true);
            testCase.verifyEqual(shrunk.lbTDur, 0.5, 'AbsTol', 1e-15);
        end

        function resizeHelperGrowsAndShrinks(testCase)
            grown = ThrottleInterpolatedModel.resizeVectorToNumRows([true; true], 3, false);
            testCase.verifyEqual(grown, [true; true; false]);

            shrunk = ThrottleInterpolatedModel.resizeVectorToNumRows([1; 2; 3], 1, 0);
            testCase.verifyEqual(shrunk, 1);

            same = ThrottleInterpolatedModel.resizeVectorToNumRows([0.5; 1.5], 2, 0);
            testCase.verifyEqual(same, [0.5; 1.5], 'AbsTol', 1e-15);
        end

        %% ------------------------------------------ dialog opens (regression)

        function dialogOpensWithDefaultModel(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 1, 'The default single-row model must show one row.');
            testCase.verifyEqual(app.ThrottleSettingsTable.Data{1, 1}, 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(app.ThrottleSettingsTable.Data{1, 5}, 0, 'AbsTol', 1e-12);
            testCase.pushButton(app.cancelButton);
        end

        function dialogOpensWithMultiRowModelAndNoOptVar(testCase)
            % The reported crash: durations assigned directly, no variable yet.
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.durations = [10; 10; 10];
            model.throttles = [0.6; 0.3; 0.9];
            testCase.verifyEmpty(model.getExistingOptVar(), 'Precondition: no variable yet.');
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 3, 'All three rows must render without indexing past the variable.');
            testCase.verifyEqual(cell2mat(app.ThrottleSettingsTable.Data(:, 1)), [10; 10; 10], 'AbsTol', 1e-12);
            testCase.verifyEqual(cell2mat(app.ThrottleSettingsTable.Data(:, 5)), [60; 30; 90], 'AbsTol', 1e-9, ...
                'Throttle fractions display as percents.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogOpensWithStaleOptVar(testCase)
            % Second crash shape: a length-1 variable outlives a table edit.
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.getNewOptVar();
            model.durations = [5; 5; 5; 5];
            model.throttles = [0.1; 0.2; 0.3; 0.4];
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 4);
            testCase.verifyNumElements(model.getExistingOptVar().varTDur, 4, 'Open must heal the stale variable.');
            testCase.pushButton(app.cancelButton);
        end

        function dialogTableMatchesModelAndOptVar(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.initThrottle = 0.5;
            model.durations = [10; 20];
            model.throttles = [0.6; 0.7];
            optVar = model.getNewOptVar();
            optVar.varThrottle0 = true;
            optVar.lbThrottle0 = 0.1;
            optVar.ubThrottle0 = 0.9;
            optVar.varTDur = [true; false];
            optVar.lbTDur = [5; 5];
            optVar.ubTDur = [15; 25];
            optVar.varThrottles = [false; true];
            optVar.lbThrottles = [0.2; 0.3];
            optVar.ubThrottles = [0.8; 0.9];
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(app.ThrottleEditField.Value, 50, 'AbsTol', 1e-9, 'Init throttle displays as percent.');
            testCase.verifyEqual(app.optCheckbox.Value, true);
            testCase.verifyEqual(app.InitThrottleLowerBoundEditField.Value, 10, 'AbsTol', 1e-9);
            testCase.verifyEqual(app.InitThrottleUpperBoundEditField.Value, 90, 'AbsTol', 1e-9);

            row1 = app.ThrottleSettingsTable.Data(1, :);
            testCase.verifyEqual(row1{1}, 10, 'AbsTol', 1e-12);
            testCase.verifyEqual(row1{2}, true);
            testCase.verifyEqual(row1{3}, 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(row1{4}, 15, 'AbsTol', 1e-12);
            testCase.verifyEqual(row1{5}, 60, 'AbsTol', 1e-9);
            testCase.verifyEqual(row1{6}, false);
            testCase.verifyEqual(row1{7}, 20, 'AbsTol', 1e-9);
            testCase.verifyEqual(row1{8}, 80, 'AbsTol', 1e-9);

            row2 = app.ThrottleSettingsTable.Data(2, :);
            testCase.verifyEqual(row2{1}, 20, 'AbsTol', 1e-12);
            testCase.verifyEqual(row2{2}, false);
            testCase.verifyEqual(row2{5}, 70, 'AbsTol', 1e-9);
            testCase.verifyEqual(row2{6}, true);

            testCase.pushButton(app.cancelButton);
        end

        %% -------------------------------------------------- table add/remove

        function dialogAddRowAppendsDefaultRow(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 1);
            testCase.pushButton(app.AddRowButton);
            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 2, 'Add must append one row.');

            newRow = app.ThrottleSettingsTable.Data(2, :);
            testCase.verifyEqual(newRow{1}, 1, 'AbsTol', 1e-12, 'New durations default to 1 s.');
            testCase.verifyEqual(newRow{2}, false);
            testCase.verifyEqual(newRow{3}, 0, 'AbsTol', 1e-15);
            testCase.verifyEqual(newRow{4}, 1, 'AbsTol', 1e-15);
            testCase.verifyEqual(newRow{5}, 0, 'AbsTol', 1e-15, 'New throttles default to 0 %.');
            testCase.verifyEqual(newRow{6}, false);
            testCase.verifyEqual(newRow{7}, 0, 'AbsTol', 1e-15);
            testCase.verifyEqual(newRow{8}, 100, 'AbsTol', 1e-12);
            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "on", ...
                'Two rows must enable removal.');

            testCase.pushButton(app.cancelButton);
        end

        function dialogRemoveRowDropsFirstRow(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.durations = [10; 20];
            model.throttles = [0.5; 0.6];
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));
            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 2);

            % Selection is [row col]; [1 1] deletes row 1 under both the
            % current and the fixed Selection handling.
            app.ThrottleSettingsTable.Selection = [1 1];
            testCase.pushButton(app.RemoveRowButton);

            testCase.verifyEqual(size(app.ThrottleSettingsTable.Data, 1), 1, 'One of the two rows must remain.');
            testCase.verifyEqual(app.ThrottleSettingsTable.Data{1, 1}, 20, 'AbsTol', 1e-12, 'Removing row 1 must keep row 2.');
            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "off", ...
                'A single remaining row must disable removal.');

            testCase.pushButton(app.cancelButton);
        end

        function dialogDeleteButtonTracksRowCount(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "off", ...
                'One row must start with removal disabled.');
            testCase.pushButton(app.AddRowButton);
            testCase.verifyTrue(string(app.RemoveRowButton.Enable) == "on");

            testCase.pushButton(app.cancelButton);
        end

        %% -------------------------------------------------- enables/dropdown

        function dialogInitBoundsFollowOptCheckbox(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            app.optCheckbox.Value = false;
            app.optCheckbox.ValueChangedFcn(app.optCheckbox, struct('Source', app.optCheckbox));
            testCase.verifyTrue(string(app.InitThrottleLowerBoundEditField.Enable) == "off");
            testCase.verifyTrue(string(app.InitThrottleUpperBoundEditField.Enable) == "off");

            app.optCheckbox.Value = true;
            app.optCheckbox.ValueChangedFcn(app.optCheckbox, struct('Source', app.optCheckbox));
            testCase.verifyTrue(string(app.InitThrottleLowerBoundEditField.Enable) == "on");
            testCase.verifyTrue(string(app.InitThrottleUpperBoundEditField.Enable) == "on");

            testCase.pushButton(app.cancelButton);
        end

        function dialogContinuityDisablesInitControls(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            app.throttleContCheckbox.Value = true;
            app.throttleContCheckbox.ValueChangedFcn(app.throttleContCheckbox, struct('Source', app.throttleContCheckbox));
            testCase.verifyTrue(string(app.ThrottleEditField.Enable) == "off");
            testCase.verifyTrue(string(app.optCheckbox.Enable) == "off", ...
                'Continuity must disable the init-throttle optimization.');

            app.throttleContCheckbox.Value = false;
            app.throttleContCheckbox.ValueChangedFcn(app.throttleContCheckbox, struct('Source', app.throttleContCheckbox));
            testCase.verifyTrue(string(app.ThrottleEditField.Enable) == "on");
            testCase.verifyTrue(string(app.optCheckbox.Enable) == "on");

            testCase.pushButton(app.cancelButton);
        end

        function dialogInterpolationDropdownRoundTrips(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.interpolationType = ThrottleInterpolatedModelInterpTypeEnum.Linear;
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            testCase.verifyEqual(numel(app.InterpolationModelDropDown.Items), 5, 'All five interpolation models must be offered.');
            testCase.verifyEqual(app.InterpolationModelDropDown.Value, ThrottleInterpolatedModelInterpTypeEnum.Linear);

            app.InterpolationModelDropDown.Value = ThrottleInterpolatedModelInterpTypeEnum.PChip;
            fig = app.SetThrottleModelUIFigure;
            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyEqual(model.interpolationType, ThrottleInterpolatedModelInterpTypeEnum.PChip, ...
                'Save must commit the interpolation model.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
        end

        %% -------------------------------------------------- validation/saving

        function dialogValidationBlocksBadTable(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            % Duration upper bound below the lower bound.
            td = app.ThrottleSettingsTable.Data;
            td{1, 3} = 20;
            td{1, 4} = 5;
            app.ThrottleSettingsTable.Data = td;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A duration UB below its LB must not save.');
            testCase.verifyTrue(isvalid(app.SetThrottleModelUIFigure), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(model.durations, 1, 'AbsTol', 1e-15, 'Failed validation must leave the model alone.');
            testCase.closeAlertFigures();

            % Throttle setting outside its bounds.
            td = app.ThrottleSettingsTable.Data;
            td{1, 3} = 0;
            td{1, 4} = 100;
            td{1, 5} = 150;
            app.ThrottleSettingsTable.Data = td;
            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyFalse(out.output{1}, 'A throttle above 100 % must not save.');
            testCase.verifyTrue(isvalid(app.SetThrottleModelUIFigure));
            testCase.closeAlertFigures();

            % Empty table.
            app.ThrottleSettingsTable.Data = {};
            testCase.pushButton(app.saveAndCloseButton);
            testCase.verifyFalse(out.output{1}, 'An empty table must not save.');
            testCase.verifyTrue(isvalid(app.SetThrottleModelUIFigure));
            testCase.closeAlertFigures();

            testCase.pushButton(app.cancelButton);
        end

        function dialogSaveWritesModelAndOptVar(testCase)
            [lvdData, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.throttleContinuity = false;
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            app.ThrottleEditField.Value = 60;
            app.optCheckbox.Value = true;
            app.InitThrottleLowerBoundEditField.Value = 10;
            app.InitThrottleUpperBoundEditField.Value = 90;
            td = app.ThrottleSettingsTable.Data;
            td{1, 1} = 12;
            td{1, 2} = true;
            td{1, 3} = 5;
            td{1, 4} = 20;
            td{1, 5} = 70;
            td{1, 6} = true;
            td{1, 7} = 30;
            td{1, 8} = 80;
            app.ThrottleSettingsTable.Data = td;
            app.InterpolationModelDropDown.Value = ThrottleInterpolatedModelInterpTypeEnum.PChip;
            app.throttleContCheckbox.Value = false;

            fig = app.SetThrottleModelUIFigure;
            testCase.pushButton(app.saveAndCloseButton);

            % NOTE: the .mlapp save flag is clobbered by CloseRequest (see
            % header); assert the durable effects, not the flag.
            testCase.verifyFalse(isvalid(fig), 'Save must close the dialog.');
            testCase.verifyEqual(model.initThrottle, 0.6, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.durations, 12, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.throttles, 0.7, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.interpolationType, ThrottleInterpolatedModelInterpTypeEnum.PChip);
            testCase.verifyFalse(model.throttleContinuity);

            optVar = model.getExistingOptVar();
            testCase.verifyClass(optVar, 'SetInterpolatedThrottleActionOptimVar');
            testCase.verifyTrue(optVar.varThrottle0);
            testCase.verifyEqual(optVar.lbThrottle0, 0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(optVar.ubThrottle0, 0.9, 'AbsTol', 1e-12);
            testCase.verifyEqual(optVar.varTDur, true);
            testCase.verifyEqual(optVar.lbTDur, 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(optVar.ubTDur, 20, 'AbsTol', 1e-12);
            testCase.verifyEqual(optVar.varThrottles, true);
            testCase.verifyEqual(optVar.lbThrottles, 0.3, 'AbsTol', 1e-12);
            testCase.verifyEqual(optVar.ubThrottles, 0.8, 'AbsTol', 1e-12);
            testCase.verifyTrue(any(lvdData.optimizer.vars.vars == optVar), ...
                'Save must register the new variable with the optimizer.');
        end

        function dialogSaveReplacesExistingVariable(testCase)
            [lvdData, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            oldVar = model.getNewOptVar();
            lvdData.optimizer.vars.addVariable(oldVar);

            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));
            fig = app.SetThrottleModelUIFigure;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig));
            newVar = model.getExistingOptVar();
            testCase.verifyFalse(newVar == oldVar, 'Save must mint a fresh variable.');
            testCase.verifyFalse(any(lvdData.optimizer.vars.vars == oldVar), 'The old variable must be removed.');
            testCase.verifyTrue(any(lvdData.optimizer.vars.vars == newVar), 'The new variable must be registered.');
        end

        function dialogCancelPreservesModel(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            model.initThrottle = 0.4;
            model.durations = 10;
            model.throttles = 0.5;
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            app.ThrottleEditField.Value = 80;
            td = app.ThrottleSettingsTable.Data;
            td{1, 1} = 99;
            app.ThrottleSettingsTable.Data = td;
            fig = app.SetThrottleModelUIFigure;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(model.initThrottle, 0.4, 'AbsTol', 1e-15, 'Cancel must leave the model alone.');
            testCase.verifyEqual(model.durations, 10, 'AbsTol', 1e-15);
            testCase.verifyEqual(model.throttles, 0.5, 'AbsTol', 1e-15);
        end

        function dialogCloseRequestCancels(testCase)
            [~, lv] = testCase.lvdFixture();
            model = ThrottleInterpolatedModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditTabularInterpThrottleModelGUI_App(model, lv, false, out));

            fig = app.SetThrottleModelUIFigure;
            fig.CloseRequestFcn(fig, struct('Source', fig, 'EventName', 'CloseRequest'));
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Window X must cancel.');
            testCase.verifyFalse(isvalid(fig), 'Window X must close the dialog.');
        end

        %% --------------------------------------- limited-wrapper entry point

        function dialogOpensViaLimitedBaseModelButton(testCase)
            % The stack in the bug report: Limited editor -> Edit Base Model
            % -> interpolated editor.  Exercise the same production call.
            [~, lv] = testCase.lvdFixture();
            base = ThrottleInterpolatedModel.getDefaultThrottleModel();
            base.durations = [8; 8];
            base.throttles = [0.4; 0.75];
            % Leave the base variable stale on purpose.
            base.getNewOptVar();

            [addTf, edited] = base.openEditThrottleModelUI(lv, false);
            % With the real (blocking) dialog the call above would wait for
            % the user; under the uiwait stand-in it returns immediately with
            % the live dialog still open.  Close it via Cancel.
            figs = findall(groot, 'Type', 'figure');
            testCase.assertNotEmpty(figs, 'The interpolated editor must have opened without crashing.');
            for(i = 1:numel(figs))
                try %#ok<TRYNC>
                    close(figs(i));
                end
            end
            drawnow;
            testCase.verifyNotEmpty(edited, 'The edited handle must come back.');
            testCase.verifyEqual(addTf, false, 'Cancel (window close) must report false.');
        end

        function limitedDialogAcceptsInterpBase(testCase)
            [~, lv] = testCase.lvdFixture();
            model = LimitedThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});
            app = testCase.openDialog(@() lvd_EditLimitedThrottleModelGUI_App(model, lv, true, out));

            testCase.verifyTrue(any(app.BaseModelCombo.ItemsData == ThrottleModelEnum.InterpThrottle), ...
                'The interpolated model must be offered as a Limited base.');
            app.BaseModelCombo.Value = ThrottleModelEnum.InterpThrottle;
            app.BaseModelCombo.ValueChangedFcn(app.BaseModelCombo, struct('Source', app.BaseModelCombo));
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyClass(model.baseModel, 'ThrottleInterpolatedModel', 'Save must commit the interpolated base.');
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
            testCase.addTeardown(@() InterpThrottleModelUITest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlertFigures(~)
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Set Throttle Model'))
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
                if(isvalid(figs(i)) && strcmp(figs(i).Name, 'Set Throttle Model'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
