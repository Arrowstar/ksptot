function [lat, long, alt, vVectSez, horzVel, vertVel, rVectECEF, vVectECEF, REci2Ecef] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, varargin)
%getLatLongAltFromInertialVect Summary of this function goes here
%   Detailed explanation goes here

    if(~isempty(varargin))
        vVectECI = varargin{1};
    else
        vVectECI = [NaN;NaN;NaN];
    end

    [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
    
    rNorm = norm(rVectECEF);
    long = AngleZero2Pi(atan2(rVectECEF(2),rVectECEF(1)));
    lat = pi/2 - acos(rVectECEF(3)/rNorm);
    alt = rNorm - bodyInfo.radius;
    
    if(~any(isnan(vVectECI)))
        vVectSez = rotVectToSEZCoords(rVectECEF, vVectECEF);
        horzVel = sqrt(vVectSez(1)^2 + vVectSez(2)^2);
        vertVel = vVectSez(3);
    else
        vVectSez = [NaN;NaN;NaN];
        horzVel = NaN;
        vertVel = NaN;
    end
end

