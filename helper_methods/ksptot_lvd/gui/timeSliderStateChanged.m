function timeSliderStateChanged(src,evt, lvdData, handles, app, force)
%timeSliderStateChanged ValueChangingFcn (and ValueChangedFcn) of the LVD
%3-D view time slider.
%
%   Rate-limits slider drags to one render per 50 ms, switches the camera
%   toolbar out of any interactive mode (which would otherwise rotate or
%   pan the axes while the slider moves), and renders the scene through
%   lvd_renderSceneAtTime.  Playback and video export call
%   lvd_renderSceneAtTime directly so they are never throttled.
%
%   The slider runs 0-100 (percent of the plotted trajectory); the percent
%   is converted back to absolute UT through the epoch stored on the
%   slider (see lvd_sliderAbsTime).
%
%   force (default false): bypass the 50 ms rate limit.  The slider's
%   ValueChangedFcn (drag release) always forces, so the final resting
%   position renders immediately.

    arguments
        src matlab.ui.control.Slider
        evt %untyped: ValueChangingData on drag, ValueChangedData on release, [] for programmatic renders
        lvdData LvdData
        handles struct
        app ma_LvdMainGUI_App
        force(1,1) logical = false
    end

    persistent lastCall

    if(isempty(lastCall))
        lastCall = tic;
    end

    if(not(force))
        elapsedTime = toc(lastCall);
        if(elapsedTime < 0.05)
            return;
        end
    end

    %We need to do this because for some reason the slider rotates, pans,
    %or zooms the axes if a camera toolbar mode is selected.
    m = cameratoolbar(app.ma_LvdMainGUI, 'GetMode');
    if(not(isempty(m)))
        cameratoolbar(app.ma_LvdMainGUI, 'SetMode','nomode');
        app.panPushMenuToggle.State ="off";
        app.orbitCameraPushMenuToggle.State ="off";
        app.rotateCameraPushMenuToggle.State ="off";
        app.zoomOutPushMenuToggle.State ="off";
        app.zoomInPushMenuToggle.State ="off";
    end

    try
        pct = evt.Value;
    catch ME %#ok<NASGU>
        pct = src.Value;
    end
    time = lvd_sliderAbsTime(src, pct);

    lvd_renderSceneAtTime(double(time), lvdData, handles, app, "limitrate");

    lastCall = tic;
end
