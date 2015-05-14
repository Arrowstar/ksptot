function [H] = keplerEqHyp(M,e, eps)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    if(e < 1.6)
        if((-pi < M && M < 0) || M > pi)
            H = M - e;
        else
            H = M + e;
        end
    else
        if(e < 3.6 && abs(M)>pi)
            H = M - sign(M)*e;
        else
            H = M/(e - 1);
        end
    end
    
    Hn = M;
    Hn1 = H;
    while(abs(Hn1 - Hn) > eps)
        Hn = Hn1;
        Hn1 = Hn + (M - e*sinh(Hn) + Hn)/(e*cosh(Hn) - 1);
    end
    
    H = Hn1;
end

