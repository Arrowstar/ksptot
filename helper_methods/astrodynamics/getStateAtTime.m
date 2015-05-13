function [rVect, vVect] = getStateAtTime(bodyInfo, time, gmu)
%getStateAtTime Summary of this function goes here
%   Detailed explanation goes here
    numTimes = length(time);

    sma = bodyInfo.sma * (zeros(1, numTimes)+1);
    ecc = bodyInfo.ecc * (zeros(1, numTimes)+1);
    inc = AngleZero2Pi(deg2rad(bodyInfo.inc)) * (zeros(1, numTimes)+1);
    raan = AngleZero2Pi(deg2rad(bodyInfo.raan)) * (zeros(1, numTimes)+1);
    argp = AngleZero2Pi(deg2rad(bodyInfo.arg)) * (zeros(1, numTimes)+1);
    M0 = deg2rad(bodyInfo.mean) * (zeros(1, numTimes)+1); 
       
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