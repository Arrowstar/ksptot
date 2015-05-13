function  [returnValue, returnRevs] = ma_convertCoastValue(stateRowStartEvent, stateRowEndEvent, prevStateRowEndEvent, convertTo, celBodyData)
%ma_convertCoastValue Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateRowEndEvent(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    rVect = stateRowEndEvent(2:4);
    vVect = stateRowEndEvent(5:7);
    gmu = bodyInfo.gm;
    [sma, ecc, ~, ~, ~, tru] = getKeplerFromState(rVect,vVect,gmu);
    
    switch(convertTo)
        case 'Go to UT'
            returnValue = stateRowEndEvent(1);
            returnRevs = 0;
        case 'Go to Delta Time'
            returnValue = stateRowEndEvent(1) - prevStateRowEndEvent(1);
            returnRevs = 0;
        case 'Go to True Anomaly'
            if(ecc < 1.0)
                period = computePeriod(sma, gmu);
                deltaT = stateRowEndEvent(1) - prevStateRowEndEvent(1);
                returnRevs = floor(deltaT/period);
            else
                returnRevs = NaN;
            end
            
            tru = rad2deg(tru);
            returnValue = tru;
        otherwise
            returnValue = [];
    end
end

