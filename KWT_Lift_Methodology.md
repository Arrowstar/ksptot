# Kerbal Wind Tunnel — Lift vs Attitude & Mach: Reverse Engineering + MATLAB Port Plan

Source: https://github.com/DBooots/KerbalWindTunnel-2
Status: KWT does NOT do CFD. It replays stock KSP aero exactly, then caches it as separable `f(Mach) * g(AoA) * q` curves.

Core chain: `SimulatedVessel` → `PartCollection` → `SimulatedPart` + `SimulatedLiftingSurface` → `CharacterizedVessel` cache.

Design decision: full 3D sweeps stored as a 4D map over (Mach, AoA, sideslip, roll) — see §7.
Native V1 only: no KSP in the sweep/generation loop (KSP files are a one-time DB build input, §6.5).
The cylinder approximation is NOT used at any stage.

---

## 1. Flight conditions (Mach + dynamic pressure)

`Scripts/AeroPredictor.cs:286-331` (`Conditions` struct):

```csharp
atmDensity, atmPressure = body.GetPressure/GetDensity(alt)
speedOfSound = body.GetSpeedOfSound(pressure, density)
mach = speed / speedOfSound
Q = 0.0005 * atmDensity * speed^2   // = 0.5*rho*V^2 in kN/m^2
pseudoReDragMult = DragCurvePseudoReynolds(rho * V)  // drag ONLY, never lift
```

Mach enters lift only via `V → Mach` conversion + `FloatCurve.Evaluate(mach)` lookups below.
No Prandtl-Glauert of its own — everything Mach is Squad's curves in part cfgs + `Physics.cfg`.

## 2. Attitude → inflow vector → flight-frame lift

`Scripts/AeroPredictor.cs:232-237`, `Scripts/VesselCache/PartCollection.cs:125-159`:

```csharp
inflowHat(AoA) = forward*cos(-AoA) + up*sin(-AoA)  // pitch-plane, radians, about left/X axis
F_vessel = Q * Σ f(normalized_inflow, mach)         // summed in vessel frame
LiftMag  = ToFlightFrame(F_vessel, AoA).y           // rotate by +AoA about left, take Y
LiftVec_vessel = ToVesselFrame(LiftMag * up, AoA)
```

`GetLiftForceComponent(force, AoA) = ToFlightFrame(force, AoA).y`
`GetDragForceComponent(force, AoA) = -ToFlightFrame(force, AoA).z`

Note: KWT's pitch-plane `InflowVect(AoA)` is a UI/sweep convenience, NOT a physics limit.
Underneath, `PartCollection.GetLiftForce` / `SimulatedPart.GetLift` / `SimulatedLiftingSurface.GetLift`
all take an arbitrary 3D `Vector3 inflow`. The 4D sweep (§7) feeds full 3D inflow vectors and
bypasses the 1D `CharacterizedVessel` cache, which is purely a speed optimization for KWT's graphs.

## 3. Wing / lifting-surface lift (`ModuleLiftingSurface`)

`Scripts/VesselCache/SimulatedLiftingSurface.cs:99-109`:

```csharp
dot    = inflowHat · liftVector          // attitude enters HERE; full 3D dot, no pitch-only assumption
absdot = omnidirectional ? |dot| : clamp01(dot)
lift = -liftVector * sign(dot)
       * liftCurve(absdot)               // stock FloatCurve on sin(AoA)-like input
       * liftMachCurve(mach)             // stock FloatCurve on Mach
       * deflectionLiftCoeff             // includes wing area
       * PhysicsGlobals.LiftMultiplier
       * 1000
if (perpendicularOnly) lift = ProjectOnPlane(lift, -inflowHat)
```

Later multiplied by `Q` in `PartCollection.GetLiftForce`.
`liftVector` comes from `ModuleLiftingSurface.SetupCoefficients(forward, ...)` — part-local, rotated to vessel by `partToVessel` quat.

Controls (`Scripts/VesselCache/SimulatedControlSurface.cs:199-215`):
same as above but `liftVector` rotated by `surfaceInput(pitchInput)` about `rotationAxis`
(`authorityLimiter`, `ctrlSurfaceRange`, ahead/behind-CoM sign flip, `deployAngle`).
Fast path (`CharacterizedVessel`) bakes controls at 0 deflection for lift; deflection survives only as drag delta (`CharacterizedControlSurface.cs:31-51` via `neutral/fullDeflectionPos/fullDeflectionNeg` cube weights).
4D tables are baked at a stated deflection (default 0); re-sweep for nonzero trim deflection.

## 4. Body lift (drag cubes, parts WITHOUT `ModuleLiftingSurface`)

`Scripts/VesselCache/SimulatedPart.cs:332-351` (lift-only) and `:270-324` (full aero):

```csharp
cubes.SetDrag(-(vesselToPart * inflowHat), mach)
liftV = partToVessel * (cubes.LiftForce * bodyLiftMultiplier)
liftV = ProjectOnPlane(liftV, inflowHat)
        * PhysicsGlobals.BodyLiftMultiplier
        * cubes.BodyLiftCurve.liftMachCurve.Evaluate(mach)
```

Zero if `shieldedFromAirstream || hasLiftModule || cubesNone || dragModel != CUBE` (`:353-354`).
`cubes.LiftForce` is the blunt-body lift vector computed inside KSP's `DragCubeList.SetDrag`
for an arbitrary 3D direction — already full-3D, no pitch-only restriction.
Body lift is NOT multiplied by `pseudoReDragMult` (drag is: `:320`).

## 5. Cached / characterized form (what the graphs actually sample)

`Scripts/CharacterizedVessel/CharacterizedVessel.cs:424-448`:

```csharp
L(M, AoA) = Q * [ Σ_groups liftMach_i(M) * CL_surf_i(AoA)
                + Σ_groups bodyMach_j(M) * CL_body_j(AoA) ]
```

- `CL(AoA) = GetLift(InflowVect(AoA), evalPt).projectedY / machMag` — sampled at a reference Mach `evalPt` where the Mach curve is nonzero, divided by `machMag` to normalize (`CharacterizedLiftingSurface.cs:97-114`, `CharacterizedPart.cs:83-99`).
- AoA sample keys = union of: every 15°, every stock-curve key mapped vessel↔local via `SinAoAMapping` (`CharacterizationExtensions.cs:85-111`), part-axis 0/90° keys. Groups split by identical `liftMachCurve` instance (`:215-237`).
- Display coefficient: `CL = L / (Q * Area)`, `Area = Σ deflectionLiftCoeff*|liftVector.y|` (`PartCollection.cs:364`), fallback 1 (`SimulatedVessel.cs:236-240`).
- AoA sweep graphs: `Scripts/DataGenerators/AoACurve.cs:207-232`. Mach/velocity envelope: `Scripts/DataGenerators/VelCurve.cs` + `EnvelopePoint.cs`. KWT export oracle: `CharacterizedVessel.cs:569-615` (`WriteToDataSet`: `surfLift/bodyLift/surfDrag/induDrag` + Mach factors).
- This 1D separable cache is NOT reused for the 4D port — it cannot represent sideslip/roll coupling. The 4D sweep evaluates the §3–§4 direct path (§7).

Net formula (pitch-plane slice; full-3D form replaces `AoA` with the 3D `inflowHat` vector):

```text
L(AoA,M,V,alt) = 0.5*rho(alt)*V^2 * [
  Σ_wings liftMach_w(M) * Gw(inflowHat(AoA)·l̂w)
  + Σ_bodies bodyMach_b(M) * Gb(cubes, inflowHat(AoA)) ]
```

`G()` = stock curve interpolation + `sign/dot/clamp/project` + flight-frame-Y extraction. Mach = per-curve lookup multiplier.

---

## 6. MATLAB port — cubes-first (no cylinder approximation)

Decision: implement drag cubes on the first pass. The cylinder model in
`helper_methods/ksptot_lvd/classes/ForceModels/aero/lift/@CylindricalLiftModel/CylindricalLiftModel.m:49,83-88`
is NOT used for this port.

### 6.1 What already exists in KSPTOT (reuse)

| Item | Location |
|---|---|
| Craft parser (tree, `link`, `istg`, stages) | `helper_methods/ksptot_lvd/vehicle_import/lvd_import_analyzeCraft.m:48-150` |
| Part DB loader (GameData scan, localization, dot/underscore aliases) | `helper_methods/ksptot_lvd/vehicle_import/lvd_import_getPartDatabase.m:373-489` |
| Stock default/body lift curves (already hardcoded from `Physics.cfg`) | `.../ForceModels/aero/lift/@LiftCoefficientCurves/LiftCoefficientCurves.m:19-52` |
| Table-lookup aero precedent (Mach/AoA/sideslip + Reynolds) | `.../ForceModels/aero/drag/kos_model/@KosDragCoeffientModel/KosDragCoeffientModel.m:99-136` |
| Tabulated lift precedent (Mach/AoA/sideslip → ClS) | `.../ForceModels/aero/lift/user_tabulated/@UserTabulatedLiftModel/UserTabulatedLiftModel.m:23,77` |
| Aero-angle helpers (Euler ↔ AoA/sideslip) | `helper_methods/ksptot_lvd/steering/computeAeroAnglesFromBodyAxes.m`, `computeBodyAxesFromAeroAngles.m`, `computeBodyAxesFromInertialAeroAngles.m` |
| Aero state sockets (`DragCoeffModel` / `LiftCoeffModel`) | `.../StateLog/@LaunchVehicleAeroState/LaunchVehicleAeroState.m:7,10,38,58` |
| Example craft files | `examples/LaunchVehicleDesigner/kOSOpenLoopControlKerbinLaunch/DragData/*.craft` |

### 6.2 Gaps (must build)

1. **Cube data source.** Bundled `vehicle_import/resources/partsDatabaseStockKSP.json` (~94KB) has NO cube fields; schema v1 (`lvd_import_getPartDatabase.m:247-290`) stores only `mass/resources/engines/roles`. Real cubes live in the KSP install's `PartDatabase.cfg` (`PART { url, DRAG_CUBE { CUBES { ... CENTER/SIZE/DRAG/AREA/DEPTH ... }, DRAGCURVES ... } }`, one block per variant/state). `sfsParse` already reads this format. Procedural parts (fairings) need `RenderProceduralDragCube` fallback — v1: throw/skip with warning.
2. **`SetDrag(dirLocal, Mach)` port.** Pure function `(cube, dirLocal, Mach) → (AreaDrag, LiftForce)` with `dirLocal` an arbitrary 3D unit vector (already 3D-capable; nothing pitch-specific to generalize). Reference implementations (port, don't derive):
   - KSPCommunityFixes PR #139 `DragCubeGeneration` — open C# re-implementation of `DragCubeSystem.CalculateAerodynamics()`.
   - Ren0k `Project-Atmospheric-Drag` (kOS) — full Tip/Surface/Tail + Mach-multiplier/power + Reynolds + occlusion + variant logic in a scripting language; closest to MATLAB.
   - MechJeb2 `FlyingSim/SimulatedPart.cs` — confirms lift assembly: `Lift = partToVessel*(cubes.LiftForce*bodyLiftMultiplier)` projected ⊥ velocity.
   - API surface: KSPDocs `DragCubeList` (`SetDrag`, `AreaDrag`, `LiftForce`, `Area`, `CubeData`), `DragCubeSystem` (`LoadDragCubes`, `RenderProceduralDragCube`).
   - Per-face shape: `cos` → frontal/rear drag, `sin` → skin drag, each through Mach curves, `Σ occludedArea × transformedDrag = AreaDrag` + blunt-body `LiftForce`.
3. **Geometry the analyzer drops.** `lvd_import_analyzeCraft` keeps the attach tree but drops `pos/rot/attRot/mir` and `attN` node lines. Cubes are part-local → need full 3D `partToVessel` quats chained from craft rotations (all three axes, not pitch only), node-occlusion pairs (rotation-dependent: which face covers which), and `ShieldedFromAirstream` approximation (bays/fairings) from the attach tree or an exclusion list.
4. **`Physics.cfg` globals.** `LiftMultiplier, BodyLiftMultiplier, DragMultiplier, DragCubeMultiplier, LiftingSurfaceCurves, DragCurvePseudoReynolds, DragCurveCd/CdPower/Multiplier`.
5. **4D table model classes.** Existing `KosDragCoeffientModel` (3D: Mach,AoA,sideslip) and `UserTabulatedLiftModel` (3D: Mach,AoA,sideslip) need 4D subclasses adding the roll axis (same `griddedInterpolant` pattern, one extra grid vector). See §7.4.

### 6.3 Proposed MATLAB interface (v1, full attitude)

```matlab
[Fvec_vessel_kN, Lmag_kN, Dmag_kN, CLS, CDAS] = kwt_aero(craftSpec, aeroDB, inflowHat, Mach, Q_kPa, pitchInput)
% craftSpec : from extended lvd_import_analyzeCraft (adds 3D partToVessel quats, CoM/CoL, ctrl flags)
% aeroDB    : from extended partDB (adds ModuleLiftingSurface params + DRAG_CUBE tables + Physics.cfg)
% inflowHat : 3xN unit vectors in vessel frame (caller builds from yaw/pitch/roll Euler or AoA/sideslip/roll, §7.1)
% Mach, Q   : scalars from rho(alt)/V/a(alt); vectorized over inflow columns inside
% pitchInput: [-1,1], default 0 (rotates control-surface liftVectors; body/wing path otherwise static)
```

Inner loop per inflow vector (mirrors `PartCollection.GetLiftForce`/`GetAeroForce` + `SimulatedPart/Surface.GetLift`):

```matlab
for each column vHat of inflowHat          % arbitrary 3D unit vector, NOT pitch-plane-only
  for each part without lift module
    dirLocal = -(q_vessel2part * vHat)
    [areaDrag, LiftForce] = ksp_setDrag(cube, dirLocal, Mach)
    F = q_part2vessel * (LiftForce * bodyLiftMultiplier)
    F = F - (F'*vHat)*vHat                 % project ⊥ inflow
    F = F * BodyLiftMultiplier * bodyLiftMach(Mach)
    D_part = -vHat * areaDrag              % drag along -inflow, × Q × DragMultiplier × pseudoRe outside
  for each lifting surface
    d = vHat' * liftVector;  a = omnidirectional ? abs(d) : clamp01(d)
    F = -liftVector * sign(d) * liftCurve(a) * liftMach(Mach) * deflectionLiftCoeff * LiftMultiplier
    if perpendicularOnly, F = F - (F'*vHat)*vHat
  F_total = Q * sum(F);  D_total = Q * sum(D)
end
```

Lift/drag magnitudes are defined against the full 3D inflow (lift = ⊥ inflow in the plane
containing body-X, drag = −inflow), consistent with LVD's `getLiftCoeffAndDir` direction
construction (`UserTabulatedLiftModel.m:106-119`: `cross(v,bodyX)` double-cross). The table stores
scalars `ClS(Mach,AoA,sideslip,roll)`, `CdA(Mach,AoA,sideslip,roll)`; direction is reconstructed
live from attitude — no 3-component vector table needed (§7.4).

### 6.4 Build order

1. `lvd_import_cubeDB` — parse `PartDatabase.cfg` + `Physics.cfg` into `partDB.cubes` (variant/state aware). Test: every stock part in a test craft resolves to ≥1 cube.
2. `ksp_setDrag` — `(cube, dirLocal3D, Mach) → (AreaDrag, LiftForce)`. Test per-face vs KSP AeroGUI arrow data (Alt-F12 → Physics → Aero) at off-axis directions (yaw/sideslip and roll cases, not just pitch), plus KWT `WriteToDataSet` pitch-plane slice at fixed Mach, AoA = -180:15:180.
3. `kwt_aero` — craft `pos/rot` → 3D `partToVessel`, wing + body loop above over arbitrary inflow vectors. Validate: 1 part → 1 winged craft → full vessel, against KWT CSV export (`bodyDrag/surfLift/bodyLift` tables) on the pitch-plane slice and kOS `Project-Atmospheric-Drag` profile for the same craft.
4. 4D sweep + table writer + 4D model classes (§7): grid over (Mach,AoA,sideslip,roll), write `mach,aoa_deg,sideslip_deg,roll_deg,Cls,CdA` CSVs, add `UserTabulated4D` / `Kos4D` subclasses. Validate per §7.5.

### 6.5 Run checklist (KSP needed ONCE for DB build, never in the sweep loop)

- [ ] ONE-TIME (on the KSP machine): KSP install path with `GameData/` (part cfgs) + `PartDatabase.cfg` (root KSP folder, generated after first run) + `Physics.cfg`. Run `cubeDB = lvd_import_cubeDB(kspRoot)` and export `cubeDB.mat` / `cubeDB.json`. This artifact ships with KSPTOT; every later step runs anywhere.
- [ ] This repo at matching commit + MATLAB with `sfsParse` on path.
- [ ] One test craft (e.g. `examples/.../DragData/Kerbal 1-5_3.craft`). Axisymmetric stack first (roll-invariance check), then a winged plane.
- [ ] (Oracle only, never input) KWT CSV export (KWT window → Export CSV) + optionally Ren0k kOS profile for the same craft.
- [ ] Run anywhere: `partDB = loadCubeDB()` → `spec = lvd_import_analyzeCraft(craftPath, partDB)` → 4D sweep (§7.3) → compare pitch-plane slice vs KWT CSV.
- [ ] (Optional, speeds step 2) KSPCommunityFixes `DragCubeGeneration` source + Ren0k `Project-Atmospheric-Drag` scripts checked out alongside for side-by-side comparison.

### 6.6 Known limitations / non-goals for v1

- Rotors (`RotorPartCollection`), deployed-gear/parachute state cubes: error/skip.
- `SetPartOcclusion` raycast fidelity: node-area occlusion only; full mesh occlusion deferred.
- Torque/`CoM`-dependent control effectiveness: force tables first, moments later (tables baked at stated deflection, default 0).
- Supersonic/hypersonic extras beyond Squad's Mach curves: out of scope — curves ARE the model.
- KSP is a build-time DB source only. If a part is missing from the exported `cubeDB`, the sweep errors with the part name rather than silently substituting.

---

## 7. Full 3D sweeps: 4D map over (Mach, AoA, sideslip, roll)

Decision: sweep the full attitude space and store scalar coefficient tables
`ClS(Mach, AoA, sideslip, roll)`, `CdA(Mach, AoA, sideslip, roll)`. Native V1, no KSP in the loop.

### 7.1 Why 4D, and why these four axes

- KWT's single-AoA axis is a graph-UI simplification. The underlying physics (`§3–§4`:
  `dot = inflow·l̂`, `SetDrag(dirLocal3D, mach)`, 6-face cubes, node occlusion) is already fully
  3D and couples pitch/yaw/roll: a yawed wing presents a different `dot` to its `liftCurve`;
  a rolled asymmetric vessel puts different cube faces windward; occlusion pairs change with
  relative part rotation. A pitch-only table silently zeroes all of that — wrong for planes,
  shuttles, and any sideslipping ascent.
- Roll is the axis most often skipped, and it matters exactly when the vessel is NOT
  axisymmetric: rotation about the velocity vector changes which faces/liftVectors see the wind
  and rotates the lift plane. Axisymmetric stacks are the special case (roll drops out —
  detectable, §7.3), not the default.
- Parameterization is (Mach, AoA, sideslip, roll-about-velocity), NOT raw yaw/pitch/roll Euler:
  (a) it matches what LVD already consumes — `attState.getAeroAngles` yields
  `(aoa, sideslip, totalAoA)` and both existing table models interpolate on
  `(Mach, AoA, sideslip)`; the 4D tables add exactly one grid axis;
  (b) Euler yaw/pitch has a singularity at ±90° pitch while the inflow unit vector does not —
  sweeping Euler but STORING aero angles keeps the physics singularity-free and the runtime
  lookup in LVD's native coordinates. Sweep generation still accepts yaw/pitch/roll Euler as
  input (intuitive attitude spec): Euler → DCM → `inflowHat` (well-defined 3D vector) →
  `(AoA, sideslip, roll)` table index via the existing `computeAeroAnglesFrom*` steering helpers.

### 7.2 No new physics vs KWT — different sampling, different storage

- Sampling: replace KWT's 1D `InflowVect(AoA)` with the full 3D inflow built from the
  (yaw,pitch,roll) attitude: `vHat_vessel = q_attitude' * (-vInf)` normalized, or equivalently
  constructed from (AoA,sideslip) + roll rotation about `vHat`. Feed it to the UNCHANGED §6.3
  per-vector loop (the `SimulatedVessel`-direct path). Skip `CharacterizedVessel` entirely —
  its separable `f(M)*g(AoA)` `FloatCurve` cache cannot represent sideslip/roll coupling by
  construction (§5).
- Storage: KWT stores separable 1D `FloatCurve`s per Mach-curve group. We store one 4D
  `griddedInterpolant` per coefficient (same pattern as `KosDragCoeffientModel.m:80` /
  `UserTabulatedLiftModel.m:66`, one extra grid vector, `"linear"` + `"nearest"` extrapolation).
  This trades KWT's compact analytic separability for generality — correct wherever the flow
  angles couple, at the cost of table size (§7.3).

### 7.3 Grid strategy and cost control

Naive uniform grids explode (e.g. 12 Mach × 37 AoA × 13 sideslip × 8 roll ≈ 46k points × N parts).
Each point is cheap (per-part curve evals, no meshing), so a full sweep is minutes in MATLAB
with vectorization/`parfor` — but build the grid adaptively anyway:

- Mach: stock Mach-curve keys (`LiftMachs`/`DragMachs` union, cf. `SimulatedVessel.cs:305-329`) +
  transonic clustering 0.8–1.2. Mach is the only axis with shocks in it; spend resolution here.
- AoA: every 15° base (KWT's `AoASpacing`) + stock `liftCurve` keys mapped through
  `SinAoAMapping` + refinement 0–30° (stall/peak region). Mirror for ±.
- Sideslip: coarse (0/5/10/15/30/…); most vessels are near-symmetric — refine only if
  asymmetric sweep variance exceeds tolerance.
- Roll: coarse (0/45/90/…); roll-exact symmetry (axisymmetric stack: variance over roll ≈ 0)
  collapses the axis entirely — detect per-vessel at sweep time and store a 3D table with a
  `rollInvariant` flag rather than 8 identical slices.
- Symmetry halves: mirror-symmetric craft need only sideslip ≥ 0 (mirror for < 0); document the
  assumed symmetry plane per craft in the table header.
- Start axisymmetric (Kerbal 1-5 stack: expect roll-invariance → validates the pipeline), then
  one winged plane (roll/sideslip coupling must appear), then the real craft.

### 7.4 LVD integration: scalar 4D tables, direction reconstructed live

- Store scalars only: `ClS` and `CdA` over (Mach, AoA, sideslip, roll). Lift DIRECTION is
  reconstructed at runtime from live attitude exactly as `UserTabulatedLiftModel.m:106-119`
  does today (`cross(v,bodyX)` double-cross via body frames) — no 3-component vector table,
  no force-model rewrite. The two new classes (`UserTabulated4DLiftModel`,
  `Kos4DDragCoeffientModel` or equivalent) are mechanical 3D→4D extensions of the existing
  pair: same CSV discipline (`mach,aoa_deg,sideslip_deg,roll_deg,Cls[,CdA]`), same
  `griddedInterpolant`, same `plotLiftEnvelope`/`plotDragEnvelope` slice plotters with roll
  held at the slice value.
- The LVD "button" (craft import → generate tables → install models into
  `LaunchVehicleAeroState`) therefore needs: sweep runner (§6.3 loop over §7.3 grid) + CSV
  writer + `newModel = FourDModel(csv)` + assignment. Staging caveat stands: tables are
  per-configuration (drop/asparagus changes geometry/occlusion) — stamp config hash + symmetry
  flags + baked deflection in the CSV header, regen per stage.

### 7.5 4D validation (each is a distinct failure mode)

1. Pitch-plane slice (`sideslip = 0`, `roll = 0`) reproduces the KWT AoA curve / KWT CSV export
   for the same craft and Mach — validates the §3–§4 port with zero 4D confounding.
2. Sideslip slice vs kOS `Project-Atmospheric-Drag` profile for the same craft — validates
   off-axis cube interpolation (`cos` frontal/rear vs `sin` skin split).
3. Roll-invariance on the axisymmetric stack (variance over roll ≈ 0 at all Mach/AoA) —
   validates quat chaining (`partToVessel` on all three axes, §6.2.3). Nonzero variance here
   means a rotation bug, not aerodynamics.
4. Roll-coupling on the winged plane (roll = 0 vs 90 at fixed AoA MUST differ) — validates the
   axis exists end-to-end (sweep → table → 4D model → force).
5. Symmetry mirror (`sideslip −β` == mirror of `+β`; symmetric craft) — validates face/occlusion
   bookkeeping rather than physics.

## References

- KWT: `AeroPredictor.cs`, `VesselCache/{SimulatedPart,SimulatedLiftingSurface,SimulatedControlSurface,SimulatedVessel,PartCollection}.cs`, `CharacterizedVessel/{CharacterizedVessel,CharacterizedPart,CharacterizedLiftingSurface,CharacterizedControlSurface,CharacterizationExtensions}.cs`, `DataGenerators/{AoACurve,VelCurve,EnvelopePoint}.cs`, `WindTunnelWindow.cs:766-767` (sim-vs-char check).
- KSPDocs: `DragCubeList` / `DragCubeSystem` / `IMultipleDragCube` class references.
- KSPCommunityFixes PR #139 (`DragCubeGeneration`).
- Ren0k `Project-Atmospheric-Drag` (kOS drag-profile + `useProfile.ks`, README drag-cube section).
- MechJeb2 `FlyingSim/SimulatedPart.cs` (`Drag`/`Lift`).
- Lt_Duckweed, "Kerbal University: The Drag Cube" (face/occlusion/Mach-transform walkthrough).
