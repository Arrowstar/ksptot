classdef ViewProfilePlottingOptionsTest < KsptotTestCase
    %ViewProfilePlottingOptionsTest Headless coverage for every 3-D
    %trajectory and 2-D ground-track plotting toggle on
    %LaunchVehicleViewProfile ("View Settings").
    %
    % SCOPE (strictly headless, per user direction):
    %   * 3-D toggles read by Generic3DTrajectoryViewType.plotStateLog and
    %     LaunchVehicleViewProfile.create*Data.
    %   * 2-D ground-track toggles read by
    %     Generic2DGroundTrackViewType.plotGroundTrack (data-builder level
    %     only -- plotGroundTrack itself needs ma_LvdMainGUI_App and is NOT
    %     called here).
    %   * F8 extras (camera modes, vehicle mesh, overlay, playback/export,
    %     skybox) are OUT OF SCOPE -- covered by RenderSceneAtTimeTest,
    %     ViewOverlayTest, ViewProfileF8PersistenceTest, VehicleMeshSettingsTest,
    %     CameraScriptTest, PlaybackControllerTest, ViewExporterTest.
    %
    % STRATEGY:
    %   * Real two-event propagated mission (same fixture as ViewOverlayTest).
    %   * profile.frame pinned to Kerbin BCI for determinism.
    %   * Offscreen figure/axes only (Visible off); no ma_LvdMainGUI_App,
    %     no lvd_renderSceneAtTime, no GroundTrackAxes.
    %   * Where production branches on a toggle AND draws, the test replicates
    %     the exact production condition + draw call on the offscreen axes
    %     and asserts on the resulting graphics objects / marker-data state.
    %     Where production only stores the flag in marker data, the test
    %     asserts on the stored flag.

    methods(Test)

        %% ------------------------- A. defaults -------------------------

        function defaultProfileMatchesDocumentedPlottingDefaults(testCase)
            profile = LaunchVehicleViewProfile();

            %axes appearance
            testCase.verifyTrue(profile.useThemeForAxes);
            testCase.verifyEqual(profile.backgroundColor, ColorSpecEnum.White);
            testCase.verifyEqual(profile.gridType, ViewGridTypeEnum.Major);
            testCase.verifyEqual(profile.majorGridColor, ColorSpecEnum.DarkGrey);
            testCase.verifyEqual(profile.minorGridColor, ColorSpecEnum.DarkGrey);
            testCase.verifyEqual(profile.gridTransparency, 0.15);
            testCase.verifyEqual(profile.meshEdgeAlpha, 0.1);
            testCase.verifyTrue(profile.showAxesBox);
            testCase.verifyEqual(profile.projType, ViewProjectionTypeEnum.Perspective);

            %axis indicators
            testCase.verifyFalse(profile.dispXAxis);
            testCase.verifyFalse(profile.dispYAxis);
            testCase.verifyFalse(profile.dispZAxis);

            %trajectory filtering
            testCase.verifyEqual(profile.trajEvtsViewType, ViewEventsTypeEnum.All);
            testCase.verifyTrue(profile.plotAllEvents);
            testCase.verifyEmpty(profile.eventsToPlot);
            testCase.verifyEqual(profile.orbitNumToPlot, 1);

            %bodies / SoI / atmosphere / lighting
            testCase.verifyFalse(profile.showSoIRadius);
            testCase.verifyEqual(profile.bodyPlotStyle, ViewProfileBodyPlottingStyle.Dot);
            testCase.verifyFalse(profile.showAtmosphere);
            testCase.verifyFalse(profile.showLighting);
            testCase.verifyFalse(profile.showSunVect);
            testCase.verifyTrue(profile.showLongLatAnnotations);

            %force vectors
            testCase.verifyFalse(profile.showThrustVectors);
            testCase.verifyEqual(profile.thrustVectColor, ColorSpecEnum.Red);
            testCase.verifyEqual(profile.thrustVectScale, 1);
            testCase.verifyEqual(profile.thrustVectEntryIncr, 1);
            testCase.verifyFalse(profile.showDragVectors);
            testCase.verifyEqual(profile.dragVectColor, ColorSpecEnum.Magenta);
            testCase.verifyEqual(profile.dragVectScale, 1);
            testCase.verifyEqual(profile.dragVectEntryIncr, 1);
            testCase.verifyFalse(profile.showSrpVectors);
            testCase.verifyEqual(profile.srpVectColor, ColorSpecEnum.Yellow);
            testCase.verifyEqual(profile.srpVectScale, 1000);
            testCase.verifyEqual(profile.srpVectEntryIncr, 1);

            %spacecraft axes
            testCase.verifyFalse(profile.showScBodyAxes);
            testCase.verifyEqual(profile.scBodyAxesScale, 100);

            %ground objects
            testCase.verifyTrue(profile.showGndTracks);
            testCase.verifyTrue(profile.showGrdObjLoS);

            %ground track
            testCase.verifyFalse(profile.showGrdTrk);
            testCase.verifyFalse(profile.showCelestialBodyGrdTracks);
            testCase.verifyFalse(profile.showGroundObjsGrdTracks);
            testCase.verifyFalse(profile.showGeomPointsGrdTracks);
            testCase.verifyFalse(profile.showTerrainContours);
            testCase.verifyEqual(profile.numTerrainContourLevels, 10);

            %geometry / sensors start empty
            testCase.verifyEmpty(profile.pointsToPlot);
            testCase.verifyEmpty(profile.vectorsToPlot);
            testCase.verifyEmpty(profile.refFramesToPlot);
            testCase.verifyEmpty(profile.anglesToPlot);
            testCase.verifyEmpty(profile.planesToPlot);
            testCase.verifyEmpty(profile.sensorsToPlot);
            testCase.verifyEmpty(profile.sensorTgtsToPlot);
            testCase.verifyEmpty(profile.bodiesToPlot);
            testCase.verifyEmpty(profile.groundObjsToPlot);
        end

        %% --------------------- B. axes appearance ----------------------

        function axesColorsGridTransparencyAndBoxApplyToOffscreenAxes(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            profile.backgroundColor = ColorSpecEnum.Black;
            profile.majorGridColor = ColorSpecEnum.Red;
            profile.minorGridColor = ColorSpecEnum.Blue;
            profile.gridTransparency = 0.4;
            profile.gridType = ViewGridTypeEnum.Minor;

            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>

            %exact production call (Generic3DTrajectoryViewType:481):
            %grid(dAxes, viewProfile.gridType.gridStr) for each grid mode
            hAx.Color = profile.backgroundColor.color;
            hAx.GridColor = profile.majorGridColor.color;
            hAx.MinorGridColor = profile.minorGridColor.color;
            hAx.GridAlpha = profile.gridTransparency;
            hAx.XColor = profile.majorGridColor.color;
            hAx.YColor = profile.majorGridColor.color;
            hAx.ZColor = profile.majorGridColor.color;

            testCase.verifyEqual(hAx.Color, [0 0 0]);
            testCase.verifyEqual(hAx.GridColor, [1 0 0]);
            testCase.verifyEqual(hAx.MinorGridColor, [0 0 1]);
            testCase.verifyEqual(hAx.GridAlpha, 0.4);

            profile.gridType = ViewGridTypeEnum.Major;
            grid(hAx, profile.gridType.gridStr);
            testCase.verifyEqual(hAx.XGrid, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(hAx.YGrid, matlab.lang.OnOffSwitchState.on);

            profile.gridType = ViewGridTypeEnum.Minor;
            grid(hAx, profile.gridType.gridStr);
            testCase.verifyEqual(hAx.XMinorGrid, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(hAx.YMinorGrid, matlab.lang.OnOffSwitchState.on);

            profile.gridType = ViewGridTypeEnum.Off;
            grid(hAx, profile.gridType.gridStr);
            testCase.verifyEqual(hAx.XGrid, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(hAx.YGrid, matlab.lang.OnOffSwitchState.off);

            %showAxesBox=false path
            profile.showAxesBox = false;
            if(profile.showAxesBox)
                hAx.Box = 'on'; hAx.Visible = 'on';
            else
                hAx.Box = 'off';
                hAx.XGrid = 'off'; hAx.YGrid = 'off'; hAx.ZGrid = 'off';
                hAx.Visible = 'off';
            end
            testCase.verifyEqual(hAx.Box, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(hAx.Visible, matlab.lang.OnOffSwitchState.off);

            %and back on
            profile.showAxesBox = true;
            hAx.Box = 'on'; hAx.Visible = 'on';
            testCase.verifyEqual(hAx.Box, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(hAx.Visible, matlab.lang.OnOffSwitchState.on);
        end

        function meshEdgeAlphaIsStoredOnBodyData(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            profile.meshEdgeAlpha = 0.55;
            bodyData = profile.createBodyData(testCase.mun, profile.frame, ...
                profile.bodyPlotStyle, false, profile.meshEdgeAlpha);
            testCase.verifyEqual(bodyData.meshEdgeAlpha, 0.55);
        end

        function projectionEnumTogglesCamproj(testCase)
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>

            camproj(hAx, 'orthographic');
            testCase.verifyEqual(hAx.Projection, 'orthographic');
            camproj(hAx, 'perspective');
            testCase.verifyEqual(hAx.Projection, 'perspective');

            %both enum members resolve (would throw on typo)
            testCase.verifyEqual(ViewProjectionTypeEnum.Orthographic.name, 'Orthographic');
            testCase.verifyEqual(ViewProjectionTypeEnum.Perspective.name, 'Perspective');
        end

        function axisIndicatorQuiversMatchDispFlags(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            viewCentralBody = profile.frame.getOriginBody();

            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>

            %production block (Generic3D:434-450), all three on
            profile.dispXAxis = true; profile.dispYAxis = true; profile.dispZAxis = true;
            axisLength = 2*viewCentralBody.radius;
            hold(hAx, 'on');
            if(profile.dispXAxis)
                quiver3(hAx, 0,0,0, axisLength,0,0, 'r', 'LineWidth',2);
            end
            if(profile.dispYAxis)
                quiver3(hAx, 0,0,0, 0,axisLength,0, 'g', 'LineWidth',2);
            end
            if(profile.dispZAxis)
                quiver3(hAx, 0,0,0, 0,0,axisLength, 'b', 'LineWidth',2);
            end
            hold(hAx, 'off');

            q = findobj(hAx, 'Type', 'Quiver');
            testCase.verifyNumElements(q, 3);
            testCase.verifyEqual(sort([q.UData]), sort([axisLength, 0, 0]), 'AbsTol', 1e-9);

            %all off draws nothing
            cla(hAx);
            profile.dispXAxis = false; profile.dispYAxis = false; profile.dispZAxis = false;
            hold(hAx, 'on');
            if(profile.dispXAxis)
                quiver3(hAx, 0,0,0, axisLength,0,0, 'r', 'LineWidth',2);
            end
            if(profile.dispYAxis)
                quiver3(hAx, 0,0,0, 0,axisLength,0, 'g', 'LineWidth',2);
            end
            if(profile.dispZAxis)
                quiver3(hAx, 0,0,0, 0,0,axisLength, 'b', 'LineWidth',2);
            end
            hold(hAx, 'off');
            testCase.verifyEmpty(findobj(hAx, 'Type', 'Quiver'));
        end

        %% ------------------- C. trajectory filtering -------------------

        function plotAllEventsSubsetFiltersStateLogEntries(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            entriesAll = lvdData.stateLog.getAllEntries();
            testCase.assertGreaterThan(numel(entriesAll), 3);

            evt1 = lvdData.script.getEventForInd(1);
            profile.plotAllEvents = false;
            profile.eventsToPlot = evt1;

            [~, filtEntries, ~] = testCase.buildSubStateLogs(lvdData, profile);
            testCase.verifyLessThan(numel(filtEntries), numel(entriesAll));
            testCase.verifyTrue(all([filtEntries.event] == evt1));

            %and back to all
            profile.plotAllEvents = true;
            [~, allEntries, ~] = testCase.buildSubStateLogs(lvdData, profile);
            testCase.verifyNumElements(allEntries, numel(entriesAll));
        end

        function eventPlotMethodIsRespectedByTrajectoryData(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            evt2 = lvdData.script.getEventForInd(2);

            %DoNotPlot drops event 2's segment
            evt2.plotMethod = EventPlottingMethodEnum.DoNotPlot;
            [subStateLogs, ~, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            profile.createTrajectoryMarkerData(subStateLogs, evtsToPlot);
            testCase.assertNotEmpty(profile.markerTrajData.timesArr);
            nSegDoNotPlot = numel(profile.markerTrajData.timesArr);

            evt2.plotMethod = EventPlottingMethodEnum.PlotContinuous;
            [subStateLogsFull, ~, evtsFull] = testCase.buildSubStateLogs(lvdData, profile);
            profile.createTrajectoryMarkerData(subStateLogsFull, evtsFull);
            nSegFull = numel(profile.markerTrajData.timesArr);
            testCase.verifyGreaterThanOrEqual(nSegFull, nSegDoNotPlot);

            %SkipFirstState drops points from every segment (exact count varies:
            %single-point segments are dropped or duplicated by the
            %interpolant padding, so assert directionally)
            nPtsFull = sum(cellfun(@numel, profile.markerTrajData.timesArr));
            evt1 = lvdData.script.getEventForInd(1);
            evt1.plotMethod = EventPlottingMethodEnum.SkipFirstState;
            evt2.plotMethod = EventPlottingMethodEnum.SkipFirstState;
            [subSkip, ~, evtsSkip] = testCase.buildSubStateLogs(lvdData, profile);
            profile.createTrajectoryMarkerData(subSkip, evtsSkip);
            nPtsSkip = sum(cellfun(@numel, profile.markerTrajData.timesArr));
            testCase.verifyLessThan(nPtsSkip, nPtsFull);
        end

        %% ----------------- D. bodies / SoI / atmosphere ----------------

        function bodiesToPlotSkipsViewOriginBody(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            profile.bodiesToPlot = [testCase.kerbin, testCase.mun];

            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            [subStateLogs, ~, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);

            %production gate: origin body is skipped (LaunchVehicleViewProfile:476).
            %NOTE: createBodyData appends to markerBodyData AND the caller
            %appends the returned handle again, so each plotted body appears
            %twice; assert on membership, not count.
            profile.createBodyMarkerData(hAx, subStateLogs, profile.frame, ...
                false, profile.meshEdgeAlpha, evtsToPlot);
            testCase.verifyNotEmpty(profile.markerBodyData);
            for k = 1:numel(profile.markerBodyData)
                testCase.verifyEqual(profile.markerBodyData(k).bodyInfo, testCase.mun, ...
                    'The view origin body (Kerbin) must be skipped');
            end
        end

        function bodyPlotStyleDotIsDefaultAndMeshSphereIsDocumented(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            testCase.verifyEqual(profile.bodyPlotStyle, ViewProfileBodyPlottingStyle.Dot);
            members = enumeration('ViewProfileBodyPlottingStyle');
            testCase.verifyNumElements(members, 2);

            %Dot stores cleanly
            dotData = profile.createBodyData(testCase.mun, profile.frame, ...
                ViewProfileBodyPlottingStyle.Dot, false, 0.1);
            testCase.verifyEqual(dotData.plotStyle, ViewProfileBodyPlottingStyle.Dot);

            %MeshSphere is a real second style: it stores and renders an
            %hgtransform marker without error.
            meshData = profile.createBodyData(testCase.mun, profile.frame, ...
                ViewProfileBodyPlottingStyle.MeshSphere, false, 0.1);
            testCase.verifyEqual(meshData.plotStyle, ViewProfileBodyPlottingStyle.MeshSphere);
            [hFigM, hAxM] = testCase.offscreenAxes();
            cleanupM = onCleanup(@() deleteIfValid(hFigM)); %#ok<NASGU>
            meshData.addData([0, 10], repmat([7000; 0; 0], 1, 2));
            meshData.plotBodyMarkerAtTime(5, hAxM);
            testCase.verifyNotEmpty(meshData.markerPlot);
            testCase.verifyTrue(isvalid(meshData.markerPlot));
        end

        function soiRadiiDrawnOnlyWhenEnabled(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            [subStateLogs, ~, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            [~, ~, midTime] = testCase.midTime(subStateLogs);

            %showSoI=true: Dot marker + 3 SoI circles under one hgtransform
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            profile.bodiesToPlot = testCase.mun;
            profile.createBodyMarkerData(hAx, subStateLogs, profile.frame, ...
                true, profile.meshEdgeAlpha, evtsToPlot);
            testCase.assertNotEmpty(profile.markerBodyData);
            for k = 1:numel(profile.markerBodyData)
                testCase.verifyEqual(profile.markerBodyData(k).bodyInfo, testCase.mun);
            end
            bodyData = profile.markerBodyData(1);
            testCase.verifyTrue(bodyData.showSoI);
            bodyData.plotBodyMarkerAtTime(midTime, hAx);
            testCase.assertNotEmpty(bodyData.markerPlot);
            testCase.assertTrue(isvalid(bodyData.markerPlot));
            kids = bodyData.markerPlot.Children;
            testCase.verifyNumElements(kids, 4, 'Dot + 3 SoI circles');

            %showSoI=false: only the Dot marker
            [hFig2, hAx2] = testCase.offscreenAxes();
            cleanup2 = onCleanup(@() deleteIfValid(hFig2)); %#ok<NASGU>
            bodyData2 = LaunchVehicleViewProfileBodyData(testCase.mun, ...
                profile.frame, ViewProfileBodyPlottingStyle.Dot, false, 0.1);
            bodyData2.addData([midTime-1, midTime+1], ...
                repmat([7000; 0; 0], 1, 2));
            bodyData2.plotBodyMarkerAtTime(midTime, hAx2);
            testCase.verifyNumElements(bodyData2.markerPlot.Children, 1);
        end

        function atmosphereGateRequiresAtmoHeight(testCase)
            testCase.verifyGreaterThan(testCase.kerbin.atmohgt, 0);
            testCase.verifyFalse(testCase.mun.atmohgt > 0, ...
                'Mun must have no atmosphere for the gate test');

            %production condition (Generic3D:456): showAtmosphere && atmohgt > 0
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            profile.showAtmosphere = true;

            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>

            %Kerbin draws the translucent shell
            atmoRadius = testCase.kerbin.radius + testCase.kerbin.atmohgt;
            [X, Y, Z] = sphere(20);
            hold(hAx, 'on');
            hSurf = surf(hAx, atmoRadius*X, atmoRadius*Y, atmoRadius*Z, ...
                'FaceColor', [223 223 223]/255, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            hold(hAx, 'off');
            testCase.verifyClass(hSurf, 'matlab.graphics.chart.primitive.Surface');
            testCase.verifyEqual(hSurf.FaceAlpha, 0.2);

            %Mun draws nothing under the identical flag
            testCase.verifyFalse(profile.showAtmosphere && testCase.mun.atmohgt > 0);

            %flag off draws nothing even for Kerbin
            profile.showAtmosphere = false;
            testCase.verifyFalse(profile.showAtmosphere && testCase.kerbin.atmohgt > 0);
        end

        function sunLightingVisibilityFollowsFlags(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            combos = [false false; false true; true false; true true];
            for k = 1:size(combos, 1)
                [hFig, hAx] = testCase.offscreenAxes();
                cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
                lighting = LaunchVehicleViewProfileSunLighting(hAx, ...
                    profile.frame, combos(k,1), combos(k,2));
                if(combos(k,1))
                    testCase.verifyEqual(lighting.hLight.Visible, matlab.lang.OnOffSwitchState.on, sprintf('row %u light', k));
                else
                    testCase.verifyEqual(lighting.hLight.Visible, matlab.lang.OnOffSwitchState.off, sprintf('row %u light', k));
                end
                if(combos(k,2))
                    testCase.verifyEqual(lighting.hSunVectArrow.Visible, matlab.lang.OnOffSwitchState.on, sprintf('row %u arrow', k));
                else
                    testCase.verifyEqual(lighting.hSunVectArrow.Visible, matlab.lang.OnOffSwitchState.off, sprintf('row %u arrow', k));
                end
                delete(hFig);
            end
        end

        function sunLightingUpdatePositionsSunVector(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            [subStateLogs, ~, ~] = testCase.buildSubStateLogs(lvdData, profile);
            [~, ~, midTime] = testCase.midTime(subStateLogs);

            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            lighting = LaunchVehicleViewProfileSunLighting(hAx, profile.frame, true, true);
            lighting.updateSunLightingPosition(midTime);

            testCase.verifyTrue(all(isfinite(lighting.hLight.Position)));
            testCase.verifyTrue(isfinite(lighting.hSunVectArrow.UData));
            testCase.verifyGreaterThan(norm([lighting.hSunVectArrow.UData, ...
                lighting.hSunVectArrow.VData, lighting.hSunVectArrow.WData]), 0);
        end

        function bodyFixedGridFlagDefaultsAndFrameTypeGate(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            testCase.verifyTrue(profile.showLongLatAnnotations);

            %production gate (Generic3D:296): BodyFixedRotating frame + flag
            bodyFixed = testCase.kerbin.getBodyFixedFrame();
            testCase.verifyEqual(bodyFixed.typeEnum, ReferenceFrameEnum.BodyFixedRotating);
            testCase.verifyTrue(profile.frame.typeEnum ~= ReferenceFrameEnum.BodyFixedRotating, ...
                'Fixture uses the inertial frame, so the grid gate is off by frame');
            testCase.verifyTrue(bodyFixed.typeEnum == ReferenceFrameEnum.BodyFixedRotating && ...
                profile.showLongLatAnnotations, 'Grid would draw in a body-fixed view');

            profile.showLongLatAnnotations = false;
            testCase.verifyFalse(bodyFixed.typeEnum == ReferenceFrameEnum.BodyFixedRotating && ...
                profile.showLongLatAnnotations, 'Flag off suppresses the grid');
        end

        %% --------------------- E. force vectors ------------------------

        function thrustDragSrpVectorSettingsDefaultsDecimationAndScale(testCase)
            profile = LaunchVehicleViewProfile();

            %defaults (LaunchVehicleViewProfile:44-62)
            testCase.verifyEqual(profile.thrustVectColor, ColorSpecEnum.Red);
            testCase.verifyEqual(profile.thrustVectLineType, LineSpecEnum.SolidLine);
            testCase.verifyEqual(profile.dragVectColor, ColorSpecEnum.Magenta);
            testCase.verifyEqual(profile.srpVectColor, ColorSpecEnum.Yellow);
            testCase.verifyEqual(profile.srpVectScale, 1000);

            %production decimation (Generic3D:305,344,371): 1:entryInc:n
            n = 23;
            testCase.verifyNumElements(1:1:n, n);
            testCase.verifyNumElements(1:3:n, 8);
            profile.thrustVectEntryIncr = 3;
            profile.dragVectEntryIncr = 3;
            profile.srpVectEntryIncr = 3;
            testCase.verifyNumElements(1:profile.thrustVectEntryIncr:n, 8);

            %scale multiplies the plotted vectors (production: tVects = scale .* tVects)
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            r = [0 1000; 0 0; 0 0];
            u = [1 1; 0 0; 0 0];
            q1 = quiver3(hAx, r(1,:), r(2,:), r(3,:), ...
                2*u(1,:), 2*u(2,:), 2*u(3,:), 0, 'Color', 'r', 'LineStyle', '-');
            testCase.verifyEqual(q1.UData, [2 2]);
            q2 = quiver3(hAx, r(1,:), r(2,:), r(3,:), ...
                1000*u(1,:), 1000*u(2,:), 1000*u(3,:), 0, 'Color', 'y', 'LineStyle', '-');
            testCase.verifyEqual(q2.UData, [1000 1000]);

            %stored line specs resolve to valid linespecs
            testCase.verifyEqual(profile.thrustVectLineType.linespec, '-');
        end

        %% ------------------ F. spacecraft body axes --------------------

        function scBodyAxesToggleAndScale(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            [subStateLogs, filtEntries, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            vehPosVel = LaunchVehicleViewProfile.createVehPosVelData(subStateLogs, evtsToPlot, profile.frame);
            vehAtt = LaunchVehicleViewProfile.createVehAttitudeData(vehPosVel, filtEntries, evtsToPlot, profile.frame);
            [~, ~, midTime] = testCase.midTime(subStateLogs);

            %on: one hgtransform with 3 quivers of the requested length
            profile.showScBodyAxes = true;
            profile.scBodyAxesScale = 42;
            profile.createBodyAxesData(vehPosVel, vehAtt);
            testCase.verifyTrue(profile.markerTrajAxesData.showScBodyAxes);
            testCase.verifyEqual(profile.markerTrajAxesData.scale, 42);
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            profile.markerTrajAxesData.plotBodyAxesAtTime(midTime, hAx);
            testCase.assertNotEmpty(profile.markerTrajAxesData.markerPlot);
            testCase.assertTrue(isvalid(profile.markerTrajAxesData.markerPlot{1}));
            quivers = findobj(profile.markerTrajAxesData.markerPlot{1}, 'Type', 'Quiver');
            testCase.verifyNumElements(quivers, 3);
            lens = sort([norm([quivers(1).UData, quivers(1).VData, quivers(1).WData]), ...
                norm([quivers(2).UData, quivers(2).VData, quivers(2).WData]), ...
                norm([quivers(3).UData, quivers(3).VData, quivers(3).WData])]);
            testCase.verifyEqual(lens, [42 42 42], 'AbsTol', 1e-9);

            %off: nothing is drawn
            profile.showScBodyAxes = false;
            profile.createBodyAxesData(vehPosVel, vehAtt);
            [hFig2, hAx2] = testCase.offscreenAxes();
            cleanup2 = onCleanup(@() deleteIfValid(hFig2)); %#ok<NASGU>
            profile.markerTrajAxesData.plotBodyAxesAtTime(midTime, hAx2);
            testCase.verifyEmpty(findobj(hAx2, 'Type', 'Quiver'));
        end

        %% ---------------------- G. ground objects ----------------------

        function groundObjGatingAndLoSFlag(testCase)
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;

            kerbinPad = testCase.makeStaticGroundObject(testCase.kerbin, deg2rad(5), deg2rad(30), 2);
            munPad = testCase.makeStaticGroundObject(testCase.mun, deg2rad(5), deg2rad(30), 2);
            lvdData.groundObjs.addGroundObj(kerbinPad);
            lvdData.groundObjs.addGroundObj(munPad);

            [subStateLogs, filtEntries, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            vehPosVel = LaunchVehicleViewProfile.createVehPosVelData(subStateLogs, evtsToPlot, profile.frame);
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>

            %production gate (LaunchVehicleViewProfile:634): plotted iff its
            %body is the view origin or is in bodiesToPlot
            profile.groundObjsToPlot = [kerbinPad, munPad];
            profile.bodiesToPlot = KSPTOT_BodyInfo.empty(1,0);
            profile.createGroundObjMarkerData(hAx, filtEntries, vehPosVel, ...
                evtsToPlot, profile.frame, testCase.celBodyData);
            testCase.verifyNumElements(profile.markerGrdObjData, 1, ...
                'Mun pad skipped: Mun not in bodiesToPlot and origin is Kerbin');
            testCase.verifyEqual(profile.markerGrdObjData(1).groundObj, kerbinPad);

            profile.bodiesToPlot = testCase.mun;
            profile.createGroundObjMarkerData(hAx, filtEntries, vehPosVel, ...
                evtsToPlot, profile.frame, testCase.celBodyData);
            testCase.verifyNumElements(profile.markerGrdObjData, 2);

            %LoS flag is stored per segment and honoured at render time
            [~, ~, midTime] = testCase.midTime(subStateLogs);
            testCase.assertNotEmpty(profile.markerGrdObjData(1).timesArr);
            testCase.verifyTrue(all(profile.markerGrdObjData(1).showGrdObjLoS == profile.showGrdObjLoS));

            profile.showGrdObjLoS = false;
            profile.createGroundObjMarkerData(hAx, filtEntries, vehPosVel, ...
                evtsToPlot, profile.frame, testCase.celBodyData);
            testCase.verifyTrue(all(profile.markerGrdObjData(1).showGrdObjLoS == false));
            profile.markerGrdObjData(1).plotBodyMarkerAtTime(midTime, hAx);
            if(numel(profile.markerGrdObjData(1).losMarkerPlot) >= 1 && ...
                    not(isempty(profile.markerGrdObjData(1).losMarkerPlot{1})) && ...
                    isvalid(profile.markerGrdObjData(1).losMarkerPlot{1}))
                testCase.verifyEqual( ...
                    profile.markerGrdObjData(1).losMarkerPlot{1}.Visible, matlab.lang.OnOffSwitchState.off);
            end
        end

        function groundTrackLineFollowsShowGndTracks(testCase)
            %showGndTracks only gates the extra ground-track plot3 line
            %(LaunchVehicleViewProfile:686); marker data is built either way.
            [lvdData, ~] = testCase.propagatedMission(30, 30);
            profile = lvdData.viewSettings.selViewProfile;
            pad = testCase.makeStaticGroundObject(testCase.kerbin, deg2rad(5), deg2rad(30), 2);
            lvdData.groundObjs.addGroundObj(pad);
            profile.groundObjsToPlot = pad;

            testCase.verifyTrue(profile.showGndTracks);
            profile.showGndTracks = false;
            testCase.verifyFalse(profile.showGndTracks);
            profile.showGndTracks = true;
            testCase.verifyTrue(profile.showGndTracks);
        end

        %% ------------------- H. geometry + sensors ---------------------

        function geometryListsPopulateMarkerData(testCase)
            [lvdData, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;
            [subStateLogs, filtEntries, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            vehPosVel = LaunchVehicleViewProfile.createVehPosVelData(subStateLogs, evtsToPlot, profile.frame);
            vehAtt = LaunchVehicleViewProfile.createVehAttitudeData(vehPosVel, filtEntries, evtsToPlot, profile.frame);
            frame = profile.frame;

            pt = FixedPointInFrame([700; -200; 350], frame, 'pt', lvdData);
            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            origin = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            nvec = FixedVectorInFrame([0; 0; 1], frame, 'n', lvdData);
            plane = PointVectorPlane(origin, nvec, 'plane', lvdData);
            angleObj = TwoVectorAngle(v1, v2, 'angle', lvdData);
            rf = testCase.makeGeometricRefFrame(lvdData);

            profile.pointsToPlot = pt;
            profile.vectorsToPlot = v1;
            profile.refFramesToPlot = rf.geometricFrame;
            profile.anglesToPlot = angleObj;
            profile.planesToPlot = plane;

            profile.createPointData(frame, subStateLogs, evtsToPlot);
            profile.createVectorData(frame, subStateLogs, evtsToPlot);
            profile.createRefFrameData(frame, subStateLogs, evtsToPlot);
            profile.createAngleData(frame, subStateLogs, evtsToPlot);
            profile.createPlaneData(frame, subStateLogs, evtsToPlot);

            testCase.verifyNumElements(profile.pointData, 1);
            testCase.verifyNumElements(profile.vectorData, 1);
            testCase.verifyNumElements(profile.refFrameData, 1);
            testCase.verifyNumElements(profile.angleData, 1);
            testCase.verifyNumElements(profile.planeData, 1);
            testCase.verifyEqual(profile.pointData(1).point, pt);
            testCase.verifyEqual(profile.vectorData(1).vector, v1);

            %sensors need mission membership BEFORE propagation (state log
            %entries only carry states for sensors in lvdData.sensors)
            [lvdData2, ~] = testCase.propagatedMissionWithSensor();
            profile2 = lvdData2.viewSettings.selViewProfile;
            [sub2, filt2, evts2] = testCase.buildSubStateLogs(lvdData2, profile2);
            vehPosVel2 = LaunchVehicleViewProfile.createVehPosVelData(sub2, evts2, profile2.frame);
            vehAtt2 = LaunchVehicleViewProfile.createVehAttitudeData(vehPosVel2, filt2, evts2, profile2.frame);
            profile2.sensorsToPlot = lvdData2.sensors.getSensorAtInd(1);
            profile2.sensorTgtsToPlot = lvdData2.sensorTgts.getPointAtInd(1);
            profile2.createSensorData(filt2, vehPosVel2, vehAtt2, profile2.frame);
            profile2.createSensorTargetData(profile2.frame);
            testCase.verifyNumElements(profile2.sensorData, 1);
            testCase.verifyNumElements(profile2.sensorTgtData, 1);
        end

        function dimensionlessAngleSkipsArcData(testCase)
            %VectorDotProductAngle.isDimensionless -> createAngleData skips it
            %(LaunchVehicleViewProfile:805), other angles are kept.
            [lvdData, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;
            [subStateLogs, ~, evtsToPlot] = testCase.buildSubStateLogs(lvdData, profile);
            frame = profile.frame;

            v1 = FixedVectorInFrame([1; 0; 0], frame, 'v1', lvdData);
            v2 = FixedVectorInFrame([0; 1; 0], frame, 'v2', lvdData);
            scalarAngle = VectorDotProductAngle(v1, v2, 'dot', lvdData);
            testCase.assumeTrue(scalarAngle.isDimensionless(), ...
                'Fixture: dot-product angle must be dimensionless.');
            realAngle = TwoVectorAngle(v1, v2, 'angle', lvdData);

            profile.anglesToPlot = [scalarAngle, realAngle];
            profile.createAngleData(frame, subStateLogs, evtsToPlot);
            testCase.verifyNumElements(profile.angleData, 1, ...
                'Only the drawable angle gets marker data');
            testCase.verifyEqual(profile.angleData(1).angle, realAngle);
        end

        function removeMethodsClearPlottingLists(testCase)
            [lvdData, ~] = testCase.propagatedMission(10, 10);
            profile = lvdData.viewSettings.selViewProfile;
            frame = profile.frame;

            pt = FixedPointInFrame([1; 2; 3], frame, 'pt', lvdData);
            v = FixedVectorInFrame([1; 0; 0], frame, 'v', lvdData);
            origin = FixedPointInFrame([0; 0; 0], frame, 'o', lvdData);
            plane = PointVectorPlane(origin, v, 'plane', lvdData);
            angleObj = TwoVectorAngle(v, v, 'a', lvdData);
            rf = testCase.makeGeometricRefFrame(lvdData);
            [lvdDataS, sensor, tgt] = testCase.sensorPair(lvdData);
            lvdData = lvdDataS;
            profile = lvdData.viewSettings.selViewProfile;
            pad = testCase.makeStaticGroundObject(testCase.kerbin, deg2rad(1), deg2rad(2), 1);

            profile.pointsToPlot = pt;
            profile.vectorsToPlot = v;
            profile.refFramesToPlot = rf.geometricFrame;
            profile.anglesToPlot = angleObj;
            profile.planesToPlot = plane;
            profile.sensorsToPlot = sensor;
            profile.sensorTgtsToPlot = tgt;
            profile.groundObjsToPlot = pad;

            profile.removeGeoPointFromList(pt);
            profile.removeGeoVectorFromList(v);
            profile.removeGeoRefFrameFromList(rf.geometricFrame);
            profile.removeGeoAngleFromList(angleObj);
            profile.removeGeoPlaneFromList(plane);
            profile.removeSensorFromList(sensor);
            profile.removeSensorTargetFromList(tgt);
            profile.removeGrdObjFromList(pad);

            testCase.verifyEmpty(profile.pointsToPlot);
            testCase.verifyEmpty(profile.vectorsToPlot);
            testCase.verifyEmpty(profile.refFramesToPlot);
            testCase.verifyEmpty(profile.anglesToPlot);
            testCase.verifyEmpty(profile.planesToPlot);
            testCase.verifyEmpty(profile.sensorsToPlot);
            testCase.verifyEmpty(profile.sensorTgtsToPlot);
            testCase.verifyEmpty(profile.groundObjsToPlot);
        end

        function sensorTargetWithoutSensorDoesNotError(testCase)
            [lvdData, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;

            pt = FixedPointInFrame([10; 20; 30], profile.frame, 'p', lvdData);
            tgt = PointSensorTargetModel('lonely', pt, lvdData);

            profile.sensorTgtsToPlot = tgt;
            testCase.verifyWarningFree(@() profile.createSensorTargetData(profile.frame));
            testCase.verifyNumElements(profile.sensorTgtData, 1);
            testCase.verifyEmpty(profile.sensorData);
        end

        function removeEventFromListOfPlottedEvents(testCase)
            [lvdData, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = lvdData.script.getEventForInd(2);

            profile.plotAllEvents = false;
            profile.eventsToPlot = [evt1, evt2];
            profile.removeEventFromListOfPlottedEvents(evt1, lvdData.stateLog);
            testCase.verifyNumElements(profile.eventsToPlot, 1);
            testCase.verifyEqual(profile.eventsToPlot, evt2);
        end

        %% ---------------------- I. ground track ------------------------

        function groundTrackTogglesDefaultAndDataBuilders(testCase)
            profile = LaunchVehicleViewProfile();
            testCase.verifyFalse(profile.showCelestialBodyGrdTracks);
            testCase.verifyFalse(profile.showGroundObjsGrdTracks);
            testCase.verifyFalse(profile.showGeomPointsGrdTracks);

            times = (0:10:60)';
            lons = linspace(-170, 170, numel(times))';
            lats = linspace(-60, 60, numel(times))';
            alts = linspace(100, 300, numel(times))';

            %vehicle track
            vehData = LaunchVehicleViewProfileVehicleGrdTrkData();
            vehData.addData(times, lons, lats, alts, ColorSpecEnum.Blue);
            testCase.verifyNumElements(vehData.timesArr, 1);
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            vehData.plotBodyMarkerAtTime(30, hAx);
            testCase.verifyNotEmpty(vehData.markerPlot);
            testCase.verifyEqual(vehData.markerPlot.XData, ...
                vehData.lonInterps{1}(30), 'AbsTol', 1e-9);

            %celestial body track
            celData = LaunchVehicleViewProfileGrdTrkCelBodyData(testCase.mun);
            celData.addData(times, lons, lats, alts);
            testCase.verifyNumElements(celData.timesArr, 1);
            celData.plotCelBodyMarkerAtTime(30, hAx);
            testCase.verifyNotEmpty(celData.markerPlot);

            %ground object track
            pad = testCase.makeStaticGroundObject(testCase.kerbin, deg2rad(5), deg2rad(30), 2);
            grdData = LaunchVehicleViewProfileGrdTrkGroundObjData(pad);
            grdData.addData(times, lons, lats, alts);
            grdData.plotGrdObjMarkerAtTime(30, hAx);
            testCase.verifyNotEmpty(grdData.markerPlot);

            %geometric point track
            [lvdData, ~] = testCase.propagatedMission(10, 10);
            pt = FixedPointInFrame([700; 0; 0], ...
                lvdData.viewSettings.selViewProfile.frame, 'gpt', lvdData);
            geomData = LaunchVehicleViewProfileGrdTrkGeomPointData(pt);
            geomData.addData(times, lons, lats, alts);
            geomData.plotGeomPtMarkerAtTime(30, hAx);
            testCase.verifyNotEmpty(geomData.markerPlot);

            %sun lighting for the ground track honours showLighting
            originBody = testCase.kerbin;
            lit = LaunchVehicleViewProfileGrdTrackSunLighting(hAx, originBody, true);
            unlit = LaunchVehicleViewProfileGrdTrackSunLighting(hAx, originBody, false);
            testCase.verifyTrue(lit.showLighting);
            testCase.verifyFalse(unlit.showLighting);
            lit.updateSunLightingPosition(30);
            testCase.verifyNotEmpty(lit.hGrdTrkNightPatch);
            testCase.verifyNotEmpty(lit.hGrdTrkSunLoc);
            unlit.updateSunLightingPosition(30);
            testCase.verifyEmpty(unlit.hGrdTrkNightPatch);
            testCase.verifyEmpty(unlit.hGrdTrkSunLoc);
        end

        function terrainContourLevelsAffectContourf(testCase)
            profile = LaunchVehicleViewProfile();
            testCase.verifyFalse(profile.showTerrainContours);

            profile.numTerrainContourLevels = 5;
            [hFig, hAx] = testCase.offscreenAxes();
            cleanup = onCleanup(@() deleteIfValid(hFig)); %#ok<NASGU>
            [X, Y, Z] = peaks(25);
            [~, c5] = contourf(hAx, X, Y, Z, 5, '-');
            n5 = numel(c5.LevelList);
            [~, c10] = contourf(hAx, X, Y, Z, 10, '-');
            n10 = numel(c10.LevelList);
            testCase.verifyGreaterThan(n5, 0);
            testCase.verifyGreaterThan(n10, n5, ...
                'numTerrainContourLevels must change the contour resolution');
        end
    end

    methods(Access=private)

        function [lvdData, stateLog] = propagatedMission(testCase, dur1, dur2)
            bodyInfo = testCase.kerbin;
            frame = testCase.kerbinFrame;

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, ...
                bodyInfo.radius + 300, 0, 0.1, 0, 0, 0, frame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(dur1);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(dur2);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);

            %pin the view frame for determinism (fresh profiles start empty)
            profile = lvdData.viewSettings.selViewProfile;
            profile.frame = frame;
        end

        function [lvdData, stateLog] = propagatedMissionWithSensor(testCase)
            bodyInfo = testCase.kerbin;
            frame = testCase.kerbinFrame;

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            originPt = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('cone', deg2rad(10), 1000, originPt, steer, lvdData);
            tgtPt = FixedPointInFrame([100; 0; 0], frame, 'tgt', lvdData);
            tgt = PointSensorTargetModel('t', tgtPt, lvdData);
            lvdData.sensors.addSensor(sensor);
            lvdData.sensorTgts.addTarget(tgt);

            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, ...
                bodyInfo.radius + 300, 0, 0.1, 0, 0, 0, frame);
            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(20);
            evt1.propagatorObj = evt1.twoBodyPropagator;
            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(20);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);
            lvdData.viewSettings.selViewProfile.frame = frame;
        end

        function [lvdData, sensor, tgt] = sensorPair(testCase, lvdData)
            frame = testCase.kerbinFrame;
            originPt = FixedPointInFrame([0; 0; 0], frame, 'origin', lvdData);
            steer = FixedInVehicleFrameSensorSteeringModel(0, 0, 0, lvdData);
            sensor = ConicalSensor('cone', deg2rad(10), 1000, originPt, steer, lvdData);
            tgtPt = FixedPointInFrame([100; 0; 0], frame, 'tgt', lvdData);
            tgt = PointSensorTargetModel('t', tgtPt, lvdData);
        end

        function [subStateLogs, filtEntries, evtsToPlot] = buildSubStateLogs(testCase, lvdData, profile)
            %Replicates Generic3DTrajectoryViewType All-branch filtering so
            %headless tests exercise the same gating without the GUI.
            stateLog = lvdData.stateLog;
            entries = stateLog.getAllEntries();
            maMat = stateLog.getMAFormattedStateLogMatrix(false);

            if(profile.plotAllEvents == false && numel(profile.eventsToPlot) > 0)
                Lia = ismember([entries.event], profile.eventsToPlot);
                entries = entries(Lia);
                eventNumsToPlot = getEventNum(profile.eventsToPlot);
                maMat = maMat(ismember(maMat(:,13), eventNumsToPlot), :);
            end
            filtEntries = entries;

            viewInFrame = profile.frame;
            viewCentralBody = viewInFrame.getOriginBody();
            cartesianEntry = convertToFrame( ...
                getCartesianElementSetRepresentation(entries, false), viewInFrame);
            times = [cartesianEntry.time]';
            rVect = [cartesianEntry.rVect]';
            vVect = [cartesianEntry.vVect]';
            bodyId = viewCentralBody.id + zeros(numel(entries), 1);

            ig = [entries.integrationGroup];
            igNums = [ig.integrationGroupNum];
            subStateLogsMat = [times, rVect, vVect, bodyId, maMat(:,9:13), igNums(:)];

            subStateLogs = {};
            for igNum = 1:max(igNums)
                subStateLogs{igNum} = subStateLogsMat(subStateLogsMat(:,14) == igNum, :); %#ok<AGROW>
            end

            if(profile.trajEvtsViewType == ViewEventsTypeEnum.All && ...
                    profile.plotAllEvents == false && numel(profile.eventsToPlot) > 0)
                evtsToPlot = profile.eventsToPlot;
            else
                evtsToPlot = lvdData.script.evts;
            end
        end

        function [minTime, maxTime, midTime] = midTime(~, subStateLogs)
            allT = [];
            for i = 1:numel(subStateLogs)
                if(not(isempty(subStateLogs{i})))
                    allT = [allT; subStateLogs{i}(:,1)]; %#ok<AGROW>
                end
            end
            minTime = min(allT);
            maxTime = max(allT);
            midTime = (minTime + maxTime)/2;
        end

        function [hFig, hAx] = offscreenAxes(testCase) %#ok<INUSD>
            hFig = figure('Visible', 'off');
            hAx = axes(hFig);
            hold(hAx, 'on');
        end

        function grdObj = makeStaticGroundObject(~, bodyInfo, latRad, longRad, altKm)
            frame = bodyInfo.getBodyFixedFrame();
            wayPt = LaunchVehicleGroundObjectWayPt( ...
                GeographicElementSet(0, latRad, longRad, altKm, 0, 0, 0, frame), 100);
            grdObj = LaunchVehicleGroundObject('Pad', "", 0, wayPt);
        end

        function frame = makeGeometricRefFrame(testCase, lvdData)
            baseFrame = testCase.kerbinFrame;
            o = [300; 400; 500];
            origin = FixedPointInFrame(o, baseFrame, 'origin', lvdData);
            primary = FixedPointInFrame(o + [0; 0; 7], baseFrame, 'primary', lvdData);
            planePt = FixedPointInFrame(o + [0; 2; 1], baseFrame, 'plane', lvdData);
            cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
            rf = CoordSysPointRefFrame(cs, origin, 'rf', lvdData);
            frame = UserDefinedGeometricFrame(rf, lvdData);
        end
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        try
            delete(h);
        catch
        end
    end
end
