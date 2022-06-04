function [radius, velocity, fpa] = computeRVFpaFromSmaEccTru(sma, ecc, tru, gmu)
    %computeRVFpaFromSmaEccTru Summary of this function goes here
    %   Detailed explanation goes here
    [rVect, vVect]=getStatefromKepler(sma, ecc, 0, 0, 0, tru, gmu);
    
    radius = norm(rVect);
    velocity = norm(vVect);
    fpa = real(asin(dotARH(rVect,vVect)/(radius*velocity)));
end

