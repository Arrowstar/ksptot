function outStr = convertSec2RSSDateTime(secUT)
    epochDT = datetime(1951,1,1,0,0,0, 'TimeZone','UTC'); % RSS default

    dt = epochDT + seconds(secUT);

    outStr = datetime(dt, Format='dd-MM-yyyy HH:mm');
end