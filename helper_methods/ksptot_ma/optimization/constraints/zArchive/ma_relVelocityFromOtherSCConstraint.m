function [c, ceq] = ma_relVelocityFromOtherSCConstraint(stateLog, eventID, lbDist, ubDist, otherSCIDApply, celBodyData, maData)
%ma_radialDistFromOtherSCConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end
    
    if(otherSCIDApply==-1)
        c = [0 0];
        ceq = [0];
    else
        otherSCID = otherSCIDApply;
        otherSCInfo = getOtherSCInfoByID(maData, otherSCID);
        
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        finalEntry = eventLog(end,:);
        
        bodyID = finalEntry(8);
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        
        [~,vVect] = getAbsPositBetweenSpacecraftAndBody(finalEntry(1), finalEntry(2:4)', bodyInfo, otherSCInfo, celBodyData, finalEntry(5:7)');
        vMag = norm(vVect);
        
        if(lbDist == ubDist)
            c = [0 0];
            ceq(1) = vMag - ubDist;
        else
            c(1) = lbDist - vMag;
            c(2) = vMag - ubDist;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end