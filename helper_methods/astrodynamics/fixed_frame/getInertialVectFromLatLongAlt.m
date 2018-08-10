function [rVectECI, vVectECI] = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, vVectECEF)
%getInertialVectFromLatLongAlt Summary of this function goes here
%   Detailed explanation goes here
    
    r = bodyInfo.radius + alt;
    
    x = r.*cos(lat).*cos(long);
    y = r.*cos(lat).*sin(long);
    z = r.*sin(lat);
    
    rVectECEF = [x;y;z];
    for(i=1:length(ut)) %#ok<*NO4LP>
        [rVectECI(:,i), vVectECI(:,i)] = getInertialVectFromFixedFrameVect(ut(i), rVectECEF(:,i), bodyInfo, vVectECEF(:,i)); %#ok<AGROW>
    end
end

