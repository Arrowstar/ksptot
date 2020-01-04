function datapt = lvd_EventNumTask(stateLogEntry, subTask)
%lvd_EventNumTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'eventNum'
            maStateLog = stateLogEntry.getMAFormattedStateLogMatrix();
            datapt = maStateLog(13);
    end
end