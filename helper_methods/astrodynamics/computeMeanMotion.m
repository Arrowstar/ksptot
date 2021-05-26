function [meanMotion] = computeMeanMotion(sma, gmu)
%computeMeanMotion Summary of this function goes here
%   Detailed explanation goes here
    meanMotion = sqrt(gmu./abs(sma).^3);
end

