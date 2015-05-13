function [c, ceq] = ma_eccentricityConstraint(stateLog, eventID, lbEcc, ubEcc, bodyIDApply, celBodyData, maData)
%ma_semiEccentricityConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1;
    
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

        [~, ecc, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);

        if(lbEcc == ubEcc)
            c = [0 0];
            ceq(1) = ecc - ubEcc;
        else
            c(1) = ecc - ubEcc;
            c(2) = lbEcc - ecc;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end

