function [c, ceq] = ma_raanConstraint(stateLog, eventID, lbRAAN, ubRAAN, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here
    normFact = pi;

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

        [~, ~, ~, raan, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
        
        if(lbRAAN <= 0 && ubRAAN <= 0)
            lbRAAN = AngleZero2Pi(lbRAAN);
            ubRAAN = AngleZero2Pi(ubRAAN);
        elseif(lbRAAN<0 && ubRAAN >=0)
            if(raan >= AngleZero2Pi(lbRAAN) && raan <= 2*pi)
                lbRAAN = AngleZero2Pi(lbRAAN);
                ubRAAN = 2*pi;
            elseif(raan >= 0 && raan <= ubRAAN)
                lbRAAN = 0;
            end
        end

        if(lbRAAN == ubRAAN)
            c = [0 0];
            ceq(1) = raan - ubRAAN;
        else
            c(1) = lbRAAN - raan;
            c(2) = raan - ubRAAN;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end

