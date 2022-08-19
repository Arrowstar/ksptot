function [stateLog, errorStr, errorEventNum] = ma_produceStateLogFromScript(script, maData, celBodyData, allowInterrupt, varargin)
%ma_produceStateLogFromScript Summary of this function goes here
%   Detailed explanation goes here
    if(isempty(varargin))
        stateLog = [];
        eventNum = 1;
    else
        partialExec = varargin{1};
        stateLog = partialExec{1};
        eventNum = partialExec{2};
    end
    initialEventNum = eventNum;
    
    if(initialEventNum > length(script))
        initialEventNum = length(script);
    end

%     profile on -history
    errorStr = '';
    errorEventNum = -1;
    for(i = initialEventNum:length(script)) %#ok<*NO4LP>
        event = script{i};
        
        if(allowInterrupt && mod(i,2))
            drawnow;
        end
        
        try
            eventLog = ma_executeEvent(event, getLastStateLogEntry(stateLog), eventNum, maData, celBodyData);
            stateLog = [stateLog ; eventLog]; %#ok<*AGROW>
            eventNum = eventNum + 1;
        catch ME
            errorStr = ME.message;
            errorEventNum = eventNum;
            
            disp('################## Propagation Error ###################');
            disp(['Event Num: ', num2str(eventNum)]);
            disp(['Error Msg: ', ME.message]);
            disp('#########################################################');
            try
                disp(ME.cause{1}.message);
                disp('#########################################################');
            catch
            end
            for(i=1:length(ME.stack)) %#ok<FXSET>
                disp(['Index: ', num2str(i)]);
                disp(['File: ',ME.stack(i).file]);
                disp(['Name: ',ME.stack(i).name]);
                disp(['Line: ',num2str(ME.stack(i).line)]);
                disp('####################');
            end
            disp('#########################################################');
            break;
        end
    end
%     profile viewer
    
    stateLog(all(stateLog==0,2),:)=[];
end

