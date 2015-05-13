function [lb, ub] = getMultiFlybyLBUB(lOpenUT, lDuration, bodiesInfo, celBodyData)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    nvars = length(bodiesInfo)+(length(bodiesInfo)-1);
    IntCon = 1:nvars;
    IntCon = IntCon(end-(length(bodiesInfo)-1)+1:end);
    lb = zeros(1,nvars);
    ub = zeros(1,nvars);
    
    pBodyInfo = getParentBodyInfo(bodiesInfo{1}, celBodyData);
    xferGmu = pBodyInfo.gm;

    lb(1) = lOpenUT;
    ub(1) = lOpenUT + lDuration;
    
    for(i=1:length(bodiesInfo)-1)
        b1 = bodiesInfo{i};
        b2 = bodiesInfo{i+1};
        
        mSMA = mean([b1.sma, b2.sma]);
        xP = computePeriod(mSMA, xferGmu);
        
        lb(i+1) = xP/25;
        ub(i+1) = xP*5;
    end
    
    lb(IntCon) = 1;
    ub(IntCon) = 2;
end

