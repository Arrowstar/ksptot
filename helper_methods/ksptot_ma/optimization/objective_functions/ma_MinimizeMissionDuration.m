function [f] = ma_MinimizeMissionDuration(stateLog, eventID, celBodyData, maData)
%ma_maxTotalPropMass Summary of this function goes here
%   Detailed explanation goes here

    f = stateLog(end,1) - stateLog(1,1);
end