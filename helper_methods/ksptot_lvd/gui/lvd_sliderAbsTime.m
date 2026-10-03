function t = lvd_sliderAbsTime(slider, pct)
%lvd_sliderAbsTime Absolute trajectory time (UT seconds) for a 0-100
%time-slider position.
%
%   The LVD 3-D view time slider runs 0-100 (percent of the plotted
%   trajectory) because R2025b uislider drag gestures freeze at large
%   absolute Limits (UT seconds), while small magnitudes drag fine.  The
%   plotted epoch range is stored on the slider itself by
%   LaunchVehicleViewProfile.configureTimeSlider.  Before the first plot
%   (no epoch stored) positions already read absolute, so pct passes
%   through unchanged.

    t = pct;
    try
        t0 = getappdata(slider, 'lvdTimeSliderT0');
        span = getappdata(slider, 'lvdTimeSliderSpan');
        if(isscalar(t0) && isscalar(span) && isfinite(t0) && isfinite(span) && span > 0)
            t = t0 + pct/100*span;
        end
    catch
    end
end
