function [hyperA] = computeHyperAFromTrueAnom(tru, ecc)
%computeHyperAFromTrueAnom Summary of this function goes here
%   Detailed explanation goes here
    num = tan(tru/2);
    denom = (((ecc+1)/(ecc-1))^(1/2));

    hyperA = 2*atanh( num / denom );
%     2*atanh(sqrt((ecc-1)/(ecc+1))*tan(tru/2))
%     hyperA = acosh((ecc+cos(tru)/(1+ecc*cos(tru))));
end

