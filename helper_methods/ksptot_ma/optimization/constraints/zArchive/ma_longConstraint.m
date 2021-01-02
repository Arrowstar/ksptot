function [c, ceq] = ma_longConstraint(stateLog, eventID, lbLong, ubLong, bodyIDApply, celBodyData, maData)
%ma_semiMajorAxisConstraint Summary of this function goes here
%   Detailed explanation goes here

    normFact = 360;

    if(ischar(eventID) && strcmpi(eventID,'final'))
        eventNum = max(stateLog(:,13));
    else
        [~, eventNum] = getEventByID(eventID, maData.script);
    end

    eventLog = stateLog(stateLog(:,13)==eventNum,:);
    finalEntry = eventLog(end,:);
    
    bodyID = finalEntry(8);

    if(bodyID == bodyIDApply || bodyIDApply==-1)
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        rVect = finalEntry(2:4)';
        vVect = finalEntry(5:7)';
        utSec = finalEntry(1);

        [~, long, ~] = getLatLongAltFromInertialVect(utSec, rVect, bodyInfo, vVect);
        lbLong = deg2rad(lbLong);
        ubLong = deg2rad(ubLong);
        
        %account for angle wrapping on bounds
        if(lbLong <= 0 && ubLong <= 0)
            lbLong = AngleZero2Pi(lbLong);
            ubLong = AngleZero2Pi(ubLong);
        elseif(lbLong<=0 && ubLong >=0)
            if(long >= AngleZero2Pi(lbLong) && long <= 2*pi)
                lbLong = AngleZero2Pi(lbLong);
                ubLong = 2*pi;
            elseif(long >= 0 && long <= ubLong)
                lbLong = 0;
            end
        end
    
        long = rad2deg(long);
        lbLong = rad2deg(lbLong);
        ubLong = rad2deg(ubLong);
        if(lbLong == ubLong)
            c = [0 0];
            ceq(1) = long - ubLong;
        else
            c(1) = lbLong - long;
            c(2) = long - ubLong;
            ceq = [0];
        end
        c = c/normFact;
        ceq = ceq/normFact;
    else
        c = [0 0];
        ceq = [0];
    end
end