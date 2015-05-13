function ma_playMovieTimerCallback(timer, evt, hPlayBtn, hFig, mAxes, maData, frameRate, celBodyData, handles)

    userData = get(timer,'UserData');
    stateLogTime = userData(1);
    prevBody = userData(2);
    orbitToPlot = userData(3);    
    
    stateLog = maData.stateLog;
    
    if(isnan(stateLogTime))
        stateLogTime = get(handles.movieFrameSlider,'Value');
    end
    
    if(get(hPlayBtn,'Value')==0 && ~isempty(evt))
        stop(timer); drawnow;
        
        return;
    end
    
    timeWarpMultiplier = get(handles.warpRateCombo,'UserData');
    [curBody] = ma_plotFrame(hFig, mAxes, maData, stateLog, stateLogTime, prevBody, orbitToPlot, celBodyData, handles);
    curStateLogTime = ma_getStateLogTimeToPlot(stateLogTime, frameRate, timeWarpMultiplier);
    
    if(prevBody~=curBody)
        orbitToPlot = orbitToPlot + 1;
    end
    prevBody = curBody;
    
    if(curStateLogTime > max(stateLog(:,1)) && stateLogTime < max(stateLog(:,1)))
        curStateLogTime = max(stateLog(:,1));
    end
        
    if(curStateLogTime > max(stateLog(:,1)))
        stop(timer);
        set(hPlayBtn,'Value',0);
        set(handles.movieFrameSlider,'Value',max(stateLog(:,1)));
        
        writeVideo();
        
        ma_handlePlayButton(handles, frameRate);
        set(handles.movieFrameSlider,'Value',get(handles.movieFrameSlider,'Min'));
        cb = get(handles.movieFrameSlider,'Callback');
        cb(handles.movieFrameSlider,[]);
        return;
    else
        set(handles.movieFrameSlider,'Value',curStateLogTime);
        set(handles.sliderUTText,'String',fullAccNum2Str(curStateLogTime));
    end
    stateLogTime = curStateLogTime;
    set(timer,'UserData',[stateLogTime, prevBody, orbitToPlot]);
end

function writeVideo()
    global GLOBAL_VideoWriter GLOBAL_isRecording;
    
    if(GLOBAL_isRecording) 
        close(GLOBAL_VideoWriter);
        
        helpMsg = sprintf('Your recording has completed and is available at the following location:\n\n%s',GLOBAL_VideoWriter.Filename);
        h = msgbox(helpMsg,'Recording Complete','help','modal');
        uiwait(h);
        
        GLOBAL_isRecording = false;
        GLOBAL_VideoWriter = [];
    end
end