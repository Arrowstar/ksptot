function [eVect] = computeEccVector(rVect,vVect,gmu)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    hVect = cross(rVect,vVect);
    
    eVect = cross(vVect,hVect)/gmu - rVect/norm(rVect);

end

