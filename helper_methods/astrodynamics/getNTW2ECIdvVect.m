function [dVVectECI] = getNTW2ECIdvVect(dVVectNTW, rVect, vVect)
%getNTWdvVect Summary of this function goes here
%   Detailed explanation goes here
    rVect = reshape(rVect, 3,1);
    vVect = reshape(vVect, 3,1);
    dVVectNTW = reshape(dVVectNTW, 3,1);
    
    tHat = vVect/norm(vVect);
    
    wHatC = crossARH(rVect,vVect);
    wHat = wHatC/norm(wHatC);
    
    nHatC = crossARH(tHat,wHat);
    nHat = nHatC/norm(nHatC);   
    
    ECI2TWNRotMat = [tHat,wHat,nHat];
%     TWN2ECIRotMat = inv(ECI2TWNRotMat);
    TWN2ECIRotMat = ECI2TWNRotMat'; %rotation matrix, inv = transpose
    
    dVVectECI = TWN2ECIRotMat \ dVVectNTW;
end