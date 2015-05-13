function [c, ceq] = ma_rPeConstraint(stateLog, eventID, lbRPe, ubRPe, bodyIDApply, celBodyData, maData)
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
        
        normFact = bodyInfo.radius;

        [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
        [~, rPe] = computeApogeePerigee(sma, ecc);

        c = [];
        ceq = [];
        if(lbRPe == ubRPe)
            c = 10*[-normFact -normFact];
            ceq(1) = rPe - ubRPe;
        else
            if(~isnan(lbRPe) && isfinite(lbRPe))
                c(end+1) = lbRPe - rPe;
            end
            if(~isnan(ubRPe) && isfinite(ubRPe))
                c(end+1) = rPe - ubRPe;
            end
            ceq = [0];
        end
    else
        c = 10*[-normFact -normFact];
        ceq = [0];
    end
    c = c/normFact;
    ceq = ceq/normFact;
end