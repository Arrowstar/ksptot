function [dVVectNTW] = getNTWdvVect(dVVect, rVect, vVect)
%getNTWdvVect Summary of this function goes here
%   Detailed explanation goes here
    vVect = reshape(vVect, 3,1);
    dVVect = reshape(dVVect, 3,1);
    
    tHat = vVect/norm(vVect);
    wHat = cross(rVect,vVect)/norm(cross(rVect,vVect));
    nHat = cross(tHat,wHat)/norm(cross(tHat,wHat));
    ECI2TWNRotMat = [tHat,wHat,nHat];
    dVVectNTW = ECI2TWNRotMat \ dVVect;
end

