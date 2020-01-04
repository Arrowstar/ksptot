function [dVVectNTW] = getECI2NTWdvVect(dVVectECI, rVect, vVect)
%getNTWdvVect Summary of this function goes here
%   Detailed explanation goes here
    rVect = reshape(rVect, 3,1);
    vVect = reshape(vVect, 3,1);
    dVVectECI = reshape(dVVectECI, 3,1);
    
    tHat = vVect/norm(vVect);
    
    wHatC = crossARH(rVect,vVect);
    wHat = wHatC/norm(wHatC);
    
    nHatC = crossARH(tHat,wHat);
    nHat = nHatC/norm(nHatC);   
    
    ECI2TWNRotMat = [tHat,wHat,nHat];
    
    dVVectNTW = ECI2TWNRotMat \ dVVectECI;
end