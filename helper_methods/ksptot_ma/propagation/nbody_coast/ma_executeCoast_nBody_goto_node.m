function [eventLog] = ma_executeCoast_nBody_goto_node(node, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, refBody, massLoss, maxPropTime, events, celBodyData)
%ma_executeCoast_nBody_goto_node Summary of this function goes here
%   Detailed explanation goes here
	bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    nodeEvent = @(T,Y) ma_NodeEvents(T,Y, node, bodyInfo, refBody, celBodyData);
    events{end+1} = nodeEvent;
    
    dt = maxPropTime;
    eventLog = ma_executeCoast_nBody_goto_dt(dt, initialState, eventNum, forceModel, considerSoITransitions, soiSkipIds, massLoss, maxPropTime, events, true, celBodyData);
end


