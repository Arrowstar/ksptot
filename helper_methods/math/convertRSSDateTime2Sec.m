function secUT = convertRSSDateTime2Sec(dateStr)
    epochDT = datetime(1951,1,1,0,0,0,'TimeZone','UTC'); % RSS default

    fmts = ["dd-MM-uuuu HH:mm:ss","dd-MM-uuuu HH:mm","dd/MM/uuuu HH:mm:ss", ...
            "dd/MM/uuuu HH:mm","uuuu-MM-dd HH:mm:ss","uuuu-MM-dd HH:mm", ...
            "dd-MM-uuuu","dd/MM/uuuu","uuuu-MM-dd"];

    parsed = NaT;
    for f = fmts
        try
            parsed = datetime(strtrim(dateStr),'InputFormat',f,'TimeZone','UTC');
            if ~isnat(parsed), break; end
        catch
        end
    end
    if isnat(parsed)
        error('Could not parse date string: "%s".', dateStr);
    end

    secUT = seconds(parsed - epochDT);
end