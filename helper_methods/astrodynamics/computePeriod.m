function [period] = computePeriod(sma, gmu)
%computePeriod Summary of this function goes here
%   Detailed explanation goes here
    if(sma > 0)
        period = 2*pi* sqrt(sma.^3./gmu);
    else
        error('MATLAB:computePeriod:smaMustBePositive', 'Orbit sma must be greater than zero to compute period.');
    end
end

