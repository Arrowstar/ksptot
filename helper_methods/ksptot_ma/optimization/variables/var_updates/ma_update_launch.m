function event = ma_update_launch(event, launchValue)
%ma_update_launch Summary of this function goes here
%   Detailed explanation goes here
    activeVars = event.vars(1,:) == 1;
    
    if(strcmpi(event.type,'Set_State') && strcmpi(event.subType, 'estLaunch'))
        event.launch.launchValue(activeVars) = launchValue;
    else
        error(['Could not update launch event, it was of the wrong type: ', maneuver.type]);
    end
end

