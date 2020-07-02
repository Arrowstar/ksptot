function [sUnitVector, OUnitVector, vInfMag] = computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu)
%computeHyperSVectOVect Summary of this function goes here
%   Detailed explanation goes here
    [hRVect,hVVect]=getStatefromKepler(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
    hHat = normVector(cross(hRVect, hVVect));
    
    flyByAngle=2*asin(1/hEcc);
    SigmaAngle=pi/2 - flyByAngle/2;
    hUnitVector=hHat;
    eVector=(norm(hVVect)^2/gmu - 1/norm(hRVect))*hRVect - (dot(hRVect,hVVect)/gmu)*hVVect;
    eUnitVect=eVector/norm(eVector);
    sUnitVector=cos(SigmaAngle)*eUnitVect + sin(SigmaAngle)*cross(hUnitVector,eUnitVect);
    BUnitVector=cross(sUnitVector,hUnitVector)/norm(cross(sUnitVector,hUnitVector));
    OUnitVector=cos(flyByAngle)*sUnitVector - sin(flyByAngle)*BUnitVector;
    
    vInfMag = sqrt(-gmu/hSMA);
end

