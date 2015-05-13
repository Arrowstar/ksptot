function [dVVectECI] = getNTW2ECIdvVect(dVVectNTW, rVect, vVect)
%getNTWdvVect Summary of this function goes here
%   Detailed explanation goes here
    rVect = reshape(rVect, 3,1);
    vVect = reshape(vVect, 3,1);
    dVVectNTW = reshape(dVVectNTW, 3,1);
    
    tHat = vVect/norm(vVect);
    wHat = cross(rVect,vVect)/norm(cross(rVect,vVect));
    nHat = cross(tHat,wHat)/norm(cross(tHat,wHat));   
    ECI2TWNRotMat = [tHat,wHat,nHat];
    TWN2ECIRotMat = inv(ECI2TWNRotMat);
    
    dVVectECI = TWN2ECIRotMat \ dVVectNTW;
end