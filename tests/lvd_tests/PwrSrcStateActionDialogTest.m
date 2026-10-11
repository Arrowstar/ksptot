classdef PwrSrcStateActionDialogTest < KsptotTestCase
    %PwrSrcStateActionDialogTest Full round-trip UI tests for the power-source
    %state action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetPwrSrcStateGUI_App.mlapp
    %   backing class: SetPowerSrcActiveStateAction
    %   (opens via SetPowerSrcActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored source/state; Save & Close writes the selected
    %   source and state back; saving without changes round-trips; Cancel
    %   and window-X preserve the model; the source dropdown mirrors the
    %   vehicle's power sources.  The dialog performs no validation, so
    %   there is no rejection case.
    %
    % FIXTURE
    %   The default LvdData carries no power sources (openEditActionUI
    %   guards that case with a warndlg), so two RTGs are seeded onto stage
    %   1, mirroring EventActionTest.buildEntryWithPowerSrc.

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

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.verifyEqual(get(handles.refPwrCompCombo, 'Value'), find(srcs == action.src, 1), ...
                'The source dropdown must point at the stored source.');
            testCase.verifyEqual(get(handles.stateCombo, 'Value'), 2, ...
                'The fixture stores Inactive, which must be shown.');
            strs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(strs{get(handles.stateCombo, 'Value')}, 'Inactive');
        end

        function refComboOffersEverySrc(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refPwrCompCombo, 'String'))), numel(srcs), ...
                'Every vehicle power source must be offered.');
        end

        function saveAndCloseWritesRefAndState(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSrcStateGUI;

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            otherInd = mod(find(srcs == action.src, 1), numel(srcs)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.src == srcs(otherInd), 'Save must write the selected source.');
            testCase.verifyTrue(action.activeStateToSet, 'Save must write the selected state.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData] = testCase.fixture();
            srcBefore = action.src;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSrcStateGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.src == srcBefore, 'An unchanged save must keep the source.');
            testCase.verifyFalse(action.activeStateToSet, 'An unchanged save must keep the state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            srcBefore = action.src;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSrcStateGUI;

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            otherInd = mod(find(srcs == action.src, 1), numel(srcs)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.src == srcBefore, 'Cancel must leave the source alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            srcBefore = action.src;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSrcStateGUI;

            set(handles.stateCombo, 'Value', 1);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.src == srcBefore, 'Window-X must leave the source alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Window-X must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            src1 = LaunchVehicleEpsRtg(stg);
            stg.addPwrSrc(src1);
            src2 = LaunchVehicleEpsRtg(stg);
            stg.addPwrSrc(src2);

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.assertGreaterThanOrEqual(numel(srcs), 2, 'Fixture must seed two power sources.');
            action = SetPowerSrcActiveStateAction(src1, false);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetPwrSrcStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PwrSrcStateActionDialogTest.deleteIfValid(app));
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
