function [energy] = getSpecOrbitEnergyFromSma(sma, gmu)
%getSpecOrbitEnergyFromSma Summary of this function goes here
%   Detailed explanation goes here

    energy = -gmu/(2*sma);
end

