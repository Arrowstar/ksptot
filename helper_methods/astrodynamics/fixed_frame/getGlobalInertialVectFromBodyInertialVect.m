function [rVectGI, vVectGI] = getGlobalInertialVectFromBodyInertialVect(rVectBCI, bodyInfo, vVectBCI)
%getGlobalInertialVectFromBodyInertialVect Convert body-centered vectors
%from Body-Centered Inertial (BCI, equatorial, standard ECI) to
%Global Inertial (GI, Sun-Earth ecliptic J2000, ECLIPJ2000).
%
% Inverse of getBodyInertialVectFromGlobalInertialVect. Tilt-only,
% time-invariant. Both frames inertial, same origin, so velocity
% transforms by the same constant rotation with no omega term.
%
% For untilted bodies (bodyRotMat == eye(3)) this is identity.
%
% Inputs:
%   rVectBCI (3xN double) - positions relative to body center in BCI [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body.
%   vVectBCI (3xN double, optional) - velocities in BCI [km/s], or NaN.
%
% Outputs:
%   rVectGI (3xN double) - same vectors in GI [km].
%   vVectGI (3xN double) - same velocities in GI [km/s], or NaN.
%
% See also getBodyInertialVectFromGlobalInertialVect.

arguments
    rVectBCI (3,:) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectBCI (3,:) double = NaN(size(rVectBCI))
end

R_BCI_to_GI = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial'; % 3x3 active, BCI->GI

rVectGI = R_BCI_to_GI * rVectBCI;

if(any(isnan(vVectBCI), 'all'))
    vVectGI = repmat(NaN, size(rVectBCI));
else
    vVectGI = R_BCI_to_GI * vVectBCI;
end
end
