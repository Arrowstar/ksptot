function [rVectBCI, vVectBCI] = getBodyInertialVectFromGlobalInertialVect(rVectGI, bodyInfo, vVectGI)
%getBodyInertialVectFromGlobalInertialVect Convert body-centered vectors
%from Global Inertial (GI, Sun-Earth ecliptic J2000, ECLIPJ2000) to
%Body-Centered Inertial (BCI, equatorial, standard ECI) for a central body.
%
% This is a tilt-only (time-invariant) rotation. Both GI and BCI are
% inertial (non-rotating) frames sharing the same origin (the central
% body center for body-relative vectors), differing only by the constant
% body-axis tilt stored in bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial.
%
% For untilted bodies (e.g. Kerbin stock, bodyRotMat == eye(3)) this is
% identity and preserves backward compatibility with legacy spin-only
% fixed-frame code that assumed GI == BCI.
%
% Inputs:
%   rVectGI (3xN double) - position vectors relative to body center,
%       expressed in GI (ecliptic J2000) coordinates [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body providing
%       bodyRotMatFromGlobalInertialToBodyInertial (R_GI_to_BI, passive).
%   vVectGI (3xN double, optional) - velocity vectors in GI [km/s].
%       Omit or pass NaN(3,N) for "no velocity" (position-only conversion).
%
% Outputs:
%   rVectBCI (3xN double) - same physical vectors in BCI (equatorial) [km].
%   vVectBCI (3xN double) - same physical velocities in BCI [km/s], or NaN
%       if input velocity was NaN/missing (both inertial, no omega term).
%
% See also getGlobalInertialVectFromBodyInertialVect,
% getFixedFrameVectFromGlobalInertialVect, getFixedFrameVectFromInertialVect.

arguments
    rVectGI (3,:) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectGI (3,:) double = NaN(size(rVectGI))
end

R_GI_to_BI = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial; % 3x3 passive, GI->BCI

rVectBCI = R_GI_to_BI * rVectGI;

if(any(isnan(vVectGI), 'all'))
    vVectBCI = repmat(NaN, size(rVectGI));
else
    vVectBCI = R_GI_to_BI * vVectGI;
end
end
