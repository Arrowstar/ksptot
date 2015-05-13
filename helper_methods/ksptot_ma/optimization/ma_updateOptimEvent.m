function event = ma_updateOptimEvent(xSubset, event)
    type = event.type;
    switch type
        case 'Coast'
            event = ma_update_coast(event, xSubset);
        case 'DV_Maneuver'
            event = ma_update_dv_maneuver(event, xSubset);
        otherwise
            error(['Event type invalid for optimization: ', event.type]);
    end
end