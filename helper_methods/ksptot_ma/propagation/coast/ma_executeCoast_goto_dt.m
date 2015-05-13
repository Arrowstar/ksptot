function eventLog = ma_executeCoast_goto_dt(dt, initialState, eventNum, considerSoITransitions, celBodyData)
%ma_executeCoast_goto_dt Summary of this function goes here
%   Detailed explanation goes here
    eventLog = ma_executeCoast_goto_ut(initialState(1)+dt, initialState, eventNum, considerSoITransitions, celBodyData);
end

