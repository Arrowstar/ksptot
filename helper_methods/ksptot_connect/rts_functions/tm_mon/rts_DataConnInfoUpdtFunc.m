function rts_DataConnInfoUpdtFunc(~,~, hRtsMainGUI, hTable)
%rts_DataConnInfoUpdtFunc Summary of this function goes here
%   Detailed explanation goes here
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

            if(isvalid(conn))
                tableData{i,1} = get(conn,'Name');
                tableData{i,2} = cap1stLetter(get(conn,'Status'));
                tableData{i,3} = [get(conn,'RemoteHost'), ':', num2str(get(conn,'RemotePort'))];
                tableData{i,4} = num2str(get(conn,'BytesAvailable'));
                tableData{i,5} = num2str(get(conn,'ValuesReceived'));
            else
                delete(conn);
            end
        end     
        
        setTableData(hTable, tableData)
    catch ME
        disp(ME.stack(2));
    end  
end

