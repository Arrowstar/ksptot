function [eventLog] = ma_executeCoast_nBody_goto_ut(ut, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime, events, celBodyData)
%ma_executeCoast_nBody_goto_ut Summary of this function goes here
%   Detailed explanation goes here
    
    dt = ut - initialState(1);
    eventLog = ma_executeCoast_nBody_goto_dt(dt, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime, events, true, celBodyData);
end

