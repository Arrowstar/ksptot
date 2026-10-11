classdef PowerRtgDialogTest < KsptotTestCase
    %PowerRtgDialogTest Full round-trip UI tests for the single RTG
    %editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_src/lvd_EditPowerRtgGUI_App.mlapp
    %   backing class: LaunchVehicleEpsRtg
    %   production caller: LaunchVehicleEpsRtg.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/LaunchVehicle/electrical/power_src/@LaunchVehicleEpsRtg/LaunchVehicleEpsRtg.m:40-42).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored rate/half-life/init-time; Save & Close writes
    %   every field back; blank and negative rates are rejected; Cancel and
    %   window-X preserve the model; the stage dropdown mirrors the stages.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [rtg, ~] = testCase.fixture();
            rtg.initPwrRate = 5;
            rtg.halfLife = 600;
            rtg.initTime = 100;

            app = testCase.openDialog(rtg);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.chargeRateText, 'String')), 5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.halfLifeText, 'String')), 600, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.decayInitTimeText, 'String')), 100, 'AbsTol', 1e-12);
            testCase.verifyEqual(get(handles.stageCombo, 'Value'), 1);
        end

        function stageComboOffersEveryStage(testCase)
            [rtg, lvdData] = testCase.fixture();
            app = testCase.openDialog(rtg);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.stageCombo, 'String'))), numel(stages), ...
                'Every vehicle stage must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [rtg, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(rtg, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditPowerRtgGUI;

            handles.rtgNameText.String = 'Renamed RTG';
            set(handles.chargeRateText, 'String', '7.5');
            set(handles.halfLifeText, 'String', '1200');
            set(handles.decayInitTimeText, 'String', '50');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(rtg.name, 'Renamed RTG');
            testCase.verifyEqual(rtg.initPwrRate, 7.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(rtg.halfLife, 1200, 'AbsTol', 1e-12);
            testCase.verifyEqual(rtg.initTime, 50, 'AbsTol', 1e-12);
        end

        function blankChargeRateIsRejected(testCase)
            [rtg, ~] = testCase.fixture();
            rtg.initPwrRate = 5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(rtg, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.chargeRateText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank charge rate must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditPowerRtgGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(rtg.initPwrRate, 5, 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function negativeHalfLifeIsRejected(testCase)
            [rtg, ~] = testCase.fixture();
            rtg.halfLife = 600;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(rtg, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.halfLifeText, 'String', '-10');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative half life must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditPowerRtgGUI));
            testCase.verifyEqual(rtg.halfLife, 600, 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [rtg, ~] = testCase.fixture();
            rtg.initPwrRate = 5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(rtg, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditPowerRtgGUI;

            set(handles.chargeRateText, 'String', '99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(rtg.initPwrRate, 5, 'AbsTol', 1e-12);
        end

        function windowClosePreservesModel(testCase)
            [rtg, ~] = testCase.fixture();
            rtg.initPwrRate = 5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(rtg, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditPowerRtgGUI;

            set(handles.chargeRateText, 'String', '99');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(rtg.initPwrRate, 5, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function [rtg, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            rtg = LaunchVehicleEpsRtg(stg);
            rtg.name = 'Test RTG';
            rtg.initPwrRate = 5;
            rtg.halfLife = 600;
            rtg.initTime = 0;
            stg.addPwrSrc(rtg);
        end

        function app = openDialog(testCase, rtg, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditPowerRtgGUI_App(rtg, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PowerRtgDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit RTG')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit RTG')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
