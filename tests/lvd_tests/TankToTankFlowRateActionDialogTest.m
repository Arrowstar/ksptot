classdef TankToTankFlowRateActionDialogTest < KsptotTestCase
    %TankToTankFlowRateActionDialogTest Full round-trip UI tests for the
    %tank-to-tank connection flow-rate action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetTankToTankConnFlowRateGUI_App.mlapp
    %   backing class: SetTankTankConnFlowRateEventAction
    %   (opens via SetTankTankConnFlowRateEventAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored connection/flow rate; Save & Close writes both
    %   back; a blank rate and a negative rate are rejected and leave the
    %   model alone; Cancel and window-X preserve the model; the connection
    %   dropdown mirrors the vehicle's tank-to-tank connections.
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
            testCase.verifyEqual(str2double(get(handles.flowRateText, 'String')), 2.5, 'AbsTol', 1e-12, ...
                'The stored flow rate must be shown.');
        end

        function refComboOffersEveryConn(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.refConnCombo, 'String'))), numel(conns), ...
                'Every tank-to-tank connection must be offered.');
        end

        function saveAndCloseWritesConnAndRate(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnFlowRateGUI;

            [~, conns] = lvdData.launchVehicle.getTankToTankConnectionsListBoxStr();
            otherInd = mod(find(conns == action.conn, 1), numel(conns)) + 1;
            set(handles.refConnCombo, 'Value', otherInd);
            set(handles.flowRateText, 'String', '4.25');

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.conn == conns(otherInd), 'Save must write the selected connection.');
            testCase.verifyEqual(action.flowRateToSet, 4.25, 'AbsTol', 1e-12, ...
                'Save must write the entered flow rate.');
        end

        function invalidFlowRateIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.flowRateText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank flow rate must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetTankToTankConnFlowRateGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.flowRateToSet, 2.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();

            set(handles.flowRateText, 'String', '-2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative flow rate must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditActionSetTankToTankConnFlowRateGUI));
            testCase.verifyEqual(action.flowRateToSet, 2.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            connBefore = action.conn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnFlowRateGUI;

            set(handles.flowRateText, 'String', '9.5');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.conn == connBefore, 'Cancel must leave the connection alone.');
            testCase.verifyEqual(action.flowRateToSet, 2.5, 'AbsTol', 1e-12, ...
                'Cancel must leave the flow rate alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData] = testCase.fixture();
            connBefore = action.conn;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditActionSetTankToTankConnFlowRateGUI;

            set(handles.flowRateText, 'String', '9.5');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.conn == connBefore, 'Window-X must leave the connection alone.');
            testCase.verifyEqual(action.flowRateToSet, 2.5, 'AbsTol', 1e-12, ...
                'Window-X must leave the flow rate alone.');
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
            action = SetTankTankConnFlowRateEventAction(conn1, 2.5);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            lv = lvdData.launchVehicle;
            app = lvd_EditActionSetTankToTankConnFlowRateGUI_App(action, lv, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankToTankFlowRateActionDialogTest.deleteIfValid(app));
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
