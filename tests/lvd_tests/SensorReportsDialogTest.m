classdef SensorReportsDialogTest < KsptotTestCase
    %SensorReportsDialogTest Full round-trip UI tests for the sensor-reports
    %window (Phase 4: sensors). This promotes the
    %LvdMainGuiWidgetSmokeTest alert-path smoke coverage to value-level
    %assertions.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/sensors/reports/lvd_SensorReports.mlapp
    %   ('Sensor Reports'; single-arg ctor (lvdData), uiwait, no output arg).
    %   production caller is the LVD main window sensor-reports menu.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app. This modern dialog
    %   exposes its controls as app properties (app.SensorsListbox,
    %   app.TargetsListbox, app.GenerateReportButton, ...), so tests drive
    %   those directly and fire buttons through their ButtonPushedFcn.
    %
    % COVERED
    %   Empty mission lists empty sensors/targets; a seeded sensor+target
    %   are listed and pre-selected; a hand-built SensorTargetResults pins
    %   the coverage-fraction content the reports summarise; the output
    %   instructions tab describes the worksheets; the data-viewer controls
    %   exist with Plot starting disabled; Generate with an empty selection
    %   keeps the alert path and leaves the window open; close preserves the
    %   model.
    %
    % NOTES
    %   Generate is deliberately NEVER pressed with a seeded selection: it
    %   would run evaluateSensorTargets (mesh toolbox, absent here per
    %   SensorTest.m:36-43), propagate-dependent state-log reads and XLS
    %   file I/O. The seeded "report content" is therefore the listbox
    %   content plus the instructions text plus the coverage oracle below,
    %   all without propagation or rendering.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function defaultMissionHasNoSensorsOrTargets(testCase)
            %Model-level only: opening the dialog with empty lists crashes
            %populate (bug log 4B.5); production guards this via the menu
            %alert path (see LvdMainGuiWidgetSmokeTest.sensorReportsAlertsWhenEmpty).
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.verifyEmpty(lvdData.sensors.sensors, ...
                'The default mission ships with no sensors.');
            testCase.verifyEmpty(lvdData.sensorTgts.targets, ...
                'The default mission ships with no sensor targets.');
        end

        function seededMissionListsSensorAndTarget(testCase)
            [lvdData, sensor, tgt] = testCase.seededFixture();
            app = testCase.openDialog(lvdData);

            [senStrs, sensors] = lvdData.sensors.getListboxStr();
            [tgtStrs, targets] = lvdData.sensorTgts.getListboxStr();
            testCase.verifyEqual(app.SensorsListbox.Items(:), senStrs(:), ...
                'The sensors listbox must mirror the stored sensors.');
            testCase.verifyEqual(app.TargetsListbox.Items(:), tgtStrs(:), ...
                'The targets listbox must mirror the stored targets.');
            testCase.verifyNumElements(app.SensorsListbox.ItemsData, 1);
            testCase.verifyTrue(app.SensorsListbox.ItemsData(1) == sensor);
            testCase.verifyNumElements(app.TargetsListbox.ItemsData, 1);
            testCase.verifyTrue(app.TargetsListbox.ItemsData(1) == tgt);
            testCase.verifyTrue(app.SensorsListbox.Value == sensor, ...
                'Populate pre-selects every sensor.');
            testCase.verifyTrue(app.TargetsListbox.Value == tgt, ...
                'Populate pre-selects every target.');
            testCase.verifyEqual(numel(sensors), 1);
            testCase.verifyEqual(numel(targets), 1);
            testCase.verifyTrue(contains(char(app.ReportOutputFolderLabel.Text), 'Report Output Folder'));
        end

        function seededCoverageFractionOracle(testCase)
            %The number the reports summarise: 3 of 4 points visible is a
            %coverage fraction of 0.75 (SensorTest.m:678-688 pattern). Kept
            %at the model level so no propagation or mesh is needed.
            [lvdData, sensor, tgt] = testCase.seededFixture();
            rVects = [1 2 3; 4 5 6; 7 8 9; 10 11 12];
            res = SensorTargetResults(sensor, tgt, 0, [0;0;0], ...
                logical([1;0;1;1]), rVects, testCase.kerbinFrame);

            testCase.verifyEqual(res.getCoverageFraction(), 0.75, 'AbsTol', 1e-12, ...
                '3 of 4 visible points must give a coverage fraction of 0.75.');
        end

        function outputInstructionsTabDescribesWorksheets(testCase)
            [lvdData, ~, ~] = testCase.seededFixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(isvalid(app.OutputInstructionsTab));
            body = strjoin(cellstr(app.Label2.Text), ' ');
            testCase.verifyTrue(contains(body, 'Coverage'), ...
                'The instructions must describe the coverage worksheet.');
            testCase.verifyTrue(contains(body, 'Azimuth'), ...
                'The instructions must describe the azimuth worksheet.');
        end

        function dataViewerControlsExistAndPlotStartsDisabled(testCase)
            [lvdData, ~, ~] = testCase.seededFixture();
            app = testCase.openDialog(lvdData);

            testCase.verifyTrue(isvalid(app.DataViewerTab));
            testCase.verifyTrue(isvalid(app.DataPanel));
            testCase.verifyTrue(isvalid(app.dataAxes));
            testCase.verifyTrue(isvalid(app.SensorDataCombo));
            testCase.verifyTrue(isvalid(app.TargetDataCombo));
            testCase.verifyTrue(isvalid(app.DataTypeCombo));
            testCase.verifyTrue(isvalid(app.DataSetListbox));
            testCase.verifyTrue(isvalid(app.PlotDataButton));
            testCase.verifyTrue(testCase.isOff(app.PlotDataButton), ...
                'Plot must start disabled: there is no generated data yet.');
            testCase.verifyTrue(isvalid(app.GenerateReportTab));
            testCase.verifyTrue(isvalid(app.SensorsPanel));
            testCase.verifyTrue(isvalid(app.TargetsPanel));
        end

        function generateWithEmptySelectionKeepsAlertPath(testCase)
            [lvdData, ~, ~] = testCase.seededFixture();
            app = testCase.openDialog(lvdData);
            fig = app.SensorReportFigureGUI;

            app.SensorsListbox.Value = {};
            app.TargetsListbox.Value = {};
            drawnow;
            testCase.pushButton(app.GenerateReportButton);

            testCase.verifyTrue(isvalid(fig), ...
                'The empty-selection alert must leave the window open.');
            testCase.closeAlerts();
        end

        function closePreservesModel(testCase)
            [lvdData, ~, ~] = testCase.seededFixture();
            app = testCase.openDialog(lvdData);
            fig = app.SensorReportFigureGUI;

            close(fig);
            drawnow;

            testCase.verifyNumElements(lvdData.sensors.sensors, 1, 'Close must leave the sensors alone.');
            testCase.verifyNumElements(lvdData.sensorTgts.targets, 1, 'Close must leave the targets alone.');
        end
    end

    methods(Access=private)
        function [lvdData, sensor, tgt] = seededFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            originPt = FixedPointInFrame([0;0;0], testCase.kerbinFrame, 'origin', lvdData);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('Report Sensor', deg2rad(10), 1000, originPt, steer, lvdData);
            lvdData.sensors.addSensor(sensor);
            tgtPt = FixedPointInFrame([100;0;0], testCase.kerbinFrame, 'tgtPt', lvdData);
            tgt = PointSensorTargetModel('Report Target', tgtPt, lvdData);
            lvdData.sensorTgts.addTarget(tgt);
        end

        function app = openDialog(testCase, lvdData)
            app = lvd_SensorReports(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SensorReportsDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Sensor Reports')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Sensor Reports')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
