function [secPastPeri] = getTimePastPeriapseFromTA(tru, sma, ecc, gmuXfr)
%getTimePastPeriapseFromTA Summary of this function goes here
%   Detailed explanation goes here

    MA = computeMeanFromTrueAnom(tru, ecc);
    eN = computeMeanMotion(sma, gmuXfr);
    if(ecc<1.0)
        MA = AngleZero2Pi(MA);
        secPastPeri = MA/eN;
    else
        secPastPeri = abs(MA/eN);
    end
end

