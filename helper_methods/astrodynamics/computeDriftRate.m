function [driftRate] = computeDriftRate(sma, bodyInfo)
%computeDriftRate Summary of this function goes here
%   Detailed explanation goes here  
    gmu = bodyInfo.gm;
    meanMotion = computeMeanMotion(sma, gmu);
    
    syncSMA = computeSMAFromPeriod(bodyInfo.rotperiod, bodyInfo.gm);
    meanMotionSync = computeMeanMotion(syncSMA, gmu);
    
    driftRate = (meanMotion-meanMotionSync); %might be off by a factor of 2*pi 
    
%     driftRate = (2*pi/bodyInfo.rotperiod) * ((computePeriod(sma, gmu) - computePeriod(syncSMA, gmu))/computePeriod(sma, gmu));
end

