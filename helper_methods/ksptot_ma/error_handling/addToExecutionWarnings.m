function addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData)
%addToExecutionWarnings Summary of this function goes here
%   Detailed explanation goes here
    global script_execution_warnings;

    if(bodyID == -1)
        bNameStr = '';
    else
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        bName = bodyInfo.name;
        bNameStr = [' (',bName ')'];
    end
    
    if(isempty(eventNum) || eventNum == -1)
        eventStr = '';
    else
        eventStr = ['Event ', num2str(eventNum), bNameStr, ': '];
    end

    execWarn = script_execution_warnings;
    execWarn{end+1} = [eventStr, warnStr];
    script_execution_warnings = execWarn;
end

