function lvd_notifyPlaybackWindows(lvdData, app)
%lvd_notifyPlaybackWindows Tells any open LVD 3-D View Playback window that
%the scene was (re)plotted for `lvdData`, so it can re-bind after an
%undo/redo replaced the mission object and refresh its controls.

    arguments
        lvdData
        app %#ok<INUSA>
    end

    figs = findall(groot, 'Type', 'figure', 'Tag', 'lvd_ViewPlaybackGUI');
    for(i=1:numel(figs)) %#ok<*NO4LP>
        try
            win = getappdata(figs(i), 'LvdViewPlaybackApp');
            if(not(isempty(win)) && isvalid(win))
                win.onMainSceneRendered(lvdData);
            end
        catch
        end
    end
end
