function [tru] = computeTrueAnomFromHypAnom(HypA, ecc)
%computeTrueAnomFromHypAnom Summary of this function goes here
%   Detailed explanation goes here

    upper = sqrt(ecc+1) .* tanh(HypA/2);
    lower = sqrt(ecc-1);
    tru = atan2(upper, lower) * 2;
end

