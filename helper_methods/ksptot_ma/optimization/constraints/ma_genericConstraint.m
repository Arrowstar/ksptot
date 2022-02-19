function [c, ceq, value, lb, ub, type, eventNum] = ma_genericConstraint(stateLog, eventID, funcHandle, lb, ub, bodyIDApply, celBodyData, maData, type)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1;

    eventNum = [];
    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end
    
    if(isempty(eventNum))
        warning('Could not find event with ID %f when evaluating optimization constraints.  Skipping.', eventID);
        
        c = [0 0];
        ceq = [0];
        value = [0];
        
        return;
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    if(isempty(eventLog))
        warning('Empty event log when evaluating constraint at event %u of type "%s".  Skipping.', eventID, type);
        
        c = [0 0];
        ceq = [0];
        value = [0];
        
        return;
    end
    
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(strcmpi(type,'Central Body ID'))
           [c, ceq, value, lb, ub] = ma_centralBodyConstraint(stateLog, eventID, bodyIDApply, bodyIDApply, bodyIDApply, celBodyData, maData);
    
    elseif(strcmpi(type,'Elevation Angle of Ref. Celestial Body'))
        value = funcHandle(finalEntry, false, maData);
        
        if(lb == ub)
            c = [0 0];
            ceq(1) = value - ub;
        else
            c(1) = lb - value;
            c(2) = value - ub;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        if(bodyID == bodyIDApply || bodyIDApply==-1)
            value = funcHandle(finalEntry, false, maData);
            
            if(lb == ub)
                c = [0 0];
                ceq(1) = value - ub;
            else
                c(1) = lb - value;
                c(2) = value - ub;
                ceq = [0];
            end
            c = c/normFact;
            ceq = ceq/normFact;
        else
            c = [0 0];
            ceq = [0];
            value = [0];
        end
    end
end