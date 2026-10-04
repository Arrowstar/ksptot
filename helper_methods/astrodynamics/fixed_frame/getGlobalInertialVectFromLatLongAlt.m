function [rVectGI, vVectGI] = getGlobalInertialVectFromLatLongAlt(ut, lat, long, alt, bodyInfo, vVectECEF)
%getGlobalInertialVectFromLatLongAlt Body-centered Global Inertial (GI,
%ecliptic J2000) vectors from planetocentric lat/long/alt. Tilt-aware.
%
% Inverse of getLatLongAltFromGlobalInertialVect. Builds BF/ECEF position
% from lat/long/alt (spherical, equatorial) via getrVectEcefFromLatLongAlt,
% then converts BF->GI (spin + tilt via getGlobalInertialVectFromFixedFrameVect).
%
% Use this to express pad/launch-site geographic coordinates in GI (e.g.
% for comparison with Sun-centered ephemerides). For spacecraft state in
% BCI (BodyCenteredInertialFrame, standard equatorial ECI) use
% getInertialVectFromLatLongAlt (BF->BCI, spin-only) instead.
%
% Inputs:
%   ut (1xN double) - universal time [sec].
%   lat, long (1xN double) - planetocentric latitude/longitude [rad].
%       long is east longitude, any 0..2*pi convention (cos/sin invariant).
%   alt (1xN double) - altitude above spherical radius [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body.
%   vVectECEF (3xN double) - velocity relative to rotating BF [km/s].
%
% Outputs:
%   rVectGI (3xN double) - positions relative to body center in GI [km].
%   vVectGI (3xN double) - velocities in GI [km/s].
%
% See also getInertialVectFromLatLongAlt (BF->BCI, spin-only).

arguments
    ut (1,:) double
    lat (1,:) double
    long (1,:) double
    alt (1,:) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectECEF (3,:) double
end

rVectECEF = getrVectEcefFromLatLongAlt(lat, long, alt, bodyInfo);

rVectGI = NaN(3, length(ut));
vVectGI = NaN(3, length(ut));
for(i=1:length(ut)) %#ok<NO4LP>
    [rVectGI(:,i), vVectGI(:,i)] = getGlobalInertialVectFromFixedFrameVect(ut(i), rVectECEF(:,i), bodyInfo, vVectECEF(:,i)); %#ok<AGROW>
end
end
