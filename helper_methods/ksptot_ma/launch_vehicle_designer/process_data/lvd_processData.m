function lvd_processData(handles)
    %lvd_processData Summary of this function goes here
    %   Detailed explanation goes here
    maData = getappdata(handles.ma_LvdMainGUI,'maData');
    celBodyData = getappdata(handles.ma_LvdMainGUI,'celBodyData');
       
    lvdData = maData.lvdData;
    
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    set(handles.plotWorkingLbl,'Visible','on');
    drawnow;
    [az,el] = view(handles.dispAxes);
    lvd_updateDispAxis(handles, maStateLog, get(handles.dispAxes,'UserData'), lvdData);
    view(handles.dispAxes, [az,el]);
    set(handles.plotWorkingLbl,'Visible','off');
    drawnow;
    
    %%%%%%%%%%
    % Update script listbox
    %%%%%%%%%%    
    evtListboxStr = lvdData.script.getListboxStr();
    set(handles.scriptListbox,'String',evtListboxStr);
    drawnow;
    
    %%%%%%%%%%
    % Update State Readouts
    %%%%%%%%%%
    ma_UpdateStateReadout(handles.initialStateReadoutLabel, 'initial', maData, maStateLog, celBodyData);
    ma_UpdateStateReadout(handles.finalStateReadoutLabel, 'final', maData, maStateLog, celBodyData);
    drawnow;
end

