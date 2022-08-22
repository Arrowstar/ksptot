function [f] = ma_maxTotalPropMassObjFunc(stateLog, eventID, celBodyData, maData)
%ma_maxTotalPropMass Summary of this function goes here
%   Detailed explanation goes here

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    finalEntry = eventLog(end,:);
    f = -sum(finalEntry(10:12));
end

