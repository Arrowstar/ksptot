function rts_waitForData(tcpipClient)
%rts_waitForData Summary of this function goes here
%   Detailed explanation goes here
    
    elapsedTime = 0;
%     pause(0.05);
    tic;
    while(tcpipClient.BytesAvailable <= 0 && elapsedTime<1)
        elapsedTime = toc;
        pause(0.025);
    end
end

