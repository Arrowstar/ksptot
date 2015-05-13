function [EccA] = solveKepler(mean, ecc)
%solveKepler Summary of this function goes here
%   Detailed explanation goes here.
    if(ecc < 1)
        if(mean < 0 || mean > 2*pi)
            mean = AngleZero2Pi(mean);
        end
        if(abs(mean - 0) < 1E-8)
            EccA = 0;
            return
        elseif(abs(mean - pi) < 1E-8 )
            EccA = pi;
            return;
        else
            if(mean < pi)
                lb = 0;
                ub = pi;
            else
                lb = pi;
                ub = 2*pi;
            end
        end
%         M=@(E) E - ecc*sin(E) - mean;
%         EccA=fzero(M,[lb ub]);
        EccA = keplerEq(mean,ecc,1E-10);
    else
        if(abs(mean - 0) < 1E-8)
            EccA = 0;
            return
        else
            if(mean > 0)
                lb = 0;
                ub = 10;
            else
                lb = -10;
                ub = 0;
            end
            M = @(H) ecc*sinh(H) - H - mean;
            EccA = fzero(M, [lb ub]); %need to do this to return correctly, even though it's misnamed
        end
    end
end

