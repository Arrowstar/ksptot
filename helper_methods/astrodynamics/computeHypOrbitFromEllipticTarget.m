function [hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat, fval] = computeHypOrbitFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf)
%computeHypOrbitFromEllipticTarget Summary of this function goes here
%   Detailed explanation goes here

    gmu = eGmu;
    hEng = norm(hVInf)^2/2;
    hSMA = -gmu/(2*hEng);
    [eRVec,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, true);
    r = norm(eRVec);
    
    f = @(hEcc) findEcc(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf, hEcc);
    lb = 1.0 + eps;
    ub = max([1-r/hSMA, r/hSMA-1]);
    
    if(ub == 1)
        lb = 1.0 + eps;
        ub = 1.0 + 2*eps;
    end

    options = optimset('TolX',1E-8);
    [hEcc, fval] = fminbnd(f, lb, ub, options);
    
    [~, hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat] = f(hEcc);
end

function [f, hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat] = findEcc(eSMA, eEcc, eInc, eRAAN, eArg, eTA, eGmu, hVInf, hEcc)
	gmu = eGmu;
    
    [eRVec,~]=getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu);

    rHat = eRVec/norm(eRVec);
    hHat = cross(rHat,hVInf) / norm(cross(rHat,hVInf));
    thHat = cross(hHat,rHat) / norm(cross(hHat,rHat));

    hEng = norm(hVInf)^2/2;
    hSMA = -gmu/(2*hEng);
%     hRp = norm(eRVec);
%     hEcc = 1 - hRp/hSMA;
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
    
    [~, OUnitVector] = computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
    
    f = norm(normVector(hVInf) - OUnitVector);
end
