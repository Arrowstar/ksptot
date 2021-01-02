function [dv, dvVect, orbitIn, orbitOut] = flybyDVObjCompFunc(vInfIn, vInfOut, gmuXfr)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

[smaIn, eIn, hHat, sHat, smaOut, eOut, oHat] = computeFlyByParameters(vInfIn, vInfOut, gmuXfr);

[hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, hTAIn, rpVectIn] = computeHyperOrbitFromFlybyParams(smaIn, eIn, hHat, sHat, true);
[hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, hTAOut, rpVectOut] = computeHyperOrbitFromFlybyParams(smaOut, eOut, hHat, oHat, false);

[rVectIn,vVectIn]=getStatefromKepler(hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, 0, gmuXfr);
[rVectOut,vVectOut]=getStatefromKepler(hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, 0, gmuXfr);

orbitIn = [hSMAIn, hEccIn, hIncIn, hRAANIn, hArgIn, hTAIn, norm(rpVectIn)];
orbitOut = [hSMAOut, hEccOut, hIncOut, hRAANOut, hArgOut, hTAOut, norm(rpVectOut)];

% disp(norm(rVectIn-rpVectIn));
% disp(norm(rVectIn-rVectOut));
% disp(norm(rpVectOut-rVectOut));

dvVect = (vVectOut-vVectIn);
% dvVect = 10000*(vVectOut-vVectIn);
dv = norm(dvVect);
end

