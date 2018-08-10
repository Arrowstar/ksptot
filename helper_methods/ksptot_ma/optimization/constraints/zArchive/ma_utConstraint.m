function [c, ceq] = ma_utConstraint(stateLog, eventID, lbUT, ubUT, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here

    normFact = 1000;
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
        ut = finalEntry(1);

        if(lbUT == ubUT)
            c = [0 0];
            ceq(1) = ut - ubUT;
        else
            c(1) = lbUT - ut;
            c(2) = ut - ubUT;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end