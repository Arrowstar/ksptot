function datapt = ma_GAVectorElementsTask(stateLogEntry, subTask, celBodyData)
%ma_GAVectorElementsTask Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'rX'
            datapt = stateLogEntry(2);
        case 'rY'
            datapt = stateLogEntry(3);
        case 'rZ'
            datapt = stateLogEntry(4);
        case 'vX'
            datapt = stateLogEntry(5);
        case 'vY'
            datapt = stateLogEntry(6);
        case 'vZ'
            datapt = stateLogEntry(7);    
        case 'rNorm'
            datapt = norm(stateLogEntry(2:4));
        case 'vNorm'
            datapt = norm(stateLogEntry(5:7));
    end
end

