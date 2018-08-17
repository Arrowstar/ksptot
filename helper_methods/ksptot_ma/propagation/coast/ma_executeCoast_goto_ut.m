function eventLog = ma_executeCoast_goto_ut(ut, initialState, eventNum, considerSoITransitions, soiSkipIds, massLoss, orbitDecay, celBodyData)
%ma_executeCoast_goto_ut Summary of this function goes here
%   Detailed explanation goes here 
    global number_state_log_entries_per_coast;
	numPts = number_state_log_entries_per_coast;
       
    utINI = initialState(1);
    
    if(utINI > ut)
%         errorStr = ['Cannot coast to UT: ', num2str(ut), '.  Reverse time error, skipping event (any revs prior to this event may still be executed).'];
%         addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
%         
%         eventLog = initialState;
%         eventLog(:,13) = eventNum;
%         return;
    elseif(utINI == ut)
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    if(considerSoITransitions)
        soITrans = findSoITransitions(initialState, ut, soiSkipIds, massLoss, orbitDecay, celBodyData);
        SoITransEventLog = [];
        if(~isempty(soITrans))
            SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, ut, soiSkipIds, massLoss, orbitDecay, celBodyData, soITrans);
            goToUTEventLog = ma_executeCoast_goto_ut(ut, SoITransEventLog(end,:), eventNum, true, soiSkipIds, massLoss, orbitDecay, celBodyData);
        else 
            goToUTEventLog = ma_executeCoast_goto_ut(ut, initialState, eventNum, false, soiSkipIds, massLoss, orbitDecay, celBodyData);
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
    
    coast_ut_step_size = (ut - utINI)/(numPts*numStepMult);
    if((ut - utINI)/coast_ut_step_size > 250000)
        coast_ut_step_size = (ut - utINI)/250000;
    end
    ut = unique([utINI:coast_ut_step_size:ut, ut],'stable');
	dt = ut(2:end) - ut(1);

    sma  = sma*ones(size(dt));
    ecc  = ecc*ones(size(dt));
    inc  = inc*ones(size(dt));
    raan = raan*ones(size(dt));
    arg  = arg*ones(size(dt));

    mean = meanINI + meanMotion.*dt;
    
    if(orbitDecay.use)
        vesselMass = sum(masses);
        vesselArea = orbitDecay.scArea;
        f107Flux = orbitDecay.solarFlux;
        geomagneticIndex = orbitDecay.geoMagInd;
        [sma, ecc, mean] = computeAtmosphericDecay(ut(2:end), sma, ecc, mean, bodyInfo, vesselMass, vesselArea, f107Flux, geomagneticIndex);
    end
    
    tru = computeTrueAnomFromMean(mean, ecc);
    
    [rVectUT,vVectUT]=vect_getStatefromKepler(sma, ecc, inc, raan, arg, tru, gmu);
    
    if(massLoss.use == 1 && ~isempty(massLoss.lossConvert))
        resRates = ma_getResRates(massLoss);
               
        eventLog = [(ut(2:end))', ...
                    rVectUT', ...
                    vVectUT', ...
                    bodyID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
                
        for(i=1:length(resRates)) %#ok<*NO4LP>
            eventLog(:,ma_resNumToStateLogCol(i)) = eventLog(1,ma_resNumToStateLogCol(i)) * ones(size(ut(2:end)))' + dt'*resRates(i);
        end
    else
        eventLog = [(ut(2:end))', ...
                    rVectUT', ...
                    vVectUT', ...
                    bodyID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
    end
end

