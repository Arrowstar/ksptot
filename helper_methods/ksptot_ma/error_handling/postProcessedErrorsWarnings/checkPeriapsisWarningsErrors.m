function checkPeriapsisWarningsErrors(stateLog, script, celBodyData)
%checkPeriapsisWarningsErrors Summary of this function goes here
%   Detailed explanation goes here
    
    chunkedStateLog = breakStateLogIntoSoIChunks(stateLog);
    for(i=1:size(chunkedStateLog,1)) %#ok<*NO4LP>
        for(j=1:size(chunkedStateLog,2))
            subLog = chunkedStateLog{i,j};
            
            if(isempty(subLog) || (size(subLog,1)==0 && size(subLog,2)==0))
                continue;
            end
            
            if(size(subLog,1) > 1)
                state = subLog(end,:);
            else
                state = subLog(1,:);
            end
            
            bodyID = state(8);
            eventNum = state(13);
            bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(state(2:4),state(5:7),bodyInfo.gm);
            [~, rPe] = computeApogeePerigee(sma, ecc);
            
            event = script{eventNum};
            
            if(strcmpi(event.type,'Landing') || (strcmpi(event.type,'Set_State') && strcmpi(event.subType,'estLaunch')));
                expectedForEvent = true;
            else
                expectedForEvent = false;
            end
            
            if(rPe <= bodyInfo.radius && not(expectedForEvent))
                addToExecutionErrors(['Low Periapse Alert (hPe = ',num2str(rPe-bodyInfo.radius),' km)'], eventNum, bodyID, celBodyData);
            elseif((rPe <= bodyInfo.radius + bodyInfo.atmohgt) && bodyInfo.atmohgt > 0.0 && not(expectedForEvent))
                addToExecutionWarnings(['Low Periapse Warning (hPe = ',num2str(rPe-bodyInfo.radius),' km)'], eventNum, bodyID, celBodyData);
            end
        end
    end   
end

