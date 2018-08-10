function [c, ceq] = ma_distFromOtherSCConstraint(stateLog, eventID, lbDist, ubDist, otherSCIDApply, celBodyData, maData)
%ma_distFromOtherSCConstraint Summary of this function goes here
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
        
        distBest = Inf;
        eventLog = stateLog(stateLog(:,13)==eventNum,:);

        bodyIDs = unique(eventLog(:,8));
        for(i=1:length(bodyIDs)) %#ok<*NO4LP>
            bodyID = bodyIDs(i);
            bodySCInfo = getBodyInfoByNumber(bodyID, celBodyData);

            bodyEventLog = eventLog(eventLog(:,8) == bodyID, :);
            time = bodyEventLog(:,1)';
            rVectSC = bodyEventLog(:,2:4)';
            dVect = getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodySCInfo, otherSCInfo, celBodyData);
            dist = min(sqrt(sum(abs(dVect).^2,1)));
            
            if(dist < distBest)
                distBest = dist;
            end
        end

        if(lbDist == ubDist)
            c = [0 0];
            ceq(1) = distBest - ubDist;
        else
            c(1) = lbDist - distBest;
            c(2) = distBest - ubDist;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end