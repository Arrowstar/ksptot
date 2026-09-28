function [areaDrag, liftForce] = ksp_setDrag(cube, dirLocal, Mach, phys, opts)
%ksp_setDrag Port of KSP DragCubeList.SetDrag for one drag cube.
%
%   [areaDrag, liftForce] = ksp_setDrag(cube, dirLocal, Mach, phys)
%   [areaDrag, liftForce] = ksp_setDrag(cube, dirLocal, Mach, phys, opts)
%
%   CUBE is a struct with .faces (6x3 [area_m2, baseDragCd, depth_m] in
%   face order +X,-X,+Y,-Y,+Z,-Z, matching KSP's faceDirections),
%   as produced by lvd_import_cubeDB.
%   DIRLOCAL is the 3x1 unit FREESTREAM-VELOCITY direction in the part
%   frame (motion of the craft through the air, NOT the airflow -- KSP's
%   DragCubeList.SetDrag negates its argument internally before the
%   per-face loop, so the loop works in velocity convention). MACH is the
%   scalar Mach number (>= 0). PHYS is a kwt_physicsGlobals struct.
%
%   OPTS (optional struct): .occlusion (6x1 area multipliers in face
%   order, default ones(6,1); node-occlusion pairs scale the occluded
%   face's windward area), .applyCdCutoff (default false; when true,
%   applies Ren0k's kOS initial-Cd cutoff rawCd<=0->0, rawCd>=1->1
%   instead of the stock clamp to the DRAG_CD edge value 0.0025).
%
%   AREADRAG is the raw face-summed area-drag in m^2:
%       sum_faces A * CdCorr^CdPower(M) * MachMult(facing,M) * weight
%   with CdCorr = DRAG_CD(baseDrag), facing = (dot+1)/2 selecting the
%   TIP (downstream, dot>0) vs TAIL (upstream, dot<0) Mach branch blended
%   with SURFACE at dot = 0 (PhysicsGlobals.DragCurveValue, decoded from
%   IL), axial weight |dot|, side weight sqrt(1-dot^2). A face at an
%   oblique angle contributes to BOTH its axial and its surface terms.
%
%   AREADRAG excludes the overall DRAG_MULTIPLIER(Mach) curve, the
%   pseudo-Reynolds multiplier, and the global DragCubeMultiplier /
%   DragMultiplier -- kwt_aero applies those outside, so the swept
%   dragCubeCdA column keeps KosDragCoeffientModel semantics
%   (CdA = dragCubeCdA * reynoldsCorrection + otherDragCdA).
%
%   LIFTFORCE is the 3x1 blunt-body lift vector in the part frame with the
%   drag-aligned component removed (same units as areaDrag). KSP-exact
%   construction, decoded from DragCubeList.AddSurfaceDragDirection
%   (KSP 1.12.5 Assembly-CSharp): ONLY leeward faces (dot > 0) contribute,
%   pushing along the INWARD normal:
%       liftForce += sum_{dot>0} -n * dot * occludedArea * weightedDrag
%                                   * BodyLiftCurve.liftCurve(dot)
%   with the raw blended base Cd (NO Mach power, NO tip/tail multiplier --
%   those shape drag only), the AoA curve evaluated at the raw dot, and
%   NaN evaluations skipped. kwt_aero rotates it to the vessel frame and
%   scales by bodyLiftMultiplier * BodyLiftMultiplier *
%   bodyLiftMach(Mach) * Q. It is exactly zero for axis-aligned flow on a
%   face-symmetric cube and continuous through edge-on (dot = 0) flow.
%
%   References: KSPCommunityFixes PR #139 (DragCubeGeneration, a port of
%   DragCubeSystem.CalculateAerodynamics), Ren0k Project-Atmospheric-Drag
%   Profile.ks, MechJeb2 FlyingSim/SimulatedPart.cs, KSPDocs DragCubeList.
%
%   See also: lvd_import_cubeDB, kwt_physicsGlobals, ksp_evalFloatCurve,
%   kwt_aero.

    if(nargin < 5)
        opts = struct();
    end
    occlusion = ones(6, 1);
    if(isfield(opts, 'occlusion') && ~isempty(opts.occlusion))
        occlusion = double(opts.occlusion(:));
    end
    applyCdCutoff = false;
    if(isfield(opts, 'applyCdCutoff') && ~isempty(opts.applyCdCutoff))
        applyCdCutoff = logical(opts.applyCdCutoff);
    end

    dirLocal = double(dirLocal(:));
    nrm = norm(dirLocal);
    if(~isfinite(nrm) || nrm <= 0)
        error('ksp_setDrag:badDirection', 'dirLocal must be a nonzero 3-vector.');
    end
    dirLocal = dirLocal / nrm;
    Mach = max(double(Mach), 0);

    if(isempty(cube) || ~isfield(cube, 'faces'))
        error('ksp_setDrag:badCube', 'cube must have a 6x3 .faces matrix.');
    end
    faces = double(cube.faces);
    if(size(faces, 1) ~= 6 || size(faces, 2) < 2)
        error('ksp_setDrag:badCube', 'cube.faces must be 6x3 [area, baseDrag, depth].');
    end
    if(numel(occlusion) ~= 6)
        error('ksp_setDrag:badOcclusion', 'opts.occlusion must have 6 elements.');
    end

    % Face outward normals in part frame: +X,-X,+Y,-Y,+Z,-Z.
    N = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1];

    tipM = ksp_evalFloatCurve(phys.tipCurve, Mach);
    surfM = ksp_evalFloatCurve(phys.surfaceCurve, Mach);
    tailM = ksp_evalFloatCurve(phys.tailCurve, Mach);
    cdPow = ksp_evalFloatCurve(phys.cdPowerCurve, Mach);

    areaDrag = 0;
    liftRaw = [0; 0; 0];
    for(i = 1:6)
        n = N(i, :)';
        A = faces(i, 1) * occlusion(i);
        if(A <= 0)
            continue;
        end
        cd0 = faces(i, 2);
        cdC = correctedCd(phys.cdCurve, cd0, applyCdCutoff);
        cdP = cdC ^ cdPow;

        dn = dirLocal' * n;   % >0 downstream (leeward, TIP branch),
                              % <0 upstream (windward, TAIL branch)
        wAx = abs(dn);
        wSide = sqrt(max(0, 1 - dn * dn));
        if(dn <= 0)
            mAx = tailM;
        else
            mAx = tipM;
        end
        axial = A * cdP * mAx * wAx;
        surf = A * cdP * surfM * wSide;
        areaDrag = areaDrag + axial + surf;

        % KSP-exact blunt-body lift: leeward faces only (dn > 0), inward
        % normal, raw base Cd, AoA curve at the raw dot. (The windward
        % push + leeward suction pair model used previously is NOT what
        % KSP computes; verified against KWT bodyLift_Coef, 2026-09-26.)
        if(dn > 0)
            cl = ksp_evalFloatCurve(phys.bodyLiftCurve, dn);
            if(isfinite(cl) && cl ~= 0)
                liftRaw = liftRaw - n * (dn * A * cd0 * cl);
            end
        end
    end

    % Remove the drag-aligned part; what remains is blunt-body lift.
    liftForce = liftRaw - (liftRaw' * dirLocal) * dirLocal;
end

function cdC = correctedCd(cdCurve, cd0, applyCutoff)
    if(applyCutoff)
        if(cd0 <= 0)
            cdC = 0;
            return;
        elseif(cd0 >= 1)
            cdC = 1;
            return;
        end
    end
    cdC = ksp_evalFloatCurve(cdCurve, cd0);
end
