classdef PwrSinkStateActionDialogTest < KsptotTestCase
    %PwrSinkStateActionDialogTest Full round-trip UI tests for the power-sink
    %state action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetPwrSinkStateGUI_App.mlapp
    %   backing class: SetPowerSinkActiveStateAction
    %   (opens via SetPowerSinkActiveStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored sink/state; Save & Close writes the selected sink
    %   and state back; saving without changes round-trips; Cancel and
    %   window-X preserve the model; the sink dropdown mirrors the
    %   vehicle's power sinks.  The dialog performs no validation, so there
    %   is no rejection case.
    %
    % FIXTURE
    %   The default LvdData carries no power sinks (openEditActionUI guards
    %   that case with a warndlg), so two simple sinks are seeded onto
    %   stage 1, mirroring EventActionTest.buildEntryWithPowerSink.

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

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.verifyEqual(get(handles.refPwrCompCombo, 'Value'), find(sinks == action.sink, 1), ...
                'The sink dropdown must point at the stored sink.');
            testCase.verifyEqual(get(handles.stateCombo, 'Value'), 2, ...
                'The fixture stores Inactive, which must be shown.');
            strs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(strs{get(handles.stateCombo, 'Value')}, 'Inactive');
        end

        function refComboOffersEverySink(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refPwrCompCombo, 'String'))), numel(sinks), ...
                'Every vehicle power sink must be offered.');
        end

        function saveAndCloseWritesRefAndState(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSinkStateGUI;

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            otherInd = mod(find(sinks == action.sink, 1), numel(sinks)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.sink == sinks(otherInd), 'Save must write the selected sink.');
            testCase.verifyTrue(action.activeStateToSet, 'Save must write the selected state.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData] = testCase.fixture();
            sinkBefore = action.sink;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSinkStateGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.sink == sinkBefore, 'An unchanged save must keep the sink.');
            testCase.verifyFalse(action.activeStateToSet, 'An unchanged save must keep the state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            sinkBefore = action.sink;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSinkStateGUI;

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            otherInd = mod(find(sinks == action.sink, 1), numel(sinks)) + 1;
            set(handles.refPwrCompCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.sink == sinkBefore, 'Cancel must leave the sink alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            sinkBefore = action.sink;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetPwrSinkStateGUI;

            set(handles.stateCombo, 'Value', 1);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.sink == sinkBefore, 'Window-X must leave the sink alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Window-X must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            sink1 = LaunchVehicleSimplePwrSink(stg);
            stg.addPwrSink(sink1);
            sink2 = LaunchVehicleSimplePwrSink(stg);
            stg.addPwrSink(sink2);

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.assertGreaterThanOrEqual(numel(sinks), 2, 'Fixture must seed two power sinks.');
            action = SetPowerSinkActiveStateAction(sink1, false);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetPwrSinkStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PwrSinkStateActionDialogTest.deleteIfValid(app));
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
