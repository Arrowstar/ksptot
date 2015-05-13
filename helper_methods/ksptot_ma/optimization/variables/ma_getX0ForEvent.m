function [x0] = ma_getX0ForEvent(event)
%ma_getX0ForEvent Summary of this function goes here
%   Detailed explanation goes here

    x0 = 0;
    switch event.type
        case 'Coast'
            x0 = event.coastToValue;
        case 'DV_Maneuver'
            dvOrig = event.maneuverValue;
            x0 = dvOrig;
    end
end

