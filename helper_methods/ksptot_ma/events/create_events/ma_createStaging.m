function staging = ma_createStaging(name, stagingValue)
%ma_createStaging Summary of this function goes here
%   Detailed explanation goes here
    %DryMass, FuelOxMass, MonoMass, XenonMass
    
    staging = struct();
    staging.name           = name;
    staging.type           = 'Staging';
    staging.stagingValue   = stagingValue; %a 4x1 of masses to set masses to
    staging.id             = rand(1);
end