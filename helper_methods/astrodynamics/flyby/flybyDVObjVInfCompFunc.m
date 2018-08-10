function [vInfIn, vInfOut, xferOrbitIn, xferOrbitOut] = flybyDVObjVInfCompFunc(departTime, flybyTime, arrivalTime, rVect1, rVect2, rVect3, vVect2, gmuXfr, shortLongWayVect)
%flybyDVObjVInfCompFunc Summary of this function goes here
%   Detailed explanation goes here

xfer1Way = shortLongWayVect(1);
xfer2Way = shortLongWayVect(2);

timeOfFlight = (flybyTime-departTime)/(86400);
[departVelocity,arrivalVelocity]=lambert(rVect1', rVect2', xfer1Way*timeOfFlight, 0, gmuXfr);
vInfIn = arrivalVelocity' - vVect2;
[~, ~, ~, ~, ~, taDepart] = getKeplerFromState(rVect1,departVelocity,gmuXfr);
[smaIn, eccIn, incIn, raanIn, argIn, taArrive] = getKeplerFromState(rVect2,arrivalVelocity,gmuXfr);
xferOrbitIn = [smaIn, eccIn, incIn, raanIn, argIn, taDepart, taArrive];

timeOfFlight = (arrivalTime-flybyTime)/(86400);
[departVelocity,arrivalVelocity]=lambert(rVect2', rVect3', xfer2Way*timeOfFlight, 0, gmuXfr);
vInfOut = departVelocity'-vVect2;
[~, ~, ~, ~, ~, taDepart] = getKeplerFromState(rVect2,departVelocity,gmuXfr);
[smaOut, eccOut, incOut, raanOut, argOut, taArrive] = getKeplerFromState(rVect3,arrivalVelocity,gmuXfr);
xferOrbitOut = [smaOut, eccOut, incOut, raanOut, argOut, taDepart, taArrive];

end

