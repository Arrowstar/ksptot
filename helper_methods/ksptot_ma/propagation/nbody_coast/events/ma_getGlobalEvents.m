function [events] = ma_getGlobalEvents(initialState, celBodyData)
%ma_getGlobalEvents Summary of this function goes here
%   Detailed explanation goes here
	bodyID = initialState(8);
    bodyInfo = getBodyInfoByNumber(bodyID, celBodyData);
    
    events = {};
    events{end + 1} = @(T,Y) ma_SoITransitionEvents(T,Y, bodyInfo, celBodyData);
end

