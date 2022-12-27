function [sUnitVector, OUnitVector, vInfMag] = vect_computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu)
%computeHyperSVectOVect Summary of this function goes here
%   Detailed explanation goes here
    [hRVect,hVVect] = vect_getStatefromKepler(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
    
    hVect = cross(hRVect,hVVect);
    hNorm = sqrt(sum(hVect.^2,1));
    hHat = bsxfun(@rdivide, hVect, hNorm);
    
    flyByAngle=2*asin(1./hEcc);
    SigmaAngle=pi/2 - flyByAngle/2;

    hUnitVector=hHat;

    normHRVect = sqrt(sum(hRVect.^2,1));
    normHVVect = sqrt(sum(hVVect.^2,1));

    eVector=(normHVVect.^2./gmu - 1./normHRVect).*hRVect - (dot(hRVect,hVVect)./gmu).*hVVect;
    eNorm = sqrt(sum(eVector.^2,1));
    eUnitVect = bsxfun(@rdivide, eVector, eNorm);

    sUnitVector=cos(SigmaAngle).*eUnitVect + sin(SigmaAngle).*cross(hUnitVector,eUnitVect);
    BUnitVector=cross(sUnitVector,hUnitVector);
    OUnitVector=cos(flyByAngle).*sUnitVector - sin(flyByAngle).*BUnitVector;
    
    sUnitVector = real(sUnitVector);
    OUnitVector = real(OUnitVector);
    
    vInfMag = sqrt(-gmu./hSMA);
end