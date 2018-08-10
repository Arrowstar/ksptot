function rts_mainGUIClockUpdateFunc(~, ~, hClockLabel, tcpipClient) 
%rts_mainGUIClockUpdateFunc Summary of this function goes here
%   Detailed explanation goes here
%     disp(get(obj,'Name'));
    try
        data = get(tcpipClient,'UserData');
        ut = data{1};
        if(~isempty(ut))
            [year, day, hour, minute, sec] = convertSec2YearDayHrMnSec(ut);
            dateStr = formDateStr(year, day, hour, minute, sec);
            set(hClockLabel,'String',['Current UT: ', dateStr]);
        end
    catch ME
        
    end
end
