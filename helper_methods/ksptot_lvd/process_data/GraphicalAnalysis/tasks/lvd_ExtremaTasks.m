function [datapt, unitStr] = lvd_ExtremaTasks(stateLogEntry, subTask, extremum)
%lvd_ExtremaTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'extremumValue'
            extremaStates = stateLogEntry.getAllExtremaStates();
            extremaState = extremaStates([extremaStates.extrema] == extremum);
            
            if(not(isempty(extremaState)))
                extremaState = extremaState(1);
                datapt = extremaState.value;
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = extremaState.extrema.unitStr;
            else
                datapt = -1;
            end
    end
end