function [otherSCInfo] = getOtherSCInfoByID(maData, otherSCID)
%getOtherSCInfoByID Summary of this function goes here
%   Detailed explanation goes here

    otherSCInfo = [];

    if(isfield(maData.spacecraft,'otherSC'))
        otherSC = maData.spacecraft.otherSC;
        if(~isempty(otherSC))
            for(i=1:length(otherSC)) %#ok<*NO4LP>
                oSC = otherSC{i};
                if(oSC.id == otherSCID)
                    otherSCInfo = oSC;
                    otherSCInfo.parent = strtrim(otherSCInfo.parent); %cleanup from a bug 7/19/2016
                    break;
                end
            end
        end
    end
end
