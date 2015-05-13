function [rVectECI] = getInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    
    r = bodyInfo.radius + alt;
    
    x = r*cos(lat)*cos(long);
    y = r*cos(lat)*sin(long);
    z = r*sin(lat);
    
    rVectECEF = [x;y;z];
    [rVectECI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo);
end

