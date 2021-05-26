function [c, ceq ] = multiFlybyNonlcon(x, fitnessfcn, minRadiiSingle, maxRadiiSingle, minXferRad, maxDepartVInf, maxArriveVInf)
%multiFlybyNonlcon Summary of this function goes here
%   Detailed explanation goes here
    ceq = [];

    numPop = size(x,1);
    
    minRadii = [];
    maxRadii = [];
%     minRadii = NaN(1, numPop*numel(minRadiiSingle));
%     maxRadii = NaN(1, numPop*numel(maxRadiiSingle));
    for(i=1:length(minRadiiSingle))
        minRadii = [minRadii, minRadiiSingle(i) * ones(1, numPop)]; %#ok<AGROW>
        maxRadii = [maxRadii, maxRadiiSingle(i) * ones(1, numPop)]; %#ok<AGROW>
    end
    
    [~, rp, ~, ~, ~, vInfDNorm, ~, vInfArrive, ~, ~, ~, ~, ~, xferRp] = fitnessfcn(x);
%     if(size(rp,2) < size(minRadii,2))
%         c = 0;
%         return;
%     end
    
    c = (minRadii(1:length(rp)) - rp)';
    c = reshape(c,numPop,size(c,1)/numPop);
    
    c2 = (rp - maxRadii(1:length(rp)))';
    c2 = reshape(c2,numPop,size(c2,1)/numPop);
    
    c3 = -(xferRp - minXferRad)'; %need the minus sign to make greater than values negative for the constraint
    c3 = reshape(c3,numPop,size(c3,1)/numPop);
    
%     c = horzcat(c,c2,c3);
    
    c4 = vInfDNorm - maxDepartVInf;
    c5 = (sqrt(sum(abs(vInfArrive).^2,1)))' - maxArriveVInf;
    c = horzcat(c,c2,c3,c4,c5);
    
    c(isnan(c)) = 1;
    c(c == -Inf) = -realmax;
    c(c == Inf) = realmax;
end