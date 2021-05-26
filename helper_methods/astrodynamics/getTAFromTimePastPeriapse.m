function [tru] = getTAFromTimePastPeriapse(timePastPeri, sma, ecc, gmuXfr)
%getTAFromTimePastPeriapse Summary of this function goes here
%   Detailed explanation goes here

    eN = computeMeanMotion(sma, gmuXfr);
    MA = eN*timePastPeri;
    tru = computeTrueAnomFromMean(MA, ecc);
    if(ecc < 1.0)
        tru = AngleZero2Pi(tru);
    end
end