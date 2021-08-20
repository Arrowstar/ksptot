function datapt = ma_GADistToCelBodyTask(stateLogEntry, subTask, refBodyInfo, celBodyData)
%ma_GADistToCelBodyTask Summary of this function goes here
%   Detailed explanation goes here

    rVect = stateLogEntry(2:4)';
    bodyID = stateLogEntry(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    if(isempty(refBodyInfo))
        datapt = -1;
        return;
    end
    
    dVect = getAbsPositBetweenSpacecraftAndBody(stateLogEntry(1), stateLogEntry(2:4)',...
            bodyInfo, refBodyInfo, celBodyData);

    switch subTask
        case 'distToCelBody'
            datapt = norm(dVect);
            
        case 'CelBodyElevation'
            angle = dang(rVect,dVect);
            
            if(angle <= pi/2)
                datapt = rad2deg(pi/2 - angle);
            else
                datapt = rad2deg(-(angle - pi/2));
            end
    end
end

