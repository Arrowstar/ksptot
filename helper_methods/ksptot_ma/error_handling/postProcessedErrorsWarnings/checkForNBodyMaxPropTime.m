function checkForNBodyMaxPropTime(stateLog, script, celBodyData)
%checkForNBodyMaxPropTime Summary of this function goes here
%   Detailed explanation goes here

    for(i=1:length(script)) %#ok<*NO4LP>
        event = script{i};
        if(strcmpi(event.type,'NBodyCoast'))
            nBodyStateLog = stateLog(stateLog(:,13)==i, :);
            if(nBodyStateLog(end,1) - nBodyStateLog(1,1) >= event.maxPropTime)
                addToExecutionWarnings(['N-Body coast terminated at maximum propagation time: ', num2str(event.maxPropTime), ' sec'], i, -1, celBodyData);
            end
        end
    end
end