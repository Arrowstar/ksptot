function maneuver = ma_update_dv_maneuver(maneuver, burnSPH)
%ma_update_dv_maneuver Summary of this function goes here
%   Detailed explanation goes here

    maneuverValue = burnSPH;
    
    activeVars = maneuver.vars(1,:) == 1;
    if(strcmpi(maneuver.type,'DV_Maneuver'))
        maneuver.maneuverValue(activeVars) = maneuverValue;
    else
        error(['Could not update DV maneuver, it was of the wrong type: ', maneuver.type]);
    end
end

