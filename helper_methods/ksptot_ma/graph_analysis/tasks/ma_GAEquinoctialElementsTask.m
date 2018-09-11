function datapt = ma_GAEquinoctialElementsTask(stateLogEntry, subTask, celBodyData)
%ma_GAEquinoctialElementsTask Summary of this function goes here
%   Detailed explanation goes here
    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = stateLogEntry(2:4)';
    vVect = stateLogEntry(5:7)';
    
    [~, ecc, inc, raan, arg, ~] = getKeplerFromState(rVect,vVect,gmu);

    switch subTask
        case 'H1'
            datapt = ecc * cos(arg + raan); %http://www.cdeagle.com/pdf/mee.pdf
        case 'K1'
            datapt = ecc * sin(arg + raan); %http://www.cdeagle.com/pdf/mee.pdf
        case 'H2'
            datapt = tan(inc/2)*cos(raan); %http://www.cdeagle.com/pdf/mee.pdf
        case 'K2'
            datapt = tan(inc/2)*sin(raan); %http://www.cdeagle.com/pdf/mee.pdf
    end
end

