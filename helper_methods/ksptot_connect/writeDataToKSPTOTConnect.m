function writeDataToKSPTOTConnect(dataType, data, varargin)
%writeDataToKSPTOTConnect Summary of this function goes here
%   Detailed explanation goes here

    dataType = paddStr(dataType(1:min(length(dataType),32)), 32);
    if(nargin == 2)
        dataClass = 'd';
    else
        dataClass = varargin{1};
    end
    
    try
        if(nargin == 4)
            tcpipClient = varargin{2};
            closeOnFinish = false;
        else
            tcpipClient = createTcpIpClient();
            closeOnFinish = true;
        end
        
        if(strcmpi(tcpipClient.Status,'Closed'))
            fopen(tcpipClient);
        end

        fwrite(tcpipClient,[dataType,dataClass],'char');
        
        dt = whos('data');
        dataSize = uint32(dt.bytes);
        
        if(strcmpi(dataClass,'d'))
            fwrite(tcpipClient,dataSize,'uint32');
            fwrite(tcpipClient,data,'double');
        elseif(strcmpi(dataClass,'t'))
            fwrite(tcpipClient,dataSize/2,'uint32'); %divide by two because MATLAB chars are two bytes but get transmitted as 1 byte (8 bits), see doc on instrument/fwrite: precision section 
            fwrite(tcpipClient,data,'char');
        elseif(strcmpi(dataClass,'s'))
            fwrite(tcpipClient,dataSize/2,'uint32'); %same as above
            fwrite(tcpipClient,data,'char');
        else
            fwrite(tcpipClient,dataSize,'uint32');
            fwrite(tcpipClient,data,'double');
        end
        
        if(closeOnFinish)
            fclose(tcpipClient);
            delete(tcpipClient);
        end
    catch ME
        error(['Write to KSPTOT Connect failed: ', ME.message]);
    end
end

