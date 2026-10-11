classdef ConicalSensorHalfAngleActionDialogTest < KsptotTestCase
    %ConicalSensorHalfAngleActionDialogTest Full round-trip UI tests for
    %the conical-sensor half-angle action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetConicalSensorHalfAngleGUI_App.mlapp
    %   backing class: SetConicalSensorAngleAction
    %   (opens via SetConicalSensorAngleAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct.  This is a pure
    %   App Designer dialog (app.* properties, Items/ItemsData dropdown,
    %   half-angle shown in degrees).  The dialog is opened directly (not
    %   via openEditActionUI); the fixture seeds one conical and one
    %   rectangular sensor, mirroring the production guard that requires
    %   at least one conical sensor.
    %
    % COVERED
    %   Open shows the stored sensor and half angle (in degrees); the
    %   sensor dropdown offers only conical sensors; Save & Close writes
    %   sensor and angle back; a zero and a non-numeric half angle are
    %   rejected (valid range is 0.001 to 90 deg) and leave the model
    %   alone; Cancel preserves the model.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData, sensor] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyEqual(str2double(app.SensorHalfAngleText.Value), 25, 'AbsTol', 1e-12);
            testCase.verifyTrue(app.SensorCombo.Value == sensor, ...
                'The stored sensor must be selected.');
        end

        function sensorComboOffersOnlyConicalSensors(testCase)
            [action, lvdData, sensor] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            [~, sensors] = lvdData.sensors.getListboxStr();
            nConical = sum([sensors.typeEnum] == SensorEnum.ConicalSensor);
            testCase.verifyEqual(nConical, 1);
            testCase.verifyEqual(numel(app.SensorCombo.Items), nConical, ...
                'Only conical sensors must be offered.');
            testCase.verifyTrue(app.SensorCombo.Value == sensor);
        end

        function saveAndCloseWritesSensorAndAngle(testCase)
            [action, lvdData, sensor] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorHalfAngleText.Value = '30';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(action.sensorAngle, deg2rad(30), 'AbsTol', 1e-12);
            testCase.verifyTrue(action.sensor == sensor, ...
                'The sensor selection must be preserved.');
        end

        function zeroHalfAngleIsRejected(testCase)
            [action, lvdData, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorHalfAngleText.Value = '0';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero half angle must not save.');
            testCase.verifyTrue(isvalid(fig), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.sensorAngle, deg2rad(25), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function nonNumericHalfAngleIsRejected(testCase)
            [action, lvdData, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorHalfAngleText.Value = 'abc';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric half angle must not save.');
            testCase.verifyTrue(isvalid(fig), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.sensorAngle, deg2rad(25), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, ~] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorHalfAngleText.Value = '45';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyEqual(action.sensorAngle, deg2rad(25), 'AbsTol', 1e-12, ...
                'Cancel must leave the model alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData, sensor] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            steeringModel = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);

            sensor = ConicalSensor('Test Conical Sensor', deg2rad(15), 500, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(sensor);

            rectSensor = RectangularSensor('Test Rectangular Sensor', deg2rad(8), deg2rad(6), 400, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(rectSensor);

            action = SetConicalSensorAngleAction(sensor, deg2rad(25));
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetConicalSensorHalfAngleGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() ConicalSensorHalfAngleActionDialogTest.deleteIfValid(app));
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
