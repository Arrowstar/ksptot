function [hyperA] = computeHyperAFromTrueAnom(tru, ecc)
%computeHyperAFromTrueAnom Summary of this function goes here
%   Detailed explanation goes here
    num = tan(tru/2);
    denom = ((ecc+1)/(ecc-1))^(1/2);
    
    hyperA = 2*atanh(num/denom);
end

