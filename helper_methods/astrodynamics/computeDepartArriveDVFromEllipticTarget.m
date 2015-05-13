function [dV, dVVect, dVVectNTW, eRVect, hOrbit, hHat, ECI2TWNRotMat] = computeDepartArriveDVFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf)
%computeDepartArriveDVFromEllipticTarget Summary of this function goes here
%   Detailed explanation goes here   

    [hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat] = computeHypOrbitFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf);

    hOrbit = [hSMA, hEcc, hInc, hRAAN, hArg, hTA];
    
    [eRVect,eVvect]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu);
    [~,hVvect]=getStatefromKepler(hSMA, hEcc, hInc, hRAAN, hArg, hTA, eGmu);

    dVVect = hVvect-eVvect;
    dV = norm(dVVect);
%     disp(['Delta-V = ', num2str(dV), ' km/s']);

    tHat = eVvect/norm(eVvect);
    wHat = cross(eRVect,eVvect)/norm(cross(eRVect,eVvect));
    nHat = cross(tHat,wHat)/norm(cross(tHat,wHat));
    ECI2TWNRotMat = [tHat,wHat,nHat];
    dVVectNTW = ECI2TWNRotMat \ dVVect;

end

