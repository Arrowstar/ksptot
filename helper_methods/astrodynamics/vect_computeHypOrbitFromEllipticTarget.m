function [hSMA, hEcc, hInc, hRAAN, hArg, hTA, hHat, fval] = vect_computeHypOrbitFromEllipticTarget(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, hVInf)
%computeHypOrbitFromEllipticTarget Summary of this function goes here
%   Detailed explanation goes here
    
    normHVInf = sqrt(sum(hVInf.^2,1));
    hEng = normHVInf.^2./2;
    hSMA = -gmu./(2*hEng);
    [eRVec,~] = vect_getStatefromKepler(eSMA, eEcc, eInc, eRAAN, eArg, eTA, gmu, true);
    r = sqrt(sum(eRVec.^2,1));
           
    rHat = bsxfun(@rdivide, eRVec, r);

    hVect = cross(rHat,hVInf);
    hNorm = sqrt(sum(hVect.^2,1));
    hHat = bsxfun(@rdivide, hVect, hNorm);

    thVect = cross(hHat,rHat);
    thNorm = sqrt(sum(thVect.^2,1));
    thHat = bsxfun(@rdivide, thVect, thNorm);

    hInc = acos(hHat(3,:));
   
    zHat = zeros(size(hHat));
    zHat(3,:) = 1;

    nVect = cross(zHat,hHat);
    nNorm = sqrt(sum(nVect.^2,1));
    nHat = bsxfun(@rdivide, nVect, nNorm);

    hRAAN = atan2(nHat(2,:),nHat(1,:));
    
    f = @(hEcc) findEcc(hVInf, hSMA, hEcc, r, rHat, thHat, hInc, hRAAN, gmu);
    lb = 1.0 + eps;
    ub = max([1-r/hSMA, r/hSMA-1]);
    
    if(ub == 1)
        lb = 1.0 + eps;
        ub = 1.0 + 2*eps;
    end

    options = optimset('TolX',1E-8, 'TolFun',1E-8);
    [hEcc, fval, exitFlag] = bisection(f,lb,ub,0,options);
    
    [~, hArg, hTA] = f(hEcc);
end

function [f, hArg, hTA] = findEcc(hVInf, hSMA, hEcc, r, rHat, thHat, hInc, hRAAN, gmu)   
    hP = hSMA.*(1-hEcc.^2);
    hTA = AngleZero2Pi(real(acos((hP./r - 1)./hEcc)));

    hTheta = atan2(rHat(3,:),thHat(3,:));
    hArg = AngleZero2Pi(hTheta-hTA);
    
    [~, OUnitVector] = vect_computeHyperSVectOVect(hSMA, hEcc, hInc, hRAAN, hArg, hTA, gmu);
    
    hVInfNorm = sqrt(sum(hVInf.^2,1));
    hVInfHat = bsxfun(@rdivide, hVInf, hVInfNorm);

    vecDiff = hVInfHat - OUnitVector;
    f = max(vecDiff, [], 1, 'ComparisonMethod','abs');
end
