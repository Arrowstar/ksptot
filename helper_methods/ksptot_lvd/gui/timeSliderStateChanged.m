function timeSliderStateChanged(src,evt, lvdData, handles, app)
%timeSliderStateChanged ValueChangingFcn of the LVD 3-D view time slider.
%
%   Rate-limits slider drags to one render per 50 ms, switches the camera
%   toolbar out of any interactive mode (which would otherwise rotate or
%   pan the axes while the slider moves), and renders the scene through
%   lvd_renderSceneAtTime.  Playback and video export call
%   lvd_renderSceneAtTime directly so they are never throttled.

    arguments
        src matlab.ui.control.Slider
        evt matlab.ui.eventdata.ValueChangingData
        lvdData LvdData
        handles struct
        app ma_LvdMainGUI_App
    end

    persistent lastCall

    if(isempty(lastCall))
        lastCall = tic;
    end

    elapsedTime = toc(lastCall);
    if(elapsedTime < 0.05)
        return;
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
        time = evt.Value;
    catch ME %#ok<NASGU>
        time = src.Value;
    end

    lvd_renderSceneAtTime(double(time), lvdData, handles, app, "limitrate");

    lastCall = tic;
end
