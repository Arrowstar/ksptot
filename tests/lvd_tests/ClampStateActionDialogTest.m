classdef ClampStateActionDialogTest < KsptotTestCase
    %ClampStateActionDialogTest Full round-trip UI tests for the
    %hold-down-clamp state action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetClampStateGUI_App.mlapp
    %   backing class: SetHoldDownClampActiveStateAction
    %   (opens via SetHoldDownClampActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditActionUI); it takes only (action,
    %   output), so no vehicle fixture beyond default LVD data is needed.
    %
    % COVERED
    %   Open shows the stored clamp state in both positions; Save &
    %   Close writes the toggled state back; Cancel preserves the model;
    %   the state dropdown offers exactly Active/Inactive.  The dialog
    %   has no validateInputs, so no validation-rejection test applies.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredActiveState(testCase)
            action = testCase.fixture(true);
            app = testCase.openDialog(action);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.stateCombo.Value, 1);
        end

        function dialogShowsStoredInactiveState(testCase)
            action = testCase.fixture(false);
            app = testCase.openDialog(action);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.stateCombo.Value, 2);
        end

        function stateComboOffersActiveAndInactive(testCase)
            action = testCase.fixture(true);
            app = testCase.openDialog(action);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(cellstr(get(handles.stateCombo, 'String')), {'Active'; 'Inactive'});
        end

        function saveAndCloseWritesToggledState(testCase)
            action = testCase.fixture(true);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetClampStateGUI;

            handles.stateCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyFalse(action.activeStateToSet, ...
                'The selected clamp state must be written back.');
        end

        function cancelPreservesModel(testCase)
            action = testCase.fixture(false);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetClampStateGUI;

            handles.stateCombo.Value = 1;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function action = fixture(~, activeState)
            action = SetHoldDownClampActiveStateAction(activeState);
        end

        function app = openDialog(testCase, action, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetClampStateGUI_App(action, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ClampStateActionDialogTest.deleteIfValid(app));
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
