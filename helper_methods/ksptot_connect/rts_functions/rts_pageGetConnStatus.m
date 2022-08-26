function rts_pageGetConnStatus(~, ~, vesselGUID, hRtsMainGUI, connStatusLabel, varargin)
%rts_pageGetConnStatus Summary of this function goes here
%   Detailed explanation goes here
    try
        connected = getappdata(hRtsMainGUI, 'Connected');
        if(connected)
%             vesselName = readStringFromKSPTOTConnect('GetVesselNameByGUID', vesselGUID, true);
            vesselName='';
        else
            vesselName='';
        end

        if(isempty(varargin))
            rts_updateConnStatusLbl(connected, connStatusLabel, vesselName);
        else
            statusOverride = varargin{1};
            rts_updateConnStatusLbl(statusOverride, connStatusLabel, vesselName);
        end
    catch ME
        for k=1:length(ME.stack)
            ME.stack(k)
        end
    end
end

