function eventLog = ma_executeCoast_goto_func_value(event, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, maData, celBodyData)
%ma_executeCoast_goto_func_value Summary of this function goes here
%   Detailed explanation goes here
    global number_state_log_entries_per_coast;
    
    old_number_state_log_entries_per_coast = number_state_log_entries_per_coast;
    number_state_log_entries_per_coast = 10; %#ok<NASGU>
    
    bnds = [0, event.maxPropTime];
    func = @(dt) getCoastFuncValue(dt, event.funcHandle, event.coastToValue, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, maData, celBodyData);
    options = optimset('TolX',1E-6);
    [x, fval, exitflag] = fminbnd(func, bnds(1), bnds(2), options);
    
    if(exitflag == 0 || abs(fval) > 1E-4)
        x = event.maxPropTime;
    end
    
    number_state_log_entries_per_coast = old_number_state_log_entries_per_coast;
    eventLog = ma_executeCoast_goto_dt(x, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, celBodyData);
end

function value = getCoastFuncValue(dt, funcHandle, desiredValue, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, maData, celBodyData)
    eventLog = ma_executeCoast_goto_dt(dt, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, celBodyData);
    finalState = eventLog(end,:);
    
    [datapt, ~, ~, taskStr, refBodyInfo, otherSC, station] = funcHandle(finalState, false, maData);
    value = abs(datapt - desiredValue);
end