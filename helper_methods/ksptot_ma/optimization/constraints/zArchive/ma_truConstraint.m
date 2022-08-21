function [c, ceq] = ma_truConstraint(stateLog, eventID, lbTru, ubTru, bodyIDApply, celBodyData, maData)
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

        [~, ~, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,gmu);

        if(lbTru <= 0 && ubTru <= 0)
            lbTru = AngleZero2Pi(lbTru);
            ubTru = AngleZero2Pi(ubTru);
        elseif(lbTru<0 && ubTru >=0)
            if(tru >= AngleZero2Pi(lbTru) && tru <= 2*pi)
                lbTru = AngleZero2Pi(lbTru);
                ubTru = 2*pi;
            elseif(tru >= 0 && tru <= ubTru)
                lbTru = 0;
            end
        end
        
        if(lbTru == ubTru)
            c = [0 0];
            ceq(1) = tru - ubTru;
        else
            c(1) = lbTru - tru;
            c(2) = tru - ubTru;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end