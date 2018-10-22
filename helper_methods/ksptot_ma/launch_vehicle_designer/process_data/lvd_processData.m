function lvd_processData(handles)
    %lvd_processData Summary of this function goes here
    %   Detailed explanation goes here
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    set(handles.plotWorkingLbl,'Visible','on');
    drawnow;
    [az,el] = view(handles.dispAxes);
    lvd_updateDispAxis(handles, maStateLog, get(handles.dispAxes,'UserData'), lvdData);
    
    entry = lvdData.stateLog.entries(1);
    rVect = entry.position;
    dcm = entry.attitude.dcm;
    hold on;
    f = 300;
    plot3([rVect(1), rVect(1) + f*dcm(1,1)], [rVect(2), rVect(2) + f*dcm(2,1)], [rVect(3), rVect(3) + f*dcm(3,1)],'r-');
    plot3([rVect(1), rVect(1) + f*dcm(1,2)], [rVect(2), rVect(2) + f*dcm(2,2)], [rVect(3), rVect(3) + f*dcm(3,2)],'g-');
    plot3([rVect(1), rVect(1) + f*dcm(1,3)], [rVect(2), rVect(2) + f*dcm(2,3)], [rVect(3), rVect(3) + f*dcm(3,3)],'b-');
    hold off;
    
    view(handles.dispAxes, [az,el]);
    set(handles.plotWorkingLbl,'Visible','off');
    drawnow;
    
    %%%%%%%%%%
    % Update script listbox
    %%%%%%%%%%    
    evtListboxStr = lvdData.script.getListboxStr();
    set(handles.scriptListbox,'String',evtListboxStr);
    
    scriptListVal = get(handles.scriptListbox,'Value');
    if(isempty(scriptListVal) || scriptListVal <= 0)
        set(handles.scriptListbox,'Value',1);
    elseif(scriptListVal > length(get(handles.scriptListbox,'String')))
        set(handles.scriptListbox,'Value',length(get(handles.scriptListbox,'String')));
    end
    drawnow;
    
    %%%%%%%%%%
    % Update State Readouts
    %%%%%%%%%%
    propNames = {'Fuel/Ox', 'Monoprop', 'Xenon'};
    ma_UpdateStateReadout(handles.initialStateReadoutLabel, 'initial', propNames, maStateLog, celBodyData);
    ma_UpdateStateReadout(handles.finalStateReadoutLabel, 'final', propNames, maStateLog, celBodyData);
    drawnow;
end

