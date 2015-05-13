function outStrs = readManyStringsFromKSPTOTConnect(dataType, paramStr, bytesPerString, waitForData, varargin)
%readManyStringsFromKSPTOTConnect Summary of this function goes here
%   Detailed explanation goes here

    dataType = paddStr(dataType(1:min(length(dataType),32)), 32);
    dataClass = 's';
    
    try
        if(isempty(varargin))
            tcpipClient = createTcpIpClient();
            closeOnFinish = true;
        else
            tcpipClient = varargin{1};
            closeOnFinish = false;
        end
       

        if(strcmpi(get(tcpipClient,'Status'),'closed'))
            fopen(tcpipClient);
        end
%         fwrite(tcpipClient,[dataType,dataClass,paramStr],'char');
        writeDataToKSPTOTConnect(dataType, paramStr, dataClass, tcpipClient);
        
        if(waitForData)
            rts_waitForData(tcpipClient);
        end
        
        outStrs = {};
        while(tcpipClient.BytesAvailable >= bytesPerString)
            outStr = fscanf(tcpipClient,'%c',bytesPerString);
            outStrs{end+1} = outStr; %#ok<AGROW>
            pause(0.02);
        end        

        if(closeOnFinish)
            fclose(tcpipClient);
            delete(tcpipClient);
        end
    catch ME
        error(['Read Strings from KSPTOT Connect failed: ', ME.message]);
        outStrs = [];
    end
end