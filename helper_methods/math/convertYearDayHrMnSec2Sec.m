function [secUT] = convertYearDayHrMnSec2Sec(year, day, hour, min, sec)
%convertYearDayHrMnSec2Sec Summary of this function goes here
%   Detailed explanation goes here

    [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits();
    
    secUT = (year-1)*secInYear;
    secUT = secUT + (day-1)*secInDay;
    secUT = secUT + hour*secInHr;
    secUT = secUT + min*secInMin;
    secUT = secUT + sec;    
end

