function eventLog = ma_executeCoast_goto_ut(ut, initialState, eventNum, considerSoITransitions, soiSkipIds, celBodyData)
%ma_executeCoast_goto_ut Summary of this function goes here
%   Detailed explanation goes here 
    global number_state_log_entries_per_coast;
    utINI = initialState(1);
    
    if(utINI > ut)
        errorStr = ['Cannot coast to UT: ', num2str(ut), '.  Reverse time error, skipping event (any revs prior to this event may still be executed).'];
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    elseif(utINI == ut)
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    if(considerSoITransitions)
        soITrans = findSoITransitions(initialState, ut, soiSkipIds, celBodyData);
        SoITransEventLog = [];
        if(~isempty(soITrans))
            SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, ut, celBodyData, soITrans);
            goToUTEventLog = ma_executeCoast_goto_ut(ut, SoITransEventLog(end,:), eventNum, true, soiSkipIds, celBodyData);
        else 
            goToUTEventLog = ma_executeCoast_goto_ut(ut, initialState, eventNum, false, soiSkipIds, celBodyData);
        end
        eventLog = [SoITransEventLog; goToUTEventLog];
        return;
    end
    
    bodyID = initialState(8);
    
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';

    masses = initialState(9:12);
    
    [sma, ecc, inc, raan, arg, truINI] = getKeplerFromState(rVect,vVect,gmu);
    meanINI = computeMeanFromTrueAnom(truINI, ecc);
    meanMotion = computeMeanMotion(sma, gmu);
       
    if(ecc < 1)
        period = computePeriod(sma, gmu);
        numStepMult = max(round((ut - utINI)/period), 1);
    else
        numStepMult = 1;
    end
    
%     numPts = 1000;
    numPts = number_state_log_entries_per_coast;
    coast_ut_step_size = (ut - utINI)/(numPts*numStepMult);
    if((ut - utINI)/coast_ut_step_size > 250000)
        coast_ut_step_size = (ut - utINI)/250000;
    end
    ut = unique([utINI:coast_ut_step_size:ut, ut]);
	dt = ut(2:end) - ut(1);

    sma  = sma*ones(size(dt));
    ecc  = ecc*ones(size(dt));
    inc  = inc*ones(size(dt));
    raan = raan*ones(size(dt));
    arg  = arg*ones(size(dt));

    mean = meanINI + meanMotion.*dt;
    tru = computeTrueAnomFromMean(mean, ecc);

    [rVectUT,vVectUT]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);

    eventLog = [(ut(2:end))', ...
                rVectUT', ...
                vVectUT', ...
                bodyID*ones(size(dt')), ...
                repmat(masses,length(dt),1), ...
                eventNum*ones(size(dt'))];
end

