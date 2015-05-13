function datapt = ma_GADistToCelBodyTask(stateLogEntry, subTask, celBodyData)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    hRefBodyCombo = findobj('Tag','refBodyCombo');
    contents = cellstr(get(hRefBodyCombo,'String'));
    refBodyStr = contents{get(hRefBodyCombo,'Value')};
    refBodyInfo = celBodyData.(lower(refBodyStr));
    if(isempty(refBodyInfo))
        datapt = -1;
        return;
    end

    switch subTask
        case 'distToCelBody'
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodyInfo, refBodyInfo, celBodyData);
            datapt = norm(dVect);
    end
end

