function outStr = readStringFromKSPTOTConnect(dataType, paramStr, waitForData, varargin)
%readStringFromKSPTOTConnect Summary of this function goes here
%   Detailed explanation goes here
    
    dataType = paddStr(dataType(1:min(length(dataType),32)), 32);
    dataClass = 's';
    
    try
        if(isempty(varargin))
            tcpipClient = createTcpIpClient();
            closeOnFinish = true;
            bytesToRead = -1;
        else
            tcpipClient = varargin{1};
            closeOnFinish = false;
            bytesToRead = -1;
            
            if(length(varargin) >= 2)
                bytesToRead = varargin{2};
            end
        end
     

        if(strcmpi(get(tcpipClient,'Status'),'closed'))
            fopen(tcpipClient);
        end
%         fwrite(tcpipClient,[dataType,dataClass,paramStr],'char');
        writeDataToKSPTOTConnect(dataType, paramStr, dataClass, tcpipClient);
        
        if(waitForData)
            rts_waitForData(tcpipClient);
        end
        
        if(bytesToRead == -1)
            outStr = fscanf(tcpipClient,'%c',tcpipClient.BytesAvailable);
        else
            outStr = fscanf(tcpipClient,'%c',min(tcpipClient.BytesAvailable,bytesToRead));
        end
        if(closeOnFinish)
            fclose(tcpipClient);
            delete(tcpipClient);
        end
    catch ME
%         error(['Read String from KSPTOT Connect failed: ', ME.message]);
        outStr = [];
    end
end

