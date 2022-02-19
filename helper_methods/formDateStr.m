function [dateStr] = formDateStr(year, day, hour, minute, sec)
%formDateStr Summary of this function goes here
%   Detailed explanation goes here
    
    hrStr = sprintf('%02d', hour);
    minStr = sprintf('%02d', minute);
    secStr = sprintf('%06.3f', sec);

    hrMinSec = [hrStr, ':', minStr, ':', secStr];
    dateStr = ['Year ', num2str(year), ', Day ', num2str(day), ' ', hrMinSec];
end

