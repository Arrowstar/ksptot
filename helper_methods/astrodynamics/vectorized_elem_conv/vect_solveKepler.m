function [EccA] = vect_solveKepler(meanALL, eccALL)
%solveKepler Summary of this function goes here
%   Detailed explanation goes here.
    EccA = zeros(size(eccALL));
    
    if(any(eccALL < 1))
        ecc = eccALL(eccALL < 1);
        mean = meanALL(eccALL < 1);

        mean = AngleZero2Pi(mean);
        
        E0 = zeros(size(mean));
        E1 = ones(size(mean)) * Inf;
        if(any(mean > pi))
            E0(mean > pi) = mean(mean > pi) - ecc(mean > pi);
        end
        if(any(mean <= pi))
            E0(mean <= pi) = mean(mean <= pi) + ecc(mean <= pi);
        end
        
        first = true;
        while(any(abs(E1 - E0) > 1E-8))
            if(~first)
                E0 = E1;
            end
            E1 = E0 + (mean - E0 + ecc.*sin(E0))./(1-ecc.*cos(E0));
            if(first)
                first = false;
            end
        end
        EccA(eccALL < 1) = E1;
    end


    if(any(eccALL >= 1))
        ecc = eccALL(eccALL >= 1);
        mean = meanALL(eccALL >= 1);
        
        H0 = zeros(size(mean));
        H1 = ones(size(mean)) * Inf;
        
        if(any(ecc < 1.6))
            bool = (-pi < mean & mean < 0) | mean > pi;
            H0(bool) = mean(bool) - ecc(bool);
            H0(not(bool)) = mean(not(bool)) + ecc(not(bool));
%             if(any(bool))
%                 H0(bool) = mean(bool) - ecc(bool);
%             else
%                 H0(bool) = mean(bool) + ecc(bool);
%             end
        end
        if(any(ecc >= 1.6)) 
            bool = ecc<3.6 & abs(mean) > pi;
            H0(bool) = mean(bool) - sign(mean(bool)).*ecc(bool);
            H0(not(bool)) = mean(not(bool))./(ecc(not(bool))-1);
%             if(any(bool))
%                 H0(bool) = mean(bool) - sign(mean(bool)).*ecc(bool);
%             else
%                 H0(bool) = mean(bool)./(ecc(bool)-1);
%             end
        end

        first = true;
        while(any(abs(H1 - H0) > 1E-8))
            if(~first)
                H0 = H1;
            end
            H1 = H0 + (mean - ecc.*sinh(H0) + H0)./(ecc.*cosh(H0) - 1);
            if(first)
                first = false;
            end
        end
        EccA(eccALL >= 1) = H1;
    end
end

