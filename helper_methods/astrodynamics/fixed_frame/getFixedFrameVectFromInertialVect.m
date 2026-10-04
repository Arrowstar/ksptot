function [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect(ut, rVectECI, bodyInfo, varargin)
%getFixedFrameVectFromInertialVect Convert body-centered Body-Centered
%Inertial (BCI, equatorial, standard ECI) vectors to Body-Fixed (BF/ECEF).
% Spin-only (GMST-like spinAngle from rotperiod/rotini). No tilt term
% because BCI and BF share the equatorial plane -- tilt cancels.
%
% IMPORTANT: "Inertial" here means BCI (BodyCenteredInertialFrame,
% equatorial), NOT Global Inertial (GI, ecliptic J2000). For untilted
% bodies (Kerbin stock, bodyRotMat==eye(3)) GI==BCI and the distinction is
% moot. For tilted bodies (Earth 23.44 deg in bodiesSolarSystem.ini) GI and
% BCI differ by the constant body-axis tilt. Passing a GI vector (e.g. Sun
% direction from getPositOfBodyWRTSun, which is ecliptic) directly here
% ignores tilt by up to 23.4 deg. Use
% getFixedFrameVectFromGlobalInertialVect (GI->BF, tilt + spin) for those.
%
% Spacecraft state in LVD/MA (LaunchVehicleStateLogEntry, BCI) is already
% BCI, so this spin-only path is correct for propagation, aero, ground
% tracks, and pad lat/long -- do not add tilt here or KSC would shift.
%
    inputs = bodyInfo.getFixedFrameFromInertialFrameInputsCache();

    %The _alg MEX takes vVectECI as a required positional argument, but callers
    %that only want the position/rotation outputs legitimately omit it.  NaN is
    %the established "no velocity" sentinel (see the reference implementation
    %below and computeHourAngle.m); supply it here so a 3-argument call does
    %not reach the MEX one argument short.
    if(isempty(varargin))
        varargin = {NaN(size(rVectECI))};
    end

%     [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect_alg(ut, rVectECI, inputs{:}, varargin{:});
    [rVectECEF, vVectECEF, REci2Ecef] = getFixedFrameVectFromInertialVect_alg_mex(ut, rVectECI, inputs{:}, varargin{:});
end

% %getFixedFrameVectFromInertialVect Summary of this function goes here
% %   Detailed explanation goes here
% 
%     if(~isempty(varargin))
%         vVectECI = varargin{1};
%     else
%         vVectECI = [NaN;NaN;NaN];
%     end
% 
%     numElems = length(ut);
%     
%     spinAngle = getBodySpinAngle(bodyInfo, ut);
%     
%     cSA = reshape(cos(spinAngle),1,1,numElems);
%     sSA = reshape(sin(spinAngle),1,1,numElems);
%     zero = zeros(1,1,numElems);
%     one = zero + 1;
%     
% %     R = [cos(spinAngle) -sin(spinAngle) 0;
% %          sin(spinAngle) cos(spinAngle) 0;
% %          0 0 1];
% 
%     R = [cSA, -sSA, zero;
%          sSA, cSA, zero;
%          zero, zero, one];
%      
% %     rVectECI = reshape(rVectECI,3,1);
%     rVectECI = reshape(rVectECI,3,1,numElems);
%     
%     REci2Ecef = permute(R,[2,1,3]); %ND transpose
% %     rVectECEF = REci2Ecef * rVectECI;
%     rVectECEF = mtimesx(REci2Ecef, rVectECI);
%     rVectECEF = reshape(rVectECEF,3,numElems);
%         
%     if(~any(isnan(vVectECI)))
%         rotRateRadSec = 2*pi/bodyInfo.rotperiod;
%         omegaRI = repmat([0;0;rotRateRadSec],1,1,numElems);
%         vVectECI = reshape(vVectECI,3,1,numElems);
%         
% %         vVectECEF = REci2Ecef*(vVectECI - cross(omegaRI, rVectECI));
%         vVectECEF = mtimesx(REci2Ecef, (vVectECI - cross(omegaRI, rVectECI)));
%         vVectECEF = reshape(vVectECEF,3,numElems);
%     else
%         vVectECEF = repmat([NaN;NaN;NaN],1,numElems);
%     end
