classdef ElectricalPowerSrcsDialogTest < KsptotTestCase
    %ElectricalPowerSrcsDialogTest Full round-trip UI tests for the power
    %source set editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_src/lvd_EditElectricalPowerSrcsGUI_App.mlapp
    %   backing classes: LaunchVehicleEpsRtg, LaunchVehicleStaticSolarPanel,
    %   LaunchVehicleRotatingSolarPanel
    %   production caller: lvd_editLaunchVehicle_App editEpsSrcsButton
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
    %   Open lists seeded sources; list mirrors the vehicle; Remove deletes
    %   the selected source and refreshes; remove disables when empty; the
    %   add button exists; Close and window-X close the dialog cleanly.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsSeededSources(testCase)
            [lvdData, rtg, panel] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyEqual(numel(app.sourcesListBox.Items), 2, ...
                'Two seeded sources must be listed.');
            testCase.verifyTrue(any(app.sourcesListBox.ItemsData == rtg));
            testCase.verifyTrue(any(app.sourcesListBox.ItemsData == panel));
            testCase.pushButton(app.closeButton);
        end

        function listMirrorsVehicle(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            [strs, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.verifyEqual(app.sourcesListBox.Items(:), strs(:), ...
                'The listbox must mirror the vehicle source list.');
            testCase.verifyEqual(numel(app.sourcesListBox.ItemsData), numel(srcs));
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDeletesSelectedSource(testCase)
            [lvdData, rtg, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            app.sourcesListBox.Value = rtg;
            testCase.pushButton(app.removeSrcButton);

            [~, srcs] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.verifyEqual(numel(srcs), 1, 'Remove must delete one source.');
            testCase.verifyFalse(any(srcs == rtg), 'The selected source must be gone.');
            testCase.verifyEqual(numel(app.sourcesListBox.Items), 1, ...
                'The listbox must refresh after removal.');
            testCase.pushButton(app.closeButton);
        end

        function removeButtonDisabledWhenEmpty(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(string(app.removeSrcButton.Enable) == "off", ...
                'With no sources removal must be disabled.');
            testCase.pushButton(app.closeButton);
        end

        function addButtonExists(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(isvalid(app.addSrcButton), ...
                'The add-source button must exist (nested type picker not pressed).');
            testCase.pushButton(app.closeButton);
        end

        function closeButtonClosesDialog(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerSrcsGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
        end

        function windowClosePreservesSources(testCase)
            [lvdData, ~, ~] = testCase.fixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditElectricalPowerSrcsGUI;

            [~, before] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            close(fig);
            drawnow;

            [~, after] = lvdData.launchVehicle.getPowerSrcsListBoxStr();
            testCase.verifyFalse(isvalid(fig), 'Window-X must close the dialog.');
            testCase.verifyEqual(numel(after), numel(before), ...
                'Window-X must leave the sources alone.');
        end
    end

    methods(Access=private)
        function [lvdData, rtg, panel] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            rtg = LaunchVehicleEpsRtg(stg);
            rtg.name = 'Test RTG';
            rtg.initPwrRate = 5;
            stg.addPwrSrc(rtg);
            panel = LaunchVehicleStaticSolarPanel(stg);
            panel.name = 'Test Fixed Panel';
            panel.refChargeRate = 4;
            stg.addPwrSrc(panel);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditElectricalPowerSrcsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ElectricalPowerSrcsDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Electrical Power Sources')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
