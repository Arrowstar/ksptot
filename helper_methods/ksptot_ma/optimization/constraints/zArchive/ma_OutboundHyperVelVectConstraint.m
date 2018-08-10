function [c, ceq] = ma_OutboundHyperVelVectConstraint(stateLog, eventID, lb, ub, bodyIDApply, celBodyData, maData, constType)
%ma_OutboundHyperVelVectConstraint Summary of this function goes here
%   Detailed explanation goes here
    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
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
        
        [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
        if(ecc > 1)
            [~, OUnitVector] = computeHyperSVectOVect(sma, ecc, inc, raan, arg, tru, gmu);

            switch constType
                case 'x'
                    vComp = OUnitVector(1);
                case 'y'
                    vComp = OUnitVector(2);
                case 'z'
                    vComp = OUnitVector(3);
                case 'mag'
                    vComp = sqrt(-gmu/sma); %from vis-viva equation; not actually a vector component but wanted to shoe-horn it in here
            end

            if(lb == ub)
                c = [0 0];
                ceq(1) = vComp - ub;
            else
                c(1) = lb - vComp;
                c(2) = vComp - ub;
                ceq = [0]; %#ok<NBRAK>
            end
        else
            c = [0 0];
            ceq = [0]; %#ok<NBRAK>
        end
    else
        c = [0 0];
        ceq = [0]; %#ok<NBRAK>
    end
end