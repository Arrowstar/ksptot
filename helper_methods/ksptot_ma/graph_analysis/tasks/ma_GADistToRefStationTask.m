function datapt = ma_GADistToRefStationTask(stateLogEntry, subTask, celBodyData)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    hRefStnCombo = findobj('Tag','refStationCombo');
    
    if(strcmpi(get(hRefStnCombo,'Enable'),'off'))
        datapt = -1;
        return;
    end
    
    try
        refSCInd = get(hRefStnCombo,'Value');
        hGA = findobj('Tag','ma_GraphicalAnalysisGUI');
        handles = guidata(hGA);
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        stations = maData.spacecraft.stations;
        station = stations{refSCInd};
    catch
        datapt = -1;
        return;
    end
    
    if(isempty(station))
        datapt = -1;
        return;
    end
    
    switch subTask
        case 'distToRefStn'
            dVect = getAbsPositBetweenSpacecraftAndStation(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, station, celBodyData);
            datapt = norm(dVect);
    end
end