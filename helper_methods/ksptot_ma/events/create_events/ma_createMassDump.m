function massDump = ma_createMassDump(name, subType, massDumpValue, thruster)
%ma_createMassDump Summary of this function goes here
%   Detailed explanation goes here
    %dDryMass, dFuelOxMass, dMonoMass, dXenonMass
    
    massDump = struct();
    massDump.name        = name;
    massDump.type        = 'Mass_Dump';
    massDump.subType     = subType;   %'basic' or 'delta-v'
    massDump.dumpValue   = massDumpValue; %either a 4x1 of masses to dump or a scalar with delta-v 
    massDump.thruster    = thruster; %for DV dumps only, empty if not
    massDump.id          = rand(1);
end

