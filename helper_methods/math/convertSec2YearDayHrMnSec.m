function [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(secUT)
%convertSec2YearDayHrMnSec Summary of this function goes here
%   Detailed explanation goes here

    [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits();
    
    year = floor(secUT/secInYear) + 1;
    secUT = secUT - (year-1)*secInYear;
    
    day = floor(secUT/secInDay) + 1;
    secUT = secUT - (day-1)*secInDay;
    
    hour = floor(secUT/secInHr);
    secUT = secUT - hour*secInHr;
    
    minute = floor(secUT/secInMin);
    secUT = secUT - minute*secInMin;
    
    sec = secUT;
end

