classdef SimplePowerSinkDialogTest < KsptotTestCase
    %SimplePowerSinkDialogTest Full round-trip UI tests for the single
    %simple power sink editor (Phase 3: vehicle electrical).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/editLaunchVehicleUIs/electrical/power_sink/lvd_EditSimplePowerSinkGUI_App.mlapp
    %   backing class: LaunchVehicleSimplePwrSink
    %   production caller: LaunchVehicleSimplePwrSink.openEditDialog
    %   (helper_methods/ksptot_lvd/classes/LaunchVehicle/electrical/power_sink/@LaunchVehicleSimplePwrSink/LaunchVehicleSimplePwrSink.m:40-42).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The sink rate is stored
    %   negative; the dialog shows the positive discharge rate.
    %
    % COVERED
    %   Open shows stored name/stage/discharge; Save & Close writes every
    %   field back (negating the discharge); blank and negative discharges
    %   are rejected; Cancel and window-X preserve the model; the stage
    %   dropdown mirrors the vehicle stages.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [sink, lvdData] = testCase.fixture();
            sink.name = 'Hull Drain';
            sink.pwrRate = -2.5;

            app = testCase.openDialog(sink, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.sinkNameText.String, 'Hull Drain');
            testCase.verifyEqual(str2double(get(handles.dischargeRateText, 'String')), 2.5, 'AbsTol', 1e-12, ...
                'The dialog must show the positive discharge rate.');
            testCase.verifyEqual(get(handles.stageCombo, 'Value'), 1);
        end

        function stageComboOffersEveryStage(testCase)
            [sink, lvdData] = testCase.fixture();
            app = testCase.openDialog(sink, lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            [~, stages] = lvdData.launchVehicle.getStagesListBoxStr();
            testCase.verifyEqual(numel(cellstr(get(handles.stageCombo, 'String'))), numel(stages), ...
                'Every vehicle stage must be offered.');
        end

        function saveAndCloseWritesEveryField(testCase)
            [sink, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sink, lvdData, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSimplePowerSinkGUI;

            handles.sinkNameText.String = 'Renamed Sink';
            set(handles.dischargeRateText, 'String', '3.5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(sink.name, 'Renamed Sink');
            testCase.verifyEqual(sink.pwrRate, -3.5, 'AbsTol', 1e-12, ...
                'Save must negate the discharge back to a sink rate.');
        end

        function blankDischargeIsRejected(testCase)
            [sink, ~] = testCase.fixture();
            sink.pwrRate = -2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sink, [], out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.dischargeRateText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank discharge must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditSimplePowerSinkGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(sink.pwrRate, -2.5, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeDischargeIsRejected(testCase)
            [sink, ~] = testCase.fixture();
            sink.pwrRate = -2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sink, [], out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.dischargeRateText, 'String', '-1');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative discharge must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_EditSimplePowerSinkGUI));
            testCase.verifyEqual(sink.pwrRate, -2.5, 'AbsTol', 1e-12);
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [sink, ~] = testCase.fixture();
            sink.pwrRate = -2.5;
            sink.name = 'Keep Me';
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sink, [], out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSimplePowerSinkGUI;

            handles.sinkNameText.String = 'Changed';
            set(handles.dischargeRateText, 'String', '9');
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(sink.name, 'Keep Me');
            testCase.verifyEqual(sink.pwrRate, -2.5, 'AbsTol', 1e-12);
        end

        function windowClosePreservesModel(testCase)
            [sink, ~] = testCase.fixture();
            sink.pwrRate = -2.5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(sink, [], out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_EditSimplePowerSinkGUI;

            set(handles.dischargeRateText, 'String', '9');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyEqual(sink.pwrRate, -2.5, 'AbsTol', 1e-12, ...
                'Window-X must leave the model alone.');
        end
    end

    methods(Access=private)
        function [sink, lvdData] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            stg = lvdData.launchVehicle.stages(1);
            sink = LaunchVehicleSimplePwrSink(stg);
            sink.name = 'Test Power Sink';
            sink.pwrRate = -2;
            stg.addPwrSink(sink);
        end

        function app = openDialog(testCase, sink, ~, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditSimplePowerSinkGUI_App(sink, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SimplePowerSinkDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Simple Power Sink')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Simple Power Sink')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
