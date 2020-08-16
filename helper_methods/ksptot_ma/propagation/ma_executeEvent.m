function eventLog = ma_executeEvent(event, initialState, eventNum, maData, celBodyData)
%ma_executeEvent Summary of this function goes here
%   Detailed explanation goes here
    
    type = event.type;
    
    if(isempty(maData))
        otherSCs = {};
    else
        otherSCs = maData.spacecraft.otherSC;
    end
    
    switch type
        case 'Set_State'
            eventLog = ma_executeSetState(event, initialState, eventNum, celBodyData);
            
        case 'Coast'
            eventLog = ma_executeCoast(event, initialState, eventNum, maData, celBodyData);
            
        case 'NBodyCoast'
            eventLog = ma_executeNBodyCoast(event, initialState, eventNum, celBodyData);
            
        case 'DV_Maneuver'
            eventLog = ma_executeDVManeuver(event, initialState, eventNum, celBodyData);
            
        case 'Mass_Dump'
            eventLog = ma_executeMassDump(event, initialState, eventNum);
            
        case 'Staging'
            eventLog = ma_executeStaging(event, initialState, eventNum);
            
        case 'Docking'
            eventLog = ma_executeDocking(event, initialState, eventNum, otherSCs, celBodyData);
        
        case 'Aerobrake'
            eventLog = ma_executeAerobrake(initialState, eventNum, event, celBodyData);
            
        case 'Landing'
            eventLog = ma_executeLanding(event, initialState, eventNum, celBodyData);
            
        otherwise
            error(['Did not recongize event of type ', type]);
    end
    
    if(size(eventLog,1) >= 1)
        eventLog(:,13) = eventNum;
    end
end

