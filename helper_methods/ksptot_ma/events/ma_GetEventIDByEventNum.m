function [eventID] = ma_GetEventIDByEventNum(eventNum, script)
%getEventIDByEventNum Summary of this function goes here
%   Detailed explanation goes here
    try
        eventID = script{eventNum}.id;
    catch
        eventID = -1;
    end
end

