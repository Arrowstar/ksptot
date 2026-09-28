function out = kwt_aero(spec, phys, inflowHat, Mach, Q_kPa, rhoV, pitchInput)
%kwt_aero Vessel-level KSP aero replay (KWT direct path, no KSP in the loop).
%
%   out = kwt_aero(spec, phys, inflowHat, Mach, Q_kPa)
%   out = kwt_aero(spec, phys, inflowHat, Mach, Q_kPa, rhoV, pitchInput)
%
%   SPEC is a kwt_buildAeroSpec struct (parts with R_part2vessel quats,
%   cubes, wing/control-surface params). PHYS is kwt_physicsGlobals.
%   INFLOWHAT is 3xN unit freestream-velocity directions in the vessel
%   aero frame (build columns with kwt_inflowFromAeroAngles). MACH is a
%   scalar Mach number. Q_KPA is the scalar dynamic pressure in kPa
%   (= kN/m^2, so F_kN = Q_kPa * coeff). RHOV is rho*V in kg/m^2/s for
%   the pseudo-Reynolds drag multiplier (default 1, i.e. mult = 1).
%   PITCHINPUT in [-1,1] (default 0) rotates control-surface lift vectors
%   about their rotation axes (baked-deflection tables: regen per trim).
%
%   Mirrors PartCollection.GetLiftForce/GetAeroForce + SimulatedPart /
%   SimulatedLiftingSurface.GetLift (methodology sections 3-4):
%     body parts : dirLocal = -(R' * vHat); [areaRaw, liftRaw] =
%                  ksp_setDrag(cube, dirLocal, Mach); F = R*(liftRaw *
%                  bodyLiftMultiplier); project perpendicular to inflow;
%                  scale by BodyLiftMultiplier * bodyLiftMach(Mach).
%                  Pseudo-Reynolds applies to drag ONLY, never lift.
%     wings      : d = vHat' * liftVec; a = |d| (omnidirectional) or
%                  clamp01(d); F = -liftVec*sign(d)*liftCurve(a)*
%                  liftMach(Mach)*deflectionLiftCoeff*LiftMultiplier*1000
%                  (projected perpendicular to inflow when
%                  perpendicularOnly). Parasitic + induced drag go to
%                  otherDragCdA (Ren0k Profile.ks decomposition: *15 and
%                  *36 scalings = 1000*liftDragMultiplier/liftMultiplier).
%
%   OUT fields (1xN unless noted): .ClS (signed lift coeff x area, m^2;
%   sign from projection onto the +Z-perpendicular lift direction),
%   .dragCubeCdA, .otherDragCdA (m^2; dragCube excludes Reynolds, matching
%   KosDragCoeffientModel semantics), .liftForce_kN (3xN),
%   .dragForce_kN (3xN), .reynoldsMult, .overallMult, .machClBody,
%   .machClWing scalars.
%
%   KSP-fidelity notes (v1): no x1000 on the body-lift path (follows KWT /
%   MechJeb, not Ren0k's x36 body scaling); control-surface CoM-sign flip
%   deferred (sign documented in kwt_buildAeroSpec); node-occlusion via
%   spec occlusion maps only.
%
%   See also: kwt_buildAeroSpec, ksp_setDrag, kwt_inflowFromAeroAngles,
%   kwt_sweepCraft.

    if(nargin < 6 || isempty(rhoV))
        rhoV = 1;
    end
    if(nargin < 7 || isempty(pitchInput))
        pitchInput = 0;
    end
    pitchInput = max(-1, min(1, double(pitchInput)));

    inflowHat = double(inflowHat);
    if(size(inflowHat, 1) ~= 3)
        error('kwt_aero:badInflow', 'inflowHat must be 3xN.');
    end
    N = size(inflowHat, 2);
    nv = sqrt(sum(inflowHat .^ 2, 1));
    if(any(~isfinite(nv)) || any(nv <= 0))
        error('kwt_aero:badInflow', 'inflowHat columns must be nonzero.');
    end
    inflowHat = inflowHat ./ nv;

    Mach = max(double(Mach), 0);
    Q_kPa = double(Q_kPa);

    overallMult = ksp_evalFloatCurve(phys.overallCurve, Mach);
    reynoldsMult = ksp_evalFloatCurve(phys.pseudoReynoldsCurve, double(rhoV));
    machClBody = ksp_evalFloatCurve(phys.bodyLiftMachCurve, Mach);
    machClWing = ksp_evalFloatCurve(phys.wingLiftMachCurve, Mach);
    cubeScale = overallMult * phys.dragCubeMultiplier * phys.dragMultiplier;

    ClS = zeros(1, N);
    dragCubeCdA = zeros(1, N);
    otherDragCdA = zeros(1, N);
    liftRaw = zeros(3, N);

    zRef = [0; 0; 1];

    for(col = 1:N)
        v = inflowHat(:, col);
        liftTot = [0; 0; 0];
        cubeTot = 0;
        otherTot = 0;

        for(p = 1:numel(spec.parts))
            part = spec.parts(p);
            if(part.isShielded)
                continue;
            end
            R = part.R_part2vessel;

            if(~part.hasLiftModule)
                % ---- body-lift path (drag cubes) ----
                if(isempty(part.cube) || ~isfield(part.cube, 'faces'))
                    continue;
                end
                % dirLocal is the VELOCITY direction in part frame (NOT
                % airflow): KSP's DragCubeList.SetDrag negates its argument
                % internally, so its `direction` (and our dirLocal) is
                % velocity-aligned. Leeward = downstream = dn > 0, which
                % takes the TIP Mach branch; windward takes TAIL.
                % (An earlier airflow-convention version mirrored all
                % transverse lift; caught by the KWT vessel comparison.)
                dirLocal = R' * v;
                setDragOpts = struct('occlusion', part.occlusion, ...
                    'applyCdCutoff', false);
                [areaRaw, liftRawPart] = ksp_setDrag(part.cube, dirLocal, Mach, phys, setDragOpts);
                cubeTot = cubeTot + areaRaw;

                F = R * (liftRawPart * part.bodyLiftMultiplier);
                F = F - (F' * v) * v;   % project perpendicular to inflow
                F = F * (phys.bodyLiftMultiplier * machClBody);
                liftTot = liftTot + F;
                % NOTE: no body-lift-induced drag term: KSP/KWT has none
                % (body drag lives entirely in the cube grid; induced drag
                % exists only for lifting surfaces). An earlier Ren0k-style
                % AoI term was removed for KSP fidelity, 2026-09-26.
            else
                % ---- lifting-surface path (curve set per part:
                % Default wings, CapsuleBottom auto-added capsules) ----
                [lcCurve, lmcCurve, dcCurve, dmcCurve] = liftCurveSet( ...
                    phys, part);
                lVec = rotateForControl(part, pitchInput);
                lV = R * lVec;
                d = v' * lV;
                if(part.omnidirectional)
                    a = abs(d);
                else
                    a = min(max(d, 0), 1);
                end
                sgn = sign(d);
                if(sgn == 0 || a == 0 || part.deflectionLiftCoeff == 0)
                    Cl = 0;
                else
                    Cl = ksp_evalFloatCurve(lcCurve, a);
                end
                machClPart = ksp_evalFloatCurve(lmcCurve, Mach);
                W = -lV * sgn * Cl * machClPart * part.deflectionLiftCoeff ...
                    * phys.liftMultiplier * 1000;
                if(part.perpendicularOnly)
                    W = W - (W' * v) * v;
                end
                liftTot = liftTot + W;

                Cd = ksp_evalFloatCurve(dcCurve, a);
                machCdPart = ksp_evalFloatCurve(dmcCurve, Mach);
                useDrag = ~isfield(part, 'useInternalDragModel') || part.useInternalDragModel;
                if(useDrag)
                    parasit = Cd * machCdPart * part.deflectionLiftCoeff ...
                        * phys.liftDragMultiplier * 1000;
                else
                    parasit = 0;
                end
                if(~part.perpendicularOnly)
                    induced = abs(Cl * machClPart * part.deflectionLiftCoeff ...
                        * phys.liftMultiplier * 1000) * a;
                else
                    induced = 0;
                end
                otherTot = otherTot + parasit + induced;
            end
        end

        % Signed ClS: projection onto the +Z-perpendicular lift direction
        % (double-cross convention, cf. UserTabulatedLiftModel), NEGATED
        % to match LVD's coefficient convention: the existing
        % CylindricalLiftModel yields ClS >= 0 for nose-up flight paired
        % with the double-cross lift direction, and LVD+15 deg on the
        % real stack gives ClS = +32.6 (antisymmetric in AoA, ~0 at 0).
        % Magnitudes are pinned by the component-level KWT vessel
        % comparison (KwtAeroTest.kwtVesselComponentAgreement, corr 0.999
        % at ratio ~1). Without the negation the tables would drive lift
        % backwards in LVD.
        liftDir = zRef - (zRef' * v) * v;
        nl = norm(liftDir);
        if(nl < 1e-12)
            % Inflow along +-Z: fall back to +Y-perpendicular.
            liftDir = [0; 1; 0] - ([0; 1; 0]' * v) * v;
            nl = norm(liftDir);
        end
        if(nl < 1e-12)
            liftDir = [0; 0; 0];
        else
            liftDir = liftDir / nl;
        end
        ClS(col) = -(liftTot' * liftDir);
        dragCubeCdA(col) = cubeTot * cubeScale;
        otherDragCdA(col) = otherTot;
        liftRaw(:, col) = liftTot;
    end

    out = struct();
    out.ClS = ClS;
    out.dragCubeCdA = dragCubeCdA;
    out.otherDragCdA = otherDragCdA;
    out.liftForce_kN = Q_kPa * liftRaw;
    dragMag = Q_kPa * (dragCubeCdA * reynoldsMult + otherDragCdA);
    out.dragForce_kN = -inflowHat .* dragMag;
    out.reynoldsMult = reynoldsMult;
    out.overallMult = overallMult;
    out.machClBody = machClBody;
    out.machClWing = machClWing;
end

function [lcCurve, lmcCurve, dcCurve, dmcCurve] = liftCurveSet(phys, part)
%liftCurveSet Selects the Physics.cfg lifting-surface curve set named by
%the part (ModuleLiftingSurface.liftingSurfaceCurve; Default wings,
%CapsuleBottom auto-added capsules, BodyLift fallback with zero drag).

    setName = 'Default';
    if(isfield(part, 'liftCurveSet') && ischar(part.liftCurveSet) ...
            && ~isempty(strtrim(part.liftCurveSet)))
        setName = strtrim(part.liftCurveSet);
    end
    switch lower(setName)
        case 'capsulebottom'
            lcCurve = phys.capsuleLiftCurve;
            lmcCurve = phys.capsuleLiftMachCurve;
            dcCurve = phys.capsuleDragCurve;
            dmcCurve = phys.capsuleDragMachCurve;
        case 'bodylift'
            lcCurve = phys.bodyLiftCurve;
            lmcCurve = phys.bodyLiftMachCurve;
            dcCurve = [0 0 0 0];
            dmcCurve = [0 0 0 0];
        otherwise
            lcCurve = phys.wingLiftCurve;
            lmcCurve = phys.wingLiftMachCurve;
            dcCurve = phys.wingDragCurve;
            dmcCurve = phys.wingDragMachCurve;
    end
end

function lVec = rotateForControl(part, pitchInput)
    lVec = part.liftVector_local(:);
    if(~part.isControl || pitchInput == 0)
        return;
    end
    angDeg = -(pitchInput * part.authorityLimiter * part.ctrlRangeDeg ...
        + part.deployAngleDeg);
    ang = deg2rad(angDeg);
    ax = part.rotationAxis_local(:);
    if(norm(ax) <= 0)
        return;
    end
    ax = ax / norm(ax);
    % Rodrigues rotation of the lift vector about the control axis.
    lVec = lVec * cos(ang) + cross(ax, lVec) * sin(ang) ...
        + ax * (ax' * lVec) * (1 - cos(ang));
end
