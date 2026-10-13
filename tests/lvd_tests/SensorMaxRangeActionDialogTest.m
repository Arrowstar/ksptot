classdef SensorMaxRangeActionDialogTest < KsptotTestCase
    %SensorMaxRangeActionDialogTest Full round-trip UI tests for the sensor
    %max-range action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetSensorMaxRangeGUI_App.mlapp
    %   backing class: SetSensorMaxRangeAction
    %   (opens via SetSensorMaxRangeAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  This modern dialog exposes its
    %   controls as app properties, so tests drive app.SensorCombo /
    %   app.SensorMaxRange directly and fire app.saveAndCloseButton.
    %
    % COVERED
    %   Open shows stored sensor/range; Save & Close writes both back; a
    %   blank range and a negative range are rejected and leave the model
    %   alone; Cancel and window-X preserve the model; the sensor dropdown
    %   mirrors the scenario sensors.
    %
    % FIXTURE
    %   The dialog guards the no-sensor case with a warndlg, so two conical
    %   sensors are seeded, mirroring
    %   EventActionTest.buildEntryWithConicalSensor.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyTrue(app.SensorCombo.Value == sensor1, ...
                'The sensor dropdown must point at the stored sensor.');
            testCase.verifyEqual(str2double(app.SensorMaxRange.Value), 750, 'AbsTol', 1e-9, ...
                'The stored max range must be shown in km.');
        end

        function sensorComboOffersEverySensor(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            [~, sensors] = lvdData.sensors.getListboxStr();
            testCase.verifyEqual(numel(app.SensorCombo.Items), numel(sensors), ...
                'Every scenario sensor must be offered.');
        end

        function saveAndCloseWritesSensorAndRange(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            sensor2 = testCase.sensorAtInd(lvdData, 2);
            testCase.assertTrue(~(sensor2 == sensor1), 'Fixture must seed two distinct sensors.');
            app.SensorCombo.Value = sensor2;
            app.SensorMaxRange.Value = '1200';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.sensor == sensor2, 'Save must write the selected sensor.');
            testCase.verifyEqual(action.sensorMaxRange, 1200, 'AbsTol', 1e-12, ...
                'Save must write the entered range.');
        end

        function blankRangeIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.SensorMaxRange.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank range must not save.');
            testCase.verifyTrue(isvalid(app.EditActionUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.sensorMaxRange, 750, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeRangeIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.SensorMaxRange.Value = '-5';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative range must not save.');
            testCase.verifyTrue(isvalid(app.EditActionUIFigure));
            testCase.verifyEqual(action.sensorMaxRange, 750, 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorCombo.Value = testCase.sensorAtInd(lvdData, 2);
            app.SensorMaxRange.Value = '999';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.sensor == sensor1, 'Cancel must leave the sensor alone.');
            testCase.verifyEqual(action.sensorMaxRange, 750, 'AbsTol', 1e-12, ...
                'Cancel must leave the range alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorMaxRange.Value = '999';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.sensor == sensor1, 'Window-X must leave the sensor alone.');
            testCase.verifyEqual(action.sensorMaxRange, 750, 'AbsTol', 1e-12, ...
                'Window-X must leave the range alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData, sensor1] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            steeringModel = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor1 = ConicalSensor('Test Conical Sensor 1', deg2rad(15), 500, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor1);
            sensor2 = ConicalSensor('Test Conical Sensor 2', deg2rad(20), 600, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor2);

            action = SetSensorMaxRangeAction(sensor1, 750);
        end

        function sensor = sensorAtInd(~, lvdData, ind)
            [~, sensors] = lvdData.sensors.getListboxStr();
            sensor = sensors(ind);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetSensorMaxRangeGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SensorMaxRangeActionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Action')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Action')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
