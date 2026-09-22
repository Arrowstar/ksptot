function lvd_renderSceneAtTime(time, lvdData, handles, app, drawMode)
%lvd_renderSceneAtTime Renders the LVD 3-D view (and ground track) at one
%instant: every time-dependent marker, the vehicle mesh, the scene camera,
%lighting and the epoch label.
%
%   lvd_renderSceneAtTime(time, lvdData, handles, app)
%   lvd_renderSceneAtTime(time, lvdData, handles, app, drawMode)
%
%   drawMode: "limitrate" (default, what the time slider uses),
%             "full" (plain drawnow, frame-exact for playback/export),
%             "none" (caller flushes)
%
%   This is the un-throttled body of the time slider callback
%   (timeSliderStateChanged), split out so playback and video export can
%   render frames without the slider's 50 ms rate limit.

    arguments
        time(1,1) double
        lvdData LvdData
        handles struct %#ok<INUSA> kept for signature parity with the slider callback
        app ma_LvdMainGUI_App
        drawMode(1,1) string {mustBeMember(drawMode, ["limitrate", "full", "none"])} = "limitrate"
    end

    hAx = app.dispAxes;
    grdTrkAx = app.GroundTrackAxes;

    %clamp to the slider range so playback never asks for a time the
    %interpolants do not cover
    try
        lims = app.DispAxesTimeSlider.Limits;
        if(all(isfinite(lims)))
            time = min(max(time, lims(1)), lims(2));
        end
    catch
    end

    profile = lvdData.viewSettings.selViewProfile;

    markerTrajData = profile.markerTrajData;
    markerBodyData = profile.markerBodyData;
    markerBodyAxesData = profile.markerTrajAxesData;
    markerGrdObjData = profile.markerGrdObjData;
    centralBodyData = profile.centralBodyData;
    pointData = profile.pointData;
    vectorData = profile.vectorData;
    refFrameData = profile.refFrameData;
    angleData = profile.angleData;
    planeData = profile.planeData;
    sensorData = profile.sensorData;
    sensorTgtData = profile.sensorTgtData;
    vehGrdTrkData = profile.vehicleGrdTrackData;
    celBodyGrdTrackData = profile.celBodyGrdTrackData;
    grdObjGrdTrkData = profile.grdObjGrdTrackData;
    geomPtGrdTrackData = profile.geomPtGrdTrackData;
    vehicleMeshData = profile.markerVehicleMeshData;

    if(not(isempty(markerTrajData)))
        markerTrajData.plotBodyMarkerAtTime(time, hAx);
    end

    for(i=1:length(markerBodyData)) %#ok<*NO4LP>
        markerBodyData(i).plotBodyMarkerAtTime(time, hAx);
    end

    if(not(isempty(markerBodyAxesData)))
        markerBodyAxesData.plotBodyAxesAtTime(time, hAx);
    end

    for(i=1:length(vehicleMeshData))
        vehicleMeshData(i).plotVehicleMeshAtTime(time, hAx);
    end

    overlayData = profile.markerOverlayData;
    for(i=1:length(overlayData))
        try
            overlayData(i).plotOverlayAtTime(time, hAx);
        catch ME
            warning('lvd_renderSceneAtTime:overlay', 'Data overlay update failed: %s', ME.message);
        end
    end

    for(i=1:length(markerGrdObjData))
        markerGrdObjData(i).plotBodyMarkerAtTime(time, hAx);
    end

    for(i=1:length(refFrameData))
        refFrameData(i).plotRefFrameAtTime(time, hAx);
    end

    for(i=1:length(vectorData))
        vectorData(i).plotVectorAtTime(time, hAx);
    end

    for(i=1:length(angleData))
        angleData(i).plotAngleAtTime(time, hAx);
    end

    for(i=1:length(planeData))
        planeData(i).plotPlaneAtTime(time, hAx);
    end

    for(i=1:length(pointData))
        pointData(i).plotPointAtTime(time, hAx);
    end

    sensorTgtResults = SensorTargetResults.empty(1,0);
    for(i=1:length(sensorData))
        subResults = sensorData(i).plotSensorAtTime(time, hAx);
        sensorTgtResults = horzcat(sensorTgtResults, subResults(:)'); %#ok<AGROW>
    end

    if(numel(sensorTgtResults) > 0)
        mergedResults = SensorTargetResults.mergeResults(sensorTgtResults);
        for(i=1:length(sensorTgtData))
            sensorTgtData(i).plotTargetResults(mergedResults, hAx);
        end
    end

    if(not(isempty(centralBodyData)))
        centralBodyData.setCentralBodyRotation(time);
    end

    if(not(isempty(profile.sunLighting)))
        profile.updateLightPosition(time);
    end

    %F8-unit-scale: nest any newly created scene graphics under the
    %normalization transform so the longest axes span stays ~1.  Must run
    %after the per-frame markers are created but before the camera is
    %driven (the camera works in scaled units).
    try
        LvdSceneNormalizer.reparentSceneChildren(hAx);
    catch
    end

    %F8: scene camera (Chase / Scripted); Manual leaves the camera alone
    try
        driver = profile.getCameraDriver();
        stateLog = lvdData.stateLog;
        timeResolverFcn = @(kf) kf.resolveTime(stateLog);
        vehPosFcn = @(t) LaunchVehicleViewProfile.firstVehPosAtTime(profile.vehPosVelInterp, t);
        driver.applyAtTime(time, hAx, timeResolverFcn, vehPosFcn);

        %the mouse keeps working in every camera mode: a drag retunes the
        %chase offsets in Chase mode and hands the camera back to the user
        %in Scripted mode (see LvdSceneCameraDriver.onUserCameraDrag)
        handler = lvd_getMouseCameraHandler(app);
        slider = app.DispAxesTimeSlider;
        timeFcn = @() lvd_lastRenderedTime(slider, time);
        driver.attach(hAx, app.ma_LvdMainGUI, handler, timeFcn, vehPosFcn);
        driver.setUndoFcn(@(label) app.lvdEnhancementsAddUndo(label));
        if(not(isempty(handler)))
            handler.cameraDragFcn = @(ax, phase) driver.onUserCameraDrag(ax, timeFcn(), vehPosFcn, phase);
        end
    catch ME
        warning('lvd_renderSceneAtTime:camera', 'Scene camera update failed: %s', ME.message);
    end

    if(profile.showGrdTrk)
        if(not(isempty(vehGrdTrkData)))
            vehGrdTrkData.plotBodyMarkerAtTime(time, grdTrkAx);
        end

        for(i=1:length(celBodyGrdTrackData))
            celBodyGrdTrackData(i).plotCelBodyMarkerAtTime(time, grdTrkAx);
        end

        for(i=1:length(grdObjGrdTrkData))
            grdObjGrdTrkData(i).plotGrdObjMarkerAtTime(time, grdTrkAx);
        end

        for(i=1:length(geomPtGrdTrackData))
            geomPtGrdTrackData(i).plotGeomPtMarkerAtTime(time, grdTrkAx);
        end

        if(not(isempty(profile.grdTrackLighting)))
            profile.grdTrackLighting.updateSunLightingPosition(time);
        end
    end

    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(time);
    epochStr = formDateStr(year, day, hour, minute, sec);

    [~, timeEvtsListboxStrs] = lvdData.script.getAllEvtsThatOccurAtTime(time);
    for(i=1:length(timeEvtsListboxStrs))
        timeEvtsListboxStrs(i) = sprintf('Event: %s',timeEvtsListboxStrs(i));
    end
    evtsStr = strjoin(timeEvtsListboxStrs,'\n');

    if(not(isempty(timeEvtsListboxStrs)))
        dashes = repmat('-',1,max(strlength(timeEvtsListboxStrs)));
    else
        dashes = '';
    end

    tooltipStr = sprintf('UT = %0.3f sec\n%s\n%s', time, dashes, evtsStr);

    app.timeSliderValueLabel.Text = epochStr;
    app.timeSliderValueLabel.Tooltip = tooltipStr;

    setappdata(app.DispAxesTimeSlider,'lastTime',time);

    %an open playback window re-binds if undo/redo swapped the mission object
    try
        lvd_notifyPlaybackWindows(lvdData, app);
    catch
    end

    switch(drawMode)
        case "limitrate"
            drawnow limitrate;
        case "full"
            drawnow;
        case "none"
            %caller flushes
    end
end
