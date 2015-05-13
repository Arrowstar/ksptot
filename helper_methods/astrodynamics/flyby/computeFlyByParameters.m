function [smaIn, eIn, hHat, sHat, smaOut, eOut, oHat] = computeFlyByParameters(vInfIn, vInfOut, gmu)
%computeFlyByParameters Summary of this function goes here
%   Detailed explanation goes here

sHat = vInfIn/norm(vInfIn);
energyIn = norm(vInfIn)^2/2;
smaIn = -gmu/(2*energyIn);

oHat = vInfOut/norm(vInfOut);
energyOut = norm(vInfOut)^2/2;
smaOut = -gmu/(2*energyOut);

hHat = cross(sHat, oHat) / norm(cross(sHat, oHat));
delta = acos(dot(sHat,oHat));

optim = optimset('TolX', eps);

e1Eqn = @(e2) 1+(smaOut/smaIn)*(e2-1);
f = @(e2) abs(delta - asin(1/e1Eqn(e2)) - asin(1/e2));
eOut = fminbnd(f,1,50, optim);
eIn = e1Eqn(eOut);

end

