function [hSMA, hEcc, hInc, hRAAN, hArg, hTA, rpVect] = computeHyperOrbitFromFlybyParams(hSMA, hEcc, hHat, SOHat, sHatBool)
%computeHyperOrbitFromFlybyParams Summary of this function goes here
%   Detailed explanation goes here

delta = 2*asin(1/hEcc);
if(sHatBool==1)
    sHat = SOHat;
    deltaHat = rodrigues_rot(sHat, hHat, delta/2);
else
    oHat = SOHat;
    deltaHat = rodrigues_rot(oHat, hHat, -delta/2);
end

eccHat = cross(deltaHat,hHat)/norm(cross(deltaHat,hHat));
rp = hSMA*(1-hEcc);
rpVect = rp*eccHat;

hInc = acos(hHat(3));
zHat = [0,0,1];
nHat = cross(zHat,hHat)/norm(cross(zHat,hHat));
if(any(isnan(nHat)))
    hRAAN=0;
else
    hRAAN = atan2(nHat(2),nHat(1));
end
hP = hSMA*(1-hEcc^2);
hTA = AngleZero2Pi(real(acos((hP/norm(rpVect) - 1)/hEcc)));

thHat = cross(hHat,eccHat) / norm(cross(hHat,eccHat));
hTheta = atan2(eccHat(3),thHat(3));
hArg = AngleZero2Pi(hTheta-hTA);

end

