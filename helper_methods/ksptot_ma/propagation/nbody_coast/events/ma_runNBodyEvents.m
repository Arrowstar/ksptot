function [value,isterminal,direction,eventDescs] = ma_runNBodyEvents(T,Y, events)
%ma_runNBodyEvents Summary of this function goes here
%   Detailed explanation goes here
    value = [];
    isterminal = [];
    direction = [];
    eventDescs = {};
    
    for(i=1:length(events)) %#ok<*NO4LP>
        eventFun = events{i};
        [valueN,isterminalN,directionN,eventDescsN] = eventFun(T,Y);
        
        value = horzcat(value,valueN); %#ok<AGROW>
        isterminal = horzcat(isterminal,isterminalN); %#ok<AGROW>
        direction = horzcat(direction,directionN); %#ok<AGROW>
        eventDescs = horzcat(eventDescs,eventDescsN); %#ok<AGROW>
    end
end

