classdef EngineToTanksConnsDialogTest < KsptotTestCase
    %EngineToTanksConnsDialogTest Full round-trip UI tests for the
    %engine-to-tank connections set editor (Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditEngineToTanksConnsGUI_App.mlapp
    %   ('Edit Engine To Tank Connections'; single-arg ctor (lvdData), no
    %   output arg -- Add / Remove write straight into
    %   lvdData.launchVehicle and Close just closes).  Add opens the single
    %   connection editor (lvd_EditEngineToTanksConnGUI_App) for a new
    %   connection and only keeps it on Save & Close.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The nested single
    %   connection editor is stubbed with whenShown handlers and the fixture
    %   error log is asserted empty.
    %
    % COVERED
    %   Open lists the stored connections; Add with a nested Save appends
    %   the connection while Add with a nested Cancel adds nothing; Remove
    %   drops the selected connection; Close and window-X preserve the
    %   model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredConnections(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            conn = lv.getEngineToTankForInd(1);
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(app.connsListBox.Items(:), {'First Stage Engine to First Stage Tank'}, ...
                'The list must mirror the vehicle''s connections.');
            testCase.verifyEqual(numel(app.connsListBox.ItemsData), 1);
            testCase.verifyTrue(app.connsListBox.ItemsData(1) == conn);
        end

        function addConnectionViaSaveAppendsConnection(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Engine To Tank Connection', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.addConnButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Engine To Tank Connection'), ...
                'Add must open the single-connection editor.');
            [~, conns] = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(conns), 2, 'A nested Save must keep the new connection.');
            testCase.verifyEqual(numel(app.connsListBox.Items), 2);
            testCase.verifyTrue(app.connsListBox.Value == conns(end), ...
                'The new connection must be selected.');
        end

        function addConnectionViaCancelAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Engine To Tank Connection', @(fig) recordAndPush(fig, seen, 'Cancel'));
            testCase.pushButton(app.addConnButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Engine To Tank Connection'));
            [~, conns] = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(conns), 1, 'A nested Cancel must drop the new connection.');
            testCase.verifyEqual(numel(app.connsListBox.Items), 1);
        end

        function removeAddedConnection(testCase)
            [lvdData, conn2] = testCase.twoConnFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            app.connsListBox.Value = conn2;
            testCase.pushButton(app.removeConnButton);

            [connStr, conns] = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(conns), 1, 'Remove must drop the selected connection.');
            testCase.verifyEqual(connStr, {'First Stage Engine to First Stage Tank'});
            testCase.verifyEqual(numel(app.connsListBox.Items), 1);
            testCase.verifyTrue(isvalid(handles.lvd_EditEngineToTanksConnsGUI), ...
                'Removing must leave the editor open.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineToTanksConnsGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            [~, conns] = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(conns), 1, 'Close must leave the model alone.');
        end

        function windowXClosePreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineToTanksConnsGUI;

            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            [~, conns] = lvdData.launchVehicle.getEngineToTankConnectionsListBoxStr();
            testCase.verifyEqual(numel(conns), 1);
        end
    end

    methods(Access=private)
        function [lvdData, conn2] = twoConnFixture(testCase)
            %A second connection built exactly the way the Add button builds
            %one (connection plus its connection state), so removal is
            %exercised on a fully wired object.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lv = lvdData.launchVehicle;
            stg = lv.stages(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 2;
            tank2.capacity = 2;
            stg.addTank(tank2);

            conn2 = EngineToTankConnection(tank2, stg.engines(1));
            lv.addEngineToTankConnection(conn2);
            lvdData.initStateModel.lvState.addE2TConnState(EngineToTankConnState(conn2));
        end

        function app = openDialog(testCase, lvdData)
            %The connections editor takes only lvdData (no output arg).
            app = lvd_EditEngineToTanksConnsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EngineToTanksConnsDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Engine To Tank Connections')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function recordAndPush(fig, seen, buttonText)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, buttonText);
end
