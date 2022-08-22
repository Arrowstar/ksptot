function writeKsptotLogFileHeaderToConsole()
    str{1}     = '========================================';
    str{end+1} = '  _  __ _____ _____ _______ ____ _______ ';
    str{end+1} = ' | |/ // ____|  __ \__   __/ __ \__   __|';
    str{end+1} = " | ' /| (___ | |__) | | | | |  | | | | ";
    str{end+1} = ' |  <  \___ \|  ___/  | | | |  | | | | ';
    str{end+1} = ' | . \ ____) | |      | | | |__| | | |  ';
    str{end+1} = ' |_|\_\_____/|_|      |_|  \____/  |_|  ';
    str{end+1} = '========================================';
    str{end+1} = sprintf('KSPTOT v%s', getKSPTOTVersionNumStr());
    str{end+1} = sprintf('MATLAB %s', version());
    str{end+1} = sprintf('DATE: %s', datestr(now, 'YYYY/mm/DD hh:MM:ss'));
    str{end+1} = '========================================';
    
    if(isdeployed())
        for(i=1:length(str))
            disp(str{i});
        end
    end
end

                                         
                                         

