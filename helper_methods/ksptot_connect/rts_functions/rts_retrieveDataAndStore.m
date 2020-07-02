function rts_retrieveDataAndStore(tcpipClient, numData, dataType)
%rts_retrieveDataAndStore Summary of this function goes here
%   Detailed explanation goes here
    readasync(tcpipClient);

    bytesDbl = 8;
    dataPts = [];   
    frameName = [];
    frameNum = [];
    transmitDateTime = [];
    
    try
        if(tcpipClient.BytesAvailable >= 88) %88 bytes is the size of the frame header
            while(tcpipClient.BytesAvailable > 88)
                [frameName, frameNum, transmitDateTime] = rts_readMinorFrameHeader(tcpipClient);
                if(strcmpi(dataType,'d'))
                    if(numData == -1)
                        dataPts = fread(tcpipClient,floor(tcpipClient.BytesAvailable/bytesDbl),'double');
                    else
                        numDataToRet = min(numData, floor(tcpipClient.BytesAvailable/bytesDbl));
                        if(numDataToRet > 0)
                            dataPts = fread(tcpipClient,numDataToRet,'double');
                        else
                            dataPts = [];
                        end
                    end
                elseif(strcmpi(dataType,'s'))
                    dataPts = deblank(fscanf(tcpipClient,'%c',numData));
                end
            end
            
            retDateTime = datevec(now);
            data = {dataPts, frameName, frameNum, transmitDateTime', retDateTime};
            set(tcpipClient,'UserData',data);
        end
    catch ME
        disp(ME.message);
    end

end

