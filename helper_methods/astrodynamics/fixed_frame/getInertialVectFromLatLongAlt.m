function [rVectECI, vVectECI] = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, vVectECEF)
%getInertialVectFromLatLongAlt Summary of this function goes here
%   Detailed explanation goes here
    
    rVectECEF = getrVectEcefFromLatLongAlt(lat, long, alt, bodyInfo);

    for(i=1:length(ut)) %#ok<*NO4LP>
        [rVectECI(:,i), vVectECI(:,i)] = getInertialVectFromFixedFrameVect(ut(i), rVectECEF(:,i), bodyInfo, vVectECEF(:,i)); %#ok<AGROW>
    end
end

