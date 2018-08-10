function [c, ceq] = ma_equiH1Constraint(stateLog, eventID, lbH1, ubH1, bodyIDApply, celBodyData, maData)
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
    
    bodyEventLog = eventLog(eventLog(:,8)==bodyIDApply,:);
    if(isempty(bodyEventLog))
        finalEntry = eventLog(end,:);
    else
        finalEntry = bodyEventLog(end,:);
    end
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        gmu = bodyInfo.gm;
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';

        [~, ecc, ~, raan, arg, ~] = getKeplerFromState(rVect,vVect,gmu);
        h1 = ecc * cos(arg + raan); %http://www.cdeagle.com/pdf/mee.pdf
        
        if(lbH1 == ubH1)
            c = [0 0];
            ceq(1) = h1 - ubH1;
        else
            c(1) = lbH1 - h1;
            c(2) = h1 - ubH1;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end