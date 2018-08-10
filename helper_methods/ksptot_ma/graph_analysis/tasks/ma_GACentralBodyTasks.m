function datapt = ma_GACentralBodyTasks(stateLogEntry, subTask, celBodyData)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    
    switch subTask
        case 'CB_ID'
            datapt = stateLogEntry(8);
    end
end

