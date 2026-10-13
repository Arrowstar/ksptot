classdef RectSensorDecActionDialogTest < KsptotTestCase
    %RectSensorDecActionDialogTest Full round-trip UI tests for the
    %rectangular-sensor declination-angle action editor (Phase 2: actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetRectangularSensorDecAngleGUI_App.mlapp
    %   backing class: SetRectangularlSensorDecAngleAction
    %   (opens via SetRectangularlSensorDecAngleAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  This modern dialog exposes its
    %   controls as app properties, so tests drive app.SensorCombo /
    %   app.SensorDecAngleText directly and fire app.saveAndCloseButton.
    %
    % COVERED
    %   Open shows stored sensor/angle; Save & Close writes both back; a
    %   blank angle and an out-of-range angle are rejected and leave the
    %   model alone; Cancel and window-X preserve the model; the sensor
    %   dropdown offers only rectangular sensors.
    %
    % FIXTURE
    %   The dialog guards the no-rectangular-sensor case with a warndlg, so
    %   two rectangular sensors are seeded (plus one conical sensor to pin
    %   the type filter), mirroring EventActionTest sensor fixtures.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [action, lvdData, rect1] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyTrue(app.SensorCombo.Value == rect1, ...
                'The sensor dropdown must point at the stored sensor.');
            testCase.verifyEqual(str2double(app.SensorDecAngleText.Value), 12, 'AbsTol', 1e-9, ...
                'The stored declination angle must be shown in degrees.');
        end

        function sensorComboOffersOnlyRectangularSensors(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            testCase.verifyEqual(numel(app.SensorCombo.Items), 2, ...
                'Both rectangular sensors (and no conical sensor) must be offered.');
            testCase.verifyTrue(all([app.SensorCombo.ItemsData.typeEnum] == SensorEnum.RectangularSensor), ...
                'Only rectangular sensors must be offered.');
        end

        function saveAndCloseWritesSensorAndAngle(testCase)
            [action, lvdData, rect1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            rect2 = testCase.rectSensorAtInd(lvdData, 2);
            testCase.assertTrue(~(rect2 == rect1), 'Fixture must seed two distinct sensors.');
            app.SensorCombo.Value = rect2;
            app.SensorDecAngleText.Value = '25';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.sensor == rect2, 'Save must write the selected sensor.');
            testCase.verifyEqual(action.sensorDecAngle, deg2rad(25), 'AbsTol', 1e-12, ...
                'Save must write the angle converted to radians.');
        end

        function blankAngleIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.SensorDecAngleText.Value = '';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A blank angle must not save.');
            testCase.verifyTrue(isvalid(app.EditActionUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(action.sensorDecAngle, deg2rad(12), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function outOfRangeAngleIsRejected(testCase)
            [action, lvdData] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);

            app.SensorDecAngleText.Value = '0';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero angle (below 0.001 deg) must not save.');
            testCase.verifyTrue(isvalid(app.EditActionUIFigure));
            testCase.verifyEqual(action.sensorDecAngle, deg2rad(12), 'AbsTol', 1e-12, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, rect1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorCombo.Value = testCase.rectSensorAtInd(lvdData, 2);
            app.SensorDecAngleText.Value = '45';
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.sensor == rect1, 'Cancel must leave the sensor alone.');
            testCase.verifyEqual(action.sensorDecAngle, deg2rad(12), 'AbsTol', 1e-12, ...
                'Cancel must leave the angle alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData, rect1] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorDecAngleText.Value = '45';
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.sensor == rect1, 'Window-X must leave the sensor alone.');
            testCase.verifyEqual(action.sensorDecAngle, deg2rad(12), 'AbsTol', 1e-12, ...
                'Window-X must leave the angle alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData, rect1] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            steeringModel = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            rect1 = RectangularSensor('Test Rectangular Sensor 1', deg2rad(8), deg2rad(12), 400, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(rect1);
            rect2 = RectangularSensor('Test Rectangular Sensor 2', deg2rad(10), deg2rad(7), 500, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(rect2);
            conical = ConicalSensor('Test Conical Sensor', deg2rad(15), 500, origin, steeringModel, lvdData);
            lvdData.sensors.addSensor(conical);

            action = SetRectangularlSensorDecAngleAction(rect1, deg2rad(12));
        end

        function sensor = rectSensorAtInd(~, lvdData, ind)
            [~, sensors] = lvdData.sensors.getListboxStr();
            rects = sensors([sensors.typeEnum] == SensorEnum.RectangularSensor);
            sensor = rects(ind);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetRectangularSensorDecAngleGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() RectSensorDecActionDialogTest.deleteIfValid(app));
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
