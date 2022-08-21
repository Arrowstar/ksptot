function [c, ceq] = ma_driftRateConstraint(stateLog, eventID, lbLong, ubLong, bodyIDApply, celBodyData, maData)

    normFact = 1;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';
        gmu = bodyInfo.gm;
        
        [sma, ~, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu, true);
        
        driftRate = computeDriftRate(sma, bodyInfo) * (3600*180/pi); %convert to deg/hr
        
        if(lbLong == ubLong)
            c = [0 0];
            ceq(1) = driftRate - ubLong;
        else
            c(1) = lbLong - driftRate;
            c(2) = driftRate - ubLong;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end