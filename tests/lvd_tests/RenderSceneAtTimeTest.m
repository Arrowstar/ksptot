classdef RenderSceneAtTimeTest < matlab.uitest.TestCase
    %RenderSceneAtTimeTest lvd_renderSceneAtTime driving the REAL LVD main
    %window (F8): the vehicle mesh appears in the 3-D axes at the vehicle's
    %pose, the chase and scripted camera modes steer the axes camera while
    %the saved manual camera stays untouched, the mouse camera handler is
    %disabled outside Manual mode, and the time slider path still works.

    properties(Access = private)
        celBodyData
        stubMainFig
        figuresBefore
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();

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
        end
    end

    methods(TestMethodSetup)
        function snapshotFigures(testCase)
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)

        function meshIsDrawnAtTheVehiclePose(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();

            meshPath = [tempname(), '.stl'];
            cleanup = onCleanup(@() deleteIfExists(meshPath)); %#ok<NASGU>
            ksptotWriteTestMesh('stl-binary', meshPath);
            profile.vehicleMesh.loadFromFile(meshPath);
            profile.vehicleMesh.scale = 0.005;
            profile.vehicleMesh.rotOffsetEulerDeg = [15 0 0];
            app.lvdEnhancementsRefresh(false);   %rebuild marker data with the mesh

            [t, rView, dcmView] = testCase.loggedPoseInViewFrame(lvdData, profile, 5);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");

            p = findobj(app.dispAxes, 'Tag', 'LvdVehicleMesh');
            testCase.assertNumElements(p, 1, 'Exactly one vehicle mesh patch in the 3-D axes');
            testCase.verifyEqual(p.Vertices, profile.vehicleMesh.getBodyFrameVertices(), 'AbsTol', 1e-12);

            M = p.Parent.Matrix;
            testCase.verifyEqual(M(1:3,4), rView, 'AbsTol', 1e-6, 'Mesh sits at the vehicle position (view frame km)');
            testCase.verifyEqual(M(1:3,1:3), dcmView, 'AbsTol', 1e-6, 'Mesh carries the body->view attitude');
            testCase.verifyEqual(p.Parent.Visible, matlab.lang.OnOffSwitchState.on);

            %disabling hides it on the next render; a replot drops it entirely
            profile.vehicleMesh.enabled = false;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(p.Parent.Visible, matlab.lang.OnOffSwitchState.off);
            app.lvdEnhancementsRefresh(false);
            testCase.verifyEmpty(findobj(app.dispAxes, 'Tag', 'LvdVehicleMesh'), 'Disabled mesh is not created on replot');
        end

        function chaseModeSteersTheCameraAndProtectsTheManualCamera(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;

            %give the profile a definite saved manual camera
            savedPos = [50000 40000 30000];
            savedTgt = [0 0 0];
            savedUp = [0 0 1];
            profile.updateViewAxesLimits = false;
            profile.viewCameraPosition = savedPos;
            profile.viewCameraTarget = savedTgt;
            profile.viewCameraUpVector = savedUp;
            profile.viewCameraViewAngle = 6.6;
            profile.viewAzEl = [-37.5 30];

            profile.cameraMode = LvdCameraModeEnum.Chase;
            profile.chaseCamera.azDeg = 20;
            profile.chaseCamera.elDeg = 10;
            profile.chaseCamera.rangeKm = 12;
            profile.chaseCamera.viewAngleDeg = 9;

            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx); %unit-scale: axes show km*sAx

            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'Chase camera looks at the vehicle');
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), 12*sAx, 'AbsTol', 1e-6*sAx, 'Chase range');
            expectedPos = LvdCameraMath.sphericalOffset(rView', 20, 10, 12);
            testCase.verifyEqual(hAx.CameraPosition, expectedPos*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifyEqual(hAx.CameraViewAngle, 9, 'AbsTol', 1e-9);

            %the main window's PostSet listeners must not have overwritten
            %the saved manual camera
            testCase.verifyEqual(profile.viewCameraPosition, savedPos, 'Saved manual camera position is preserved in Chase mode');
            testCase.verifyEqual(profile.viewCameraTarget, savedTgt);
            testCase.verifyEqual(profile.viewCameraUpVector, savedUp);
            testCase.verifyEqual(profile.viewCameraViewAngle, 6.6);
            testCase.verifyEqual(profile.viewAzEl, [-37.5 30]);

            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            testCase.verifyTrue(handler.enabled, 'The mouse camera stays enabled while the chase camera drives');
            testCase.verifyClass(handler.cameraDragFcn, 'function_handle', 'Drags are routed to the scene camera driver');

            %back to Manual: the saved camera returns to the axes
            profile.cameraMode = LvdCameraModeEnum.Manual;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition, savedPos*sAx, 'AbsTol', 1e-9, 'Manual restores the saved camera');
            testCase.verifyEqual(hAx.CameraTarget, savedTgt*sAx, 'AbsTol', 1e-9);
            testCase.verifyEqual(profile.viewCameraPosition, savedPos);
            testCase.verifyTrue(handler.enabled, 'Mouse camera is still enabled in Manual mode');
        end

        %% ------------------------------------------------ fixed anchor

        function fixedAnchorFixedXyzSitsAtTheAnchorAndTracksTheVehicle(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;

            %a definite saved manual camera to protect
            savedPos = [50000 40000 30000]; savedTgt = [0 0 0]; savedUp = [0 0 1];
            profile.updateViewAxesLimits = false;
            profile.viewCameraPosition = savedPos;
            profile.viewCameraTarget = savedTgt;
            profile.viewCameraUpVector = savedUp;
            profile.viewCameraViewAngle = 6.6;

            anchor = [1200 -800 400];
            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.FixedXYZ;
            fa.fixedPosition = anchor;
            fa.anchorFrame = profile.frame;   %resolves verbatim in the view frame
            fa.viewAngleDeg = 8;
            profile.cameraMode = LvdCameraModeEnum.FixedAnchor;

            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition, anchor*sAx, 'AbsTol', 1e-6*sAx, 'Camera sits at the fixed anchor');
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'and looks at the vehicle');
            testCase.verifyEqual(hAx.CameraViewAngle, 8, 'AbsTol', 1e-9);

            %the camera stays put while the target tracks as time advances
            [t2, rView2] = testCase.loggedPoseInViewFrame(lvdData, profile, max(2, numel(lvdData.stateLog.getAllEntries())-1));
            testCase.assumeTrue(abs(t2 - t) > 0, 'Need two distinct logged times.');
            lvd_renderSceneAtTime(t2, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, anchor*sAx, 'AbsTol', 1e-6*sAx, 'The fixed camera does not move');
            testCase.verifyEqual(hAx.CameraTarget(:), rView2*sAx, 'AbsTol', 1e-6*sAx, 'The target follows the vehicle');
            testCase.verifyGreaterThan(norm(rView2 - rView), 1e-3, 'Fixture: the vehicle actually moved between the two frames');

            %the saved manual camera is untouched, and Manual restores it
            testCase.verifyEqual(profile.viewCameraPosition, savedPos, 'Saved manual camera preserved in FixedAnchor mode');
            testCase.verifyEqual(profile.viewCameraTarget, savedTgt);
            testCase.verifyEqual(profile.viewCameraViewAngle, 6.6);

            profile.cameraMode = LvdCameraModeEnum.Manual;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, savedPos*sAx, 'AbsTol', 1e-9, 'Manual restores the saved camera');
            testCase.verifyEqual(hAx.CameraTarget, savedTgt*sAx, 'AbsTol', 1e-9);
        end

        function fixedAnchorGroundObjectMovesWithTheBody(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;

            bodyInfo = testCase.celBodyData.kerbin;
            bodyFixed = bodyInfo.getBodyFixedFrame();
            wayPt = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, deg2rad(5), deg2rad(30), 2, 0,0,0, bodyFixed), 100);
            grdObj = LaunchVehicleGroundObject('Pad', "", 0, wayPt);
            grdObj.extrapolateTimes = true;
            lvdData.groundObjs.addGroundObj(grdObj);

            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.groundObject = grdObj;
            profile.cameraMode = LvdCameraModeEnum.FixedAnchor;

            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 3);
            anchor0 = fa.getAnchorPosAtTime(t, profile.frame);
            testCase.assumeNotEmpty(anchor0, 'The ground object must resolve at the test time.');
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition(:), anchor0*sAx, 'AbsTol', 1e-6*sAx, 'Camera at the ground object');
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'looking at the vehicle');

            %at a later time the body-fixed anchor has rotated in the view frame
            [t2, rView2] = testCase.loggedPoseInViewFrame(lvdData, profile, max(2, numel(lvdData.stateLog.getAllEntries())-1));
            anchor1 = fa.getAnchorPosAtTime(t2, profile.frame);
            testCase.assumeNotEmpty(anchor1, 'The ground object must resolve at the later time.');
            lvd_renderSceneAtTime(t2, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition(:), anchor1*sAx, 'AbsTol', 1e-6*sAx, 'The camera follows the ground object as the body rotates');
            testCase.verifyEqual(hAx.CameraTarget(:), rView2*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifyEqual(norm(anchor1), norm(anchor0), 'RelTol', 1e-6, 'The ground object keeps its distance from the body centre');
            testCase.verifyGreaterThan(norm(anchor1 - anchor0), 1e-6, 'A rotating body moves a body-fixed anchor in the inertial view frame');
        end

        function fixedXyzMouseDragRetunesTheAnchorAndKeepsTracking(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.FixedXYZ;
            fa.fixedPosition = [1500 0 0];
            fa.anchorFrame = profile.frame;
            profile.cameraMode = LvdCameraModeEnum.FixedAnchor;

            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.assertTrue(handler.enabled, 'FixedAnchor mode must not disable the mouse');

            changed = CallRecorder();
            addlistener(profile.getCameraDriver(), 'CameraChangedByUser', @(~,~) changed.record(true));

            anchorBefore = fa.fixedPosition;
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([160 110]);
            handler.endDrag();

            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.FixedAnchor, 'A FixedXYZ drag stays in FixedAnchor mode');
            testCase.verifyEqual(fa.anchorType, LvdCameraAnchorTypeEnum.FixedXYZ);
            testCase.verifyGreaterThan(norm(fa.fixedPosition - anchorBefore), 1e-3, 'The drag retuned the fixed anchor');
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'The target is re-pinned on the vehicle');
            testCase.verifyEqual(hAx.CameraPosition(:), fa.getAnchorPosAtTime(t, profile.frame)*sAx, 'AbsTol', 1e-6*sAx, 'The camera sits at the new anchor');
            testCase.verifyEqual(changed.count(), 1, 'One CameraChangedByUser per drag');

            %the next render keeps the mouse-chosen anchor
            camAfter = hAx.CameraPosition;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, camAfter, 'AbsTol', 1e-6, 'No snap back');
        end

        function objectAnchoredDragTakesManualControl(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            bodyFixed = testCase.celBodyData.kerbin.getBodyFixedFrame();
            wayPt = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, deg2rad(5), deg2rad(30), 2, 0,0,0, bodyFixed), 100);
            grdObj = LaunchVehicleGroundObject('Pad', "", 0, wayPt);
            grdObj.extrapolateTimes = true;
            lvdData.groundObjs.addGroundObj(grdObj);

            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.groundObject = grdObj;
            profile.cameraMode = LvdCameraModeEnum.FixedAnchor;

            [t, ~] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            testCase.assumeNotEmpty(fa.getAnchorPosAtTime(t, profile.frame), 'The ground object must resolve at the test time.');
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");

            %grabbing an object-anchored fixed camera hands over to free look
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([160 110]);
            handler.endDrag();

            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Manual, 'An object-anchored drag takes manual control');
            testCase.verifyTrue(handler.enabled, 'The mouse still works after taking manual control');
        end

        %% ------------------------------------------------ mouse camera

        function mouseDragMathMovesTheCameraAndReportsPhases(testCase)
            %The mouse handler's orbit / pan / dolly, driven through the same
            %beginDrag/applyDrag/endDrag path the window callbacks use.
            [app, ~, ~, ~] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            testCase.verifyTrue(handler.enabled);

            phases = CallRecorder();
            handler.cameraDragFcn = @(ax, phase) phases.record(char(phase));

            pos0 = hAx.CameraPosition; tgt0 = hAx.CameraTarget;
            r0 = norm(pos0 - tgt0);

            %orbit: azimuth about the data Z axis changes, distance does not
            handler.beginDrag('orbit', [100 100]);
            testCase.verifyTrue(handler.isDragInProgress());
            handler.applyDrag([140 100]);   % 40 px -> 20 deg
            handler.endDrag();
            testCase.verifyFalse(handler.isDragInProgress());
            pos1 = hAx.CameraPosition;
            testCase.verifyGreaterThan(norm(pos1 - pos0), 1e-6, 'Orbit moved the camera');
            testCase.verifyEqual(norm(pos1 - hAx.CameraTarget), r0, 'RelTol', 1e-6, 'Orbit keeps the camera distance');
            testCase.verifyEqual(hAx.CameraTarget, tgt0, 'AbsTol', 1e-6, 'Orbit keeps the target');
            testCase.verifyEqual(phases.firstArgs(), {'motion', 'end'}, 'One motion report and one end report');

            %dolly: camera moves along the view line, target fixed, and the
            %distance scales exponentially with the drag
            phases = CallRecorder(); handler.cameraDragFcn = @(ax, phase) phases.record(char(phase));
            r1 = norm(pos1 - hAx.CameraTarget);
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 120]);
            handler.applyDrag([100 140]);
            handler.endDrag();
            pos2 = hAx.CameraPosition;
            d = (pos2 - pos1); v = (hAx.CameraTarget - pos1);
            testCase.verifyEqual(abs(dot(d, v)), norm(d)*norm(v), 'RelTol', 1e-6, 'Dolly moves along the line of sight');
            testCase.verifyEqual(hAx.CameraTarget, tgt0, 'AbsTol', 1e-6);
            testCase.verifyEqual(norm(pos2 - hAx.CameraTarget), r1*exp(-40*handler.DollyRatePerPixel), 'RelTol', 1e-9, '40 px of dolly = exp(-40*rate) of the distance');
            testCase.verifyEqual(phases.firstArgs(), {'motion', 'motion', 'end'});

            %pan: position and target shift by the same offset, one pixel
            %moving the scene by one pixel's worth at the target's depth
            r2 = norm(pos2 - hAx.CameraTarget);
            handler.beginDrag('dollyhv', [100 100]);
            handler.applyDrag([130 110]);
            handler.endDrag();
            shift = hAx.CameraTarget - tgt0;
            testCase.verifyEqual(hAx.CameraPosition - pos2, shift, 'AbsTol', 1e-6, 'Pan translates camera and target together');
            testCase.verifyEqual(norm(shift), norm([30 10]) * handler.worldUnitsPerPixel(r2), 'RelTol', 1e-6, 'Pan distance is pixels x world units per pixel');
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), r2, 'RelTol', 1e-9, 'Pan keeps the camera distance');

            %a disabled handler is a switch, not the default
            handler.enabled = false;
            testCase.verifyFalse(handler.enabled);
            handler.enabled = true;
        end

        function dollyAndPanStayGentleCloseToTheTargetAndNeverPassThroughIt(testCase)
            %The bug report: with the camera a few km from a chased vehicle in
            %a planet-sized scene, a tiny dolly rammed the camera through the
            %target and out the other side, because the step was scaled by the
            %axes limits (thousands of km) rather than the camera distance.
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            %planet-scale axes, camera 0.05 km from the vehicle
            profile.cameraMode = LvdCameraModeEnum.Chase;
            profile.chaseCamera.rangeKm = 0.05; profile.chaseCamera.azDeg = 30; profile.chaseCamera.elDeg = 10;
            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            limSpans = [diff(hAx.XLim), diff(hAx.YLim), diff(hAx.ZLim)];
            testCase.verifyEqual(max(limSpans), 1, 'RelTol', 0.05, 'Fixture: the unit-scaled scene spans ~1');
            sight0 = hAx.CameraTarget - hAx.CameraPosition;

            %one pixel of dolly moves the camera ~1% of its distance
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 101]);
            handler.endDrag();
            r = norm(hAx.CameraPosition - hAx.CameraTarget);
            testCase.verifyEqual(r, 0.05*sAx*exp(-handler.DollyRatePerPixel), 'RelTol', 1e-6, 'One pixel is one percent of the distance');
            testCase.verifyGreaterThan(dot(hAx.CameraTarget - hAx.CameraPosition, sight0), 0, 'The camera is still on the same side of the target');

            %a huge dolly gets very close but never crosses; dragging back returns
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 1100]);   % 1000 px toward the target
            handler.endDrag();
            rClose = norm(hAx.CameraPosition - hAx.CameraTarget);
            testCase.verifyGreaterThan(rClose, 0);
            testCase.verifyLessThan(rClose, 1e-3*sAx);
            testCase.verifyGreaterThan(dot(hAx.CameraTarget - hAx.CameraPosition, sight0), 0, 'Never through the target');
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 -900]);   % 1000 px back out
            handler.endDrag();
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), r, 'RelTol', 1e-6, 'Dolly is reversible');
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'Chase keeps the target on the vehicle throughout');
            testCase.verifyEqual(profile.chaseCamera.rangeKm, r/sAx, 'RelTol', 1e-6, 'The chase range followed the dolly');

            %pan is proportional to the distance too: 10 px at 0.05 km is a
            %small fraction of a km, not tens of km
            handler.beginDrag('dollyhv', [100 100]);
            handler.applyDrag([110 100]);
            handler.endDrag();
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");   %chase re-pins the target
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifyLessThan(norm(hAx.CameraPosition - hAx.CameraTarget), 0.2*sAx, 'A short pan near the vehicle stays near the vehicle');
        end

        function mouseDragInChaseModeRetunesTheChaseOffsets(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            profile.cameraMode = LvdCameraModeEnum.Chase;
            profile.chaseCamera.azDeg = 20; profile.chaseCamera.elDeg = 10; profile.chaseCamera.rangeKm = 12; profile.chaseCamera.viewAngleDeg = 9;
            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.assertTrue(handler.enabled, 'Chase mode must not disable the mouse');

            changed = CallRecorder();
            addlistener(profile.getCameraDriver(), 'CameraChangedByUser', @(~,~) changed.record(true));

            %dolly in: the chase range follows the mouse
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 140]);
            handler.endDrag();
            newRange = profile.chaseCamera.rangeKm;
            testCase.verifyNotEqual(newRange, 12, 'The dolly changed the chase range');
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), newRange*sAx, 'RelTol', 1e-6, 'Camera distance equals the new chase range');
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'Still looking at the vehicle');
            testCase.verifyEqual(changed.count(), 1, 'One CameraChangedByUser per drag');

            %orbit: azimuth follows, range stays
            azBefore = profile.chaseCamera.azDeg;
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([140 100]);   % 20 deg
            handler.endDrag();
            testCase.verifyEqual(abs(angleNegPiToPi(deg2rad(profile.chaseCamera.azDeg - azBefore))), deg2rad(20), 'AbsTol', deg2rad(0.5), 'Orbit retuned the chase azimuth');
            testCase.verifyEqual(profile.chaseCamera.rangeKm, newRange, 'RelTol', 1e-6, 'Orbit kept the chase range');

            %the next render keeps the mouse-chosen view: no snap back
            camAfterDrag = hAx.CameraPosition;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, camAfterDrag, 'AbsTol', 1e-6, 'The chase camera keeps following from where the user left it');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Chase, 'Chase mode is kept');
        end

        function mouseDragInScriptedModeDetachesTheCameraAndKeepsScriptMode(testCase)
            %Authoring loop: a drag in Camera Script mode takes the camera off
            %the script WITHOUT leaving the mode; the camera then keeps the
            %user's offset from the vehicle while the time is scrubbed (or
            %stays put for scene-fixed authoring) until the script is resumed.
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            [tStart, tEnd] = lvdData.stateLog.getStartAndEndTimes();

            a = LvdCameraKeyframe(); a.absTime = tStart; a.camPosition = [1000 0 0]; a.camTarget = [0 0 0];
            b = LvdCameraKeyframe(); b.absTime = tEnd;   b.camPosition = [0 1000 0]; b.camTarget = [0 0 0];
            profile.cameraScript.addKeyframe(a); profile.cameraScript.addKeyframe(b);
            profile.cameraMode = LvdCameraModeEnum.Scripted;
            tMid = (tStart + tEnd)/2;
            lvd_renderSceneAtTime(tMid, lvdData, handles, app, "full");
            testCase.assertTrue(handler.enabled, 'Scripted mode must not disable the mouse');
            driver = profile.getCameraDriver();
            scriptPose = hAx.CameraPosition;
            savedBefore = profile.viewCameraPosition;

            changed = CallRecorder();
            addlistener(driver, 'CameraChangedByUser', @(~,~) changed.record(true));

            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([160 110]);
            handler.endDrag();
            dragged = hAx.CameraPosition;

            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Scripted, 'Dragging does NOT leave Camera Script mode');
            testCase.verifyTrue(driver.isScriptDetached(), 'The camera is detached from the script');
            testCase.verifyGreaterThanOrEqual(changed.count(), 1, 'Listeners (the playback window) are told');
            testCase.verifyEqual(profile.viewCameraPosition, savedBefore, 'AbsTol', 1e-9, 'The saved manual camera is untouched');
            testCase.verifyGreaterThan(norm(dragged - scriptPose), 1e-3, 'The drag moved the camera');

            %default (vehicle-relative authoring): scrubbing keeps the user's
            %offset from the vehicle, so the vehicle stays framed
            vehMid = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid);
            sAx = LvdSceneNormalizer.getScale(hAx);
            range = norm(dragged(:) - vehMid(:)*sAx);
            [t4, rView4] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t4, lvdData, handles, app, "full");
            testCase.verifyTrue(driver.isScriptDetached(), 'Scrubbing keeps the camera detached');
            testCase.verifyEqual(hAx.CameraTarget(:), rView4*sAx, 'AbsTol', 1e-6*sAx, 'A detached camera keeps looking at the vehicle');
            testCase.verifyEqual(norm(hAx.CameraPosition(:) - rView4*sAx), range, 'RelTol', 1e-6, 'at the range the user set');
            testCase.verifyEqual(profile.viewCameraPosition, savedBefore, 'AbsTol', 1e-9, 'Still no leak into the saved manual camera');

            %scene-fixed authoring: the camera stays exactly where it was left
            driver.setDetachedFollowMode(false);
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([120 100]);
            handler.endDrag();
            left = hAx.CameraPosition;
            lvd_renderSceneAtTime(tMid, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, left, 'AbsTol', 1e-6, 'Scene-fixed authoring leaves the camera where the user put it');

            %resume: the script drives the camera again from the next frame
            driver.resumeScript();
            testCase.verifyFalse(driver.isScriptDetached());
            lvd_renderSceneAtTime(tMid, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, scriptPose, 'AbsTol', 1e-6, 'The script pose is back');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Scripted);
        end

        function toolbarCameraModesInChaseModeOrbitTheVehicleAndRetune(testCase)
            %Camera changes made through the camera toolbar modes (which
            %bypass the mouse handler) must also retune the chase camera,
            %and the camera target must stay pinned on the vehicle so an
            %orbit orbits the vehicle.
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            hFig = app.ma_LvdMainGUI;

            profile.cameraMode = LvdCameraModeEnum.Chase;
            profile.chaseCamera.azDeg = 30; profile.chaseCamera.elDeg = 15; profile.chaseCamera.rangeKm = 20;
            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.assertEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx);

            %toolbar orbit: the camera position moves about the target
            cameratoolbar(hFig, 'SetMode', 'orbit');
            cleanup = onCleanup(@() cameratoolbar(hFig, 'SetMode', 'nomode')); %#ok<NASGU>
            camorbit(hAx, 25, 0, 'data', [0 0 1]);
            drawnow;
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'The target stays on the vehicle through an orbit');
            testCase.verifyEqual(abs(angleNegPiToPi(deg2rad(profile.chaseCamera.azDeg - 30))), deg2rad(25), 'AbsTol', deg2rad(0.5), 'The orbit retuned the chase azimuth');
            testCase.verifyEqual(profile.chaseCamera.rangeKm, 20, 'RelTol', 1e-6, 'Orbit keeps the range');

            %toolbar dolly: the main window's listener drags the target along
            %to keep the distance; in Chase mode the target snaps back to the
            %vehicle and the dolly becomes a range change
            cameratoolbar(hFig, 'SetMode', 'dollyfb');
            dir = (hAx.CameraTarget - hAx.CameraPosition); dir = dir/norm(dir);
            hAx.CameraPosition = hAx.CameraPosition + (8*sAx)*dir;   % 8 km closer
            drawnow;
            testCase.verifyEqual(hAx.CameraTarget(:), rView*sAx, 'AbsTol', 1e-6*sAx, 'The target is re-pinned on the vehicle after a dolly');
            testCase.verifyEqual(profile.chaseCamera.rangeKm, 12, 'RelTol', 1e-3, 'The dolly retuned the chase range');
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), profile.chaseCamera.rangeKm*sAx, 'RelTol', 1e-6);

            %the next frame keeps the user's view
            cameratoolbar(hFig, 'SetMode', 'nomode');
            camBefore = hAx.CameraPosition;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, camBefore, 'AbsTol', 1e-6, 'No snap back on the next render');

            %a programmatic camera change with no gesture in progress is NOT
            %taken as user input: the next render restores the chase pose
            hAx.CameraPosition = hAx.CameraPosition + (500*sAx)*[1 0 0];
            drawnow;
            testCase.verifyEqual(profile.chaseCamera.rangeKm, 12, 'RelTol', 1e-3, 'Chase offsets untouched by a programmatic change');
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, camBefore, 'AbsTol', 1e-6, 'The chase pose is re-applied');
        end

        function toolbarCameraModesInScriptedModeDetachTheCamera(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            hFig = app.ma_LvdMainGUI;
            [tStart, tEnd] = lvdData.stateLog.getStartAndEndTimes();

            a = LvdCameraKeyframe(); a.absTime = tStart; a.camPosition = [1000 0 0]; a.camTarget = [0 0 0];
            b = LvdCameraKeyframe(); b.absTime = tEnd;   b.camPosition = [0 1000 0]; b.camTarget = [0 0 0];
            profile.cameraScript.addKeyframe(a); profile.cameraScript.addKeyframe(b);
            profile.cameraMode = LvdCameraModeEnum.Scripted;
            tMid = (tStart + tEnd)/2;
            lvd_renderSceneAtTime(tMid, lvdData, handles, app, "full");
            driver = profile.getCameraDriver();
            driver.setDetachedFollowMode(false);   %scene-fixed authoring: camera stays put
            savedBefore = profile.viewCameraPosition;

            cameratoolbar(hFig, 'SetMode', 'orbit');
            cleanup = onCleanup(@() cameratoolbar(hFig, 'SetMode', 'nomode')); %#ok<NASGU>
            camorbit(hAx, 15, 5, 'data', [0 0 1]);
            drawnow;
            dragged = hAx.CameraPosition;
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Scripted, 'A toolbar orbit keeps Camera Script mode');
            testCase.verifyTrue(driver.isScriptDetached(), 'and detaches the camera from the script');
            testCase.verifyEqual(profile.viewCameraPosition, savedBefore, 'AbsTol', 1e-9, 'The saved manual camera is untouched');
            cameratoolbar(hFig, 'SetMode', 'nomode');
            lvd_renderSceneAtTime(tMid, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, dragged, 'AbsTol', 1e-6, 'The dragged view stays until the script is resumed');
        end

        function closingThePlaybackWindowInChaseModeLeavesTheMouseWorking(testCase)
            %The bug report: after "Show in Chase Camera" and closing the
            %window, pan / orbit / dolly did nothing.
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            handler = lvd_getMouseCameraHandler(app);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            w = lvd_ViewPlaybackGUI_App(lvdData, app, false);
            meshPath = [tempname(), '.stl'];
            cleanup = onCleanup(@() deleteIfExists(meshPath)); %#ok<NASGU>
            ksptotWriteTestMesh('stl-binary', meshPath);
            w.importMeshFromFile(meshPath);
            w.showMeshInChaseCamera();
            testCase.assertEqual(profile.cameraMode, LvdCameraModeEnum.Chase);
            delete(w);

            slider = app.DispAxesTimeSlider;
            lims = slider.Limits;
            slider.ValueChangingFcn(slider, matlab.ui.eventdata.ValueChangingData(lims(1) + 0.5*(lims(2)-lims(1))));

            testCase.verifyTrue(handler.enabled, 'The mouse camera is still enabled');
            pos0 = hAx.CameraPosition;
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([150 100]);
            handler.endDrag();
            testCase.verifyGreaterThan(norm(hAx.CameraPosition - pos0), 1e-6, 'An orbit drag still moves the camera');

            pos1 = hAx.CameraPosition;
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 150]);
            handler.endDrag();
            testCase.verifyGreaterThan(norm(hAx.CameraPosition - pos1), 1e-6, 'A dolly drag still moves the camera');

            %and it keeps working after the slider moves again
            slider.ValueChangingFcn(slider, matlab.ui.eventdata.ValueChangingData(lims(1) + 0.6*(lims(2)-lims(1))));
            pause(0.06);
            pos2 = hAx.CameraPosition;
            handler.beginDrag('dollyhv', [100 100]);
            handler.applyDrag([130 100]);
            handler.endDrag();
            testCase.verifyGreaterThan(norm(hAx.CameraPosition - pos2), 1e-6, 'A pan drag still moves the camera');
            testCase.verifyTrue(handler.enabled);
            lvd_renderSceneAtTime(lims(1), lvdData, handles, app, "none");
            testCase.verifyTrue(handler.enabled, 'Rendering never disables the mouse');
        end

        function scriptedModeFollowsTheKeyframes(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;
            [tStart, tEnd] = lvdData.stateLog.getStartAndEndTimes();

            a = LvdCameraKeyframe(); a.absTime = tStart; a.easing = LvdCameraEasingEnum.Linear;
            a.camPosition = [1000 0 0]; a.camTarget = [0 0 0]; a.camUpVector = [0 0 1]; a.viewAngleDeg = 10;
            b = LvdCameraKeyframe(); b.absTime = tEnd;
            b.camPosition = [0 1000 0]; b.camTarget = [0 0 100]; b.camUpVector = [0 0 1]; b.viewAngleDeg = 20;
            profile.cameraScript.addKeyframe(a);
            profile.cameraScript.addKeyframe(b);
            profile.cameraMode = LvdCameraModeEnum.Scripted;

            lvd_renderSceneAtTime(tStart, lvdData, handles, app, "full");
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition, [1000 0 0]*sAx, 'AbsTol', 1e-9);

            lvd_renderSceneAtTime((tStart + tEnd)/2, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, [500 500 0]*sAx, 'AbsTol', 1e-6*sAx, 'Linear midpoint of the two keyframes');
            testCase.verifyEqual(hAx.CameraTarget, [0 0 50]*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifyEqual(hAx.CameraViewAngle, 15, 'AbsTol', 1e-9);

            lvd_renderSceneAtTime(tEnd, lvdData, handles, app, "full");
            testCase.verifyEqual(hAx.CameraPosition, [0 1000 0]*sAx, 'AbsTol', 1e-9);

            %a replot in scripted mode does not flash the saved manual camera
            %over the script: the first frame after the plot is the script's
            app.lvdEnhancementsRefresh(false);
            sliderTime = app.DispAxesTimeSlider.Value;
            expected = profile.cameraScript.evaluate(sliderTime, @(kf) kf.absTime, @(t) NaN(3,1));
            testCase.verifyEqual(hAx.CameraPosition, expected.position*sAx, 'AbsTol', 1e-6*sAx);
        end

        function sceneIsNormalizedToUnitScale(testCase)
            %The 3-D view nests the scene under a unit-scale transform so
            %the longest axes span is ~1 while profiles stay in km.
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;

            [t, ~, ~] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");

            hNorm = findobj(hAx, 'Tag', 'LvdUnitScale');
            testCase.assertNotEmpty(hNorm, 'The normalization transform is in the 3-D axes');
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyGreaterThan(sAx, 0, 'The scale is positive');
            testCase.verifyLessThan(sAx, 1, 'A planet-scale scene normalizes down');
            spans = [diff(hAx.XLim), diff(hAx.YLim), diff(hAx.ZLim)];
            testCase.verifyEqual(max(spans), 1, 'RelTol', 0.05, 'The longest axes span is ~1');
        end

        function overlayTextIsDrawnInTheMainAxesAndFollowsTime(testCase)
            [app, lvdData, handles, profile] = testCase.openPropagatedLvd();
            hAx = app.dispAxes;

            profile.overlay.enabled = true;
            profile.overlay.title = 'Overlay Test';
            profile.overlay.addQuantity('Altitude', profile.frame);
            app.lvdEnhancementsRefresh(false);   %rebuild the overlay data with the item

            [t, rView] = testCase.loggedPoseInViewFrame(lvdData, profile, 4);
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");

            h = findobj(hAx, 'Tag', 'LvdViewOverlayText');
            testCase.assertNumElements(h, 1, 'The overlay text block is in the 3-D axes');
            testCase.verifyEqual(h.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(h.String{1}, 'Overlay Test');
            altLine = h.String{startsWith(h.String, 'Altitude: ')};
            testCase.verifyNotEmpty(altLine);
            expectedAlt = norm(rView) - profile.frame.getOriginBody().radius;
            shownAlt = sscanf(altLine, 'Altitude: %f');
            testCase.verifyEqual(shownAlt, expectedAlt, 'AbsTol', 1e-2, 'The altitude shown matches the logged state');

            lateInd = max(2, numel(lvdData.stateLog.getAllEntries()) - 1);
            [tLate, rView2] = testCase.loggedPoseInViewFrame(lvdData, profile, lateInd);
            lvd_renderSceneAtTime(tLate, lvdData, handles, app, "full");
            altLine2 = h.String{startsWith(h.String, 'Altitude: ')};
            testCase.verifyEqual(sscanf(altLine2, 'Altitude: %f'), norm(rView2) - profile.frame.getOriginBody().radius, 'AbsTol', 1e-2);

            %the overlay is part of what a video frame captures
            frame = LvdViewExporter.captureAxesFrame(hAx);
            testCase.verifyEqual(size(frame, 3), 3);

            profile.overlay.enabled = false;
            lvd_renderSceneAtTime(t, lvdData, handles, app, "full");
            testCase.verifyEqual(h.Visible, matlab.lang.OnOffSwitchState.off);
        end

        function timeSliderCallbackStillRendersThroughTheThrottle(testCase)
            [app, lvdData, ~, ~] = testCase.openPropagatedLvd(); %#ok<ASGLU>
            slider = app.DispAxesTimeSlider;
            lims = slider.Limits;
            t = lims(1) + 0.5*(lims(2) - lims(1));

            pause(0.06);   %clear the 50 ms throttle window
            slider.ValueChangingFcn(slider, matlab.ui.eventdata.ValueChangingData(t));
            testCase.verifyEqual(getappdata(slider, 'lastTime'), t, 'AbsTol', 1e-9, 'The slider callback rendered at the requested time');
            testCase.verifyNotEmpty(app.timeSliderValueLabel.Text);
        end

        function renderClampsToTheSliderRange(testCase)
            [app, lvdData, handles, ~] = testCase.openPropagatedLvd();
            lims = app.DispAxesTimeSlider.Limits;
            lvd_renderSceneAtTime(lims(2) + 1e6, lvdData, handles, app, "none");
            testCase.verifyEqual(getappdata(app.DispAxesTimeSlider, 'lastTime'), lims(2), 'AbsTol', 1e-9);
            lvd_renderSceneAtTime(lims(1) - 1e6, lvdData, handles, app, "none");
            testCase.verifyEqual(getappdata(app.DispAxesTimeSlider, 'lastTime'), lims(1), 'AbsTol', 1e-9);
        end
    end

    methods(Access = private)
        function [app, lvdData, handles, profile] = openPropagatedLvd(testCase)
            %openPropagatedLvd The real LVD main window on a two-event,
            %two-body mission that has been propagated and plotted.
            testCase.stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(testCase.stubMainFig));

            app = ma_LvdMainGUI_App(testCase.celBodyData, testCase.stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;
            testCase.assertTrue(isvalid(app.ma_LvdMainGUI), 'The LVD main window must open.');

            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            bodyInfo = testCase.celBodyData.kerbin;
            frame = bodyInfo.getBodyCenteredInertialFrame();
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, bodyInfo.radius + 300, 0, 0.1, 0, 0, 0, frame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(120);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(120);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            app.lvdEnhancementsRefresh(true);   %propagate + plot
            drawnow;

            handles = guidata(app.ma_LvdMainGUI);
            profile = lvdData.viewSettings.selViewProfile;
            testCase.assertGreaterThan(lvdData.stateLog.getNumberOfEntries(), 3, 'Fixture: the mission must have propagated.');
            testCase.assertNotEmpty(profile.vehPosVelInterp, 'Fixture: the plot must have built the vehicle interpolants.');
        end

        function [t, rView, dcmView] = loggedPoseInViewFrame(~, lvdData, profile, entryInd)
            %An independent oracle: a logged state converted into the view
            %frame the same way the 3-D view converts trajectories.
            entries = lvdData.stateLog.getAllEntries();
            entry = entries(entryInd);
            t = entry.time;
            ce = entry.getCartesianElementSetRepresentation().convertToFrame(profile.frame);
            rView = ce.rVect(:);

            R_body2bi = entry.steeringModel.getBody2InertialDcmAtTime(entry.time, entry.position, entry.velocity, entry.centralBody);
            [~, ~, ~, R_view2gi] = profile.frame.getOffsetsWrtInertialOrigin(entry.time, ce);
            [~, ~, ~, R_bi2gi] = entry.centralBody.getBodyCenteredInertialFrame().getOffsetsWrtInertialOrigin(entry.time, ce);
            dcmView = R_view2gi' * R_bi2gi * R_body2bi;
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
