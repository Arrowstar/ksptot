function setCamSrcTgtComboBoxes(handles, time)
    maData = getappdata(handles.ma_MainGUI,'ma_data');
    celBodyData = getappdata(handles.ma_MainGUI,'celBodyData');
    stateLog = maData.stateLog;
    stateLogRow = getStateLogRowAtTime(stateLog, time);
    bodyInfo = getBodyInfoByNumber(stateLogRow(8), celBodyData);
    
    cBoxStr = {'sc: Spacecraft'; 'cb: Central Body'};
    otherSCs = maData.spacecraft.otherSC;
    stations = maData.spacecraft.stations;
    
    bodyFields = fieldnames(celBodyData);
    for(i=1:length(bodyFields))
        body = celBodyData.(bodyFields{i});
        if(body.parentid == bodyInfo.id)
            cBoxStr{end+1} = sprintf('chBd: %s (id: %s)', body.name, num2str(body.id)); %#ok<AGROW>
        end
    end
    
    for(i=1:length(otherSCs)) %#ok<*NO4LP>
        otherSC = otherSCs{i};
        if(otherSC.parentID == bodyInfo.id)
            cBoxStr{end+1} = sprintf('osc: %s (id: %s)', otherSC.name, fullAccNum2Str(otherSC.id)); %#ok<AGROW>
        end
    end
    
    for(i=1:length(stations)) %#ok<*NO4LP>
        station = stations{i};
        if(station.parentID == bodyInfo.id)
            cBoxStr{end+1} = sprintf('grd: %s (id: %s)', station.name, fullAccNum2Str(station.id)); %#ok<AGROW>
        end
    end
    
    set(handles.cameraSrcCombo, 'String', cBoxStr);
    set(handles.cameraTgtCombo, 'String', cBoxStr);
end