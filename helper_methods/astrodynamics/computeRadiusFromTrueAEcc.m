function radius = computeRadiusFromTrueAEcc(tru, sma, ecc)
%computeRadiusFromTrueAEcc Summary of this function goes here
%   Detailed explanation goes here
    p = sma*(1-ecc^2);
    radius = p/(1+ecc*cos(tru));        
end

