function [rVect, vVect] = getStateAtTime(bodyInfo, time, gmu)
%getStateAtTime Summary of this function goes here
%   Detailed explanation goes here
    numTimes = length(time);

    oneArray = (zeros(1, numTimes)+1);
    
    sma = bodyInfo.sma * oneArray;
    ecc = bodyInfo.ecc * oneArray;
    inc = AngleZero2Pi(deg2rad(bodyInfo.inc)) * oneArray;
    raan = AngleZero2Pi(deg2rad(bodyInfo.raan)) * oneArray;
    argp = AngleZero2Pi(deg2rad(bodyInfo.arg)) * oneArray;
    M0 = deg2rad(bodyInfo.mean) * oneArray; 
       
    n = computeMeanMotion(sma, gmu);
    deltaT = time - bodyInfo.epoch;
    M = M0 + n.*deltaT;
    tru = computeTrueAnomFromMean(M, ecc);
    
    if(length(tru) > 1)
        [rVect,vVect]=vect_getStatefromKepler(sma, ecc, inc, raan, argp, tru, gmu, true); 
    else
        [rVect,vVect]=getStatefromKepler(sma, ecc, inc, raan, argp, tru, gmu, true);
    end
end