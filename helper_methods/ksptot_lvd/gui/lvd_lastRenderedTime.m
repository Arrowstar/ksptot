function t = lvd_lastRenderedTime(slider, fallback)
%lvd_lastRenderedTime The time the LVD 3-D view was last rendered at,
%from the time slider's 'lastTime' appdata, or `fallback` when none.

    t = fallback;
    try
        if(isvalid(slider) && isappdata(slider, 'lastTime'))
            v = getappdata(slider, 'lastTime');
            if(isscalar(v) && isfinite(v))
                t = v;
            end
        end
    catch
    end
end
