function [c, ceq] = ma_orbitPeriodConstraint(stateLog, eventID, lbPeriod, ubPeriod, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 10;

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

        [sma, ~, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
        if(sma <= 0)
            c = [0 0];
            ceq = [0];
            return;
        end
        period = computePeriod(sma, gmu);
        
        if(lbPeriod == ubPeriod)
            c = [0 0];
            ceq(1) = period - ubPeriod;
        else
            c(1) = lbPeriod - period;
            c(2) = period - ubPeriod;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end