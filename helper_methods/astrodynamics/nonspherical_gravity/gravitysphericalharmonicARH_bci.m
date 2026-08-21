function gInertial = gravitysphericalharmonicARH_bci(elemSet, gravBodyInfo)
%GRAVITYSPHERICALHARMONIC_ARH_BCI Spherical harmonic gravity, BCI-frame fast path.
%   gInertial = GRAVITYSPHERICALHARMONIC_ARH_BCI(elemSet, gravBodyInfo)
%
%   Identical computation to gravitysphericalharmonicARH, minus the frame
%   equality test.  PRECONDITION: elemSet must already be expressed in
%   gravBodyInfo's body-centered inertial frame.  The only caller,
%   GravityForceModel.getForce, constructs elemSet from
%   bodyInfo.getBodyCenteredInertialFrame() and therefore always satisfies
%   this precondition; using this variant skips a per-evaluation deep frame
%   comparison (measured ~18 us/call on R2026b prerelease).
%
%   See gravitysphericalharmonicARH for the full documentation and the
%   general-case implementation.

    arguments
        elemSet AbstractElementSet
        gravBodyInfo(1,1) KSPTOT_BodyInfo
    end

    %Time
    ut = elemSet.time;

    bci = getBodyCenteredInertialFrame(gravBodyInfo);

    %Get position in cartesian elements in body fixed frame
    posOff = getPositOfBodyWRTSun(ut, gravBodyInfo, gravBodyInfo.celBodyData);
    R_bci_to_GI = gravBodyInfo.bodyRotMatFromGlobalInertialToBodyInertial';
    spinAngle = getBodySpinAngle(gravBodyInfo, ut);
    R_bff_to_GI = getBodyFixedToGlobalInertialFrame_mex(ut, spinAngle(:)', gravBodyInfo.bodyRotMatFromGlobalInertialToBodyInertial);
    cartElemSet = convertToCartesianElementSet(elemSet);
    rVect2 = posOff + (R_bci_to_GI * cartElemSet.rVect);
    p = (R_bff_to_GI' * (rVect2 - posOff))';

    %Get body data
    Re = gravBodyInfo.radius;
    GM = gravBodyInfo.gm;
    C = gravBodyInfo.nonSphericalGravC;
    S = gravBodyInfo.nonSphericalGravS;
    maxdeg = gravBodyInfo.nonsphericalgravmaxdeg;

    [gx, gy, gz] = computeBodyFixedGravAccel_mex(p, Re, maxdeg, C, S, GM);

    gBodyFixed = [gx(:)'; gy(:)'; gz(:)'];

    R_ecef_to_bci = R_bci_to_GI' * R_bff_to_GI;

    gInertial = R_ecef_to_bci * gBodyFixed;
end
