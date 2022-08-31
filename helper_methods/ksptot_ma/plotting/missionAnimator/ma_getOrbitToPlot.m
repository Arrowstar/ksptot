function [orbitToPlot, stateLogToPlot] = ma_getOrbitToPlot(stateLog, time)
    bodies = stateLog(:,8);
    endInd = [find(diff(bodies)~=0);size(stateLog,1)];
    startInd = [1;endInd(1:end-1)+1];
    startEndInd = [startInd,endInd];

    stateLogInd = find(stateLog(:,1)<=time,1,'last');
    orbitToPlot = 1;
    for(i=1:size(startEndInd,1)) %#ok<*NO4LP>
        if(startEndInd(i,1) <= stateLogInd && startEndInd(i,2) >= stateLogInd)
            orbitToPlot = i;
            stateLogToPlot = stateLog(startEndInd(i,1):startEndInd(i,2),:);
            break;
        end
    end
end

