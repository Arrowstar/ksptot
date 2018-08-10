function rts_retrieveDynamicsAndStore(~, ~,tcpipClient, vesselGUID, dblsTcpipClient)
%rts_retrieveDynamicsAndStore Summary of this function goes here
%   Detailed explanation goes here
    attPtsBase = 30;

    try
        data = get(dblsTcpipClient,'UserData');
        rwaDataPts = data{1}(7)*4;
        rwaDataPts = max(4,rwaDataPts);
        rts_retrieveDataAndStore(tcpipClient, attPtsBase+rwaDataPts, 'd');
%         rwaInfo = readDoublesFromKSPTOTConnect('GetVesselNumberOfRWAs', vesselGUID, false, [], 3);
%         if(~isempty(rwaInfo))
%             rwaDataPts = numRWAs;
%             
%         end
    catch ME
%         disp(ME.message);
%         for k=1:length(ME.stack)
%             ME.stack(k)
%         end
    end
end