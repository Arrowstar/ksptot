function [stationInfo] = getStationInfoByID(maData, stationID)
%getOtherSCInfoByID Summary of this function goes here
%   Detailed explanation goes here

    stationInfo = [];

    if(isfield(maData.spacecraft,'otherSC'))
        stations = maData.spacecraft.stations;
        if(~isempty(stations))
            for(i=1:length(stations)) %#ok<*NO4LP>
                stn = stations{i};
                if(stn.id == stationID)
                    stationInfo = stn;
                    break;
                end
            end
        end
    end
end
