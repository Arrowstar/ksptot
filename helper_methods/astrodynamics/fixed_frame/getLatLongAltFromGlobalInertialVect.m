function [lat, long, alt, vVectSez, horzVel, vertVel, rVectECEF, vVectECEF, R_GI_to_BF] = getLatLongAltFromGlobalInertialVect(ut, rVectGI, bodyInfo, vVectGI)
%getLatLongAltFromGlobalInertialVect Geographic coordinates from a
%body-centered Global Inertial (GI, ecliptic J2000) vector. Tilt-aware.
%
% Converts GI->BF (tilt + spin via getFixedFrameVectFromGlobalInertialVect)
% then computes planetocentric lat/long/alt exactly as in
% getLatLongAltFromInertialVect (which expects BCI/equatorial ECI).
%
% Use this when the input vector is naturally in GI, e.g. Sun direction
% from getPositOfBodyWRTSun (ecliptic) or heliocentric cruise legs
% expressed about a tilted central body. For spacecraft state already in
% BCI (BodyCenteredInertialFrame, equatorial, standard ECI) use
% getLatLongAltFromInertialVect (spin-only, already correct).
%
% Inputs:
%   ut (1x1 double) - universal time [sec]. Vector time not supported here
%       (matches single-vector convention of getLatLongAltFromInertialVect
%       callers; loop externally for vectors).
%   rVectGI (3x1 double) - position relative to body center in GI [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body.
%   vVectGI (3x1 double, optional) - velocity in GI [km/s], or NaN for
%       position-only (matches legacy NaN sentinel).
%
% Outputs:
%   lat (1x1 double) - planetocentric latitude [rad], -pi/2..pi/2.
%   long (1x1 double) - east longitude [rad], 0..2*pi via AngleZero2Pi.
%   alt (1x1 double) - altitude above spherical radius [km].
%   vVectSez, horzVel, vertVel - as in getLatLongAltFromInertialVect, derived
%       from BF velocity via rotVectToSEZCoords_mex, or NaN if no velocity.
%   rVectECEF, vVectECEF - intermediate BF vectors [km, km/s].
%   R_GI_to_BF (3x3 double) - passive rotation GI->BF at ut.
%
% See also getLatLongAltFromInertialVect (BCI->geographic, spin-only).

arguments
    ut (1,1) double
    rVectGI (3,1) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectGI (3,1) double = [NaN;NaN;NaN]
end

[rVectECEF, vVectECEF, R_GI_to_BF] = getFixedFrameVectFromGlobalInertialVect(ut, rVectGI, bodyInfo, vVectGI);

rNorm = norm(rVectECEF);
long = AngleZero2Pi(atan2(rVectECEF(2), rVectECEF(1)));
lat = pi/2 - acos(rVectECEF(3)/rNorm);
alt = rNorm - bodyInfo.radius;

if(~any(isnan(vVectGI)))
    vVectSez = rotVectToSEZCoords_mex(rVectECEF, vVectECEF);
    horzVel = sqrt(vVectSez(1)^2 + vVectSez(2)^2);
    vertVel = vVectSez(3);
else
    vVectSez = [NaN;NaN;NaN];
    horzVel = NaN;
    vertVel = NaN;
end
end
