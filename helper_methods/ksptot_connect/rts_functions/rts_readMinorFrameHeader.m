function [frameName, frameNum, transmitDateTime] = rts_readMinorFrameHeader(tcpipClient)
%rts_readMinorFrameHeader Summary of this function goes here
%   Detailed explanation goes here
    
        frameName = deblank(fscanf(tcpipClient,'%c',32));
        frameNum = fread(tcpipClient,1,'double');
        transmitDateTime = fread(tcpipClient,6,'double');
end

