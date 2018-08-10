function outDoubles = readDoublesFromKSPTOTConnect(dataType, paramStr, waitForData, varargin)
%readStringFromKSPTOTConnect Summary of this function goes here
%   Detailed explanation goes here

    bytesDbl = 8;
    
    dataTypePassedIn = dataType;
    dataType = paddStr(dataType(1:min(length(dataType),32)), 32);
    dataClass = 's';
    
    if(isempty(paramStr))
        dataClass = 'n';
    end
    
    try
        if(isempty(varargin))
            tcpipClient = createTcpIpClient();
            closeOnFinish = true;
            dblToRead = -1;
        else
            if(isempty(varargin{1}))
                tcpipClient = createTcpIpClient();
                closeOnFinish = true;
            else
                tcpipClient = varargin{1};
                closeOnFinish = false;
            end
            dblToRead = -1;
            
            if(length(varargin) >= 2)
                dblToRead = varargin{2};
            end
        end
        
        if(~isvalid(tcpipClient))
            outDoubles = [];
            delete(tcpipClient);
            return;
        end
        

        if(strcmpi(tcpipClient.Status,'Closed'))
            fopen(tcpipClient);
        end
%         fwrite(tcpipClient,[dataType,dataClass,paramStr],'char');
        writeDataToKSPTOTConnect(dataType, paramStr, dataClass, tcpipClient);

        if(waitForData)
            rts_waitForData(tcpipClient);
        end
        
        if(dblToRead == -1)
            outDoubles = fread(tcpipClient,tcpipClient.BytesAvailable/bytesDbl,'double');
        else
            outDoubles = fread(tcpipClient,dblToRead,'double');
        end
        
        if(closeOnFinish)
            fclose(tcpipClient);
            delete(tcpipClient);
        end
        
    catch ME
        outDoubles = [];
        disp(['Read doubles from KSPTOT Connect failed: ', ME.message]);
        for k=1:length(ME.stack)
            disp(ME.stack(k));
        end
    end
end

