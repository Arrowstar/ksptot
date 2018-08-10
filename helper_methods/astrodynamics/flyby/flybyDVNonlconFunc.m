function [c, ceq] = flybyDVNonlconFunc(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr, disableRpConst)
%flybyDVNonlconFunc Summary of this function goes here
%   Detailed explanation goes here

[~, ~, Rp, xferOrbitIn, xferOrbitOut] = flybyDVObjFunc(x, departBodyInfo, flybyBodyInfo, arrivalBodyInfo, gmuXfr);

c = [];
if(disableRpConst==0)
    c(end+1) = (flybyBodyInfo.radius+flybyBodyInfo.atmohgt+0.1) - Rp;
    c(end+1) = Rp - 0.9*flybyBodyInfo.sma*(flybyBodyInfo.gm/gmuXfr)^(2/5);
end
c(end+1) = xferOrbitIn(3) - pi/2;
c(end+1) = xferOrbitOut(3) - pi/2;

ceq = [];
end

