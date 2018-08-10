function datapt = ma_TimeTask(stateLogEntry, subTask, celBodyData)
%ma_GAVectorElementsTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'ut'
            datapt = stateLogEntry(1);
    end
end