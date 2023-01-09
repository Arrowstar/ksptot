function [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits()
%getSecondsInVariousTimeUnits Summary of this function goes here
%   Detailed explanation goes here
    global options_UseEarthTimeSystem;

    secInMin = 60;
    secInHr = 60*secInMin;
	if(options_UseEarthTimeSystem == true)
        secInDay = 24*secInHr;
        secInYear = 365*secInDay;
    else
        secInDay = 6*secInHr;
        secInYear = 426*secInDay;
	end
end

