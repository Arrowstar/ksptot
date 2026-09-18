function handler = lvd_getMouseCameraHandler(app)
%lvd_getMouseCameraHandler The LvdMouseCameraHandler attached to the LVD
%main window, or [] when there is none (tests, or a window without it).
%
%   LvdMouseCameraHandler.setup stores the handler on the app's
%   mouseCameraHandler property when that is writable and otherwise in the
%   main figure's appdata; this looks in both places.

    handler = [];

    try
        handler = app.mouseCameraHandler;
    catch
        handler = [];
    end

    if(isempty(handler))
        try
            handler = getappdata(app.ma_LvdMainGUI, 'LvdMouseCameraHandler');
        catch
            handler = [];
        end
    end

    if(not(isempty(handler)) && not(isvalid(handler)))
        handler = [];
    end
end
