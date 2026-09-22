classdef LvdSceneCameraDriver < handle
    %LvdSceneCameraDriver Drives the 3-D view axes camera from a view
    %profile's camera mode (Manual / Chase / Scripted) on every rendered
    %frame, and cooperates with the user's camera input.
    %
    %   Saved manual camera.  The main LVD window installs PostSet listeners
    %   on the axes camera properties that copy every camera change back
    %   into the profile's saved manual camera (viewCameraPosition/Target/
    %   UpVector/ViewAngle, viewAzEl, viewZoomAxLims).  A chase or scripted
    %   camera would therefore silently overwrite the user's saved manual
    %   view on every frame.  This driver snapshots the manual camera when a
    %   non-manual mode is entered, re-asserts the snapshot on the profile
    %   immediately after each camera write (the listeners run
    %   synchronously), and puts the snapshot back on the axes when Manual
    %   is re-selected.
    %
    %   User input.  The mouse always works.  attach() installs the driver's
    %   own listeners on the axes camera; a camera change that the driver did
    %   not make, while the mouse camera handler is dragging or a camera
    %   toolbar mode is active, is treated as the user's:
    %     Chase    - the new camera becomes the chase offset (azimuth,
    %                elevation, range from the vehicle) and the camera target
    %                is pinned back onto the vehicle, so orbiting always
    %                orbits the vehicle and the camera keeps following from
    %                where the user put it.
    %     Scripted - the camera DETACHES from the script (the mode stays
    %                Camera Script): the script stops driving the camera until
    %                resumeScript() is called, which the playback window does
    %                when a keyframe is added or updated from the camera, when
    %                Resume Script is pressed, or when playback starts.  While
    %                detached the camera either keeps the offset from the
    %                vehicle the user set (detachedFollowsVehicle, the default:
    %                scrubbing the time keeps the vehicle framed) or stays
    %                where it was left in the scene.  This is the keyframe
    %                authoring loop: scrub, drag, add/update.
    %   Programmatic camera changes with no user gesture in progress (plot
    %   resets, axes limit changes) are ignored.
    %
    %   Transient: one per profile, created by
    %   LaunchVehicleViewProfile.getCameraDriver().

    properties(SetAccess = private)
        profile LaunchVehicleViewProfile
        activeMode(1,1) LvdCameraModeEnum = LvdCameraModeEnum.Manual;
        manualCam = [];       %struct(position,target,up,viewAngle,azEl,zoomAxLims) or []
        lastPose = [];        %last pose written to the axes

        attachedAxes = [];    %axes whose camera is watched
        attachedFig = [];     %its figure (for cameratoolbar mode queries)
        mouseHandler = [];    %LvdMouseCameraHandler or []
        timeFcn = [];         %@() -> time the scene was last rendered at
        vehPosFcn = [];       %@(t) -> vehicle position, 3x1 view-frame km
        axesListeners = {};
        isApplying(1,1) logical = false;

        undoFcn = [];         %@(label) pushes an LVD undo state before a user camera gesture
        gestureActive(1,1) logical = false;

        %Scripted mode authoring state (runtime only, never saved)
        scriptDetached(1,1) logical = false;
        detachedFollowsVehicle(1,1) logical = true;
        detachedOffset = [];  %struct(az, el, range, viewAngle) of the detached camera about the vehicle, or []
    end

    events
        %Fired when user camera input changed the camera state: chase offsets
        %retuned, or the camera detached from / re-attached to the script.
        CameraChangedByUser
    end

    methods
        function obj = LvdSceneCameraDriver(profile)
            arguments
                profile(1,1) LaunchVehicleViewProfile
            end
            obj.profile = profile;
            obj.activeMode = profile.cameraMode;
        end

        function delete(obj)
            obj.detach();
        end

        %% -------------------------------------------------- per-frame use
        function pose = computePose(obj, time, timeResolverFcn, vehPosFcn, defaultVA)
            %computePose The pose the current mode asks for at `time`, or []
            %(Manual mode, empty script, unknown vehicle position).
            arguments
                obj(1,1) LvdSceneCameraDriver
                time(1,1) double
                timeResolverFcn(1,1) function_handle
                vehPosFcn(1,1) function_handle
                defaultVA(1,1) double = NaN
            end
            obj.profile.ensureF8Defaults();

            switch(obj.profile.cameraMode)
                case LvdCameraModeEnum.Manual
                    pose = [];

                case LvdCameraModeEnum.Chase
                    pose = obj.profile.chaseCamera.getPose(vehPosFcn(time));

                case LvdCameraModeEnum.Scripted
                    pose = obj.profile.cameraScript.evaluate(time, timeResolverFcn, vehPosFcn, defaultVA, obj.profile.frame);

                case LvdCameraModeEnum.FixedAnchor
                    pose = obj.profile.fixedAnchorCamera.getPose(time, obj.profile.frame, vehPosFcn(time));

                otherwise
                    pose = [];
            end
        end

        function applied = applyAtTime(obj, time, hAx, timeResolverFcn, vehPosFcn)
            %applyAtTime Sets the axes camera for `time` according to the
            %profile's camera mode.  Returns true when the camera was set.
            applied = false;
            mode = obj.profile.cameraMode;
            if(mode ~= obj.activeMode)
                obj.onModeChanged(mode, hAx);
            end

            if(mode == LvdCameraModeEnum.Manual)
                return;
            end

            defaultVA = NaN;
            try
                defaultVA = hAx.CameraViewAngle;
            catch
            end

            if(mode == LvdCameraModeEnum.Scripted && obj.scriptDetached)
                %the user is authoring: the script does not move the camera.
                %Keep the user's offset from the vehicle when asked to, else
                %leave the camera exactly where it was left.
                if(obj.detachedFollowsVehicle && not(isempty(obj.detachedOffset)))
                    vehPos = vehPosFcn(time);
                    if(not(isempty(vehPos)) && all(isfinite(vehPos)))
                        o = obj.detachedOffset;
                        pose = LvdCameraMath.chasePose(vehPos(:), o.az, o.el, o.range, o.viewAngle);
                        if(not(isempty(pose)))
                            obj.writePose(pose, hAx);
                        end
                    end
                else
                    obj.restoreManualCamOnProfile();
                end
                return;
            end

            pose = obj.computePose(time, timeResolverFcn, vehPosFcn, defaultVA);
            if(isempty(pose))
                return;
            end

            obj.writePose(pose, hAx);
            applied = true;

            if(obj.gestureActive && not(obj.isUserDrivingCamera()))
                obj.gestureActive = false;
            end
        end

        function applyPosePreview(obj, pose, hAx)
            %applyPosePreview Shows a pose on the axes without changing mode
            %and without letting it leak into the saved manual camera.
            if(isempty(pose))
                return;
            end
            if(isempty(obj.manualCam))
                obj.manualCam = obj.snapshotManualCamera(hAx);
            end
            obj.writePose(pose, hAx);
        end

        %% ------------------------------------------------- user input
        function attach(obj, hAx, hFig, mouseHandler, timeFcn, vehPosFcn)
            %attach Watches the axes camera for user-driven changes.  Safe to
            %call every frame: listeners are created once per axes, the
            %closures are refreshed each time.
            arguments
                obj(1,1) LvdSceneCameraDriver
                hAx
                hFig
                mouseHandler
                timeFcn(1,1) function_handle
                vehPosFcn(1,1) function_handle
            end
            obj.timeFcn = timeFcn;
            obj.vehPosFcn = vehPosFcn;
            obj.mouseHandler = mouseHandler;
            obj.attachedFig = hFig;

            if(not(isempty(obj.attachedAxes)) && isvalid(obj.attachedAxes) && obj.attachedAxes == hAx && not(isempty(obj.axesListeners)))
                return;
            end

            obj.detach();
            obj.attachedAxes = hAx;
            props = {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'};
            for(i=1:numel(props)) %#ok<*NO4LP>
                obj.axesListeners{end+1} = addlistener(hAx, props{i}, 'PostSet', @(~,~) obj.onAxesCameraChanged());
            end
        end

        function setUndoFcn(obj, undoFcn)
            %setUndoFcn Callback @(label) that records an LVD undo state; it
            %is called once at the start of each user camera gesture that
            %changes the profile (a Chase retune).  Detaching from a script
            %changes nothing that is saved, so it records no state.
            obj.undoFcn = undoFcn;
        end

        %% -------------------------------------- script authoring state
        function detachFromScript(obj, hAx)
            %detachFromScript Stops the script from driving the camera (the
            %mode stays Camera Script) so the user can set up a keyframe.
            %The camera's current offset from the vehicle is remembered so
            %the vehicle stays framed while the time is scrubbed.
            if(obj.profile.cameraMode ~= LvdCameraModeEnum.Scripted)
                return;
            end
            wasDetached = obj.scriptDetached;
            obj.scriptDetached = true;
            obj.captureDetachedOffset(hAx);
            obj.restoreManualCamOnProfile();
            obj.lastPose = [];
            if(not(wasDetached))
                notify(obj, 'CameraChangedByUser');
            end
        end

        function resumeScript(obj)
            %resumeScript Lets the script drive the camera again from the
            %next rendered frame.
            wasDetached = obj.scriptDetached;
            obj.scriptDetached = false;
            obj.detachedOffset = [];
            if(wasDetached)
                notify(obj, 'CameraChangedByUser');
            end
        end

        function tf = isScriptDetached(obj)
            tf = obj.profile.cameraMode == LvdCameraModeEnum.Scripted && obj.scriptDetached;
        end

        function setDetachedFollowMode(obj, followsVehicle)
            %setDetachedFollowMode true: a detached camera keeps its offset
            %from the vehicle as the time changes; false: it stays put.
            obj.detachedFollowsVehicle = logical(followsVehicle);
        end

        function o = getDetachedCameraOffset(obj)
            o = obj.detachedOffset;
        end

        function detach(obj)
            for(i=1:numel(obj.axesListeners))
                if(isvalid(obj.axesListeners{i}))
                    delete(obj.axesListeners{i});
                end
            end
            obj.axesListeners = {};
            obj.attachedAxes = [];
        end

        function tf = isUserDrivingCamera(obj)
            %isUserDrivingCamera True while the mouse camera handler is
            %dragging or a camera toolbar mode (orbit, pan, dolly, zoom) is on.
            tf = false;
            try
                if(not(isempty(obj.mouseHandler)) && isvalid(obj.mouseHandler) && obj.mouseHandler.isDragInProgress())
                    tf = true;
                    return;
                end
            catch
            end
            try
                if(not(isempty(obj.attachedFig)) && isvalid(obj.attachedFig))
                    m = cameratoolbar(obj.attachedFig, 'GetMode');
                    tf = not(isempty(m)) && not(strcmpi(m, 'nomode'));
                end
            catch
            end
        end

        function onAxesCameraChanged(obj)
            %onAxesCameraChanged The axes camera changed.  Ignore the driver's
            %own writes and programmatic changes; act on the user's.
            if(obj.isApplying)
                return;
            end
            if(obj.profile.cameraMode == LvdCameraModeEnum.Manual)
                return;
            end
            if(not(obj.isUserDrivingCamera()))
                return;
            end
            hAx = obj.attachedAxes;
            if(isempty(hAx) || not(isvalid(hAx)))
                return;
            end
            obj.handleUserCameraChange(hAx, "motion");
        end

        function onUserCameraDrag(obj, hAx, time, vehPosFcn, phase)
            %onUserCameraDrag Explicit report from the mouse camera handler
            %(cameraDragFcn).  The PostSet path has usually already retuned
            %the camera during the drag; this makes the result final and
            %notifies listeners once at the end of the gesture.
            arguments
                obj(1,1) LvdSceneCameraDriver
                hAx
                time(1,1) double
                vehPosFcn(1,1) function_handle
                phase(1,1) string = "motion"
            end
            obj.timeFcn = @() time;
            obj.vehPosFcn = vehPosFcn;
            obj.handleUserCameraChange(hAx, phase);
        end

        function takeManualControl(obj, hAx)
            %takeManualControl Makes the axes' current camera the saved
            %manual camera and switches the profile to Manual mode.
            %The axes are unit-scaled; the profile persists km.
            sCam = 1;
            try
                sCam = LvdSceneNormalizer.getScale(hAx);
            catch
            end
            cam = struct('position', reshape(hAx.CameraPosition,1,3)/sCam, ...
                         'target', reshape(hAx.CameraTarget,1,3)/sCam, ...
                         'up', reshape(hAx.CameraUpVector,1,3), ...
                         'viewAngle', hAx.CameraViewAngle, ...
                         'azEl', obj.profile.viewAzEl, ...
                         'zoomAxLims', obj.profile.viewZoomAxLims);
            try
                [az, el] = view(hAx);
                cam.azEl = [az, el];
            catch
            end
            obj.manualCam = cam;
            obj.restoreManualCamOnProfile();
            obj.profile.cameraMode = LvdCameraModeEnum.Manual;
            obj.activeMode = LvdCameraModeEnum.Manual;
            obj.manualCam = [];
            obj.lastPose = [];
        end

        %% --------------------------------------------- manual camera
        function onModeChanged(obj, newMode, hAx)
            %onModeChanged Bookkeeping for entering/leaving Manual mode.
            oldMode = obj.activeMode;

            if(oldMode == LvdCameraModeEnum.Manual && newMode ~= LvdCameraModeEnum.Manual)
                obj.manualCam = obj.snapshotManualCamera(hAx);

            elseif(oldMode ~= LvdCameraModeEnum.Manual && newMode == LvdCameraModeEnum.Manual)
                obj.restoreManualCamOnProfile();
                if(not(isempty(obj.manualCam)) && not(isempty(hAx)) && isvalid(hAx) && ...
                   not(obj.profile.updateViewAxesLimits))
                    cam = obj.manualCam;
                    if(not(any(isnan(cam.position))) && not(any(isnan(cam.target))) && not(any(isnan(cam.up))))
                        obj.writePose(LvdCameraMath.makePose(cam.position, cam.target, cam.up, cam.viewAngle), hAx);
                    end
                end
                obj.manualCam = [];
                obj.lastPose = [];
            end

            %a mode change always ends an authoring detachment
            obj.scriptDetached = false;
            obj.detachedOffset = [];

            obj.activeMode = newMode;
        end

        function restoreManualCamOnProfile(obj)
            %restoreManualCamOnProfile Undoes the main window's PostSet
            %write-back so the saved manual camera stays what it was.
            if(isempty(obj.manualCam))
                return;
            end
            cam = obj.manualCam;
            p = obj.profile;
            p.viewCameraPosition = cam.position;
            p.viewCameraTarget = cam.target;
            p.viewCameraUpVector = cam.up;
            p.viewCameraViewAngle = cam.viewAngle;
            p.viewAzEl = cam.azEl;
            p.viewZoomAxLims = cam.zoomAxLims;
        end

        function cam = getManualCameraSnapshot(obj)
            cam = obj.manualCam;
        end
    end

    methods(Access = private)
        function writePose(obj, pose, hAx)
            %writePose Sets the axes camera, marking the write as the
            %driver's own so the camera listeners ignore it, then protects
            %the saved manual camera.  Poses are computed in km; the axes
            %show unit-scaled (~1) units, so scale at the boundary.
            try
                pose = LvdSceneNormalizer.scalePoseToAxes(pose, LvdSceneNormalizer.getScale(hAx));
            catch
            end
            obj.isApplying = true;
            try
                LvdCameraMath.applyPoseToAxes(pose, hAx);
            catch ME
                obj.isApplying = false;
                rethrow(ME);
            end
            obj.isApplying = false;
            obj.lastPose = pose;
            obj.restoreManualCamOnProfile();
        end

        function handleUserCameraChange(obj, hAx, phase)
            if(obj.profile.cameraMode == LvdCameraModeEnum.Manual)
                return;
            end

            %one undo state per gesture, recorded before the first change
            %(a Chase retune, a FixedXYZ anchor move, or grabbing an
            %object-anchored fixed camera into Manual; detaching from a
            %script saves nothing)
            if(not(obj.gestureActive))
                obj.gestureActive = true;
                undoLabel = '';
                if(obj.profile.cameraMode == LvdCameraModeEnum.Chase)
                    undoLabel = 'Adjust Chase Camera by Mouse';
                elseif(obj.profile.cameraMode == LvdCameraModeEnum.FixedAnchor)
                    if(obj.profile.fixedAnchorCamera.anchorType == LvdCameraAnchorTypeEnum.FixedXYZ)
                        undoLabel = 'Move Fixed Camera by Mouse';
                    else
                        undoLabel = 'Take Manual Camera Control';
                    end
                end
                if(not(isempty(obj.undoFcn)) && not(isempty(undoLabel)))
                    try
                        obj.undoFcn(undoLabel);
                    catch
                    end
                end
            end
            if(phase == "end")
                obj.gestureActive = false;
            end

            switch(obj.profile.cameraMode)
                case LvdCameraModeEnum.Manual
                    return;

                case LvdCameraModeEnum.Chase
                    vehPos = obj.currentVehiclePosition();
                    if(isempty(vehPos) || any(not(isfinite(vehPos))))
                        return;
                    end
                    %the camera position the user chose becomes the chase
                    %offset; the target is pinned back onto the vehicle so an
                    %orbit always orbits the vehicle and a dolly changes range
                    obj.profile.chaseCamera.setFromCamera(hAx, vehPos(:));
                    pose = obj.profile.chaseCamera.getPose(vehPos(:));
                    if(not(isempty(pose)))
                        obj.writePose(pose, hAx);
                    end
                    if(phase == "end" || not(obj.mouseDragging()))
                        notify(obj, 'CameraChangedByUser');
                    end

                case LvdCameraModeEnum.Scripted
                    %authoring: the camera comes off the script and follows
                    %the user's hand; the saved manual camera stays protected
                    if(obj.scriptDetached)
                        obj.captureDetachedOffset(hAx);
                        obj.reassertAxesCamera(hAx);
                        if(phase == "end")
                            notify(obj, 'CameraChangedByUser');
                        end
                    else
                        obj.detachFromScript(hAx);   %notifies
                        obj.reassertAxesCamera(hAx);
                    end

                case LvdCameraModeEnum.FixedAnchor
                    if(obj.profile.fixedAnchorCamera.anchorType == LvdCameraAnchorTypeEnum.FixedXYZ)
                        %the dragged camera position becomes the fixed anchor
                        %and the target is pinned back onto the vehicle, so an
                        %orbit orbits the vehicle and a dolly moves the pad
                        time = obj.currentTime();
                        obj.profile.fixedAnchorCamera.setFixedPositionFromCamera(hAx, time, obj.profile.frame);
                        vehPos = obj.currentVehiclePosition();
                        pose = obj.profile.fixedAnchorCamera.getPose(time, obj.profile.frame, vehPos(:));
                        if(not(isempty(pose)))
                            obj.writePose(pose, hAx);
                        end
                        if(phase == "end" || not(obj.mouseDragging()))
                            notify(obj, 'CameraChangedByUser');
                        end
                    else
                        %the anchor is owned by another object and cannot be
                        %dragged: grabbing the camera hands over to free look
                        obj.takeManualControl(hAx);
                        notify(obj, 'CameraChangedByUser');
                    end
            end
        end

        function reassertAxesCamera(obj, hAx)
            %reassertAxesCamera Re-writes the axes' current camera through
            %writePose.  The main window's own PostSet listener may run AFTER
            %this driver's for the same property change and would then be the
            %last to write the saved manual camera; writing the (unchanged)
            %camera once more makes the driver's restore the final word.
            try
                pose = LvdCameraMath.poseFromAxes(hAx);
                %poseFromAxes reads scaled axes units; writePose expects km.
                pose.position = LvdSceneNormalizer.unscalePos(pose.position, hAx);
                pose.target = LvdSceneNormalizer.unscalePos(pose.target, hAx);
            catch
                pose = [];
            end
            if(isempty(pose))
                obj.restoreManualCamOnProfile();
                return;
            end
            obj.writePose(pose, hAx);
            obj.lastPose = [];
        end

        function captureDetachedOffset(obj, hAx)
            %captureDetachedOffset Remembers the camera's spherical offset
            %from the vehicle (for detachedFollowsVehicle); [] when the
            %vehicle position is unknown.
            obj.detachedOffset = [];
            if(isempty(hAx) || not(isvalid(hAx)))
                return;
            end
            vehPos = obj.currentVehiclePosition();
            if(isempty(vehPos) || any(not(isfinite(vehPos))))
                return;
            end
            %Axes camera is unit-scaled; offsets are computed in km.
            camPosKm = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraPosition,1,3), hAx);
            [az, el, r] = LvdCameraMath.cartesianToSpherical(camPosKm - vehPos(:)');
            obj.detachedOffset = struct('az', az, 'el', el, 'range', max(r, 1e-9), 'viewAngle', hAx.CameraViewAngle);
        end

        function tf = mouseDragging(obj)
            tf = false;
            try
                tf = not(isempty(obj.mouseHandler)) && isvalid(obj.mouseHandler) && obj.mouseHandler.isDragInProgress();
            catch
            end
        end

        function vehPos = currentVehiclePosition(obj)
            vehPos = NaN(3,1);
            if(isempty(obj.timeFcn) || isempty(obj.vehPosFcn))
                return;
            end
            try
                vehPos = obj.vehPosFcn(obj.timeFcn());
            catch
                vehPos = NaN(3,1);
            end
        end

        function t = currentTime(obj)
            t = 0;
            if(isempty(obj.timeFcn))
                return;
            end
            try
                t = obj.timeFcn();
            catch
                t = 0;
            end
        end

        function cam = snapshotManualCamera(obj, hAx)
            p = obj.profile;
            cam = struct('position', p.viewCameraPosition, ...
                         'target', p.viewCameraTarget, ...
                         'up', p.viewCameraUpVector, ...
                         'viewAngle', p.viewCameraViewAngle, ...
                         'azEl', p.viewAzEl, ...
                         'zoomAxLims', p.viewZoomAxLims);

            %a profile that has never recorded a camera holds NaNs; take the
            %live axes camera instead so Manual can be restored later.
            %The axes are unit-scaled; the snapshot persists km.
            if(not(isempty(hAx)) && isvalid(hAx))
                if(any(isnan(cam.position)))
                    cam.position = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraPosition,1,3), hAx);
                end
                if(any(isnan(cam.target)))
                    cam.target = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraTarget,1,3), hAx);
                end
                if(any(isnan(cam.up)))
                    cam.up = reshape(hAx.CameraUpVector,1,3);
                end
                if(isnan(cam.viewAngle))
                    cam.viewAngle = hAx.CameraViewAngle;
                end
            end
        end
    end
end
