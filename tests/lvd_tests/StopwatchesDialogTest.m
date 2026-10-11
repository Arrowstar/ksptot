classdef StopwatchesDialogTest < KsptotTestCase
    %StopwatchesDialogTest Full round-trip UI tests for the stopwatch set
    %editor (Phase 3: vehicle).  This promotes the LvdMainGuiWidgetSmokeTest
    %open/cancel smoke coverage to value-level assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditStopwatchesGUI_App.mlapp
    %   backing store: LaunchVehicle.stopwatches (dialog ctor is (lvdData))
    %   production caller: LVD main window (editStopwatchesMenu).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The Add button opens the
    %   single-stopwatch child dialog (figure 'Edit Stopwatch'), stubbed
    %   with UiwaitInterceptorFixture.whenShown to press Save & Close (the
    %   CompositeObjectiveDialogTest pattern).
    %
    % COVERED
    %   The list mirrors the stored stopwatches; Add (stubbed child) appends
    %   one stopwatch and refreshes the listbox; Remove drops the selection
    %   (and keeps the rest); Close ends the dialog and leaves the model
    %   alone.  The set dialog has no Save/Cancel/output: edits apply
    %   immediately.  No test propagates or optimizes.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function listShowsStoredStopwatches(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeSw(lvdData, 'Coast Timer');
            testCase.makeSw(lvdData, 'Burn Timer');

            app = testCase.openDialog(lvdData);

            [swStrs, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyNumElements(app.stopwatchesListBox.ItemsData, 2, ...
                'The listbox must mirror the stored stopwatches.');
            testCase.verifyEqual(app.stopwatchesListBox.Items(:), swStrs(:), ...
                'The listbox strings must mirror the vehicle strings.');
            testCase.verifyNumElements(sws, 2);
        end

        function addStopwatchAppendsViaChildDialog(testCase)
            [lvdData] = testCase.fixture();
            [~, before] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.assertEmpty(before, 'Fixture: the default mission must have no stopwatches.');

            stub = UiwaitInterceptorFixture();
            stub.whenShown('Edit Stopwatch', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));

            app = testCase.openDialog(lvdData);
            testCase.pushButton(app.addStopwatchButton);

            testCase.verifyEmpty(stub.errors(), strjoin(stub.errors(), newline));
            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyNumElements(sws, 1, 'Accepting the child dialog must append one stopwatch.');
            testCase.verifyNumElements(app.stopwatchesListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
            testCase.verifyEqual(app.stopwatchesListBox.Value.name, 'Untitled Stopwatch', ...
                'The new stopwatch must be selected after an add.');
        end

        function removeStopwatchDropsSelected(testCase)
            [lvdData] = testCase.fixture();
            sw = testCase.makeSw(lvdData, 'Coast Timer');

            app = testCase.openDialog(lvdData);
            app.stopwatchesListBox.Value = sw;
            drawnow;
            testCase.pushButton(app.removeStopwatchButton);

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyEmpty(sws, 'Remove must drop the selected stopwatch.');
            testCase.verifyEmpty(app.stopwatchesListBox.ItemsData, 'The listbox must refresh after a remove.');
        end

        function removeKeepsUnselectedStopwatches(testCase)
            [lvdData] = testCase.fixture();
            swA = testCase.makeSw(lvdData, 'Coast Timer');
            testCase.makeSw(lvdData, 'Burn Timer');

            app = testCase.openDialog(lvdData);
            app.stopwatchesListBox.Value = swA;
            drawnow;
            testCase.pushButton(app.removeStopwatchButton);

            [~, sws] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyNumElements(sws, 1, 'Only the selected stopwatch may go.');
            testCase.verifyEqual(sws(1).name, 'Burn Timer', ...
                'The surviving stopwatch must be the unselected one.');
        end

        function closeButtonClosesWithoutTouchingModel(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeSw(lvdData, 'Coast Timer');
            [~, before] = lvdData.launchVehicle.getStopwatchesListBoxStr();

            app = testCase.openDialog(lvdData);
            fig = app.lvd_EditStopwatchesGUI;
            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, after] = lvdData.launchVehicle.getStopwatchesListBoxStr();
            testCase.verifyNumElements(after, numel(before), 'Close must leave the model alone.');
        end

        function emptyVehicleShowsEmptyList(testCase)
            [lvdData] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.stopwatchesListBox.ItemsData, ...
                'The default mission ships with no stopwatches.');
            testCase.verifyEqual(char(app.removeStopwatchButton.Enable), 'off', ...
                'With nothing listed there is nothing to remove.');
        end
    end

    methods(Access=private)
        function lvdData = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function sw = makeSw(~, lvdData, name)
            sw = LaunchVehicleStopwatch(lvdData);
            sw.name = name;
            lvdData.launchVehicle.addStopwatch(sw);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditStopwatchesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() StopwatchesDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Stopwatches') || ...
                        strcmp(figs(i).Name, 'Edit Stopwatch'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
