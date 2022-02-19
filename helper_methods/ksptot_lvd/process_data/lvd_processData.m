function lvd_processData(handles, app)
    %lvd_processData Summary of this function goes here
    %   Detailed explanation goes here
    
    
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(true);
       
    %%%%%%%%%%
    % Update script listbox
    %%%%%%%%%%    
    [evtListboxStr, events] = lvdData.script.getListboxStr();
    app.scriptListbox.Items = evtListboxStr;
    app.scriptListbox.ItemsData = events;
    
    scriptListVal = get(handles.scriptListbox,'Value');
    if(isempty(scriptListVal) || scriptListVal <= 0)
        set(handles.scriptListbox,'Value',1);
    elseif(scriptListVal > length(get(handles.scriptListbox,'String')))
        set(handles.scriptListbox,'Value',length(get(handles.scriptListbox,'String')));
    end
    drawnow;
    
    %%%%%%%%%%
    % Update Non-Sequential Events listbox
    %%%%%%%%%%   
    [nonSeqEvtsListboxStr, nonSeqEvents] = lvdData.script.nonSeqEvts.getListboxStr();
    
    if(isempty(nonSeqEvtsListboxStr))
        set(handles.nonSeqEventsListbox,'String','');
    else
        app.nonSeqEventsListbox.Items = nonSeqEvtsListboxStr;
        app.nonSeqEventsListbox.ItemsData = nonSeqEvents;
    end
    
    scriptListVal = get(handles.nonSeqEventsListbox,'Value');
    if(isempty(scriptListVal) || scriptListVal <= 0)
        set(handles.nonSeqEventsListbox,'Value',1);
    elseif(scriptListVal > length(get(handles.nonSeqEventsListbox,'String')))
        set(handles.nonSeqEventsListbox,'Value',length(get(handles.nonSeqEventsListbox,'String')));
    end
    drawnow;
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    lvdData.viewSettings.plotTrajectoryWithActiveViewProfile(handles, app);
    drawnow;
       
    %%%%%%%%%%
    % Update State Readouts
    %%%%%%%%%%
    propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
    ma_UpdateStateReadout(handles.initialStateReadoutLabel, 'initial', propNames, maStateLog, celBodyData);
    ma_UpdateStateReadout(handles.finalStateReadoutLabel, 'final', propNames, maStateLog, celBodyData);

    drawnow;
end