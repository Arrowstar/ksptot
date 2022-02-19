function [printdigs] = fullAccNum2Str(x)
%fullAccNum2Str Summary of this function goes here
%   Detailed explanation goes here
    printdigs = stripzeros(sprintf('%.*f', max(ceil(-log10(eps(x)))-2,1), x));
end

