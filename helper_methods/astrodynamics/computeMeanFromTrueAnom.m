function [mean, ehAnom] = computeMeanFromTrueAnom(tru, ecc)
%computeMeanFromTrueAnom Summary of this function goes here
%   Detailed explanation goes here
    if(ecc<1.0)
        EA = (atan2(sqrt(1-ecc^2)*sin(tru), ecc+cos(tru)));
        if(tru < 2*pi)
            EA = AngleZero2Pi(EA);
        end
        mean = EA - ecc*sin(EA);
        mean = AngleZero2Pi(mean);
        
        ehAnom=EA;
    else
        HA = computeHyperAFromTrueAnom(tru, ecc);
        mean = ecc*sinh(HA)-HA;
        
        ehAnom = HA;
    end
end

