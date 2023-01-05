function [EccA] = solveKepler(mean, ecc)
%solveKepler Summary of this function goes here
%   Detailed explanation goes here.
    tol = 1E-12;

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
%             if(mean < pi)
%                 lb = 0;
%                 ub = pi;
%             else
%                 lb = pi;
%                 ub = 2*pi;
%             end
        end
        EccA = keplerEq(mean,ecc,tol);
    else
        if(abs(mean - 0) < 1E-8)
            EccA = 0;
            return
        else
            EccA = keplerEqHyp(mean,ecc,tol);
        end
    end
end

