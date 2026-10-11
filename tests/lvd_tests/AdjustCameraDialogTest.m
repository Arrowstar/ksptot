classdef AdjustCameraDialogTest < KsptotTestCase
    %AdjustCameraDialogTest Headless UI tests for the camera-controls dialog
    %(Phase 4: view). Asserts on dialog state plus the axes camera only:
    %never renders a scene, never propagates, never optimises.
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/view/lvd_AdjustCameraGUI_App.mlapp
    %   ('Camera Controls'; modeless, uiwait=0).
    %   ctor: startupFcn(app, hAx) takes the axes handle to drive; with no
    %   arg it builds its own demo axes (a sphere surf -- rendering, so
    %   every test below passes an explicit offscreen axes).
    %
    % PATTERN
    %   UiwaitInterceptorFixture is applied for uniformity although this
    %   modeless dialog never blocks in uiwait. Sliders act live on the axes
    %   through their ValueChangingFcn, so tests fire
    %   slider.ValueChangingFcn(slider, struct('Value', v)) and assert on
    %   hAx.CameraPosition / CameraTarget / CameraViewAngle.
    %
    % COVERED
    %   Open shows default slider positions/limits and the title; pan
    %   up/down and right/left translate position and target together
    %   (separation preserved); pan in/out dollies the position only;
    %   zoom changes the view angle; closing the dialog leaves the camera
    %   exactly as edited and the axes valid.
    %
    % NOTES
    %   Production has no Save/Apply/Cancel/Restore: every slider writes
    %   live, and WindowButtonUp only re-centres the sliders. "Preserves"
    %   is therefore close-leaves-camera-alone. The rotate sliders are
    %   deliberately never fired: they call roty/rotz, which are absent in
    %   this environment (SensorTest.m:36-43). The camera model here is the
    %   axes camera itself (cf. FixedAnchorCameraTest for the
    %   profile-anchor model, which this dialog does not touch).

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogOpensWithDefaultSlidersAndTitle(testCase)
            [app, hFig, hAx] = testCase.openCamera(); %#ok<ASGLU>

            testCase.verifyEqual(char(app.CameraControlsUIFigure.Name), 'Camera Controls');
            testCase.verifyEqual(app.CameraPanUpDownSlider.Value, 0);
            testCase.verifyEqual(app.CameraPanRightLeftSlider.Value, 0);
            testCase.verifyEqual(app.CameraPanInOutSlider.Value, 0);
            testCase.verifyEqual(app.CameraRotateUpDownSlider.Value, 0);
            testCase.verifyEqual(app.CameraRotateRightLeftSlider.Value, 0);
            testCase.verifyEqual(app.CameraZoomSlider.Value, 1);
            testCase.verifyEqual(app.CameraPanUpDownSlider.Limits, [-1 1]);
            testCase.verifyEqual(app.CameraPanRightLeftSlider.Limits, [-1 1]);
            testCase.verifyEqual(app.CameraZoomSlider.Limits, [0.9 1.1]);
            testCase.verifyTrue(isvalid(app.CameraPanPanel));
            testCase.verifyTrue(isvalid(app.CameraMoveForwardsBackwardsPanel));
            testCase.verifyTrue(isvalid(app.CameraRotatePanel));
            testCase.verifyTrue(isvalid(app.CameraZoomPanel));
            testCase.verifyTrue(isvalid(hAx));
        end

        function panUpDownTranslatesCameraTogether(testCase)
            [app, hFig, hAx] = testCase.openCamera(); %#ok<ASGLU>
            posBefore = hAx.CameraPosition(:);
            tgtBefore = hAx.CameraTarget(:);
            sepBefore = norm(tgtBefore - posBefore);

            testCase.fireChanging(app.CameraPanUpDownSlider, 0.5);

            posAfter = hAx.CameraPosition(:);
            tgtAfter = hAx.CameraTarget(:);
            testCase.verifyEqual(posAfter - posBefore, tgtAfter - tgtBefore, 'AbsTol', 1e-9, ...
                'Pan must translate position and target by the same offset.');
            testCase.verifyEqual(norm(tgtAfter - posAfter), sepBefore, 'AbsTol', 1e-9, ...
                'Pan must preserve the position-target separation.');
            testCase.verifyEqual(norm(posAfter - posBefore), 500, 'AbsTol', 1e-6, ...
                'A 0.5 drag over a 1000-unit range must move 500 units.');
        end

        function panRightLeftTranslatesCameraTogether(testCase)
            [app, hFig, hAx] = testCase.openCamera(); %#ok<ASGLU>
            posBefore = hAx.CameraPosition(:);
            tgtBefore = hAx.CameraTarget(:);
            sepBefore = norm(tgtBefore - posBefore);

            testCase.fireChanging(app.CameraPanRightLeftSlider, 0.5);

            posAfter = hAx.CameraPosition(:);
            tgtAfter = hAx.CameraTarget(:);
            testCase.verifyEqual(posAfter - posBefore, tgtAfter - tgtBefore, 'AbsTol', 1e-9, ...
                'Pan must translate position and target by the same offset.');
            testCase.verifyEqual(norm(tgtAfter - posAfter), sepBefore, 'AbsTol', 1e-9);
            testCase.verifyEqual(norm(posAfter - posBefore), 500, 'AbsTol', 1e-6);
        end

        function panInOutMovesPositionOnly(testCase)
            [app, hFig, hAx] = testCase.openCamera(); %#ok<ASGLU>
            posBefore = hAx.CameraPosition(:);
            tgtBefore = hAx.CameraTarget(:);
            sepBefore = norm(tgtBefore - posBefore);

            testCase.fireChanging(app.CameraPanInOutSlider, 0.5);

            testCase.verifyEqual(hAx.CameraTarget(:), tgtBefore, 'AbsTol', 1e-9, ...
                'In/out dolly must leave the target alone.');
            testCase.verifyGreaterThan(norm(hAx.CameraPosition(:) - posBefore), 100, ...
                'In/out dolly must move the position.');
            testCase.verifyNotEqual(norm(hAx.CameraTarget(:) - hAx.CameraPosition(:)), sepBefore, ...
                'In/out dolly must change the separation.');
        end

        function zoomChangesViewAngle(testCase)
            [app, hFig, hAx] = testCase.openCamera(); %#ok<ASGLU>
            angleBefore = hAx.CameraViewAngle;

            testCase.fireChanging(app.CameraZoomSlider, 1.1);

            testCase.verifyLessThan(hAx.CameraViewAngle, angleBefore, ...
                'Zooming with a factor above 1 must narrow the view angle.');
            testCase.verifyTrue(isvalid(hAx));
        end

        function closePreservesCamera(testCase)
            [app, hFig, hAx] = testCase.openCamera();
            testCase.fireChanging(app.CameraPanUpDownSlider, 0.5);
            posEdited = hAx.CameraPosition(:);
            tgtEdited = hAx.CameraTarget(:);
            fig = app.CameraControlsUIFigure;

            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(hAx.CameraPosition(:), posEdited, 'AbsTol', 1e-12, ...
                'Closing must leave the edited camera alone.');
            testCase.verifyEqual(hAx.CameraTarget(:), tgtEdited, 'AbsTol', 1e-12);
            testCase.verifyTrue(isvalid(hAx), 'Closing must leave the axes valid.');
            testCase.verifyTrue(isvalid(hFig));
        end
    end

    methods(Access=private)
        function [app, hFig, hAx] = openCamera(testCase)
            %Offscreen UIAxes with a known pose and known limits; always
            %passed explicitly so the dialog never builds its demo scene.
            %Must be uiaxes: the dialog's hAx property is typed
            %matlab.ui.control.UIAxes and rejects plain axes handles.
            hFig = figure('Visible', 'off');
            hAx = uiaxes(hFig);
            hAx.CameraPosition = [500 0 0];
            hAx.CameraTarget = [0 0 0];
            hAx.CameraUpVector = [0 0 1];
            hAx.XLim = [0 1000];
            hAx.YLim = [0 1000];
            hAx.ZLim = [0 1000];

            app = lvd_AdjustCameraGUI_App(hAx);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            %Single teardown in a fixed order: deleting the axes fires the
            %dialog's axesBeingDestroyed listener, which needs a live app
            %(it closes the dialog itself), so the axes go first and the
            %app second.  Separate teardowns race the listener against app
            %deletion regardless of registration order.
            testCase.addTeardown(@() AdjustCameraDialogTest.teardownCamera(app, hFig));
        end

        function fireChanging(~, slider, value)
            evt = struct('Source', slider, 'EventName', 'ValueChanging', 'Value', value);
            slider.ValueChangingFcn(slider, evt);
            drawnow;
        end
    end

    methods(Static, Access=private)
        function teardownCamera(app, hFig)
            %Deleting the axes fires the dialog's axesBeingDestroyed
            %listener, which dereferences the app without checking it is
            %alive first (bug log 4B.6); when the test already closed the
            %dialog, that listener can only warn.  Suppress just that
            %warning ID around the teardown deletes.
            ws = warning('off', 'MATLAB:callback:error');
            cleaner = onCleanup(@() warning(ws)); %#ok<NASGU>
            if ~isempty(hFig) && isvalid(hFig)
                try %#ok<TRYNC>
                    delete(hFig);
                end
            end
            AdjustCameraDialogTest.deleteDialog(app);
        end

        function deleteDialog(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Camera Controls')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function deleteIfValidFig(h)
    if ~isempty(h) && isvalid(h)
        try %#ok<TRYNC>
            delete(h);
        end
    end
end
