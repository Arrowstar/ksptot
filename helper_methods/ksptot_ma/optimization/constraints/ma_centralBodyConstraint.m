function [c, ceq, bodyID, lbBody, ubBody] = ma_centralBodyConstraint(stateLog, eventID, lbBody, ubBody, bodyIDApply, celBodyData, maData)
%ma_semiEccentricityConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1/10000000;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(bodyIDApply==-1)
        c = [0 0];
        ceq = [0];
        return;
    end
    
    %handles cases where the body ID of 0 means that the constraint isn't
    %enforced
    if(bodyID==0 && lbBody==0 && ubBody==0)
        bodyID = 1;
        lbBody = 1;
        ubBody = 1;
    end
    
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    refBodyInfo = getBodyInfoByNumber(lbBody, celBodyData); %the lowerbound body should be the same as the upper bound body!
    
    dVect = getAbsPositBetweenSpacecraftAndBody(finalEntry(1), finalEntry(2:4)',...
            bodyInfo, refBodyInfo, celBodyData);
    dist = norm(dVect);
    
    if(lbBody == ubBody)
        c = [0 0];
        ceq(1) = dist*(bodyID - ubBody);
    else
        c(1) = dist*(lbBody - bodyID);
        c(2) = dist*(bodyID - ubBody);
        ceq = [0];
    end
    c = c/normFact;
    ceq = ceq/normFact;
end

