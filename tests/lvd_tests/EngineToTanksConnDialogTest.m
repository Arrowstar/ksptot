classdef EngineToTanksConnDialogTest < KsptotTestCase
    %EngineToTanksConnDialogTest Full round-trip UI tests for the single
    %engine-to-tank connection editor (Phase 3: vehicle editors).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditEngineToTanksConnGUI_App.mlapp
    %   ('Edit Engine To Tank Connection'; two-arg ctor (e2TConn, output).
    %   Backing class: EngineToTankConnection.)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % NOTE
    %   This dialog performs no validation: its Save & Close button calls
    %   saveAndClose directly (the mlapp carries no validate step), and both
    %   dropdowns can only name objects already on the vehicle.  There is
    %   therefore no validation-rejection test here by construction.
    %
    % COVERED
    %   Open shows the stored tank/engine selections; both dropdowns offer
    %   every vehicle tank/engine; Save & Close repoints the connection;
    %   saving unchanged keeps it; Cancel and window-X preserve it.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredConnection(testCase)
            [conn, ~] = testCase.twoByTwoFixture();
            app = testCase.openDialog(conn);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.tankCombo.Value, 2, ...
                'The tank dropdown must show the connected tank.');
            testCase.verifyEqual(handles.engineCombo.Value, 2, ...
                'The engine dropdown must show the connected engine.');
        end

        function combosOfferEveryTankAndEngine(testCase)
            [~, lvdData] = testCase.twoByTwoFixture();
            app = testCase.openDialog(lvdData.launchVehicle.getEngineToTankForInd(1));
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            tankItems = cellstr(handles.tankCombo.String);
            testCase.verifyEqual(numel(tankItems), 2, 'Every vehicle tank must be offered.');
            testCase.verifyEqual(tankItems(:), {'First Stage Tank'; 'Second Tank'});

            engineItems = cellstr(handles.engineCombo.String);
            testCase.verifyEqual(numel(engineItems), 2, 'Every vehicle engine must be offered.');
            testCase.verifyEqual(engineItems(:), {'First Stage Engine'; 'Second Engine'});
        end

        function saveAndCloseRepointsConnection(testCase)
            [conn, lvdData] = testCase.twoByTwoFixture();
            lv = lvdData.launchVehicle;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineToTanksConnGUI;

            handles.tankCombo.Value = 1;
            handles.engineCombo.Value = 1;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(conn.tank == lv.getTankForInd(1), 'Save must repoint the tank.');
            testCase.verifyTrue(conn.engine == lv.getEngineForInd(1), 'Save must repoint the engine.');
        end

        function saveAndCloseUnchangedKeepsConnection(testCase)
            [conn, ~] = testCase.fixture();
            tank = conn.tank;
            engine = conn.engine;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(conn.tank == tank && conn.engine == engine, ...
                'Saving unchanged must keep the connection.');
        end

        function cancelPreservesConnection(testCase)
            [conn, ~] = testCase.twoByTwoFixture();
            tank = conn.tank;
            engine = conn.engine;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineToTanksConnGUI;

            handles.tankCombo.Value = 1;
            handles.engineCombo.Value = 1;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(conn.tank == tank && conn.engine == engine, ...
                'Cancel must leave the connection alone.');
        end

        function windowXPreservesConnection(testCase)
            [conn, ~] = testCase.twoByTwoFixture();
            tank = conn.tank;
            engine = conn.engine;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditEngineToTanksConnGUI;

            handles.tankCombo.Value = 1;
            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyFalse(out.output{1});
            testCase.verifyTrue(conn.tank == tank && conn.engine == engine);
        end
    end

    methods(Access=private)
        function [conn, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            conn = lvdData.launchVehicle.getEngineToTankForInd(1);
        end

        function [conn, lvdData] = twoByTwoFixture(testCase)
            %A second tank and engine plus a connection between them, so the
            %dropdown selections are distinguishable from the stock ones.
            %No state-model entries are needed: this dialog never touches
            %the state model.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Second Tank';
            tank2.initialMass = 2;
            tank2.capacity = 2;
            stg.addTank(tank2);

            engine2 = LaunchVehicleEngine(stg);
            engine2.name = 'Second Engine';
            stg.addEngine(engine2);

            conn = EngineToTankConnection(tank2, engine2);
        end

        function app = openDialog(testCase, conn, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditEngineToTanksConnGUI_App(conn, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() EngineToTanksConnDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Engine To Tank Connection')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
