function xferOrbits = getMultiFlybyXferOrbits(x, numRev, r1Sc, r2Sc, v1Sc, v2Sc, bodiesInfo, celBodyData)
%getMultiFlybyXferOrbits Summary of this function goes here
%   Detailed explanation goes here

%     [~, ~, secInDay, ~] = getSecondsInVariousTimeUnits();

    flybyBodies = bodiesInfo(2:end-1);
    numFB = length(flybyBodies);
    numBodies = length(bodiesInfo);
    numREVS = length(bodiesInfo) - 1;
    
    if(numFB == 0)
        tm = x(:,3);
        numRevInds = x(:,4);
    else
        tm = x(:,numBodies+1:numBodies+numREVS);
        numRevInds = x(:,numBodies+1+numREVS:end);
    end

    tm = round(tm);
    tm(tm==2) = -1;
    numTM = size(tm,2);
    
    x = x(:,1:end-numTM);
    daTimes = cumsum(x,2);

    pBodyInfo = getParentBodyInfo(bodiesInfo{1}, celBodyData);
    gmu = pBodyInfo.gm;
    
    xferOrbits = zeros(length(bodiesInfo)-1,10);
    for(i=1:length(bodiesInfo)-1) %#ok<*NO4LP>
        b1Info = bodiesInfo{i};
        b2Info = bodiesInfo{i+1};
        
        t1 = daTimes(i);
        t2 = daTimes(i+1);
        dt = t2 - t1;
        
        [r1, ~] = getStateAtTime(b1Info, t1, getParentGM(b1Info, celBodyData));
        [r2, ~] = getStateAtTime(b2Info, t2, getParentGM(b2Info, celBodyData));
        [v1, v2] = lambert(r1', r2', tm(i)*dt/86400, numRev(i), gmu);

        if(any(isnan(v1)) || any(isnan(v2))) %failsafe incase the solver does something dumb
            v1 = v1Sc(:,i)';
            v2 = v2Sc(:,i)';
        end
        
        [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState(r1,v1',gmu);
        [~, ~, ~, ~, ~, tru2] = vect_getKeplerFromState(r2,v2',gmu);
        
        if(inc >= pi/2)
            [v1, v2] = lambert(r1', r2', -tm(i)*dt/86400, numRev(i), gmu);

            [sma, ecc, inc, raan, arg, tru] = vect_getKeplerFromState(r1,v1',gmu);
            [~, ~, ~, ~, ~, tru2] = vect_getKeplerFromState(r2,v2',gmu);
        end
        
        orbit = [sma ecc inc raan arg tru tru2 t1 t2 gmu];
        xferOrbits(i,:) = orbit;
    end   
end

