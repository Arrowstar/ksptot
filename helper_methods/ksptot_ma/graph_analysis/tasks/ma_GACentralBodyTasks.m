function datapt = ma_GACentralBodyTasks(stateLogEntry, subTask, celBodyData)
%ma_GACentralBodyTasks Summary of this function goes here
%   Detailed explanation goes here
    
    switch subTask
        case 'CB_ID'
            datapt = stateLogEntry(8);
    end
end

