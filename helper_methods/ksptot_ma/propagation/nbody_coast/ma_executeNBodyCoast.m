function eventLog = ma_executeNBodyCoast(coastEvent, initialState, eventNum, celBodyData)
%ma_executeNBodyCoast Summary of this function goes here
%   Detailed explanation goes here

	soiSkipIds = coastEvent.soiSkipIds;
    refBody = coastEvent.refBody;
    massLoss = coastEvent.massloss;
    forceModel = coastEvent.forceModel;
	maxPropTime = coastEvent.maxPropTime;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get global coast ODE solver event functions
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    events = ma_getGlobalEvents(initialState, celBodyData);
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Propagate through the n revs, if applicable
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    eventLog = [];
    revs = coastEvent.revs;
    if(revs > 0)
        rVect = initialState(2:4);
        vVect = initialState(5:7);
        
        bodyID = initialState(8);
        bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
        
        [sma, ecc, ~, ~, ~, tru] = getKeplerFromState(rVect, vVect, bodyInfo.gm);
        
        if(ecc < 1)
            revsInitstate = initialState;
            for(i=1:revs) %#ok<*NO4LP>
                period = computePeriod(sma, bodyInfo.gm);
                eventLogCoastRev1 = ma_executeCoast_nBody_goto_dt(period/2, revsInitstate, eventNum, forceModel, true, soiSkipIds, massLoss, maxPropTime, events, true, celBodyData);
                eventLogCoastRev2 = ma_executeCoast_nBody_goto_tru(tru, eventLogCoastRev1(end,:), eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
                
                eventLog = [eventLog;eventLogCoastRev1; eventLogCoastRev2]; %#ok<AGROW>
                revsInitstate = eventLogCoastRev2(end,:);
            end
            
            coastINIState = eventLogCoastRev2(end,:);
        else
            coastINIState = initialState;
            warnStr = ['Could not perform ',num2str(revs),' revolutions during coast, initial orbit is not elliptical.'];
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
            eventLogCoast = ma_executeCoast_nBody_goto_ut(value, coastINIState, eventNum, forceModel, true, soiSkipIds, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_dt'
            eventLogCoast = ma_executeCoast_nBody_goto_dt(value, coastINIState, eventNum, forceModel, true, soiSkipIds, massLoss, maxPropTime, events, true, celBodyData);
            
        case 'goto_tru'
            eventLogCoast = ma_executeCoast_nBody_goto_tru(value, coastINIState, eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_apo'
            eventLogCoast = ma_executeCoast_nBody_goto_tru(pi, coastINIState, eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_peri'
            eventLogCoast = ma_executeCoast_nBody_goto_tru(0, coastINIState, eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_asc_node'
            eventLogCoast = ma_executeCoast_nBody_goto_node('asc', coastINIState, eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_desc_node'
            eventLogCoast = ma_executeCoast_nBody_goto_node('desc', coastINIState, eventNum, forceModel, true, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData);
            
        case 'goto_soi_trans'
            eventLogCoast = ma_executeCoast_nBody_goto_soi_trans(coastINIState, eventNum, forceModel, soiSkipIds, massLoss, maxPropTime, events, celBodyData);
            
        otherwise
            error(['Did not recongize coast of type ', type]);
    end
    
    eventLog = [eventLog; eventLogCoast];
end

