function [c, ceq] = ma_normalDistFromOtherSCConstraint(stateLog, eventID, lbDist, ubDist, otherSCIDApply, subtype, celBodyData, maData)
%ma_normalDistFromOtherSCConstraint Summary of this function goes here
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
        
        nDist = ma_GADistToRefSCTask(finalEntry, subtype, maData, otherSCInfo, celBodyData);

%         rVect = getAbsPositBetweenSpacecraftAndBody(finalEntry(1), finalEntry(2:4)', bodyInfo, otherSCInfo, celBodyData);
%         
%         lvlhCurviPosDeputy = computeLvlhCurviPos(finalEntry(2:4)', finalEntry(5:7)', rVect, bodyInfo.gm);
%         nDist = lvlhCurviPosDeputy(3);
        
%         rVectNTW = getECI2NTWdvVect(rVect, finalEntry(2:4)', finalEntry(5:7)');
%         nDist = rVectNTW(2);

        if(lbDist == ubDist)
            c = [0 0];
            ceq(1) = nDist - ubDist;
        else
            c(1) = lbDist - nDist;
            c(2) = nDist - ubDist;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end