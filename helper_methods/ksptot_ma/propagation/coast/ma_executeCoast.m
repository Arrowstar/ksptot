function eventLog = ma_executeCoast(coastEvent, initialState, eventNum, celBodyData)
%ma_executeCoast Summary of this function goes here
%   Detailed explanation goes here   
    refBody = coastEvent.refBody;
    if(~isempty(refBody))
        refBodyID = refBody.id;
    else
        refBodyID = -1;
    end
    bodyID = initialState(8);

    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    gmu = bodyInfo.gm;
    utINI = initialState(1);
    rVect = initialState(2:4)';
    vVect = initialState(5:7)';
    
    [sma, ecc, ~, ~, ~, ~] = getKeplerFromState(rVect,vVect,gmu);
    
    soiSkipIds = coastEvent.soiSkipIds;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Propagate through the n revs, if applicable
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    eventLog = [];
    revs = coastEvent.revs;
    if(revs > 0)
        if(ecc < 1)
            period = computePeriod(sma, gmu);  
            
            maxUT = utINI+revs*period; 
            soITrans = findSoITransitions(initialState, maxUT, soiSkipIds, celBodyData);
            if(~isempty(soITrans) && min(soITrans(:,2)) < maxUT)
                [~,ind] = ismember(refBodyID,soITrans(:,4));
                
                if(ind > 0)
                    SoITransUT = soITrans(ind,2);
                    advSoITrans = soITrans(soITrans(:,2)>=SoITransUT,:);
                    SoITransEventLog1 = ma_executeCoast_goto_ut(SoITransUT, initialState, eventNum, true, soiSkipIds, celBodyData);
                    SoITransEventLog2 = ma_executeCoast_goto_soi_trans(SoITransEventLog1(end,:), eventNum, 10, soiSkipIds, celBodyData, advSoITrans); %what is that 10 for?
                    SoITransEventLog = [SoITransEventLog1; SoITransEventLog2];
                else
                    SoITransEventLog = ma_executeCoast_goto_soi_trans(initialState, eventNum, maxUT, soiSkipIds, celBodyData, soITrans);
                end
                
                execCoastEventLog = ma_executeCoast(coastEvent, SoITransEventLog(end,:), eventNum, celBodyData);
                eventLog = [SoITransEventLog; execCoastEventLog];
                return;                
            end
            
            for(r=1:revs) %#ok<*NO4LP>
                eventLog = vertcat(eventLog,ma_executeCoast_goto_dt(period, initialState, eventNum, true, soiSkipIds, celBodyData)); %#ok<AGROW>
                initialState = eventLog(end,:);
            end
            coastINIState = eventLog(end,:);
        else
            coastINIState = initialState;
            warnStr = ['Could not perform ',num2str(revs),' revolutions during coast, orbit is not elliptical.'];
            addToExecutionWarnings(warnStr, eventNum, bodyID, celBodyData);
        end
    else
        coastINIState = initialState;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do the coast according to its sub-type
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    type = coastEvent.coastType;
    value = coastEvent.coastToValue;
    switch type
        case 'goto_ut'
            eventLogCoast = ma_executeCoast_goto_ut(value, coastINIState, eventNum, true, soiSkipIds, celBodyData);
            
        case 'goto_dt'
            eventLogCoast = ma_executeCoast_goto_dt(value, coastINIState, eventNum, true, soiSkipIds, celBodyData);
            
        case 'goto_tru'
            eventLogCoast = ma_executeCoast_goto_tru(value, coastINIState, eventNum, true, soiSkipIds, refBody, celBodyData);
            
        case 'goto_apo'
            eventLogCoast = ma_executeCoast_goto_tru(pi, coastINIState, eventNum, true, soiSkipIds, refBody, celBodyData);
            
        case 'goto_peri'
            eventLogCoast = ma_executeCoast_goto_tru(0, coastINIState, eventNum, true, soiSkipIds, refBody, celBodyData);
            
        case 'goto_asc_node'
            eventLogCoast = ma_executeCoast_goto_node('asc', coastINIState, eventNum, true, soiSkipIds, refBody, celBodyData);
            
        case 'goto_desc_node'
            eventLogCoast = ma_executeCoast_goto_node('desc', coastINIState, eventNum, true, soiSkipIds, refBody, celBodyData);
            
        case 'goto_soi_trans'
            eventLogCoast = ma_executeCoast_goto_soi_trans(coastINIState, eventNum, [], soiSkipIds, celBodyData);
            
        otherwise
            error(['Did not recongize coast of type ', type]);
    end
    
    eventLog = [eventLog; eventLogCoast];
end

