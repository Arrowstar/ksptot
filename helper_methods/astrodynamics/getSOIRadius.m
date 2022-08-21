function [rSOI] = getSOIRadius(bodyInfo, parentBodyInfo)
%getSOIRadius Summary of this function goes here
%   Detailed explanation goes here
    if(~isempty(parentBodyInfo))
        rSOI = bodyInfo.sma * (bodyInfo.gm/parentBodyInfo.gm)^(2/5);
    else
        rSOI = realmax;
    end
end

