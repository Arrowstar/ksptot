function [c, ceq] = ma_XenonPropMassConstraint(stateLog, eventID, lbProp, ubProp, bodyIDApply, celBodyData, maData)
%ma_liqFuelOxPropMassConstraint Summary of this function goes here
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
    
    propMass = finalEntry(12);
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        if(lbProp == ubProp)
            c = [0 0];
            ceq(1) = propMass - ubProp;
        else
            c(1) = lbProp - propMass;
            c(2) = propMass - ubProp;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end