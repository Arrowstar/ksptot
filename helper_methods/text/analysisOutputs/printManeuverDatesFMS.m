function [xferOrbitTextDates] = printManeuverDatesFMS(departUT, flybyUT, arriveUT, form, paddLen)
%printManeuverDatesFMS Summary of this function goes here
%   Detailed explanation goes here
        xferOrbitTextDates={};
        
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(departUT);
        dateStr = formDateStr(year, day, hour, minute, sec);
        xferOrbitTextDates{end+1} = [paddStr('Departure Date = ',17), dateStr];
        xferOrbitTextDates{end+1} = [paddStr('',22), '(',num2str(departUT, form),' sec UT)'];
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(flybyUT);
        dateStr = formDateStr(year, day, hour, minute, sec);
        xferOrbitTextDates{end+1} = [paddStr('Flyby Date = ',17), dateStr];
        xferOrbitTextDates{end+1} = [paddStr('',22), '(',num2str(flybyUT, form),' sec UT)'];
        [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(arriveUT);
        dateStr = formDateStr(year, day, hour, minute, sec);
        xferOrbitTextDates{end+1} = [paddStr('Arrival Date = ',17), dateStr];
        xferOrbitTextDates{end+1} = [paddStr('',22), '(',num2str(arriveUT, form),' sec UT)'];
end

