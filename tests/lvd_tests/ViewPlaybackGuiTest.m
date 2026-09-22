classdef ViewPlaybackGuiTest < matlab.uitest.TestCase
    %ViewPlaybackGuiTest App Testing Framework coverage of the LVD 3-D View
    %Playback window (lvd_ViewPlaybackGUI_App, F8) against the REAL LVD main
    %window: transport buttons, camera modes, keyframe editing, mesh import
    %and the export seams.
    %
    %   File dialogs are never opened: the public seam methods take paths.
    %   The type gesture is never used (Enter is bound to Save & Close in
    %   LVD editors); values are set directly and buttons are pressed.

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

        %% ------------------------------------------------------- opening

        function windowClassExistsAndOpensHidden(testCase)
            testCase.verifyEqual(exist('lvd_ViewPlaybackGUI_App', 'class'), 8);
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData, false);

            testCase.verifyTrue(startsWith(app.UIFigure.Name, 'LVD 3-D View Playback'));
            testCase.verifySubstring(app.UIFigure.Name, lvdData.viewSettings.selViewProfile.name, 'The title names the active view profile');
            testCase.verifyEqual(app.UIFigure.Tag, 'lvd_ViewPlaybackGUI');
            testCase.verifyEqual(app.UIFigure.Visible, matlab.lang.OnOffSwitchState.off);
            [t0, t1] = app.getTimeLimits();
            [s0, s1] = lvdData.stateLog.getStartAndEndTimes();
            testCase.verifyEqual([t0 t1], [s0 s1], 'AbsTol', 1e-9, 'The window adopts the trajectory''s time range');
            testCase.verifyEqual(app.PlayButton.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function opensFromTheMainWindowViewMenu(testCase)
            %The launcher is a real App Designer canvas component of the
            %main window (View menu), added with lvdfixCanvasizeF8.
            [mainApp, ~] = testCase.openPropagatedLvd();
            viewMenuItems = {mainApp.viewMenu.Children.Text};
            testCase.assertTrue(any(strcmp(viewMenuItems, '3-D View Playback, Camera and Vehicle Mesh...')), ...
                'The View menu must carry the playback launcher item.');

            item = testCase.menuItem(mainApp.viewMenu, '3-D View Playback, Camera and Vehicle Mesh...');
            testCase.press(item);
            drawnow;

            figs = findall(groot, 'Type', 'figure', 'Tag', 'lvd_ViewPlaybackGUI');
            testCase.assertNumElements(figs, 1, 'The playback window opens from the menu');
            testCase.verifyTrue(startsWith(figs.Name, 'LVD 3-D View Playback'));
            testCase.verifyEqual(figs.Visible, matlab.lang.OnOffSwitchState.on);

            app = getappdata(figs, 'LvdViewPlaybackApp');
            testCase.assertTrue(isa(app, 'lvd_ViewPlaybackGUI_App') && isvalid(app));
            testCase.verifyEqual(app.PlayButton.Enable, matlab.lang.OnOffSwitchState.on, 'A propagated mission enables playback');

            %pressing the menu item again raises the same window
            testCase.press(item);
            drawnow;
            testCase.verifyNumElements(findall(groot, 'Type', 'figure', 'Tag', 'lvd_ViewPlaybackGUI'), 1);
        end

        function openingTwiceRaisesTheSameWindow(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app1 = testCase.openWindow(mainApp, lvdData, false);
            app2 = lvd_ViewPlaybackGUI_App(lvdData, mainApp, false);
            testCase.verifySameHandle(app2, app1, 'A second open returns the existing window');
            figs = findall(groot, 'Type', 'figure', 'Tag', 'lvd_ViewPlaybackGUI');
            testCase.verifyNumElements(figs, 1);
        end

        %% ------------------------------------------------------ playback

        function playAdvancesTheMainWindowSliderAndPauseStops(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            slider = mainApp.DispAxesTimeSlider;
            lims = slider.Limits;

            %20x: the 240 s trajectory takes ~12 s of wall time, so the pause
            %gesture (which itself takes a moment) lands well before the end
            app.SpeedEditField.Value = 20;
            app.FpsEditField.Value = 20;
            testCase.press(app.PlayButton);
            testCase.verifyEqual(app.getController().state, "playing");
            pause(0.4);
            testCase.press(app.PauseButton);
            testCase.verifyEqual(app.getController().state, "paused");

            tPaused = slider.Value;
            testCase.verifyGreaterThan(tPaused, lims(1) + 2, 'The main window slider advanced while playing');
            testCase.verifyLessThan(tPaused, lims(2), 'Paused before the end');
            testCase.verifyEqual(getappdata(slider, 'lastTime'), tPaused, 'AbsTol', 1e-9, 'The scene was rendered at the slider time');
            pause(0.15);
            testCase.verifyEqual(slider.Value, tPaused, 'Paused: the slider stays put');
            testCase.verifySubstring(app.TimeLabel.Text, 'UT');

            testCase.press(app.StopButton);
            testCase.verifyEqual(app.getController().state, "stopped");
            testCase.verifyEqual(slider.Value, lims(1), 'AbsTol', 1e-9, 'Stop returns to the start');

            testCase.press(app.StepFwdButton);
            testCase.verifyEqual(slider.Value, lims(1) + 20/20, 'AbsTol', 1e-9, 'One frame = speed/fps seconds');
            testCase.press(app.GoToEndButton);
            testCase.verifyEqual(slider.Value, lims(2), 'AbsTol', 1e-9);
            testCase.press(app.GoToStartButton);
            testCase.verifyEqual(slider.Value, lims(1), 'AbsTol', 1e-9);

            testCase.verifyEqual(lvdData.viewSettings.selViewProfile.playbackSettings.simSecPerRealSec, 20, 'Speed was saved on the profile');
        end

        function loopCheckboxAndPlaybackFieldsWriteThrough(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            settings = lvdData.viewSettings.selViewProfile.playbackSettings;

            testCase.press(app.LoopCheckBox);
            testCase.verifyTrue(settings.loop);
            testCase.choose(app.VideoFormatDropDown, 'GIF');
            testCase.verifyEqual(settings.videoFormat, "GIF");
            app.QualityEditField.Value = 55;
            app.applyPlaybackFields();
            testCase.verifyEqual(settings.videoQuality, 55);
            app.ExportStartEditField.Value = '12.5';
            app.applyPlaybackFields();
            testCase.verifyEqual(settings.exportStartTime, 12.5);
            app.ExportStartEditField.Value = '';
            app.applyPlaybackFields();
            testCase.verifyTrue(isnan(settings.exportStartTime), 'Blank means "from the start"');
        end

        %% -------------------------------------------------------- camera

        function chaseModeFromTheDropDownTracksTheVehicle(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Chase Camera');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Chase);
            testCase.verifyEqual(app.ChaseRangeEditField.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.KeyframeTable.Enable, matlab.lang.OnOffSwitchState.on, 'The script can be authored in any camera mode');
            testCase.verifyEqual(app.ResumeScriptButton.Enable, matlab.lang.OnOffSwitchState.off, 'but there is nothing to resume outside Camera Script mode');
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'CHASE');

            app.ChaseRangeEditField.Value = 33;
            app.applyChaseFields();
            testCase.verifyEqual(profile.chaseCamera.rangeKm, 33);

            [t0, t1] = app.getTimeLimits();
            tMid = (t0 + t1)/2;
            app.stepTo(tMid);
            vehPos = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid);
            hAx = mainApp.dispAxes;
            sAx = LvdSceneNormalizer.getScale(hAx); %unit-scale: axes show km*sAx
            testCase.verifyEqual(hAx.CameraTarget(:), vehPos*sAx, 'AbsTol', 1e-6*sAx, 'Chase camera looks at the vehicle');
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), 33*sAx, 'AbsTol', 1e-6*sAx);

            testCase.choose(app.CameraModeDropDown, 'Manual');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Manual);
        end

        function fixedAnchorFixedCoordinatesTracksTheVehicleFromTheDropDown(testCase)
            %"Fixed Camera (Tracking)" with a Fixed-Coordinates anchor: the
            %camera sits at the anchor and keeps the vehicle centred, with a
            %fixed field of view.  An inertial anchor stays put as time runs.
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            fa = profile.fixedAnchorCamera;
            hAx = mainApp.dispAxes;

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Fixed Camera (Tracking)');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.FixedAnchor);
            testCase.verifyEqual(app.AnchorTypeDropDown.Enable, matlab.lang.OnOffSwitchState.on, ...
                'The fixed-anchor panel enables in FixedAnchor mode');
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'FIXED (TRACKING)');

            %strict per-mode visibility: only the Fixed Camera panel is shown,
            %and the other modes' rows collapse so nothing is pushed off-screen
            testCase.verifyEqual(app.FixedAnchorPanel.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.ChasePanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.ScriptPanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.CameraGrid.RowHeight{2}, 0, 'Chase row collapsed');
            testCase.verifyEqual(app.CameraGrid.RowHeight{3}, 0, 'Script row collapsed');
            testCase.verifyGreaterThan(app.CameraGrid.RowHeight{4}, 0, 'Fixed Camera row is shown');

            %a fixed XYZ anchor in the view frame + a fixed field of view
            testCase.choose(app.AnchorTypeDropDown, 'Fixed Coordinates');
            testCase.verifyEqual(app.FixedXYZSubGrid.Visible, matlab.lang.OnOffSwitchState.on, ...
                'The Fixed-Coordinates inputs are shown');
            testCase.verifyEqual(app.GroundObjSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.GeomPtSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            app.setFixedAnchorPosition([1500 -900 600], profile.frame);
            app.setFixedAnchorViewAngle(9);
            testCase.verifyEqual(fa.anchorType, LvdCameraAnchorTypeEnum.FixedXYZ);
            testCase.verifyEqual(fa.fixedPosition, [1500 -900 600]);

            [t0, t1] = app.getTimeLimits();
            tMid = (t0 + t1)/2;
            app.stepTo(tMid);
            anchor = fa.getAnchorPosAtTime(tMid, profile.frame);
            vehMid = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid);
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition(:), anchor*sAx, 'AbsTol', 1e-6*sAx, 'Camera sits at the fixed anchor');
            testCase.verifyEqual(hAx.CameraTarget(:), vehMid*sAx, 'AbsTol', 1e-6*sAx, 'and looks at the vehicle');
            testCase.verifyEqual(hAx.CameraViewAngle, 9, 'AbsTol', 1e-6, 'The fixed field of view is applied');

            %the anchor is inertial: advancing time keeps the camera put but re-aims it
            camAtMid = hAx.CameraPosition;
            app.stepTo(t1);
            vehEnd = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, t1);
            testCase.verifyEqual(hAx.CameraPosition, camAtMid, 'AbsTol', 1e-6, 'An inertial anchor does not move as time advances');
            testCase.verifyEqual(hAx.CameraTarget(:), vehEnd*sAx, 'AbsTol', 1e-6*sAx, 'but keeps tracking the vehicle');

            %"Set From Current Camera" grabs the live camera as the anchor
            app.setFixedAnchorFromCamera();
            testCase.verifyTrue(ismember('Set Fixed Anchor from Current View', app.UndoLog));
            testCase.verifyEqual(fa.getAnchorPosAtTime(app.getCurrentTime(), profile.frame)*sAx, ...
                                 hAx.CameraPosition(:), 'AbsTol', 1e-6*sAx, 'The grabbed anchor resolves back to the camera position');

            %one undo state per real edit
            testCase.verifyTrue(ismember('Change Camera Mode', app.UndoLog));
            testCase.verifyTrue(ismember('Edit Fixed Anchor Camera', app.UndoLog));

            testCase.choose(app.CameraModeDropDown, 'Manual');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Manual);
        end

        function fixedAnchorObjectAnchorsTrackFromTheObjectDropDowns(testCase)
            %The Ground Object and Geometric Point anchors: the camera sits on
            %the chosen mission object (resolved into the view frame) and keeps
            %the vehicle centred.  Exercised through the anchor-type and object
            %dropdowns.
            [mainApp, lvdData] = testCase.openPropagatedLvd();

            %a ground object on the body-fixed frame and a fixed geometric point
            bodyInfo = testCase.celBodyData.kerbin;
            grdObj = makeStaticGroundObject(bodyInfo, deg2rad(5), deg2rad(30), 2);
            lvdData.groundObjs.addGroundObj(grdObj);
            pt = FixedPointInFrame([700 -200 350], bodyInfo.getBodyCenteredInertialFrame(), 'Pad Point', lvdData);
            lvdData.geometry.points.addPoint(pt);

            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            fa = profile.fixedAnchorCamera;
            hAx = mainApp.dispAxes;
            [t0, t1] = app.getTimeLimits();
            tMid = (t0 + t1)/2;

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Fixed Camera (Tracking)');

            %--- Ground Object anchor via the anchor-type dropdown + object seam
            %(the object dropdown auto-selects its only item, so choosing it is
            %a no-op; setAnchorGroundObject is the seam behind its callback)
            testCase.choose(app.AnchorTypeDropDown, 'Ground Object');
            testCase.verifyEqual(fa.anchorType, LvdCameraAnchorTypeEnum.GroundObject);
            testCase.assertTrue(any(strcmp(app.AnchorGroundObjectDropDown.Items, grdObj.name)), ...
                'The mission''s ground object appears in the picker');
            app.setAnchorGroundObject(grdObj);
            testCase.verifySameHandle(fa.groundObject, grdObj);

            app.stepTo(tMid);
            anchor = fa.getAnchorPosAtTime(tMid, profile.frame);
            testCase.assertNotEmpty(anchor);
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition(:), anchor*sAx, 'AbsTol', 1e-6*sAx, 'Camera sits on the ground object');
            testCase.verifyEqual(hAx.CameraTarget(:), LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid)*sAx, ...
                'AbsTol', 1e-6*sAx, 'and looks at the vehicle');

            %--- Geometric Point anchor via the anchor-type dropdown + object seam
            gpStr = pt.getListboxStr();
            testCase.choose(app.AnchorTypeDropDown, 'Geometric Point');
            testCase.verifyEqual(fa.anchorType, LvdCameraAnchorTypeEnum.GeometricPoint);
            %only the geometric-point sub-grid is shown (the FixedXYZ inputs
            %collapse rather than leaving empty reserved rows above the dropdown)
            testCase.verifyEqual(app.GeomPtSubGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.FixedXYZSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.GroundObjSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.assertTrue(any(strcmp(app.AnchorGeometricPointDropDown.Items, gpStr)), ...
                'The (vehicle-independent) geometric point appears in the picker');
            app.setAnchorGeometricPoint(pt);
            testCase.verifySameHandle(fa.geometricPoint, pt);

            app.stepTo(tMid);
            anchorPt = fa.getAnchorPosAtTime(tMid, profile.frame);
            testCase.assertNotEmpty(anchorPt);
            testCase.verifyEqual(hAx.CameraPosition(:), anchorPt*sAx, 'AbsTol', 1e-6*sAx, 'Camera sits on the geometric point');
            testCase.verifyEqual(hAx.CameraTarget(:), LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid)*sAx, ...
                'AbsTol', 1e-6*sAx, 'and keeps tracking the vehicle');

            %the object-anchor edits recorded undo states
            testCase.verifyTrue(ismember('Edit Fixed Anchor Camera', app.UndoLog));

            testCase.choose(app.CameraModeDropDown, 'Manual');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Manual);
        end

        function anchorTypeSelectionSeedsObjectWithoutDropdownCallback(testCase)
            %Regression: the anchor object dropdown auto-shows its first item
            %but never fires its ValueChangedFcn on populate (and cannot fire at
            %all when it holds a single item), so choosing the anchor TYPE must
            %itself seed the anchor object.  Otherwise the anchor stays empty,
            %getAnchorPosAtTime returns [], the pose is [], and the tracking
            %camera never resolves (no axes update on the switch, no tracking
            %during playback) -- the reported "no tracking with Ground Objects".
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            bodyInfo = testCase.celBodyData.kerbin;
            pt = FixedPointInFrame([700 -200 350], bodyInfo.getBodyCenteredInertialFrame(), 'Pad Point', lvdData);
            lvdData.geometry.points.addPoint(pt);

            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            fa = profile.fixedAnchorCamera;
            hAx = mainApp.dispAxes;
            [t0, t1] = app.getTimeLimits();
            tMid = (t0 + t1)/2;

            testCase.assertNotEmpty(lvdData.groundObjs.getListboxStr(), ...
                'Precondition: the mission has a ground object to anchor to');
            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Fixed Camera (Tracking)');

            %choosing the anchor type ALONE (no setAnchorGroundObject seam) must
            %seed a ground object so the camera resolves
            testCase.choose(app.AnchorTypeDropDown, 'Ground Object');
            testCase.verifyNotEmpty(fa.groundObject, ...
                'Choosing the Ground Object anchor type seeds a ground object');
            app.stepTo(tMid);
            anchor = fa.getAnchorPosAtTime(tMid, profile.frame);
            testCase.assertNotEmpty(anchor);
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition(:), anchor*sAx, 'AbsTol', 1e-6*sAx, ...
                'Camera resolves onto the seeded ground object');
            testCase.verifyEqual(hAx.CameraTarget(:), ...
                LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid)*sAx, ...
                'AbsTol', 1e-6*sAx, 'and tracks the vehicle');

            %likewise a geometric point seeds on choosing its type
            testCase.choose(app.AnchorTypeDropDown, 'Geometric Point');
            testCase.verifyNotEmpty(fa.geometricPoint, ...
                'Choosing the Geometric Point anchor type seeds a geometric point');
            app.stepTo(tMid);
            anchorPt = fa.getAnchorPosAtTime(tMid, profile.frame);
            testCase.assertNotEmpty(anchorPt);
            testCase.verifyEqual(hAx.CameraPosition(:), anchorPt*sAx, 'AbsTol', 1e-6*sAx, ...
                'Camera resolves onto the seeded geometric point');
        end

        function switchingIntoFixedAnchorModeSeedsEmptyAnchorObject(testCase)
            %Regression: a profile whose anchor type is Ground Object but whose
            %ground object is empty (e.g. a profile saved by an older build)
            %must resolve when the user switches into Fixed Camera (Tracking)
            %mode, rather than rendering nothing.
            [mainApp, lvdData] = testCase.openPropagatedLvd();

            profile = lvdData.viewSettings.selViewProfile;
            fa = profile.fixedAnchorCamera;
            fa.anchorType = LvdCameraAnchorTypeEnum.GroundObject;
            fa.groundObject = LaunchVehicleGroundObject.empty(1,0);   %the stale/empty state

            app = testCase.openWindow(mainApp, lvdData);
            testCase.choose(app.CameraTab);
            testCase.assertTrue(isempty(fa.groundObject), 'Precondition: anchor object starts empty');
            testCase.assertNotEmpty(lvdData.groundObjs.getListboxStr(), ...
                'Precondition: the mission has a ground object to seed');

            testCase.choose(app.CameraModeDropDown, 'Fixed Camera (Tracking)');
            testCase.verifyNotEmpty(fa.groundObject, ...
                'Entering FixedAnchor mode seeds the empty ground-object anchor');
        end

        function manualModeHidesAllCameraConfigPanels(testCase)
            %Manual mode has no camera configuration, so none of the per-mode
            %panels are shown; each shows only in its own mode.
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            testCase.choose(app.CameraTab);

            testCase.choose(app.CameraModeDropDown, 'Manual');
            testCase.verifyEqual(app.ChasePanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.ScriptPanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.FixedAnchorPanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.CameraGrid.RowHeight{2}, 0);
            testCase.verifyEqual(app.CameraGrid.RowHeight{3}, 0);
            testCase.verifyEqual(app.CameraGrid.RowHeight{4}, 0);

            %each mode reveals only its own panel
            testCase.choose(app.CameraModeDropDown, 'Chase Camera');
            testCase.verifyEqual(app.ChasePanel.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.ScriptPanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.FixedAnchorPanel.Visible, matlab.lang.OnOffSwitchState.off);

            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            testCase.verifyEqual(app.ScriptPanel.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.ChasePanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.FixedAnchorPanel.Visible, matlab.lang.OnOffSwitchState.off);

            testCase.choose(app.CameraModeDropDown, 'Manual');
        end

        %% ------------------------------------------- profile awareness

        function windowNamesTheActiveProfileAndFollowsProfileChanges(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData, false);
            vs = lvdData.viewSettings;
            p1 = vs.selViewProfile;

            testCase.verifySubstring(app.UIFigure.Name, p1.name);
            testCase.verifySubstring(app.ProfileHeaderLabel.Text, p1.name);
            testCase.verifySubstring(app.ProfileHeaderLabel.Text, 'ACTIVE VIEW PROFILE');
            testCase.verifySubstring(app.ProfileHeaderLabel.Text, 'Set Active View Profile');

            p2 = LaunchVehicleViewProfile();
            p2.name = 'Cinematic Profile';
            p2.frame = p1.frame;
            p2.playbackSettings.fps = 7;
            p2.playbackSettings.simSecPerRealSec = 123;
            vs.addViewProfile(p2);
            vs.setProfileAsActive(p2);
            drawnow;

            testCase.verifySubstring(app.UIFigure.Name, 'Cinematic Profile', 'The title follows the active profile');
            testCase.verifySubstring(app.ProfileHeaderLabel.Text, 'Cinematic Profile');
            testCase.verifyEqual(app.FpsEditField.Value, 7, 'The controls show the newly active profile''s settings');
            testCase.verifyEqual(app.SpeedEditField.Value, 123);
            testCase.verifySubstring(app.StatusLabel.Text, 'Cinematic Profile');

            vs.setProfileAsActive(p1);
            drawnow;
            testCase.verifySubstring(app.UIFigure.Name, p1.name);
            testCase.verifyEqual(app.FpsEditField.Value, p1.playbackSettings.fps);
        end

        %% ------------------------------------------------------ undo

        function editsRecordUndoStatesAndUndoRebindsTheWindow(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData, false);
            mainFig = mainApp.ma_LvdMainGUI;
            undoRedo = getappdata(mainFig, 'undoRedo');
            profile = lvdData.viewSettings.selViewProfile;

            [tf0, ~] = undoRedo.shouldUndoMenuBeEnabled();
            testCase.assumeFalse(tf0, 'Fixture: no undo states before the window edits.');

            app.setCameraMode(LvdCameraModeEnum.Chase);
            [tf, label] = undoRedo.shouldUndoMenuBeEnabled();
            testCase.verifyTrue(tf, 'Changing the camera mode recorded an undo state');
            testCase.verifyEqual(label, 'Change Camera Mode');
            testCase.verifyTrue(endsWith(mainFig.Name, '*'), 'The mission is marked as modified');

            app.setChaseParams(1, 2, 3, 4);
            app.setChaseParams(1, 2, 3, 4);   %no change -> no new state
            app.addOverlayQuantity('Altitude', profile.frame);
            app.setOverlayItemFormat(1, 2, "Scientific", [], []);
            app.setOverlayEnabled(false);
            app.applyPlaybackFields();       %unchanged fields -> no new state
            testCase.verifyEqual(app.UndoLog, {'Change Camera Mode', 'Edit Chase Camera', 'Add Data Overlay Quantity', ...
                                               'Edit Data Overlay Quantity', 'Toggle Data Overlay'}, ...
                'One descriptive undo state per real edit, none for no-op edits');

            %Edit > Undo in the main window replaces the mission object; the
            %window must follow it and show the pre-edit state
            [~, label] = undoRedo.shouldUndoMenuBeEnabled();
            testCase.assertEqual(label, 'Toggle Data Overlay');
            testCase.press(mainApp.undoMenu);
            drawnow;
            newLvdData = getappdata(mainFig, 'lvdData');
            testCase.verifyNotSameHandle(newLvdData, lvdData, 'Undo swapped in a restored mission object');
            testCase.verifyTrue(isvalid(app), 'The window survives an undo');
            testCase.verifySameHandle(app.getLvdData(), newLvdData, 'The window re-bound to the restored mission');
            newProfile = newLvdData.viewSettings.selViewProfile;
            testCase.verifyTrue(newProfile.overlay.enabled, 'The undone edit (overlay off) is reverted');
            testCase.verifyEqual(newProfile.overlay.getNumItems(), 1);
            testCase.verifyEqual(newProfile.cameraMode, LvdCameraModeEnum.Chase, 'Earlier edits are still in place');
            testCase.verifyEqual(app.OverlayEnabledCheckBox.Value, true, 'Controls show the restored state');
            [t0, t1] = app.getTimeLimits();
            testCase.verifyTrue(isfinite(t0) && isfinite(t1), 'The playback controller was rebuilt for the restored mission');

            %and further edits go onto the restored mission
            app.setCameraMode(LvdCameraModeEnum.Manual);
            testCase.verifyEqual(newProfile.cameraMode, LvdCameraModeEnum.Manual);
        end

        %% ------------------------------------------------- data overlay

        function overlayTabAddsFormatsAndRemovesQuantities(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            ov = profile.overlay;
            hAx = mainApp.dispAxes;

            testCase.choose(app.OverlayTab);
            testCase.verifyFalse(ov.enabled);
            testCase.verifyEmpty(findobj(hAx, 'Tag', 'LvdViewOverlayText'), 'No overlay before it is enabled');

            fullCount = numel(app.OverlayTaskListBox.Items);
            testCase.assertGreaterThan(fullCount, 50, 'The full Graphical Analysis quantity list is offered');
            app.filterOverlayTasks('altit');
            testCase.verifyLessThan(numel(app.OverlayTaskListBox.Items), fullCount, 'Search filters the list');
            testCase.verifyTrue(any(strcmp(app.OverlayTaskListBox.Items, 'Altitude')));

            testCase.choose(app.OverlayTaskListBox, 'Altitude');
            testCase.press(app.OverlayAddButton);

            testCase.verifyEqual(ov.getNumItems(), 1);
            testCase.verifyEqual(ov.items(1).task.taskStr, 'Altitude');
            testCase.verifyTrue(ov.enabled, 'Adding a quantity switches the overlay on');
            testCase.verifyEqual(app.OverlayEnabledCheckBox.Value, true);
            data = app.getOverlayTableData();
            testCase.verifySize(data, [1 6]);
            testCase.verifyEqual(data{1,1}, 'Altitude');
            h = findobj(hAx, 'Tag', 'LvdViewOverlayText');
            testCase.assertNumElements(h, 1, 'The overlay is drawn in the main window');
            testCase.verifyTrue(any(startsWith(h.String, 'Altitude: ')));
            testCase.verifySubstring(app.OverlayPreviewLabel.Text, 'Altitude: ');

            %formatting through the table cells
            app.applyOverlayTableEdit(1, 4, 1);
            app.applyOverlayTableEdit(1, 3, 'Alt');
            app.applyOverlayTableEdit(1, 5, 'Scientific');
            app.applyOverlayTableEdit(1, 6, false);
            it = ov.items(1);
            testCase.verifyEqual(it.decimals, 1);
            testCase.verifyEqual(it.label, 'Alt');
            testCase.verifyEqual(it.format, "Scientific");
            testCase.verifyFalse(it.showUnits);
            altLine = h.String{startsWith(h.String, 'Alt: ')};
            testCase.verifyTrue(not(isempty(regexp(altLine, '^Alt: -?\d\.\de[+-]\d+$', 'once'))), altLine);
            app.applyOverlayTableEdit(1, 4, 99);   %out of range: ignored
            testCase.verifyEqual(it.decimals, 1);

            %placement and style
            testCase.choose(app.OverlayCornerDropDown, 'Bottom Right');
            testCase.verifyEqual(ov.corner, "Bottom Right");
            testCase.verifyEqual(h.HorizontalAlignment, 'right');
            testCase.verifyEqual(h.VerticalAlignment, 'bottom');
            testCase.press(app.OverlayBoldCheckBox);
            testCase.verifyEqual(ov.fontWeight, "bold");
            testCase.verifyEqual(h.FontWeight, 'bold');
            app.OverlayFontSizeSpinner.Value = 18;
            app.OverlayMarginSpinner.Value = 5;
            app.applyOverlayFields();
            testCase.verifyEqual(ov.fontSize, 18);
            testCase.verifyEqual(h.FontSize, 18);
            testCase.verifyEqual(ov.marginFrac, 0.05, 'AbsTol', 1e-12);
            testCase.verifyEqual(h.Position(1:2), [0.95 0.05], 'AbsTol', 1e-12);
            app.setOverlayColors([1 0 0], [0 0 1]);
            testCase.verifyEqual(h.Color, [1 0 0]);
            testCase.verifyEqual(h.BackgroundColor(1:3), [0 0 1]);
            testCase.press(app.OverlayBackgroundCheckBox);
            testCase.verifyFalse(ov.showBackground);
            testCase.verifyEqual(h.BackgroundColor, 'none');
            testCase.verifyEqual(app.OverlayBackgroundColorButton.Enable, matlab.lang.OnOffSwitchState.off);

            %header lines
            testCase.press(app.OverlayShowEventCheckBox);
            testCase.verifyFalse(ov.showEventName);
            testCase.verifyFalse(any(startsWith(h.String, 'Event: ')));
            app.OverlayTitleEditField.Value = 'My Mission';
            app.applyOverlayFields();
            testCase.verifyEqual(h.String{1}, 'My Mission');

            %second quantity, reorder, remove
            app.addOverlayQuantity('Throttle', profile.frame);
            testCase.verifyEqual(ov.getNumItems(), 2);
            app.selectOverlayItem(2);
            testCase.press(app.OverlayMoveUpButton);
            testCase.verifyEqual(ov.items(1).task.taskStr, 'Throttle');
            app.selectOverlayItem(1);
            testCase.press(app.OverlayRemoveButton);
            testCase.verifyEqual(ov.getNumItems(), 1);
            testCase.verifyEqual(ov.items(1).task.taskStr, 'Altitude');
            testCase.verifySize(app.getOverlayTableData(), [1 6]);

            %switch the overlay off from the tab
            testCase.press(app.OverlayEnabledCheckBox);
            testCase.verifyFalse(ov.enabled);
            testCase.verifyEqual(h.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifySubstring(app.OverlayPreviewLabel.Text, 'OFF');
        end

        function cameraTabMirrorsMouseDrags(testCase)
            %A mouse drag on the main window retunes the chase offsets, and
            %the Camera tab shows the new values; in script mode a drag drops
            %the profile to Manual and the drop-down follows.
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            handler = lvd_getMouseCameraHandler(mainApp);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Chase Camera');
            [t0, t1] = app.getTimeLimits();
            app.stepTo((t0 + t1)/2);
            rangeBefore = app.ChaseRangeEditField.Value;

            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 150]);
            handler.endDrag();
            drawnow;

            testCase.verifyNotEqual(profile.chaseCamera.rangeKm, rangeBefore, 'The drag changed the chase range');
            testCase.verifyEqual(app.ChaseRangeEditField.Value, profile.chaseCamera.rangeKm, 'AbsTol', 1e-9, 'The Camera tab shows the dragged range');
            testCase.verifyEqual(app.ChaseAzEditField.Value, profile.chaseCamera.azDeg, 'AbsTol', 1e-9);

            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            testCase.press(app.AddKeyframeButton);
            app.stepTo(t1);
            testCase.press(app.AddKeyframeButton);
            testCase.assertEqual(profile.cameraMode, LvdCameraModeEnum.Scripted);
            app.stepTo((t0 + t1)/2);
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'Script is driving the camera');
            testCase.verifyEqual(app.ResumeScriptButton.Enable, matlab.lang.OnOffSwitchState.off);
            scriptPose = mainApp.dispAxes.CameraPosition;

            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([130 100]);
            handler.endDrag();
            drawnow;

            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Scripted, 'Grabbing the camera keeps Camera Script mode');
            testCase.verifyTrue(app.isScriptDetached(), 'but detaches the camera from the script');
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'DETACHED', 'The Camera tab says so');
            testCase.verifyEqual(app.ResumeScriptButton.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(profile.cameraScript.getNumKeyframes(), 2, 'The script itself is kept');

            testCase.press(app.ResumeScriptButton);
            testCase.verifyFalse(app.isScriptDetached());
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'Script is driving the camera');
            testCase.verifyEqual(mainApp.dispAxes.CameraPosition, scriptPose, 'AbsTol', 1e-6, 'Resume puts the script pose back');
        end

        function keyframesCanBeAddedEditedRemovedAndPlayed(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            script = profile.cameraScript;
            [t0, t1] = app.getTimeLimits();

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            testCase.verifyEqual(app.AddKeyframeButton.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'empty', 'An empty script says what to do');

            %this case exercises the classic scene-fixed / absolute-time
            %keyframes through the "New keyframes are" toggles
            testCase.choose(app.NewKeyframeRefDropDown, 'Scene-Fixed');
            testCase.choose(app.NewKeyframeAnchorDropDown, 'absolute time (UT)');

            %two keyframes from the current camera at the start and the end
            app.stepTo(t0);
            mainApp.dispAxes.CameraPosition = [1000 0 0];
            mainApp.dispAxes.CameraTarget = [0 0 0];
            testCase.press(app.AddKeyframeButton);
            app.stepTo(t1);
            mainApp.dispAxes.CameraPosition = [0 1000 0];
            mainApp.dispAxes.CameraTarget = [0 0 0];
            testCase.press(app.AddKeyframeButton);

            testCase.verifyEqual(script.getNumKeyframes(), 2);
            data = app.getKeyframeTableData();
            testCase.verifySize(data, [2 6]);
            testCase.verifyEqual(data{1,2}, 'Keyframe 1');
            testCase.verifyEqual(script.keyframes(1).absTime, t0, 'AbsTol', 1e-9);
            testCase.verifyEqual(script.keyframes(2).absTime, t1, 'AbsTol', 1e-9);
            %keyframes persist km; the axes were posed in scaled units
            sAx = LvdSceneNormalizer.getScale(mainApp.dispAxes);
            testCase.verifyEqual(script.keyframes(1).camPosition, [1000 0 0]/sAx, 'AbsTol', 1e-9);

            %edit keyframe 1 through the editor: linear easing, a hold, a name
            app.selectKeyframe(1);
            app.KfNameEditField.Value = 'Wide shot';
            testCase.choose(app.KfEasingDropDown, 'Linear');
            app.KfHoldEditField.Value = 0;
            testCase.press(app.ApplyKeyframeButton);
            testCase.verifyEqual(script.keyframes(1).name, 'Wide shot');
            testCase.verifyEqual(script.keyframes(1).easing, LvdCameraEasingEnum.Linear);
            data = app.getKeyframeTableData();
            testCase.verifyEqual(data{1,2}, 'Wide shot');

            %the scripted camera interpolates between them
            app.stepTo((t0 + t1)/2);
            testCase.verifyEqual(mainApp.dispAxes.CameraPosition, [500 500 0], 'AbsTol', 1e-6, 'Linear midpoint between the keyframes');

            %anchor keyframe 2 to the start of event 2 with an offset
            app.selectKeyframe(2);
            testCase.choose(app.KfAnchorDropDown, 'Event Start');
            testCase.verifyEqual(app.KfEventDropDown.Enable, matlab.lang.OnOffSwitchState.on, 'Event picker enables for event anchors');
            testCase.choose(app.KfEventDropDown, app.KfEventDropDown.Items{2});
            app.KfTimeEditField.Value = 5;
            testCase.press(app.ApplyKeyframeButton);
            kf2 = script.keyframes(2);
            testCase.verifyEqual(kf2.anchorType, LvdCameraKeyframeAnchorEnum.EventStart);
            testCase.verifySameHandle(kf2.event, lvdData.script.getEventForInd(2));
            evt2Entries = lvdData.stateLog.getAllStateLogEntriesForEvent(kf2.event);
            testCase.verifyEqual(kf2.resolveTime(lvdData.stateLog), evt2Entries(1).time + 5, 'AbsTol', 1e-9);
            data = app.getKeyframeTableData();
            testCase.verifySubstring(data{2,3}, 'start of Event 2');
            testCase.verifyFalse(contains(data{2,6}, 'fallback'), 'Resolved time is shown without the fallback marker');

            %the numeric pose fields are an advanced option, hidden by default
            testCase.verifyEqual(app.AdvancedPoseGrid.Visible, matlab.lang.OnOffSwitchState.off, 'Numeric pose fields start hidden');
            testCase.press(app.AdvancedPoseCheckBox);
            testCase.verifyEqual(app.AdvancedPoseGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyGreaterThan(app.KeyframeEditorGrid.RowHeight{5}, 0);

            %vehicle-relative keyframe fields enable with the reference
            testCase.choose(app.KfRefDropDown, 'Vehicle-Relative (Chase)');
            testCase.verifyEqual(app.KfRangeEditField.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.KfPosXEditField.Enable, matlab.lang.OnOffSwitchState.off);
            app.KfRangeEditField.Value = 8;
            testCase.press(app.ApplyKeyframeButton);
            testCase.verifyEqual(kf2.refType, LvdCameraKeyframeRefEnum.VehicleRelative);
            testCase.verifyEqual(kf2.rangeKm, 8);

            %clicking a row goes to that keyframe: slider on its time, camera on its pose
            app.selectKeyframe(1);
            testCase.choose(app.KeyframeTable, [2 2]);
            testCase.verifyEqual(app.getSelectedKeyframeIndex(), 2, 'The row click selected keyframe 2');
            testCase.verifyEqual(mainApp.DispAxesTimeSlider.Value, kf2.resolveTime(lvdData.stateLog), 'AbsTol', 1e-9);
            vehPos = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, mainApp.DispAxesTimeSlider.Value);
            testCase.verifyEqual(mainApp.dispAxes.CameraTarget(:), vehPos*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifyEqual(norm(mainApp.dispAxes.CameraPosition(:) - vehPos*sAx), 8*sAx, 'AbsTol', 1e-6*sAx);
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'Keyframe 2', 'The state line names the keyframe the script is on');

            %the table is in play order (resolved time), whatever the order in the script
            app.selectKeyframe(2);
            testCase.choose(app.KfAnchorDropDown, 'Absolute Time (UT)');
            app.KfTimeEditField.Value = t0 - 10;    %keyframe 2 now comes first
            testCase.press(app.ApplyKeyframeButton);
            data = app.getKeyframeTableData();
            testCase.verifyEqual(data{1,2}, 'Keyframe 2', 'Earliest keyframe is on the first row');
            testCase.verifyEqual(data{2,2}, 'Wide shot');
            testCase.verifyEqual(app.getKeyframeRowOrder(), [2 1]);
            testCase.verifyEqual(script.keyframes(1).name, 'Wide shot', 'The script''s own order is not touched');

            %remove the selected keyframe
            testCase.press(app.RemoveKeyframeButton);
            testCase.verifyEqual(script.getNumKeyframes(), 1);
            testCase.verifyEqual(script.keyframes(1).name, 'Wide shot');
            testCase.verifySize(app.getKeyframeTableData(), [1 6]);

            %the saved manual camera never changed while the script drove
            testCase.verifyEqual(profile.viewCameraPosition, profile.getCameraDriver().getManualCameraSnapshot().position, ...
                'Saved manual camera is what it was when the script mode was entered');
        end

        function addKeyframeHereDefaultsToVehicleRelativeEventAnchoredAndReattaches(testCase)
            %The authoring loop the user asked for: scrub, drag the view (the
            %camera detaches, the mode stays Camera Script), press Add
            %Keyframe Here.  The new keyframe is vehicle-relative, anchored to
            %the start of the event active at that time, reproduces the
            %camera, and the script re-attaches with no jump.
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            handler = lvd_getMouseCameraHandler(mainApp);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            profile = lvdData.viewSettings.selViewProfile;
            script = profile.cameraScript;
            hAx = mainApp.dispAxes;
            [t0, t1] = app.getTimeLimits();

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            testCase.verifyEqual(app.NewKeyframeRefDropDown.Value, 'Vehicle-Relative (Chase)', 'Default: vehicle-relative');
            testCase.verifySubstring(app.NewKeyframeAnchorDropDown.Value, 'active event', 'Default: anchored to the active event');

            %first keyframe at the start, from the camera as it is
            app.stepTo(t0);
            testCase.press(app.AddKeyframeButton);
            kf1 = script.keyframes(1);
            testCase.verifyEqual(kf1.refType, LvdCameraKeyframeRefEnum.VehicleRelative);
            testCase.verifyEqual(kf1.anchorType, LvdCameraKeyframeAnchorEnum.EventStart);
            testCase.verifySameHandle(kf1.event, lvdData.script.getEventForInd(1));
            testCase.verifyEqual(kf1.timeOffset, 0, 'AbsTol', 1e-9);

            %second: scrub into event 2, drag, add
            evt2 = lvdData.script.getEventForInd(2);
            evt2Entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt2);
            tIn2 = evt2Entries(1).time + 0.6*(t1 - evt2Entries(1).time);
            app.stepTo(tIn2);
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([150 120]);
            handler.endDrag();
            handler.beginDrag('dollyfb', [100 100]);
            handler.applyDrag([100 130]);
            handler.endDrag();
            drawnow;
            testCase.assertTrue(app.isScriptDetached(), 'Dragging detached the camera');
            camBefore = hAx.CameraPosition;
            vehPos = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tIn2);

            testCase.press(app.AddKeyframeButton);
            testCase.verifyEqual(script.getNumKeyframes(), 2);
            kf2 = script.keyframes(2);
            testCase.verifyEqual(kf2.refType, LvdCameraKeyframeRefEnum.VehicleRelative);
            testCase.verifyEqual(kf2.anchorType, LvdCameraKeyframeAnchorEnum.EventStart);
            testCase.verifySameHandle(kf2.event, evt2, 'Anchored to the event active at that time');
            testCase.verifyEqual(kf2.timeOffset, tIn2 - evt2Entries(1).time, 'AbsTol', 1e-6);
            testCase.verifyEqual(kf2.resolveTime(lvdData.stateLog), tIn2, 'AbsTol', 1e-6, 'and it resolves to the time it was added at');
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(kf2.rangeKm, norm(camBefore(:)/sAx - vehPos), 'RelTol', 1e-6, 'Range reproduces the camera');
            expectedPose = kf2.getPoseAtVehiclePosition(vehPos);
            testCase.verifyEqual(expectedPose.position*sAx, camBefore, 'AbsTol', 1e-6*max(1, norm(camBefore)), 'Az/el/range reproduce the camera position');

            testCase.verifyFalse(app.isScriptDetached(), 'Adding a keyframe re-attaches the script');
            testCase.verifyEqual(hAx.CameraPosition, camBefore, 'AbsTol', 1e-6*max(1, norm(camBefore)), 'No jump: the script now passes through the new keyframe');
            testCase.verifySubstring(app.ScriptStateLabel.Text, 'Script is driving the camera');
            testCase.verifyEqual(app.UndoLog(end), {'Add Camera Keyframe'});
            data = app.getKeyframeTableData();
            testCase.verifySubstring(data{2,3}, 'start of Event 2');
        end

        function updateSelectedFromCameraReattachesTheScript(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            handler = lvd_getMouseCameraHandler(mainApp);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            profile = lvdData.viewSettings.selViewProfile;
            script = profile.cameraScript;
            hAx = mainApp.dispAxes;
            [t0, t1] = app.getTimeLimits();

            testCase.choose(app.CameraTab);
            app.setNewKeyframeDefaults(LvdCameraKeyframeRefEnum.SceneFixed, false);
            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            app.stepTo(t0);
            testCase.press(app.AddKeyframeButton);
            app.stepTo(t1);
            testCase.press(app.AddKeyframeButton);
            kf1 = script.keyframes(1);
            posBefore = kf1.camPosition;

            %go to keyframe 1, nudge the view, update it
            testCase.choose(app.KeyframeTable, [1 1]);
            testCase.verifyEqual(mainApp.DispAxesTimeSlider.Value, t0, 'AbsTol', 1e-9);
            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([140 100]);
            handler.endDrag();
            drawnow;
            testCase.assertTrue(app.isScriptDetached());
            nudged = hAx.CameraPosition;
            testCase.verifyEqual(app.UpdateKeyframeButton.Enable, matlab.lang.OnOffSwitchState.on);

            testCase.press(app.UpdateKeyframeButton);
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(kf1.camPosition, nudged/sAx, 'AbsTol', 1e-6, 'The keyframe took the nudged camera');
            testCase.verifyGreaterThan(norm(kf1.camPosition - posBefore), 1e-3);
            testCase.verifyEqual(kf1.absTime, t0, 'AbsTol', 1e-9, 'Its time is kept');
            testCase.verifyFalse(app.isScriptDetached(), 'Updating re-attaches the script');
            testCase.verifyEqual(hAx.CameraPosition, nudged, 'AbsTol', 1e-6, 'No jump');
            testCase.verifyEqual(app.UndoLog(end), {'Update Camera Keyframe'});
            testCase.verifyEqual(script.getNumKeyframes(), 2);
            testCase.verifyEqual(app.KfPosXEditField.Value, nudged(1)/sAx, 'AbsTol', 1e-6, 'The (advanced) numeric fields follow');
        end

        function keyframeCanUseFixedAnchorTrackingMode(testCase)
            %A script keyframe can use the "Fixed Camera (Tracking)" reference:
            %the camera parks at a fixed anchor (Fixed Coordinates / Ground
            %Object / Geometric Point, resolved into the view frame) and tracks
            %the vehicle for that keyframe, just like the profile-level mode.
            %Exercised through the keyframe editor's ref + anchor-type dropdowns.
            [mainApp, lvdData] = testCase.openPropagatedLvd();

            %a ground object on the body-fixed frame and a fixed geometric point
            bodyInfo = testCase.celBodyData.kerbin;
            grdObj = makeStaticGroundObject(bodyInfo, deg2rad(5), deg2rad(30), 2);
            lvdData.groundObjs.addGroundObj(grdObj);
            pt = FixedPointInFrame([700 -200 350], bodyInfo.getBodyCenteredInertialFrame(), 'Pad Point', lvdData);
            lvdData.geometry.points.addPoint(pt);

            app = testCase.openWindow(mainApp, lvdData);
            profile = lvdData.viewSettings.selViewProfile;
            script = profile.cameraScript;
            hAx = mainApp.dispAxes;
            [t0, t1] = app.getTimeLimits();
            tMid = (t0 + t1)/2;

            testCase.choose(app.CameraTab);
            app.setNewKeyframeDefaults(LvdCameraKeyframeRefEnum.SceneFixed, false);
            testCase.choose(app.CameraModeDropDown, 'Camera Script');

            %one keyframe at the start; select it and switch its reference to
            %fixed-anchor tracking
            app.stepTo(t0);
            testCase.press(app.AddKeyframeButton);
            app.selectKeyframe(1);
            kf = script.keyframes(1);

            testCase.choose(app.KfRefDropDown, 'Fixed Camera (Tracking)');
            %the anchor editor takes over: the scene-fixed / vehicle-relative
            %inputs (and the advanced numeric-pose option) give way to it
            testCase.verifyEqual(app.KfAnchorEditorGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.AdvancedPoseGrid.Visible, matlab.lang.OnOffSwitchState.off, 'Numeric pose fields are hidden');
            testCase.verifyEqual(app.AdvancedPoseCheckBox.Visible, matlab.lang.OnOffSwitchState.off, 'and their toggle too');
            testCase.verifyEqual(app.KfRangeEditField.Enable, matlab.lang.OnOffSwitchState.off, 'Vehicle-relative range disables');

            %--- Fixed Coordinates: the default anchor type shows the XYZ sub-grid
            testCase.verifyEqual(app.KfFixedXYZSubGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.KfGroundObjSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.KfGeomPtSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            app.KfAnchorXEditField.Value = 900;
            app.KfAnchorYEditField.Value = -150;
            app.KfAnchorZEditField.Value = 400;
            testCase.press(app.ApplyKeyframeButton);
            testCase.verifyEqual(kf.refType, LvdCameraKeyframeRefEnum.FixedAnchorTracking);
            testCase.verifyEqual(kf.anchor.anchorType, LvdCameraAnchorTypeEnum.FixedXYZ);
            testCase.verifyEqual(kf.anchor.fixedPosition, [900 -150 400], 'AbsTol', 1e-9);

            %--- Ground Object anchor: choose the type, then the object
            testCase.choose(app.KfAnchorTypeDropDown, 'Ground Object');
            testCase.verifyEqual(app.KfGroundObjSubGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.KfFixedXYZSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.assertTrue(any(strcmp(app.KfAnchorGroundObjectDropDown.Items, grdObj.name)), ...
                'The mission''s ground object appears in the keyframe picker');
            testCase.choose(app.KfAnchorGroundObjectDropDown, grdObj.name);
            testCase.press(app.ApplyKeyframeButton);
            testCase.verifyEqual(kf.anchor.anchorType, LvdCameraAnchorTypeEnum.GroundObject);
            testCase.verifySameHandle(kf.anchor.groundObject, grdObj);

            %--- Geometric Point anchor
            gpStr = pt.getListboxStr();
            testCase.choose(app.KfAnchorTypeDropDown, 'Geometric Point');
            testCase.verifyEqual(app.KfGeomPtSubGrid.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.KfGroundObjSubGrid.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.assertTrue(any(strcmp(app.KfAnchorGeometricPointDropDown.Items, gpStr)), ...
                'The (vehicle-independent) geometric point appears in the keyframe picker');
            testCase.choose(app.KfAnchorGeometricPointDropDown, gpStr);
            testCase.press(app.ApplyKeyframeButton);
            testCase.verifyEqual(kf.anchor.anchorType, LvdCameraAnchorTypeEnum.GeometricPoint);
            testCase.verifySameHandle(kf.anchor.geometricPoint, pt);

            %the scripted camera parks at the (geometric-point) anchor and keeps
            %the vehicle centred as playback steps
            app.stepTo(tMid);
            anchor = kf.anchor.getAnchorPosAtTime(tMid, profile.frame);
            testCase.assertNotEmpty(anchor);
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(hAx.CameraPosition(:), anchor*sAx, 'AbsTol', 1e-6*sAx, 'Camera sits on the keyframe anchor');
            testCase.verifyEqual(hAx.CameraTarget(:), LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, tMid)*sAx, ...
                'AbsTol', 1e-6*sAx, 'and tracks the vehicle');

            testCase.choose(app.CameraModeDropDown, 'Manual');
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Manual);
        end

        function playingResumesADetachedScript(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            handler = lvd_getMouseCameraHandler(mainApp);
            testCase.assumeNotEmpty(handler, 'This LVD build has no mouse camera handler.');
            [t0, t1] = app.getTimeLimits();

            testCase.choose(app.CameraTab);
            testCase.choose(app.CameraModeDropDown, 'Camera Script');
            app.stepTo(t0);
            testCase.press(app.AddKeyframeButton);
            app.stepTo(t1);
            testCase.press(app.AddKeyframeButton);
            app.stepTo((t0 + t1)/2);

            handler.beginDrag('orbit', [100 100]);
            handler.applyDrag([130 100]);
            handler.endDrag();
            testCase.assertTrue(app.isScriptDetached());

            app.SpeedEditField.Value = 1;
            app.play();
            testCase.verifyFalse(app.isScriptDetached(), 'Playing is watching: the script takes the camera back');
            app.pause();
            app.stop();
        end

        %% ---------------------------------------------------------- mesh

        function meshImportShowsThePatchAndThePreview(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            mesh = lvdData.viewSettings.selViewProfile.vehicleMesh;

            meshPath = [tempname(), '.stl'];
            cleanup = onCleanup(@() deleteIfExists(meshPath)); %#ok<NASGU>
            ksptotWriteTestMesh('stl-binary', meshPath);

            testCase.verifyEmpty(findobj(mainApp.dispAxes, 'Tag', 'LvdVehicleMesh'));
            testCase.choose(app.MeshTab);
            app.importMeshFromFile(meshPath);
            testCase.verifyEqual(app.ProgressDialogLog, {'Importing Mesh'}, 'An (indeterminate) progress dialog is shown while the mesh loads');
            testCase.verifyTrue(isvalid(app.UIFigure), 'The window is intact after the dialog closed');

            testCase.verifyTrue(mesh.enabled);
            testCase.verifyEqual(app.MeshEnabledCheckBox.Value, true);
            testCase.verifySubstring(app.MeshPathLabel.Text, '.stl');
            testCase.verifySubstring(app.MeshInfoLabel.Text, '12 faces');

            %import auto-fits the longest side to the display length, which
            %defaults to 2% of the central body radius (Kerbin: 12 km)
            bodyRadius = lvdData.initStateModel.centralBody.radius;
            testCase.verifyEqual(app.FitLengthEditField.Value, 0.02*bodyRadius, 'AbsTol', 1e-9, 'Default display length is 2% of the body radius');
            [mn, mx] = mesh.getBodyFrameBounds();
            testCase.verifyEqual(max(mx - mn), 0.02*bodyRadius, 'AbsTol', 1e-9, 'The imported unit cube is shown at the display length');
            testCase.verifySubstring(app.StatusLabel.Text, 'longest side');
            testCase.verifyNumElements(findobj(mainApp.dispAxes, 'Tag', 'LvdVehicleMesh'), 1, 'The mesh is drawn in the main window');
            testCase.verifyNumElements(findobj(app.MeshPreviewAxes, 'Tag', 'LvdMeshPreviewPatch'), 1, 'The preview shows the mesh');
            testCase.verifyNumElements(findobj(app.MeshPreviewAxes, 'Tag', 'LvdMeshPreviewTriad'), 3, 'The preview shows the body axes triad');

            %fit and transform through the controls
            app.FitLengthEditField.Value = 0.05;
            testCase.press(app.FitButton);
            testCase.verifyEqual(mesh.scale, 0.05, 'AbsTol', 1e-12, 'Unit cube: longest side 1 -> scale 0.05');
            testCase.verifyEqual(app.MeshScaleEditField.Value, 0.05, 'AbsTol', 1e-12);

            app.MeshYawEditField.Value = 90;
            app.MeshTransXEditField.Value = 0.1;
            app.applyMeshFields();
            testCase.verifyEqual(mesh.rotOffsetEulerDeg, [90 0 0]);
            testCase.verifyEqual(mesh.transOffsetKm, [0.1 0 0]);
            p = findobj(mainApp.dispAxes, 'Tag', 'LvdVehicleMesh');
            testCase.verifyEqual(p.Vertices, mesh.getBodyFrameVertices(), 'AbsTol', 1e-12, 'The drawn patch follows the transform');

            app.setMeshAppearance([1 0 0], 0.5, true, [0 0 1], false);
            testCase.verifyEqual(p.FaceColor, [1 0 0]);
            testCase.verifyEqual(p.FaceAlpha, 0.5);
            testCase.verifyEqual(p.EdgeColor, [0 0 1]);
            testCase.verifyEqual(app.MeshAlphaSpinner.Value, 0.5);

            %"Show in Chase Camera" frames the mesh: chase mode, range 4 x longest side
            testCase.press(app.ShowInChaseButton);
            profile = lvdData.viewSettings.selViewProfile;
            testCase.verifyEqual(profile.cameraMode, LvdCameraModeEnum.Chase);
            [mn, mx] = mesh.getBodyFrameBounds();
            testCase.verifyEqual(profile.chaseCamera.rangeKm, 4*max(mx - mn), 'AbsTol', 1e-12);
            hAx = mainApp.dispAxes;
            sAx = LvdSceneNormalizer.getScale(hAx);
            testCase.verifyEqual(norm(hAx.CameraPosition - hAx.CameraTarget), profile.chaseCamera.rangeKm*sAx, 'AbsTol', 1e-6*sAx, 'The camera sits at the chase range');
            vehPos = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, app.getCurrentTime());
            testCase.verifyEqual(hAx.CameraTarget(:), vehPos*sAx, 'AbsTol', 1e-6*sAx, 'and looks at the vehicle');
            app.setCameraMode(LvdCameraModeEnum.Manual);

            %disable via the checkbox hides it
            testCase.press(app.MeshEnabledCheckBox);
            testCase.verifyFalse(mesh.enabled);
            testCase.verifyEqual(p.Parent.Visible, matlab.lang.OnOffSwitchState.off);

            testCase.press(app.ClearMeshButton);
            testCase.verifyFalse(mesh.hasMesh());
            testCase.verifyEqual(app.MeshPathLabel.Text, '<no mesh imported>');
            testCase.verifyEmpty(findobj(app.MeshPreviewAxes, 'Tag', 'LvdMeshPreviewPatch'));
        end

        %% -------------------------------------------------------- export

        function exportImageAndVideoThroughTheSeams(testCase)
            testCase.assumeVideoProfile('Motion JPEG AVI');
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            [t0, ~] = app.getTimeLimits();

            pngPath = [tempname(), '.png'];
            aviPath = [tempname(), '.avi'];
            cleanup = onCleanup(@() cellfun(@deleteIfExists, {pngPath, aviPath})); %#ok<NASGU>

            app.ImageDpiEditField.Value = 72;
            app.exportImage(pngPath);
            testCase.assertTrue(isfile(pngPath));
            info = imfinfo(pngPath);
            testCase.verifyGreaterThan(info.Width, 10);

            app.stepTo(t0 + 30);
            opts = struct('videoFormat', "Motion JPEG AVI", 'fps', 5, 'simSecPerRealSec', 10, ...
                          'exportStartTime', t0, 'exportEndTime', t0 + 4, 'showProgress', false);
            n = app.exportVideo(aviPath, opts);
            expectedTimes = LvdViewPlaybackController.frameSchedule(t0, t0 + 4, 5, 10);
            testCase.verifyEqual(n, numel(expectedTimes), 'One frame per scheduled time');
            testCase.assertTrue(isfile(aviPath));
            v = VideoReader(aviPath);
            frames = 0;
            while(hasFrame(v))
                readFrame(v);
                frames = frames + 1;
            end
            delete(v);
            testCase.verifyEqual(frames, n);
            testCase.verifyEqual(mainApp.DispAxesTimeSlider.Value, t0 + 30, 'AbsTol', 1e-9, 'The slider returns to where it was before the export');
            testCase.verifySubstring(app.StatusLabel.Text, 'frames');

            %the per-call overrides did not touch the saved settings
            testCase.verifyEqual(lvdData.viewSettings.selViewProfile.playbackSettings.fps, app.FpsEditField.Value);
        end

        %% ------------------------------------------------ lifecycle

        function windowSurvivesRepropagationAndTracksTheNewRange(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            [~, t1Before] = app.getTimeLimits();

            evt2 = lvdData.script.getEventForInd(2);
            evt2.termCond = EventDurationTermCondition(300);
            mainApp.lvdEnhancementsRefresh(true);
            drawnow;

            testCase.verifyTrue(isvalid(app), 'The window survives a re-propagation');
            [~, t1After] = app.getTimeLimits();
            testCase.verifyGreaterThan(t1After, t1Before + 100, 'The time range follows the new trajectory');
            testCase.verifyEqual(app.getController().state, "stopped");
            testCase.verifySubstring(app.StatusLabel.Text, 'spans');
        end

        function unpropagatedMissionDisablesPlaybackButKeepsTheMeshTab(testCase)
            mainApp = testCase.openLvd();
            lvdData = getappdata(mainApp.ma_LvdMainGUI, 'lvdData');
            lvdData.stateLog.clearStateLog();
            app = testCase.openWindow(mainApp, lvdData);

            testCase.verifyEqual(app.PlayButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.ExportVideoButton.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifySubstring(app.StatusLabel.Text, 'Propagate');
            testCase.verifyError(@() app.exportVideo([tempname() '.avi']), 'lvd_ViewPlaybackGUI_App:noStateLog');

            meshPath = [tempname(), '.obj'];
            cleanup = onCleanup(@() deleteIfExists(meshPath)); %#ok<NASGU>
            ksptotWriteTestMesh('obj', meshPath);
            app.importMeshFromFile(meshPath);
            testCase.verifyTrue(lvdData.viewSettings.selViewProfile.vehicleMesh.hasMesh(), 'Mesh import works without a trajectory');
            testCase.verifyNumElements(findobj(app.MeshPreviewAxes, 'Tag', 'LvdMeshPreviewPatch'), 1);
        end

        function closingTheMainWindowClosesThePlaybackWindow(testCase)
            [mainApp, lvdData] = testCase.openPropagatedLvd();
            app = testCase.openWindow(mainApp, lvdData);
            app.SpeedEditField.Value = 1;
            app.play();
            testCase.verifyEqual(app.getController().state, "playing");

            delete(mainApp);
            drawnow;
            testCase.verifyFalse(isvalid(app), 'The playback window is deleted with the main window');
            testCase.verifyEmpty(timerfindall('Tag', 'LvdViewPlaybackTimer'), 'No playback timer is left running');
        end
    end

    methods(Access = private)
        function app = openLvd(testCase)
            testCase.stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(testCase.stubMainFig));

            app = ma_LvdMainGUI_App(testCase.celBodyData, testCase.stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;
            testCase.assertTrue(isvalid(app.ma_LvdMainGUI), 'The LVD main window must open.');
        end

        function [mainApp, lvdData] = openPropagatedLvd(testCase)
            mainApp = testCase.openLvd();
            lvdData = getappdata(mainApp.ma_LvdMainGUI, 'lvdData');

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

            mainApp.lvdEnhancementsRefresh(true);
            drawnow;
            testCase.assertGreaterThan(lvdData.stateLog.getNumberOfEntries(), 3, 'Fixture: the mission must have propagated.');
        end

        function app = openWindow(testCase, mainApp, lvdData, visible)
            %openWindow The playback window; visible by default because the
            %App Testing Framework only applies gestures to visible windows.
            if(nargin < 4)
                visible = true;
            end
            app = lvd_ViewPlaybackGUI_App(lvdData, mainApp, visible);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;
            testCase.assertTrue(isvalid(app.UIFigure), 'The playback window must open.');
        end

        function item = menuItem(~, parentMenu, text)
            children = parentMenu.Children;
            item = children(strcmp({children.Text}, text));
            assert(isscalar(item), 'Menu item "%s" not found exactly once.', text);
        end

        function assumeVideoProfile(testCase, name)
            profiles = VideoWriter.getProfiles();
            testCase.assumeTrue(any(strcmp({profiles.Name}, name)), ...
                sprintf('VideoWriter profile "%s" is not available on this machine.', name));
        end

        function closeNewFigures(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            delete(figs(isvalid(figs)));
        end
    end
end

function grdObj = makeStaticGroundObject(bodyInfo, lat, long, altKm)
    %makeStaticGroundObject A single-waypoint (stationary) ground object on
    %the given body, expressed in its body-fixed frame.
    frame = bodyInfo.getBodyFixedFrame();
    wayPt = LaunchVehicleGroundObjectWayPt(GeographicElementSet(0, lat, long, altKm, 0,0,0, frame), 100);
    grdObj = LaunchVehicleGroundObject('Pad', "", 0, wayPt);
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
