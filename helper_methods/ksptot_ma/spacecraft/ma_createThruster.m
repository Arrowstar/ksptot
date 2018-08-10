function [thruster] = ma_createThruster(name, propType, Isp, thrust)
%ma_createThruster Summary of this function goes here
%   Detailed explanation goes here

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Valid dv maneuver propType strings:
    % fuelOxMass - Depletes prop from fuel/ox reserves 
    % monoMass   - Depletes prop from monoprop reserves
    % xenonMass  - Depletes prop from xenon reserves
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rng('shuffle');
    
    thruster = struct();
    thruster.name     = name;
    thruster.type     = 'Thruster';
    thruster.propType = propType;
    thruster.isp      = Isp;
    thruster.thrust   = thrust;
    thruster.id       = rand(1);
end

