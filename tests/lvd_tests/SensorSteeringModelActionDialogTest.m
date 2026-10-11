classdef SensorSteeringModelActionDialogTest < KsptotTestCase
    %SensorSteeringModelActionDialogTest Full round-trip UI tests for the
    %sensor steering-model action editor (Phase 2: event actions).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/actionUIs/lvd_EditActionSetSensorSteeringModelGUI_App.mlapp
    %   backing class: SetSensorSteeringModelAction
    %   (opens via SetSensorSteeringModelAction.openEditActionUI).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  This modern dialog exposes its
    %   controls as app properties, so tests drive app.SensorCombo /
    %   app.PointingModelCombo directly and fire app.saveAndCloseButton.
    %   The EditPointingModelButton opens the nested steering-model editor
    %   and is deliberately never pressed here (it would block on its own
    %   uiwait); likewise the combo is never switched to FixedInCoordSys,
    %   whose zero-coordinate-system alert path is broken (see bug note).
    %
    % COVERED
    %   Open shows stored sensor/pointing model; Save & Close writes the
    %   selected sensor back and keeps the chosen steering model; Cancel
    %   and window-X preserve the model; both dropdowns mirror the
    %   scenario.  The dialog performs no validation, so there is no
    %   rejection case.
    %
    % FIXTURE
    %   The dialog guards the no-sensor case with a warndlg, so two conical
    %   sensors are seeded, mirroring
    %   EventActionTest.buildEntryWithConicalSensor.
    %
    % KNOWN PRODUCTION BUG (pinned, not fixed here)
    %   PointingModelComboValueChanged alerts through
    %   app.EditConicalSensorGUI, a figure that does not exist in this
    %   dialog (it should be app.EditActionUIFigure), so picking
    %   FixedInCoordSys with no coordinate system in the scenario errors
    %   instead of warning.  The stray SensorHalfAngleTextValueChanged
    %   callback references another missing control.  No test touches
    %   either path.

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
            testCase.verifyEqual(app.PointingModelCombo.Value, SensorSteeringModelEnum.FixedVehicleBodyFrame, ...
                'The stored fixed-in-vehicle-frame model must be shown.');
        end

        function combosOfferEveryOption(testCase)
            [action, lvdData] = testCase.fixture();
            app = testCase.openDialog(action, lvdData);

            [~, sensors] = lvdData.sensors.getListboxStr();
            testCase.verifyEqual(numel(app.SensorCombo.Items), numel(sensors), ...
                'Every scenario sensor must be offered.');
            testCase.verifyEqual(numel(app.PointingModelCombo.ItemsData), ...
                numel(enumeration('SensorSteeringModelEnum')), ...
                'Every steering-model type must be offered.');
        end

        function saveAndCloseWritesSensorAndKeepsModel(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            modelBefore = action.steeringModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            sensor2 = testCase.sensorAtInd(lvdData, 2);
            testCase.assertTrue(~(sensor2 == sensor1), 'Fixture must seed two distinct sensors.');
            app.SensorCombo.Value = sensor2;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyTrue(action.sensor == sensor2, 'Save must write the selected sensor.');
            testCase.verifyTrue(action.steeringModel == modelBefore, ...
                'Save must keep the selected steering model.');
        end

        function saveWithoutChangesRoundTrips(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            modelBefore = action.steeringModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyFalse(isvalid(fig));
            testCase.verifyTrue(action.sensor == sensor1, 'An unchanged save must keep the sensor.');
            testCase.verifyTrue(action.steeringModel == modelBefore, ...
                'An unchanged save must keep the steering model.');
        end

        function cancelPreservesModel(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            modelBefore = action.steeringModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorCombo.Value = testCase.sensorAtInd(lvdData, 2);
            testCase.pushButton(app.cancelButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Cancel must close the dialog.');
            testCase.verifyTrue(action.sensor == sensor1, 'Cancel must leave the sensor alone.');
            testCase.verifyTrue(action.steeringModel == modelBefore, ...
                'Cancel must leave the steering model alone.');
        end

        function windowClosePreservesModel(testCase)
            [action, lvdData, sensor1] = testCase.fixture();
            modelBefore = action.steeringModel;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(action, lvdData, out);
            fig = app.EditActionUIFigure;

            app.SensorCombo.Value = testCase.sensorAtInd(lvdData, 2);
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without Save must not report success.');
            testCase.verifyTrue(action.sensor == sensor1, 'Window-X must leave the sensor alone.');
            testCase.verifyTrue(action.steeringModel == modelBefore, ...
                'Window-X must leave the steering model alone.');
        end
    end

    methods(Access=private)
        function [action, lvdData, sensor1] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            origin = VehiclePoint('Sensor Origin');
            seedSteering = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor1 = ConicalSensor('Test Conical Sensor 1', deg2rad(15), 500, origin, seedSteering, lvdData);
            lvdData.sensors.addSensor(sensor1);
            sensor2 = ConicalSensor('Test Conical Sensor 2', deg2rad(20), 600, origin, seedSteering, lvdData);
            lvdData.sensors.addSensor(sensor2);

            model = FixedInVehicleFrameSensorSteeringModel(0.1, 0.2, 0.3, lvdData);
            action = SetSensorSteeringModelAction(sensor1, model);
        end

        function sensor = sensorAtInd(~, lvdData, ind)
            [~, sensors] = lvdData.sensors.getListboxStr();
            sensor = sensors(ind);
        end

        function app = openDialog(testCase, action, lvdData, out)
            if nargin < 4 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_EditActionSetSensorSteeringModelGUI_App(action, lvdData, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SensorSteeringModelActionDialogTest.deleteIfValid(app));
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
