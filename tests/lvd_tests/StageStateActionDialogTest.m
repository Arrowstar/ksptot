classdef StageStateActionDialogTest < KsptotTestCase
    %StageStateActionDialogTest Full round-trip UI tests for the stage-state
    %action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetStageStateGUI_App.mlapp
    %   backing class: SetStageActiveStateAction
    %   (opens via SetStageActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored stage/state; Save & Close writes the selected
    %   state back (and keeps the stage on an unchanged save); Cancel and
    %   window-X preserve the model; the stage dropdown mirrors the
    %   vehicle's stages.  The dialog performs no validation, so there is
    %   no rejection case.  The default single-stage vehicle is used as-is:
    %   no seeding is required.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(get(handles.refStageCombo, 'Value'), find(stages == action.stage, 1), ...
                'The stage dropdown must point at the stored stage.');
            testCase.verifyEqual(get(handles.stateCombo, 'Value'), 2, ...
                'The fixture stores Inactive, which must be shown.');
            strs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(strs{get(handles.stateCombo, 'Value')}, 'Inactive');
        end

        function refComboOffersEveryStage(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refStageCombo, 'String'))), numel(stages), ...
                'Every vehicle stage must be offered.');
        end

        function saveAndCloseWritesState(testCase)
            [action, lvdData] = testCase.fixture();
            stageBefore = action.stage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStageStateGUI;

            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.stage == stageBefore, 'Save must keep the selected stage.');
            testCase.verifyTrue(action.activeStateToSet, 'Save must write the selected state.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData] = testCase.fixture();
            stageBefore = action.stage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStageStateGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.stage == stageBefore, 'An unchanged save must keep the stage.');
            testCase.verifyFalse(action.activeStateToSet, 'An unchanged save must keep the state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            stageBefore = action.stage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStageStateGUI;

            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.stage == stageBefore, 'Cancel must leave the stage alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            stageBefore = action.stage;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStageStateGUI;

            set(handles.stateCombo, 'Value', 1);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.stage == stageBefore, 'Window-X must leave the stage alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Window-X must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stage = lvdData.launchVehicle.stages(1);
            action = SetStageActiveStateAction(stage, false);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetStageStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StageStateActionDialogTest.deleteIfValid(app));
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
