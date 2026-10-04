function [rVectGI, vVectGI] = getGlobalInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF)
%getGlobalInertialVectFromFixedFrameVect Convert body-centered vectors
%from Body-Fixed (BF/ECEF, equatorial rotating) to Global Inertial
%(GI, ecliptic J2000).
%
% Tilt-aware inverse of getFixedFrameVectFromGlobalInertialVect.
% Implemented as BF->BCI (spin-only with omega, legacy) then BCI->GI
% (constant tilt, no omega). Both BCI and GI are inertial, so tilt step
% carries velocity by the same rotation with no extra omega term.
%
% Use this to express pad/launch-site BF vectors in GI (e.g. for
% cross-checks against Sun-centered ephemerides). For spacecraft state in
% BCI (BodyCenteredInertialFrame, standard ECI), use
% getInertialVectFromFixedFrameVect (BF->BCI, spin-only) instead.
%
% For untilted bodies this reduces exactly to
% getInertialVectFromFixedFrameVect followed by identity tilt.
%
% Inputs:
%   ut (1xN double) - universal time [sec].
%   rVectECEF (3xN double) - positions in BF/ECEF [km].
%   bodyInfo (1x1 KSPTOT_BodyInfo) - central body.
%   vVectECEF (3xN double) - velocities relative to rotating BF [km/s].
%
% Outputs:
%   rVectGI (3xN double) - positions relative to body center in GI [km].
%   vVectGI (3xN double) - velocities in GI [km/s].
%
% See also getFixedFrameVectFromGlobalInertialVect,
% getInertialVectFromFixedFrameVect, getGlobalInertialVectFromBodyInertialVect.

arguments
    ut (1,:) double
    rVectECEF (3,:) double
    bodyInfo (1,1) KSPTOT_BodyInfo
    vVectECEF (3,:) double
end

% Step 1: BF -> BCI, spin-only with omega (legacy, correct for equatorial).
[rVectBCI, vVectBCI] = getInertialVectFromFixedFrameVect(ut, rVectECEF, bodyInfo, vVectECEF);

% Step 2: BCI -> GI, constant tilt, no omega (both inertial).
[rVectGI, vVectGI] = getGlobalInertialVectFromBodyInertialVect(rVectBCI, bodyInfo, vVectBCI);
end
