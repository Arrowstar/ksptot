function [event, eventNum] = getEventByID(eventID, script)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    event = [];
    eventNum = -1;
    for(i=1:length(script))
        eventTest = script{i};
        if(eventTest.id == eventID)
            event = eventTest;
            eventNum = i;
            break;
        end
    end
end

