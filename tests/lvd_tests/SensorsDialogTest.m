classdef SensorsDialogTest < KsptotTestCase
    %SensorsDialogTest Full round-trip UI tests for the sensors set editor
    %(Phase 4: sensors). This promotes the LvdMainGuiWidgetSmokeTest
    %open/cancel smoke coverage to value-level assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/sensors/sensor_models/lvd_EditSensorsGUI_App.mlapp
    %   ('Edit Sensors'; single-arg ctor (lvdData), no output arg -- Add /
    %   Remove write straight into lvdData.sensors and Close just closes).
    %   Add opens the listdlgARH_App picker (figure 'Select New Sensor
    %   Type') and then the single-sensor child editor (figure 'Edit
    %   Sensor'); production caller is the LVD main window sensor menu.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the TanksDialogTest
    %   pattern). The Add picker is stubbed with whenShown (the
    %   CalculusObjsDialogTest pattern); the child Save path is guarded on
    %   the mesh toolbox (see NOTES).
    %
    % COVERED
    %   Open lists the stored sensors and disables Remove when empty; Add
    %   with a nested Save appends the sensor (toolbox-guarded); Add with no
    %   geometric point alerts and adds nothing; Remove drops the selected
    %   sensor; Close preserves the model.
    %
    % NOTES
    %   The set dialog has no Save/Cancel/output: edits apply immediately,
    %   so "save" here is Add-via-Save and "cancel" is the no-point alert
    %   path. The single-sensor child (lvd_EditConicalSensorGUI_App)
    %   populates its 3-D preview via getSensorMesh, which needs
    %   rotm2axang/roty/sphereMesh -- all absent in this environment
    %   (SensorTest.m:36-43 documents the missing toolbox). The Save-path
    %   test therefore assumes those functions and SKIPS here; it will run
    %   wherever the toolboxes exist. No test propagates or renders.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredSensors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            s1 = testCase.makeConical(lvdData, 'Alpha');
            s2 = testCase.makeRectangular(lvdData, 'Beta');
            lvdData.sensors.addSensor(s1);
            lvdData.sensors.addSensor(s2);

            app = testCase.openDialog(lvdData);

            [strs, sensors] = lvdData.sensors.getListboxStr();
            testCase.verifyEqual(app.SensorsListBox.Items(:), strs(:), ...
                'The listbox must mirror the stored sensors.');
            testCase.verifyNumElements(app.SensorsListBox.ItemsData, 2);
            testCase.verifyTrue(app.SensorsListBox.ItemsData(1) == s1);
            testCase.verifyTrue(app.SensorsListBox.ItemsData(2) == s2);
            testCase.verifyEqual(numel(sensors), 2);
            testCase.verifyFalse(testCase.isOff(app.RemoveSensorButton), ...
                'Remove must enable when sensors exist.');
        end

        function emptySetDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.SensorsListBox.ItemsData, ...
                'The default mission ships with no sensors.');
            testCase.verifyTrue(testCase.isOff(app.RemoveSensorButton), ...
                'With nothing listed there is nothing to remove.');
        end

        function addSensorViaSaveAppendsSensor(testCase)
            testCase.assumeNotEmpty(which('roty'), ...
                'roty() unavailable; the single-sensor child cannot draw its preview.');
            testCase.assumeNotEmpty(which('rotm2axang'), ...
                'rotm2axang() unavailable; the single-sensor child cannot build its mesh.');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            app = testCase.openDialog(lvdData);

            testCase.fixture.whenShown('Select New Sensor Type', @(fig) SensorsDialogTest.pickConicalAndOk(fig));
            testCase.fixture.whenShown('Edit Sensor', @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));
            testCase.pushButton(app.AddSensorButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyNumElements(lvdData.sensors.sensors, 1, ...
                'A nested Save must keep the new sensor.');
            testCase.verifyNumElements(app.SensorsListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
            testCase.verifyFalse(testCase.isOff(app.RemoveSensorButton));
        end

        function addWithoutGeometricPointAlertsAndAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.assertEqual(lvdData.geometry.points.getNumPoints(), 0, ...
                'Fixture: the default mission must have no geometric points.');
            app = testCase.openDialog(lvdData);

            testCase.fixture.whenShown('Select New Sensor Type', @(fig) SensorsDialogTest.pickConicalAndOk(fig));
            testCase.pushButton(app.AddSensorButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEmpty(lvdData.sensors.sensors, ...
                'Without a geometric point the sensor cannot be built.');
            testCase.verifyEmpty(app.SensorsListBox.ItemsData);
            testCase.verifyTrue(isvalid(app.EditSensorsGUI), ...
                'The alert must leave the editor open.');
            testCase.closeAlerts();
        end

        function removeSensorDropsSelected(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            s1 = testCase.makeConical(lvdData, 'Alpha');
            s2 = testCase.makeRectangular(lvdData, 'Beta');
            lvdData.sensors.addSensor(s1);
            lvdData.sensors.addSensor(s2);
            app = testCase.openDialog(lvdData);

            app.SensorsListBox.Value = s2;
            drawnow;
            testCase.pushButton(app.RemoveSensorButton);

            testCase.verifyNumElements(lvdData.sensors.sensors, 1, 'Remove must drop the selected sensor.');
            testCase.verifyTrue(lvdData.sensors.getSensorAtInd(1) == s1, ...
                'The surviving sensor must be the unselected one.');
            testCase.verifyNumElements(app.SensorsListBox.ItemsData, 1, ...
                'The listbox must refresh after a remove.');
            testCase.verifyTrue(isvalid(app.EditSensorsGUI), ...
                'Removing must leave the editor open.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            lvdData.sensors.addSensor(testCase.makeConical(lvdData, 'Alpha'));
            app = testCase.openDialog(lvdData);
            fig = app.EditSensorsGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyNumElements(lvdData.sensors.sensors, 1, 'Close must leave the model alone.');
        end
    end

    methods(Access=private)
        function pt = seedPoint(testCase, lvdData)
            pt = FixedPointInFrame([0;0;0], testCase.kerbinFrame, 'origin', lvdData);
            lvdData.geometry.points.addPoint(pt);
        end

        function sensor = makeConical(~, lvdData, name)
            origin = lvdData.geometry.points.getPointAtInd(1);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor(name, deg2rad(10), 1000, origin, steer, lvdData);
        end

        function sensor = makeRectangular(~, lvdData, name)
            origin = lvdData.geometry.points.getPointAtInd(1);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = RectangularSensor(name, deg2rad(10), deg2rad(5), 1000, origin, steer, lvdData);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditSensorsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SensorsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function tf = isOff(~, comp)
            tf = strcmpi(string(comp.Enable), 'off');
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Sensors')
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
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Sensors') || ...
                        strcmp(figs(i).Name, 'Select New Sensor Type') || ...
                        strcmp(figs(i).Name, 'Edit Sensor'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function pickConicalAndOk(fig)
            lbs = findall(fig, 'Type', 'uilistbox');
            lb = lbs(1);
            idx = find(strcmp(lb.Items, 'Conical Sensor'), 1);
            if isempty(idx)
                idx = 1;
            end
            lb.Value = lb.Items{idx};
            drawnow;
            UiwaitInterceptorFixture.pushButton(fig, 'OK');
        end
    end
end
