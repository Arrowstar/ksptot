function pct = lvd_sliderPctForTime(slider, t)
%lvd_sliderPctForTime 0-100 time-slider position for an absolute trajectory
%time (UT seconds), clamped to the slider range.
%
%   Inverse of lvd_sliderAbsTime.  Before the first plot (no epoch stored)
%   this falls back to clamping the time into the slider's own Limits, the
%   historical behavior.

    try
        t0 = getappdata(slider, 'lvdTimeSliderT0');
        span = getappdata(slider, 'lvdTimeSliderSpan');
        if(isscalar(t0) && isscalar(span) && isfinite(t0) && isfinite(span) && span > 0)
            pct = min(max(100*(t - t0)/span, 0), 100);
            return;
        end
    catch
    end

    pct = t;
    try
        lims = slider.Limits;
        if(all(isfinite(lims)))
            pct = min(max(t, lims(1)), lims(2));
        end
    catch
    end
end
