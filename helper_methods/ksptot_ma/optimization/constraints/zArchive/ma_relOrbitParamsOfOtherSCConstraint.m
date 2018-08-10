function [c, ceq] = ma_relOrbitParamsOfOtherSCConstraint(stateLog, eventID, lbValue, ubValue, otherSCIDApply, constType, celBodyData, maData)
%ma_relOrbitParamsOfOtherSCConstraint Summary of this function goes here
%   Detailed explanation goes here
    
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
        otherScBodyInfo = getBodyInfoByNumber(otherSCInfo.parentID, celBodyData);
        
        eventLog = stateLog(stateLog(:,13)==eventNum,:);
        finalEntry = eventLog(end,:);

        bodyID = finalEntry(8);
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        
        gmu = bodyInfo.gm;
        ut = finalEntry(1);
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';

        [sma, ecc, inc, raan, arg, ~] = getKeplerFromState(rVect,vVect,gmu);
        
        switch constType
            case 'sma'
                value = otherSCInfo.sma - sma;
                normFact = bodyInfo.radius;
            case 'ecc'
                value = otherSCInfo.ecc - ecc;
                normFact = 1;
            case 'inc'
                hHat1 = normVector(crossARH(rVect,vVect));
                
                [rVectOsc, vVectOsc] = getStateAtTime(otherSCInfo, ut, otherScBodyInfo.gm);
                hHat2 = normVector(crossARH(rVectOsc,vVectOsc));
                
                value = dang(hHat1, hHat2);
                normFact = 1;
            case 'raan'
                value = otherSCInfo.raan - raan;
                normFact = 1;
            case 'arg'
                value = otherSCInfo.arg - arg;
                normFact = 1;
        end
        
        if(lbValue == ubValue)
            c = [0 0];
            ceq(1) = value - ubValue;
        else
            c(1) = lbValue - value;
            c(2) = value - ubValue;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    end
end

