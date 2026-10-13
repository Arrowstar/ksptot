classdef TankToTankConnDialogTest < KsptotTestCase
    %TankToTankConnDialogTest Full round-trip UI tests for the single
    %tank-to-tank connection editor (Phase 3: vehicle).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_EditTankToTankConnGUI_App.mlapp
    %   backing class: TankToTankConnection (dialog ctor is (t2TConn, output))
    %   production caller: lvd_EditTankToTankConnsGUI_App (add/edit paths).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored source/target/flow rate; both combos offer every
    %   vehicle tank plus the leading external entry; Save & Close writes
    %   source, target and rate back; a blank or negative rate and a
    %   self-connection are rejected and leave the model alone; Cancel and
    %   window-X preserve the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [conn, lvdData, tank1, tank2] = testCase.fixture();
            app = testCase.openDialog(conn);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            lv = lvdData.launchVehicle;
            testCase.verifyEqual(handles.srcTankCombo.Value, 1 + lv.getListBoxIndForTank(tank1));
            testCase.verifyEqual(handles.tgtTankCombo.Value, 1 + lv.getListBoxIndForTank(tank2));
            testCase.verifyEqual(str2double(get(handles.flowRateText, 'String')), 0.05, 'AbsTol', 1e-12);
        end

        function combosOfferEveryTankPlusExternal(testCase)
            [conn, lvdData] = testCase.fixture();
            app = testCase.openDialog(conn);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, tanks] = lvdData.launchVehicle.getTanksListBoxStr();
            testCase.verifyEqual(numel(cellstr(handles.srcTankCombo.String)), numel(tanks) + 1, ...
                'The source combo must offer every tank plus the external entry.');
            testCase.verifyEqual(numel(cellstr(handles.tgtTankCombo.String)), numel(tanks) + 1, ...
                'The target combo must offer every tank plus the external entry.');
        end

        function saveAndCloseWritesSourcesAndRate(testCase)
            [conn, lvdData, ~, tank2] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            lv = lvdData.launchVehicle;
            handles.srcTankCombo.Value = 1 + lv.getListBoxIndForTank(tank2);
            handles.tgtTankCombo.Value = 1; % external: dump overboard
            set(handles.flowRateText, 'String', '0.25');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(conn.srcTank.name, 'Aft Tank');
            testCase.verifyTrue(isempty(conn.tgtTank), 'An external target must be stored empty.');
            testCase.verifyEqual(conn.initFlowRate, 0.25, 'AbsTol', 1e-12);
        end

        function blankFlowRateIsRejected(testCase)
            [conn, ~, ~, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            set(handles.flowRateText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank flow rate must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(conn.initFlowRate, 0.05, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts(fig);
        end

        function negativeFlowRateIsRejected(testCase)
            [conn, ~, ~, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            set(handles.flowRateText, 'String', '-3');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative flow rate must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(conn.initFlowRate, 0.05, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts(fig);
        end

        function sameSourceAndTargetIsRejected(testCase)
            [conn, ~, tank1, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            handles.tgtTankCombo.Value = handles.srcTankCombo.Value;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A self-connection must not save.');
            testCase.verifyTrue(isvalid(fig), 'Failed validation must leave the dialog open.');
            testCase.verifyEqual(conn.srcTank.name, tank1.name, 'Rejected input must leave the model alone.');
            testCase.verifyEqual(conn.initFlowRate, 0.05, 'AbsTol', 1e-12);
            testCase.closeAlerts(fig);
        end

        function cancelPreservesModel(testCase)
            [conn, ~, tank1, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            set(handles.flowRateText, 'String', '99');
            handles.tgtTankCombo.Value = 1;
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(conn.initFlowRate, 0.05, 'AbsTol', 1e-12, 'Cancel must leave the model alone.');
            testCase.verifyEqual(conn.srcTank.name, tank1.name);
        end

        function windowClosePreservesModel(testCase)
            [conn, ~, ~, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(conn, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditTankToTankConnGUI;

            set(handles.flowRateText, 'String', '99');
            close(fig);

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(conn.initFlowRate, 0.05, 'AbsTol', 1e-12, 'Window-X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [conn, lvdData, tank1, tank2] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            tank1 = stg.tanks(1);

            tank2 = LaunchVehicleTank(stg);
            tank2.name = 'Aft Tank';
            tank2.initialMass = 1;
            tank2.capacity = 1;
            stg.addTank(tank2);

            conn = TankToTankConnection(tank1, tank2);
            conn.initFlowRate = 0.05;
        end

        function app = openDialog(testCase, conn, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditTankToTankConnGUI_App(conn, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() TankToTankConnDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~, keepFig)
            %Compare by captured figure number: .Number on a figure that
            %died mid-sweep returns [] and breaks &&-chained comparisons.
            keepNum = [];
            if ~isempty(keepFig) && isvalid(keepFig)
                keepNum = keepFig.Number;
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~isequal(figs(i).Number, keepNum)
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Tank To Tank Connection')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
