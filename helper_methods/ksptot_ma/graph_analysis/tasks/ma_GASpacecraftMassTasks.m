function datapt = ma_GASpacecraftMassTasks(stateLogEntry, subTask, celBodyData)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
    
    switch subTask
        case 'fuelOx'
            datapt = stateLogEntry(10);
        case 'monoprop'
            datapt = stateLogEntry(11);
        case 'xenon'
            datapt = stateLogEntry(12);
        case 'dry'
            datapt = stateLogEntry(9);
        case 'total'
            datapt = sum(stateLogEntry(9:12));
    end
end

