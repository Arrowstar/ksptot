function [rVect, vVect] = getStateAtTime_alg(time, sma, ecc, inc, raan, arg, mean, epoch, gmu)
%getStateAtTime Summary of this function goes here
%   Detailed explanation goes here
    numTimes = length(time);

    oneArray = (zeros(1, numTimes)+1);
    
    sma = sma * oneArray;
    ecc = ecc * oneArray;
    inc = AngleZero2Pi(deg2rad(inc)) * oneArray;
    raan = AngleZero2Pi(deg2rad(raan)) * oneArray;
    argp = AngleZero2Pi(deg2rad(arg)) * oneArray;
    M0 = deg2rad(mean) * oneArray; 
       
    n = computeMeanMotion(sma, gmu);
    deltaT = time - epoch;
    M = (M0(:) + n(:).*deltaT(:))';
    tru = computeTrueAnomFromMean(M, ecc);

    if(length(tru) > 1)
        [rVect,vVect] = vect_getStatefromKepler(sma, ecc, inc, raan, argp, tru, gmu, false); 
    else
        [rVect, vVect] = getStatefromKepler_Alg(sma, ecc, inc, raan, argp, tru, gmu);
    end
end