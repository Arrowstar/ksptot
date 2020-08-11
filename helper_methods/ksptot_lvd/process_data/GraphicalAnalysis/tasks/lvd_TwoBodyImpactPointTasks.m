function datapt = lvd_TwoBodyImpactPointTasks(stateLogEntry, subTask)
%lvd_SteeringAngleTask Summary of this function goes here
%   Detailed explanation goes here
    global number_state_log_entries_per_coast;

    ut = stateLogEntry.time;
    rVect = stateLogEntry.position;
    vVect = stateLogEntry.velocity;
    gmu = stateLogEntry.centralBody.gm;
    bodyRadius = stateLogEntry.centralBody.radius;
    
    [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
    [~, rPe] = computeApogeePerigee(sma, ecc);
    
    if(rPe > bodyRadius)
        datapt = NaN;
    else
        if(isempty(number_state_log_entries_per_coast))
            number_state_log_entries_per_coast = 10;
        end
        
        truTarget = 2*pi - computeTrueAFromRadiusEcc(bodyRadius, sma, ecc); %2*pi - tru to get the descending tru anomaly

        maStateLog = stateLogEntry.getMAFormattedStateLogMatrix(false);

        eventNum = 1;
        considerSoITransitions = false;
        soiSkipIds = [];
        refBody = stateLogEntry.centralBody;
        massLoss = getDefaultMassLoss();
        orbitDecay = getDefaultOrbitDecay();
        celBodyData = stateLogEntry.celBodyData;

        eventLog = ma_executeCoast_goto_tru(truTarget, maStateLog, eventNum, considerSoITransitions, soiSkipIds, refBody, massLoss, orbitDecay, celBodyData);

        eventLogEnd = eventLog(end,:);
        iptUt = eventLogEnd(1);
        iptRVect = eventLogEnd(2:4);

        [lat, long, ~, ~, ~, ~, ~, ~] = getLatLongAltFromInertialVect(iptUt, iptRVect, refBody);
        
        datapt = -1;
        switch subTask
            case 'timeToImpact'
                datapt = iptUt - ut;
            case 'longitude'
                datapt = rad2deg(long);
            case 'latitude'
                datapt = rad2deg(lat);
        end
    end
end

function massloss = getDefaultMassLoss()
    massloss = struct();
    massloss.use  = false;
    massloss.lossConvert = [];
end