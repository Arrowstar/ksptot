function plotOneFrame(handles)
    if(strcmpi(get(handles.ma_MissionAnimatorGUI,'Visible'),'on'))
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        stateLog = maData.stateLog;  
        celBodyData = maData.celBodyData;

        time = get(handles.movieFrameSlider,'Value');
        orbitToPlot = ma_getOrbitToPlot(stateLog, time);
        
        hFig = handles.ma_MissionAnimatorGUI;
        mAxes = handles.movieAxes;

        ma_plotFrame(hFig, mAxes, maData, stateLog, time, NaN, orbitToPlot, celBodyData, handles);
    end
end