function [printdigs] = fullAccNum2Str(x)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    printdigs = stripzeros(sprintf('%.*f', ceil(-log10(eps(x))), x));
end

