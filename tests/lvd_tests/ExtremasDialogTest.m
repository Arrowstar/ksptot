classdef ExtremasDialogTest < KsptotTestCase
    %ExtremasDialogTest Full round-trip UI tests for the extrema set editor
    %(Phase 3: vehicle).  This promotes the LvdMainGuiWidgetSmokeTest
    %open/cancel smoke coverage to value-level assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditExtremasGUI_App.mlapp
    %   backing store: LaunchVehicle.extrema (dialog ctor is (lvdData))
    %   production caller: LVD main window (editExtremaMenu).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The Add button opens the
    %   single-extremum child dialog (figure 'Edit Extrema'), stubbed with
    %   UiwaitInterceptorFixture.whenShown to press Save & Close (the
    %   CompositeObjectiveDialogTest pattern).  Note parent and child share
    %   the figure Name 'Edit Extrema', so teardown closes by that Name.
    %
    % COVERED
    %   The list mirrors the stored extrema; Add (stubbed child) appends one
    %   extremum and refreshes the listbox; Remove drops the selection (and
    %   keeps the rest); Close ends the dialog and leaves the model alone.
    %   The set dialog has no Save/Cancel/output: edits apply immediately.
    %   No test propagates or optimizes.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function listShowsStoredExtrema(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeEx(lvdData, 'Altitude');
            testCase.makeEx(lvdData, 'Velocity');

            app = testCase.openDialog(lvdData);

            [exStrs, exa] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.verifyNumElements(app.extremasListBox.ItemsData, 2, ...
                'The listbox must mirror the stored extrema.');
            testCase.verifyEqual(app.extremasListBox.Items(:), exStrs(:), ...
                'The listbox strings must mirror the vehicle strings.');
            testCase.verifyNumElements(exa, 2);
        end

        function addExtremumAppendsViaChildDialog(testCase)
            [lvdData] = testCase.fixture();
            [~, before] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.assertEmpty(before, 'Fixture: the default mission must have no extrema.');

            app = testCase.openDialog(lvdData);
            %Register AFTER the parent opens: parent and child share the
            %figure Name 'Edit Extrema', and an earlier registration would
            %be consumed by the parent's own uiwait (which has no
            %Save & Close button).
            stub = UiwaitInterceptorFixture();
            stub.whenShown('Edit Extrema', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));

            testCase.pushButton(app.addExtremaButton);

            testCase.verifyEmpty(stub.errors(), strjoin(stub.errors(), newline));
            [~, exa] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.verifyNumElements(exa, 1, 'Accepting the child dialog must append one extremum.');
            testCase.verifyNumElements(app.extremasListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
            testCase.verifyFalse(isempty(exa(1).quantStr), 'The added extremum must carry a quantity.');
        end

        function removeExtremumDropsSelected(testCase)
            [lvdData] = testCase.fixture();
            ex = testCase.makeEx(lvdData, 'Altitude');

            app = testCase.openDialog(lvdData);
            app.extremasListBox.Value = ex;
            drawnow;
            testCase.pushButton(app.removeExtremaButton);

            [~, exa] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.verifyEmpty(exa, 'Remove must drop the selected extremum.');
            testCase.verifyEmpty(app.extremasListBox.ItemsData, 'The listbox must refresh after a remove.');
        end

        function removeKeepsUnselectedExtrema(testCase)
            [lvdData] = testCase.fixture();
            exA = testCase.makeEx(lvdData, 'Altitude');
            exB = testCase.makeEx(lvdData, 'Velocity');

            app = testCase.openDialog(lvdData);
            app.extremasListBox.Value = exA;
            drawnow;
            testCase.pushButton(app.removeExtremaButton);

            [~, exa] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.verifyNumElements(exa, 1, 'Only the selected extremum may go.');
            testCase.verifyEqual(exa(1).quantStr, exB.quantStr, ...
                'The surviving extremum must be the unselected one.');
        end

        function closeButtonClosesWithoutTouchingModel(testCase)
            [lvdData] = testCase.fixture();
            testCase.makeEx(lvdData, 'Altitude');
            [~, before] = lvdData.launchVehicle.getExtremaListBoxStr();

            app = testCase.openDialog(lvdData);
            fig = app.lvd_EditExtremasGUI;
            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, after] = lvdData.launchVehicle.getExtremaListBoxStr();
            testCase.verifyNumElements(after, numel(before), 'Close must leave the model alone.');
        end

        function emptyVehicleShowsEmptyList(testCase)
            [lvdData] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.extremasListBox.ItemsData, ...
                'The default mission ships with no extrema.');
            testCase.verifyEqual(char(app.removeExtremaButton.Enable), 'off', ...
                'With nothing listed there is nothing to remove.');
        end
    end

    methods(Access=private)
        function lvdData = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function ex = makeEx(~, lvdData, quantStr)
            ex = LaunchVehicleExtrema(lvdData);
            ex.quantStr = quantStr;
            ex.type = LaunchVehicleExtremaTypeEnum.Maximum;
            ex.frame = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData).getBodyCenteredInertialFrame();
            lvdData.launchVehicle.addExtremum(ex);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditExtremasGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ExtremasDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Extrema')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
