function [c, ceq] = ma_latConstraint(stateLog, eventID, lbLat, ubLat, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here

    normFact = pi;

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
        utSec = finalEntry(1);

        [lat, ~, ~] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo, vVect);

        lat = rad2deg(lat);
        if(lbLat == ubLat)
            c = [0 0];
            ceq(1) = lat - ubLat;
        else
            c(1) = lbLat - lat;
            c(2) = lat - ubLat;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end