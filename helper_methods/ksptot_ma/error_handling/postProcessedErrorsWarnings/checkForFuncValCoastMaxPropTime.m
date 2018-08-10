function checkForFuncValCoastMaxPropTime(stateLog, script, celBodyData)
%checkForNBodyMaxPropTime Summary of this function goes here
%   Detailed explanation goes here

    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        if(strcmpi(event.type,'Coast') && strcmpi(event.coastType,'goto_func_value'))
            prevStateLog = stateLog(stateLog(:,13)==i-1, :);
            subStateLog = stateLog(stateLog(:,13)==i, :);
            if(subStateLog(end,1) - prevStateLog(end,1) >= event.maxPropTime)
                addToExecutionWarnings(['Coast to function value terminated at maximum propagation time: ', num2str(event.maxPropTime), ' sec'], i, -1, celBodyData);
            end
        end
    end
end