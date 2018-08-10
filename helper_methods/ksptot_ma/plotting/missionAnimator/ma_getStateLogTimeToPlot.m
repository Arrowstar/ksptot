function [stateLogTime] = ma_getStateLogTimeToPlot(prevStateLogTime, frameRate, timeWarpMultiplier)
%ma_getStateLogTimeToPlot Summary of this function goes here
%   Detailed explanation goes here    
    timeBetweenFrames = 1/frameRate;
    stateTimeBetweenFrames = timeBetweenFrames*timeWarpMultiplier;
    stateLogTime = prevStateLogTime + stateTimeBetweenFrames;
end

