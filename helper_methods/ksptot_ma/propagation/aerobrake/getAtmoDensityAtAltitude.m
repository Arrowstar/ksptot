function [density] = getAtmoDensityAtAltitude(bodyInfo, altitude)
%getAtmoDensityAtAltitude Summary of this function goes here
%   Detailed explanation goes here
    press2Density = 1.2230948554874; 
    pressure = getPressureAtAltitude(bodyInfo, altitude) / 101325; % Atm
    density = pressure * press2Density; %kg/m^3
end

function pressure = getPressureAtAltitude(bodyInfo, altitude)
    p0 = (bodyInfo.atmopresssl*1000); %Pa
    scaleHgt = bodyInfo.atmoscalehgt; %km
    
    if(altitude <= bodyInfo.atmohgt)
        pressure = p0 * exp(-altitude/scaleHgt); %Pa
    else
        pressure = 0; %Pa
    end
end