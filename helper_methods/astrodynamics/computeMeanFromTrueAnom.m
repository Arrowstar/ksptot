function [mean, ehAnom] = computeMeanFromTrueAnom(tru, ecc)
%computeMeanFromTrueAnom Summary of this function goes here
%   Detailed explanation goes here
    mean = NaN(size(tru));
    ehAnom = NaN(size(tru));
    
    bool = ecc < 1.0;
    if(any(bool))
        eccBool = ecc(bool);
        truBool = tru(bool);
        
        EA = (atan2(sqrt(1-eccBool.^2).*sin(truBool), eccBool+cos(truBool)));
        
        tru2PiBool = truBool < 2*pi;
        EA(tru2PiBool) = AngleZero2Pi(EA(tru2PiBool));

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

%     if(ecc<1.0)
%         EA = (atan2(sqrt(1-ecc^2)*sin(tru), ecc+cos(tru)));
%         if(tru < 2*pi)
%             EA = AngleZero2Pi(EA);
%         end
%         mean = EA - ecc*sin(EA);
%         mean = AngleZero2Pi(mean);
%         
%         ehAnom=EA;
%     else
%         HA = computeHyperAFromTrueAnom(tru, ecc);
%         mean = ecc*sinh(HA)-HA;
%         
%         ehAnom = HA;
%     end

