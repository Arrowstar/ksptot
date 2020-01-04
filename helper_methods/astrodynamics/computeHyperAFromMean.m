function [ HypA ] = computeHyperAFromMean(mean, ecc)
%computeHyperAFromMean Summary of this function goes here
%   Detailed explanation goes here

%     M=@(H) ecc*sinh(H) - H - mean;
%     HypA=fzero(M,mean);
    HypA = solveKepler(mean, ecc);
end

