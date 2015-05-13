function [sPeriod] = computeSynodicPeriod(n1, n2)
%computeSynodicPeriod Summary of this function goes here
%   Detailed explanation goes here

    sPeriod = abs((2*pi) / (n1 - n2));
    return;
end

