function [mean, ehAnom] = computeMeanFromTrueAnom(tru, ecc)
%computeMeanFromTrueAnom Summary of this function goes here
%   Detailed explanation goes here
    if(isscalar(ecc) && numel(tru) > 1)
        ecc = repmat(ecc, size(tru));
    end

    mean = NaN(size(tru));
    ehAnom = NaN(size(tru));
    
    bool = ecc < 1.0;
    if(any(bool))
        eccBool = ecc(bool);
        truBool = tru(bool);
        
        EA = (atan2(sqrt(1-eccBool.^2).*sin(truBool), eccBool+cos(truBool)));
        
        EA = AngleZero2Pi(EA);

        mean(bool) = AngleZero2Pi(EA - eccBool.*sin(EA));
        ehAnom(bool)=EA;
    end
    
    bool = not(bool);
    if(any(bool))
        eccBool = ecc(bool);
        truBool = tru(bool);
        
        HA = computeHyperAFromTrueAnom(truBool, eccBool);
        mean(bool) = eccBool.*sinh(HA)-HA;
        
        ehAnom(bool) = HA;
    end
end