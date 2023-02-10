function [hSMA, hEcc, hInc, hRAAN, hArg, hTA, rpVect, rp] = computeHyperOrbitFromMultiFlybyParams(hSMA, hEcc, hHat, SOHat, sHatBool)
%computeHyperOrbitFromFlybyParams Summary of this function goes here
%   Detailed explanation goes here
    delta = 2*asin(1./hEcc);
    if(sHatBool==1)
        sHat = SOHat;
        deltaHat = rodrigues_rot_vect(sHat, hHat, delta/2);
%         deltaHat2 = rodrigues_rot(sHat(:,1), hHat(:,1), delta(1)/2);
    else
        oHat = SOHat;
        deltaHat = rodrigues_rot_vect(oHat, hHat, -delta/2);
%         deltaHat2 = rodrigues_rot(oHat(:,1), hHat(:,1), -delta(1)/2);
    end

    eccHatCross = cross(deltaHat,hHat);
    eccHatCrossNorm = sqrt(sum(abs(eccHatCross).^2,1));
    eccHat = bsxfun(@rdivide,eccHatCross,eccHatCrossNorm);

    rp = hSMA.*(1-hEcc);
    rpVect = bsxfun(@times,rp,eccHat);
    normRpVect = sqrt(sum(abs(rpVect).^2,1));

    hInc = acos(hHat(3,:));
    zHat = [zeros(size(delta));zeros(size(delta));ones(size(delta))];

    nHatCross = cross(zHat,hHat);
    nHatCrossNorm = sqrt(sum(abs(nHatCross).^2,1));
    nHat = bsxfun(@rdivide,nHatCross,nHatCrossNorm);

    hRAAN = zeros(size(hSMA));
    bool = any(isnan(nHat),1);
    
    hRAAN(~bool) = atan2(nHat(2,~bool),nHat(1,~bool));
    
    hP = hSMA.*(1-hEcc.^2);
    hTA = AngleZero2Pi(real(acos((hP./normRpVect - 1)./hEcc)));

    thHatCross = cross(hHat,eccHat);
    thHatCrossNorm = sqrt(sum(abs(thHatCross).^2,1));
    thHat = bsxfun(@rdivide,thHatCross,thHatCrossNorm);

    hTheta = atan2(eccHat(3,:),thHat(3,:));
    hArg = AngleZero2Pi(hTheta-hTA);
end

