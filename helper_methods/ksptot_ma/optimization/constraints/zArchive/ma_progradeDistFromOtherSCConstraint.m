function [c, ceq] = ma_progradeDistFromOtherSCConstraint(stateLog, eventID, lbDist, ubDist, otherSCIDApply, subtype, celBodyData, maData)
%ma_progradeDistFromOtherSCConstraint Summary of this function goes here
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
        
%         bodyID = finalEntry(8);
%         bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        
        pDist = ma_GADistToRefSCTask(finalEntry, subtype, maData, otherSCInfo, celBodyData);

%         rVect = getAbsPositBetweenSpacecraftAndBody(finalEntry(1), finalEntry(2:4)', bodyInfo, otherSCInfo, celBodyData);
%         
%         lvlhCurviPosDeputy = computeLvlhCurviPos(finalEntry(2:4)', finalEntry(5:7)', rVect, bodyInfo.gm);
%         pDist = lvlhCurviPosDeputy(2);
        
        if(lbDist == ubDist)
            c = [0 0];
            ceq(1) = pDist - ubDist;
        else
            c(1) = lbDist - pDist;
            c(2) = pDist - ubDist;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end