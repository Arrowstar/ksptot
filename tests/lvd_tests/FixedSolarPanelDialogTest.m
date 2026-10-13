classdef FixedSolarPanelDialogTest < KsptotTestCase
    %FixedSolarPanelDialogTest Full round-trip UI tests for the single
    %fixed solar panel editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_src/lvd_EditFixedSolarPanelGUI_App.mlapp
    %   backing class: LaunchVehicleStaticSolarPanel
    %   production caller: LaunchVehicleStaticSolarPanel.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/LaunchVehicle/electrical/power_src/@LaunchVehicleStaticSolarPanel/LaunchVehicleStaticSolarPanel.m:40-42).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The normal vector is
    %   normalized on save.
    %
    % COVERED
    %   Open shows stored rate/distance/normal; Save & Close writes every
    %   field back (normalizing the vector); blank/negative rates, a tiny
    %   distance and a zero vector are rejected; Cancel and window-X
    %   preserve the model; the stage dropdown mirrors the stages.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [panel, ~] = testCase.fixture();
            panel.refChargeRate = 4.5;
            panel.refChargeRateDist = 13599840.256;
            panel.bodyFrameNormVect = [0; 1; 0];

            app = testCase.openDialog(panel);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.refChargeRateText, 'String')), 4.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.refDistText, 'String')), 13599840.256, 'RelTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.panelXText, 'String')), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.panelYText, 'String')), 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.panelZText, 'String')), 0, 'AbsTol', 1e-12);
            testCase.verifyEqual(get(handles.stageCombo, 'Value'), 1);
        end

        function stageComboOffersEveryStage(testCase)
            [panel, lvdData] = testCase.fixture();
            app = testCase.openDialog(panel);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.stageCombo, 'String'))), numel(stages), ...
                'Every vehicle stage must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [panel, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(panel, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedSolarPanelGUI;

            handles.solarPanelNameText.String = 'Renamed Panel';
            set(handles.refChargeRateText, 'String', '7.5');
            set(handles.refDistText, 'String', '10000000');
            set(handles.panelXText, 'String', '0');
            set(handles.panelYText, 'String', '0');
            set(handles.panelZText, 'String', '2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(panel.name, 'Renamed Panel');
            testCase.verifyEqual(panel.refChargeRate, 7.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(panel.refChargeRateDist, 10000000, 'AbsTol', 1e-9);
            testCase.verifyEqual(panel.bodyFrameNormVect, [0; 0; 1], 'AbsTol', 1e-12, ...
                'Save must normalize the panel normal vector.');
        end

        function blankChargeRateIsRejected(testCase)
            [panel, ~] = testCase.fixture();
            panel.refChargeRate = 4.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(panel, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.refChargeRateText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank charge rate must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFixedSolarPanelGUI));
            testCase.verifyEqual(panel.refChargeRate, 4.5, 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function zeroVectorIsRejected(testCase)
            [panel, ~] = testCase.fixture();
            panel.bodyFrameNormVect = [0; 1; 0];
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(panel, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.panelXText, 'String', '0');
            set(handles.panelYText, 'String', '0');
            set(handles.panelZText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero normal vector must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditFixedSolarPanelGUI));
            testCase.verifyEqual(panel.bodyFrameNormVect, [0; 1; 0], 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [panel, ~] = testCase.fixture();
            panel.refChargeRate = 4.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(panel, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedSolarPanelGUI;

            set(handles.refChargeRateText, 'String', '99');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(panel.refChargeRate, 4.5, 'AbsTol', 1e-12);
        end

        function windowClosePreservesModel(testCase)
            [panel, ~] = testCase.fixture();
            panel.refChargeRate = 4.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(panel, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditFixedSolarPanelGUI;

            set(handles.refChargeRateText, 'String', '99');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyEqual(panel.refChargeRate, 4.5, 'AbsTol', 1e-12);
        end
    end

    methods(Access=private)
        function [panel, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            panel = LaunchVehicleStaticSolarPanel(stg);
            panel.name = 'Test Fixed Panel';
            panel.refChargeRate = 4;
            panel.refChargeRateDist = 13599840.256;
            panel.bodyFrameNormVect = [0; 1; 0];
            stg.addPwrSrc(panel);
        end

        function app = openDialog(testCase, panel, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditFixedSolarPanelGUI_App(panel, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FixedSolarPanelDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Fixed Solar Panel')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Fixed Solar Panel')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
