function [c, ceq] = ma_distFromBodyConstraint(stateLog, eventID, lbDist, ubDist, bodyIDApply, celBodyData, maData)
%ma_distFromBodyConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = 1;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
%         hMAMainGUI = findall(0,'tag','ma_MainGUI');
%         maData = getappdata(hMAMainGUI,'ma_data');
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    if(bodyIDApply==-1)
        c = [0]; %#ok<*NBRAK>
        ceq = [0];
    else
        bodyOtherID = bodyIDApply;
        bodyOtherInfo = getBodyInfoByNumber(bodyOtherID, celBodyData);

        distBest = Inf;
        eventLog = stateLog(stateLog(:,13)==eventNum,:);

        bodyIDs = unique(eventLog(:,8));
        for(i=1:length(bodyIDs)) %#ok<*NO4LP>
            bodyID = bodyIDs(i);
            bodySCInfo = getBodyInfoByNumber(bodyID, celBodyData);

            bodyEventLog = eventLog(eventLog(:,8) == bodyID, :);
            time = bodyEventLog(:,1)';
            rVectSC = bodyEventLog(:,2:4)';
            dVect = getAbsPositBetweenSpacecraftAndBody(time, rVectSC, bodySCInfo, bodyOtherInfo, celBodyData);
%             dist = norm(dVect);
            dist = min(sqrt(sum(abs(dVect).^2,1)));
            
            if(dist < distBest)
                distBest = dist;
            end
        end
        
        if(lbDist == ubDist)
            c = [0 0];
            ceq(1) = distBest - ubDist;
        else
            c(1) = distBest - ubDist;
            c(2) = lbDist - distBest;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end

