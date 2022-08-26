function [eventLog] = ma_executeCoast_nBody_goto_tru(truTarget, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData)
	bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    taEvent = @(T,Y) ma_TrueAnomalyEvent(T,Y, truTarget, bodyInfo, refBody, celBodyData);
    events{end+1} = taEvent;
    
    dt = maxPropTime;
    eventLog = ma_executeCoast_nBody_goto_dt(dt, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime, events, true, celBodyData);
end

