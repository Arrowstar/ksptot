classdef StageDialogTest < KsptotTestCase
    %StageDialogTest Full round-trip UI tests for the single-stage editor
    %(Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditStageGUI_App.mlapp
    %   ('Edit Stage'; two-arg ctor (stage, output).  Backing class:
    %   LaunchVehicleStage, plus its StageDryMassOptimizationVariable when
    %   the dry mass is optimized.)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored name/dry mass/optimization bounds; Save &
    %   Close writes every field including the dry-mass optimization
    %   variable; a blank or negative dry mass and an upper bound below the
    %   lower bound are rejected and leave the model alone; Cancel and
    %   window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [stage, ~] = testCase.fixture();
            stage.name = 'Booster';
            stage.dryMass = 2.5;

            app = testCase.openDialog(stage);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(get(handles.stageNameText, 'String'), 'Booster');
            testCase.verifyEqual(str2double(get(handles.dryMassText, 'String')), 2.5, 'AbsTol', 1e-9);
            testCase.verifyFalse(logical(handles.optCheckbox.Value), ...
                'The stock stage optimizes nothing.');
            testCase.verifyEqual(str2double(get(handles.lbText, 'String')), 0);
            testCase.verifyEqual(str2double(get(handles.ubText, 'String')), 0);
        end

        function saveAndCloseWritesEveryField(testCase)
            [stage, lvdData] = testCase.fixture(); %#ok<ASGLU>
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStageGUI;

            set(handles.stageNameText, 'String', 'Upper Stage');
            set(handles.dryMassText, 'String', '3.25');
            set(handles.optCheckbox, 'Value', 1);
            set(handles.lbText, 'String', '2');
            set(handles.ubText, 'String', '5');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(stage.name, 'Upper Stage');
            testCase.verifyEqual(stage.dryMass, 3.25, 'AbsTol', 1e-12);
            optVar = stage.getExistingOptVar();
            testCase.verifyTrue(optVar.getUseTfForVariable(), 'Save must enable the dry-mass variable.');
            [lb, ub] = optVar.getAllBndsForVariable();
            testCase.verifyEqual([lb, ub], [2, 5], 'Save must write the dry-mass bounds.');
        end

        function blankDryMassIsRejected(testCase)
            [stage, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.dryMassText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank dry mass must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditStageGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(stage.dryMass, 2, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeDryMassIsRejected(testCase)
            [stage, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.dryMassText, 'String', '-1');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative dry mass must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditStageGUI));
            testCase.verifyEqual(stage.dryMass, 2, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function upperBoundBelowLowerIsRejected(testCase)
            [stage, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.lbText, 'String', '5');
            set(handles.ubText, 'String', '2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'An upper bound below the lower bound must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditStageGUI));
            testCase.verifyEqual(stage.dryMass, 2, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [stage, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStageGUI;

            set(handles.stageNameText, 'String', 'Scratch Stage');
            set(handles.dryMassText, 'String', '9');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(stage.name, 'First Stage', 'Cancel must leave the model alone.');
            testCase.verifyEqual(stage.dryMass, 2);
        end

        function windowXPreservesModel(testCase)
            [stage, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(stage, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditStageGUI;

            set(handles.dryMassText, 'String', '9');
            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(stage.dryMass, 2);
        end
    end

    methods(Access=private)
        function [stage, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stage = lvdData.launchVehicle.stages(1);
        end

        function app = openDialog(testCase, stage, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditStageGUI_App(stage, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StageDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Stage')
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
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Stage')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
