function [sma] = computeSMAFromPeriod(period, gmu)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    sma = (((period./(2.*pi)).^2).*gmu).^(1/3);

end

