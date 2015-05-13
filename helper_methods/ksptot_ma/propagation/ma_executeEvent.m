function eventLog = ma_executeEvent(event, initialState, eventNum, celBodyData)
%ma_executeEvent Summary of this function goes here
%   Detailed explanation goes here
    
    type = event.type;
    
    switch type
        case 'Set_State'
            eventLog = ma_executeSetState(event, eventNum);
            
        case 'Coast'
            eventLog = ma_executeCoast(event, initialState, eventNum, celBodyData);
            
        case 'DV_Maneuver'
            eventLog = ma_executeDVManeuver(event, initialState, eventNum, celBodyData);
            
        case 'Mass_Dump'
            eventLog = ma_executeMassDump(event, initialState, eventNum);
        
        case 'Aerobrake'
            eventLog = ma_executeAerobrake(initialState, eventNum, event, celBodyData);
            
        otherwise
            error(['Did not recongize event of type ', type]);
    end
end

