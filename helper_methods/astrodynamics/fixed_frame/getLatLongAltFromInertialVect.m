function [lat, long, alt, vectSez, horzVel, vertVel] = getLatLongAltFromInertialVect(ut, rVectECI, bodyInfo, varargin)
%getLatLongAltFromInertialVect Summary of this function goes here
%   Detailed explanation goes here

    if(~isempty(varargin))
        vVectECI = varargin{1};
    else
        vVectECI = [NaN;NaN;NaN];
    end

    [rVectECEF, vVectECEF] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo, vVectECI);
    
    rNorm = norm(rVectECEF);
    long = AngleZero2Pi(atan2(rVectECEF(2),rVectECEF(1)));
    lat = pi/2 - acos(rVectECEF(3)/rNorm);
    alt = rNorm - bodyInfo.radius;
    
    if(~any(isnan(vVectECI)))
        vectSez = rotVectToSEZCoords(rVectECEF, vVectECEF);
        horzVel = sqrt(vectSez(1)^2 + vectSez(2)^2);
        vertVel = vectSez(3);
    else
        vectSez = [NaN;NaN;NaN];
        horzVel = NaN;
        vertVel = NaN;
    end
end

function vectSez = rotVectToSEZCoords(rVector, vector)

    kHat = [0;0;1];
    zHat = normVector(rVector);
    eHat = normVector(cross(kHat, zHat));
    sHat = normVector(cross(eHat, zHat));
    
    rotMat = [sHat'; eHat'; zHat'];
    
    vectSez = rotMat * vector;
end