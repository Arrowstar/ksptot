function [c, ceq] = ma_altConstraint(stateLog, eventID, lbAlt, ubAlt, bodyIDApply, celBodyData, maData)
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
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        rVect = finalEntry(2:4)';
        utSec = finalEntry(1);
        
        normFact = bodyInfo.radius;

        [~, ~, alt] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo);

        if(lbAlt == ubAlt)
            c = [0 0];
            ceq(1) = alt - ubAlt;
        else
            c(1) = lbAlt - alt;
            c(2) = alt - ubAlt;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end