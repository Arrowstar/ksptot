function datapt = ma_GADistanceTraveledTask(stateLogEntry, subTask, celBodyData, prevStateLogEntry, prevDistTraveled)
%ma_GADistanceTraveledTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'Distance Traveled'
            if(isempty(prevStateLogEntry) || stateLogEntry(8) ~= prevStateLogEntry(8))
                deltaDist = 0;
            else
                deltaDist = norm(stateLogEntry(2:4) - prevStateLogEntry(2:4));
            end
            
            datapt = prevDistTraveled + deltaDist;
    end
end

