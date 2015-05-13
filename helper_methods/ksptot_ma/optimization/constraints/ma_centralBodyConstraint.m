function [c, ceq] = ma_centralBodyConstraint(stateLog, eventID, lbBody, ubBody, bodyIDApply, celBodyData, maData)
%ma_semiEccentricityConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1/10000000;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
%         hMAMainGUI = findall(0,'tag','ma_MainGUI');
%         maData = getappdata(hMAMainGUI,'ma_data');
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
    
    if(lbBody == ubBody)
        c = [0 0];
        ceq(1) = bodyID - ubBody;
    else
        c(1) = lbBody - bodyID;
        c(2) = bodyID - ubBody;
        ceq = [0];
    end
    c = c/normFact;
    ceq = ceq/normFact;
end

