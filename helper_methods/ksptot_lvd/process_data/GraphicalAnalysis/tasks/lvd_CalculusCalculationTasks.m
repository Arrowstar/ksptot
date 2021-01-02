function [datapt, unitStr] = lvd_CalculusCalculationTasks(stateLogEntry, subTask, calcObj)
%lvd_ExtremaTasks Summary of this function goes here
%   Detailed explanation goes here

    switch subTask
        case 'calcObjValue'
            calcObjStates = stateLogEntry.getAllCalculusObjStates();
            calcObjState = calcObjStates([calcObjStates.calcObj] == calcObj);
            
            if(not(isempty(calcObjState)))
                time = stateLogEntry.time;
                calcObjState = calcObjState(1);
                datapt = calcObjState.getValueAtTime(time);
                
                if(isempty(datapt))
                    datapt = -1;
                end
                
                unitStr = calcObjState.calcObj.unitStr;
            else
                datapt = -1;
            end
    end
end