function datapt = lvd_StopwatchMassTasks(stateLogEntry, subTask, stopwatch)
%lvd_StopwatchMassTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'swValue'
            stopwatchStates = stateLogEntry.getAllStopwatchStates();
            stopwatchState = stopwatchStates([stopwatchStates.stopwatch] == stopwatch);
            
            if(not(isempty(stopwatchState)))
                stopwatchState = stopwatchState(1);
                datapt = stopwatchState.value;
            else
                datapt = -1;
            end
    end
end