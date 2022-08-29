function gInertial = gravitysphericalharmonicARH(elemSet, gravBodyInfo)
%  GRAVITYSPHERICALHARMONIC Implement a spherical harmonic representation
%   of planetary gravity.
%   [GX, GY, GZ] = GRAVITYSPHERICALHARMONIC( P ) implements the mathematical
%   representation of spherical harmonic planetary gravity based on
%   planetary gravitational potential. Using P, a M-by-3 array of
%   Planet-Centered Planet-Fixed coordinates, GX, GY and GZ, arrays of M
%   gravity values in the x-axis, y-axis and z-axis of the Planet-Centered
%   Planet-Fixed coordinates are calculated for planet using 120th degree
%   and order spherical coefficients for EGM2008 by default.
%
%   Inputs for spherical harmonic gravity are:
%   P        :a M-by-3 array of Planet-Centered Planet-Fixed coordinates in
%            meters where the z-axis is positive towards the North Pole. For
%            Earth this would be ECEF coordinates.
%
%   Output calculated for the spherical harmonic gravity includes:
%   gInertial - gravitational acceleration in the body centered inertial
%   frame
%
%   Limitations:
%
%   This function has the limitations of excluding the centrifugal effects
%   of planetary rotation, and the effects of a precessing reference frame.
%
%   Spherical harmonic gravity model is valid for radial positions greater
%   than the planet equatorial radius.  Using it near or at the planetary
%   surface can probably be done with negligible error.  The spherical
%   harmonic gravity model is not valid for radial positions less than
%   planetary surface.
    arguments
        elemSet AbstractElementSet
        gravBodyInfo(1,1) KSPTOT_BodyInfo
    end
    
    %Time 
    ut = elemSet.time;
    
    %Get position in cartesian elements in body fixed frame
    bci = gravBodyInfo.getBodyCenteredInertialFrame();
    bff = gravBodyInfo.getBodyFixedFrame();
    ceBF = elemSet.convertToCartesianElementSet().convertToFrame(bff, true);
    p = ceBF.rVect';
    
    %Get body data
    Re = gravBodyInfo.radius;
    GM = gravBodyInfo.gm;
    C = gravBodyInfo.nonSphericalGravC;
    S = gravBodyInfo.nonSphericalGravS;
    maxdeg = gravBodyInfo.nonsphericalgravmaxdeg;  %gravBodyInfo.nonsphericalgravmaxdeg
    
%     [gx, gy, gz] = computeBodyFixedGravAccel(p, Re, maxdeg, C, S, GM);
    [gx, gy, gz] = computeBodyFixedGravAccel_mex(p, Re, maxdeg, C, S, GM);

    gBodyFixed = [gx(:)'; gy(:)'; gz(:)'];
    
    R_ecef_to_global_inertial = bff.getRotMatToInertialAtTime(ut,[],[]);
    R_bci_to_global_inertial = bci.getRotMatToInertialAtTime(ut,[],[]);
    R_ecef_to_bci = R_bci_to_global_inertial' * R_ecef_to_global_inertial;
    
    gInertial = R_ecef_to_bci * gBodyFixed;
end

% %assumes that the rotating frame and inertial fram have the same origin
% function aInertial = rotateAccelVectToInertialFrame(aRot, vehElemSet, bodyFixedFrame)
%     arguments
%         aRot(3,1) double %acceleration vector, rotating frame
%         vehElemSet(1,1) AbstractElementSet
%         bodyFixedFrame(1,1) BodyFixedFrame
%     end
% 
%     time = vehElemSet.time;
%     vehElemSet = vehElemSet.convertToCartesianElementSet();
%     rVectBodyFixed = vehElemSet.rVect;
%     vVectBodyFixed = vehElemSet.vVect;
% 
%     angVelWrtOrigin = bodyFixedFrame.getAngVelWrtOriginAndRotMatToInertial(time, vehElemSet, []);
% 
%     %does not handle any angular acceleration and there's no origin
%     %acceleration to deal with because the origin is the same in both
%     %frames.  Those two terms are thus zeros.
%     %See Vallado section 3.4.3, page 174 for this equation
%     zeroVect = zeros(size(aRot));
%     aInertial = aRot + zeroVect + crossARH(angVelWrtOrigin, crossARH(angVelWrtOrigin, rVectBodyFixed)) + 2*crossARH(angVelWrtOrigin, vVectBodyFixed) + zeroVect;
% end