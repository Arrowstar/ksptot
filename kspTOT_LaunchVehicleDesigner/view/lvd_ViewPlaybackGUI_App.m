classdef lvd_ViewPlaybackGUI_App < matlab.apps.AppBase
    %lvd_ViewPlaybackGUI_App 3-D view playback, camera control, vehicle mesh,
    %data overlay and video/image export for the Launch Vehicle Designer (F8).
    %
    %   Programmatic App Designer (uifigure) window in the style of
    %   lvd_VariableTableGUI_App.  Launched from the LVD main window as
    %
    %       lvd_ViewPlaybackGUI_App(lvdData, mainApp);
    %
    %   The window is NOT modal.  It drives the main window's 3-D axes and
    %   time slider through lvd_renderSceneAtTime, so everything it does is
    %   visible in the main window as it happens.
    %
    %   EVERY setting in this window belongs to the ACTIVE VIEW PROFILE
    %   (lvdData.viewSettings.selViewProfile) and is saved with it in the
    %   mission file; the window says so in its title and banner and follows
    %   the active profile when it is switched.  Every edit records an LVD
    %   undo state (Edit > Undo) with a descriptive label, and the window
    %   re-binds itself after an undo/redo replaces the mission object.
    %
    %   lvd_ViewPlaybackGUI_App(lvdData, mainApp, false) builds the window
    %   hidden, which the unit tests use.  The public methods below the
    %   constructor are the test seam and never open a dialog.

    % Framework components
    properties (Access = public)
        UIFigure
        MainGrid
        ProfileHeaderLabel
        TabGroup
        StatusLabel

        %Playback tab
        PlaybackTab
        PlaybackGrid
        TimeLabel
        TransportGrid
        GoToStartButton
        StepBackButton
        PlayButton
        PauseButton
        StopButton
        StepFwdButton
        GoToEndButton
        PlaybackSettingsPanel
        PlaybackSettingsGrid
        SpeedEditField
        FpsEditField
        LoopCheckBox
        ExportPanel
        ExportGrid
        VideoFormatDropDown
        QualityEditField
        ExportStartEditField
        ExportEndEditField
        ExportVideoButton
        ImageDpiEditField
        ExportImageButton
        CopyImageButton

        %Camera tab
        CameraTab
        CameraGrid
        CameraModeDropDown
        ChasePanel
        ChaseGrid
        ChaseAzEditField
        ChaseElEditField
        ChaseRangeEditField
        ChaseViewAngleEditField
        ChaseFromCurrentButton
        FixedAnchorPanel
        FixedAnchorGrid
        FixedXYZSubGrid
        GroundObjSubGrid
        GeomPtSubGrid
        AnchorTypeDropDown
        AnchorViewAngleEditField
        AnchorXEditField
        AnchorYEditField
        AnchorZEditField
        AnchorFrameSelector
        AnchorFromCurrentButton
        AnchorGroundObjectDropDown
        AnchorGeometricPointDropDown
        ScriptPanel
        ScriptGrid
        ScriptStateLabel
        KeyframeTable
        KeyframeButtonGrid
        AddKeyframeButton
        UpdateKeyframeButton
        ResumeScriptButton
        RemoveKeyframeButton
        NewKeyframeGrid
        NewKeyframeRefDropDown
        NewKeyframeAnchorDropDown
        KeyframeEditorPanel
        KeyframeEditorGrid
        AdvancedPoseCheckBox
        AdvancedPoseGrid
        KfNameEditField
        KfAnchorDropDown
        KfEventDropDown
        KfTimeEditField
        KfHoldEditField
        KfRefDropDown
        KfEasingDropDown
        KfViewAngleEditField
        KfPosXEditField
        KfPosYEditField
        KfPosZEditField
        KfTgtXEditField
        KfTgtYEditField
        KfTgtZEditField
        KfUpXEditField
        KfUpYEditField
        KfUpZEditField
        KfAzEditField
        KfElEditField
        KfRangeEditField
        KfAnchorEditorGrid
        KfAnchorTypeDropDown
        KfFixedXYZSubGrid
        KfGroundObjSubGrid
        KfGeomPtSubGrid
        KfAnchorXEditField
        KfAnchorYEditField
        KfAnchorZEditField
        KfAnchorFrameSelector
        KfAnchorFromCurrentButton
        KfAnchorGroundObjectDropDown
        KfAnchorGeometricPointDropDown
        ApplyKeyframeButton

        %Vehicle mesh tab
        MeshTab
        MeshGrid
        MeshEnabledCheckBox
        MeshPathLabel
        ImportMeshButton
        ReloadMeshButton
        ClearMeshButton
        ShowInChaseButton
        MeshTransformPanel
        MeshScaleNoteLabel
        MeshTransformGrid
        MeshScaleEditField
        FitLengthEditField
        FitButton
        MeshYawEditField
        MeshPitchEditField
        MeshRollEditField
        MeshTransXEditField
        MeshTransYEditField
        MeshTransZEditField
        MeshAppearancePanel
        MeshAppearanceGrid
        MeshFaceColorButton
        MeshAlphaSpinner
        MeshShowEdgesCheckBox
        MeshEdgeColorButton
        MeshLightingCheckBox
        MeshInfoLabel
        MeshPreviewAxes

        %Data overlay tab
        OverlayTab
        OverlayGrid
        OverlayEnabledCheckBox
        OverlayLeftGrid
        OverlayContentPanel
        OverlayContentGrid
        OverlayTitleEditField
        OverlayShowEpochCheckBox
        OverlayShowUtCheckBox
        OverlayShowMetCheckBox
        OverlayShowEventCheckBox
        OverlayStylePanel
        OverlayStyleGrid
        OverlayCornerDropDown
        OverlayMarginSpinner
        OverlayFontNameDropDown
        OverlayFontSizeSpinner
        OverlayBoldCheckBox
        OverlayFontColorButton
        OverlayBackgroundCheckBox
        OverlayBackgroundColorButton
        OverlayQuantitiesPanel
        OverlayQuantitiesGrid
        OverlayTable
        OverlayItemButtonGrid
        OverlayRemoveButton
        OverlayMoveUpButton
        OverlayMoveDownButton
        OverlayAddPanel
        OverlayAddGrid
        OverlaySearchEditField
        OverlayTaskListBox
        OverlayFrameLabel
        OverlayFrameSelector
        OverlayAddButton
        OverlayPreviewLabel
    end

    properties (Access = private)
        LvdData
        MainApp
        Controller
        Listeners
        DriverListener = [];
        SelectedKfInd = 0;          %index into cameraScript.keyframes (NOT a table row)
        KeyframeRowOrder = [];      %table row r shows keyframe KeyframeRowOrder(r) (sorted by resolved time)
        ActiveKfInd = 0;            %keyframe whose segment covers the current time (bold row)
        SelectedOverlayInd = 0;
        Populating = false;
    end

    properties (Access = public, Hidden)
        %titles of every progress dialog shown, oldest first (test seam)
        ProgressDialogLog = {};
        %labels of every undo state this window pushed, oldest first (test seam)
        UndoLog = {};
        %messages of errors caught by the field callbacks (shown to the user
        %as alerts), oldest first (test seam)
        CallbackErrorLog = {};
    end

    %private so AppThemer.themeApp (which walks the public properties as
    %widgets) never sees them
    properties (Constant, Access = private)
        FigureTag = 'lvd_ViewPlaybackGUI';
        WindowName = 'LVD 3-D View Playback';
        %Selected Keyframe panel: title + padding + rows + spacing, with the
        %numeric pose rows hidden / shown
        EditorHeightCollapsed = 200;
        EditorHeightExpanded = 264;
        %a FixedAnchorTracking keyframe hides the numeric-pose checkbox/grid
        %and shows the anchor editor instead (XYZ needs an extra frame + "set
        %from current camera" line, so it is taller than the object anchors).
        EditorHeightFixedAnchorXYZ = 292;
        EditorHeightFixedAnchorObject = 264;
        %Camera Script panel: the keyframe table is a fixed height so the
        %advanced-pose editor grows the (scrollable) Camera tab instead of
        %squeezing the table; the script row is the fixed chrome plus whatever
        %height the selected-keyframe editor currently needs.
        KeyframeTableHeight = 150;
        ScriptPanelHeightCollapsed = 535;
        ScriptPanelHeightExpanded = 599;    %+ (EditorHeightExpanded - EditorHeightCollapsed)
        ScriptPanelChromeHeight = 335;      %ScriptPanelHeightCollapsed - EditorHeightCollapsed
        %Fixed Camera panel: title + padding + the always-shown header row plus
        %the anchor-specific sub-grid.  FixedXYZ needs two control lines (XYZ,
        %then frame + "set from current"); a ground-object / geometric-point
        %anchor needs only one.
        FixedAnchorHeightXYZ = 150;
        FixedAnchorHeightObject = 110;
    end

    methods (Access = public)
        function app = lvd_ViewPlaybackGUI_App(varargin)
            %singleton: raise an existing window instead of opening a second
            existing = findall(groot, 'Type', 'figure', 'Tag', lvd_ViewPlaybackGUI_App.FigureTag);
            existingApp = [];
            if(not(isempty(existing)))
                existingApp = getappdata(existing(1), 'LvdViewPlaybackApp');
            end
            if(not(isempty(existingApp)) && isvalid(existingApp))
                figure(existing(1));
                app = existingApp;
                if(nargout == 0)
                    clear app
                end
                return;
            end

            createComponents(app);

            %Deliberately NOT registerApp(app, app.UIFigure): the LVD main
            %window is a GUIDE-migrated app whose callbacks fetch their
            %`handles` through AppManagementService.getFigure, which returns
            %whichever REGISTERED App Designer figure is first in the groot
            %children list - i.e. this window whenever it is in front.  Its
            %main-window callbacks (Edit menu, ...) would then build `handles`
            %from this window and fail.  Reproduce the two things registerApp
            %does that matter (figure destroyed -> app deleted; startup) here.
            addlistener(app.UIFigure, 'ObjectBeingDestroyed', @(~,~) delete(app));
            app.startupFcn(varargin{:});

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if(not(isempty(app.Controller)) && isvalid(app.Controller))
                try
                    app.Controller.stop(false);
                catch
                end
                delete(app.Controller);
            end
            app.Controller = [];

            app.deleteListeners();

            if(not(isempty(app.UIFigure)) && isvalid(app.UIFigure))
                delete(app.UIFigure);
            end
        end

        %% ------------------------------------------------------ general
        function refresh(app)
            %refresh Re-reads the active view profile and the propagation
            %state into every control.
            if(isempty(app.LvdData) || isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end

            if(not(isempty(app.Controller)) && isvalid(app.Controller))
                app.Controller.stop(false);
            end

            hasLog = app.hasStateLog();
            if(hasLog)
                [t0, t1] = app.LvdData.stateLog.getStartAndEndTimes();
                lims = [t0 t1];
            else
                lims = [NaN NaN];
            end
            if(not(isempty(app.Controller)) && isvalid(app.Controller))
                app.Controller.setTimeLimits(lims);
            end

            app.updateProfileHeader();
            app.populatePlaybackTab();
            app.populateCameraTab();
            app.populateMeshTab();
            app.populateOverlayTab();
            app.updateEnableStates();
            app.updateTimeLabel();
            app.listenToCameraDriver();

            if(not(hasLog))
                app.StatusLabel.Text = 'No propagated trajectory.  Propagate the mission to enable playback and export.';
            else
                app.StatusLabel.Text = sprintf('Trajectory spans %.1f s of simulated time.  Settings shown are those of view profile "%s".', ...
                                               lims(2) - lims(1), app.getProfileName());
            end
        end

        function onMainSceneRendered(app, lvdData)
            %onMainSceneRendered Called by lvd_renderSceneAtTime on every
            %frame of the main window.  After an undo/redo the main window
            %holds a NEW LvdData object; re-bind to it.
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end
            if(isempty(lvdData) || not(isa(lvdData, 'LvdData')))
                return;
            end
            if(isempty(app.LvdData) || not(isvalid(app.LvdData)) || app.LvdData ~= lvdData)
                app.bindToLvdData(lvdData);
            end
        end

        function profile = getProfile(app)
            profile = [];
            if(not(isempty(app.LvdData)) && isvalid(app.LvdData) && not(isempty(app.LvdData.viewSettings)))
                profile = app.LvdData.viewSettings.selViewProfile;
                if(not(isempty(profile)))
                    profile.ensureF8Defaults();
                end
            end
        end

        function name = getProfileName(app)
            name = '';
            profile = app.getProfile();
            if(not(isempty(profile)))
                name = char(profile.name);
            end
        end

        function lvdData = getLvdData(app)
            lvdData = app.LvdData;
        end

        function ctrl = getController(app)
            ctrl = app.Controller;
        end

        function [t0, t1] = getTimeLimits(app)
            lims = app.Controller.timeLimits;
            t0 = lims(1);
            t1 = lims(2);
        end

        function t = getCurrentTime(app)
            t = app.Controller.currentTime;
        end

        %% ----------------------------------------------------- playback
        function play(app)
            if(not(app.hasStateLog()))
                app.StatusLabel.Text = 'Propagate the mission before playing it back.';
                return;
            end
            app.applyPlaybackFields();
            %playing is watching: a camera detached for authoring re-attaches
            app.resumeScript(false);
            app.Controller.play();
        end

        function pause(app)
            app.Controller.pause();
        end

        function stop(app)
            app.Controller.stop(true);
        end

        function stepTo(app, time)
            app.Controller.stepTo(time);
        end

        function stepFrames(app, numFrames)
            app.applyPlaybackFields();
            app.Controller.stepFrames(numFrames);
        end

        function changed = applyPlaybackFields(app)
            %applyPlaybackFields Writes the playback controls to the profile
            %(one undo state when anything actually changed).
            settings = app.getProfile().playbackSettings;
            new = struct('simSecPerRealSec', app.SpeedEditField.Value, ...
                         'fps', app.FpsEditField.Value, ...
                         'loop', logical(app.LoopCheckBox.Value), ...
                         'videoFormat', string(app.VideoFormatDropDown.Value), ...
                         'videoQuality', app.QualityEditField.Value, ...
                         'imageDpi', app.ImageDpiEditField.Value, ...
                         'exportStartTime', app.parseOptionalTime(app.ExportStartEditField.Value), ...
                         'exportEndTime', app.parseOptionalTime(app.ExportEndEditField.Value));
            changed = app.applyStructIfChanged(settings, new, 'Edit Playback Settings');
        end

        %% ------------------------------------------------------- export
        function numFrames = exportVideo(app, filePath, opts)
            %exportVideo Renders the export time range frame by frame into a
            %video/GIF file.  opts (optional struct) overrides the profile's
            %playback settings for this call: videoFormat, fps,
            %simSecPerRealSec, videoQuality, exportStartTime, exportEndTime,
            %showProgress (default: true when the window is visible).
            arguments
                app
                filePath(1,:) char
                opts struct = struct()
            end
            if(not(app.hasStateLog()))
                error('lvd_ViewPlaybackGUI_App:noStateLog', 'Propagate the mission before exporting a video.');
            end

            app.applyPlaybackFields();
            settings = app.getProfile().playbackSettings.copyForExport();
            fields = fieldnames(opts);
            for(i=1:numel(fields)) %#ok<*NO4LP>
                if(isprop(settings, fields{i}))
                    settings.(fields{i}) = opts.(fields{i});
                end
            end

            showProgress = strcmp(app.UIFigure.Visible, 'on');
            if(isfield(opts, 'showProgress'))
                showProgress = logical(opts.showProgress);
            end

            [t0, t1] = LvdViewExporter.exportTimeRange(settings, app.Controller.timeLimits);
            times = LvdViewPlaybackController.frameSchedule(t0, t1, settings.fps, settings.simSecPerRealSec);

            app.Controller.pause();
            tBefore = app.Controller.currentTime;

            renderFcn = @(t) app.Controller.stepTo(t);
            captureFcn = @() LvdViewExporter.captureAxesFrame(app.MainApp.dispAxes);

            dlg = [];
            progressFcn = [];
            if(showProgress)
                dlg = uiprogressdlg(app.UIFigure, 'Title', 'Exporting Video', 'Message', 'Rendering frames...', 'Cancelable', 'on');
                progressFcn = @(k, n) lvd_ViewPlaybackGUI_App.updateProgress(dlg, k, n);
            end
            cleanup = onCleanup(@() closeIfValid(dlg)); %#ok<NASGU>

            numFrames = LvdViewExporter.exportVideo(filePath, settings.videoFormat, settings.fps, settings.videoQuality, ...
                                                    times, renderFcn, captureFcn, progressFcn);

            app.Controller.stepTo(tBefore);
            if(numFrames == numel(times))
                app.StatusLabel.Text = sprintf('Wrote %u frames to %s', numFrames, filePath);
            else
                app.StatusLabel.Text = sprintf('Video export cancelled after %u of %u frames.', numFrames, numel(times));
            end
        end

        function exportImage(app, filePath)
            arguments
                app
                filePath(1,:) char
            end
            app.applyPlaybackFields();
            LvdViewExporter.exportImage(app.MainApp.dispAxes, filePath, app.getProfile().playbackSettings.imageDpi);
            app.StatusLabel.Text = sprintf('Image written to %s', filePath);
        end

        function tf = copyImage(app)
            tf = LvdViewExporter.copyImageToClipboard(app.MainApp.dispAxes);
            if(tf)
                app.StatusLabel.Text = 'The 3-D view was copied to the clipboard.';
            else
                app.StatusLabel.Text = 'The clipboard is not available in this session.';
            end
        end

        %% ------------------------------------------------------- camera
        function setCameraMode(app, mode)
            arguments
                app
                mode(1,1) LvdCameraModeEnum
            end
            profile = app.getProfile();
            if(profile.cameraMode ~= mode)
                app.pushUndo('Change Camera Mode');
            end
            profile.cameraMode = mode;
            %entering FixedAnchor with an object-backed anchor type but no
            %object selected (e.g. a profile saved by an older build, or a
            %single-item dropdown that never fired its callback) would render
            %nothing: seed the object so the tracking camera resolves.
            if(mode == LvdCameraModeEnum.FixedAnchor)
                app.seedFixedAnchorObjectIfEmpty(profile.fixedAnchorCamera);
            end
            app.Populating = true;
            app.CameraModeDropDown.Value = mode.name;
            app.Populating = false;
            app.updateEnableStates();
            app.renderCurrent();
        end

        function seedFixedAnchorObjectIfEmpty(app, fa)
            %seedFixedAnchorObjectIfEmpty Defaults an object-backed anchor to
            %the first available object when none is selected.  A single-item
            %ground-object / geometric-point dropdown never fires its
            %ValueChangedFcn, so the anchor object could otherwise be left
            %empty and never resolve to a camera pose (no tracking).
            if(fa.anchorType == LvdCameraAnchorTypeEnum.GroundObject && isempty(fa.groundObject))
                [~, objs] = app.LvdData.groundObjs.getListboxStr();
                if(not(isempty(objs)))
                    fa.groundObject = objs(1);
                end
            elseif(fa.anchorType == LvdCameraAnchorTypeEnum.GeometricPoint && isempty(fa.geometricPoint))
                [~, pts] = app.filteredGeomPoints();
                if(not(isempty(pts)))
                    fa.geometricPoint = pts(1);
                end
            end
        end

        function setChaseParams(app, azDeg, elDeg, rangeKm, viewAngleDeg)
            chase = app.getProfile().chaseCamera;
            new = struct('azDeg', azDeg, 'elDeg', elDeg, 'rangeKm', rangeKm, 'viewAngleDeg', viewAngleDeg);
            app.applyStructIfChanged(chase, new, 'Edit Chase Camera');
            app.populateCameraTab();
            app.renderCurrent();
        end

        function applyChaseFields(app)
            app.setChaseParams(app.ChaseAzEditField.Value, app.ChaseElEditField.Value, ...
                               app.ChaseRangeEditField.Value, app.ChaseViewAngleEditField.Value);
        end

        function setChaseFromCurrentCamera(app)
            vehPos = app.vehiclePositionNow();
            if(any(isnan(vehPos)))
                app.StatusLabel.Text = 'The vehicle position is unknown at this time; move the slider onto the trajectory first.';
                return;
            end
            app.pushUndo('Set Chase Camera from Current View');
            app.getProfile().chaseCamera.setFromCamera(app.MainApp.dispAxes, vehPos);
            app.populateCameraTab();
            app.renderCurrent();
        end

        %% -------------------------------------------- fixed anchor camera
        function setCameraAnchorType(app, anchorType)
            arguments
                app
                anchorType(1,1) LvdCameraAnchorTypeEnum
            end
            fa = app.getProfile().fixedAnchorCamera;
            app.applyStructIfChanged(fa, struct('anchorType', anchorType), 'Edit Fixed Anchor Camera');
            %Switching into an object-backed anchor type with nothing selected
            %yet leaves the anchor object empty when the dropdown holds a
            %single item (its ValueChangedFcn never fires), so the camera would
            %never resolve.  Seed the first available object.
            app.seedFixedAnchorObjectIfEmpty(fa);
            app.populateCameraTab();
            app.renderCurrent();
        end

        function setFixedAnchorPosition(app, xyz, frame)
            %setFixedAnchorPosition Sets the fixed XYZ anchor (and switches to
            %the FixedXYZ anchor type).  frame is optional; [] leaves the
            %stored anchor frame unchanged.
            arguments
                app
                xyz(1,3) double
                frame = []
            end
            fa = app.getProfile().fixedAnchorCamera;
            new = struct('anchorType', LvdCameraAnchorTypeEnum.FixedXYZ, 'fixedPosition', reshape(xyz,1,3));
            if(not(isempty(frame)))
                new.anchorFrame = frame;
            end
            app.applyStructIfChanged(fa, new, 'Edit Fixed Anchor Camera');
            app.populateCameraTab();
            app.renderCurrent();
        end

        function setFixedAnchorFromCamera(app)
            fa = app.getProfile().fixedAnchorCamera;
            app.pushUndo('Set Fixed Anchor from Current View');
            try
                fa.anchorFrame = app.AnchorFrameSelector.getSelectedFrame();
            catch
            end
            fa.setFixedPositionFromCamera(app.MainApp.dispAxes, app.currentTimeOrStart(), app.getProfile().frame);
            app.populateCameraTab();
            app.renderCurrent();
        end

        function setAnchorGroundObject(app, indOrObj)
            [~, objs] = app.LvdData.groundObjs.getListboxStr();
            grdObj = app.resolveFromArray(indOrObj, objs);
            fa = app.getProfile().fixedAnchorCamera;
            new = struct('anchorType', LvdCameraAnchorTypeEnum.GroundObject, 'groundObject', grdObj);
            app.applyStructIfChanged(fa, new, 'Edit Fixed Anchor Camera');
            app.populateCameraTab();
            app.renderCurrent();
        end

        function setAnchorGeometricPoint(app, indOrObj)
            [~, pts] = app.filteredGeomPoints();
            pt = app.resolveFromArray(indOrObj, pts);
            fa = app.getProfile().fixedAnchorCamera;
            new = struct('anchorType', LvdCameraAnchorTypeEnum.GeometricPoint, 'geometricPoint', pt);
            app.applyStructIfChanged(fa, new, 'Edit Fixed Anchor Camera');
            app.populateCameraTab();
            app.renderCurrent();
        end

        function setFixedAnchorViewAngle(app, va)
            fa = app.getProfile().fixedAnchorCamera;
            app.applyStructIfChanged(fa, struct('viewAngleDeg', va), 'Edit Fixed Anchor Camera');
            app.populateCameraTab();
            app.renderCurrent();
        end

        function kf = addKeyframeHere(app)
            %addKeyframeHere "Add Keyframe Here": a keyframe at the current
            %time capturing the main window's camera, using the "New
            %keyframes are" reference (scene-fixed / vehicle-relative) and
            %anchor (start of the active event + offset / absolute UT)
            %defaults.  A camera detached for authoring re-attaches to the
            %script, which now passes through this keyframe, so nothing jumps.
            profile = app.getProfile();
            hAx = app.MainApp.dispAxes;
            t = app.currentTimeOrStart();

            refType = app.newKeyframeRefType();
            vehPos = app.vehiclePositionAt(t);
            if(refType == LvdCameraKeyframeRefEnum.VehicleRelative && any(isnan(vehPos)))
                refType = LvdCameraKeyframeRefEnum.SceneFixed;
                app.StatusLabel.Text = 'The vehicle position is unknown at this time, so the keyframe was added scene-fixed.';
            end
            switch(refType)
                case LvdCameraKeyframeRefEnum.VehicleRelative
                    kf = LvdCameraKeyframe.fromCameraRelativeToVehicle(hAx, vehPos(:), t);
                case LvdCameraKeyframeRefEnum.FixedAnchorTracking
                    %park the anchor at the current camera (fixed coordinates in
                    %the view frame) and track the vehicle from there
                    kf = LvdCameraKeyframe.fromSceneCamera(hAx, t);
                    kf.refType = LvdCameraKeyframeRefEnum.FixedAnchorTracking;
                    kf.anchor.setFixedPositionFromCamera(hAx, t, profile.frame);
                otherwise
                    kf = LvdCameraKeyframe.fromSceneCamera(hAx, t);
            end
            kf.name = sprintf('Keyframe %u', profile.cameraScript.getNumKeyframes() + 1);

            if(app.newKeyframesAnchorToEvents())
                app.anchorKeyframeToActiveEvent(kf, t);
            end

            app.addKeyframe(kf);
        end

        function kf = addKeyframeFromCurrentCamera(app)
            %addKeyframeFromCurrentCamera Older name of addKeyframeHere.
            kf = app.addKeyframeHere();
        end

        function setNewKeyframeDefaults(app, refType, anchorToEvents)
            %setNewKeyframeDefaults What "Add Keyframe Here" creates.
            arguments
                app
                refType(1,1) LvdCameraKeyframeRefEnum
                anchorToEvents(1,1) logical
            end
            app.Populating = true;
            app.NewKeyframeRefDropDown.Value = char(refType.name);
            if(anchorToEvents)
                app.NewKeyframeAnchorDropDown.Value = app.NewKeyframeAnchorDropDown.Items{1};
            else
                app.NewKeyframeAnchorDropDown.Value = app.NewKeyframeAnchorDropDown.Items{2};
            end
            app.Populating = false;
            app.applyNewKeyframeDefaults();
        end

        function refType = newKeyframeRefType(app)
            refType = LvdCameraKeyframeRefEnum.getEnumForListboxStr(app.NewKeyframeRefDropDown.Value);
        end

        function tf = newKeyframesAnchorToEvents(app)
            tf = strcmp(app.NewKeyframeAnchorDropDown.Value, app.NewKeyframeAnchorDropDown.Items{1});
        end

        function evt = anchorKeyframeToActiveEvent(app, kf, t)
            %anchorKeyframeToActiveEvent Anchors kf to the start of the
            %event active at time t (the later event owns a shared
            %boundary), keeping its resolved time equal to t.  Leaves the
            %keyframe on absolute time when no event covers t.
            evt = LaunchVehicleEvent.empty(1,0);
            try
                [evts, ~] = app.LvdData.script.getAllEvtsThatOccurAtTime(t);
            catch
                evts = [];
            end
            if(isempty(evts))
                return;
            end
            candidate = evts(end);
            probe = kf.copy();
            probe.anchorType = LvdCameraKeyframeAnchorEnum.EventStart;
            probe.event = candidate;
            probe.timeOffset = 0;
            [tStart, resolved] = probe.resolveTime(app.LvdData.stateLog);
            if(not(resolved))
                return;
            end
            kf.anchorType = LvdCameraKeyframeAnchorEnum.EventStart;
            kf.event = candidate;
            kf.timeOffset = t - tStart;
            kf.absTime = tStart;      %fallback if the event is ever deleted
            evt = candidate;
        end

        function addKeyframe(app, kf)
            arguments
                app
                kf(1,1) LvdCameraKeyframe
            end
            app.pushUndo('Add Camera Keyframe');
            profile = app.getProfile();
            profile.cameraScript.addKeyframe(kf);
            app.refreshKeyframeTable();
            app.selectKeyframe(profile.cameraScript.getNumKeyframes());
            app.resumeScript(false);
            app.renderCurrent();
            app.StatusLabel.Text = sprintf('Added "%s" (%s, %s).', kf.name, kf.refType.name, kf.getAnchorStr(app.LvdData.script));
        end

        function removeKeyframe(app, ind)
            profile = app.getProfile();
            if(nargin < 2)
                ind = app.SelectedKfInd;
            end
            if(ind < 1 || ind > profile.cameraScript.getNumKeyframes())
                return;
            end
            app.pushUndo('Remove Camera Keyframe');
            profile.cameraScript.removeKeyframe(ind);
            app.refreshKeyframeTable();
            app.selectKeyframe(min(ind, profile.cameraScript.getNumKeyframes()));
            app.renderCurrent();
        end

        function selectKeyframe(app, ind)
            %selectKeyframe Selects keyframe `ind` (an index into the
            %script's keyframes) in the table and editor.  Programmatic; does
            %not move the camera (a user's row click does, see goToKeyframe).
            profile = app.getProfile();
            n = profile.cameraScript.getNumKeyframes();
            if(n == 0 || ind < 1 || ind > n)
                app.SelectedKfInd = 0;
            else
                app.SelectedKfInd = ind;
            end

            app.Populating = true;
            try
                row = app.rowOfKeyframe(app.SelectedKfInd);
                if(row > 0)
                    app.KeyframeTable.Selection = row;
                else
                    app.KeyframeTable.Selection = [];
                end
            catch
            end
            app.Populating = false;

            app.populateKeyframeEditor();
            app.updateEnableStates();
        end

        function ind = getSelectedKeyframeIndex(app)
            ind = app.SelectedKfInd;
        end

        function order = getKeyframeRowOrder(app)
            %getKeyframeRowOrder Table row r shows keyframe order(r).
            order = app.KeyframeRowOrder;
        end

        function ind = getActiveKeyframeIndex(app)
            %getActiveKeyframeIndex The keyframe whose segment (hold or
            %transition to the next) covers the current time; 0 if none.
            ind = app.ActiveKfInd;
        end

        function kf = getSelectedKeyframe(app)
            kf = [];
            profile = app.getProfile();
            if(app.SelectedKfInd >= 1 && app.SelectedKfInd <= profile.cameraScript.getNumKeyframes())
                kf = profile.cameraScript.keyframes(app.SelectedKfInd);
            end
        end

        function applyKeyframeEdits(app)
            %applyKeyframeEdits Writes the keyframe editor fields onto the
            %selected keyframe.
            kf = app.getSelectedKeyframe();
            if(isempty(kf))
                return;
            end
            app.pushUndo('Edit Camera Keyframe');

            kf.name = strtrim(app.KfNameEditField.Value);
            if(isempty(kf.name))
                kf.name = sprintf('Keyframe %u', app.SelectedKfInd);
            end
            kf.anchorType = LvdCameraKeyframeAnchorEnum.getEnumForListboxStr(app.KfAnchorDropDown.Value);
            evtInd = app.KfEventDropDown.Value;
            if(kf.anchorType == LvdCameraKeyframeAnchorEnum.AbsoluteTime)
                kf.absTime = app.KfTimeEditField.Value;
                kf.timeOffset = 0;
            else
                kf.timeOffset = app.KfTimeEditField.Value;
                if(not(isempty(evtInd)) && evtInd >= 1 && evtInd <= app.LvdData.script.getTotalNumOfEvents())
                    kf.event = app.LvdData.script.getEventForInd(evtInd);
                else
                    kf.event = LaunchVehicleEvent.empty(1,0);
                end
                %keep the fallback sensible if the event is ever deleted
                kf.absTime = kf.resolveTime(app.LvdData.stateLog) - kf.timeOffset;
            end
            kf.holdDuration = app.KfHoldEditField.Value;
            kf.refType = LvdCameraKeyframeRefEnum.getEnumForListboxStr(app.KfRefDropDown.Value);
            kf.easing = LvdCameraEasingEnum.getEnumForListboxStr(app.KfEasingDropDown.Value);
            kf.viewAngleDeg = app.KfViewAngleEditField.Value;
            kf.camPosition = [app.KfPosXEditField.Value, app.KfPosYEditField.Value, app.KfPosZEditField.Value];
            kf.camTarget = [app.KfTgtXEditField.Value, app.KfTgtYEditField.Value, app.KfTgtZEditField.Value];
            up = [app.KfUpXEditField.Value, app.KfUpYEditField.Value, app.KfUpZEditField.Value];
            if(norm(up) > 0)
                kf.camUpVector = up / norm(up);
            end
            kf.azDeg = app.KfAzEditField.Value;
            kf.elDeg = app.KfElEditField.Value;
            kf.rangeKm = app.KfRangeEditField.Value;

            %fixed-anchor tracking settings (read only for a fixed-anchor
            %keyframe, so switching a keyframe's reference away and re-applying
            %never clobbers a stored anchor).  The keyframe's viewAngleDeg above
            %is the FOV; the anchor's own viewAngleDeg stays unused.
            if(kf.refType == LvdCameraKeyframeRefEnum.FixedAnchorTracking)
                fa = kf.anchor;
                fa.anchorType = LvdCameraAnchorTypeEnum.getEnumForListboxStr(app.KfAnchorTypeDropDown.Value);
                fa.fixedPosition = [app.KfAnchorXEditField.Value, app.KfAnchorYEditField.Value, app.KfAnchorZEditField.Value];
                try
                    fa.anchorFrame = app.KfAnchorFrameSelector.getSelectedFrame();
                catch
                end
                [~, goObjs] = app.LvdData.groundObjs.getListboxStr();
                go = app.resolveFromArray(app.KfAnchorGroundObjectDropDown.Value, goObjs);
                if(isempty(go))
                    fa.groundObject = LaunchVehicleGroundObject.empty(1,0);   %typed empty (property is class-typed)
                else
                    fa.groundObject = go;
                end
                [~, gpPts] = app.filteredGeomPoints();
                pt = app.resolveFromArray(app.KfAnchorGeometricPointDropDown.Value, gpPts);
                if(isempty(pt))
                    fa.geometricPoint = AbstractGeometricPoint.empty(1,0);    %typed empty (property is class-typed)
                else
                    fa.geometricPoint = pt;
                end
            end

            app.refreshKeyframeTable();
            app.selectKeyframe(app.SelectedKfInd);
            app.renderCurrent();
        end

        function updateSelectedKeyframeFromCamera(app)
            %updateSelectedKeyframeFromCamera "Update Selected From Camera":
            %the selected keyframe's pose becomes the main window's current
            %camera (its reference type and time are kept); a detached camera
            %re-attaches to the script.
            kf = app.getSelectedKeyframe();
            if(isempty(kf))
                return;
            end
            hAx = app.MainApp.dispAxes;
            switch(kf.refType)
                case LvdCameraKeyframeRefEnum.SceneFixed
                    app.pushUndo('Update Camera Keyframe');
                    kf.camPosition = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraPosition,1,3), hAx);
                    kf.camTarget = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraTarget,1,3), hAx);
                    kf.camUpVector = reshape(hAx.CameraUpVector,1,3);
                case LvdCameraKeyframeRefEnum.VehicleRelative
                    vehPos = app.vehiclePositionNow();
                    if(any(isnan(vehPos)))
                        app.StatusLabel.Text = 'The vehicle position is unknown at this time; move the slider onto the trajectory first.';
                        return;
                    end
                    app.pushUndo('Update Camera Keyframe');
                    camPosKm = LvdSceneNormalizer.unscalePos(reshape(hAx.CameraPosition,1,3), hAx);
                    [kf.azDeg, kf.elDeg, r] = LvdCameraMath.cartesianToSpherical(camPosKm - vehPos');
                    kf.rangeKm = max(r, 1e-6);
                case LvdCameraKeyframeRefEnum.FixedAnchorTracking
                    %park the anchor at the current camera as fixed coordinates,
                    %mirroring the profile-level "set from current camera"
                    app.pushUndo('Update Camera Keyframe');
                    try
                        kf.anchor.anchorFrame = app.KfAnchorFrameSelector.getSelectedFrame();
                    catch
                    end
                    kf.anchor.setFixedPositionFromCamera(hAx, app.currentTimeOrStart(), app.getProfile().frame);
            end
            kf.viewAngleDeg = hAx.CameraViewAngle;
            app.populateKeyframeEditor();
            app.refreshKeyframeTable();
            app.resumeScript(false);
            app.renderCurrent();
            app.StatusLabel.Text = sprintf('"%s" now uses the current camera.', kf.name);
        end

        function captureCameraIntoSelectedKeyframe(app)
            %captureCameraIntoSelectedKeyframe Older name of updateSelectedKeyframeFromCamera.
            app.updateSelectedKeyframeFromCamera();
        end

        function setKeyframeAnchorFromCamera(app)
            %setKeyframeAnchorFromCamera The keyframe anchor editor's "Set From
            %Current Camera": stages the main window's current camera position
            %(expressed in the chosen anchor frame) into the editor's fixed-XYZ
            %fields and switches the anchor type to Fixed Coordinates.  The user
            %presses Apply to commit, so this does not touch the keyframe or the
            %undo stack.
            kf = app.getSelectedKeyframe();
            if(isempty(kf))
                return;
            end
            tmp = LvdFixedAnchorCameraSettings();
            try
                tmp.anchorFrame = app.KfAnchorFrameSelector.getSelectedFrame();
            catch
            end
            tmp.setFixedPositionFromCamera(app.MainApp.dispAxes, app.currentTimeOrStart(), app.getProfile().frame);
            app.Populating = true;
            app.KfAnchorTypeDropDown.Value = LvdCameraAnchorTypeEnum.FixedXYZ.name;
            app.KfAnchorXEditField.Value = tmp.fixedPosition(1);
            app.KfAnchorYEditField.Value = tmp.fixedPosition(2);
            app.KfAnchorZEditField.Value = tmp.fixedPosition(3);
            app.Populating = false;
            app.updateKeyframeRefFieldStates();
        end

        function goToKeyframe(app, ind)
            %goToKeyframe Moves the time slider to keyframe `ind` and shows
            %its camera (the script drives it there in Camera Script mode; in
            %other modes the pose is previewed).  The keyframe is selected, so
            %"nudge the view, Update Selected From Camera" edits it.
            if(nargin < 2)
                ind = app.SelectedKfInd;
            end
            profile = app.getProfile();
            if(ind < 1 || ind > profile.cameraScript.getNumKeyframes())
                return;
            end
            kf = profile.cameraScript.keyframes(ind);
            t = kf.resolveTime(app.LvdData.stateLog);
            app.selectKeyframe(ind);

            if(app.hasStateLog())
                app.Controller.pause();
                app.resumeScript(false);       %so the script places the camera on the keyframe
                app.Controller.stepTo(t);
            end

            if(profile.cameraMode ~= LvdCameraModeEnum.Scripted)
                pose = kf.getPoseAtVehiclePosition(app.vehiclePositionAt(t), t, profile.frame);
                if(isempty(pose))
                    app.StatusLabel.Text = 'The keyframe cannot be shown: the vehicle position is unknown at its time.';
                    return;
                end
                profile.getCameraDriver().applyPosePreview(pose, app.MainApp.dispAxes);
                drawnow;
            end
            app.StatusLabel.Text = sprintf('At "%s" (UT %.3f s).  Adjust the view and press Update Selected From Camera to change it.', kf.name, t);
        end

        function previewKeyframe(app, ind)
            %previewKeyframe Older name of goToKeyframe.
            if(nargin < 2)
                app.goToKeyframe();
            else
                app.goToKeyframe(ind);
            end
        end

        function resumeScript(app, announce)
            %resumeScript "Resume Script": the script drives the camera again.
            arguments
                app
                announce(1,1) logical = true
            end
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            driver = profile.getCameraDriver();
            if(not(driver.isScriptDetached()))
                return;
            end
            driver.resumeScript();
            if(announce)
                app.renderCurrent();
                app.StatusLabel.Text = 'The camera script is driving the camera again.';
            end
        end

        function tf = isScriptDetached(app)
            %isScriptDetached True while the camera is off the script for
            %authoring (test seam).
            tf = false;
            profile = app.getProfile();
            if(not(isempty(profile)))
                tf = profile.getCameraDriver().isScriptDetached();
            end
        end

        function showAdvancedPose(app, tf)
            %showAdvancedPose Shows/hides the numeric pose fields of the
            %keyframe editor.
            tf = logical(tf);
            app.Populating = true;
            app.AdvancedPoseCheckBox.Value = tf;
            app.Populating = false;
            app.updateKeyframeEditorLayout();
        end

        function updateKeyframeEditorLayout(app)
            %updateKeyframeEditorLayout Owns the variable-height rows of the
            %selected-keyframe editor: the numeric-pose checkbox/grid (scene &
            %vehicle refs) versus the fixed-anchor tracking editor (fixed-anchor
            %ref).  It also sets the editor panel height and, through
            %updateCameraModePanels, the Camera-tab script row.  Driven by the
            %editor's own widgets so it reflects a live ref/anchor change before
            %the user presses Apply.
            refType = LvdCameraKeyframeRefEnum.getEnumForListboxStr(app.KfRefDropDown.Value);
            isFixedAnchor = not(isempty(refType)) && refType == LvdCameraKeyframeRefEnum.FixedAnchorTracking;
            advanced = app.AdvancedPoseCheckBox.Value && not(isFixedAnchor);

            %the numeric-pose checkbox + grid only apply to scene/vehicle kfs
            app.AdvancedPoseCheckBox.Visible = app.onOff(not(isFixedAnchor));
            app.AdvancedPoseGrid.Visible = app.onOff(advanced);
            app.KfAnchorEditorGrid.Visible = app.onOff(isFixedAnchor);

            g = app.KeyframeEditorGrid;
            g.RowHeight{4} = 22 * not(isFixedAnchor);   %AdvancedPoseCheckBox row
            g.RowHeight{5} = 54 * advanced;             %numeric pose grid
            if(isFixedAnchor)
                anchorType = LvdCameraAnchorTypeEnum.getEnumForListboxStr(app.KfAnchorTypeDropDown.Value);
                if(anchorType == LvdCameraAnchorTypeEnum.FixedXYZ)
                    g.RowHeight{6} = 92;                %XYZ + frame line
                else
                    g.RowHeight{6} = 62;               %single object dropdown
                end
            else
                g.RowHeight{6} = 0;
            end

            app.ScriptGrid.RowHeight{5} = app.currentKeyframeEditorHeight();
            app.updateCameraModePanels();
        end

        function h = currentKeyframeEditorHeight(app)
            %currentKeyframeEditorHeight The height the selected-keyframe editor
            %panel needs for its current ref/anchor type, from the editor
            %widgets (fixed-anchor kfs replace the numeric-pose grid with the
            %anchor editor).
            refType = LvdCameraKeyframeRefEnum.getEnumForListboxStr(app.KfRefDropDown.Value);
            if(not(isempty(refType)) && refType == LvdCameraKeyframeRefEnum.FixedAnchorTracking)
                anchorType = LvdCameraAnchorTypeEnum.getEnumForListboxStr(app.KfAnchorTypeDropDown.Value);
                if(anchorType == LvdCameraAnchorTypeEnum.FixedXYZ)
                    h = app.EditorHeightFixedAnchorXYZ;
                else
                    h = app.EditorHeightFixedAnchorObject;
                end
            elseif(app.AdvancedPoseCheckBox.Value)
                h = app.EditorHeightExpanded;
            else
                h = app.EditorHeightCollapsed;
            end
        end

        function data = getKeyframeTableData(app)
            data = app.KeyframeTable.Data;
        end

        %% --------------------------------------------------------- mesh
        function importMeshFromFile(app, filePath)
            %importMeshFromFile Loads the mesh and scales it so its longest
            %side is the "Fit longest side to" length (a display size: the
            %scene spans thousands of km, so a true-scale vehicle cannot be
            %rendered; see LvdVehicleMeshSettings.defaultDisplayLengthKm).
            arguments
                app
                filePath(1,:) char
            end
            mesh = app.getProfile().vehicleMesh;
            [~, name, ext] = fileparts(filePath);

            dlg = app.showProgress('Importing Mesh', sprintf('Reading %s%s...', name, ext));
            cleanup = onCleanup(@() closeIfValid(dlg)); %#ok<NASGU>

            app.pushUndo('Import Vehicle Mesh');
            info = mesh.loadFromFile(filePath);

            fitLength = app.FitLengthEditField.Value;
            if(isfinite(fitLength) && fitLength > 0)
                mesh.fitLongestDimensionTo(fitLength);
            end

            app.setProgressMessage(dlg, sprintf('Drawing %u faces...', info.numFaces));
            app.populateMeshTab();
            app.afterMeshChanged();
            app.StatusLabel.Text = sprintf('Imported %u faces from %s into view profile "%s"; shown with a longest side of %.4g km (change with Scale or Fit).', ...
                                           info.numFaces, filePath, app.getProfileName(), fitLength);
        end

        function dlg = showProgress(app, title, message)
            %showProgress An indeterminate progress dialog on this window (or
            %[] when the window is hidden, e.g. under test).  Every call is
            %recorded in ProgressDialogLog so tests can see it happened.
            app.ProgressDialogLog{end+1} = title;
            dlg = [];
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)) || not(strcmp(app.UIFigure.Visible, 'on')))
                return;
            end
            try
                dlg = uiprogressdlg(app.UIFigure, 'Title', title, 'Message', message, 'Indeterminate', 'on');
                drawnow;
            catch
                dlg = [];
            end
        end

        function setProgressMessage(~, dlg, message)
            if(not(isempty(dlg)) && isvalid(dlg))
                dlg.Message = message;
                drawnow;
            end
        end

        function showMeshInChaseCamera(app)
            %showMeshInChaseCamera Switches to the Chase camera at a range
            %that frames the mesh, so an imported model can be found at once.
            mesh = app.getProfile().vehicleMesh;
            [mn, mx] = mesh.getBodyFrameBounds();
            longest = max(mx - mn);
            if(not(mesh.hasMesh()) || longest <= 0)
                app.StatusLabel.Text = 'Import a mesh first.';
                return;
            end
            app.pushUndo('Show Vehicle Mesh in Chase Camera');
            chase = app.getProfile().chaseCamera;
            chase.rangeKm = 4 * longest;
            if(isnan(chase.viewAngleDeg))
                chase.viewAngleDeg = 10;
            end
            app.populateCameraTab();
            app.getProfile().cameraMode = LvdCameraModeEnum.Chase;
            app.Populating = true;
            app.CameraModeDropDown.Value = LvdCameraModeEnum.Chase.name;
            app.Populating = false;
            app.updateEnableStates();
            app.renderCurrent();
            app.StatusLabel.Text = sprintf('Chase camera %.4g km from the vehicle; the Camera tab has the offsets.', chase.rangeKm);
        end

        function reloadMesh(app)
            mesh = app.getProfile().vehicleMesh;
            dlg = app.showProgress('Reloading Mesh', sprintf('Reading %s...', mesh.sourcePath));
            cleanup = onCleanup(@() closeIfValid(dlg)); %#ok<NASGU>
            app.pushUndo('Reload Vehicle Mesh');
            info = mesh.reloadFromFile();
            app.populateMeshTab();
            app.afterMeshChanged();
            app.StatusLabel.Text = sprintf('Reloaded %u faces from %s', info.numFaces, mesh.sourcePath);
        end

        function clearMesh(app)
            app.pushUndo('Clear Vehicle Mesh');
            app.getProfile().vehicleMesh.clearMesh();
            app.populateMeshTab();
            app.afterMeshChanged();
        end

        function setMeshTransform(app, scale, eulerDeg, transKm)
            mesh = app.getProfile().vehicleMesh;
            new = struct('scale', scale, 'rotOffsetEulerDeg', reshape(eulerDeg,1,3), 'transOffsetKm', reshape(transKm,1,3));
            app.applyStructIfChanged(mesh, new, 'Edit Vehicle Mesh Transform');
            app.populateMeshTab();
            app.afterMeshChanged();
        end

        function setMeshAppearance(app, faceColor, faceAlpha, showEdges, edgeColor, useLighting)
            mesh = app.getProfile().vehicleMesh;
            new = struct('faceColor', reshape(faceColor,1,3), 'faceAlpha', faceAlpha, 'showEdges', logical(showEdges), ...
                         'edgeColor', reshape(edgeColor,1,3), 'useLighting', logical(useLighting));
            app.applyStructIfChanged(mesh, new, 'Edit Vehicle Mesh Appearance');
            app.populateMeshTab();
            app.afterMeshChanged();
        end

        function fitMeshToLength(app, lengthKm)
            mesh = app.getProfile().vehicleMesh;
            app.pushUndo('Fit Vehicle Mesh Size');
            mesh.fitLongestDimensionTo(lengthKm);
            app.populateMeshTab();
            app.afterMeshChanged();
        end

        function applyMeshFields(app)
            %applyMeshFields Writes the mesh tab controls to the profile.
            mesh = app.getProfile().vehicleMesh;
            new = struct('enabled', logical(app.MeshEnabledCheckBox.Value), ...
                         'scale', app.MeshScaleEditField.Value, ...
                         'rotOffsetEulerDeg', [app.MeshYawEditField.Value, app.MeshPitchEditField.Value, app.MeshRollEditField.Value], ...
                         'transOffsetKm', [app.MeshTransXEditField.Value, app.MeshTransYEditField.Value, app.MeshTransZEditField.Value], ...
                         'faceAlpha', app.MeshAlphaSpinner.Value, ...
                         'showEdges', logical(app.MeshShowEdgesCheckBox.Value), ...
                         'useLighting', logical(app.MeshLightingCheckBox.Value));
            app.applyStructIfChanged(mesh, new, 'Edit Vehicle Mesh');
            app.afterMeshChanged();
        end

        %% ------------------------------------------------------ overlay
        function setOverlayEnabled(app, tf)
            ov = app.getProfile().overlay;
            if(ov.enabled ~= logical(tf))
                app.pushUndo('Toggle Data Overlay');
            end
            ov.enabled = logical(tf);
            app.populateOverlayTab();
            app.afterOverlayChanged(false);
        end

        function applyOverlayFields(app)
            %applyOverlayFields Writes the overlay content/style controls to
            %the profile (one undo state when anything actually changed).
            ov = app.getProfile().overlay;
            new = struct('enabled', logical(app.OverlayEnabledCheckBox.Value), ...
                         'title', strtrim(app.OverlayTitleEditField.Value), ...
                         'showEpoch', logical(app.OverlayShowEpochCheckBox.Value), ...
                         'showUT', logical(app.OverlayShowUtCheckBox.Value), ...
                         'showMet', logical(app.OverlayShowMetCheckBox.Value), ...
                         'showEventName', logical(app.OverlayShowEventCheckBox.Value), ...
                         'corner', string(app.OverlayCornerDropDown.Value), ...
                         'marginFrac', app.OverlayMarginSpinner.Value / 100, ...
                         'fontName', app.OverlayFontNameDropDown.Value, ...
                         'fontSize', app.OverlayFontSizeSpinner.Value, ...
                         'showBackground', logical(app.OverlayBackgroundCheckBox.Value));
            if(app.OverlayBoldCheckBox.Value)
                new.fontWeight = "bold";
            else
                new.fontWeight = "normal";
            end
            app.applyStructIfChanged(ov, new, 'Edit Data Overlay');
            app.afterOverlayChanged(false);
        end

        function setOverlayColors(app, fontColor, backgroundColor)
            ov = app.getProfile().overlay;
            new = struct();
            if(not(isempty(fontColor)))
                new.fontColor = reshape(fontColor,1,3);
            end
            if(not(isempty(backgroundColor)))
                new.backgroundColor = reshape(backgroundColor,1,3);
            end
            app.applyStructIfChanged(ov, new, 'Edit Data Overlay');
            app.populateOverlayTab();
            app.afterOverlayChanged(false);
        end

        function filterOverlayTasks(app, searchStr)
            %filterOverlayTasks Shows the quantities whose name contains
            %searchStr (case-insensitive); empty shows all.
            full = app.allOverlayTasks();
            searchStr = strtrim(char(searchStr));
            if(isempty(searchStr))
                shown = full;
            else
                hits = contains(lower(full), lower(searchStr));
                shown = full(hits);
            end
            app.Populating = true;
            app.OverlayTaskListBox.Items = shown;
            if(not(isempty(shown)))
                app.OverlayTaskListBox.Value = shown{1};
            end
            app.Populating = false;
            app.updateEnableStates();
        end

        function item = addOverlayQuantity(app, taskStr, frame)
            %addOverlayQuantity Adds a Graphical Analysis quantity to the
            %overlay in the given frame (default: the frame chosen in the
            %frame selector).
            arguments
                app
                taskStr(1,:) char
                frame = []
            end
            if(isempty(frame))
                frame = app.selectedOverlayFrame();
            end
            if(not(ismember(taskStr, app.allOverlayTasks())))
                error('lvd_ViewPlaybackGUI_App:unknownQuantity', 'Unknown Graphical Analysis quantity "%s".', taskStr);
            end
            app.pushUndo('Add Data Overlay Quantity');
            ov = app.getProfile().overlay;
            item = ov.addQuantity(taskStr, frame);
            if(not(ov.enabled))
                ov.enabled = true;   %adding a quantity is a clear request to see it
            end
            app.populateOverlayTab();
            app.selectOverlayItem(ov.getNumItems());
            app.afterOverlayChanged(true);
            app.StatusLabel.Text = sprintf('Added "%s" to the data overlay of view profile "%s".', taskStr, app.getProfileName());
        end

        function addSelectedOverlayQuantity(app)
            sel = app.OverlayTaskListBox.Value;
            if(isempty(sel))
                app.StatusLabel.Text = 'Select a quantity in the list first.';
                return;
            end
            if(iscell(sel))
                sel = sel{1};
            end
            app.addOverlayQuantity(sel);
        end

        function removeOverlayItem(app, ind)
            ov = app.getProfile().overlay;
            if(nargin < 2)
                ind = app.SelectedOverlayInd;
            end
            if(ind < 1 || ind > ov.getNumItems())
                return;
            end
            app.pushUndo('Remove Data Overlay Quantity');
            ov.removeItem(ind);
            app.populateOverlayTab();
            app.selectOverlayItem(min(ind, ov.getNumItems()));
            app.afterOverlayChanged(true);
        end

        function moveOverlayItem(app, ind, direction)
            ov = app.getProfile().overlay;
            n = ov.getNumItems();
            if(ind < 1 || ind > n || (direction < 0 && ind == 1) || (direction > 0 && ind == n))
                return;
            end
            app.pushUndo('Reorder Data Overlay Quantities');
            if(direction < 0)
                ov.moveItemUp(ind);
                newInd = ind - 1;
            else
                ov.moveItemDown(ind);
                newInd = ind + 1;
            end
            app.populateOverlayTab();
            app.selectOverlayItem(newInd);
            app.afterOverlayChanged(true);
        end

        function selectOverlayItem(app, ind)
            ov = app.getProfile().overlay;
            n = ov.getNumItems();
            if(n == 0 || ind < 1 || ind > n)
                app.SelectedOverlayInd = 0;
            else
                app.SelectedOverlayInd = ind;
            end
            app.Populating = true;
            try
                if(app.SelectedOverlayInd > 0)
                    app.OverlayTable.Selection = app.SelectedOverlayInd;
                else
                    app.OverlayTable.Selection = [];
                end
            catch
            end
            app.Populating = false;
            app.updateEnableStates();
        end

        function setOverlayItemFormat(app, ind, decimals, format, showUnits, label)
            %setOverlayItemFormat Formatting of one quantity; pass [] to
            %leave a field alone.
            arguments
                app
                ind(1,1) double
                decimals = []
                format = []
                showUnits = []
                label = []
            end
            ov = app.getProfile().overlay;
            if(ind < 1 || ind > ov.getNumItems())
                return;
            end
            item = ov.items(ind);
            new = struct();
            if(not(isempty(decimals))); new.decimals = round(decimals); end
            if(not(isempty(format)));   new.format = string(format); end
            if(not(isempty(showUnits))); new.showUnits = logical(showUnits); end
            if(not(isempty(label)) || ischar(label)); new.label = char(label); end
            app.applyStructIfChanged(item, new, 'Edit Data Overlay Quantity');
            app.populateOverlayTab();
            app.selectOverlayItem(ind);
            app.afterOverlayChanged(false);
        end

        function applyOverlayTableEdit(app, row, col, newData)
            %applyOverlayTableEdit Shared body of the table CellEditCallback.
            ov = app.getProfile().overlay;
            if(row < 1 || row > ov.getNumItems())
                return;
            end
            switch(col)
                case 3 %Label
                    app.setOverlayItemFormat(row, [], [], [], char(string(newData)));
                case 4 %Decimals
                    d = double(newData);
                    if(not(isfinite(d)) || d < 0 || d > 15)
                        app.populateOverlayTab();
                        return;
                    end
                    app.setOverlayItemFormat(row, d, [], [], []);
                case 5 %Format
                    app.setOverlayItemFormat(row, [], newData, [], []);
                case 6 %Units
                    app.setOverlayItemFormat(row, [], [], logical(newData), []);
            end
        end

        function data = getOverlayTableData(app)
            data = app.OverlayTable.Data;
        end

        function lines = getOverlayLines(app)
            %getOverlayLines The text the overlay shows at the current time.
            lines = {};
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            t = app.currentTimeOrStart();
            if(not(isempty(profile.markerOverlayData)))
                lines = profile.markerOverlayData(1).buildLines(t);
            else
                tmp = LaunchVehicleViewProfileOverlayData(profile.overlay, app.LvdData);
                lines = tmp.buildLines(t);
            end
        end
    end

    methods (Access = private)
        %% ------------------------------------------------------ startup
        function startupFcn(app, lvdData, mainApp, showFigure)
            arguments
                app
                lvdData(1,1) LvdData
                mainApp(1,1) ma_LvdMainGUI_App
                showFigure(1,1) logical = true
            end

            app.MainApp = mainApp;
            setappdata(app.UIFigure, 'LvdViewPlaybackApp', app);

            app.populateStaticItems();
            app.bindToLvdData(lvdData);

            %default display size for an imported mesh: 2% of the central body
            try
                bodyRadius = lvdData.initStateModel.centralBody.radius;
            catch
                bodyRadius = NaN;
            end
            app.FitLengthEditField.Value = LvdVehicleMeshSettings.defaultDisplayLengthKm(bodyRadius);

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            app.updateMeshPreview();

            if(showFigure)
                app.UIFigure.Visible = 'on';
            end
        end

        function bindToLvdData(app, lvdData)
            %bindToLvdData Points the window at a mission object (initially,
            %and again after undo/redo swapped it), rebuilding listeners and
            %the playback controller.
            app.deleteListeners();
            if(not(isempty(app.Controller)) && isvalid(app.Controller))
                try
                    app.Controller.stop(false);
                catch
                end
                delete(app.Controller);
            end
            app.Controller = [];

            app.LvdData = lvdData;
            app.Listeners = {};

            handles = guidata(app.MainApp.ma_LvdMainGUI);
            app.Controller = LvdViewPlaybackController.fromMainApp(lvdData, handles, app.MainApp);
            app.Listeners{end+1} = addlistener(app.Controller, 'StateChanged', @(~,~) app.onPlaybackStateChanged());
            app.Listeners{end+1} = addlistener(app.Controller, 'FrameRendered', @(~,~) app.updateTimeLabel());
            app.Listeners{end+1} = addlistener(lvdData.script, 'ScriptPropagationFinished', @(~,~) app.refresh());
            app.Listeners{end+1} = addlistener(lvdData.viewSettings, 'ActiveProfileChanged', @(~,~) app.onActiveProfileChanged());
            app.Listeners{end+1} = addlistener(app.MainApp.ma_LvdMainGUI, 'ObjectBeingDestroyed', @(~,~) delete(app));

            try
                app.OverlayFrameSelector.initializeWithFrames(lvdData);
                app.OverlayFrameSelector.setSelectedFrame(lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame());
            catch
            end
            try
                app.AnchorFrameSelector.initializeWithFrames(lvdData);
                app.AnchorFrameSelector.setSelectedFrame(lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame());
            catch
            end
            app.filterOverlayTasks(app.OverlaySearchEditField.Value);

            app.refresh();
        end

        function deleteListeners(app)
            for(i=1:numel(app.Listeners))
                if(isvalid(app.Listeners{i}))
                    delete(app.Listeners{i});
                end
            end
            app.Listeners = {};
            if(not(isempty(app.DriverListener)) && isvalid(app.DriverListener))
                delete(app.DriverListener);
            end
            app.DriverListener = [];
        end

        function listenToCameraDriver(app)
            %listenToCameraDriver Mirrors mouse-driven camera changes (chase
            %offsets retuned, camera detached from / re-attached to the
            %script) on the Camera tab.
            if(not(isempty(app.DriverListener)) && isvalid(app.DriverListener))
                delete(app.DriverListener);
            end
            app.DriverListener = [];
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            app.DriverListener = addlistener(profile.getCameraDriver(), 'CameraChangedByUser', @(~,~) app.onCameraChangedByUser());
        end

        function onCameraChangedByUser(app)
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end
            app.populateCameraTab();
            app.updateEnableStates();
        end

        function onActiveProfileChanged(app)
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end
            app.refresh();
            app.updateMeshPreview();
            app.StatusLabel.Text = sprintf('Now showing the settings of view profile "%s".', app.getProfileName());
        end

        function populateStaticItems(app)
            app.VideoFormatDropDown.Items = cellstr(LvdViewPlaybackSettings.getVideoFormats());
            app.CameraModeDropDown.Items = LvdCameraModeEnum.getListBoxStr();
            app.KfAnchorDropDown.Items = LvdCameraKeyframeAnchorEnum.getListBoxStr();
            app.KfRefDropDown.Items = LvdCameraKeyframeRefEnum.getListBoxStr();
            app.KfEasingDropDown.Items = LvdCameraEasingEnum.getListBoxStr();
            app.NewKeyframeRefDropDown.Items = LvdCameraKeyframeRefEnum.getListBoxStr();
            app.NewKeyframeRefDropDown.Value = LvdCameraKeyframeRefEnum.VehicleRelative.name;
            app.NewKeyframeAnchorDropDown.Items = {'start of the active event + offset', 'absolute time (UT)'};
            app.NewKeyframeAnchorDropDown.Value = app.NewKeyframeAnchorDropDown.Items{1};
            app.OverlayCornerDropDown.Items = cellstr(LvdViewOverlaySettings.getCorners());
            app.OverlayFontNameDropDown.Items = LvdViewOverlaySettings.getFontNames();
        end

        %% ---------------------------------------------------------- undo
        function pushUndo(app, label)
            %pushUndo Records an LVD undo state (Edit > Undo) BEFORE an edit,
            %with the LVD convention's descriptive label.
            app.UndoLog{end+1} = label;
            try
                if(not(isempty(app.MainApp)) && isvalid(app.MainApp))
                    app.MainApp.lvdEnhancementsAddUndo(label);
                end
            catch
            end
        end

        function changed = applyStructIfChanged(app, target, new, undoLabel)
            %applyStructIfChanged Assigns the fields of `new` onto handle
            %object `target`, pushing one undo state first if any differs.
            fields = fieldnames(new);
            changed = false;
            for(i=1:numel(fields))
                if(not(isequaln(target.(fields{i}), new.(fields{i}))))   %isequaln: NaN == NaN (optional times)
                    changed = true;
                    break;
                end
            end
            if(not(changed))
                return;
            end
            app.pushUndo(undoLabel);
            for(i=1:numel(fields))
                target.(fields{i}) = new.(fields{i});
            end
        end

        %% --------------------------------------------------- populators
        function updateProfileHeader(app)
            name = app.getProfileName();
            if(isempty(name))
                name = '<none>';
            end
            app.UIFigure.Name = sprintf('%s  |  View Profile: %s', app.WindowName, name);
            app.ProfileHeaderLabel.Text = sprintf(['Everything in this window belongs to the ACTIVE VIEW PROFILE "%s" and is saved with it in the mission file.  ' ...
                                                   'Other view profiles keep their own playback, camera, mesh and overlay settings.  ' ...
                                                   'Switch profiles with View > Set Active View Profile... in the main window.'], name);
        end

        function populatePlaybackTab(app)
            settings = app.getProfile().playbackSettings;
            app.Populating = true;
            app.SpeedEditField.Value = settings.simSecPerRealSec;
            app.FpsEditField.Value = settings.fps;
            app.LoopCheckBox.Value = settings.loop;
            app.VideoFormatDropDown.Value = char(settings.videoFormat);
            app.QualityEditField.Value = settings.videoQuality;
            app.ImageDpiEditField.Value = settings.imageDpi;
            app.ExportStartEditField.Value = app.formatOptionalTime(settings.exportStartTime);
            app.ExportEndEditField.Value = app.formatOptionalTime(settings.exportEndTime);
            app.Populating = false;
        end

        function populateCameraTab(app)
            profile = app.getProfile();
            app.Populating = true;
            app.CameraModeDropDown.Value = profile.cameraMode.name;
            app.ChaseAzEditField.Value = profile.chaseCamera.azDeg;
            app.ChaseElEditField.Value = profile.chaseCamera.elDeg;
            app.ChaseRangeEditField.Value = profile.chaseCamera.rangeKm;
            app.ChaseViewAngleEditField.Value = profile.chaseCamera.viewAngleDeg;
            app.populateFixedAnchorControls(profile.fixedAnchorCamera);
            app.Populating = false;

            app.populateEventItems();
            app.refreshKeyframeTable();
            app.applyNewKeyframeDefaults();
            n = profile.cameraScript.getNumKeyframes();
            if(app.SelectedKfInd < 1 || app.SelectedKfInd > n)
                app.selectKeyframe(min(1, n));
            else
                app.selectKeyframe(app.SelectedKfInd);
            end
        end

        function populateFixedAnchorControls(app, fa)
            %populateFixedAnchorControls Mirrors the FixedAnchor settings onto
            %the panel.  Called from populateCameraTab inside a Populating
            %block, so it must not toggle Populating itself.
            app.AnchorTypeDropDown.Value = fa.anchorType.name;
            app.AnchorXEditField.Value = fa.fixedPosition(1);
            app.AnchorYEditField.Value = fa.fixedPosition(2);
            app.AnchorZEditField.Value = fa.fixedPosition(3);
            app.AnchorViewAngleEditField.Value = app.formatOptionalTime(fa.viewAngleDeg);
            if(not(isempty(fa.anchorFrame)) && all(isvalid(fa.anchorFrame)))
                try
                    app.AnchorFrameSelector.setSelectedFrame(fa.anchorFrame);
                catch
                end
            end

            %ground object dropdown
            [goNames, goObjs] = app.LvdData.groundObjs.getListboxStr();
            if(isempty(goNames))
                app.AnchorGroundObjectDropDown.Items = {'(none)'};
                app.AnchorGroundObjectDropDown.ItemsData = {[]};
            else
                app.AnchorGroundObjectDropDown.Items = goNames;
                app.AnchorGroundObjectDropDown.ItemsData = num2cell(1:numel(goObjs));
                if(not(isempty(fa.groundObject)) && all(isvalid(fa.groundObject)))
                    idx = find(goObjs == fa.groundObject, 1);
                    if(not(isempty(idx)))
                        app.AnchorGroundObjectDropDown.Value = idx;
                    end
                end
            end

            %geometric point dropdown (vehicle-independent points only)
            [gpNames, gpPts] = app.filteredGeomPoints();
            if(isempty(gpNames))
                app.AnchorGeometricPointDropDown.Items = {'(none)'};
                app.AnchorGeometricPointDropDown.ItemsData = {[]};
            else
                app.AnchorGeometricPointDropDown.Items = gpNames;
                app.AnchorGeometricPointDropDown.ItemsData = num2cell(1:numel(gpPts));
                if(not(isempty(fa.geometricPoint)) && all(isvalid(fa.geometricPoint)))
                    idx = find(gpPts == fa.geometricPoint, 1);
                    if(not(isempty(idx)))
                        app.AnchorGeometricPointDropDown.Value = idx;
                    end
                end
            end

            app.updateAnchorTypeVisibility(fa.anchorType);
        end

        function updateAnchorTypeVisibility(app, anchorType)
            %updateAnchorTypeVisibility Shows only the anchor-specific sub-grid
            %for the current anchor type (the whole sub-grid collapses when
            %hidden, so no empty rows are reserved) and sizes the Fixed Camera
            %panel to fit it.
            isXYZ = anchorType == LvdCameraAnchorTypeEnum.FixedXYZ;
            app.FixedXYZSubGrid.Visible = app.onOff(isXYZ);
            app.GroundObjSubGrid.Visible = app.onOff(anchorType == LvdCameraAnchorTypeEnum.GroundObject);
            app.GeomPtSubGrid.Visible = app.onOff(anchorType == LvdCameraAnchorTypeEnum.GeometricPoint);

            %resize the panel row to the visible anchor type, but only while
            %FixedAnchor is the active mode (otherwise the row stays collapsed)
            profile = app.getProfile();
            if(not(isempty(profile)) && profile.cameraMode == LvdCameraModeEnum.FixedAnchor)
                app.updateCameraModePanels();
            end
        end

        function populateEventItems(app)
            script = app.LvdData.script;
            n = script.getTotalNumOfEvents();
            items = cell(1, n);
            for(i=1:n)
                evt = script.getEventForInd(i);
                items{i} = sprintf('%u: %s', i, evt.name);
            end
            if(n == 0)
                items = {'<no events>'};
                itemsData = {[]};
            else
                itemsData = num2cell(1:n);
            end
            app.Populating = true;
            app.KfEventDropDown.Items = items;
            app.KfEventDropDown.ItemsData = itemsData;
            app.Populating = false;
        end

        function refreshKeyframeTable(app)
            %refreshKeyframeTable Rows in the order the script plays them
            %(sorted by resolved time; that is how LvdCameraScript.evaluate
            %orders them, whatever the order they were added in).
            profile = app.getProfile();
            kfs = profile.cameraScript.keyframes;
            stateLog = app.LvdData.stateLog;
            n = numel(kfs);
            times = zeros(1, n);
            resolvedFlags = true(1, n);
            for(i=1:n)
                [times(i), resolvedFlags(i)] = kfs(i).resolveTime(stateLog);
            end
            [~, order] = sort(times);    %stable
            app.KeyframeRowOrder = order;

            data = cell(n, 6);
            for(r=1:n)
                i = order(r);
                kf = kfs(i);
                if(resolvedFlags(i))
                    tStr = sprintf('%.3f', times(i));
                else
                    tStr = sprintf('%.3f (fallback)', times(i));
                end
                data(r,:) = {r, kf.name, kf.getAnchorStr(app.LvdData.script), kf.refType.name, kf.holdDuration, tStr};
            end
            app.Populating = true;
            app.KeyframeTable.Data = data;
            app.Populating = false;
            app.ActiveKfInd = -1;   %force the highlight to be redrawn
            app.updateActiveKeyframeHighlight();
        end

        function row = rowOfKeyframe(app, kfInd)
            %rowOfKeyframe Table row showing keyframe kfInd, 0 if none.
            row = find(app.KeyframeRowOrder == kfInd, 1);
            if(isempty(row))
                row = 0;
            end
        end

        function ind = activeKeyframeAt(app, t)
            %activeKeyframeAt The keyframe whose hold or transition covers
            %time t (the last keyframe at or before t; the first one before
            %the script starts); 0 for an empty script.
            ind = 0;
            profile = app.getProfile();
            if(isempty(profile) || profile.cameraScript.getNumKeyframes() == 0 || isnan(t))
                return;
            end
            stateLog = app.LvdData.stateLog;
            [tStart, ~, order] = profile.cameraScript.resolveSchedule(@(kf) kf.resolveTime(stateLog));
            k = find(tStart <= t, 1, 'last');
            if(isempty(k))
                k = 1;
            end
            ind = order(k);
        end

        function updateActiveKeyframeHighlight(app)
            %updateActiveKeyframeHighlight Bold row = the keyframe the script
            %is on (or easing away from) at the current time.
            if(isempty(app.KeyframeTable) || not(isvalid(app.KeyframeTable)))
                return;
            end
            ind = app.activeKeyframeAt(app.currentTimeOrStart());
            if(ind == app.ActiveKfInd)
                return;
            end
            app.ActiveKfInd = ind;
            try
                removeStyle(app.KeyframeTable);
                row = app.rowOfKeyframe(ind);
                if(row > 0)
                    addStyle(app.KeyframeTable, uistyle('FontWeight', 'bold'), 'row', row);
                end
            catch
            end
            app.updateScriptStateLabel();
        end

        function updateScriptStateLabel(app)
            %updateScriptStateLabel One line that always says who is driving
            %the camera and what to do next.
            if(isempty(app.ScriptStateLabel) || not(isvalid(app.ScriptStateLabel)))
                return;
            end
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            n = profile.cameraScript.getNumKeyframes();
            switch(profile.cameraMode)
                case LvdCameraModeEnum.Manual
                    str = 'Camera: MANUAL (mouse and toolbar).  Keyframes can still be added from the current view; switch to Camera Script to play them.';
                case LvdCameraModeEnum.Chase
                    str = 'Camera: CHASE.  Keyframes can still be added from the current view; switch to Camera Script to play them.';
                case LvdCameraModeEnum.FixedAnchor
                    str = sprintf('Camera: FIXED (TRACKING).  %s, looking at the vehicle.', profile.fixedAnchorCamera.getSummaryStr());
                otherwise
                    if(n == 0)
                        str = 'Camera: SCRIPT (empty).  Scrub to a time, aim the camera with the mouse, then press Add Keyframe Here.';
                    elseif(profile.getCameraDriver().isScriptDetached())
                        str = 'Camera DETACHED from the script: adjust the view, then Add Keyframe Here, Update Selected From Camera, or Resume Script.';
                    else
                        active = app.ActiveKfInd;
                        if(active >= 1 && active <= n)
                            kfName = profile.cameraScript.keyframes(active).name;
                            str = sprintf('Script is driving the camera (now on "%s").  Drag the view to detach and set up a keyframe.', kfName);
                        else
                            str = 'Script is driving the camera.  Drag the view to detach and set up a keyframe.';
                        end
                    end
            end
            app.ScriptStateLabel.Text = str;
        end

        function applyNewKeyframeDefaults(app)
            %applyNewKeyframeDefaults Mirrors the "New keyframes are" choice
            %onto the driver: a detached camera follows the vehicle for
            %vehicle-relative keyframes and stays put for scene-fixed ones.
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            follows = app.newKeyframeRefType() == LvdCameraKeyframeRefEnum.VehicleRelative;
            profile.getCameraDriver().setDetachedFollowMode(follows);
        end

        function populateKeyframeEditor(app)
            kf = app.getSelectedKeyframe();
            app.Populating = true;
            if(isempty(kf))
                app.KfNameEditField.Value = '';
            else
                app.KfNameEditField.Value = kf.name;
                app.KfAnchorDropDown.Value = kf.anchorType.name;
                if(kf.anchorType == LvdCameraKeyframeAnchorEnum.AbsoluteTime)
                    app.KfTimeEditField.Value = kf.absTime;
                else
                    app.KfTimeEditField.Value = kf.timeOffset;
                end
                evtInd = [];
                if(not(isempty(kf.event)) && isvalid(kf.event))
                    evtInd = app.LvdData.script.getNumOfEvent(kf.event);
                end
                if(isempty(evtInd) || not(any(cellfun(@(d) isequal(d, evtInd), app.KfEventDropDown.ItemsData))))
                    app.KfEventDropDown.Value = app.KfEventDropDown.ItemsData{1};
                else
                    app.KfEventDropDown.Value = evtInd;
                end
                app.KfHoldEditField.Value = kf.holdDuration;
                app.KfRefDropDown.Value = kf.refType.name;
                app.KfEasingDropDown.Value = kf.easing.name;
                app.KfViewAngleEditField.Value = kf.viewAngleDeg;
                app.KfPosXEditField.Value = kf.camPosition(1);
                app.KfPosYEditField.Value = kf.camPosition(2);
                app.KfPosZEditField.Value = kf.camPosition(3);
                app.KfTgtXEditField.Value = kf.camTarget(1);
                app.KfTgtYEditField.Value = kf.camTarget(2);
                app.KfTgtZEditField.Value = kf.camTarget(3);
                app.KfUpXEditField.Value = kf.camUpVector(1);
                app.KfUpYEditField.Value = kf.camUpVector(2);
                app.KfUpZEditField.Value = kf.camUpVector(3);
                app.KfAzEditField.Value = kf.azDeg;
                app.KfElEditField.Value = kf.elDeg;
                app.KfRangeEditField.Value = kf.rangeKm;
                app.populateKeyframeAnchorControls(kf.anchor);
            end
            app.Populating = false;
        end

        function populateKeyframeAnchorControls(app, fa)
            %populateKeyframeAnchorControls Mirrors a keyframe's fixed-anchor
            %settings onto the editor's anchor sub-grids.  Called from
            %populateKeyframeEditor inside a Populating block (does not toggle
            %Populating itself).  The FOV is the keyframe's own View angle
            %field, so the anchor's viewAngleDeg is not shown here.
            app.KfAnchorTypeDropDown.Value = fa.anchorType.name;
            app.KfAnchorXEditField.Value = fa.fixedPosition(1);
            app.KfAnchorYEditField.Value = fa.fixedPosition(2);
            app.KfAnchorZEditField.Value = fa.fixedPosition(3);
            if(not(isempty(fa.anchorFrame)) && all(isvalid(fa.anchorFrame)))
                try
                    app.KfAnchorFrameSelector.setSelectedFrame(fa.anchorFrame);
                catch
                end
            end

            %ground object dropdown
            [goNames, goObjs] = app.LvdData.groundObjs.getListboxStr();
            if(isempty(goNames))
                app.KfAnchorGroundObjectDropDown.Items = {'(none)'};
                app.KfAnchorGroundObjectDropDown.ItemsData = {[]};
            else
                app.KfAnchorGroundObjectDropDown.Items = goNames;
                app.KfAnchorGroundObjectDropDown.ItemsData = num2cell(1:numel(goObjs));
                if(not(isempty(fa.groundObject)) && all(isvalid(fa.groundObject)))
                    idx = find(goObjs == fa.groundObject, 1);
                    if(not(isempty(idx)))
                        app.KfAnchorGroundObjectDropDown.Value = idx;
                    end
                end
            end

            %geometric point dropdown (vehicle-independent points only)
            [gpNames, gpPts] = app.filteredGeomPoints();
            if(isempty(gpNames))
                app.KfAnchorGeometricPointDropDown.Items = {'(none)'};
                app.KfAnchorGeometricPointDropDown.ItemsData = {[]};
            else
                app.KfAnchorGeometricPointDropDown.Items = gpNames;
                app.KfAnchorGeometricPointDropDown.ItemsData = num2cell(1:numel(gpPts));
                if(not(isempty(fa.geometricPoint)) && all(isvalid(fa.geometricPoint)))
                    idx = find(gpPts == fa.geometricPoint, 1);
                    if(not(isempty(idx)))
                        app.KfAnchorGeometricPointDropDown.Value = idx;
                    end
                end
            end
        end

        function populateMeshTab(app)
            mesh = app.getProfile().vehicleMesh;
            app.Populating = true;
            app.MeshEnabledCheckBox.Value = mesh.enabled;
            if(strlength(mesh.sourcePath) > 0)
                app.MeshPathLabel.Text = char(mesh.sourcePath);
            else
                app.MeshPathLabel.Text = '<no mesh imported>';
            end
            app.MeshScaleEditField.Value = mesh.scale;
            app.MeshYawEditField.Value = mesh.rotOffsetEulerDeg(1);
            app.MeshPitchEditField.Value = mesh.rotOffsetEulerDeg(2);
            app.MeshRollEditField.Value = mesh.rotOffsetEulerDeg(3);
            app.MeshTransXEditField.Value = mesh.transOffsetKm(1);
            app.MeshTransYEditField.Value = mesh.transOffsetKm(2);
            app.MeshTransZEditField.Value = mesh.transOffsetKm(3);
            app.MeshAlphaSpinner.Value = mesh.faceAlpha;
            app.MeshShowEdgesCheckBox.Value = mesh.showEdges;
            app.MeshLightingCheckBox.Value = mesh.useLighting;
            app.MeshFaceColorButton.BackgroundColor = mesh.faceColor;
            app.MeshFaceColorButton.FontColor = app.contrastColor(mesh.faceColor);
            app.MeshEdgeColorButton.BackgroundColor = mesh.edgeColor;
            app.MeshEdgeColorButton.FontColor = app.contrastColor(mesh.edgeColor);
            app.MeshInfoLabel.Text = mesh.getSummaryStr();
            app.Populating = false;
        end

        function populateOverlayTab(app)
            ov = app.getProfile().overlay;
            app.Populating = true;
            app.OverlayEnabledCheckBox.Value = ov.enabled;
            app.OverlayTitleEditField.Value = ov.title;
            app.OverlayShowEpochCheckBox.Value = ov.showEpoch;
            app.OverlayShowUtCheckBox.Value = ov.showUT;
            app.OverlayShowMetCheckBox.Value = ov.showMet;
            app.OverlayShowEventCheckBox.Value = ov.showEventName;
            app.OverlayCornerDropDown.Value = char(ov.corner);
            app.OverlayMarginSpinner.Value = round(ov.marginFrac * 100, 1);
            if(ismember(ov.fontName, app.OverlayFontNameDropDown.Items))
                app.OverlayFontNameDropDown.Value = ov.fontName;
            end
            app.OverlayFontSizeSpinner.Value = ov.fontSize;
            app.OverlayBoldCheckBox.Value = ov.fontWeight == "bold";
            app.OverlayFontColorButton.BackgroundColor = ov.fontColor;
            app.OverlayFontColorButton.FontColor = app.contrastColor(ov.fontColor);
            app.OverlayBackgroundCheckBox.Value = ov.showBackground;
            app.OverlayBackgroundColorButton.BackgroundColor = ov.backgroundColor;
            app.OverlayBackgroundColorButton.FontColor = app.contrastColor(ov.backgroundColor);

            items = ov.items;
            data = cell(numel(items), 6);
            for(i=1:numel(items))
                it = items(i);
                data(i,:) = {it.getQuantityStr(), it.getFrameStr(), it.label, it.decimals, char(it.format), it.showUnits};
            end
            app.OverlayTable.Data = data;
            app.Populating = false;

            n = ov.getNumItems();
            if(app.SelectedOverlayInd < 1 || app.SelectedOverlayInd > n)
                app.selectOverlayItem(min(1, n));
            else
                app.selectOverlayItem(app.SelectedOverlayInd);
            end
            app.updateOverlayPreview();
        end

        function updateOverlayPreview(app)
            try
                lines = app.getOverlayLines();
            catch
                lines = {};
            end
            ov = app.getProfile().overlay;
            if(isempty(lines))
                app.OverlayPreviewLabel.Text = 'Preview: (nothing to show - tick some header lines or add a quantity)';
            elseif(not(ov.enabled))
                app.OverlayPreviewLabel.Text = sprintf('Preview (overlay is OFF): %s', strjoin(lines, '   |   '));
            else
                app.OverlayPreviewLabel.Text = sprintf('Preview: %s', strjoin(lines, '   |   '));
            end
        end

        function updateEnableStates(app)
            hasLog = app.hasStateLog();
            onOff = app.onOff(hasLog);
            app.PlayButton.Enable = onOff;
            app.PauseButton.Enable = onOff;
            app.StopButton.Enable = onOff;
            app.StepBackButton.Enable = onOff;
            app.StepFwdButton.Enable = onOff;
            app.GoToStartButton.Enable = onOff;
            app.GoToEndButton.Enable = onOff;
            app.ExportVideoButton.Enable = onOff;

            profile = app.getProfile();
            isChase = profile.cameraMode == LvdCameraModeEnum.Chase;
            isScript = profile.cameraMode == LvdCameraModeEnum.Scripted;
            isFixedAnchor = profile.cameraMode == LvdCameraModeEnum.FixedAnchor;
            app.setChildrenEnable(app.ChaseGrid, isChase);
            app.setChildrenEnable(app.FixedAnchorGrid, isFixedAnchor);
            app.updateCameraModePanels();

            %the script can be authored in ANY camera mode (keyframes are taken
            %from wherever the camera is); only Resume needs a detached script
            hasSel = app.SelectedKfInd > 0;
            app.KeyframeTable.Enable = 'on';
            app.AddKeyframeButton.Enable = 'on';
            app.UpdateKeyframeButton.Enable = app.onOff(hasSel);
            app.RemoveKeyframeButton.Enable = app.onOff(hasSel);
            app.ResumeScriptButton.Enable = app.onOff(isScript && profile.getCameraDriver().isScriptDetached());
            app.setChildrenEnable(app.KeyframeEditorGrid, hasSel);
            app.AdvancedPoseCheckBox.Enable = app.onOff(hasSel);
            if(hasSel)
                app.updateKeyframeRefFieldStates();
            end
            app.updateScriptStateLabel();

            mesh = profile.vehicleMesh;
            app.ReloadMeshButton.Enable = app.onOff(strlength(mesh.sourcePath) > 0);
            app.ClearMeshButton.Enable = app.onOff(mesh.hasMesh());
            app.FitButton.Enable = app.onOff(mesh.hasMesh());
            app.ShowInChaseButton.Enable = app.onOff(mesh.hasMesh() && hasLog);

            ov = profile.overlay;
            nOv = ov.getNumItems();
            hasOvSel = app.SelectedOverlayInd > 0;
            app.OverlayRemoveButton.Enable = app.onOff(hasOvSel);
            app.OverlayMoveUpButton.Enable = app.onOff(hasOvSel && app.SelectedOverlayInd > 1);
            app.OverlayMoveDownButton.Enable = app.onOff(hasOvSel && app.SelectedOverlayInd < nOv);
            app.OverlayAddButton.Enable = app.onOff(not(isempty(app.OverlayTaskListBox.Items)));
            app.OverlayBackgroundColorButton.Enable = app.onOff(ov.showBackground);
        end

        function updateCameraModePanels(app)
            %updateCameraModePanels Strict per-mode visibility: only the active
            %camera mode's configuration panel is shown, and every hidden
            %panel's Camera-tab grid row collapses to zero height so the active
            %panel is never pushed off the bottom of the window.  Manual shows
            %no configuration panel at all.
            profile = app.getProfile();
            if(isempty(profile))
                return;
            end
            mode = profile.cameraMode;
            isChase = mode == LvdCameraModeEnum.Chase;
            isScript = mode == LvdCameraModeEnum.Scripted;
            isFixedAnchor = mode == LvdCameraModeEnum.FixedAnchor;

            app.ChasePanel.Visible = app.onOff(isChase);
            app.ScriptPanel.Visible = app.onOff(isScript);
            app.FixedAnchorPanel.Visible = app.onOff(isFixedAnchor);

            %Chase row: the panel is a fixed two-row grid (matches the row
            %height the tab shipped with)
            chaseH = 0;
            if(isChase)
                chaseH = 105;
            end

            %Script row: fixed chrome plus whatever height the selected-keyframe
            %editor currently needs (numeric pose toggle / fixed-anchor editor)
            scriptH = 0;
            if(isScript)
                scriptH = app.ScriptPanelChromeHeight + app.currentKeyframeEditorHeight();
            end

            %Fixed Camera row: its height tracks the anchor type (FixedXYZ needs
            %an extra control line for the frame + "set from current camera")
            fixedH = 0;
            if(isFixedAnchor)
                if(profile.fixedAnchorCamera.anchorType == LvdCameraAnchorTypeEnum.FixedXYZ)
                    fixedH = app.FixedAnchorHeightXYZ;
                else
                    fixedH = app.FixedAnchorHeightObject;
                end
            end

            app.CameraGrid.RowHeight = {24, chaseH, scriptH, fixedH};
        end

        function updateKeyframeRefFieldStates(app)
            kf = app.getSelectedKeyframe();
            if(isempty(kf))
                return;
            end
            refType = LvdCameraKeyframeRefEnum.getEnumForListboxStr(app.KfRefDropDown.Value);
            isScene = refType == LvdCameraKeyframeRefEnum.SceneFixed;
            isVeh = refType == LvdCameraKeyframeRefEnum.VehicleRelative;
            isFixedAnchor = refType == LvdCameraKeyframeRefEnum.FixedAnchorTracking;
            sceneFields = {app.KfPosXEditField, app.KfPosYEditField, app.KfPosZEditField, ...
                           app.KfTgtXEditField, app.KfTgtYEditField, app.KfTgtZEditField, ...
                           app.KfUpXEditField, app.KfUpYEditField, app.KfUpZEditField};
            vehFields = {app.KfAzEditField, app.KfElEditField, app.KfRangeEditField};
            for(i=1:numel(sceneFields))
                sceneFields{i}.Enable = app.onOff(isScene);
            end
            for(i=1:numel(vehFields))
                vehFields{i}.Enable = app.onOff(isVeh);
            end

            %fixed-anchor tracking: show only the sub-grid for the chosen anchor
            %type (the whole anchor editor is shown/collapsed by the layout)
            anchorType = LvdCameraAnchorTypeEnum.getEnumForListboxStr(app.KfAnchorTypeDropDown.Value);
            app.KfFixedXYZSubGrid.Visible = app.onOff(isFixedAnchor && anchorType == LvdCameraAnchorTypeEnum.FixedXYZ);
            app.KfGroundObjSubGrid.Visible = app.onOff(isFixedAnchor && anchorType == LvdCameraAnchorTypeEnum.GroundObject);
            app.KfGeomPtSubGrid.Visible = app.onOff(isFixedAnchor && anchorType == LvdCameraAnchorTypeEnum.GeometricPoint);

            anchor = LvdCameraKeyframeAnchorEnum.getEnumForListboxStr(app.KfAnchorDropDown.Value);
            app.KfEventDropDown.Enable = app.onOff(anchor ~= LvdCameraKeyframeAnchorEnum.AbsoluteTime);
            if(anchor == LvdCameraKeyframeAnchorEnum.AbsoluteTime)
                app.KfTimeEditField.Tooltip = 'Keyframe time, seconds UT.';
            else
                app.KfTimeEditField.Tooltip = 'Offset from the event start/end, seconds.';
            end

            app.updateKeyframeEditorLayout();
        end

        function updateTimeLabel(app)
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end
            if(isempty(app.Controller) || not(isvalid(app.Controller)) || isnan(app.Controller.currentTime))
                app.TimeLabel.Text = 'UT: --';
                return;
            end
            t = app.Controller.currentTime;
            try
                [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(t);
                epochStr = formDateStr(year, day, hour, minute, sec);
            catch
                epochStr = '';
            end
            app.TimeLabel.Text = sprintf('UT %.3f s   %s', t, epochStr);
            app.updateActiveKeyframeHighlight();
        end

        function onPlaybackStateChanged(app)
            if(isempty(app.UIFigure) || not(isvalid(app.UIFigure)))
                return;
            end
            switch(app.Controller.state)
                case "playing"
                    app.PlayButton.Text = 'Playing...';
                case "paused"
                    app.PlayButton.Text = 'Resume';
                otherwise
                    app.PlayButton.Text = 'Play';
            end
        end

        %% ------------------------------------------------------ helpers
        function tf = hasStateLog(app)
            tf = false;
            try
                tf = app.LvdData.stateLog.getNumberOfEntries() > 0;
            catch
            end
        end

        function t = currentTimeOrStart(app)
            t = NaN;
            if(not(isempty(app.Controller)) && isvalid(app.Controller))
                t = app.Controller.currentTime;
                if(isnan(t))
                    lims = app.Controller.timeLimits;
                    t = lims(1);
                end
            end
            if(isnan(t))
                t = 0;
            end
        end

        function pos = vehiclePositionNow(app)
            pos = app.vehiclePositionAt(app.currentTimeOrStart());
        end

        function pos = vehiclePositionAt(app, t)
            profile = app.getProfile();
            pos = LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, t);
        end

        function tasks = allOverlayTasks(app)
            tasks = {};
            try
                tasks = lvd_getGraphAnalysisTaskList(app.LvdData, getLvdGAExcludeList());
                tasks = sort(tasks(:))';
            catch
                tasks = {};
            end
        end

        function frame = selectedOverlayFrame(app)
            frame = [];
            try
                frame = app.OverlayFrameSelector.getSelectedFrame();
            catch
                frame = [];
            end
            if(isempty(frame))
                frame = app.LvdData.initStateModel.centralBody.getBodyCenteredInertialFrame();
            end
        end

        function renderCurrent(app)
            %renderCurrent Re-renders the main window at the current time so
            %camera/mesh/overlay edits show up immediately.
            if(isempty(app.MainApp) || not(isvalid(app.MainApp)) || not(app.hasStateLog()))
                return;
            end
            try
                app.Controller.stepTo(app.currentTimeOrStart());
            catch ME
                app.StatusLabel.Text = sprintf('Render failed: %s', ME.message);
            end
        end

        function afterMeshChanged(app)
            profile = app.getProfile();
            for(i=1:numel(profile.markerVehicleMeshData))
                try
                    profile.markerVehicleMeshData(i).refreshAppearance();
                catch
                end
            end
            app.MeshInfoLabel.Text = profile.vehicleMesh.getSummaryStr();
            app.updateEnableStates();
            app.updateMeshPreview();
            app.renderCurrent();
        end

        function afterOverlayChanged(app, itemsChanged)
            profile = app.getProfile();
            for(i=1:numel(profile.markerOverlayData))
                try
                    if(itemsChanged)
                        profile.markerOverlayData(i).invalidate();
                    end
                    profile.markerOverlayData(i).refreshAppearance();
                catch
                end
            end
            app.updateEnableStates();
            app.renderCurrent();
            app.updateOverlayPreview();
        end

        function updateMeshPreview(app)
            ax = app.MeshPreviewAxes;
            if(isempty(ax) || not(isvalid(ax)))
                return;
            end
            mesh = app.getProfile().vehicleMesh;
            delete(findobj(ax, 'Tag', 'LvdMeshPreviewPatch'));
            delete(findobj(ax, 'Tag', 'LvdMeshPreviewTriad'));

            if(not(mesh.hasMesh()))
                title(ax, 'No mesh loaded');
                return;
            end

            Vb = mesh.getBodyFrameVertices();
            hold(ax, 'on');
            patch(ax, 'Faces', mesh.faces, 'Vertices', Vb, ...
                  'FaceColor', mesh.faceColor, 'FaceAlpha', max(0.15, mesh.faceAlpha), ...
                  'EdgeColor', app.edgeColorOrNone(mesh), 'Tag', 'LvdMeshPreviewPatch');

            r = max(mesh.getBoundingRadiusKm(), eps) * 1.2;
            quiver3(ax, 0, 0, 0, r, 0, 0, 0, 'Color', 'r', 'LineWidth', 2, 'Tag', 'LvdMeshPreviewTriad');
            quiver3(ax, 0, 0, 0, 0, r, 0, 0, 'Color', 'g', 'LineWidth', 2, 'Tag', 'LvdMeshPreviewTriad');
            quiver3(ax, 0, 0, 0, 0, 0, r, 0, 'Color', 'b', 'LineWidth', 2, 'Tag', 'LvdMeshPreviewTriad');
            hold(ax, 'off');

            axis(ax, 'equal');
            axis(ax, 'vis3d');
            lim = [-r r];
            xlim(ax, lim); ylim(ax, lim); zlim(ax, lim);
            title(ax, 'Body frame: X red, Y green, Z blue (km)');
        end

        function c = edgeColorOrNone(~, mesh)
            if(mesh.showEdges)
                c = mesh.edgeColor;
            else
                c = 'none';
            end
        end

        function fc = contrastColor(~, bg)
            if(0.299*bg(1) + 0.587*bg(2) + 0.114*bg(3) > 0.55)
                fc = [0.1 0.1 0.1];
            else
                fc = [0.95 0.95 0.95];
            end
        end

        function setChildrenEnable(app, container, tf)
            if(isempty(container) || not(isvalid(container)))
                return;
            end
            kids = container.Children;
            for(i=1:numel(kids))
                if(isprop(kids(i), 'Enable'))
                    kids(i).Enable = app.onOff(tf);
                elseif(isa(kids(i), 'matlab.ui.container.GridLayout') || isa(kids(i), 'matlab.ui.container.Panel'))
                    app.setChildrenEnable(kids(i), tf);
                end
            end
        end

        function t = parseOptionalTime(~, str)
            str = strtrim(str);
            if(isempty(str))
                t = NaN;
            else
                t = str2double(str);
                if(isnan(t))
                    error('lvd_ViewPlaybackGUI_App:badTime', '"%s" is not a number.', str);
                end
            end
        end

        function str = formatOptionalTime(~, t)
            if(isnan(t))
                str = '';
            else
                str = sprintf('%.3f', t);
            end
        end

        function va = parseOptionalViewAngle(~, str)
            %parseOptionalViewAngle Blank -> NaN (leave the axes view angle);
            %else a number in (0, 180).
            str = strtrim(str);
            if(isempty(str))
                va = NaN;
                return;
            end
            va = str2double(str);
            if(isnan(va) || va <= 0 || va >= 180)
                error('lvd_ViewPlaybackGUI_App:badViewAngle', '"%s" is not a view angle in (0, 180) degrees.', str);
            end
        end

        function [names, pts] = filteredGeomPoints(app)
            %filteredGeomPoints The mission's geometric points, minus the
            %vehicle-dependent ones (a fixed anchor cannot depend on the
            %vehicle it is meant to track).
            [allNames, allPts] = app.LvdData.geometry.points.getListboxStr();
            keep = false(1, numel(allPts));
            for(i=1:numel(allPts))
                try
                    keep(i) = not(allPts(i).isVehDependent());
                catch
                    keep(i) = false;
                end
            end
            names = allNames(keep);
            pts = allPts(keep);
        end

        function obj = resolveFromArray(~, indOrObj, arr)
            %resolveFromArray Maps a 1-based index (or an object already in
            %arr) to the element of arr; [] when out of range/not found.
            if(isnumeric(indOrObj))
                if(isscalar(indOrObj) && indOrObj >= 1 && indOrObj <= numel(arr))
                    obj = arr(indOrObj);
                else
                    obj = [];
                end
            else
                obj = indOrObj;
            end
        end

        %% ---------------------------------------------------- callbacks
        function onPlaybackFieldChanged(app)
            if(app.Populating)
                return;
            end
            try
                app.applyPlaybackFields();
            catch ME
                uialert(app.UIFigure, ME.message, 'Invalid Value', 'Icon', 'error');
                app.populatePlaybackTab();
            end
        end

        function onCameraModeChanged(app)
            if(app.Populating)
                return;
            end
            mode = LvdCameraModeEnum.getEnumForListboxStr(app.CameraModeDropDown.Value);
            app.setCameraMode(mode);
        end

        function onChaseFieldChanged(app)
            if(app.Populating)
                return;
            end
            app.applyChaseFields();
        end

        function onAnchorTypeChanged(app)
            if(app.Populating)
                return;
            end
            app.setCameraAnchorType(LvdCameraAnchorTypeEnum.getEnumForListboxStr(app.AnchorTypeDropDown.Value));
        end

        function onAnchorFixedFieldChanged(app)
            if(app.Populating)
                return;
            end
            frame = [];
            try
                frame = app.AnchorFrameSelector.getSelectedFrame();
            catch
            end
            app.setFixedAnchorPosition([app.AnchorXEditField.Value, app.AnchorYEditField.Value, app.AnchorZEditField.Value], frame);
        end

        function onAnchorGroundObjChanged(app)
            if(app.Populating)
                return;
            end
            ind = app.AnchorGroundObjectDropDown.Value;
            if(isempty(ind))
                return;
            end
            app.setAnchorGroundObject(ind);
        end

        function onAnchorGeomPtChanged(app)
            if(app.Populating)
                return;
            end
            ind = app.AnchorGeometricPointDropDown.Value;
            if(isempty(ind))
                return;
            end
            app.setAnchorGeometricPoint(ind);
        end

        function onAnchorViewAngleChanged(app)
            if(app.Populating)
                return;
            end
            try
                va = app.parseOptionalViewAngle(app.AnchorViewAngleEditField.Value);
            catch ME
                uialert(app.UIFigure, ME.message, 'Invalid Value', 'Icon', 'error');
                app.populateCameraTab();
                return;
            end
            app.setFixedAnchorViewAngle(va);
        end

        function onKeyframeTableSelection(app)
            if(app.Populating)
                return;
            end
            sel = app.KeyframeTable.Selection;
            if(isempty(sel))
                return;
            end
            row = sel(1);
            if(row < 1 || row > numel(app.KeyframeRowOrder))
                return;
            end
            %a user's click on a row goes to that keyframe
            app.goToKeyframe(app.KeyframeRowOrder(row));
        end

        function onKeyframeEditorFieldChanged(app)
            if(app.Populating)
                return;
            end
            app.updateKeyframeRefFieldStates();
        end

        function onNewKeyframeDefaultsChanged(app)
            if(app.Populating)
                return;
            end
            app.applyNewKeyframeDefaults();
        end

        function onAdvancedPoseToggled(app)
            if(app.Populating)
                return;
            end
            app.showAdvancedPose(app.AdvancedPoseCheckBox.Value);
        end

        function onMeshFieldChanged(app)
            if(app.Populating)
                return;
            end
            try
                app.applyMeshFields();
            catch ME
                uialert(app.UIFigure, ME.message, 'Invalid Value', 'Icon', 'error');
                app.populateMeshTab();
            end
        end

        function onOverlayFieldChanged(app)
            if(app.Populating)
                return;
            end
            try
                app.applyOverlayFields();
            catch ME
                app.CallbackErrorLog{end+1} = sprintf('%s | %s', ME.message, ME.getReport('basic'));
                uialert(app.UIFigure, ME.message, 'Invalid Value', 'Icon', 'error');
                app.populateOverlayTab();
            end
        end

        function onOverlayTableSelection(app)
            if(app.Populating)
                return;
            end
            sel = app.OverlayTable.Selection;
            if(isempty(sel))
                return;
            end
            app.selectOverlayItem(sel(1));
        end

        function onOverlayCellEdit(app, evt)
            if(app.Populating)
                return;
            end
            app.applyOverlayTableEdit(evt.Indices(1), evt.Indices(2), evt.NewData);
        end

        function onOverlaySearchChanging(app, evt)
            app.filterOverlayTasks(evt.Value);
        end

        function onOverlayColorButton(app, which)
            ov = app.getProfile().overlay;
            if(strcmp(which, 'font'))
                current = ov.fontColor;
            else
                current = ov.backgroundColor;
            end
            try
                c = uisetcolor(current, 'Select Overlay Colour');
            catch
                return;
            end
            figure(app.UIFigure);
            if(isequal(c, 0) || numel(c) ~= 3)
                return;
            end
            if(strcmp(which, 'font'))
                app.setOverlayColors(c, []);
            else
                app.setOverlayColors([], c);
            end
        end

        function onImportMeshButton(app)
            [fileName, pathName] = uigetfile({'*.stl;*.obj', 'Mesh Files (*.stl, *.obj)'; '*.stl', 'STL Files'; '*.obj', 'Wavefront OBJ Files'}, ...
                                             'Import Vehicle Mesh');
            figure(app.UIFigure);
            if(isequal(fileName, 0))
                return;
            end
            try
                app.importMeshFromFile(fullfile(pathName, fileName));
            catch ME
                uialert(app.UIFigure, ME.message, 'Mesh Import Failed', 'Icon', 'error');
            end
        end

        function onReloadMeshButton(app)
            try
                app.reloadMesh();
            catch ME
                uialert(app.UIFigure, ME.message, 'Mesh Reload Failed', 'Icon', 'error');
            end
        end

        function onFitButton(app)
            try
                app.fitMeshToLength(app.FitLengthEditField.Value);
            catch ME
                uialert(app.UIFigure, ME.message, 'Cannot Fit Mesh', 'Icon', 'error');
            end
        end

        function onColorButton(app, which)
            mesh = app.getProfile().vehicleMesh;
            if(strcmp(which, 'face'))
                current = mesh.faceColor;
            else
                current = mesh.edgeColor;
            end
            try
                c = uisetcolor(current, 'Select Mesh Colour');
            catch
                return;
            end
            figure(app.UIFigure);
            if(isequal(c, 0) || numel(c) ~= 3)
                return;
            end
            app.pushUndo('Edit Vehicle Mesh Appearance');
            if(strcmp(which, 'face'))
                mesh.faceColor = c;
            else
                mesh.edgeColor = c;
            end
            app.populateMeshTab();
            app.afterMeshChanged();
        end

        function onExportVideoButton(app)
            try
                app.applyPlaybackFields();
            catch ME
                uialert(app.UIFigure, ME.message, 'Invalid Value', 'Icon', 'error');
                return;
            end
            if(not(app.hasStateLog()))
                uialert(app.UIFigure, 'Propagate the mission before exporting a video.', 'No Trajectory', 'Icon', 'warning');
                return;
            end
            settings = app.getProfile().playbackSettings;
            ext = settings.getVideoExtension();
            [fileName, pathName] = uiputfile({['*' ext], sprintf('%s (*%s)', settings.videoFormat, ext)}, 'Export Video', ['lvd_trajectory' ext]);
            figure(app.UIFigure);
            if(isequal(fileName, 0))
                return;
            end
            try
                n = app.exportVideo(fullfile(pathName, fileName));
                uialert(app.UIFigure, sprintf('%u frames written to:\n\n%s', n, fullfile(pathName, fileName)), 'Video Exported', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, sprintf('Video export failed: %s', ME.message), 'Export Error', 'Icon', 'error');
            end
        end

        function onExportImageButton(app)
            [fileName, pathName] = uiputfile({'*.png', 'PNG Image (*.png)'; '*.jpg', 'JPEG Image (*.jpg)'; '*.pdf', 'PDF (*.pdf)'}, 'Export Image', 'lvd_view.png');
            figure(app.UIFigure);
            if(isequal(fileName, 0))
                return;
            end
            try
                app.exportImage(fullfile(pathName, fileName));
            catch ME
                uialert(app.UIFigure, sprintf('Image export failed: %s', ME.message), 'Export Error', 'Icon', 'error');
            end
        end

        function onGoToStart(app)
            lims = app.Controller.timeLimits;
            app.Controller.pause();
            app.Controller.stepTo(lims(1));
        end

        function onGoToEnd(app)
            lims = app.Controller.timeLimits;
            app.Controller.pause();
            app.Controller.stepTo(lims(2));
        end

        function onPlayButton(app)
            try
                if(app.Controller.state == "playing")
                    app.pause();
                else
                    app.play();
                end
            catch ME
                uialert(app.UIFigure, ME.message, 'Cannot Play', 'Icon', 'error');
            end
        end

        %% ----------------------------------------------------- creation
        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 60 760 800];   %tall enough that no tab's fixed-height panels are clipped
            app.UIFigure.Name = app.WindowName;
            app.UIFigure.Tag = app.FigureTag;
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.HandleVisibility = 'callback';   %survives "close all", like the other LVD dialogs
            app.UIFigure.CloseRequestFcn = @(~,~) delete(app);

            app.MainGrid = uigridlayout(app.UIFigure, [3 1]);
            app.MainGrid.RowHeight = {48, '1x', 'fit'};
            app.MainGrid.ColumnWidth = {'1x'};

            app.ProfileHeaderLabel = uilabel(app.MainGrid);
            app.ProfileHeaderLabel.Text = '';
            app.ProfileHeaderLabel.WordWrap = 'on';
            app.ProfileHeaderLabel.FontWeight = 'bold';
            app.ProfileHeaderLabel.FontSize = 11;
            app.ProfileHeaderLabel.HorizontalAlignment = 'center';
            app.ProfileHeaderLabel.Tooltip = 'View profiles are managed with View > Edit View Settings... and View > Set Active View Profile... in the main window.';
            app.ProfileHeaderLabel.Layout.Row = 1;
            app.ProfileHeaderLabel.Layout.Column = 1;

            app.TabGroup = uitabgroup(app.MainGrid);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = 1;

            app.StatusLabel = uilabel(app.MainGrid);
            app.StatusLabel.Text = '';
            app.StatusLabel.HorizontalAlignment = 'center';
            app.StatusLabel.FontAngle = 'italic';
            app.StatusLabel.WordWrap = 'on';
            app.StatusLabel.Layout.Row = 3;
            app.StatusLabel.Layout.Column = 1;

            app.createPlaybackTab();
            app.createCameraTab();
            app.createMeshTab();
            app.createOverlayTab();
        end

        function createPlaybackTab(app)
            app.PlaybackTab = uitab(app.TabGroup, 'Title', 'Playback');
            app.PlaybackTab.Tooltip = 'Playback speed, frame rate and export settings of the active view profile.';
            app.PlaybackGrid = uigridlayout(app.PlaybackTab, [4 1]);
            app.PlaybackGrid.RowHeight = {28, 40, 100, 175};
            app.PlaybackGrid.ColumnWidth = {'1x'};
            app.PlaybackGrid.Scrollable = 'on';

            app.TimeLabel = uilabel(app.PlaybackGrid);
            app.TimeLabel.Text = 'UT: --';
            app.TimeLabel.HorizontalAlignment = 'center';
            app.TimeLabel.FontSize = 14;
            app.TimeLabel.FontWeight = 'bold';
            app.TimeLabel.Layout.Row = 1;
            app.TimeLabel.Layout.Column = 1;

            app.TransportGrid = uigridlayout(app.PlaybackGrid, [1 7]);
            app.TransportGrid.ColumnWidth = {'1x', '1x', '1.4x', '1x', '1x', '1x', '1x'};
            app.TransportGrid.RowHeight = {'1x'};
            app.TransportGrid.Padding = [0 0 0 0];
            app.TransportGrid.Layout.Row = 2;
            app.TransportGrid.Layout.Column = 1;

            app.GoToStartButton = app.makeButton(app.TransportGrid, 1, '|<', 'Go to the start of the trajectory', @(~,~) app.onGoToStart());
            app.StepBackButton = app.makeButton(app.TransportGrid, 2, '< Frame', 'Step back one playback frame', @(~,~) app.stepFrames(-1));
            app.PlayButton = app.makeButton(app.TransportGrid, 3, 'Play', 'Play / pause the trajectory in the 3-D view', @(~,~) app.onPlayButton());
            app.PauseButton = app.makeButton(app.TransportGrid, 4, 'Pause', 'Pause playback', @(~,~) app.pause());
            app.StopButton = app.makeButton(app.TransportGrid, 5, 'Stop', 'Stop and return to the start', @(~,~) app.stop());
            app.StepFwdButton = app.makeButton(app.TransportGrid, 6, 'Frame >', 'Step forward one playback frame', @(~,~) app.stepFrames(1));
            app.GoToEndButton = app.makeButton(app.TransportGrid, 7, '>|', 'Go to the end of the trajectory', @(~,~) app.onGoToEnd());

            app.PlaybackSettingsPanel = uipanel(app.PlaybackGrid, 'Title', 'Playback Settings (saved on the active view profile)');
            app.PlaybackSettingsPanel.Layout.Row = 3;
            app.PlaybackSettingsPanel.Layout.Column = 1;
            app.PlaybackSettingsGrid = uigridlayout(app.PlaybackSettingsPanel, [2 4]);
            app.PlaybackSettingsGrid.RowHeight = {24, 24};
            app.PlaybackSettingsGrid.ColumnWidth = {'fit', '1x', 'fit', '1x'};

            app.makeLabel(app.PlaybackSettingsGrid, 1, 1, 'Speed (sim s per real s):');
            app.SpeedEditField = app.makeNumField(app.PlaybackSettingsGrid, 1, 2, 60, [1e-6 Inf], 'Simulated seconds that pass for every real second of playback.', @(~,~) app.onPlaybackFieldChanged());
            app.makeLabel(app.PlaybackSettingsGrid, 1, 3, 'Frame rate (fps):');
            app.FpsEditField = app.makeNumField(app.PlaybackSettingsGrid, 1, 4, 30, [1 240], 'Frames per second for playback and video export.', @(~,~) app.onPlaybackFieldChanged());
            app.LoopCheckBox = uicheckbox(app.PlaybackSettingsGrid);
            app.LoopCheckBox.Text = 'Loop playback';
            app.LoopCheckBox.Layout.Row = 2;
            app.LoopCheckBox.Layout.Column = [1 2];
            app.LoopCheckBox.ValueChangedFcn = @(~,~) app.onPlaybackFieldChanged();

            app.ExportPanel = uipanel(app.PlaybackGrid, 'Title', 'Export (the data overlay, if enabled, is included)');
            app.ExportPanel.Layout.Row = 4;
            app.ExportPanel.Layout.Column = 1;
            app.ExportGrid = uigridlayout(app.ExportPanel, [4 4]);
            app.ExportGrid.RowHeight = {24, 24, 30, 30};
            app.ExportGrid.ColumnWidth = {'fit', '1x', 'fit', '1x'};

            app.makeLabel(app.ExportGrid, 1, 1, 'Video format:');
            app.VideoFormatDropDown = uidropdown(app.ExportGrid);
            app.VideoFormatDropDown.Items = {'MPEG-4'};
            app.VideoFormatDropDown.Layout.Row = 1;
            app.VideoFormatDropDown.Layout.Column = 2;
            app.VideoFormatDropDown.ValueChangedFcn = @(~,~) app.onPlaybackFieldChanged();
            app.makeLabel(app.ExportGrid, 1, 3, 'Quality (1-100):');
            app.QualityEditField = app.makeNumField(app.ExportGrid, 1, 4, 90, [1 100], 'Video quality (ignored by GIF).', @(~,~) app.onPlaybackFieldChanged());

            app.makeLabel(app.ExportGrid, 2, 1, 'Export start UT (s):');
            app.ExportStartEditField = uieditfield(app.ExportGrid, 'text');
            app.ExportStartEditField.Tooltip = 'Leave blank to start at the beginning of the trajectory.';
            app.ExportStartEditField.Layout.Row = 2;
            app.ExportStartEditField.Layout.Column = 2;
            app.ExportStartEditField.ValueChangedFcn = @(~,~) app.onPlaybackFieldChanged();
            app.makeLabel(app.ExportGrid, 2, 3, 'Export end UT (s):');
            app.ExportEndEditField = uieditfield(app.ExportGrid, 'text');
            app.ExportEndEditField.Tooltip = 'Leave blank to end at the end of the trajectory.';
            app.ExportEndEditField.Layout.Row = 2;
            app.ExportEndEditField.Layout.Column = 4;
            app.ExportEndEditField.ValueChangedFcn = @(~,~) app.onPlaybackFieldChanged();

            app.ExportVideoButton = uibutton(app.ExportGrid, 'push');
            app.ExportVideoButton.Text = 'Export Video...';
            app.ExportVideoButton.Tooltip = 'Render the export time range frame by frame into a video or animated GIF.  The video has the pixel size of the 3-D axes.';
            app.ExportVideoButton.Layout.Row = 3;
            app.ExportVideoButton.Layout.Column = [1 4];
            app.ExportVideoButton.ButtonPushedFcn = @(~,~) app.onExportVideoButton();

            app.makeLabel(app.ExportGrid, 4, 1, 'Image DPI:');
            app.ImageDpiEditField = app.makeNumField(app.ExportGrid, 4, 2, 150, [10 1200], 'Resolution of exported still images.', @(~,~) app.onPlaybackFieldChanged());
            app.ExportImageButton = uibutton(app.ExportGrid, 'push');
            app.ExportImageButton.Text = 'Export Image...';
            app.ExportImageButton.Layout.Row = 4;
            app.ExportImageButton.Layout.Column = 3;
            app.ExportImageButton.ButtonPushedFcn = @(~,~) app.onExportImageButton();
            app.CopyImageButton = uibutton(app.ExportGrid, 'push');
            app.CopyImageButton.Text = 'Copy Image';
            app.CopyImageButton.Tooltip = 'Copy the current 3-D view to the clipboard.';
            app.CopyImageButton.Layout.Row = 4;
            app.CopyImageButton.Layout.Column = 4;
            app.CopyImageButton.ButtonPushedFcn = @(~,~) app.copyImage();
        end

        function createCameraTab(app)
            app.CameraTab = uitab(app.TabGroup, 'Title', 'Camera');
            app.CameraTab.Tooltip = 'Camera mode, chase offsets and camera script of the active view profile.';
            app.CameraGrid = uigridlayout(app.CameraTab, [4 2]);
            app.CameraGrid.RowHeight = {24, 105, app.ScriptPanelHeightCollapsed, 150};   %all fixed so the tab scrolls (never collapses the script panel) when the window is short; the script row grows with the advanced-pose editor
            app.CameraGrid.ColumnWidth = {'fit', '1x'};
            app.CameraGrid.Scrollable = 'on';

            app.makeLabel(app.CameraGrid, 1, 1, 'Camera mode:');
            app.CameraModeDropDown = uidropdown(app.CameraGrid);
            app.CameraModeDropDown.Items = {'Manual'};
            app.CameraModeDropDown.Tooltip = 'Manual: mouse and toolbar.  Chase: follow the vehicle at a fixed offset (drag to adjust).  Camera Script: interpolate between keyframes (drag to take control).  Fixed Camera (Tracking): sit at a fixed anchor and keep the vehicle centred (a launch-pad camera).';
            app.CameraModeDropDown.Layout.Row = 1;
            app.CameraModeDropDown.Layout.Column = 2;
            app.CameraModeDropDown.ValueChangedFcn = @(~,~) app.onCameraModeChanged();

            app.ChasePanel = uipanel(app.CameraGrid, 'Title', 'Chase Camera');
            app.ChasePanel.Layout.Row = 2;
            app.ChasePanel.Layout.Column = [1 2];
            app.ChaseGrid = uigridlayout(app.ChasePanel, [2 6]);
            app.ChaseGrid.RowHeight = {24, 28};
            app.ChaseGrid.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x'};
            app.makeLabel(app.ChaseGrid, 1, 1, 'Azimuth (deg):');
            app.ChaseAzEditField = app.makeNumField(app.ChaseGrid, 1, 2, 45, [-Inf Inf], 'Azimuth of the camera about the vehicle, from view +X toward +Y.', @(~,~) app.onChaseFieldChanged());
            app.makeLabel(app.ChaseGrid, 1, 3, 'Elevation (deg):');
            app.ChaseElEditField = app.makeNumField(app.ChaseGrid, 1, 4, 20, [-90 90], 'Elevation of the camera above the view XY plane.', @(~,~) app.onChaseFieldChanged());
            app.makeLabel(app.ChaseGrid, 1, 5, 'Range (km):');
            app.ChaseRangeEditField = app.makeNumField(app.ChaseGrid, 1, 6, 50, [1e-9 Inf], 'Distance from the vehicle to the camera.', @(~,~) app.onChaseFieldChanged());
            app.makeLabel(app.ChaseGrid, 2, 1, 'View angle (deg):');
            app.ChaseViewAngleEditField = app.makeNumField(app.ChaseGrid, 2, 2, 10, [0.01 179], 'Camera field of view.', @(~,~) app.onChaseFieldChanged());
            app.ChaseFromCurrentButton = uibutton(app.ChaseGrid, 'push');
            app.ChaseFromCurrentButton.Text = 'Set From Current Camera';
            app.ChaseFromCurrentButton.Tooltip = 'Use the main window''s current camera position, relative to the vehicle, as the chase offset.';
            app.ChaseFromCurrentButton.Layout.Row = 2;
            app.ChaseFromCurrentButton.Layout.Column = [3 6];
            app.ChaseFromCurrentButton.ButtonPushedFcn = @(~,~) app.setChaseFromCurrentCamera();

            app.createFixedAnchorPanel();

            app.ScriptPanel = uipanel(app.CameraGrid, 'Title', 'Camera Script');
            app.ScriptPanel.Layout.Row = 3;
            app.ScriptPanel.Layout.Column = [1 2];
            app.ScriptGrid = uigridlayout(app.ScriptPanel, [5 1]);
            app.ScriptGrid.RowHeight = {36, app.KeyframeTableHeight, 30, 26, app.EditorHeightCollapsed};   %fixed table height so the advanced-pose editor grows the (scrollable) tab instead of squeezing the table
            app.ScriptGrid.ColumnWidth = {'1x'};

            %who is driving the camera, and what to do next
            app.ScriptStateLabel = uilabel(app.ScriptGrid);
            app.ScriptStateLabel.Text = 'Camera script state';
            app.ScriptStateLabel.WordWrap = 'on';
            app.ScriptStateLabel.FontWeight = 'bold';
            app.ScriptStateLabel.Tooltip = 'In Camera Script mode, dragging the view detaches the camera from the script so you can set up a keyframe; Add / Update / Resume re-attach it.  Playing also re-attaches.';
            app.ScriptStateLabel.Layout.Row = 1;
            app.ScriptStateLabel.Layout.Column = 1;

            app.KeyframeTable = uitable(app.ScriptGrid);
            app.KeyframeTable.ColumnName = {'#', 'Name', 'Anchor', 'Reference', 'Hold (s)', 'Resolved UT (s)'};
            app.KeyframeTable.ColumnWidth = {30, 110, 'auto', 130, 60, 110};
            app.KeyframeTable.ColumnEditable = false;
            app.KeyframeTable.RowName = {};
            app.KeyframeTable.SelectionType = 'row';
            app.KeyframeTable.Multiselect = 'off';
            app.KeyframeTable.Tooltip = 'Keyframes in the order the script plays them (by resolved time).  The bold row is where the script is at the current time.  Click a row to go to that keyframe.';
            app.KeyframeTable.Layout.Row = 2;
            app.KeyframeTable.Layout.Column = 1;
            app.KeyframeTable.SelectionChangedFcn = @(~,~) app.onKeyframeTableSelection();

            app.KeyframeButtonGrid = uigridlayout(app.ScriptGrid, [1 4]);
            app.KeyframeButtonGrid.RowHeight = {'1x'};
            app.KeyframeButtonGrid.ColumnWidth = {'1.3x', '1.7x', '1x', '0.8x'};
            app.KeyframeButtonGrid.Padding = [0 0 0 0];
            app.KeyframeButtonGrid.Layout.Row = 3;
            app.KeyframeButtonGrid.Layout.Column = 1;
            app.AddKeyframeButton = app.makeButton(app.KeyframeButtonGrid, 1, 'Add Keyframe Here', ...
                'Add a keyframe at the current time from the main window''s camera, using the "New keyframes are" settings below.  Works in every camera mode; a detached camera re-attaches to the script.', ...
                @(~,~) app.addKeyframeHere());
            app.UpdateKeyframeButton = app.makeButton(app.KeyframeButtonGrid, 2, 'Update Selected From Camera', ...
                'Give the selected keyframe the main window''s current camera (its time and reference type are kept); a detached camera re-attaches to the script.', ...
                @(~,~) app.updateSelectedKeyframeFromCamera());
            app.ResumeScriptButton = app.makeButton(app.KeyframeButtonGrid, 3, 'Resume Script', ...
                'Let the script drive the camera again without adding or changing a keyframe.', ...
                @(~,~) app.resumeScript());
            app.RemoveKeyframeButton = app.makeButton(app.KeyframeButtonGrid, 4, 'Remove', 'Remove the selected keyframe', @(~,~) app.removeKeyframe());

            app.NewKeyframeGrid = uigridlayout(app.ScriptGrid, [1 4]);
            app.NewKeyframeGrid.RowHeight = {'1x'};
            app.NewKeyframeGrid.ColumnWidth = {'fit', '1x', 'fit', '1.4x'};
            app.NewKeyframeGrid.Padding = [0 0 0 0];
            app.NewKeyframeGrid.Layout.Row = 4;
            app.NewKeyframeGrid.Layout.Column = 1;
            app.makeLabel(app.NewKeyframeGrid, 1, 1, 'New keyframes are:');
            app.NewKeyframeRefDropDown = uidropdown(app.NewKeyframeGrid);
            app.NewKeyframeRefDropDown.Items = {'Scene-Fixed'};
            app.NewKeyframeRefDropDown.Tooltip = 'Vehicle-relative: the keyframe stores the camera''s azimuth / elevation / range about the vehicle and a detached camera keeps that offset while you scrub.  Scene-fixed: the keyframe stores the camera position in the scene and a detached camera stays where you left it.';
            app.NewKeyframeRefDropDown.Layout.Row = 1;
            app.NewKeyframeRefDropDown.Layout.Column = 2;
            app.NewKeyframeRefDropDown.ValueChangedFcn = @(~,~) app.onNewKeyframeDefaultsChanged();
            app.makeLabel(app.NewKeyframeGrid, 1, 3, 'anchored to:');
            app.NewKeyframeAnchorDropDown = uidropdown(app.NewKeyframeGrid);
            app.NewKeyframeAnchorDropDown.Items = {'absolute time (UT)'};
            app.NewKeyframeAnchorDropDown.Tooltip = 'Event anchors ("start of Event N + offset") follow the event when the mission is re-optimised or its durations change; absolute times do not.';
            app.NewKeyframeAnchorDropDown.Layout.Row = 1;
            app.NewKeyframeAnchorDropDown.Layout.Column = 4;
            app.NewKeyframeAnchorDropDown.ValueChangedFcn = @(~,~) app.onNewKeyframeDefaultsChanged();

            app.KeyframeEditorPanel = uipanel(app.ScriptGrid, 'Title', 'Selected Keyframe');
            app.KeyframeEditorPanel.Layout.Row = 5;
            app.KeyframeEditorPanel.Layout.Column = 1;
            g = uigridlayout(app.KeyframeEditorPanel, [7 8]);
            g.RowHeight = {22, 22, 22, 22, 0, 0, 26};
            g.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x', 'fit', '1x'};
            app.KeyframeEditorGrid = g;

            app.makeLabel(g, 1, 1, 'Name:');
            app.KfNameEditField = uieditfield(g, 'text');
            app.KfNameEditField.Layout.Row = 1;
            app.KfNameEditField.Layout.Column = [2 4];
            app.makeLabel(g, 1, 5, 'Easing to next:');
            app.KfEasingDropDown = uidropdown(g);
            app.KfEasingDropDown.Items = {'Linear'};
            app.KfEasingDropDown.Layout.Row = 1;
            app.KfEasingDropDown.Layout.Column = [6 8];

            app.makeLabel(g, 2, 1, 'Anchor:');
            app.KfAnchorDropDown = uidropdown(g);
            app.KfAnchorDropDown.Items = {'Absolute Time (UT)'};
            app.KfAnchorDropDown.Layout.Row = 2;
            app.KfAnchorDropDown.Layout.Column = 2;
            app.KfAnchorDropDown.ValueChangedFcn = @(~,~) app.onKeyframeEditorFieldChanged();
            app.makeLabel(g, 2, 3, 'Event:');
            app.KfEventDropDown = uidropdown(g);
            app.KfEventDropDown.Items = {'<no events>'};
            app.KfEventDropDown.ItemsData = {[]};
            app.KfEventDropDown.Layout.Row = 2;
            app.KfEventDropDown.Layout.Column = [4 6];
            app.makeLabel(g, 2, 7, 'Time / offset (s):');
            app.KfTimeEditField = app.makeNumField(g, 2, 8, 0, [-Inf Inf], 'Keyframe time, seconds UT.', []);

            app.makeLabel(g, 3, 1, 'Hold (s):');
            app.KfHoldEditField = app.makeNumField(g, 3, 2, 0, [0 Inf], 'How long the camera stays on this keyframe before moving to the next.', []);
            app.makeLabel(g, 3, 3, 'Reference:');
            app.KfRefDropDown = uidropdown(g);
            app.KfRefDropDown.Items = {'Scene-Fixed'};
            app.KfRefDropDown.Layout.Row = 3;
            app.KfRefDropDown.Layout.Column = [4 6];
            app.KfRefDropDown.ValueChangedFcn = @(~,~) app.onKeyframeEditorFieldChanged();
            app.makeLabel(g, 3, 7, 'View angle (deg):');
            app.KfViewAngleEditField = app.makeNumField(g, 3, 8, 10, [0.01 179], 'Camera field of view at this keyframe.', []);

            %the numeric pose is the advanced way in; the camera is the normal one
            app.AdvancedPoseCheckBox = uicheckbox(g);
            app.AdvancedPoseCheckBox.Text = 'Show numeric pose (advanced): position / target / up, azimuth / elevation / range';
            app.AdvancedPoseCheckBox.Tooltip = 'Normally you aim the camera with the mouse and press Update Selected From Camera.  Tick this to type the pose numbers instead.';
            app.AdvancedPoseCheckBox.Layout.Row = 4;
            app.AdvancedPoseCheckBox.Layout.Column = [1 8];
            app.AdvancedPoseCheckBox.ValueChangedFcn = @(~,~) app.onAdvancedPoseToggled();

            ga = uigridlayout(g, [2 8]);
            ga.RowHeight = {22, 22};
            ga.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x', 'fit', '1x'};
            ga.Padding = [0 0 0 0];
            ga.Layout.Row = 5;
            ga.Layout.Column = [1 8];
            ga.Visible = 'off';
            app.AdvancedPoseGrid = ga;

            app.makeLabel(ga, 1, 1, 'Position (km):');
            app.KfPosXEditField = app.makeNumField(ga, 1, 2, 0, [-Inf Inf], 'Scene-fixed camera position, view frame X', []);
            app.KfPosYEditField = app.makeNumField(ga, 1, 3, 0, [-Inf Inf], 'Scene-fixed camera position, view frame Y', []);
            app.KfPosZEditField = app.makeNumField(ga, 1, 4, 0, [-Inf Inf], 'Scene-fixed camera position, view frame Z', []);
            app.makeLabel(ga, 1, 5, 'Target (km):');
            app.KfTgtXEditField = app.makeNumField(ga, 1, 6, 0, [-Inf Inf], 'Scene-fixed camera target, view frame X', []);
            app.KfTgtYEditField = app.makeNumField(ga, 1, 7, 0, [-Inf Inf], 'Scene-fixed camera target, view frame Y', []);
            app.KfTgtZEditField = app.makeNumField(ga, 1, 8, 0, [-Inf Inf], 'Scene-fixed camera target, view frame Z', []);

            app.makeLabel(ga, 2, 1, 'Up vector:');
            app.KfUpXEditField = app.makeNumField(ga, 2, 2, 0, [-Inf Inf], 'Scene-fixed camera up vector X', []);
            app.KfUpYEditField = app.makeNumField(ga, 2, 3, 0, [-Inf Inf], 'Scene-fixed camera up vector Y', []);
            app.KfUpZEditField = app.makeNumField(ga, 2, 4, 1, [-Inf Inf], 'Scene-fixed camera up vector Z', []);
            app.makeLabel(ga, 2, 5, 'Az / El / Range:');
            app.KfAzEditField = app.makeNumField(ga, 2, 6, 45, [-Inf Inf], 'Vehicle-relative azimuth (deg)', []);
            app.KfElEditField = app.makeNumField(ga, 2, 7, 20, [-90 90], 'Vehicle-relative elevation (deg)', []);
            app.KfRangeEditField = app.makeNumField(ga, 2, 8, 50, [1e-9 Inf], 'Vehicle-relative range (km)', []);

            %fixed-anchor tracking editor (row 6): shown only when the keyframe's
            %reference is "Fixed Camera (Tracking)".  Mirrors the profile-level
            %createFixedAnchorPanel: an anchor-type header plus three swappable
            %sub-grids sharing one cell (only one shown at a time).  The FOV is
            %the keyframe's own View angle field, so there is no view-angle field
            %here (the embedded anchor's viewAngleDeg stays unused).
            gk = uigridlayout(g, [2 1]);
            gk.Layout.Row = 6;
            gk.Layout.Column = [1 8];
            gk.RowHeight = {24, '1x'};
            gk.ColumnWidth = {'1x'};
            gk.RowSpacing = 6;
            gk.Padding = [0 0 0 0];
            gk.Visible = 'off';
            app.KfAnchorEditorGrid = gk;

            kfHeader = uigridlayout(gk, [1 2]);
            kfHeader.Layout.Row = 1;
            kfHeader.Layout.Column = 1;
            kfHeader.ColumnWidth = {'fit', '1x'};
            kfHeader.Padding = [0 0 0 0];
            app.makeLabel(kfHeader, 1, 1, 'Anchor:');
            app.KfAnchorTypeDropDown = uidropdown(kfHeader);
            app.KfAnchorTypeDropDown.Items = LvdCameraAnchorTypeEnum.getListBoxStr();
            app.KfAnchorTypeDropDown.Tooltip = 'Fixed Coordinates: an XYZ point in a chosen reference frame (a body-fixed frame rotates with the planet, like a pad; an inertial one stays put).  Ground Object / Geometric Point: track from one of the mission''s objects.  The camera sits here and tracks the vehicle for this keyframe.';
            app.KfAnchorTypeDropDown.Layout.Row = 1;
            app.KfAnchorTypeDropDown.Layout.Column = 2;
            app.KfAnchorTypeDropDown.ValueChangedFcn = @(~,~) app.onKeyframeEditorFieldChanged();

            %FixedXYZ: X/Y/Z, then frame + "set from current camera"
            kxyz = uigridlayout(gk, [2 6]);
            kxyz.Layout.Row = 2;
            kxyz.Layout.Column = 1;
            kxyz.RowHeight = {28, 28};
            kxyz.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x'};
            kxyz.Padding = [0 0 0 0];
            app.KfFixedXYZSubGrid = kxyz;
            app.makeLabel(kxyz, 1, 1, 'X (km):');
            app.KfAnchorXEditField = app.makeNumField(kxyz, 1, 2, 0, [-Inf Inf], 'Anchor X coordinate in the chosen frame.', []);
            app.makeLabel(kxyz, 1, 3, 'Y (km):');
            app.KfAnchorYEditField = app.makeNumField(kxyz, 1, 4, 0, [-Inf Inf], 'Anchor Y coordinate in the chosen frame.', []);
            app.makeLabel(kxyz, 1, 5, 'Z (km):');
            app.KfAnchorZEditField = app.makeNumField(kxyz, 1, 6, 0, [-Inf Inf], 'Anchor Z coordinate in the chosen frame.', []);
            app.makeLabel(kxyz, 2, 1, 'Frame:');
            app.KfAnchorFrameSelector = referenceFrameSelectComp(kxyz);
            app.KfAnchorFrameSelector.Layout.Row = 2;
            app.KfAnchorFrameSelector.Layout.Column = [2 4];
            app.KfAnchorFromCurrentButton = uibutton(kxyz, 'push');
            app.KfAnchorFromCurrentButton.Text = 'Set From Current Camera';
            app.KfAnchorFromCurrentButton.Tooltip = 'Use the main window''s current camera position (expressed in the chosen frame) as this keyframe''s fixed anchor.';
            app.KfAnchorFromCurrentButton.Layout.Row = 2;
            app.KfAnchorFromCurrentButton.Layout.Column = [5 6];
            app.KfAnchorFromCurrentButton.ButtonPushedFcn = @(~,~) app.setKeyframeAnchorFromCamera();

            %GroundObject: label + dropdown
            kgo = uigridlayout(gk, [1 2]);
            kgo.Layout.Row = 2;
            kgo.Layout.Column = 1;
            kgo.RowHeight = {28};
            kgo.ColumnWidth = {'fit', '1x'};
            kgo.Padding = [0 0 0 0];
            app.KfGroundObjSubGrid = kgo;
            app.makeLabel(kgo, 1, 1, 'Ground object:');
            app.KfAnchorGroundObjectDropDown = uidropdown(kgo);
            app.KfAnchorGroundObjectDropDown.Items = {'(none)'};
            app.KfAnchorGroundObjectDropDown.ItemsData = {[]};
            app.KfAnchorGroundObjectDropDown.Tooltip = 'The ground object the camera sits on and tracks the vehicle from for this keyframe.';
            app.KfAnchorGroundObjectDropDown.Layout.Row = 1;
            app.KfAnchorGroundObjectDropDown.Layout.Column = 2;

            %GeometricPoint: label + dropdown
            kgp = uigridlayout(gk, [1 2]);
            kgp.Layout.Row = 2;
            kgp.Layout.Column = 1;
            kgp.RowHeight = {28};
            kgp.ColumnWidth = {'fit', '1x'};
            kgp.Padding = [0 0 0 0];
            app.KfGeomPtSubGrid = kgp;
            app.makeLabel(kgp, 1, 1, 'Geometric point:');
            app.KfAnchorGeometricPointDropDown = uidropdown(kgp);
            app.KfAnchorGeometricPointDropDown.Items = {'(none)'};
            app.KfAnchorGeometricPointDropDown.ItemsData = {[]};
            app.KfAnchorGeometricPointDropDown.Tooltip = 'The (vehicle-independent) geometric point the camera sits on and tracks the vehicle from for this keyframe.';
            app.KfAnchorGeometricPointDropDown.Layout.Row = 1;
            app.KfAnchorGeometricPointDropDown.Layout.Column = 2;

            app.ApplyKeyframeButton = uibutton(g, 'push');
            app.ApplyKeyframeButton.Text = 'Apply Keyframe Changes';
            app.ApplyKeyframeButton.Layout.Row = 7;
            app.ApplyKeyframeButton.Layout.Column = [1 8];
            app.ApplyKeyframeButton.ButtonPushedFcn = @(~,~) app.applyKeyframeEdits();
        end

        function createFixedAnchorPanel(app)
            %createFixedAnchorPanel The "Fixed Camera (Tracking)" controls:
            %an anchor type, and the anchor-specific inputs (fixed XYZ in a
            %chosen frame, a ground object, or a geometric point).  The whole
            %panel enables only in FixedAnchor mode; the anchor-specific rows
            %show/hide with the anchor type.
            app.FixedAnchorPanel = uipanel(app.CameraGrid, 'Title', 'Fixed Camera (Tracking)');
            app.FixedAnchorPanel.Layout.Row = 4;
            app.FixedAnchorPanel.Layout.Column = [1 2];
            g = uigridlayout(app.FixedAnchorPanel, [2 1]);
            g.RowHeight = {24, '1x'};
            g.ColumnWidth = {'1x'};
            g.Padding = [5 5 5 5];
            g.RowSpacing = 6;
            app.FixedAnchorGrid = g;

            %row 1 (always shown): anchor type + view angle
            header = uigridlayout(g, [1 4]);
            header.Layout.Row = 1;
            header.Layout.Column = 1;
            header.ColumnWidth = {'fit', '1x', 'fit', '1x'};
            header.Padding = [0 0 0 0];
            app.makeLabel(header, 1, 1, 'Anchor:');
            app.AnchorTypeDropDown = uidropdown(header);
            app.AnchorTypeDropDown.Items = LvdCameraAnchorTypeEnum.getListBoxStr();
            app.AnchorTypeDropDown.Tooltip = 'Fixed Coordinates: an XYZ point in a chosen reference frame (a body-fixed frame rotates with the planet, like a pad; an inertial one stays put).  Ground Object / Geometric Point: track from one of the mission''s objects.';
            app.AnchorTypeDropDown.Layout.Row = 1;
            app.AnchorTypeDropDown.Layout.Column = 2;
            app.AnchorTypeDropDown.ValueChangedFcn = @(~,~) app.onAnchorTypeChanged();
            app.makeLabel(header, 1, 3, 'View angle (deg):');
            app.AnchorViewAngleEditField = uieditfield(header, 'text');
            app.AnchorViewAngleEditField.Tooltip = 'Camera field of view.  Leave blank to keep the current view angle (the vehicle naturally shrinks with distance).';
            app.AnchorViewAngleEditField.Layout.Row = 1;
            app.AnchorViewAngleEditField.Layout.Column = 4;
            app.AnchorViewAngleEditField.ValueChangedFcn = @(~,~) app.onAnchorViewAngleChanged();

            %row 2 (anchor-specific): three sub-grids sharing the same cell, only
            %one shown at a time -> no empty reserved rows for the hidden types.

            %FixedXYZ: X/Y/Z, then frame + "set from current camera"
            xyz = uigridlayout(g, [2 6]);
            xyz.Layout.Row = 2;
            xyz.Layout.Column = 1;
            xyz.RowHeight = {28, 28};
            xyz.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x'};
            xyz.Padding = [0 0 0 0];
            app.FixedXYZSubGrid = xyz;
            app.makeLabel(xyz, 1, 1, 'X (km):');
            app.AnchorXEditField = app.makeNumField(xyz, 1, 2, 0, [-Inf Inf], 'Anchor X coordinate in the chosen frame.', @(~,~) app.onAnchorFixedFieldChanged());
            app.makeLabel(xyz, 1, 3, 'Y (km):');
            app.AnchorYEditField = app.makeNumField(xyz, 1, 4, 0, [-Inf Inf], 'Anchor Y coordinate in the chosen frame.', @(~,~) app.onAnchorFixedFieldChanged());
            app.makeLabel(xyz, 1, 5, 'Z (km):');
            app.AnchorZEditField = app.makeNumField(xyz, 1, 6, 0, [-Inf Inf], 'Anchor Z coordinate in the chosen frame.', @(~,~) app.onAnchorFixedFieldChanged());
            app.makeLabel(xyz, 2, 1, 'Frame:');
            app.AnchorFrameSelector = referenceFrameSelectComp(xyz);
            app.AnchorFrameSelector.Layout.Row = 2;
            app.AnchorFrameSelector.Layout.Column = [2 4];
            app.AnchorFromCurrentButton = uibutton(xyz, 'push');
            app.AnchorFromCurrentButton.Text = 'Set From Current Camera';
            app.AnchorFromCurrentButton.Tooltip = 'Use the main window''s current camera position (expressed in the chosen frame) as the fixed anchor.';
            app.AnchorFromCurrentButton.Layout.Row = 2;
            app.AnchorFromCurrentButton.Layout.Column = [5 6];
            app.AnchorFromCurrentButton.ButtonPushedFcn = @(~,~) app.setFixedAnchorFromCamera();

            %GroundObject: label + dropdown
            go = uigridlayout(g, [1 2]);
            go.Layout.Row = 2;
            go.Layout.Column = 1;
            go.RowHeight = {28};
            go.ColumnWidth = {'fit', '1x'};
            go.Padding = [0 0 0 0];
            app.GroundObjSubGrid = go;
            app.makeLabel(go, 1, 1, 'Ground object:');
            app.AnchorGroundObjectDropDown = uidropdown(go);
            app.AnchorGroundObjectDropDown.Items = {'(none)'};
            app.AnchorGroundObjectDropDown.ItemsData = {[]};
            app.AnchorGroundObjectDropDown.Tooltip = 'The ground object the camera sits on and tracks the vehicle from.';
            app.AnchorGroundObjectDropDown.Layout.Row = 1;
            app.AnchorGroundObjectDropDown.Layout.Column = 2;
            app.AnchorGroundObjectDropDown.ValueChangedFcn = @(~,~) app.onAnchorGroundObjChanged();

            %GeometricPoint: label + dropdown
            gp = uigridlayout(g, [1 2]);
            gp.Layout.Row = 2;
            gp.Layout.Column = 1;
            gp.RowHeight = {28};
            gp.ColumnWidth = {'fit', '1x'};
            gp.Padding = [0 0 0 0];
            app.GeomPtSubGrid = gp;
            app.makeLabel(gp, 1, 1, 'Geometric point:');
            app.AnchorGeometricPointDropDown = uidropdown(gp);
            app.AnchorGeometricPointDropDown.Items = {'(none)'};
            app.AnchorGeometricPointDropDown.ItemsData = {[]};
            app.AnchorGeometricPointDropDown.Tooltip = 'The (vehicle-independent) geometric point the camera sits on and tracks the vehicle from.';
            app.AnchorGeometricPointDropDown.Layout.Row = 1;
            app.AnchorGeometricPointDropDown.Layout.Column = 2;
            app.AnchorGeometricPointDropDown.ValueChangedFcn = @(~,~) app.onAnchorGeomPtChanged();
        end

        function createMeshTab(app)
            app.MeshTab = uitab(app.TabGroup, 'Title', 'Vehicle Mesh');
            app.MeshTab.Tooltip = 'Vehicle mesh of the active view profile (the geometry is stored in the mission file).';
            app.MeshGrid = uigridlayout(app.MeshTab, [5 2]);
            app.MeshGrid.RowHeight = {24, 30, 160, 70, 220};   %fixed preview row so the tab scrolls when the window is short
            app.MeshGrid.ColumnWidth = {'1x', '1x'};
            app.MeshGrid.Scrollable = 'on';

            app.MeshEnabledCheckBox = uicheckbox(app.MeshGrid);
            app.MeshEnabledCheckBox.Text = 'Show vehicle mesh in the 3-D view';
            app.MeshEnabledCheckBox.Layout.Row = 1;
            app.MeshEnabledCheckBox.Layout.Column = 1;
            app.MeshEnabledCheckBox.ValueChangedFcn = @(~,~) app.onMeshFieldChanged();
            app.MeshPathLabel = uilabel(app.MeshGrid);
            app.MeshPathLabel.Text = '<no mesh imported>';
            app.MeshPathLabel.FontAngle = 'italic';
            app.MeshPathLabel.Layout.Row = 1;
            app.MeshPathLabel.Layout.Column = 2;

            fileGrid = uigridlayout(app.MeshGrid, [1 4]);
            fileGrid.RowHeight = {'1x'};
            fileGrid.ColumnWidth = {'1.3x', '1x', '1x', '1.2x'};
            fileGrid.Padding = [0 0 0 0];
            fileGrid.Layout.Row = 2;
            fileGrid.Layout.Column = [1 2];
            app.ImportMeshButton = app.makeButton(fileGrid, 1, 'Import Mesh (STL / OBJ)...', 'Load a mesh file; its geometry is stored in the mission and scaled to the "Fit longest side to" length.', @(~,~) app.onImportMeshButton());
            app.ReloadMeshButton = app.makeButton(fileGrid, 2, 'Reload From File', 'Re-read the mesh from its source file.', @(~,~) app.onReloadMeshButton());
            app.ClearMeshButton = app.makeButton(fileGrid, 3, 'Clear Mesh', 'Remove the mesh from this view profile.', @(~,~) app.clearMesh());
            app.ShowInChaseButton = app.makeButton(fileGrid, 4, 'Show in Chase Camera', 'Switch the camera to Chase mode at a range that frames the mesh.', @(~,~) app.showMeshInChaseCamera());

            app.MeshTransformPanel = uipanel(app.MeshGrid, 'Title', 'Mesh to Body Frame Transform');
            app.MeshTransformPanel.Layout.Row = 3;
            app.MeshTransformPanel.Layout.Column = [1 2];
            g = uigridlayout(app.MeshTransformPanel, [4 6]);
            g.RowHeight = {24, 24, 24, 'fit'};
            g.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit', '1x'};
            app.MeshTransformGrid = g;
            app.makeLabel(g, 1, 1, 'Scale (km per mesh unit):');
            app.MeshScaleEditField = app.makeNumField(g, 1, 2, 1, [1e-15 Inf], 'Multiply mesh coordinates by this to get km.  A mesh in metres needs 0.001 for true scale, which is far too small to render in a planet-sized scene.', @(~,~) app.onMeshFieldChanged());
            app.makeLabel(g, 1, 3, 'Fit longest side to (km):');
            app.FitLengthEditField = app.makeNumField(g, 1, 4, 1, [1e-12 Inf], 'Display length of the mesh''s longest bounding-box side.  Applied automatically on import; default 2% of the central body radius.', []);
            app.FitButton = app.makeButton(g, 5, 'Fit', 'Set the scale so the mesh''s longest side has the length on the left.', @(~,~) app.onFitButton());
            app.FitButton.Layout.Row = 1;
            app.FitButton.Layout.Column = [5 6];

            app.MeshScaleNoteLabel = uilabel(g);
            app.MeshScaleNoteLabel.Text = ['The mesh is a display model: the scene spans thousands of km and its depth buffer cannot resolve a ' ...
                                           'true-scale vehicle (a few tens of metres), which vanishes and blanks close-up views.  Keep the ' ...
                                           'longest side at roughly 1-5% of the body radius and use the chase camera to look at it.'];
            app.MeshScaleNoteLabel.WordWrap = 'on';
            app.MeshScaleNoteLabel.FontAngle = 'italic';
            app.MeshScaleNoteLabel.FontSize = 11;
            app.MeshScaleNoteLabel.Layout.Row = 4;
            app.MeshScaleNoteLabel.Layout.Column = [1 6];

            app.makeLabel(g, 2, 1, 'Rotation yaw / pitch / roll (deg):');
            app.MeshYawEditField = app.makeNumField(g, 2, 2, 0, [-Inf Inf], 'Rotation about the mesh Z axis (applied first: R = Rz*Ry*Rx).', @(~,~) app.onMeshFieldChanged());
            app.MeshPitchEditField = app.makeNumField(g, 2, 3, 0, [-Inf Inf], 'Rotation about the mesh Y axis.', @(~,~) app.onMeshFieldChanged());
            app.MeshRollEditField = app.makeNumField(g, 2, 4, 0, [-Inf Inf], 'Rotation about the mesh X axis.', @(~,~) app.onMeshFieldChanged());

            app.makeLabel(g, 3, 1, 'Translation X / Y / Z (km, body frame):');
            app.MeshTransXEditField = app.makeNumField(g, 3, 2, 0, [-Inf Inf], 'Offset of the mesh origin from the vehicle centre, body X.', @(~,~) app.onMeshFieldChanged());
            app.MeshTransYEditField = app.makeNumField(g, 3, 3, 0, [-Inf Inf], 'Offset of the mesh origin from the vehicle centre, body Y.', @(~,~) app.onMeshFieldChanged());
            app.MeshTransZEditField = app.makeNumField(g, 3, 4, 0, [-Inf Inf], 'Offset of the mesh origin from the vehicle centre, body Z.', @(~,~) app.onMeshFieldChanged());

            app.MeshAppearancePanel = uipanel(app.MeshGrid, 'Title', 'Appearance');
            app.MeshAppearancePanel.Layout.Row = 4;
            app.MeshAppearancePanel.Layout.Column = [1 2];
            g2 = uigridlayout(app.MeshAppearancePanel, [1 6]);
            g2.RowHeight = {26};
            g2.ColumnWidth = {'1x', 'fit', '1x', '1x', '1x', '1x'};
            app.MeshAppearanceGrid = g2;
            app.MeshFaceColorButton = app.makeButton(g2, 1, 'Face Colour...', 'Pick the mesh face colour.', @(~,~) app.onColorButton('face'));
            app.makeLabel(g2, 1, 2, 'Opacity:');
            app.MeshAlphaSpinner = uispinner(g2);
            app.MeshAlphaSpinner.Limits = [0 1];
            app.MeshAlphaSpinner.Step = 0.1;
            app.MeshAlphaSpinner.Value = 1;
            app.MeshAlphaSpinner.Layout.Row = 1;
            app.MeshAlphaSpinner.Layout.Column = 3;
            app.MeshAlphaSpinner.ValueChangedFcn = @(~,~) app.onMeshFieldChanged();
            app.MeshShowEdgesCheckBox = uicheckbox(g2);
            app.MeshShowEdgesCheckBox.Text = 'Show edges';
            app.MeshShowEdgesCheckBox.Layout.Row = 1;
            app.MeshShowEdgesCheckBox.Layout.Column = 4;
            app.MeshShowEdgesCheckBox.ValueChangedFcn = @(~,~) app.onMeshFieldChanged();
            app.MeshEdgeColorButton = app.makeButton(g2, 5, 'Edge Colour...', 'Pick the mesh edge colour.', @(~,~) app.onColorButton('edge'));
            app.MeshLightingCheckBox = uicheckbox(g2);
            app.MeshLightingCheckBox.Text = 'Lit by the Sun';
            app.MeshLightingCheckBox.Value = true;
            app.MeshLightingCheckBox.Layout.Row = 1;
            app.MeshLightingCheckBox.Layout.Column = 6;
            app.MeshLightingCheckBox.ValueChangedFcn = @(~,~) app.onMeshFieldChanged();

            previewGrid = uigridlayout(app.MeshGrid, [2 1]);
            previewGrid.RowHeight = {'1x', 'fit'};
            previewGrid.ColumnWidth = {'1x'};
            previewGrid.Padding = [0 0 0 0];
            previewGrid.Layout.Row = 5;
            previewGrid.Layout.Column = [1 2];
            app.MeshPreviewAxes = uiaxes(previewGrid);
            app.MeshPreviewAxes.Layout.Row = 1;
            app.MeshPreviewAxes.Layout.Column = 1;
            app.MeshPreviewAxes.Tag = 'LvdMeshPreviewAxes';
            view(app.MeshPreviewAxes, 3);
            grid(app.MeshPreviewAxes, 'on');
            xlabel(app.MeshPreviewAxes, 'X'); ylabel(app.MeshPreviewAxes, 'Y'); zlabel(app.MeshPreviewAxes, 'Z');
            app.MeshInfoLabel = uilabel(previewGrid);
            app.MeshInfoLabel.Text = 'No mesh loaded.';
            app.MeshInfoLabel.HorizontalAlignment = 'center';
            app.MeshInfoLabel.WordWrap = 'on';
            app.MeshInfoLabel.Layout.Row = 2;
            app.MeshInfoLabel.Layout.Column = 1;
        end

        function createOverlayTab(app)
            app.OverlayTab = uitab(app.TabGroup, 'Title', 'Data Overlay');
            app.OverlayTab.Tooltip = 'Text block of mission quantities drawn on the 3-D view (and into exported video/images); saved on the active view profile.';
            app.OverlayGrid = uigridlayout(app.OverlayTab, [4 2]);
            app.OverlayGrid.RowHeight = {24, 300, 215, 44};   %all fixed so the tab scrolls (never collapses the panels) when the window is short
            app.OverlayGrid.ColumnWidth = {'1x', '1.15x'};
            app.OverlayGrid.Scrollable = 'on';

            app.OverlayEnabledCheckBox = uicheckbox(app.OverlayGrid);
            app.OverlayEnabledCheckBox.Text = 'Show the data overlay on the 3-D view (it is included in exported video and images)';
            app.OverlayEnabledCheckBox.Layout.Row = 1;
            app.OverlayEnabledCheckBox.Layout.Column = [1 2];
            app.OverlayEnabledCheckBox.ValueChangedFcn = @(~,~) app.onOverlayFieldChanged();

            %left column: what is shown, how it looks
            app.OverlayLeftGrid = uigridlayout(app.OverlayGrid, [2 1]);
            app.OverlayLeftGrid.RowHeight = {130, 164};   %both panels at their full content height (4 x 24 px rows + spacing + title)
            app.OverlayLeftGrid.ColumnWidth = {'1x'};
            app.OverlayLeftGrid.Padding = [0 0 0 0];
            app.OverlayLeftGrid.Layout.Row = 2;
            app.OverlayLeftGrid.Layout.Column = 1;

            app.OverlayContentPanel = uipanel(app.OverlayLeftGrid, 'Title', 'Header lines');
            app.OverlayContentPanel.Layout.Row = 1;
            app.OverlayContentPanel.Layout.Column = 1;
            gc = uigridlayout(app.OverlayContentPanel, [3 2]);
            gc.RowHeight = {24, 24, 24};
            gc.ColumnWidth = {'1x', '1x'};
            app.OverlayContentGrid = gc;
            app.OverlayTitleEditField = uieditfield(gc, 'text');
            app.OverlayTitleEditField.Placeholder = 'Title line (optional)';
            app.OverlayTitleEditField.Tooltip = 'Free text shown as the first line of the overlay, e.g. the mission name.';
            app.OverlayTitleEditField.Layout.Row = 1;
            app.OverlayTitleEditField.Layout.Column = [1 2];
            app.OverlayTitleEditField.ValueChangedFcn = @(~,~) app.onOverlayFieldChanged();
            app.OverlayShowEpochCheckBox = app.makeCheck(gc, 2, 1, 'Epoch (date/time)', 'The universal time as a calendar epoch.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayShowUtCheckBox = app.makeCheck(gc, 2, 2, 'UT (seconds)', 'The universal time in seconds.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayShowMetCheckBox = app.makeCheck(gc, 3, 1, 'Mission elapsed time', 'Time since the first logged state, as [days] hh:mm:ss.sss.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayShowEventCheckBox = app.makeCheck(gc, 3, 2, 'Current event', 'Number and name of the event(s) active at the displayed time.', @(~,~) app.onOverlayFieldChanged());

            app.OverlayStylePanel = uipanel(app.OverlayLeftGrid, 'Title', 'Position and style');
            app.OverlayStylePanel.Layout.Row = 2;
            app.OverlayStylePanel.Layout.Column = 1;
            gs = uigridlayout(app.OverlayStylePanel, [4 4]);
            gs.RowHeight = {24, 24, 24, 24};
            gs.ColumnWidth = {'fit', '1x', 'fit', '1x'};
            app.OverlayStyleGrid = gs;
            app.makeLabel(gs, 1, 1, 'Corner:');
            app.OverlayCornerDropDown = uidropdown(gs);
            app.OverlayCornerDropDown.Items = {'Top Left'};
            app.OverlayCornerDropDown.Tooltip = 'Which corner of the 3-D view the overlay is anchored to.';
            app.OverlayCornerDropDown.Layout.Row = 1;
            app.OverlayCornerDropDown.Layout.Column = 2;
            app.OverlayCornerDropDown.ValueChangedFcn = @(~,~) app.onOverlayFieldChanged();
            app.makeLabel(gs, 1, 3, 'Margin (% of view):');
            app.OverlayMarginSpinner = app.makeSpinner(gs, 1, 4, 2, [0 45], 0.5, 'Distance from the corner, as a percentage of the view size.', @(~,~) app.onOverlayFieldChanged());
            app.makeLabel(gs, 2, 1, 'Font:');
            app.OverlayFontNameDropDown = uidropdown(gs);
            app.OverlayFontNameDropDown.Items = {'Helvetica'};
            app.OverlayFontNameDropDown.Layout.Row = 2;
            app.OverlayFontNameDropDown.Layout.Column = 2;
            app.OverlayFontNameDropDown.ValueChangedFcn = @(~,~) app.onOverlayFieldChanged();
            app.makeLabel(gs, 2, 3, 'Size (pt):');
            app.OverlayFontSizeSpinner = app.makeSpinner(gs, 2, 4, 12, [4 72], 1, 'Font size in points.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayBoldCheckBox = app.makeCheck(gs, 3, 1, 'Bold', 'Bold text.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayBoldCheckBox.Layout.Column = [1 2];
            app.OverlayFontColorButton = app.makeButton(gs, 3, 'Text Colour...', 'Pick the text colour.', @(~,~) app.onOverlayColorButton('font'));
            app.OverlayFontColorButton.Layout.Row = 3;
            app.OverlayFontColorButton.Layout.Column = [3 4];
            app.OverlayBackgroundCheckBox = app.makeCheck(gs, 4, 1, 'Background box', 'Draw a filled box behind the text for legibility.', @(~,~) app.onOverlayFieldChanged());
            app.OverlayBackgroundCheckBox.Layout.Column = [1 2];
            app.OverlayBackgroundColorButton = app.makeButton(gs, 3, 'Box Colour...', 'Pick the background box colour.', @(~,~) app.onOverlayColorButton('background'));
            app.OverlayBackgroundColorButton.Layout.Row = 4;
            app.OverlayBackgroundColorButton.Layout.Column = [3 4];

            %right column: the quantities
            app.OverlayQuantitiesPanel = uipanel(app.OverlayGrid, 'Title', 'Quantities shown (edit Label, Decimals, Format and Units in the table)');
            app.OverlayQuantitiesPanel.Layout.Row = 2;
            app.OverlayQuantitiesPanel.Layout.Column = 2;
            gq = uigridlayout(app.OverlayQuantitiesPanel, [2 1]);
            gq.RowHeight = {'1x', 30};
            gq.ColumnWidth = {'1x'};
            app.OverlayQuantitiesGrid = gq;
            app.OverlayTable = uitable(gq);
            app.OverlayTable.ColumnName = {'Quantity', 'Frame', 'Label', 'Decimals', 'Format', 'Units'};
            app.OverlayTable.ColumnWidth = {'auto', 110, 90, 60, 80, 45};
            app.OverlayTable.ColumnEditable = [false false true true true true];
            app.OverlayTable.ColumnFormat = {'char', 'char', 'char', 'numeric', {'Fixed', 'Scientific', 'Auto'}, 'logical'};
            app.OverlayTable.RowName = {};
            app.OverlayTable.SelectionType = 'row';
            app.OverlayTable.Multiselect = 'off';
            app.OverlayTable.Tooltip = {'Label: blank uses the quantity name.  Decimals: digits after the decimal point.  Format: Fixed 1234.568, Scientific 1.235e+03, Auto shortest.  Units: append the unit.'};
            app.OverlayTable.Layout.Row = 1;
            app.OverlayTable.Layout.Column = 1;
            app.OverlayTable.SelectionChangedFcn = @(~,~) app.onOverlayTableSelection();
            app.OverlayTable.CellEditCallback = @(~,evt) app.onOverlayCellEdit(evt);
            app.OverlayItemButtonGrid = uigridlayout(gq, [1 3]);
            app.OverlayItemButtonGrid.RowHeight = {'1x'};
            app.OverlayItemButtonGrid.ColumnWidth = {'1x', '1x', '1x'};
            app.OverlayItemButtonGrid.Padding = [0 0 0 0];
            app.OverlayItemButtonGrid.Layout.Row = 2;
            app.OverlayItemButtonGrid.Layout.Column = 1;
            app.OverlayRemoveButton = app.makeButton(app.OverlayItemButtonGrid, 1, 'Remove', 'Remove the selected quantity from the overlay', @(~,~) app.removeOverlayItem());
            app.OverlayMoveUpButton = app.makeButton(app.OverlayItemButtonGrid, 2, 'Move Up', 'Show the selected quantity one line higher', @(~,~) app.moveOverlayItem(app.SelectedOverlayInd, -1));
            app.OverlayMoveDownButton = app.makeButton(app.OverlayItemButtonGrid, 3, 'Move Down', 'Show the selected quantity one line lower', @(~,~) app.moveOverlayItem(app.SelectedOverlayInd, 1));

            %bottom: add a quantity
            app.OverlayAddPanel = uipanel(app.OverlayGrid, 'Title', 'Add a quantity: search, pick it, choose its reference frame, press Add');
            app.OverlayAddPanel.Layout.Row = 3;
            app.OverlayAddPanel.Layout.Column = [1 2];
            ga = uigridlayout(app.OverlayAddPanel, [3 2]);
            ga.RowHeight = {24, '1x', 30};
            ga.ColumnWidth = {'1x', '1x'};
            app.OverlayAddGrid = ga;
            app.OverlaySearchEditField = uieditfield(ga, 'text');
            app.OverlaySearchEditField.Placeholder = 'Search quantities (e.g. altitude, throttle, eccentricity)...';
            app.OverlaySearchEditField.Tooltip = 'Type to filter the Graphical Analysis quantities below.';
            app.OverlaySearchEditField.Layout.Row = 1;
            app.OverlaySearchEditField.Layout.Column = 1;
            app.OverlaySearchEditField.ValueChangingFcn = @(~,evt) app.onOverlaySearchChanging(evt);
            app.OverlaySearchEditField.ValueChangedFcn = @(src,~) app.filterOverlayTasks(src.Value);
            app.OverlayTaskListBox = uilistbox(ga);
            app.OverlayTaskListBox.Items = {};
            app.OverlayTaskListBox.Multiselect = 'off';
            app.OverlayTaskListBox.Tooltip = 'Every Graphical Analysis quantity; the same list as the Graphical Analysis tool.';
            app.OverlayTaskListBox.Layout.Row = [2 3];
            app.OverlayTaskListBox.Layout.Column = 1;
            app.OverlayFrameLabel = uilabel(ga);
            app.OverlayFrameLabel.Text = 'Reference frame for the quantity (its origin body is the reference body):';
            app.OverlayFrameLabel.WordWrap = 'on';
            app.OverlayFrameLabel.Layout.Row = 1;
            app.OverlayFrameLabel.Layout.Column = 2;
            app.OverlayFrameSelector = referenceFrameSelectComp(ga);
            app.OverlayFrameSelector.Layout.Row = 2;
            app.OverlayFrameSelector.Layout.Column = 2;
            app.OverlayAddButton = uibutton(ga, 'push');
            app.OverlayAddButton.Text = 'Add Selected Quantity to Overlay';
            app.OverlayAddButton.Layout.Row = 3;
            app.OverlayAddButton.Layout.Column = 2;
            app.OverlayAddButton.ButtonPushedFcn = @(~,~) app.addSelectedOverlayQuantity();

            app.OverlayPreviewLabel = uilabel(app.OverlayGrid);
            app.OverlayPreviewLabel.Text = 'Preview:';
            app.OverlayPreviewLabel.WordWrap = 'on';
            app.OverlayPreviewLabel.FontName = 'Courier New';
            app.OverlayPreviewLabel.FontSize = 11;
            app.OverlayPreviewLabel.Tooltip = 'What the overlay reads at the current playback time.';
            app.OverlayPreviewLabel.Layout.Row = 4;
            app.OverlayPreviewLabel.Layout.Column = [1 2];
        end

        function lbl = makeLabel(~, parent, row, col, text)
            lbl = uilabel(parent);
            lbl.Text = text;
            lbl.HorizontalAlignment = 'right';
            lbl.Layout.Row = row;
            lbl.Layout.Column = col;
        end

        function cb = makeCheck(~, parent, row, col, text, tooltip, changedFcn)
            cb = uicheckbox(parent);
            cb.Text = text;
            cb.Tooltip = tooltip;
            cb.Layout.Row = row;
            cb.Layout.Column = col;
            cb.ValueChangedFcn = changedFcn;
        end

        function sp = makeSpinner(~, parent, row, col, value, limits, step, tooltip, changedFcn)
            sp = uispinner(parent);
            sp.Limits = limits;
            sp.Step = step;
            sp.Value = value;
            sp.Tooltip = tooltip;
            sp.Layout.Row = row;
            sp.Layout.Column = col;
            sp.ValueChangedFcn = changedFcn;
        end

        function f = makeNumField(~, parent, row, col, value, limits, tooltip, changedFcn)
            f = uieditfield(parent, 'numeric');
            f.Limits = limits;
            f.Value = value;
            f.Tooltip = tooltip;
            f.Layout.Row = row;
            f.Layout.Column = col;
            if(not(isempty(changedFcn)))
                f.ValueChangedFcn = changedFcn;
            end
        end

        function b = makeButton(~, parent, col, text, tooltip, pushedFcn)
            b = uibutton(parent, 'push');
            b.Text = text;
            b.Tooltip = tooltip;
            b.Layout.Row = 1;
            b.Layout.Column = col;
            b.ButtonPushedFcn = pushedFcn;
        end
    end

    methods (Static, Access = private)
        function tf = updateProgress(dlg, k, n)
            tf = false;
            if(isempty(dlg) || not(isvalid(dlg)))
                return;
            end
            dlg.Value = (k-1)/n;
            dlg.Message = sprintf('Rendering frame %u of %u...', k, n);
            tf = dlg.CancelRequested;
        end
    end

    methods (Static)
        function s = onOff(tf)
            if(tf)
                s = 'on';
            else
                s = 'off';
            end
        end
    end
end

function closeIfValid(dlg)
    if(not(isempty(dlg)) && isvalid(dlg))
        close(dlg);
    end
end
