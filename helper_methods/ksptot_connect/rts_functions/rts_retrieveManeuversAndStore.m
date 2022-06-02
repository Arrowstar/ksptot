function rts_retrieveManeuversAndStore(~, ~,tcpipClient, vesselGUID, dblsTcpipClient)
%rts_retrieveManeuversAndStore Summary of this function goes here
%   Detailed explanation goes here
    try
        data = get(dblsTcpipClient,'UserData');
        numNodes = data{1}(6);
%         numNodes = readDoublesFromKSPTOTConnect('GetVesselNumOfManeuverNodes', vesselGUID, false, [], 1);
        if(numNodes == 0)
            numNodes = 1;
        end
        nodeDataPts = 5*numNodes;
        rts_retrieveDataAndStore(tcpipClient, nodeDataPts, 'd');
    catch ME
%         for k=1:length(ME.stack)
%             ME.stack(k)
%         end
    end
end