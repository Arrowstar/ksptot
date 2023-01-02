function lastState = getLastStateLogEntry(stateLog)
    if(size(stateLog,1) > 0)
        lastState = stateLog(end,:);
    else
        lastState = [];
    end
end

