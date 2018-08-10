function datapt = ma_GADistToCelBodyTask(stateLogEntry, subTask, refBodyInfo, celBodyData)
%ma_GADistToCelBodyTask Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
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

