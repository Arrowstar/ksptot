function eventLog = ma_executeCoast_goto_node(node, initialState, eventNum, considerSoITransitions, refBody, celBodyData)
%ma_executeCoast_goto_asc_node Summary of this function goes here
%   Detailed explanation goes here   
    bodyID = initialState(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';
    
    [sma, ecc, inc, raan, arg, truINI] = getKeplerFromState(rVect,vVect,gmu);
    
    if(isempty(refBody))
        refBody.id = -1;
    end
 
    try
        [truOfAN, truOfDN] = computeTruOfAscDescNodes(sma, ecc, inc, raan, arg, gmu,[0,0,1]);
    catch ME
        warnStr ='Error computing nodes, setting node anomaly = 0.';
        addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
        truOfAN = 0;
        truOfDN = 0;
    end
    
    if(isnan(truOfAN))
        truOfAN = 0;
        warnStr ='Error computing nodes, setting node anomaly = 0.';
        addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
    end
    if(isnan(truOfDN))
        truOfDN = 0;
        warnStr ='Error computing nodes, setting node anomaly = 0.';
        addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
    end
    
    if(strcmpi(node, 'asc'))
        truOfN = truOfAN;
    else
        truOfN = truOfDN;
    end
    
    if(considerSoITransitions)
        truTarget = truOfN;
        if(refBody.id == bodyID)
            dt = getDtToTru(truTarget, sma, ecc, truINI, gmu);
            if(dt < 0)
                dt = 0;
                warnStr =['Reverse time error while computing node position.  Node may be behind spacecraft on hyperbolic orbit.'];
                addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
            end
            utTru = initialState(1) + dt;
        else
            utTru = Inf;
        end
        
        soITrans = findSoITransitions(initialState, utTru, celBodyData);
        SoITransEventLog = [];
        if(~isempty(soITrans) && min(soITrans(:,2)) < utTru)            
            SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, utTru, celBodyData, soITrans);
            goToUTEventLog = ma_executeCoast_goto_node(node, SoITransEventLog(end,:), eventNum, true, refBody, celBodyData);
        else 
            goToUTEventLog = ma_executeCoast_goto_node(node, initialState, eventNum, false, refBody, celBodyData);
        end
        eventLog = [SoITransEventLog; goToUTEventLog];
        return;
    end
    
    eventLog = ma_executeCoast_goto_tru(truOfN, initialState, eventNum, considerSoITransitions, refBody, celBodyData);
end

