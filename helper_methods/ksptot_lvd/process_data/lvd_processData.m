function lvd_processData(handles)
    %lvd_processData Summary of this function goes here
    %   Detailed explanation goes here
    set(handles.plotWorkingLbl,'Visible','on'); drawnow;
    lvdData = getappdata(handles.ma_LvdMainGUI,'lvdData');
    celBodyData = lvdData.celBodyData;
    
    maStateLog = lvdData.stateLog.getMAFormattedStateLogMatrix();
    
    %%%%%%%%%%
    % Redraw plots
    %%%%%%%%%%
    drawnow;
    lvdData.viewSettings.plotTrajectoryWithActiveViewProfile(handles);
%     [az,el] = view(handles.dispAxes);
%     orbitPlotType = getappdata(handles.ma_LvdMainGUI,'orbitPlotType');
%     lvd_updateDispAxis(handles, maStateLog, get(handles.dispAxes,'UserData'), orbitPlotType, lvdData);
    
%     entry = lvdData.stateLog.getLastStateLogForEvent(lvdData.script.getEventForInd(3));
%     rVect = entry.position;
%     dcm = entry.attitude.dcm;
%     hold on;
%     f = 300;
%     plot3([rVect(1), rVect(1) + f*dcm(1,1)], [rVect(2), rVect(2) + f*dcm(2,1)], [rVect(3), rVect(3) + f*dcm(3,1)],'r-');
%     plot3([rVect(1), rVect(1) + f*dcm(1,2)], [rVect(2), rVect(2) + f*dcm(2,2)], [rVect(3), rVect(3) + f*dcm(3,2)],'g-');
%     plot3([rVect(1), rVect(1) + f*dcm(1,3)], [rVect(2), rVect(2) + f*dcm(2,3)], [rVect(3), rVect(3) + f*dcm(3,3)],'b-');
%     hold off;
    
%     if(strcmpi(orbitPlotType,'3DInertial') || strcmpi(orbitPlotType,'3DBodyFixed'))
%         view(handles.dispAxes, [az,el]);
%         handles.dispAxes.Position = [531.0, 206.0, 418.0, 350.0];
%     elseif(strcmpi(orbitPlotType,'2DMercador'))
%         view(2);
%         handles.dispAxes.OuterPosition = [531.0, 206.0, 418.0, 350.0];
%     else
%         error('Unknown plot type: %s', orbitPlotType);
%     end
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
    drawnow;
end

