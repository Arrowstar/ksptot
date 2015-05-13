function datapt = ma_GADistToRefSCTask(stateLogEntry, subTask, celBodyData)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    hRefSCCombo = findobj('Tag','refSpacecraftCombo');
    
    if(strcmpi(get(hRefSCCombo,'Enable'),'off'))
        datapt = -1;
        return;
    end
    
    try
        refSCInd = get(hRefSCCombo,'Value');
        hGA = findobj('Tag','ma_GraphicalAnalysisGUI');
        handles = guidata(hGA);
        maData = getappdata(handles.ma_MainGUI,'ma_data');
        otherSCs = maData.spacecraft.otherSC;
        otherSC = otherSCs{refSCInd};
    catch
        datapt = -1;
        return;
    end
    
    if(isempty(otherSC))
        datapt = -1;
        return;
    end
    
    switch subTask
        case 'distToRefSC'
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, otherSC, celBodyData);
            datapt = norm(dVect);
    end
end