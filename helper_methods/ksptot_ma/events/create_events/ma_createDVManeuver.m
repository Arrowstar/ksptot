function maneuver = ma_createDVManeuver(name, maneuverType, maneuverValue, thruster, vars, lineColor, lineStyle, lineWidth)
%ma_createDVManeuver Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Valid dv maneuver type strings:
    % dv_inertial - Provide a 3x1 delta-v vector (km/s) in the inertial
    %              frame (x, y, z)
    % dv_orbit    - Provide a 3x1 delta-v vector (km/s) in the orbit frame
    %              (prograde, normal, radial)
    % circularize - Circularizes the orbit at the position vector of the
    %               input state
    % finite_steered - 
    % finite_inertial -
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % vars = [bool bool bool; lower lower lower; upper upper upper]
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    maneuver = struct();
    maneuver.name          = name;
    maneuver.type          = 'DV_Maneuver';
    maneuver.maneuverType  = maneuverType;
    maneuver.maneuverValue = maneuverValue;
    maneuver.thruster      = thruster;
    maneuver.id            = rand(1);
    maneuver.vars          = vars;
    maneuver.lineColor     = lineColor;
    maneuver.lineStyle     = lineStyle;
    maneuver.lineWidth     = lineWidth;
end

