function setSrcComboUserData(hObject,handles,plotFrame)
    contents = cellstr(get(hObject,'String'));
    sel = strtrim(contents{get(hObject,'Value')});
    set(hObject,'UserData',sel);
    
    if(plotFrame && get(handles.playButton,'Value')==0)
        plotOneFrame(handles);
    end
end