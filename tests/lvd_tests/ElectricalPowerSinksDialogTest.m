classdef ElectricalPowerSinksDialogTest < KsptotTestCase
    %ElectricalPowerSinksDialogTest Full round-trip UI tests for the power
    %sink set editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_sink/lvd_EditElectricalPowerSinksGUI_App.mlapp
    %   backing classes: LaunchVehicleSimplePwrSink
    %   production caller: lvd_editLaunchVehicle_App editEpsSinksButton
    %   (kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/lvd_editLaunchVehicle_App.mlapp).
    %   Single-sink editor caller: LaunchVehicleSimplePwrSink.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/LaunchVehicle/electrical/power_sink/@LaunchVehicleSimplePwrSink/LaunchVehicleSimplePwrSink.m:40-42).
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
    %   Open lists seeded sinks; list mirrors the vehicle; Remove deletes
    %   the selected sink and refreshes; remove disables when empty; the
    %   add button exists; Close and window-X close the dialog cleanly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsSeededSinks(testCase)
            [lvdData, s1, s2] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(numel(app.sinkListBox.Items), 2, ...
                'Two seeded sinks must be listed.');
            testCase.verifyTrue(any(app.sinkListBox.ItemsData == s1));
            testCase.verifyTrue(any(app.sinkListBox.ItemsData == s2));
            testCase.pushButton(app.closeButton);
        end

        function listMirrorsVehicle(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            [strs, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.verifyEqual(app.sinkListBox.Items(:), strs(:), ...
                'The listbox must mirror the vehicle sink list.');
            testCase.verifyEqual(numel(app.sinkListBox.ItemsData), numel(sinks));
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDeletesSelectedSink(testCase)
            [lvdData, s1, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            app.sinkListBox.Value = s1;
            testCase.pushButton(app.removeSinkButton);

            [~, sinks] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.verifyEqual(numel(sinks), 1, 'Remove must delete one sink.');
            testCase.verifyFalse(any(sinks == s1), 'The selected sink must be gone.');
            testCase.verifyEqual(numel(app.sinkListBox.Items), 1, ...
                'The listbox must refresh after removal.');
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDisabledWhenEmpty(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(string(app.removeSinkButton.Enable) == "off", ...
                'With no sinks removal must be disabled.');
            testCase.pushButton(app.closeButton);
        end

        function addButtonExists(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(isvalid(app.addSinkButton), ...
                'The add-sink button must exist (nested type picker not pressed).');
            testCase.pushButton(app.closeButton);
        end

        function closeButtonClosesDialog(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerSinksGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
        end

        function windowClosePreservesSinks(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerSinksGUI;

            [~, before] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            close(fig);
            drawnow;

            [~, after] = lvdData.launchVehicle.getPowerSinksListBoxStr();
            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyEqual(numel(after), numel(before), ...
                'Window-X must leave the sinks alone.');
        end
    end

    methods(Access=private)
        function [lvdData, s1, s2] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            s1 = LaunchVehicleSimplePwrSink(stg);
            s1.name = 'Sink One';
            s1.pwrRate = -2;
            stg.addPwrSink(s1);
            s2 = LaunchVehicleSimplePwrSink(stg);
            s2.name = 'Sink Two';
            s2.pwrRate = -3;
            stg.addPwrSink(s2);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditElectricalPowerSinksGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ElectricalPowerSinksDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Electrical Power Sinks')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
