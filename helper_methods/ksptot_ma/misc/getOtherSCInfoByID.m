function [otherSCInfo] = getOtherSCInfoByID(maData, otherSCID)
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

    otherSCInfo = [];

    if(isfield(maData.spacecraft,'otherSC'))
        otherSC = maData.spacecraft.otherSC;
        if(~isempty(otherSC))
            for(i=1:length(otherSC))
                oSC = otherSC{i};
                if(oSC.id == otherSCID)
                    otherSCInfo = oSC;
                    break;
                end
            end
        end
    end
end

