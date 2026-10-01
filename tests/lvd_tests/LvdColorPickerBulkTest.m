classdef LvdColorPickerBulkTest < matlab.uitest.TestCase
    %LvdColorPickerBulkTest Free RGB pickers on every converted LVD dialog.
    %
    % Companion to EventColorPickerTest (which covers the event-only pilot
    % slice): one test per editor dialog converted in the bulk phase, each
    % driving every color picker on that dialog through the shared
    % lvdSetupColorPicker seam. Save-style dialogs stub the modal
    % uisetcolor via the fig-level lvdColorPickerFcn appdata, press the
    % runtime "Choose..." button with an App Testing Framework gesture,
    % press Save & Close, and verify the stored 1x3 RGB. Live-write
    % dialogs (ground objects, graphical analysis, view settings) verify
    % the object is updated on pick with no save step. A final group
    % covers loadobj migration for classes with required constructor
    % arguments and the grey-background helper.
    %
    % Dialogs block in uiwait; UiwaitInterceptorFixture stands in for
    % uiwait so constructors return the live app.

    properties(Access = private)
        celBodyData
        kerbinFrame
        fixture UiwaitInterceptorFixture
        figuresBefore
    end

    methods(TestClassSetup)
        function loadBodies(testCase)
            testCase.celBodyData = ksptotTestBodyData();
            testCase.kerbinFrame = testCase.celBodyData.kerbin.getBodyCenteredInertialFrame();
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)
        %% ------------------------------------------- .m programmatic UIs

        function unitVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            u = UnitVector(g.v1, 'u', lvdData);
            lvdData.geometry.vectors.addVector(u);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditUnitVectorGUI_App(u, lvdData, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
            testCase.checkSavePicker(app.UIFigure, 'lineColor', @() u.lineColor);
        end

        function vectorSumDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            s = VectorSumVector(g.v1, g.v2, 's', lvdData);
            lvdData.geometry.vectors.addVector(s);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditVectorSumVectorGUI_App(s, lvdData, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
            testCase.checkSavePicker(app.UIFigure, 'lineColor', @() s.lineColor);
        end

        function twoPlaneAngleDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            a = TwoPlaneAngle(g.pl1, g.pl2, 'a', lvdData);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditTwoPlaneAngleGUI_App(a, lvdData, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
            testCase.checkSavePicker(app.UIFigure, 'lineColor', @() a.lineColor);
        end

        function vectorPlaneIntersectionDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            pt = VectorPlaneIntersectionPoint(g.p1, g.v1, g.pl1, 'x', lvdData);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditVectorPlaneIntersectionPointGUI_App(pt, lvdData, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
            fig = app.UIFigure;
            %both pickers keep independent pending state; one save writes both
            testCase.stagePicker(fig, 'markerColor', [0.2, 0.4, 0.6]);
            testCase.stagePicker(fig, 'trkLineColor', [0.9, 0.1, 0.1]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(pt.markerColor, [0.2, 0.4, 0.6], 'AbsTol', 1e-12);
            testCase.verifyEqual(pt.trkLineColor, [0.9, 0.1, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function ephemerisPointDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            pt = EphemerisFilePoint('', g.frame, 'e', lvdData);
            pt.setTable([0, 10, 20], repmat([7000; 0; 0; 0; 7.5; 0], 1, 3));
            out = AppDesignerGUIOutput({false});

            app = lvd_EditEphemerisFilePointGUI_App(pt, lvdData, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
            %save requires a readable CSV on disk; point it at a temp table
            csv = [tempname(), '.csv'];
            writematrix([(0:10:20)', repmat([7000, 0, 0, 0, 7.5, 0], 3, 1)], csv);
            testCase.addTeardown(@() deleteIfExists(csv));
            app.filePathText.Value = csv;
            testCase.checkSavePicker(app.UIFigure, 'markerColor', @() pt.markerColor);
        end

        %% --------------------------------------- mlapp geometry editors

        function twoVectorAngleDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            a = TwoVectorAngle(g.v1, g.v2, 'a', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditTwoVectorAngleGUI_App(a, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditTwoVectorAngleGUI, 'lineColor', @() a.lineColor, []);
        end

        function vectorPlaneAngleDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            a = VectorPlaneAngle(g.v1, g.pl1, 'a', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditVectorPlaneAngleGUI_App(a, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditVectorPlaneAngleGUI, 'lineColor', @() a.lineColor, []);
        end

        function pointVectorPlaneDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            pl = PointVectorPlane(g.p1, g.v1, 'pl', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditPointVectorPlaneGUI_App(pl, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditPointVectorPlaneGUI, 'lineColor', @() pl.lineColor, []);
        end

        function threePointPlaneDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            pl = ThreePointPlane(g.p1, g.p2, g.p3, 'pl', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditThreePointPlaneGUI_App(pl, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditThreePointPlaneGUI, 'lineColor', @() pl.lineColor, []);
        end

        function fixedInFramePointDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            app = testCase.openGuideDialog(@(out) lvd_EditFixedInFramePointGUI_App(g.p1, lvdData, out));
            fig = app.lvd_EditFixedInFramePointGUI;
            testCase.stagePicker(fig, 'markerColor', [0.2, 0.4, 0.6]);
            testCase.stagePicker(fig, 'trkLineColor', [0.9, 0.1, 0.1]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(g.p1.markerColor, [0.2, 0.4, 0.6], 'AbsTol', 1e-12);
            testCase.verifyEqual(g.p1.trkLineColor, [0.9, 0.1, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function lagrangePointDialogPicker(testCase)
            [lvdData, ~] = testCase.geoFixture();
            frame = TwoBodyRotatingFrame(testCase.celBodyData.kerbin, testCase.celBodyData.mun, TwoBodyRotatingFrameOriginEnum.Primary, testCase.celBodyData);
            pt = LagrangeGeometricPoint(LagrangeGeometricPointEnum.L4, frame, lvdData, 'lag');
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditLagrangePointGUI_App(pt, lvdData, out));
            testCase.checkSavePicker(app.EditPointUIFigure, 'markerColor', @() pt.markerColor);
        end

        function lvdTrajectoryPointDialogPicker(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            inputLvd = LvdData.getDefaultLvdData(testCase.celBodyData);
            pt = LvdDataPoint(inputLvd, lvdData, 'tp');
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditLvdTrajectoryPointGUI_App(pt, out, lvdData));
            testCase.checkSavePicker(app.lvd_EditLvdTrajectoryPointGUI, 'markerColor', @() pt.markerColor);
        end

        function twoBodyPointDialogPicker(testCase)
            %TwoBodyPoint.save refreshes its trajectory cache, which needs a
            %propagated mission behind the dialog.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, ...
                testCase.celBodyData.kerbin.radius + 300, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(10);
            evt.propagatorObj = evt.twoBodyPropagator;
            lvdData.script.executeScript(false, evt, false, false, false, false, false);
            kep = KeplerianElementSet(0, testCase.celBodyData.kerbin.radius + 300, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);
            pt = TwoBodyPoint(kep, 'tb', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditTwoBodyPointGUI_App(pt, lvdData, out));
            fig = app.lvd_EditTwoBodyPointGUI;
            testCase.stagePicker(fig, 'markerColor', [0.2, 0.4, 0.6]);
            testCase.stagePicker(fig, 'trkLineColor', [0.9, 0.1, 0.1]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(pt.markerColor, [0.2, 0.4, 0.6], 'AbsTol', 1e-12);
            testCase.verifyEqual(pt.trkLineColor, [0.9, 0.1, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function coordSysOriginRefFrameDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            rf = CoordSysPointRefFrame(g.cs, g.p1, 'rf', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditCoordSysOriginRefFrameGUI_App(rf, lvdData, out));
            fig = app.lvd_EditCoordSysOriginRefFrameGUI;
            testCase.stagePicker(fig, 'xAxisColor', [0.9, 0.2, 0.2]);
            testCase.stagePicker(fig, 'yAxisColor', [0.2, 0.9, 0.2]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(rf.xAxisColor, [0.9, 0.2, 0.2], 'AbsTol', 1e-12);
            testCase.verifyEqual(rf.yAxisColor, [0.2, 0.9, 0.2], 'AbsTol', 1e-12);
            testCase.verifyEqual(rf.zAxisColor, [0, 0, 1], 'AbsTol', 1e-12, 'Untouched axis keeps its default.');
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function crossProductVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = CrossProductVector(g.v1, g.v2, 'c', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditCrossProductVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditCrossProductVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function fixedInFrameVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = FixedVectorInFrame([1; 2; 3], g.frame, 'f', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditFixedInFrameVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditFixedInFrameVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function planeToPointVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = PlaneToPointVector(g.p1, g.pl1, 'pp', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditPlaneToPointVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditPlaneToPointVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function pointVelocityVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = PointVelocityVector(g.p1, 'pv', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditPointVelocityVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditPointVelocityVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function projectedVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = ProjectedVector(g.v1, g.v2, 'pj', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditProjectedVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditProjectedVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function scaledVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = ScaledVector(g.v1, 2, 'sc', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditScaledVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditScaledVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function twoPointVectorDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = TwoPointVector(g.p1, g.p2, 'tp', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditTwoPointVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditTwoPointVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function vectorDifferenceDialogPicker(testCase)
            [lvdData, g] = testCase.geoFixture();
            v = VectorDifferenceVector(g.v1, g.v2, 'd', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditVectorDifferenceVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditProjectedVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        function vehicleStateVectorDialogPicker(testCase)
            [lvdData, ~] = testCase.geoFixture();
            v = VehicleStateVector(VehicleStateVectorTypeEnum.Radial, 1, 'vs', lvdData);
            app = testCase.openGuideDialog(@(out) lvd_EditVehicleStateVectorGUI_App(v, lvdData, out));
            testCase.checkSavePicker(app.lvd_EditVehicleStateVectorGUI, 'lineColor', @() v.lineColor, []);
        end

        %% --------------------------------------- sensors and targets

        function conicalSensorDialogPicker(testCase)
            %Sensor mesh preview needs rotx (see SensorTest documented skips).
            testCase.assumeTrue(logical(exist('rotx', 'file')), ...
                'rotx is unavailable in this MATLAB session.');
            [lvdData, sensor] = testCase.conicalFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditConicalSensorGUI_App(sensor, lvdData, out));
            testCase.checkSavePicker(app.EditConicalSensorGUI, 'sensorColor', @() sensor.color);
        end

        function rectangularSensorDialogPicker(testCase)
            %Sensor mesh preview needs rotx (see SensorTest documented skips).
            testCase.assumeTrue(logical(exist('rotx', 'file')), ...
                'rotx is unavailable in this MATLAB session.');
            [lvdData, sensor] = testCase.rectFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditRectangularSensorGUI_App(sensor, lvdData, out));
            testCase.checkSavePicker(app.EditRectangularSensorGUI, 'sensorColor', @() sensor.color);
        end

        function circleGridTargetDialogPicker(testCase)
            %BodyFixedCircleGridTargetModel needs rotz (Phased Array / Aerospace
            %Toolbox); SensorTest documents the same prerequisite.
            testCase.assumeTrue(logical(exist('rotz', 'file')), ...
                'rotz is unavailable in this MATLAB session.');
            [lvdData, target] = testCase.circleTargetFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditLatLongCircleGridSensorTargetGUI_App(target, lvdData, out));
            fig = app.EditSensorTargetUIFigure;
            testCase.stagePicker(fig, 'foundFaceColor', [0.1, 0.8, 0.1]);
            testCase.stagePicker(fig, 'notFoundEdgeColor', [0.8, 0.1, 0.8]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(target.markerFoundFaceColor, [0.1, 0.8, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEqual(target.markerNotFoundEdgeColor, [0.8, 0.1, 0.8], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function rectGridTargetDialogPicker(testCase)
            [lvdData, target] = testCase.rectTargetFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditLatLongRectGridSensorTargetGUI_App(target, lvdData, out));
            fig = app.EditSensorTargetUIFigure;
            testCase.stagePicker(fig, 'foundEdgeColor', [0.1, 0.8, 0.1]);
            testCase.stagePicker(fig, 'notFoundFaceColor', [0.8, 0.1, 0.8]);
            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(target.markerFoundEdgeColor, [0.1, 0.8, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEqual(target.markerNotFoundFaceColor, [0.8, 0.1, 0.8], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function pointTargetDialogPicker(testCase)
            [lvdData, target] = testCase.pointTargetFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() lvd_EditPointSensorTargetGUI_App(target, lvdData, out));
            testCase.checkSavePicker(app.EditSensorTargetUIFigure, 'foundFaceColor', @() target.markerFoundFaceColor);
        end

        %% --------------------------------------- live-write dialogs

        function groundObjectsDialogPickers(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            app = testCase.openMlapp(@() lvd_EditGroundObjectsGUI_App(lvdData.groundObjs));
            fig = app.lvd_EditGroundObjectsGUI;
            grndObj = lvdData.groundObjs.getGroundObjAtInd(1);

            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) [0.7, 0.2, 0.2]);
            testCase.press(getappdata(fig, 'markerColorButton'));
            testCase.verifyEqual(grndObj.markerColor, [0.7, 0.2, 0.2], 'AbsTol', 1e-12, ...
                'Ground object marker writes live with no save step.');

            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) [0.2, 0.2, 0.7]);
            testCase.press(getappdata(fig, 'trkLineColorButton'));
            testCase.verifyEqual(grndObj.grdTrkLineColor, [0.2, 0.2, 0.7], 'AbsTol', 1e-12);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function graphicalAnalysisDialogPickers(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            %Second arg is the main-GUI figure handle, used only by the export path.
            app = testCase.openMlapp(@() lvd_GraphicalAnalysisGUI_App(lvdData, []));
            fig = app.lvd_GraphicalAnalysisGUI;
            ga = lvdData.graphAnalysis;

            sw = getappdata(fig, 'lineColorSwatch');
            testCase.verifyEqual(sw.BackgroundColor, [1, 1, 1], 'AbsTol', 1e-12, 'Line default stays white.');
            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) [0.9, 0.4, 0.1]);
            testCase.press(getappdata(fig, 'lineColorButton'));
            testCase.verifyEqual(ga.lineColor, [0.9, 0.4, 0.1], 'AbsTol', 1e-12);

            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) [0.1, 0.1, 0.4]);
            testCase.press(getappdata(fig, 'bgColorButton'));
            testCase.verifyEqual(ga.bgColor, [0.1, 0.1, 0.4], 'AbsTol', 1e-12);

            testCase.press(app.useEvtLineColorsCheckbox);
            testCase.verifyEqual(getappdata(fig, 'lineColorButton').Enable, matlab.lang.OnOffSwitchState.off, ...
                'Event-colored plots disable the manual line picker.');
            testCase.press(app.useEvtLineColorsCheckbox);
            testCase.verifyEqual(getappdata(fig, 'lineColorButton').Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function viewSettingsDialogPickers(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            profile = lvdData.viewSettings.selViewProfile;
            app = testCase.openMlapp(@() lvd_viewSettingsGUI_App(lvdData.viewSettings));
            fig = app.lvd_viewSettingsGUI;

            testCase.verifyEqual(getappdata(fig, 'backgroundColorButton').Enable, matlab.lang.OnOffSwitchState.off, ...
                'The theme drives axes colors by default.');
            testCase.choose(app.ViewAxesOptionsTab);
            testCase.press(app.UseThemeforAxesColorsCheckBox);
            testCase.verifyEqual(getappdata(fig, 'backgroundColorButton').Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(getappdata(fig, 'majorGridColorButton').Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(getappdata(fig, 'minorGridColorButton').Enable, matlab.lang.OnOffSwitchState.on);

            cases = {'backgroundColor', [0.2, 0.2, 0.2], 'majorGridColor', [0.8, 0.1, 0.1], ...
                     'minorGridColor', [0.1, 0.1, 0.8]};
            testCase.choose(app.ViewAxesOptionsTab);
            for k = 1:2:numel(cases)
                tag = cases{k};
                rgb = cases{k+1};
                setappdata(fig, 'lvdColorPickerFcn', @(cur, title) rgb);
                testCase.press(getappdata(fig, [tag, 'Button']));
                testCase.verifyEqual(profile.(tag), rgb, 'AbsTol', 1e-12, ...
                    sprintf('View profile %s writes live.', tag));
            end
            testCase.choose(app.SpacecraftCeletialBodiesTab);
            cases = {'thrustVectColor', [0.1, 0.8, 0.1], ...
                     'dragVectColor', [0.8, 0.1, 0.8], 'srpVectColor', [0.8, 0.8, 0.1]};
            for k = 1:2:numel(cases)
                tag = cases{k};
                rgb = cases{k+1};
                setappdata(fig, 'lvdColorPickerFcn', @(cur, title) rgb);
                testCase.press(getappdata(fig, [tag, 'Button']));
                testCase.verifyEqual(profile.(tag), rgb, 'AbsTol', 1e-12, ...
                    sprintf('View profile %s writes live.', tag));
            end
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        %% --------------------------------------- migration unit tests

        function structLoadobjConvertsVectorColor(testCase)
            [lvdData, g] = testCase.geoFixture();
            s = struct('vector', g.v1, 'name', 'u', 'lvdData', lvdData, ...
                       'lineColor', ColorSpecEnum.Magenta, 'lineSpec', LineSpecEnum.DottedLine);
            obj = UnitVector.loadobj(s);
            testCase.verifyEqual(obj.lineColor, [178/255, 0, 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.getName(), 'u');
        end

        function structLoadobjToleratesMissingColorFields(testCase)
            %Ancient files may predate a color property entirely.
            [lvdData, g] = testCase.geoFixture();
            s = struct('vector', g.v1, 'name', 'u', 'lvdData', lvdData);
            obj = UnitVector.loadobj(s);
            testCase.verifyEqual(obj.lineColor, [0, 0, 0], 'AbsTol', 1e-12, ...
                'Missing color fields keep the current default.');
            testCase.verifyEqual(obj.getName(), 'u');
        end

        function structLoadobjConvertsGroundObjColors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            s = struct('name', 'KSC', 'desc', '', 'initialTime', 0, ...
                       'wayPts', LaunchVehicleGroundObjectWayPt.empty(1,0), ...
                       'markerColor', ColorSpecEnum.Red, 'grdTrkLineColor', ColorSpecEnum.Blue);
            obj = LaunchVehicleGroundObject.loadobj(s);
            testCase.verifyEqual(obj.markerColor, [1, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.grdTrkLineColor, [0, 0, 1], 'AbsTol', 1e-12);
        end

        function structLoadobjConvertsSensorColor(testCase)
            [lvdData, sensor] = testCase.conicalFixture();
            s = struct('name', 'cone', 'angle', sensor.angle, 'range', sensor.range, ...
                       'origin', sensor.origin, 'steeringModel', sensor.steeringModel, ...
                       'lvdData', lvdData, 'color', ColorSpecEnum.Green);
            obj = ConicalSensor.loadobj(s);
            testCase.verifyEqual(obj.color, [76/255, 220/255, 0], 'AbsTol', 1e-12);
        end

        function structLoadobjConvertsTargetColors(testCase)
            [lvdData, target] = testCase.pointTargetFixture();
            s = struct('name', 'pt', 'point', target.point, 'lvdData', lvdData, ...
                       'markerFoundFaceColor', ColorSpecEnum.Green, ...
                       'markerFoundEdgeColor', ColorSpecEnum.Black, ...
                       'markerNotFoundFaceColor', ColorSpecEnum.Black, ...
                       'markerNotFoundEdgeColor', ColorSpecEnum.Black);
            obj = PointSensorTargetModel.loadobj(s);
            testCase.verifyEqual(obj.markerFoundFaceColor, [76/255, 220/255, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.markerFoundEdgeColor, [0, 0, 0], 'AbsTol', 1e-12);
        end

        function structLoadobjConvertsGraphicalAnalysisColors(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            s = struct('lvdData', lvdData, 'lineColor', ColorSpecEnum.White, 'bgColor', ColorSpecEnum.Black);
            obj = LvdGraphicalAnalysis.loadobj(s);
            testCase.verifyEqual(obj.lineColor, [1, 1, 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.bgColor, [0, 0, 0], 'AbsTol', 1e-12);
        end

        function structLoadobjConvertsRefFrameColors(testCase)
            [lvdData, g] = testCase.geoFixture();
            s = struct('coordSys', g.cs, 'origin', g.p1, 'name', 'rf', 'lvdData', lvdData, ...
                       'xAxisColor', ColorSpecEnum.Red, 'yAxisColor', ColorSpecEnum.Green, ...
                       'zAxisColor', ColorSpecEnum.Blue);
            obj = CoordSysPointRefFrame.loadobj(s);
            testCase.verifyEqual(obj.xAxisColor, [1, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.yAxisColor, [76/255, 220/255, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.zAxisColor, [0, 0, 1], 'AbsTol', 1e-12);
        end

        function viewProfileLoadobjConvertsColors(testCase)
            s = struct('backgroundColor', ColorSpecEnum.White, 'majorGridColor', ColorSpecEnum.Red, ...
                       'minorGridColor', ColorSpecEnum.Blue, 'thrustVectColor', ColorSpecEnum.Red, ...
                       'dragVectColor', ColorSpecEnum.Magenta, 'srpVectColor', ColorSpecEnum.Yellow);
            out = LaunchVehicleViewProfile.loadobj(s);
            %Materialized to a real profile (see ViewProfileF8PersistenceTest).
            testCase.verifyClass(out, 'LaunchVehicleViewProfile');
            testCase.verifyEqual(out.backgroundColor, [1, 1, 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(out.dragVectColor, [178/255, 0, 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(out.srpVectColor, [1, 216/255, 0], 'AbsTol', 1e-12);
        end

        function greyBackgroundHelperPicksDistinctGrey(testCase)
            testCase.verifyEqual(lvd_bestGreyBackgroundColor([1, 0, 0; 0, 0, 1]), [0, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(lvd_bestGreyBackgroundColor([1, 1, 1; 0, 0, 0]), [0.5, 0.5, 0.5], 'AbsTol', 1e-12);
            testCase.verifyEqual(lvd_bestGreyBackgroundColor(zeros(0, 3)), [0, 0, 0], 'AbsTol', 1e-12, ...
                'An event-less script with the flag on must still yield a background.');
        end

        function pickerHelperCancelInvalidIdempotentAndEnable(testCase)
            %Unit tests for the shared runtime helper need no dialog.
            fig = uifigure('Visible', 'off');
            testCase.addTeardown(@() deleteIfValid(fig));
            grid = uigridlayout(fig, [1, 2]);
            dd = uidropdown(grid);
            dd.Items = {'a'};
            dd.Layout.Row = 1;
            dd.Layout.Column = 1;

            btn = lvdSetupColorPicker(fig, grid, 1, 1, dd, [1, 0, 0], 'tip', 't');
            testCase.verifyFalse(isvalid(dd), 'The dropdown is retired.');
            testCase.verifyEqual(getappdata(fig, 'tRGB'), [1, 0, 0], 'AbsTol', 1e-12);

            %cancel leaves everything alone
            %uitest press needs a visible hierarchy; the helper callback is
            %the unit under test here, so invoke it directly.
            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) 0);
            btn.ButtonPushedFcn(btn, struct('Source', btn));
            testCase.verifyEqual(getappdata(fig, 'tRGB'), [1, 0, 0], 'AbsTol', 1e-12);

            %garbage is rejected
            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) [2, 2, 2]);
            btn.ButtonPushedFcn(btn, struct('Source', btn));
            testCase.verifyEqual(getappdata(fig, 'tRGB'), [1, 0, 0], 'AbsTol', 1e-12);

            %repopulate refreshes instead of duplicating
            lvdSetupColorPicker(fig, grid, 1, 1, matlab.ui.control.DropDown.empty(1, 0), [0, 0, 1], 'tip', 't');
            testCase.verifyEqual(numel(findobj(fig, 'Tag', 'tButton')), 1);
            testCase.verifyEqual(getappdata(fig, 'tSwatch').BackgroundColor, [0, 0, 1], 'AbsTol', 1e-12);

            %enable seam
            lvdSetColorPickerEnable(fig, 't', 'off');
            testCase.verifyEqual(btn.Enable, matlab.lang.OnOffSwitchState.off);
            lvdSetColorPickerEnable(fig, 't', 'on');
            testCase.verifyEqual(btn.Enable, matlab.lang.OnOffSwitchState.on);

            %missing pending state falls back
            rmappdata(fig, 'tRGB');
            testCase.verifyEqual(lvdGetColorPickerRGB(fig, 't', [0, 0, 1]), [0, 0, 1], 'AbsTol', 1e-12);
        end

        function structLoadobjConvertsAllRemainingColors(testCase)
            [lvdData, g] = testCase.geoFixture();
            kerbin = testCase.celBodyData.kerbin;
            kep = KeplerianElementSet(0, kerbin.radius + 300, 0, 0.1, 0, 0, 0, g.frame);
            rotFrame = TwoBodyRotatingFrame(kerbin, testCase.celBodyData.mun, TwoBodyRotatingFrameOriginEnum.Primary, testCase.celBodyData);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            RED = ColorSpecEnum.Red; GREEN = ColorSpecEnum.Green; BLACK = ColorSpecEnum.Black;

            cases = {
                'TwoPlaneAngle', struct('plane1', g.pl1, 'plane2', g.pl2, 'name', 'a', 'lvdData', lvdData, 'lineColor', RED), ...
                    struct('lineColor', [1, 0, 0]), ...
                'TwoVectorAngle', struct('vector1', g.v1, 'vector2', g.v2, 'name', 'a', 'lvdData', lvdData, 'lineColor', RED), ...
                    struct('lineColor', [1, 0, 0]), ...
                'VectorDotProductAngle', struct('vector1', g.v1, 'vector2', g.v2, 'name', 'a', 'lvdData', lvdData, 'lineColor', RED), ...
                    struct('lineColor', [1, 0, 0]), ...
                'VectorPlaneAngle', struct('vector', g.v1, 'plane', g.pl1, 'name', 'a', 'lvdData', lvdData, 'lineColor', RED), ...
                    struct('lineColor', [1, 0, 0]), ...
                'PointVectorPlane', struct('point', g.p1, 'vector', g.v1, 'name', 'pl', 'lvdData', lvdData, 'lineColor', GREEN), ...
                    struct('lineColor', [76/255, 220/255, 0]), ...
                'ThreePointPlane', struct('point1', g.p1, 'point2', g.p2, 'point3', g.p3, 'name', 'pl', 'lvdData', lvdData, 'lineColor', GREEN), ...
                    struct('lineColor', [76/255, 220/255, 0]), ...
                'FixedPointInFrame', struct('rVect', [7000; 0; 0], 'frame', g.frame, 'name', 'p', 'lvdData', lvdData, 'markerColor', RED, 'trkLineColor', BLACK), ...
                    struct('markerColor', [1, 0, 0], 'trkLineColor', [0, 0, 0]), ...
                'TwoBodyPoint', struct('elemSet', kep, 'name', 'tb', 'lvdData', lvdData, 'markerColor', RED, 'trkLineColor', BLACK), ...
                    struct('markerColor', [1, 0, 0], 'trkLineColor', [0, 0, 0]), ...
                'VectorPlaneIntersectionPoint', struct('originPoint', g.p1, 'vector', g.v1, 'plane', g.pl1, 'name', 'x', 'lvdData', lvdData, 'markerColor', RED, 'trkLineColor', BLACK), ...
                    struct('markerColor', [1, 0, 0], 'trkLineColor', [0, 0, 0]), ...
                'LagrangeGeometricPoint', struct('lpoint', LagrangeGeometricPointEnum.L4, 'frame', rotFrame, 'lvdData', lvdData, 'name', 'lag', 'markerColor', RED, 'trkLineColor', BLACK), ...
                    struct('markerColor', [1, 0, 0], 'trkLineColor', [0, 0, 0]), ...
                'CrossProductVector', struct('vector1', g.v1, 'vector2', g.v2, 'name', 'c', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'FixedVectorInFrame', struct('vect', [1; 2; 3], 'frame', g.frame, 'name', 'f', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'PlaneToPointVector', struct('point', g.p1, 'plane', g.pl1, 'name', 'pp', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'PointVelocityVector', struct('point', g.p1, 'name', 'pv', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'ProjectedVector', struct('projVect', g.v1, 'normVect', g.v2, 'name', 'pj', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'ScaledVector', struct('vector', g.v1, 'scaleFactor', 2, 'name', 'sc', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'TwoPointVector', struct('point1', g.p1, 'point2', g.p2, 'name', 'tp', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'VectorDifferenceVector', struct('vector1', g.v1, 'vector2', g.v2, 'name', 'd', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'VectorSumVector', struct('vector1', g.v1, 'vector2', g.v2, 'name', 's', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'VehicleStateVector', struct('type', VehicleStateVectorTypeEnum.Radial, 'scaleFactor', 1, 'name', 'vs', 'lvdData', lvdData, 'lineColor', BLACK), ...
                    struct('lineColor', [0, 0, 0]), ...
                'RectangularSensor', struct('name', 'rect', 'azAngle', 0.5, 'decAngle', 0.3, 'range', 1000, 'origin', g.p1, 'steeringModel', steer, 'lvdData', lvdData, 'color', GREEN), ...
                    struct('color', [76/255, 220/255, 0]), ...
                'BodyFixedLatLongGridTargetModel', struct('name', 'rt', 'bodyInfo', kerbin, 'nwCornerLong', -0.1, 'nwCornerLat', 0.1, 'seCornerLong', 0.1, 'seCornerLat', -0.1, 'numPtsLong', 4, 'numPtsLat', 4, 'altitude', 100, 'lvdData', lvdData, 'markerFoundFaceColor', GREEN, 'markerFoundEdgeColor', GREEN, 'markerNotFoundFaceColor', BLACK, 'markerNotFoundEdgeColor', BLACK), ...
                    struct('markerFoundFaceColor', [76/255, 220/255, 0], 'markerFoundEdgeColor', [76/255, 220/255, 0], 'markerNotFoundFaceColor', [0, 0, 0], 'markerNotFoundEdgeColor', [0, 0, 0]), ...
                };

            for k = 1:3:numel(cases)
                className = cases{k};
                s = cases{k+1};
                want = cases{k+2};
                obj = feval([className, '.loadobj'], s);
                testCase.verifyClass(obj, className, sprintf('%s must materialize.', className));
                props = fieldnames(want);
                for j = 1:numel(props)
                    testCase.verifyEqual(obj.(props{j}), want.(props{j}), 'AbsTol', 1e-12, ...
                        sprintf('%s.%s must migrate to RGB.', className, props{j}));
                end
            end
        end

        function structLoadobjSkipsEphemerisFileRead(testCase)
            [lvdData, g] = testCase.geoFixture();
            s = struct('filePath', fullfile('no', 'such', 'file.csv'), 'frame', g.frame, ...
                       'name', 'e', 'lvdData', lvdData, 'times', [0, 10], ...
                       'rvVects', zeros(6, 2), 'markerColor', ColorSpecEnum.Red, ...
                       'trkLineColor', ColorSpecEnum.Black);
            obj = EphemerisFilePoint.loadobj(s);
            testCase.verifyEqual(obj.times, [0, 10]);
            testCase.verifyEqual(obj.filePath, fullfile('no', 'such', 'file.csv'), ...
                'The saved path round-trips without touching the disk.');
            testCase.verifyEqual(obj.markerColor, [1, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.trkLineColor, [0, 0, 0], 'AbsTol', 1e-12);
        end

        function structLoadobjReloadsLvdDataPoint(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            inputLvd = LvdData.getDefaultLvdData(testCase.celBodyData);
            s = struct('inputLvdData', inputLvd, 'lvdData', lvdData, 'name', 'tp', ...
                       'markerColor', ColorSpecEnum.Red, 'trkLineColor', ColorSpecEnum.Black);
            obj = LvdDataPoint.loadobj(s);
            testCase.verifyEqual(obj.markerColor, [1, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.trkLineColor, [0, 0, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.getName(), 'tp');
        end

        function structLoadobjConvertsCircleGridTarget(testCase)
            %Grid construction needs rotz (see SensorTest documented skips).
            testCase.assumeTrue(logical(exist('rotz', 'file')), ...
                'rotz is unavailable in this MATLAB session.');
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            s = struct('name', 'ct', 'bodyInfo', testCase.celBodyData.kerbin, ...
                       'longCenter', 0, 'latCenter', 0, 'radius', 0.1, ...
                       'arcOffset', 0, 'arcAngle', 1, 'numPtsCircumference', 4, ...
                       'numPtsRadial', 3, 'altitude', 100, 'lvdData', lvdData, ...
                       'markerFoundFaceColor', ColorSpecEnum.Green, ...
                       'markerFoundEdgeColor', ColorSpecEnum.Green, ...
                       'markerNotFoundFaceColor', ColorSpecEnum.Black, ...
                       'markerNotFoundEdgeColor', ColorSpecEnum.Black);
            obj = BodyFixedCircleGridTargetModel.loadobj(s);
            testCase.verifyEqual(obj.markerFoundFaceColor, [76/255, 220/255, 0], 'AbsTol', 1e-12);
            testCase.verifyEqual(obj.markerNotFoundEdgeColor, [0, 0, 0], 'AbsTol', 1e-12);
        end

        function missionRoundTripPreservesRgbGeometry(testCase)
            %New-format save/load exercises every included class's loadobj
            %object branch (normalization path).
            [lvdData, g] = testCase.geoFixture();
            v = UnitVector(g.v1, 'u', lvdData);
            v.lineColor = [0.1, 0.5, 0.9];
            lvdData.geometry.vectors.addVector(v);
            a = TwoPlaneAngle(g.pl1, g.pl2, 'a', lvdData);
            a.lineColor = [0.9, 0.1, 0.1];
            lvdData.geometry.angles.addAngle(a);
            grndObj = lvdData.groundObjs.getGroundObjAtInd(1);
            grndObj.markerColor = [0.2, 0.8, 0.2];

            matPath = [tempname(), '.mat'];
            testCase.addTeardown(@() deleteIfExists(matPath));
            save(matPath, 'lvdData');
            loaded = load(matPath, 'lvdData');
            lv = loaded.lvdData;

            us = lv.geometry.vectors.getVectorsForInds(1:lv.geometry.vectors.getNumVectors());
            uLoaded = us(strcmp(arrayfun(@(x) x.getName(), us, 'UniformOutput', false), 'u'));
            testCase.verifyEqual(uLoaded.lineColor, [0.1, 0.5, 0.9], 'AbsTol', 1e-12);
            angs = lv.geometry.angles.getAnglesForInds(1:lv.geometry.angles.getNumAngles());
            aLoaded = angs(strcmp(arrayfun(@(x) x.getName(), angs, 'UniformOutput', false), 'a'));
            testCase.verifyEqual(aLoaded.lineColor, [0.9, 0.1, 0.1], 'AbsTol', 1e-12);
            testCase.verifyEqual(lv.groundObjs.getGroundObjAtInd(1).markerColor, [0.2, 0.8, 0.2], 'AbsTol', 1e-12);
        end

        function mainGuiScriptListUsesEventColors(testCase)
            %The LVD main window listens on globals the KSPTOT launcher
            %normally creates (see LvdMainGuiInteractionTest).
            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end
            global ksptot_TimeSystem options_UseEarthTimeSystem %#ok<GVMIS>
            if(isempty(ksptot_TimeSystem))
                [rawIni, ~, ~] = inifile(fullfile(ksptotTestRoot(), 'bodies.ini'), 'readall');
                ksptot_TimeSystem = getTimeSystemFromConfig(getAppOptionsFromFile(), rawIni);
                options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system, 'earth_stock');
            end

            stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(stubMainFig));
            app = ma_LvdMainGUI_App(testCase.celBodyData, stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;

            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            profile = lvdData.viewSettings.selViewProfile;
            profile.scriptBoxUseEventColors = true;
            evt = lvdData.script.getEventForInd(1);
            evt.colorLineSpec.color = [1, 0, 0];

            %Public refresh seam (no re-propagation): re-renders the script list.
            app.lvdEnhancementsRefresh(false);
            drawnow;

            testCase.verifyEqual(app.scriptListbox.BackgroundColor, [0, 0, 0], 'AbsTol', 1e-12, ...
                'A single bright-red event leaves the largest value gap below it.');
            styles = app.scriptListbox.StyleConfigurations.Style;
            if(iscell(styles))
                styles = [styles{:}];
            end
            fonts = arrayfun(@(s) s.FontColor, styles, 'UniformOutput', false);
            testCase.verifyTrue(any(cellfun(@(c) isequal(c, [1, 0, 0]), fonts)), ...
                'The event row must carry its trajectory color as font color.');
        end
    end

    methods(Access = private)
        function [lvdData, g] = geoFixture(testCase)
            %Shared geometry stack so every editor's combos validate.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            frame = testCase.kerbinFrame;
            p1 = FixedPointInFrame([7000; 0; 0], frame, 'p1', lvdData);
            p2 = FixedPointInFrame([0; 7000; 0], frame, 'p2', lvdData);
            p3 = FixedPointInFrame([0; 0; 7000], frame, 'p3', lvdData);
            lvdData.geometry.points.addPoint(p1);
            lvdData.geometry.points.addPoint(p2);
            lvdData.geometry.points.addPoint(p3);
            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            lvdData.geometry.vectors.addVector(v1);
            lvdData.geometry.vectors.addVector(v2);
            pl1 = PointVectorPlane(p1, v1, 'pl1', lvdData);
            pl2 = PointVectorPlane(p2, v2, 'pl2', lvdData);
            lvdData.geometry.planes.addPlane(pl1);
            lvdData.geometry.planes.addPlane(pl2);
            cs = ThreePointCoordSystem(p1, p2, p3, 'cs', lvdData);
            lvdData.geometry.coordSyses.addCoordSys(cs);
            g = struct('frame', frame, 'p1', p1, 'p2', p2, 'p3', p3, ...
                       'v1', v1, 'v2', v2, 'pl1', pl1, 'pl2', pl2, 'cs', cs);
        end

        function [lvdData, sensor] = conicalFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            pt = FixedPointInFrame([0; 0; 0], testCase.kerbinFrame, 'p', lvdData);
            lvdData.geometry.points.addPoint(pt);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('cone', 0.2, 1000, pt, steer, lvdData);
        end

        function [lvdData, sensor] = rectFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            pt = FixedPointInFrame([0; 0; 0], testCase.kerbinFrame, 'p', lvdData);
            lvdData.geometry.points.addPoint(pt);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = RectangularSensor('rect', 0.5, 0.3, 1000, pt, steer, lvdData);
        end

        function [lvdData, target] = circleTargetFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            target = BodyFixedCircleGridTargetModel('ct', testCase.celBodyData.kerbin, ...
                0, 0, 0.1, 0, 1, 4, 3, 100, lvdData);
        end

        function [lvdData, target] = rectTargetFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            target = BodyFixedLatLongGridTargetModel('rt', testCase.celBodyData.kerbin, ...
                -0.1, 0.1, 0.1, -0.1, 4, 4, 100, lvdData);
        end

        function [lvdData, target] = pointTargetFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            pt = FixedPointInFrame([7000; 0; 0], testCase.kerbinFrame, 'p', lvdData);
            lvdData.geometry.points.addPoint(pt);
            target = PointSensorTargetModel('pt', pt, lvdData);
        end

        function app = openMlapp(testCase, createFcn)
            app = createFcn();
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
        end

        function app = openGuideDialog(testCase, createFcn)
            %GUIDE-migrated dialogs take (obj, lvdData, output).
            out = AppDesignerGUIOutput({false});
            app = testCase.openMlapp(@() createFcn(out));
        end

        function saveBtn = findSaveButton(testCase, fig)
            btns = findobj(fig, 'Type', 'uibutton');
            texts = {btns.Text};
            hit = btns(strcmp(texts, 'Save & Close'));
            if(isempty(hit))
                hit = btns(strcmp(texts, 'Save'));
            end
            testCase.assertNotEmpty(hit, sprintf('No Save button; buttons are: %s', strjoin(texts, ', ')));
            saveBtn = hit(1);
        end

        function stagePicker(testCase, fig, tag, stubRGB)
            %stagePicker Stubs a pick and presses the button without saving.
            btn = getappdata(fig, [tag, 'Button']);
            sw = getappdata(fig, [tag, 'Swatch']);
            testCase.verifyTrue(isa(btn, 'matlab.ui.control.Button') && all(isvalid(btn)), ...
                sprintf('Picker button %s must exist.', tag));
            testCase.verifyEqual(btn.Text, 'Choose...');
            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) stubRGB);
            testCase.press(btn);
            testCase.verifyEqual(getappdata(fig, [tag, 'RGB']), stubRGB, 'AbsTol', 1e-12, ...
                'Pick must stage pending RGB.');
            testCase.verifyEqual(sw.BackgroundColor, stubRGB, 'AbsTol', 1e-12, ...
                'Pick must refresh the swatch.');
        end

        function checkSavePicker(testCase, fig, tag, getStoredFcn, stubRGB)
            %checkSavePicker Drives one runtime color picker end to end.
            if(nargin < 6 || isempty(stubRGB))
                stubRGB = [0.2, 0.4, 0.6];
            end
            btn = getappdata(fig, [tag, 'Button']);
            sw = getappdata(fig, [tag, 'Swatch']);
            testCase.verifyTrue(isa(btn, 'matlab.ui.control.Button') && all(isvalid(btn)), ...
                sprintf('Picker button %s must exist.', tag));
            testCase.verifyTrue(all(isvalid(sw)), sprintf('Picker swatch %s must exist.', tag));
            testCase.verifyEqual(btn.Text, 'Choose...');

            setappdata(fig, 'lvdColorPickerFcn', @(cur, title) stubRGB);
            testCase.press(btn);
            testCase.verifyEqual(getappdata(fig, [tag, 'RGB']), stubRGB, 'AbsTol', 1e-12, ...
                'Pick must stage pending RGB.');
            testCase.verifyEqual(sw.BackgroundColor, stubRGB, 'AbsTol', 1e-12, ...
                'Pick must refresh the swatch.');

            testCase.press(testCase.findSaveButton(fig));
            testCase.verifyEqual(getStoredFcn(), stubRGB, 'AbsTol', 1e-12, ...
                'Save must write the picked RGB to the object.');
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
        end

        function closeNewFigures(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            delete(figs(isvalid(figs)));
        end
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        delete(h);
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
