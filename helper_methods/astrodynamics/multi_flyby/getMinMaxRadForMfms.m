function [minRadii,minRadiiSingle,maxRadii,maxRadiiSingle] = getMinMaxRadForMfms(popSize,flybyBodies,celBodyData)
%getMinMaxRad Summary of this function goes here
%   Detailed explanation goes here

    nFlybyBodies = size(flybyBodies,2);
    minRadii = zeros(1, nFlybyBodies*popSize);
    maxRadii = zeros(1, nFlybyBodies*popSize);
    minRadiiSingle = [];
    maxRadiiSingle = [];
    for(i=1:nFlybyBodies) %#ok<*NO4LP>
        inds = (i-1)*popSize+1:i*popSize;
        atmoRad = (flybyBodies{i}.radius + flybyBodies{i}.atmohgt);
        minRadii(inds) = atmoRad*ones(size(inds));
        minRadiiSingle(i) = atmoRad; %#ok<AGROW>

        pBodyInfo = getParentBodyInfo(flybyBodies{i}, celBodyData);
        rSOI = getSOIRadius(flybyBodies{i}, pBodyInfo);
        maxRadii(inds) = rSOI*ones(size(inds));
        maxRadiiSingle(i) = rSOI; %#ok<AGROW>
    end
end

