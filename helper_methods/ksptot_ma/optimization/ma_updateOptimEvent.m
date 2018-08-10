function event = ma_updateOptimEvent(xSubset, event)
    type = event.type;
    switch type
        case 'Coast'
            event = ma_update_coast(event, xSubset);
        case 'NBodyCoast'
            event = ma_update_coast(event, xSubset);
        case 'DV_Maneuver'
            event = ma_update_dv_maneuver(event, xSubset);
        case 'Set_State'
            if(strcmpi(event.subType,'estLaunch'))
                event = ma_update_launch(event, xSubset);
            else
                event = ma_update_setState(event, xSubset);
            end
        otherwise
            error(['Event type invalid for optimization: ', event.type]);
    end
end