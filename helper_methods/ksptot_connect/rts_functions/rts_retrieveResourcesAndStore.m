function rts_retrieveResourcesAndStore(~, ~,tcpipClient, vesselGUID, dblsTcpipClient)
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

    try
        data = get(dblsTcpipClient,'UserData');
        numDbls = data{1}(1);
        if(~isempty(numDbls))
            rts_retrieveDataAndStore(tcpipClient, numDbls, 'd');
        end
    catch ME
%         disp(ME.message);
%         for k=1:length(ME.stack)
%             ME.stack(k)
%         end
    end
end

