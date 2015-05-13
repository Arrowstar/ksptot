function [hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat] = computeHypOrbitFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf)
%computeHypOrbitFromEllipticTarget Summary of this function goes here
%   Detailed explanation goes here
    gmu = eGmu;
    
    [eRVec,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu);

    rHat = eRVec/norm(eRVec);
    hHat = cross(rHat,hVInf) / norm(cross(rHat,hVInf));
    thHat = cross(hHat,rHat) / norm(cross(hHat,rHat));

    hEng = norm(hVInf)^2/2;
    hSMA = -gmu/(2*hEng);
    hRp = norm(eRVec);
    hEcc = 1 - hRp/hSMA;
    hInc = acos(hHat(3));
   
    zHat = [0,0,1];
    nHat = cross(zHat,hHat)/norm(cross(zHat,hHat));
    if(any(isnan(nHat)))
        hRAAN=eTA;
    else
        hRAAN = atan2(nHat(2),nHat(1));
    end
    
    hP = hSMA*(1-hEcc^2);
    hTA = AngleZero2Pi(real(acos((hP/norm(eRVec) - 1)/hEcc)));

    hTheta = atan2(rHat(3),thHat(3));
    hArg = AngleZero2Pi(hTheta-hTA);
end

