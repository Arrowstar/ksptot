function [eventLog] = ma_executeCoast_nBody_goto_soi_trans(initialState, eventNum, forceModel, soiSkipIds, massLoss, maxPropTime, events, celBodyData)
%ma_executeCoast_nBody_goto_soi_trans Summary of this function goes here
%   Detailed explanation goes here

    eventLog = ma_executeCoast_nBody_goto_dt(maxPropTime, initialState, eventNum, forceModel, true, soiSkipIds, massLoss, maxPropTime, events, false, celBodyData);
end

