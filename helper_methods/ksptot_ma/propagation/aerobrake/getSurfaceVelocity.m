function [surfVel] = getSurfaceVelocity(bodyInfo, ut, rVectECI, vVectECI)
%getSurfaceVelocity Summary of this function goes here
%   Detailed explanation goes here
    [lat, ~, ~] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo);
    bodyCircum = 2*pi*bodyInfo.radius;
    equatSpeed = bodyCircum / bodyInfo.rotperiod; %km/s
    
    speedAtLat = equatSpeed * cos(lat);
    bodySurfVelECI = -normVector(cross(rVectECI, [0;0;1])) * speedAtLat;
    surfVel = vVectECI - bodySurfVelECI;
end

