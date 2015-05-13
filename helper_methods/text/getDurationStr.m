function [durationStr] = getDurationStr(sec)
%getDurationStr Summary of this function goes here
%   Detailed explanation goes here

    [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(sec);
    year = year - 1;
    day = day - 1;

    if(year>0)
        if(year>1)
            numYearStr = 'Years';
        else
            numYearStr = 'Year';
        end
        yearStr = [num2str(year), ' ', numYearStr];
    else
        yearStr = '';
    end
    
    if(day>0)
        if(day>1)
            numDayStr = 'Days';
        else
            numDayStr = 'Day';
        end
        dayStr = [num2str(day), ' ', numDayStr];
    else
        dayStr = '';
    end
    
    hrStr = sprintf('%02d', hour);
    minStr = sprintf('%02d', minute);
    secStr = sprintf('%06.3f', sec);

    hrMinSec = [hrStr, ':', minStr, ':', secStr];
    
    durationStr = '';
    if(not(isempty(yearStr)))
        durationStr = [durationStr, yearStr];
    end
    
    if(not(isempty(dayStr)))
        if(isempty(durationStr))
            durationStr = [durationStr, dayStr];
        else
            durationStr = [durationStr, ', ', dayStr];
        end
    end
    
    if(isempty(durationStr))
        durationStr = hrMinSec;
    else 
        durationStr = [durationStr, ' ', hrMinSec];
    end
end

