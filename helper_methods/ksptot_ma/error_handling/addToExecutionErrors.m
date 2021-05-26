function addToExecutionErrors(errorStr, eventNum, bodyID, celBodyData)
%addToExecutionErrors Summary of this function goes here
%   Detailed explanation goes here
    global script_execution_errors;
       
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
    
    execError = script_execution_errors;
    execError{end+1} = [eventStr, errorStr];
    script_execution_errors = execError;
end

