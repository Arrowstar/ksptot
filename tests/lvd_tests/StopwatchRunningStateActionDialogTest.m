classdef StopwatchRunningStateActionDialogTest < KsptotTestCase
    %StopwatchRunningStateActionDialogTest Full round-trip UI tests for the
    %stopwatch-running-state action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetStopwatchRunningStateGUI_App.mlapp
    %   backing class: SetStopwatchRunningStateAction
    %   (opens via SetStopwatchRunningStateAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored stopwatch; Save & Close writes the selected
    %   stopwatch and running state back; Cancel and window-X preserve the
    %   model; the stopwatch dropdown mirrors the vehicle's stopwatches.
    %   The dialog performs no validation, so there is no rejection case.
    %
    % FIXTURE
    %   The default LvdData carries no stopwatches, so two are seeded,
    %   mirroring EventActionTest.buildEntryWithStopwatch.
    %
    % KNOWN PRODUCTION BUG (pinned, not fixed here)
    %   populateGUI seeds the state dropdown from
    %   action.stopwatch.startOn (the stopwatch's initial setting) instead
    %   of action.runningStateToSet (the value being edited), so the shown
    %   state is wrong whenever the two differ.  The mismatched-start-on
    %   test below documents the behaviour; retire it if the dialog is
    %   fixed.  The save path reads the dropdown correctly, so the
    %   saveAndClose test is unaffected.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredStopwatch(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyEqual(get(handles.refStopwatchCombo, 'Value'), find(sws == action.stopwatch, 1), ...
                'The stopwatch dropdown must point at the stored stopwatch.');
        end

        function mismatchedStartOnShowsStartOnNotStoredState(testCase)
            %The fixture stopwatch starts NotRunning but the action stores
            %Running.  The dialog shows the stopwatch's startOn value
            %instead of the action's stored runningStateToSet.
            [action, lvdData] = testCase.fixture();
            testCase.assertEqual(action.runningStateToSet, StopwatchRunningEnum.Running);
            testCase.assertEqual(action.stopwatch.startOn, StopwatchRunningEnum.NotRunning);

            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [strs, ~] = StopwatchRunningEnum.getNameStrs();
            shownInd = get(handles.stateCombo, 'Value');
            testCase.verifyEqual(shownInd, StopwatchRunningEnum.getIndOfListboxStrs(action.stopwatch.startOn), ...
                'BUG PIN: the dialog shows startOn, not the stored runningStateToSet.');
            shownStrs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(shownStrs(:), strs(:), ...
                'Both running states must still be offered.');
        end

        function refComboOffersEveryStopwatch(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refStopwatchCombo, 'String'))), numel(sws), ...
                'Every vehicle stopwatch must be offered.');
        end

        function saveAndCloseWritesRefAndState(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStopwatchRunningStateGUI;

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            otherInd = mod(find(sws == action.stopwatch, 1), numel(sws)) + 1;
            set(handles.refStopwatchCombo, 'Value', otherInd);
            set(handles.stateCombo, 'Value', StopwatchRunningEnum.getIndOfListboxStrs(StopwatchRunningEnum.NotRunning));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.stopwatch == sws(otherInd), 'Save must write the selected stopwatch.');
            testCase.verifyEqual(action.runningStateToSet, StopwatchRunningEnum.NotRunning, ...
                'Save must write the selected running state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            swBefore = action.stopwatch;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStopwatchRunningStateGUI;

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            otherInd = mod(find(sws == action.stopwatch, 1), numel(sws)) + 1;
            set(handles.refStopwatchCombo, 'Value', otherInd);
            set(handles.stateCombo, 'Value', StopwatchRunningEnum.getIndOfListboxStrs(StopwatchRunningEnum.NotRunning));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.stopwatch == swBefore, 'Cancel must leave the stopwatch alone.');
            testCase.verifyEqual(action.runningStateToSet, StopwatchRunningEnum.Running, ...
                'Cancel must leave the running state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            swBefore = action.stopwatch;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetStopwatchRunningStateGUI;

            set(handles.stateCombo, 'Value', StopwatchRunningEnum.getIndOfListboxStrs(StopwatchRunningEnum.NotRunning));
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.stopwatch == swBefore, 'Window-X must leave the stopwatch alone.');
            testCase.verifyEqual(action.runningStateToSet, StopwatchRunningEnum.Running, ...
                'Window-X must leave the running state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            sw1 = LaunchVehicleStopwatch(lvdData);
            sw1.name = 'Test Stopwatch 1';
            sw1.startOn = StopwatchRunningEnum.NotRunning;
            sw1.startValue = 7;
            lvdData.launchVehicle.addStopwatch(sw1);
            sw2 = LaunchVehicleStopwatch(lvdData);
            sw2.name = 'Test Stopwatch 2';
            sw2.startOn = StopwatchRunningEnum.Running;
            sw2.startValue = 3;
            lvdData.launchVehicle.addStopwatch(sw2);

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.assertGreaterThanOrEqual(numel(sws), 2, 'Fixture must seed two stopwatches.');
            action = SetStopwatchRunningStateAction(sw1, StopwatchRunningEnum.Running);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetStopwatchRunningStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StopwatchRunningStateActionDialogTest.deleteIfValid(app));
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
