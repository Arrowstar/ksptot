function datapt = ma_GAKeplerElementsTask(stateLogEntry, subTask, celBodyData)
%ma_GAKeplerElementsTask Summary of this function goes here
%   Detailed explanation goes here

    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = stateLogEntry(2:4)';
    vVect = stateLogEntry(5:7)';
    
    [sma, ecc, inc, raan, arg, tru] = getKeplerFromState(rVect,vVect,gmu);
        
    switch subTask
        case 'sma'
            datapt = sma;
        case 'ecc'
            datapt = ecc;
        case 'inc'
            datapt = rad2deg(inc);
        case 'raan'
            datapt = rad2deg(raan);
        case 'arg'
            datapt = rad2deg(arg);
        case 'tru'
            datapt = rad2deg(tru);
        case 'mean'
            datapt = rad2deg(computeMeanFromTrueAnom(tru, ecc));
        case 'period'
            if(sma <= 0)
                datapt = NaN;
            else
                datapt = computePeriod(sma, gmu);
            end
        case 'sunRX'
            bodySCInfo = getBodyInfoByNumber(bodyID, celBodyData);
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodySCInfo, celBodyData.sun, celBodyData);
            datapt = -dVect(1); %neg sign to go from spacecraft to sun -> sun to spacecraft
        case 'sunRY'
            bodySCInfo = getBodyInfoByNumber(bodyID, celBodyData);
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodySCInfo, celBodyData.sun, celBodyData);
            datapt = -dVect(2); %neg sign to go from spacecraft to sun -> sun to spacecraft
        case 'sunRZ'
            bodySCInfo = getBodyInfoByNumber(bodyID, celBodyData);
            dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
                    bodySCInfo, celBodyData.sun, celBodyData);
            datapt = -dVect(3); %neg sign to go from spacecraft to sun -> sun to spacecraft
        case 'rPe'
            [~, rPe] = computeApogeePerigee(sma, ecc);
            datapt = rPe;
        case 'rAp'
            [rAp, ~] = computeApogeePerigee(sma, ecc);
            datapt = rAp;
    end
end

