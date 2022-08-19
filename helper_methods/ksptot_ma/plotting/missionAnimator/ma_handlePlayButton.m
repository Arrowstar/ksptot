function ma_handlePlayButton(handles, frameRate)
%ma_handlePlayButton Summary of this function goes here
%   Detailed explanation goes here
    global GLOBAL_VideoWriter GLOBAL_isRecording;
    persistent mTimer;
    
    if(get(handles.playButton,'Value')==1)
        set(handles.playButton,'String','<html>&#9632;');
        delete(mTimer);
        
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
        stateLog = maData.stateLog; 
        
        time = get(handles.movieFrameSlider,'Value');
        [orbitToPlot] = ma_getOrbitToPlot(stateLog, time);
        
        hold(handles.movieAxes,'on');
        period = 1/frameRate;
        period = round(period*1000)/1000;
        tFunc = @(obj,event) ma_playMovieTimerCallback(obj, event, handles.playButton, handles.ma_MissionAnimatorGUI, handles.movieAxes, maData, frameRate, celBodyData, handles);
        mTimer = timer('TimerFcn',tFunc,'Period',period,'ExecutionMode','fixedRate','UserData',[NaN, NaN, orbitToPlot]);
        hold(handles.movieAxes,'off');
        
        if(GLOBAL_isRecording)
            GLOBAL_VideoWriter.FrameRate = frameRate;
            open(GLOBAL_VideoWriter);
        end
        
        drawnow;
        start(mTimer);
    else
        set(handles.playButton,'String','<html>&#9658');
        
        if(GLOBAL_isRecording) 
            try
                close(GLOBAL_VideoWriter);
            catch
                %no action
            end
            GLOBAL_isRecording = false;
            GLOBAL_VideoWriter = [];
        end
        drawnow;
    end
end

