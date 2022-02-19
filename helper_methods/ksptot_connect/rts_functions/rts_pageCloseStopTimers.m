function rts_pageCloseStopTimers(hObject)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    timers = getappdata(hObject,'timers');
    if(~isempty(timers))
        for(i=1:length(timers))
            timerObj = timers(i);
            if(isvalid(timerObj))
                stop(timerObj);
            end
            delete(timerObj);
        end
    end
end

