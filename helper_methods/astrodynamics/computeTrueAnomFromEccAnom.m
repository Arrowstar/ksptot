function [tru] = computeTrueAnomFromEccAnom(EccA, ecc)
%computeTrueAnomFromEccAnom Summary of this function goes here
%   Detailed explanation goes here
    
    upper = sqrt(1+ecc) .* tan(EccA/2);
    lower = sqrt(1-ecc);
    tru = AngleZero2Pi(atan2(upper, lower) * 2);
end

