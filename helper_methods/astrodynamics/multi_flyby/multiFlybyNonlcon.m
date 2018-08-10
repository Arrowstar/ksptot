function [c, ceq ] = multiFlybyNonlcon(x, fitnessfcn, minRadii, maxRadii, minXferRad)
%multiFlybyNonlcon Summary of this function goes here
%   Detailed explanation goes here
    ceq = [];

    numPop = size(x,1);
    
    [~, rp, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, ~, xferRp] = fitnessfcn(x);
    if(size(rp,2) < size(minRadii,2))
        c = 0;
        return;
    end
    
    c = (minRadii(1:length(rp)) - rp)';
    c = reshape(c,numPop,size(c,1)/numPop);
    
    c2 = (rp - maxRadii(1:length(rp)))';
    c2 = reshape(c2,numPop,size(c2,1)/numPop);
    
    c3 = -(xferRp - minXferRad)'; %need the minus sign to make greater than values negative for the constraint
    c3 = reshape(c3,numPop,size(c3,1)/numPop);
    
    c = horzcat(c,c2,c3);
    c(isnan(c)) = 1;
end