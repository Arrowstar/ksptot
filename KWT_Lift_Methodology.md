# Kerbal Wind Tunnel — Lift vs Attitude & Mach: Reverse Engineering + MATLAB Port Plan

Source: https://github.com/DBooots/KerbalWindTunnel-2
Status: KWT does NOT do CFD. It replays stock KSP aero exactly, then caches it as separable `f(Mach) * g(AoA) * q` curves.

Core chain: `SimulatedVessel` → `PartCollection` → `SimulatedPart` + `SimulatedLiftingSurface` → `CharacterizedVessel` cache.

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

## 3. Wing / lifting-surface lift (`ModuleLiftingSurface`)

`Scripts/VesselCache/SimulatedLiftingSurface.cs:99-109`:

```csharp
dot    = inflowHat · liftVector          // attitude enters HERE
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
`cubes.LiftForce` is the blunt-body lift vector computed inside KSP's `DragCubeList.SetDrag`.
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

Net formula:

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
| Example craft files | `examples/LaunchVehicleDesigner/kOSOpenLoopControlKerbinLaunch/DragData/*.craft` |

### 6.2 Gaps (must build)

1. **Cube data source.** Bundled `vehicle_import/resources/partsDatabaseStockKSP.json` (~94KB) has NO cube fields; schema v1 (`lvd_import_getPartDatabase.m:247-290`) stores only `mass/resources/engines/roles`. Real cubes live in the KSP install's `PartDatabase.cfg` (`PART { url, DRAG_CUBE { CUBES { ... CENTER/SIZE/DRAG/AREA/DEPTH ... }, DRAGCURVES ... } }`, one block per variant/state). `sfsParse` already reads this format. Procedural parts (fairings) need `RenderProceduralDragCube` fallback — v1: throw/skip with warning.
2. **`SetDrag(dirLocal, Mach)` port.** Pure function `(cube, dirLocal, Mach) → (AreaDrag, LiftForce)`. Reference implementations (port, don't derive):
   - KSPCommunityFixes PR #139 `DragCubeGeneration` — open C# re-implementation of `DragCubeSystem.CalculateAerodynamics()`.
   - Ren0k `Project-Atmospheric-Drag` (kOS) — full Tip/Surface/Tail + Mach-multiplier/power + Reynolds + occlusion + variant logic in a scripting language; closest to MATLAB.
   - MechJeb2 `FlyingSim/SimulatedPart.cs` — confirms lift assembly: `Lift = partToVessel*(cubes.LiftForce*bodyLiftMultiplier)` projected ⊥ velocity.
   - API surface: KSPDocs `DragCubeList` (`SetDrag`, `AreaDrag`, `LiftForce`, `Area`, `CubeData`), `DragCubeSystem` (`LoadDragCubes`, `RenderProceduralDragCube`).
   - Per-face shape: `cos` → frontal/rear drag, `sin` → skin drag, each through Mach curves, `Σ occludedArea × transformedDrag = AreaDrag` + blunt-body `LiftForce`.
3. **Geometry the analyzer drops.** `lvd_import_analyzeCraft` keeps the attach tree but drops `pos/rot/attRot/mir` and `attN` node lines. Cubes are part-local → need `partToVessel` quats chained from craft rotations, node-occlusion pairs (rotation-dependent: which face covers which), and `ShieldedFromAirstream` approximation (bays/fairings) from the attach tree or an exclusion list.
4. **`Physics.cfg` globals.** `LiftMultiplier, BodyLiftMultiplier, DragMultiplier, DragCubeMultiplier, LiftingSurfaceCurves, DragCurvePseudoReynolds, DragCurveCd/CdPower/Multiplier`.

### 6.3 Proposed MATLAB interface (v1, lift-only)

```matlab
[Lvec_vessel_kN, Lmag_kN, CL] = kwt_lift(craftSpec, aeroDB, AoA_rad, Mach, Q_kPa, pitchInput)
% craftSpec : from extended lvd_import_analyzeCraft (adds partToVessel quat, CoM/CoL, ctrl flags)
% aeroDB    : from extended partDB (adds ModuleLiftingSurface params + DRAG_CUBE tables + Physics.cfg)
% AoA_rad   : scalar or vector (pitch-plane, KWT convention: 0 = nose-on, + = up)
% Mach, Q   : scalars from rho(alt)/V/a(alt); vectorized over AoA inside
% pitchInput: [-1,1], default 0 (rotates control-surface liftVectors; body/wing path otherwise static)
```

Inner loop per AoA (mirrors `PartCollection.GetLiftForce` + `SimulatedPart/Surface.GetLift`):

```matlab
vHat = [0; sin(-AoA); cos(-AoA)];   % vessel frame: forward=z, up=y (check sign vs KWT InflowVect)
for each part without lift module
    dirLocal = -(q_vessel2part * vHat)
    [~, LiftForce] = ksp_setDrag(cube, dirLocal, Mach)
    F = q_part2vessel * (LiftForce * bodyLiftMultiplier)
    F = F - (F'*vHat)*vHat           % project ⊥ inflow
    F = F * BodyLiftMultiplier * bodyLiftMach(Mach)
for each lifting surface
    d = vHat' * liftVector;  a = min(max(abs(d),0),1) or abs
    F = -liftVector * sign(d) * liftCurve(a) * liftMach(Mach) * deflectionLiftCoeff * LiftMultiplier
    if perpendicularOnly, F = F - (F'*vHat)*vHat
L = Q * sum(F);  Lmag = rotX(AoA)*L -> y-component
```

### 6.4 Build order

1. `lvd_import_cubeDB` — parse `PartDatabase.cfg` + `Physics.cfg` into `partDB.cubes` (variant/state aware). Test: every stock part in a test craft resolves to ≥1 cube.
2. `ksp_setDrag` — `(cube, dirLocal, Mach) → (AreaDrag, LiftForce)`. Test per-face vs KSP AeroGUI arrow data (Alt-F12 → Physics → Aero) or KWT `WriteToDataSet` export at fixed Mach, AoA = -180:15:180.
3. `kwt_lift` — craft `pos/rot` → `partToVessel`, wing + body loop above, `× Q`, flight-frame Y. Validate: 1 part → 1 winged craft → full vessel, against KWT CSV export (`bodyDrag/surfLift/bodyLift` tables) and/or kOS `Project-Atmospheric-Drag` profile for the same craft.

### 6.5 Run checklist (on the KSP machine)

- [ ] KSP install path with `GameData/` (for part cfgs) + `PartDatabase.cfg` (root KSP folder, generated after first run) + `Physics.cfg` (`GameData/Squad/...` or root `Physics.cfg` depending on version).
- [ ] This repo at matching commit + MATLAB with `sfsParse` on path.
- [ ] One test craft (e.g. `examples/.../DragData/Kerbal 1-5_3.craft`) + its KWT export (KWT window → Export CSV) as oracle.
- [ ] (Optional, speeds step 2) KSPCommunityFixes `DragCubeGeneration` source + Ren0k `Project-Atmospheric-Drag` scripts checked out alongside for side-by-side comparison.
- [ ] Run: `partDB = lvd_import_getPartDatabase(struct('gameDataPath',...))` → `cubeDB = lvd_import_cubeDB(kspRoot)` → `spec = lvd_import_analyzeCraft(craftPath, partDB)` → `[Lvec,Lmag,CL] = kwt_lift(spec, cubeDB, deg2rad(-180:5:180), Mach, Q, 0)` → plot vs KWT CSV.

### 6.6 Known limitations / non-goals for v1

- Rotors (`RotorPartCollection`), deployed-gear/parachute state cubes: error/skip.
- `SetPartOcclusion` raycast fidelity: node-area occlusion only; full mesh occlusion deferred.
- Torque/`CoM`-dependent control effectiveness: lift magnitude first, moments later.
- Supersonic/hypersonic extras beyond Squad's Mach curves: out of scope — curves ARE the model.

## References

- KWT: `AeroPredictor.cs`, `VesselCache/{SimulatedPart,SimulatedLiftingSurface,SimulatedControlSurface,SimulatedVessel,PartCollection}.cs`, `CharacterizedVessel/{CharacterizedVessel,CharacterizedPart,CharacterizedLiftingSurface,CharacterizedControlSurface,CharacterizationExtensions}.cs`, `DataGenerators/{AoACurve,VelCurve,EnvelopePoint}.cs`, `WindTunnelWindow.cs:766-767` (sim-vs-char check).
- KSPDocs: `DragCubeList` / `DragCubeSystem` / `IMultipleDragCube` class references.
- KSPCommunityFixes PR #139 (`DragCubeGeneration`).
- Ren0k `Project-Atmospheric-Drag` (kOS drag-profile + `useProfile.ks`, README drag-cube section).
- MechJeb2 `FlyingSim/SimulatedPart.cs` (`Drag`/`Lift`).
- Lt_Duckweed, "Kerbal University: The Drag Cube" (face/occlusion/Mach-transform walkthrough).
