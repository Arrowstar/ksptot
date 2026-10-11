classdef EngineStateActionDialogTest < KsptotTestCase
    %EngineStateActionDialogTest Full round-trip UI tests for the
    %engine-state action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetEngineStateGUI_App.mlapp
    %   backing class: SetEngineActiveStateAction
    %   (opens via SetEngineActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditActionUI) with the launch vehicle from
    %   default LVD data; the engine under test is the first engine from
    %   lv.getEnginesListBoxStr().
    %
    % COVERED
    %   Open shows the stored engine and active state; Save & Close
    %   writes the reselected engine and toggled state back; Cancel
    %   preserves the model; the engine dropdown mirrors the vehicle's
    %   engines and the state dropdown offers exactly Active/Inactive.
    %   The dialog has no validateInputs, so no validation-rejection
    %   test applies.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lv, ~] = testCase.fixture();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.refEngineCombo.Value, 1);
            testCase.verifyEqual(handles.stateCombo.Value, 2);
        end

        function refEngineComboOffersEveryEngine(testCase)
            [action, lv, engines] = testCase.fixture();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.refEngineCombo.String)), numel(engines), ...
                'Every engine must be offered.');
        end

        function stateComboOffersActiveAndInactive(testCase)
            [action, lv, ~] = testCase.fixture();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(cellstr(get(handles.stateCombo, 'String')), {'Active'; 'Inactive'});
        end

        function saveAndCloseWritesEngineAndState(testCase)
            [action, lv, engines] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lv, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetEngineStateGUI;

            handles.refEngineCombo.Value = numel(engines);
            handles.stateCombo.Value = 1;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.engine == engines(end), ...
                'The selected engine must be written back.');
            testCase.verifyTrue(action.activeStateToSet, ...
                'The selected engine state must be written back.');
        end

        function cancelPreservesModel(testCase)
            [action, lv, engines] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lv, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetEngineStateGUI;

            handles.refEngineCombo.Value = numel(engines);
            handles.stateCombo.Value = 1;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.engine == engines(1), 'Cancel must leave the engine alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lv, engines] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            [~, engines] = lv.getEnginesListBoxStr();
            testCase.assertNotEmpty(engines, 'The default vehicle must ship at least one engine.');

            action = SetEngineActiveStateAction(engines(1), false);
        end

        function app = openDialog(testCase, action, lv, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetEngineStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EngineStateActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Action')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Action')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
