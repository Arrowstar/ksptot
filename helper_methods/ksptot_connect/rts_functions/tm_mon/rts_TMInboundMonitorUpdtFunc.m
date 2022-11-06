function rts_TMInboundMonitorUpdtFunc(~,~, hRtsMainGUI, hTable)
%rts_TMInboundMonitor Summary of this function goes here
%   Detailed explanation goes here
    dateStrFormat = 'yyyy/mm/dd HH:MM:SS.FFF';
    tcpips = getappdata(hRtsMainGUI,'tcpip');

    tableData = {};
    try
        validtcpips = {};
        for(i=1:length(tcpips))
            if(isvalid(tcpips{i}))
                validtcpips{end+1} = tcpips{i};
            else
                delete(tcpips{i});
            end
        end

        for(i=1:length(validtcpips))            
            conn = validtcpips{i};
            connData = get(conn,'UserData');
            if(~isempty(connData))
                
                tableData{i,1} = connData{2};
                tableData{i,2} = connData{3};
                tableData{i,3} = datestr(connData{4}, dateStrFormat);
                tableData{i,4} = datestr(connData{5}, dateStrFormat);

                data = connData{1};
                dataStr = '[';
                for(j=1:length(data));
                    dataStr = strcat(dataStr,[num2str(data(j)), ', ']);
                end
                if(~isempty(data))
                    dataStr(end) = '';
                end
                dataStr = strcat(dataStr,']');

                dataStr = trucStr(dataStr, 49, false);
                tableData{i,5} = dataStr;
            end
        end     
        
        setTableData(hTable, tableData);
    catch ME
        disp(ME.message);
        disp(ME.stack(1));
    end  
end

function strTruc = trucStr(str, numChars, keepLastChar)
    if(length(str) < numChars)
        strTruc = str;
        return;
    end
    if(keepLastChar)
        lastChar = str(end);
        numSub = 4;
    else
        lastChar = '';
        numSub = 3;
    end
    strTruc = str(1:numChars-numSub);
    strTruc = strcat(strTruc,'...', lastChar);
end