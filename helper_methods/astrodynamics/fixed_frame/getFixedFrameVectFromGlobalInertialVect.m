function [rVectECEF, vVectECEF, R_GI_to_BF] = getFixedFrameVectFromGlobalInertialVect(ut, rVectGI, bodyInfo, vVectGI)
%getFixedFrameVectFromGlobalInertialVect Convert body-centered vectors
%from Global Inertial (GI, ecliptic J2000) to Body-Fixed (BF/ECEF, equatorial rotating).
%
% Tilt-aware (tilt + spin). Implemented as GI->BCI (constant tilt,
% bodyRotMat) then BCI->BF (spin-only via legacy MEX, GMST-like spinAngle).
% Both GI and BCI are inertial, so no omega term is introduced by the tilt
% step; omega ([0;0;2*pi/rotperiod] in BCI/BF) is applied only in the
% spin-only BCI->BF leg, exactly as in getFixedFrameVectFromInertialVect.
%
% Use this for vectors naturally expressed in GI, e.g. Sun direction from
% getPositOfBodyWRTSun (ecliptic) when computing hour angle, day/night,
% or surface-relative geometry on tilted bodies (Earth 23.44 deg). Do NOT
% use this for spacecraft state already in BCI (BodyCenteredInertialFrame);
% for those, use getFixedFrameVectFromInertialVect (spin-only, BCI->BF),
% which is already correct and preserves backward compatibility.
%
% For untilted bodies (bodyRotMat == eye(3)), GI == BCI and this reduces
% exactly to getFixedFrameVectFromInertialVect (verified in unit tests).
%
% Inputs:
%   ut (1xN double) - universal time [sec]. Scalar or vector; N = num vectors.
%   rVectGI (3xN double) - positions relative to body center in GI [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body.
%   vVectGI (3xN double, optional) - velocities in GI [km/s], or NaN(3,N)
%       for position-only (matches legacy NaN sentinel convention).
%
% Outputs:
%   rVectECEF (3xN double) - positions in BF/ECEF [km].
%   vVectECEF (3xN double) - velocities relative to rotating BF [km/s], or NaN.
%   R_GI_to_BF (3x3xN double) - passive rotation GI->BF at each ut,
%       i.e. r_BF = R_GI_to_BF * r_GI. Equals Rz(spin)' * R_GI_to_BI.
%
% See also getFixedFrameVectFromInertialVect (BCI->BF, spin-only),
% getBodyInertialVectFromGlobalInertialVect, getGlobalInertialVectFromFixedFrameVect.

arguments
    ut (1,:) double
    rVectGI (3,:) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectGI (3,:) double = NaN(size(rVectGI))
end

% Step 1: GI (ecliptic) -> BCI (equatorial), constant tilt, no omega.
[rVectBCI, vVectBCI] = getBodyInertialVectFromGlobalInertialVect(rVectGI, bodyInfo, vVectGI);

% Step 2: BCI -> BF, spin-only via legacy fast path (MEX when available).
% getFixedFrameVectFromInertialVect expects BCI ("ECI") and handles NaN velocity.
[rVectECEF, vVectECEF, R_BCI_to_BF] = getFixedFrameVectFromInertialVect(ut, rVectBCI, bodyInfo, vVectBCI);

% Full GI->BF rotation: R_GI_to_BF = R_BCI_to_BF * R_GI_to_BI.
R_GI_to_BI = bodyInfo.bodyRotMatFromGlobalInertialToBodyInertial; % 3x3
numElems = size(R_BCI_to_BF, 3);
if(numElems == 1)
    R_GI_to_BF = R_BCI_to_BF(:,:,1) * R_GI_to_BI;
else
    R_GI_to_BF = pagemtimes(R_BCI_to_BF, repmat(R_GI_to_BI, [1 1 numElems]));
end
end
