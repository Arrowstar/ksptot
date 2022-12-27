function [c, ceq] = ma_inclinationConstraint(stateLog, eventID, lbInc, ubInc, bodyIDApply, celBodyData, maData)
%ma_semiEccentricityConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = pi;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
%         hMAMainGUI = findall(0,'tag','ma_MainGUI');
%         maData = getappdata(hMAMainGUI,'ma_data');
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);

    bodyEventLog = eventLog(eventLog(:,8)==bodyIDApply,:);
    if(isempty(bodyEventLog))
        finalEntry = eventLog(end,:);
    else
        finalEntry = bodyEventLog(end,:);
    end
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        gmu = bodyInfo.gm;
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';

        [~, ~, inc, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);

        if(lbInc == ubInc)
            c = [0 0];
            ceq(1) = inc - ubInc;
        else
            c(1) = inc - ubInc;
            c(2) = lbInc - inc;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end

