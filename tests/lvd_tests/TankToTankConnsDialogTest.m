classdef TankToTankConnsDialogTest < KsptotTestCase
    %TankToTankConnsDialogTest Full round-trip UI tests for the
    %tank-to-tank connection set editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditTankToTankConnsGUI_App.mlapp
    %   backing store: LaunchVehicle.tankToTankConns (dialog ctor is (lvdData))
    %   production caller: lvd_editLaunchVehicle_App (editTankToTankConnsButton).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The Add button opens the
    %   single-connection child dialog (figure 'Edit Tank To Tank
    %   Connection'), stubbed with UiwaitInterceptorFixture.whenShown to
    %   press Save & Close (the CompositeObjectiveDialogTest pattern).
    %
    % COVERED
    %   The list mirrors the stored connections; Add (stubbed child) appends
    %   one connection, refreshes the listbox and creates its state; Remove
    %   drops the selection (and keeps the rest); Close ends the dialog and
    %   leaves the model alone.  The set dialog has no Save/Cancel/output:
    %   edits apply immediately.  No test propagates or optimizes.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function listShowsStoredConnections(testCase)
            [lvdData, tank1, tank2] = testCase.fixture();
            testCase.makeConn(lvdData, tank1, tank2, 0.05);
            testCase.makeConn(lvdData, tank2, tank1, 0.1);

            app = testCase.openDialog(lvdData);

            [connStrs, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyNumElements(app.connsListBox.ItemsData, 2, ...
                'The listbox must mirror the stored connections.');
            testCase.verifyEqual(app.connsListBox.Items(:), connStrs(:), ...
                'The listbox strings must mirror the vehicle strings.');
            testCase.verifyNumElements(conns, 2);
        end

        function addConnAppendsViaChildDialog(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            [~, before] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.assertEmpty(before, 'Fixture: the default mission must have no T2T connections.');

            stub = UiwaitInterceptorFixture();
            stub.whenShown('Edit Tank To Tank Connection', ...
                @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));

            app = testCase.openDialog(lvdData);
            testCase.pushButton(app.addConnButton);

            testCase.verifyEmpty(stub.errors(), strjoin(stub.errors(), newline));
            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyNumElements(conns, 1, 'Accepting the child dialog must append one connection.');
            testCase.verifyNumElements(app.connsListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
            lvState = lvdData.initStateModel.lvState;
            testCase.verifyFalse(isempty(lvState.getTank2TankConnStateForConn(conns(1))), ...
                'The add path must also create the connection state.');
        end

        function removeConnDropsSelectedConnection(testCase)
            [lvdData, tank1, tank2] = testCase.fixture();
            conn = testCase.makeConn(lvdData, tank1, tank2, 0.05);

            app = testCase.openDialog(lvdData);
            app.connsListBox.Value = conn;
            drawnow;
            testCase.pushButton(app.removeConnButton);

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyEmpty(conns, 'Remove must drop the selected connection.');
            testCase.verifyEmpty(app.connsListBox.ItemsData, 'The listbox must refresh after a remove.');
        end

        function removeKeepsUnselectedConnections(testCase)
            [lvdData, tank1, tank2] = testCase.fixture();
            connA = testCase.makeConn(lvdData, tank1, tank2, 0.05);
            testCase.makeConn(lvdData, tank2, tank1, 0.1);

            app = testCase.openDialog(lvdData);
            app.connsListBox.Value = connA;
            drawnow;
            testCase.pushButton(app.removeConnButton);

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyNumElements(conns, 1, 'Only the selected connection may go.');
            testCase.verifyTrue(contains(conns(1).getName(), '0.100'), ...
                'The surviving connection must be the unselected one.');
        end

        function closeButtonClosesWithoutTouchingModel(testCase)
            [lvdData, tank1, tank2] = testCase.fixture();
            testCase.makeConn(lvdData, tank1, tank2, 0.05);
            [~, before] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();

            app = testCase.openDialog(lvdData);
            fig = app.lvd_EditTankToTanksConnsGUI;
            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, after] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyNumElements(after, numel(before), 'Close must leave the model alone.');
        end

        function emptyVehicleShowsEmptyList(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.connsListBox.ItemsData, ...
                'The default mission ships with no T2T connections.');
        end
    end

    methods(Access=private)
        function [lvdData, tank1, tank2] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Aft Tank';
            tank2.initialMass = 1;
            tank2.capacity = 1;
            stg.addTank(tank2);
        end

        function conn = makeConn(~, lvdData, srcTank, tgtTank, rate)
            conn = TankToTankConnection(srcTank, tgtTank);
            conn.initFlowRate = rate;
            lvdData.launchVehicle.addTankToTankConnection(conn);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditTankToTankConnsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankToTankConnsDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Tank To Tank Connections') || ...
                        strcmp(figs(i).Name, 'Edit Tank To Tank Connection'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
