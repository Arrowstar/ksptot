function eventLog = ma_executeDocking(dockingEvent, initialState, eventNum, oScs, celBodyData)
%ma_executeDocking Summary of this function goes here
%   Detailed explanation goes here
    global number_state_log_entries_per_coast;

    oSc = [];
    for(i=1:length(oScs)) %#ok<NO4LP>
        if(oScs{i}.id == dockingEvent.oScId)
            oSc = oScs{i};
            break;
        end
    end
    
    if(isempty(oSc))
        errorStr = 'Cannot dock: Could not identify Other Spacecraft selected in Docking UI.';
        addToExecutionErrors(errorStr, eventNum, initialState(8), celBodyData);
        
        eventLog = initialState;
        eventLog(:,13) = eventNum;
        return;
    end
    
    bodyInfo = getBodyInfoByNumber(oSc.parentID, celBodyData);
    ut = linspace(initialState(1), initialState(1) + dockingEvent.undockTime, number_state_log_entries_per_coast+1);
    dt = ut(2:end) - ut(1);
    
    [rVect, vVect] = getStateAtTime(oSc, ut, bodyInfo.gm);
    
    masses = initialState(9:12);
        
    massLoss = dockingEvent.massloss;
    if(massLoss.use == 1 && ~isempty(massLoss.lossConvert))
        resRates = ma_getResRates(massLoss);
               
        eventLog = [ut(2:end)', ...
                    rVect(:,2:end)', ...
                    vVect(:,2:end)', ...
                    oSc.parentID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
                
        for(i=1:length(resRates)) %#ok<*NO4LP>
            eventLog(:,ma_resNumToStateLogCol(i)) = eventLog(1,ma_resNumToStateLogCol(i)) * ones(size(ut(2:end)))' + dt'*resRates(i);
        end
    else
        eventLog = [ut(2:end)', ...
                    rVect(:,2:end)', ...
                    vVect(:,2:end)', ...
                    oSc.parentID*ones(size(dt')), ...
                    repmat(masses,length(dt),1), ...
                    eventNum*ones(size(dt'))];
    end
    
    a = 1;
end

