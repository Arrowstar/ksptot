function [c, ceq] = ma_argConstraint(stateLog, eventID, lbArg, ubArg, bodyIDApply, celBodyData, maData)
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
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        gmu = bodyInfo.gm;
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';

        [~, ~, ~, ~, arg, ~] = getKeplerFromState(rVect,vVect,gmu);
        
        %account for angle wrapping on bounds
        if(lbArg <= 0 && ubArg <= 0)
            lbArg = AngleZero2Pi(lbArg);
            ubArg = AngleZero2Pi(ubArg);
        elseif(lbArg<=0 && ubArg >=0)
            if(arg >= AngleZero2Pi(lbArg) && arg <= 2*pi)
                lbArg = AngleZero2Pi(lbArg);
                ubArg = 2*pi;
            elseif(arg >= 0 && arg <= ubArg)
                lbArg = 0;
            end
        end

        if(lbArg == ubArg)
            c = [0 0];
            ceq(1) = arg - ubArg;
        else
            c(1) = lbArg - arg;
            c(2) = arg - ubArg;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end

