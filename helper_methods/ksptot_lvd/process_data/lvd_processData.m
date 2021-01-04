function lvd_processData(handles)
    %lvd_processData Summary of this function goes here
    %   Detailed explanation goes here
    set(handles.plotWorkingLbl,'Visible','on'); drawnow;
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix(true);
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    drawnow;
    lvdData.viewSettings.plotTrajectoryWithActiveViewProfile(handles);
    
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
    % Update Non-Sequential Events listbox
    %%%%%%%%%%   
    nonSeqEvtsListboxStr = lvdData.script.nonSeqEvts.getListboxStr();
    
    if(isempty(nonSeqEvtsListboxStr))
        set(handles.nonSeqEventsListbox,'String','');
    else
        set(handles.nonSeqEventsListbox,'String',nonSeqEvtsListboxStr);
    end
    
    scriptListVal = get(handles.nonSeqEventsListbox,'Value');
    if(isempty(scriptListVal) || scriptListVal <= 0)
        set(handles.nonSeqEventsListbox,'Value',1);
    elseif(scriptListVal > length(get(handles.nonSeqEventsListbox,'String')))
        set(handles.nonSeqEventsListbox,'Value',length(get(handles.nonSeqEventsListbox,'String')));
    end
    drawnow;
    
    %%%%%%%%%%
    % Update State Readouts
    %%%%%%%%%%
%     propNames = {'Liquid Fuel/Ox','Monopropellant','Xenon'};
    propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
    ma_UpdateStateReadout(handles.initialStateReadoutLabel, 'initial', propNames, maStateLog, celBodyData);
    ma_UpdateStateReadout(handles.finalStateReadoutLabel, 'final', propNames, maStateLog, celBodyData);

    set(handles.plotWorkingLbl,'Visible','off');
    drawnow;
end

