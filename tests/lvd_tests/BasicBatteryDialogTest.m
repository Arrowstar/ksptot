classdef BasicBatteryDialogTest < KsptotTestCase
    %BasicBatteryDialogTest Full round-trip UI tests for the single basic
    %battery editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_storage/lvd_EditBasicBatteryGUI_App.mlapp
    %   backing class: LaunchVehicleBasicElectricalBattery
    %   production caller: LaunchVehicleBasicElectricalBattery.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/LaunchVehicle/electrical/power_storage/@LaunchVehicleBasicElectricalBattery/LaunchVehicleBasicElectricalBattery.m:40-42).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The initial charge is
    %   capped by the maximum capacity.
    %
    % COVERED
    %   Open shows stored capacity/charge; Save & Close writes every field
    %   back; a blank capacity and a charge above capacity are rejected and
    %   leave the model alone; Cancel and window-X preserve the model; the
    %   stage dropdown mirrors the vehicle stages.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [batt, ~] = testCase.fixture();
            batt.maxCapacity = 100;
            batt.initialStateOfCharge = 50;

            app = testCase.openDialog(batt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.maxCapacityText, 'String')), 100, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.initStateOfChargeText, 'String')), 50, 'AbsTol', 1e-12);
            testCase.verifyEqual(get(handles.stageCombo, 'Value'), 1);
        end

        function stageComboOffersEveryStage(testCase)
            [batt, lvdData] = testCase.fixture();
            app = testCase.openDialog(batt);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.stageCombo, 'String'))), numel(stages), ...
                'Every vehicle stage must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [batt, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(batt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditBasicBatteryGUI;

            handles.batteryNameText.String = 'Renamed Battery';
            set(handles.maxCapacityText, 'String', '200');
            set(handles.initStateOfChargeText, 'String', '150');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(batt.name, 'Renamed Battery');
            testCase.verifyEqual(batt.maxCapacity, 200, 'AbsTol', 1e-12);
            testCase.verifyEqual(batt.initialStateOfCharge, 150, 'AbsTol', 1e-12);
        end

        function blankCapacityIsRejected(testCase)
            [batt, ~] = testCase.fixture();
            batt.maxCapacity = 100;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(batt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxCapacityText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank capacity must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditBasicBatteryGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(batt.maxCapacity, 100, 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function chargeAboveCapacityIsRejected(testCase)
            [batt, ~] = testCase.fixture();
            batt.maxCapacity = 100;
            batt.initialStateOfCharge = 50;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(batt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.initStateOfChargeText, 'String', '150');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A charge above capacity must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditBasicBatteryGUI));
            testCase.verifyEqual(batt.initialStateOfCharge, 50, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [batt, ~] = testCase.fixture();
            batt.maxCapacity = 100;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(batt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditBasicBatteryGUI;

            set(handles.maxCapacityText, 'String', '999');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(batt.maxCapacity, 100, 'AbsTol', 1e-12);
        end

        function windowClosePreservesModel(testCase)
            [batt, ~] = testCase.fixture();
            batt.maxCapacity = 100;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(batt, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditBasicBatteryGUI;

            set(handles.maxCapacityText, 'String', '999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(batt.maxCapacity, 100, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function [batt, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            batt = LaunchVehicleBasicElectricalBattery(stg);
            batt.name = 'Test Battery';
            batt.maxCapacity = 100;
            batt.initialStateOfCharge = 50;
            stg.addPwrStorage(batt);
        end

        function app = openDialog(testCase, batt, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditBasicBatteryGUI_App(batt, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() BasicBatteryDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Basic Battery')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Basic Battery')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
