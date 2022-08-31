function [c, ceq] = ma_surfaceVelConstraint(stateLog, eventID, lbHorzVel, ubHorzVel, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here

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
        horzVel = ma_GALongLatAltTasks(finalEntry, 'horzVel', celBodyData);

        if(lbHorzVel == ubHorzVel)
            c = [0 0];
            ceq(1) = horzVel - ubHorzVel;
        else
            c(1) = lbHorzVel - horzVel;
            c(2) = horzVel - ubHorzVel;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end