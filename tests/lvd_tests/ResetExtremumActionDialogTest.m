classdef ResetExtremumActionDialogTest < KsptotTestCase
    %ResetExtremumActionDialogTest Full round-trip UI tests for the
    %reset-extremum-value action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionResetExtremumValueGUI_App.mlapp
    %   backing class: ResetExtremumValueAction
    %   (opens via ResetExtremumValueAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog is opened
    %   directly (not via openEditActionUI); the fixture seeds two
    %   extrema (default LVD data ships none) so reselection is
    %   exercisable.  Unlike its sibling
    %   SetExtremumRecordingStateAction.openEditActionUI, production
    %   offers no empty-extrema guard here, so the dialog simply assumes
    %   extrema exist (see the bug list in the final report).
    %
    % COVERED
    %   Open shows the stored extremum; Save & Close writes the
    %   reselected extremum back; Cancel preserves the model; the
    %   extremum dropdown mirrors the vehicle's extrema; an action with
    %   no extremum yet defaults to the first extremum.  The dialog has
    %   no validateInputs, so no validation-rejection test applies.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredExtremum(testCase)
            [action, lv] = testCase.fixture();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.refExtremumCombo.Value, 1);
        end

        function refExtremumComboOffersEveryExtremum(testCase)
            [action, lv] = testCase.fixture();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, extrema] = lv.getExtremaListBoxStr();
            testCase.verifyEqual(numel(extrema), 2);
            testCase.verifyEqual(numel(cellstr(handles.refExtremumCombo.String)), numel(extrema), ...
                'Every extremum must be offered.');
        end

        function saveAndCloseWritesExtremum(testCase)
            [action, lv] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lv, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionResetExtremumValueGUI;

            [~, extrema] = lv.getExtremaListBoxStr();
            handles.refExtremumCombo.Value = 2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.extremum == extrema(2), ...
                'The selected extremum must be written back.');
        end

        function cancelPreservesModel(testCase)
            [action, lv] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lv, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionResetExtremumValueGUI;

            [~, extrema] = lv.getExtremaListBoxStr();
            handles.refExtremumCombo.Value = 2;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.extremum == extrema(1), 'Cancel must leave the model alone.');
        end

        function emptyActionDefaultsToFirstExtremum(testCase)
            [~, lv] = testCase.fixture();
            action = ResetExtremumValueAction();
            app = testCase.openDialog(action, lv);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.refExtremumCombo.Value, 1, ...
                'With no stored extremum the dialog must point at the first one.');
        end
    end

    methods(Access=private)
        function [action, lv] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            frame = testCase.kerbin.getBodyCenteredInertialFrame();

            ex1 = LaunchVehicleExtrema(lvdData);
            ex1.frame = frame;
            ex1.quantStr = 'Altitude';
            lv.addExtremum(ex1);

            ex2 = LaunchVehicleExtrema(lvdData);
            ex2.frame = frame;
            ex2.quantStr = 'Apoapsis';
            lv.addExtremum(ex2);

            action = ResetExtremumValueAction(ex1);
        end

        function app = openDialog(testCase, action, lv, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionResetExtremumValueGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ResetExtremumActionDialogTest.deleteIfValid(app));
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
