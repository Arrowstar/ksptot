function massFlowRate = getMdotFromThrustIsp(thrust, isp)
%getMdotFromThrustIsp Summary of this function goes here
%   Detailed explanation goes here

    g0 = getG0(); %m/s^2
    massFlowRate = thrust / (g0 * isp); %ton/s = kN / ((m/s^2) * s)
end

