classdef TankToTankConnStateActionDialogTest < KsptotTestCase
    %TankToTankConnStateActionDialogTest Full round-trip UI tests for the
    %tank-to-tank connection state action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetTankToTankConnStateGUI_App.mlapp
    %   backing class: SetTankTankConnActiveStateEventAction
    %   (opens via SetTankTankConnActiveStateEventAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored connection/state; Save & Close writes both back;
    %   saving without changes round-trips; Cancel and window-X preserve
    %   the model; the connection dropdown mirrors the vehicle's
    %   tank-to-tank connections.  The dialog performs no validation, so
    %   there is no rejection case.
    %
    % FIXTURE
    %   The default LvdData carries no tank-to-tank connections
    %   (openEditActionUI guards that case with a warndlg), so a second and
    %   third tank plus two connections are seeded onto the vehicle.

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

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyEqual(get(handles.refConnCombo, 'Value'), find(conns == action.conn, 1), ...
                'The connection dropdown must point at the stored connection.');
            testCase.verifyEqual(get(handles.stateCombo, 'Value'), 2, ...
                'The fixture stores Inactive, which must be shown.');
            strs = cellstr(get(handles.stateCombo, 'String'));
            testCase.verifyEqual(strs{get(handles.stateCombo, 'Value')}, 'Inactive');
        end

        function refComboOffersEveryConn(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refConnCombo, 'String'))), numel(conns), ...
                'Every tank-to-tank connection must be offered.');
        end

        function saveAndCloseWritesConnAndState(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnStateGUI;

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            otherInd = mod(find(conns == action.conn, 1), numel(conns)) + 1;
            set(handles.refConnCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.conn == conns(otherInd), 'Save must write the selected connection.');
            testCase.verifyTrue(action.activeStateToSet, 'Save must write the selected state.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData] = testCase.fixture();
            connBefore = action.conn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnStateGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.conn == connBefore, 'An unchanged save must keep the connection.');
            testCase.verifyFalse(action.activeStateToSet, 'An unchanged save must keep the state.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            connBefore = action.conn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnStateGUI;

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            otherInd = mod(find(conns == action.conn, 1), numel(conns)) + 1;
            set(handles.refConnCombo, 'Value', otherInd);
            strs = cellstr(get(handles.stateCombo, 'String'));
            set(handles.stateCombo, 'Value', find(strcmp(strs, 'Active'), 1));
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.conn == connBefore, 'Cancel must leave the connection alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Cancel must leave the state alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            connBefore = action.conn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnStateGUI;

            set(handles.stateCombo, 'Value', 1);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.conn == connBefore, 'Window-X must leave the connection alone.');
            testCase.verifyFalse(action.activeStateToSet, 'Window-X must leave the state alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);
            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 9;
            tank2.capacity = 9;
            stg.addTank(tank2);
            tank3 = LaunchVehicleTank(stg);
            tank3.name = 'Third Tank';
            tank3.initialMass = 9;
            tank3.capacity = 9;
            stg.addTank(tank3);

            conn1 = TankToTankConnection(tank1, tank2);
            lvdData.launchVehicle.addTankToTankConnection(conn1);
            conn2 = TankToTankConnection(tank1, tank3);
            lvdData.launchVehicle.addTankToTankConnection(conn2);

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.assertGreaterThanOrEqual(numel(conns), 2, 'Fixture must seed two connections.');
            action = SetTankTankConnActiveStateEventAction(conn1, false);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetTankToTankConnStateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankToTankConnStateActionDialogTest.deleteIfValid(app));
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
