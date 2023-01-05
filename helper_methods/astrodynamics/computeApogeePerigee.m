function [rAp, rPe] = computeApogeePerigee(sma, ecc)
%computeApogeePerigee Summary of this function goes here
%   Detailed explanation goes here
    rAp = sma .* (1 + ecc);
    rPe = sma .* (1 - ecc);
end

