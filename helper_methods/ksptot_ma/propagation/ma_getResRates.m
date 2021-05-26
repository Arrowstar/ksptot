function [resRates] = ma_getResRates(massLoss)
%getResRates Summary of this function goes here
%   Detailed explanation goes here
    maxNumRes = max(horzcat(massLoss.lossConvert.resLost, massLoss.lossConvert.resConvert));
    resRates = zeros(1,maxNumRes);

    for(i=1:length(massLoss.lossConvert)) %#ok<*NO4LP>
        lossConvert = massLoss.lossConvert(i);
        resRates(lossConvert.resLost) = resRates(lossConvert.resLost) - lossConvert.resLostRates(lossConvert.resLost);

        sumRates = sum(lossConvert.resLostRates);
        resRates(lossConvert.resConvert) = resRates(lossConvert.resConvert) + sumRates*lossConvert.resConvertPercent(lossConvert.resConvert);
    end
end

