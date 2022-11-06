function ma_setAnimatorSliderBounds(handles, stateLog)
    if(size(stateLog,1) > 1)
        warpRate = handles.warpRateCombo.UserData;
        
        if(isempty(warpRate))
            lowerStep = 1/(size(stateLog,1)-1);
        else
            lowerStep = abs(warpRate / (stateLog(end,1) - stateLog(1,1)));
        end
        
        if(lowerStep <= 0.1)
            upperStep = 0.1;
        else
            upperStep = lowerStep;
        end
        
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(end,1),'Value',stateLog(1,1));
        set(handles.movieFrameSlider,'SliderStep',[lowerStep,upperStep]);
        set(handles.movieFrameSlider,'TooltipString', sprintf('Current step size: %0.3f s', warpRate));
    else
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(1,1)+1,'Value',stateLog(1,1));
    end
end