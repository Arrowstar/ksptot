function datapt = ma_GADistToRefStationTask(stateLogEntry, subTask, station, celBodyData)
%ma_GADistToRefStationTask Summary of this function goes here
%   Detailed explanation goes here
    bodyID = stateLogEntry(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);

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