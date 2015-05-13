function [h] = plotLineOfNodes(hAxis, departBodyOrbit, arriveBodyOrbit, xferOrbit, gmuXfr)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    dSMA = departBodyOrbit(1);
    dECC = departBodyOrbit(2);
    aSMA = arriveBodyOrbit(1);
    aECC = arriveBodyOrbit(2);
    smaX = xferOrbit(1);
    eccX = xferOrbit(2);
    
    aHVect = computeHVect(arriveBodyOrbit(1), arriveBodyOrbit(2), arriveBodyOrbit(3), arriveBodyOrbit(4), arriveBodyOrbit(5), gmuXfr);
    hVectX = computeHVect(xferOrbit(1), xferOrbit(2), xferOrbit(3), xferOrbit(4), xferOrbit(5), gmuXfr);
    nVectHat = (cross(aHVect, hVectX)/norm(cross(aHVect, hVectX)));
    
    dRa = dSMA*(1+dECC);
    aRa = aSMA*(1+aECC);
    RAANVectLength = abs(smaX*(1+eccX));
    RAANVectLength = min(RAANVectLength, max(dRa,aRa));
    
    nVect = abs(RAANVectLength)*nVectHat;
    h = plot3(hAxis, [-nVect(1) nVect(1)], [-nVect(2) nVect(2)], [-nVect(3) nVect(3)], '--w', 'LineWidth', 1);
end

