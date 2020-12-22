function chunkedStateLog = breakStateLogIntoSoIChunks(stateLog)
%breakStateLogIntoSoIChunks Summary of this function goes here
%   Detailed explanation goes here
    allBodyIDs = stateLog(:,8);
    x = diff(allBodyIDs)~=0;
    inds = find(x)+1;
    inds = [1 inds' length(allBodyIDs)+1];
    
    chunkedStateLog = cell(length(inds)-1,1);
    for(i=1:length(inds)-1)
        ind = inds(i);
        nextInd = inds(i+1)-1;

        bodyLog = stateLog(ind:nextInd,:);
        chunkedStateLog{i} = bodyLog;
    end

    chunkedStateLog = breakChunksByEvents(chunkedStateLog');
end

function stateLogChunkedByEvents = breakChunksByEvents(chunkedStateLog) 
    
    stateLogChunkedByEvents = cell(length(chunkedStateLog),1);
    
    for(i=1:length(chunkedStateLog))
        stateLog = chunkedStateLog{i};
        allEventIDs = stateLog(:,13);
        x = diff(allEventIDs)~=0;
        inds = find(x);
        inds = [1 inds'+1 length(allEventIDs)];
        
        for(j=1:length(inds)-1) %#ok<*NO4LP>
            if(j==1)
                ind = inds(j);
                nextInd = inds(j+1)-1;
            else
                ind = inds(j);
                nextInd = inds(j+1);
            end
            
            if(nextInd < ind)
                nextInd = ind;
            end
            
            eventLog = stateLog(ind:nextInd,:);
            stateLogChunkedByEvents{i,j} = eventLog;
        end
    end
end
