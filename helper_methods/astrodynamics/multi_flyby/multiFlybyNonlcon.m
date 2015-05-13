function [c, ceq ] = multiFlybyNonlcon(x, fitnessfcn, minRadii, maxRadii)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    ceq = [];

    numPop = size(x,1);
    
    [~, rp, ~, ~] = fitnessfcn(x);
    if(size(rp,2) < size(minRadii,2))
        c = 0;
        return;
    end
    
    c = (minRadii(1:length(rp)) - rp)';
    c = reshape(c,numPop,size(c,1)/numPop);
    
    c2 = (rp - maxRadii(1:length(rp)))';
    c2 = reshape(c2,numPop,size(c2,1)/numPop);
    
    c = horzcat(c,c2);
    c(isnan(c)) = 1;
end