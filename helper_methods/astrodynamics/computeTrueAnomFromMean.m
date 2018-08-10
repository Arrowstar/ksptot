function [tru] = computeTrueAnomFromMean(mean, ecc)
%computeTrueAnomFromMean Summary of this function goes here
%   Detailed explanation goes here
    if(length(ecc) > 1) %use vectorized if needed, else use compiled
        bool = ecc < 1.0;
        EA = zeros(size(ecc));
        tru = zeros(size(ecc));
        if(any(bool))
            EA(bool) = vect_solveKepler(mean(bool), ecc(bool));
            tru(bool) = computeTrueAnomFromEccAnom(EA(bool), ecc(bool));
        end
        bool = ~bool;
        if(any(bool))
            HA(bool) = vect_solveKepler(mean(bool), ecc(bool));
            tru(bool) = computeTrueAnomFromHypAnom(HA(bool), ecc(bool));
        end
    else
        if(ecc < 1.0)
            EA = solveKepler(mean, ecc);
            tru = computeTrueAnomFromEccAnom(EA, ecc);
        else
            HA = solveKepler(mean, ecc);
            tru = computeTrueAnomFromHypAnom(HA, ecc);
        end
    end
end

