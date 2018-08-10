function eventLog = ma_executeDVManeuver(maneuverEvent, initialState, eventNum, celBodyData)
%ma_executeDVManeuver Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do the maneuver according to its sub-type
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    type = maneuverEvent.maneuverType;
    value = maneuverEvent.maneuverValue;
    thruster = maneuverEvent.thruster;
    switch type
        case 'dv_inertial'
            eventLog = ma_executeDVManeuver_dv_inertial(value, thruster, initialState, eventNum);
        case 'dv_orbit'
            eventLog = ma_executeDVManeuver_dv_orbit(value, thruster, initialState, eventNum);
        case 'finite_inertial'
            eventLog = ma_executeDVManeuver_finite_inertial(value, thruster, initialState, eventNum, celBodyData);
        case 'finite_steered'
            eventLog = ma_executeDVManeuver_finite_steered(value, thruster, initialState, eventNum, celBodyData);
        case 'dv_inertial_spherical'
            eventLog = ma_executeDVManeuver_dv_inertial_spherical(value, thruster, initialState, eventNum);
        case 'dv_orbit_spherical'
            eventLog = ma_executeDVManeuver_dv_orbit_spherical(value, thruster, initialState, eventNum);
        case 'finite_inertial_spherical'
            eventLog = ma_executeDVManeuver_finite_inertial_spherical(value, thruster, initialState, eventNum, celBodyData);
        case 'finite_steered_spherical'
            eventLog = ma_executeDVManeuver_finite_steered_spherical(value, thruster, initialState, eventNum, celBodyData);
        case 'circularize'
            eventLog = ma_executeDVManeuver_circularize(thruster, initialState, eventNum, celBodyData);
        otherwise
            error(['Did not recongize maneuver of type ', type]);
    end
end

