function [sma, ecc] =  computeSmaEccFromRaRp(rA, rP)
    sma = (rA + rP)/2;
    ecc = getEccFromRpAndSma(sma, rP);
end