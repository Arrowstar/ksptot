function [lat, long, alt] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo)
%getLatLongAltFromInertialVect Summary of this function goes here
%   Detailed explanation goes here

    [rVectECEF] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo);
    rNorm = norm(rVectECEF);
    long = AngleZero2Pi(atan2(rVectECEF(2),rVectECEF(1)));
    lat = pi/2 - acos(rVectECEF(3)/rNorm);
    alt = rNorm - bodyInfo.radius;
end

