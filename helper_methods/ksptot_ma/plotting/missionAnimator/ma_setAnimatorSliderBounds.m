function ma_setAnimatorSliderBounds(handles, stateLog)
    if(size(stateLog,1) > 1)
        lowerStep = 1/(size(stateLog,1)-1);
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(end,1),'Value',stateLog(1,1));
        set(handles.movieFrameSlider,'SliderStep',[lowerStep,0.1]);
    else
        set(handles.movieFrameSlider,'Min',stateLog(1,1),'Max',stateLog(1,1)+1,'Value',stateLog(1,1));
    end
end