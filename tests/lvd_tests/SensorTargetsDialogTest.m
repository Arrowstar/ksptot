classdef SensorTargetsDialogTest < KsptotTestCase
    %SensorTargetsDialogTest Full round-trip UI tests for the sensor-targets
    %set editor (Phase 4: sensors). This promotes the
    %LvdMainGuiWidgetSmokeTest open/cancel smoke coverage to value-level
    %assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/sensors/target_models/lvd_EditSensorTargetsGUI_App.mlapp
    %   ('Edit Sensor Targets'; single-arg ctor (lvdData), no output arg --
    %   Add / Remove write straight into lvdData.sensorTgts and Close just
    %   closes). Add opens the listdlgARH_App picker (figure 'Select New
    %   Sensor Target') and then the
    %   single-target child editor (figure 'Edit Sensor Target');
    %   production caller is the LVD main window sensor-target menu.
    %   (Fixed bug 4B.1: picker was titled 'Select New Sensor Type'.)
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the TanksDialogTest
    %   pattern). Both the picker and the child are stubbed with whenShown
    %   (the CalculusObjsDialogTest pattern).
    %
    % COVERED
    %   Open lists the stored targets and disables Remove when empty; Add
    %   (stubbed picker plus stubbed child) appends one lat/long
    %   rectangular grid and refreshes the listbox; Add with a nested Cancel
    %   adds nothing; Remove drops the selection; Close preserves the model.
    %
    % NOTES
    %   The set dialog has no Save/Cancel/output: edits apply immediately.
    %   The grid child editors do not draw on open (updateDispAxes runs only
    %   on field edits), so the stubbed Save path is headless-safe, unlike
    %   the sensor editors. No test propagates or renders.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogListsStoredTargets(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            t1 = testCase.makePointTarget(lvdData, 'Pad Tracker');
            t2 = testCase.makeRectGrid(lvdData, 'Survey Grid');
            lvdData.sensorTgts.addTarget(t1);
            lvdData.sensorTgts.addTarget(t2);

            app = testCase.openDialog(lvdData);

            [strs, targets] = lvdData.sensorTgts.getListboxStr();
            testCase.verifyEqual(app.SensorTargetsListBox.Items(:), strs(:), ...
                'The listbox must mirror the stored targets.');
            testCase.verifyNumElements(app.SensorTargetsListBox.ItemsData, 2);
            testCase.verifyTrue(app.SensorTargetsListBox.ItemsData(1) == t1);
            testCase.verifyTrue(app.SensorTargetsListBox.ItemsData(2) == t2);
            testCase.verifyEqual(numel(targets), 2);
            testCase.verifyFalse(testCase.isOff(app.RemoveTargetButton), ...
                'Remove must enable when targets exist.');
        end

        function emptySetDisablesRemove(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.verifyEmpty(app.SensorTargetsListBox.ItemsData, ...
                'The default mission ships with no sensor targets.');
            testCase.verifyTrue(testCase.isOff(app.RemoveTargetButton), ...
                'With nothing listed there is nothing to remove.');
        end

        function addRectGridViaSaveAppendsTarget(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.fixture.whenShown('Select New Sensor Target', @(fig) SensorTargetsDialogTest.pickRectGridAndOk(fig));
            testCase.fixture.whenShown('Edit Sensor Target', @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));
            testCase.pushButton(app.AddTargetButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyNumElements(lvdData.sensorTgts.targets, 1, ...
                'A nested Save must keep the new target.');
            testCase.verifyClass(lvdData.sensorTgts.targets(1), 'BodyFixedLatLongGridTargetModel', ...
                'The stubbed picker must build the lat/long rectangular grid.');
            testCase.verifyNumElements(app.SensorTargetsListBox.ItemsData, 1, ...
                'The listbox must refresh after an add.');
            testCase.verifyFalse(testCase.isOff(app.RemoveTargetButton));
        end

        function addViaCancelAddsNothing(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openDialog(lvdData);

            testCase.fixture.whenShown('Select New Sensor Target', @(fig) SensorTargetsDialogTest.pickRectGridAndOk(fig));
            testCase.fixture.whenShown('Edit Sensor Target', @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Cancel'));
            testCase.pushButton(app.AddTargetButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEmpty(lvdData.sensorTgts.targets, 'A nested Cancel must drop the new target.');
            testCase.verifyEmpty(app.SensorTargetsListBox.ItemsData);
            testCase.verifyTrue(testCase.isOff(app.RemoveTargetButton));
        end

        function removeTargetDropsSelected(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            t1 = testCase.makePointTarget(lvdData, 'Pad Tracker');
            t2 = testCase.makeRectGrid(lvdData, 'Survey Grid');
            lvdData.sensorTgts.addTarget(t1);
            lvdData.sensorTgts.addTarget(t2);
            app = testCase.openDialog(lvdData);

            app.SensorTargetsListBox.Value = t2;
            drawnow;
            testCase.pushButton(app.RemoveTargetButton);

            testCase.verifyNumElements(lvdData.sensorTgts.targets, 1, 'Remove must drop the selected target.');
            testCase.verifyTrue(lvdData.sensorTgts.getPointAtInd(1) == t1, ...
                'The surviving target must be the unselected one.');
            testCase.verifyNumElements(app.SensorTargetsListBox.ItemsData, 1, ...
                'The listbox must refresh after a remove.');
            testCase.verifyTrue(isvalid(app.EditSensorTargetsGUI), ...
                'Removing must leave the editor open.');
        end

        function closeButtonPreservesModel(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.seedPoint(lvdData);
            lvdData.sensorTgts.addTarget(testCase.makePointTarget(lvdData, 'Pad Tracker'));
            app = testCase.openDialog(lvdData);
            fig = app.EditSensorTargetsGUI;

            testCase.pushButton(app.closeButton);

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyNumElements(lvdData.sensorTgts.targets, 1, 'Close must leave the model alone.');
        end
    end

    methods(Access=private)
        function pt = seedPoint(testCase, lvdData)
            pt = FixedPointInFrame([0;0;0], testCase.kerbinFrame, 'origin', lvdData);
            lvdData.geometry.points.addPoint(pt);
        end

        function tgt = makePointTarget(~, lvdData, name)
            pt = lvdData.geometry.points.getPointAtInd(1);
            tgt = PointSensorTargetModel(name, pt, lvdData);
        end

        function tgt = makeRectGrid(testCase, lvdData, name)
            bodyInfo = LvdData.getDefaultInitialBodyInfo(lvdData.celBodyData);
            tgt = BodyFixedLatLongGridTargetModel(name, bodyInfo, ...
                deg2rad(-30), deg2rad(-30), deg2rad(30), deg2rad(30), 10, 10, 1, lvdData);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_EditSensorTargetsGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SensorTargetsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function tf = isOff(~, comp)
            tf = strcmpi(string(comp.Enable), 'off');
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && (strcmp(figs(i).Name, 'Edit Sensor Targets') || ...
                        strcmp(figs(i).Name, 'Select New Sensor Target') || ...
                        strcmp(figs(i).Name, 'Edit Sensor Target'))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end

        function pickRectGridAndOk(fig)
            lbs = findall(fig, 'Type', 'uilistbox');
            lb = lbs(1);
            idx = find(strcmp(lb.Items, 'Lat/Long Rectangular Grid'), 1);
            if isempty(idx)
                idx = 1;
            end
            lb.Value = lb.Items{idx};
            drawnow;
            UiwaitInterceptorFixture.pushButton(fig, 'OK');
        end
    end
end
