function checkPropLevelsWarningsErrors(stateLog, celBodyData)
%checkPropLevelsWarningsErrors Summary of this function goes here
%   Detailed explanation goes here
    chunkedStateLog = breakStateLogIntoSoIChunks(stateLog);
    
    lowFuelOxEventsBodiesWarn = zeros(0,2);
    lowMonopropEventsBodiesWarn = zeros(0,2);
    lowXenonEventsBodiesWarn = zeros(0,2);
    
    lowFuelOxEventsBodiesAlert = zeros(0,2);
    lowMonopropEventsBodiesAlert = zeros(0,2);
    lowXenonEventsBodiesAlert = zeros(0,2);
    
    minWarnThresh = 0.1;
    minAlertThresh = 0.01;
    
    iniState = stateLog(1,:);
    iniFuelOx = iniState(10);
    iniMono = iniState(11);
    iniXenon = iniState(12);
    
    for(i=1:size(chunkedStateLog,1)) %#ok<*NO4LP>
        for(j=1:size(chunkedStateLog,2))
            subLog = chunkedStateLog{i,j};
            
            if(isempty(subLog) || (size(subLog,1)==0 || size(subLog,2)==0))
                continue;
            end
            
            state = subLog(end,:);
            
            bodyID = state(8);
            %bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
            eventNum = state(13);
            
            fuelOx = state(10);
            monoprop = state(11);
            xenon = state(12);
            
            if(fuelOx / iniFuelOx <= minWarnThresh && fuelOx / iniFuelOx > minAlertThresh)
                lowFuelOxEventsBodiesWarn(end+1,:) = [eventNum, bodyID];
            elseif(fuelOx / iniFuelOx < minAlertThresh)
                lowFuelOxEventsBodiesAlert(end+1,:) = [eventNum, bodyID];
            end
            
            if(monoprop / iniMono <= minWarnThresh && monoprop / iniMono > minAlertThresh)
                lowMonopropEventsBodiesWarn(end+1,:) = [eventNum, bodyID];
            elseif(monoprop / iniMono < minAlertThresh)
                lowMonopropEventsBodiesAlert(end+1,:) = [eventNum, bodyID];
            end
            
            if(xenon / iniXenon <= minWarnThresh && xenon / iniXenon > minAlertThresh)
                lowXenonEventsBodiesWarn(end+1,:) = [eventNum, bodyID];
            elseif(xenon / iniXenon < minAlertThresh)
                lowXenonEventsBodiesAlert(end+1,:) = [eventNum, bodyID];
            end
        end
    end

    if(~isempty(lowFuelOxEventsBodiesAlert))
        eventNum = lowFuelOxEventsBodiesAlert(1,1);
        bodyID = lowFuelOxEventsBodiesAlert(1,2);
        addToExecutionErrors(['Low Fuel/Ox Alert (Events: ', makeEventsStr(lowFuelOxEventsBodiesAlert), ')'], -1, -1, celBodyData);
    end
    
    if(~isempty(lowFuelOxEventsBodiesWarn))
        eventNum = lowFuelOxEventsBodiesWarn(1,1);
        bodyID = lowFuelOxEventsBodiesWarn(1,2);
        C = setdiff(lowFuelOxEventsBodiesWarn,lowFuelOxEventsBodiesAlert,'rows');
        addToExecutionWarnings(['Low Fuel/Ox Warning (Events: ', makeEventsStr(C), ')'], -1, -1, celBodyData);
    end
    
    if(~isempty(lowMonopropEventsBodiesAlert))
        eventNum = lowMonopropEventsBodiesAlert(1,1);
        bodyID = lowMonopropEventsBodiesAlert(1,2);
        addToExecutionErrors(['Low Monoprop Alert (Events: ', makeEventsStr(lowMonopropEventsBodiesAlert), ')'], -1, -1, celBodyData);
    end
    
    if(~isempty(lowMonopropEventsBodiesWarn))
        eventNum = lowMonopropEventsBodiesWarn(1,1);
        bodyID = lowMonopropEventsBodiesWarn(1,2);
        C = setdiff(lowMonopropEventsBodiesWarn,lowMonopropEventsBodiesAlert,'rows');
        addToExecutionWarnings(['Low Monoprop Warning (Events: ', makeEventsStr(C), ')'], -1, -1, celBodyData);
    end
    
    if(~isempty(lowXenonEventsBodiesAlert))
        eventNum = lowXenonEventsBodiesAlert(1,1);
        bodyID = lowXenonEventsBodiesAlert(1,2);
        addToExecutionErrors(['Low Xenon Alert (Events: ', makeEventsStr(lowXenonEventsBodiesAlert), ')'], -1, -1, celBodyData);
    end
    
    if(~isempty(lowXenonEventsBodiesWarn))
        eventNum = lowXenonEventsBodiesWarn(1,1);
        bodyID = lowXenonEventsBodiesWarn(1,2);
        C = setdiff(lowXenonEventsBodiesWarn,lowXenonEventsBodiesAlert,'rows');
        addToExecutionWarnings(['Low Xenon Warning (Events: ', makeEventsStr(C), ')'], -1, -1, celBodyData);
    end
end

function str = makeEventsStr(eventsBodies)
    eventNums = unique(eventsBodies(:,1));
    str = '';
    for(i=1:length(eventNums))
        if(i==length(eventNums))
            endChar = '';
        else
            endChar = ', ';
        end
        
        str = [str, num2str(eventNums(i)),endChar];
    end
end

