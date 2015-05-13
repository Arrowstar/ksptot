function maneuver = ma_update_dv_maneuver(maneuver, burnSPH)
%ma_update_dv_maneuver Summary of this function goes here
%   Detailed explanation goes here

    if(length(burnSPH) ~= 3) %we need a 1x3
        error('burnSPH is wrong size: must be length 3');
    end

%     az = burnSPH(1);
%     el = burnSPH(2);
%     mag  = burnSPH(3);
%     [x,y,z] = sph2cart(az,el,mag);
%     maneuverValue = [x,y,z];
    maneuverValue = burnSPH;

    if(strcmpi(maneuver.type,'DV_Maneuver'))
        maneuver.maneuverValue = maneuverValue;
    else
        error(['Could not update DV maneuver, it was of the wrong type: ', maneuver.type]);
    end
end

