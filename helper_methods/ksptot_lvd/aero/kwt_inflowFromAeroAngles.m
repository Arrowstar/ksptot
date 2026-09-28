function vHat = kwt_inflowFromAeroAngles(aoa, sideslip)
%kwt_inflowFromAeroAngles Freestream-velocity direction in the vessel frame.
%
%   vHat = kwt_inflowFromAeroAngles(aoa, sideslip)
%
%   AOA and SIDESLIP are scalars (radians, LVD convention as produced by
%   LaunchVehicleAttitudeState.getAeroAngles / computeAeroAnglesFromBodyAxes).
%   VHAT is the 3x1 unit vector of the freestream velocity direction
%   expressed in the vessel body frame (X = nose/long axis, the LVD bodyX
%   convention), at zero bank angle:
%
%       vHat = [cos(aoa)*cos(ss); -sin(ss); sin(aoa)*cos(ss)]
%
%   This is the exact inverse of computeBodyAxesFromAeroAngles at bank = 0
%   (RBody2Wind = eul2rotm([ss, aoa, 0], 'zyx'); vHat is the wind x-axis in
%   body coordinates, i.e. the first row of RBody2Wind). The sweep builds
%   inflow vectors with this helper, so the stored (Mach, AoA, sideslip)
%   table axes line up with the runtime lookup in KosDragCoeffientModel /
%   UserTabulatedLiftModel, which resolve the same angles live via
%   getAeroAngles. See KwtAeroTest.roundTripThroughLvdAeroAngles.
%
%   KSP/KWT note: KWT sweeps pitch from a nose-forward +Z reference, so
%   for +Y-nosed rockets its AoA=0 is broadside, not nose-on. KWT
%   comparisons therefore map each export row through the vessel->aero
%   frame rotation (see KwtAeroTest.kwtSliceAgreement) rather than
%   matching numerical AoA. Tables generated here are self-consistent
%   with LVD end to end in any case.
%
%   AOA/SIDESLIP may also be arrays of the same size, in which case VHAT
%   is 3xN with one column per element.
%
%   See also: kwt_aero, kwt_sweepCraft, computeBodyAxesFromAeroAngles.

    cA = cos(aoa);
    sA = sin(aoa);
    cS = cos(sideslip);
    sS = sin(sideslip);

    vHat = [cA .* cS; -sS; sA .* cS];

    n = sqrt(sum(vHat .^ 2, 1));
    n(n == 0) = 1;
    vHat = vHat ./ n;
end
