function [hVect] = computeHVect(sma, ecc, inc, raan, arg, gmu)
%computeHVect Summary of this function goes here
%   Detailed explanation goes here
    [rVect,vVect] = getStatefromKepler(sma, ecc, inc, raan, arg, 0, gmu);
    hVect = cross(rVect, vVect);
end

