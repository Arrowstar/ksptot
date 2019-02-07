function [dmasses] = computeDMFromDV(masses, dv, Isp, propType)
%computeDMFromDV Summary of this function goes here
%   Detailed explanation goes here
    
    m0 = sum(masses);
    m1 = revRocketEqn(m0, Isp, dv);
    dm = m0 - m1;
    
    dmasses = masses;
    switch propType
        case 'fuelOxMass'
            dmasses(2) = dmasses(2) - dm;
        case 'monoMass'
            dmasses(3) = dmasses(3) - dm;
        case 'xenonMass'
            dmasses(4) = dmasses(4) - dm;
        case 'none'
            %no action
        otherwise
            error(['Unknown propellant type: ', propType]);
    end
end