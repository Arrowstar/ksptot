classdef ElectricalPowerStoragesDialogTest < KsptotTestCase
    %ElectricalPowerStoragesDialogTest Full round-trip UI tests for the
    %power storage set editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_storage/lvd_EditElectricalPowerStoragesGUI_App.mlapp
    %   backing class: LaunchVehicleBasicElectricalBattery
    %   production caller: lvd_editLaunchVehicle_App editEpsStorageButton
    %   (kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_editLaunchVehicle_App.mlapp).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The set editor has no
    %   save flag: Close is the only exit, add opens nested dialogs and is
    %   covered by existence (never pressed), remove is safe (no nesting).
    %
    % COVERED
    %   Open lists seeded storages; list mirrors the vehicle; Remove deletes
    %   the selected storage and refreshes; remove disables when empty; the
    %   add button exists; Close and window-X close the dialog cleanly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsSeededStorages(testCase)
            [lvdData, b1, b2] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(numel(app.storageListBox.Items), 2, ...
                'Two seeded batteries must be listed.');
            testCase.verifyTrue(any(app.storageListBox.ItemsData == b1));
            testCase.verifyTrue(any(app.storageListBox.ItemsData == b2));
            testCase.pushButton(app.closeButton);
        end

        function listMirrorsVehicle(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            [strs, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.verifyEqual(app.storageListBox.Items(:), strs(:), ...
                'The listbox must mirror the vehicle storage list.');
            testCase.verifyEqual(numel(app.storageListBox.ItemsData), numel(storages));
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDeletesSelectedStorage(testCase)
            [lvdData, b1, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            app.storageListBox.Value = b1;
            testCase.pushButton(app.removeStorageButton);

            [~, storages] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.verifyEqual(numel(storages), 1, 'Remove must delete one storage.');
            testCase.verifyFalse(any(storages == b1), 'The selected storage must be gone.');
            testCase.verifyEqual(numel(app.storageListBox.Items), 1, ...
                'The listbox must refresh after removal.');
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDisabledWhenEmpty(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(string(app.removeStorageButton.Enable) == "off", ...
                'With no storages removal must be disabled.');
            testCase.pushButton(app.closeButton);
        end

        function addButtonExists(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(isvalid(app.addStorageButton), ...
                'The add-storage button must exist (nested type picker not pressed).');
            testCase.pushButton(app.closeButton);
        end

        function closeButtonClosesDialog(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerStoragesGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
        end

        function windowClosePreservesStorages(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerStoragesGUI;

            [~, before] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            close(fig);
            drawnow;

            [~, after] = lvdData.launchVehicle.getPowerStoragesListBoxStr();
            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyEqual(numel(after), numel(before), ...
                'Window-X must leave the storages alone.');
        end
    end

    methods(Access=private)
        function [lvdData, b1, b2] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            b1 = LaunchVehicleBasicElectricalBattery(stg);
            b1.name = 'Battery One';
            b1.maxCapacity = 100;
            b1.initialStateOfCharge = 50;
            stg.addPwrStorage(b1);
            b2 = LaunchVehicleBasicElectricalBattery(stg);
            b2.name = 'Battery Two';
            b2.maxCapacity = 200;
            b2.initialStateOfCharge = 20;
            stg.addPwrStorage(b2);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditElectricalPowerStoragesGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ElectricalPowerStoragesDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Electrical Power Storage')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
