# Launch Vehicle Designer — Enhancement Report

*Prepared 2026-09-15 against branch `v1.6.11` (HEAD `0b640548`).*

This report is the result of a close read of the LVD engine (`helper_methods/ksptot_lvd/**`) and its App Designer front end (`kspTOT_LaunchVehicleDesigner/**`). It deliberately stays inside LVD's existing architecture: a 3-DOF, event-scripted, force-model-integrating trajectory tool with embedded NLP optimization. Nothing here requires rotational dynamics, a new simulation core, or a new UI framework.

Two earlier idea documents exist in the repository history: `LVD_DeepDive_and_Roadmap.md` (Aug 25, 2026, since removed from the tree) and `kspTOT_LaunchVehicleDesigner/LVD_ENHANCEMENT_IDEAS.md` (Aug 27, 2026, tracked at HEAD). Two of their items have shipped since, craft-file import (`e1588aec`) and incremental re-propagation caching (`0140f712`). Where this report agrees with them (Monte Carlo, wind, heating and load indicators, engine transients, multi-start and continuation, templates, headless runner, ephemeris exchange) the item is kept but given a concrete implementation path in the current code. The bulk of what follows is new: it comes from reading the event, termination, steering, throttle, optimization, analysis, and vehicle classes line by line, and it concentrates on friction and gaps that are invisible from the feature list but obvious from the source, including several stubs and defects.

---

## 1. Where LVD stands today

The numbers below were counted from the source, not from documentation.

| Area | Inventory |
|---|---|
| Event actions | 33 concrete action classes plus if/elseif/else `ConditionalAction` (AND/OR trees over any Graphical Analysis quantity). 5 actions carry optimization variables. |
| Termination conditions | 25 listed in `TerminationConditionEnum`; 23 optimizable; **2 are non-functional stubs** (Ascending Node, Descending Node). One condition per event; direction is an event-level enum. |
| Non-sequential events | Interrupt-style: actions only, single condition, armed over an event-index range, `maxNumExecs` counter. |
| Force models | Gravity (point mass or full spherical harmonics from a user file), 3rd-body, drag (constant / 1-D table / kOS Cd(Mach,AoA,β) / two hidden Kerbal Wind Tunnel models), lift (KSP cylinder only), SRP (sphere, solar sail), thrust, spherical ground "normal force". No wind, no heating. |
| Steering | 9 steering model classes (2 hidden/deprecated), 3 control frames (NED, wind, base-frame RA/Dec), any `AbstractReferenceFrame` as base, per-angle math models (poly terms, sines, linear tangent, `fitnet`). All open-loop functions of time. A complete PEG class exists and is **referenced nowhere**. |
| Throttle | 3 models: polynomial, target T/W, tabular interpolation. No q-limited or g-limited law; no selectable math models like steering has. |
| Integrators | 7 adaptive MATLAB solvers, 1 fixed-step (ODE5), RKN1210 for the gravity-only 2nd-order propagator. 3 propagators. |
| Optimization | 7 solvers (fmincon IP/SQP/AS, custom SQP, IPOPT, NOMAD 4.6 + DiscoMADS surrogate, patternsearch, surrogateopt, AdamNLOpt). 3 gradient modes (solver built-in, custom FD with objective sparsity, DERIVEST). ~50 variable classes, 37 constraint classes plus the ~55-quantity `GenericMAConstraint`, StateComparison mode for continuity, composite objective (Sum/RSS/Max/Min, Min/Max). |
| Analysis | 87 fixed Graphical Analysis quantities + 20 per-object dynamic families; 5 independent variables; CSV export only. Constraint Jacobian heat map and two auto-scalers. |
| Geometry | 7 point, 9 vector, 2 angle, 2 plane, 3 coord-sys, 1 ref-frame types. |
| Sensors / ground | Conical + rectangular sensors with body-occlusion meshes, 3 target types, Excel coverage report. Ground objects with moving waypoints; az/el/range/LoS analysis; az/el/range constraints. Sensors contribute zero constraints or GA quantities. |
| Case Matrix | Full-factorial sweep over **plugin variables only**, optimizing each case in parallel, Excel output. No random sampling. |
| Vehicle import | `.craft` parser to stages/tanks/engines/crossfeed with a bundled stock parts DB. No EPS, aero, or staging-event generation. |
| kOS export | Time-indexed yaw/pitch/roll/throttle/stage-cue CSV + `exec_lvd_control.ks`. Open loop only. |

**Overall assessment.** LVD's engine is broad and its extension points (`AbstractEventAction`, `AbstractEventTerminationCondition`, `AbstractConstraint`, `AbstractOptimizationVariable`, `AbstractSteeringModel`, `AbstractThrottleModel`, `AbstractGeometricPoint/Vector`, the GA task registry, `LvdPluginExecLocEnum`) are clean enough that most of the items below are additive. The biggest usability drag is not missing physics; it is friction in the event/termination model and in optimization diagnostics. The biggest capability gap for professional users is the absence of interplanetary targeting quantities (B-plane), contact-interval analysis, and dispersion/trade tooling that sweeps anything other than plugin variables.

---

## 2. Enhancement list

Each item gives: **what**, **who benefits** (KSP = advanced KSP player, Pro = astrodynamicist), **why**, **how it fits** (classes/files to extend), and a rough **effort** (S = a day or two, M = a week, L = multiple weeks). Priority tiers are in Section 3.

### A. Event scripting and termination

**A1. Multiple termination conditions per event (first-of / all-of).**
KSP, Pro. "Burn until apoapsis = 200 km *or* tank empty *or* 300 s elapsed" is the single most common thing users want and currently requires chaining dummy events. `LaunchVehicleEvent.termCond` is `(1,1)`; `AbstractPropagator.odeEvents` already builds an arbitrary-length events vector (max sim time, min altitude, non-seq conditions, SoI events, then the event's own condition), so the propagator side is nearly free. Add a `termConds` array plus a `termCondLogic` enum (Any / All; "All" is implemented as a latched flag per condition), record *which* condition fired in the state log, and extend `lvd_editEventGUI_App` with a list box. Effort: M.

**A2. "Graphical Analysis quantity" termination condition.**
KSP, Pro. `QuantityComparisonActionCondition` already evaluates any GA task in any frame against a constant or another quantity. A `GaQuantityTermCondition` reusing `lvd_getDepVarValueUnit` would instantly give termination on eccentricity, inclination, RAAN, C3, distance to any body/point, geometric angle or vector magnitude, ground-station elevation, per-engine state, Mach, heating (once A-list D2 exists), and so on. Cost per ODE step is one GA evaluation, comparable to existing conditions. Effort: S–M.

**A3. Nth-crossing and arming delay.**
Pro. Add `numCrossingsToSkip` and `minTimeBeforeArm` to `AbstractEventTerminationCondition`, honoured in the event function wrapper (return a non-terminal value until armed). Replaces the "dummy 10-second coast before the real periapsis event" idiom and makes `TrueAnomalyTermCondition.mustGoThrough0` (currently unreachable from any UI) redundant. Effort: S.

**A4. Finish or remove the Ascending/Descending Node conditions.**
Both classes in `Events/termConditions/@AscendingNodeTermCondition` and `@DescendingNodeTermCondition` implement neither `getEventTermCondFuncHandle` nor `initTermCondition`, yet are selectable in the UI and error at propagation. Implement as the sign change of the z-component of position in the selected frame (with direction), which also gives a "relative node with respect to a target orbit plane" if the frame is a user-defined geometric frame. Effort: S.

**A5. Event bypass flag, event copy/duplicate, action reordering, per-action exec node.**
KSP, Pro. Today: no way to skip an event without deleting it (`disableOptim` only freezes its variables), no copy/paste or duplicate of events (`grep copyEvent|duplicateEvent` finds nothing), `LaunchVehicleEvent` has add/remove but no `moveAction`, and `execActionsNode` is all-or-nothing per event. All four are small data-model additions with obvious UI hooks in the script list box context menu and the event editor. The bypass flag needs one branch in `LaunchVehicleScript.executeEvent`. Effort: S each.

**A6. Event groups / collapsible sections and per-event notes.**
KSP, Pro. Long missions become flat 60–100 line lists. A lightweight `groupName` string on `LaunchVehicleEvent` with collapse/expand in the list box (or a uitree replacing the list box) plus a per-event notes field costs little and greatly improves readability. Effort: M (uitree migration), S (notes only).

**A7. Loop safety and visibility for `SetNextEventAction`.**
KSP, Pro. Branching exists but is invisible in the script list and unguarded except for the 5-second wall-clock watchdog, which then silently pads unpropagated events with the final state. Add: a per-action `maxIterations` counter (error when exceeded), a "↺ → Event N" decoration in the list box, and a validator warning when a script contains loops. Also fix `Validators/scriptContainsSetNextEventAction.m` to recurse into `ConditionalAction` branches; today a `SetNextEventAction` inside a conditional (the natural "loop while X" pattern) is not detected, so incremental re-propagation stays enabled and can return stale results. Effort: S.

**A8. Non-sequential events: explicit enable toggle, priority order, logged discontinuities.**
Pro. Today "active" is only `numExecsRemaining > 0`; there is no priority when two fire in the same step; and `NonSeqEventTermCondIntTermCause` has the state-log append commented out, so an impulsive ΔV from a non-seq event never appears as a distinct log entry. Effort: S.

**A9. More ΔV frames for `AddDeltaVAction`.**
KSP, Pro. `DeltaVFrameEnum` has exactly two entries (inertial XYZ, NTW prograde/normal/radial). Add RSW/LVLH, VNB, body-fixed, and any user-defined geometric frame. Termination conditions already accept arbitrary `AbstractReferenceFrame` objects, so the plumbing pattern exists. Also expose the ΔV in polar form (magnitude, in-plane angle, out-of-plane angle) as an alternative parameterization for the optimizer; that is usually better conditioned than three Cartesian components. Effort: S.

**A10. Per-event overrides for min altitude and max duration; terrain-aware minimum altitude.**
KSP, Pro. `LvdSettings.minAltitude`, `simMaxDur`, and `maxScriptPropTime` are global, and `simMaxDur` is measured from script start (commented at `AbstractPropagator.odeEvents`). The min-altitude event uses `norm(r) - radius`, ignoring the terrain heightmap that `HeightAboveTerrainCondition` already interpolates. Add optional per-event overrides and a "use terrain" toggle. Effort: S.

**A11. NOT conditional and cross-event comparisons in conditional actions.**
Pro. `ConditionalTypeEnum` has AND/OR but no NOT; comparisons are always current state versus constant or current-state quantity. Add `LogicalNot` and an "at event N (initial/final)" option on `QuantityComparisonActionCondition`, mirroring `AbstractConstraint`'s StateComparison mode. Effort: S.

### B. Guidance, steering and throttle

**B1. Throttle model parity with steering: selectable math models.**
KSP, Pro. `GenericSelectableSteeringModel` lets each angle use sum-of-poly-terms, sum-of-sines, linear tangent, or `fitnet`; throttle has only const/lin/accel, T/W target, and a table. Add a `SelectableThrottleModel` wrapping the same `steering/math_models` classes (they are already time-only functions). Effort: S–M.

**B2. Dynamic-pressure-limited and acceleration-limited throttle laws.**
KSP, Pro. A "max-Q bucket" (throttle = min(commanded, throttle that holds q ≤ q_max)) and a "g-limit" law (throttle that holds |a| ≤ a_max, which `T2WThrottleModel` almost is) are standard launch-vehicle features. Both are closed-form per step from quantities already available in the ODE function (q from `getAtmoDensityAtAltitude`, current mass, thrust curve). Implement as *modifiers* wrapping an inner throttle model so they compose with any base law. Note the existing `editThrottleModifierProfileGUI_App` suggests a modifier concept already exists in the UI; make it a first-class model. Effort: M.

**B3. Pointing steering models (target-relative attitude).**
KSP, Pro. There is no prograde/retrograde/normal/radial-hold, no "point body axis at body / geometric point / ground object", no sun-pointing model. All are closed-form from the state, so they are strictly 3-DOF and cheap: build the DCM from a primary vector (chosen `VehicleStateVectorTypeEnum` or geometric vector) and a secondary constraint vector, exactly like `AlignedConstrainedCoordSys` already does for coordinate systems. Reuse that class to define a `PointingSteeringModel` whose base frame is an aligned-constrained coordinate system and whose angles are fixed offsets (optimizable). Also add LVLH/VNB as `ControlFramesEnum` entries. Effort: M.

**B4. Wire in Powered Explicit Guidance.**
KSP, Pro. `ForceModels/steering/@PoweredExplicitGuidance` is a full Teren-style PEG implementation with zero call sites. Expose it as a steering model (target apoapsis/periapsis/inclination or target orbit elements, cutoff via A2/A1 GA quantity termination condition), extend for yaw steering and multi-stage using the stage list already on the vehicle. This gives KSP players the closed-loop ascent guidance they use in kOS today and gives professionals a comparison baseline for optimized open-loop programs. Effort: M–L.

**B5. Ascent script generator (initial-guess wizard).**
KSP. Given launch site, target orbit, and the vehicle, auto-create a standard script: clamps release, vertical rise to v₀, gravity-turn pitch program (RPY polynomial per stage), staging events on tank-empty conditions, coast, circularization burn, plus matching constraints and a sensible objective. Everything it needs exists (`LaunchVehicleEvent.getDefaultEvent`, term condition factories, `createContinuityConstraints`). Removes the largest new-user hurdle and produces a good optimizer starting point. Effort: M.

**B6. C1 continuity and angular-acceleration limits for steering.**
Pro. Continuity flags today carry only the constant term across events (`setConstsFromDcmAndContinuitySettings`). An option to also carry the linear (rate) term removes attitude-rate discontinuities at event boundaries. Add body angular *acceleration* GA tasks and constraints next to the existing `BodyAngularVel*` ones so the optimizer cannot produce profiles that are unflyable even at the 3-DOF level. This constrains the parameterization, not a control law. Effort: S.

### C. Vehicle modeling

**C1. Separate tank capacity from initial mass.**
KSP, Pro. `LaunchVehicleTank.initialMass` doubles as capacity, so `fuelRemainPct` (which drives `FuelThrottleCurve`) is wrong for any partially filled tank, and crossfeed into a tank can exceed its physical volume. Add `capacity` with a validator. Effort: S.

**C2. Fuel flow priority and fractions on engine-to-tank connections.**
KSP, Pro. `getTankMassFlowRatesDueToEngines` splits mdot evenly over all connected non-empty tanks. KSP fuel priority (drain drop tanks first, then core) and real vehicles (sequenced drains) both need per-connection `priority` and optional `flowFraction`. Also allow `TankToTankConnection` flow rate to be "as fast as sink consumes" instead of a constant. Effort: S–M.

**C3. Engine transients: thrust ramp (spool) and ignition limits.**
KSP (RO/RealFuels users), Pro. A first-order thrust lag with `spoolTimeConstant` on `LaunchVehicleEngine`, applied in `getThrustFlowRateForPressure` via an engine "commanded vs. actual" state (one extra ODE state per engine or an algebraic ramp from ignition time), plus an `ignitionsRemaining` counter decremented by `SetEngineActiveStateAction`. The ramp affects insertion accuracy for short burns and is what makes kOS-executed profiles diverge from LVD predictions. Effort: M.

**C4. Propellant boiloff and a fuel-cell EPS source.**
KSP, Pro. Boiloff as a per-tank mass-proportional loss rate (`boiloffRate` fraction/s) added to `tankMdots` in `TotalForceModel.getForce`. Fuel cell as a `LaunchVehiclePowerSrc` that produces EC while draining a tank, since sinks/sources today are constant-rate only. Effort: S each.

**C5. Craft import completion.**
KSP. `lvd_import_analyzeCraft` skips EPS parts (batteries, panels, RTGs, alternators), aerodynamics, and any staging sequence. Add: EPS part mapping from the parts DB, a drag-area/Cd estimate from part sizes (feeds the 1-D drag model as a first guess), full `atmosphereCurve` import instead of the 2-point SL/vac inference, and optional generation of a skeleton script (one event per stage with a tank-mass termination condition, with staging actions), which would combine with B5. Effort: M.

**C6. Live vessel import over KSPTOTConnect.**
KSP. KSPTOTConnect already returns orbits and masses; the only remaining LVD hooks are in `_deprecated`. Pull the active vessel's stage/engine/tank/EC tree the same way the `.craft` pipeline does, so users can model the vehicle actually on the pad. Effort: M (requires a KSPTOTConnect plugin change too).

### D. Force models and environment

**D1. Wind profile.**
KSP (FAR/RSS users), Pro. Relative airspeed is exactly co-rotating body-fixed velocity everywhere. Add a `WindModel` on the aero state (altitude table of speed and direction in the local NED frame, optional gust multiplier) and subtract it in `DragForceModel`, `LiftForceModel`, and the wind-frame aero-angle computations (`computeWindFrame`). This is also the natural dispersion source for G2. Effort: M.

**D2. Aerodynamic heating and structural load indicators.**
KSP (reentry/aerocapture), Pro. Stagnation-point heat flux (Sutton–Graves, `q̇ = k √(ρ/rₙ) v³`), integrated heat load, stagnation temperature and pressure, q·α and q·β (bending-moment proxies), and axial/normal load factor in g, all as GA tasks. Every new GA task automatically becomes available as a termination condition (via A2), a constraint (via `GenericMAConstraint`), an extremum, and a calculus integral, so one computation serves four uses. Needs one `noseRadius` and `k` on the aero state. Effort: S.

**D3. Quick J2 without a coefficient file, and a J2 default for RSS bodies.**
Pro. Non-spherical gravity works, but only from a user-supplied harmonics file attached to the body, and it silently self-disables if the file is missing. Add `j2` (and optional `j3`, `j4`) scalar fields on `KSPTOT_BodyInfo`/`bodies.ini` and a closed-form zonal path in `GravityForceModel`, with a validation warning when a harmonics file is configured but not found. Effort: S.

**D4. User-tabulated lift model and un-hiding (or removing) the Kerbal Wind Tunnel drag models.**
KSP. Lift has a single model (KSP cylinder with hard-coded `physics.cfg` curves). A tabular Cl(Mach, AoA) model mirroring `KosDragCoeffientModel` gives FAR/wind-tunnel users a real lift capability. The two KWT drag models are complete but `enumeration(Hidden)`; either finish and expose them or delete them. Effort: S–M.

**D5. Penumbra for SRP and solar panels.**
Pro. `hasSunLoS` is a binary conical test. A partial-shadow factor (fraction of solar disc visible, cylindrical or conical) is a few lines in `AbstractLaunchVehicleSolarPanel.getExpensiveSolarPanelInputs` and improves both power and solar-sail fidelity for long-duration cases. Effort: S.

**D6. Terrain-aware ground contact.**
KSP (landing missions). `NormalForceModel` sticks the vehicle to a sphere. Use the heightmap that `HeightAboveTerrainCondition` already interpolates so landing/ascent scripts on Mun-like bodies terminate at the actual surface. Effort: S.

**D7. Time-dependent atmosphere when using the cached density grid.**
Pro. `createDensityGriddedInterp` bakes temperature at UT = 0 on a 100³ grid; the switch between cached and exact paths is implicit. Expose the choice per mission and warn when diurnal/seasonal effects are being dropped. Effort: S.

### E. Optimization

**E1. Single propagation per x for all solvers; single Jacobian pass.**
KSP, Pro. `CompositeObjectiveFcn.evalObjFcn` and `ConstraintSet.evalConstraints` each call `executeScript`. When incremental re-propagation is enabled and the script has no loops or plugins, the second call is served from cache (`resolvePropagationStartPoint` → `skipPropagation`). For looping scripts and any scenario with plugins the cache is disabled and every x costs two full propagations. Add an x-keyed state-log cache at the `LvdOptimization` level (NOMAD already does this with globals), and stop `evalConstraintsWithGradients` from computing the full constraint Jacobian twice (once for `DC`, once for `DCeq`). Also make it honour the user's finite-difference settings instead of hard-coded `h = 1e-5`, forward, 2-point. Effort: S–M, large speedup for gradient solvers.

**E2. Constraint Jacobian sparsity and unified parallel FD.**
Pro. IPOPT's `jacobianstructure` is declared dense; the objective has a sparsity mask but constraints do not. Detect constraint sparsity at x0 the same way (`getXElementEvtNums` already tells which event owns each x element, so any constraint evaluated at event k is structurally independent of variables owned by events > k), and route all FD Jacobians through `computeGradAtPoint` so "parallel" means the same thing for every solver. Effort: M.

**E3. One-sided constraints and better failure semantics.**
KSP, Pro. FixedBounds always emits both lower and upper inequalities; a bound of ±Inf yields an `Inf` residual. Add explicit ≤ / ≥ / = modes. Separately, `ConstraintSet.evalConstraints` returns scalar `c = NaN; ceq = NaN` on propagation failure (wrong length), `CompositeObjectiveFcn` returns `NaN` with the error swallowed, and `GenericMAConstraint` returns `0` on evaluation failure (silently "satisfied"). Return correctly sized NaN vectors and surface the message in the output window. Effort: S.

**E4. Variable table and constraint status table.**
KSP, Pro. There is no single place to see all optimization variables (value, bounds, active, owning event) or all constraints (value, bounds, violation, scale factor); constraint values are visible only in tooltips and a validator warning. `lvd_adjustOptVarGUI_App` covers value sliding but tells the user to reopen it if the variable set changes. Add a dockable table for each, with inline editing of bounds/active flags and color-coded violation, listening to the `VarsListUpdated*` events that already fire. Mission Architect has a `ConstraintDetails` window that serves as a pattern. Effort: M.

**E5. Linked variables and variable groups.**
Pro. No way to tie two variables together (e.g. same pitch rate for two boosters, or "stage 2 initial pitch = stage 1 final pitch + Δ"). A `LinkedVariable` that maps one x element to several targets through affine relations, plus UI in the variable table, would cut problem dimension for symmetric vehicles and multi-burn sequences. Effort: M.

**E6. Solution snapshots, multi-start, and continuation helper.**
Pro. The scorecard lets the user pick final / lowest-f / lowest-violation iterates, but nothing persists x across sessions except the mission file itself. Add named x snapshots stored on `LvdOptimization`, a "multi-start from N perturbed x0 in parallel, keep best" runner using the existing `perturbVar` machinery and `parfeval`, and a continuation mode that ramps a chosen constraint's bounds from the current value to the target in k steps, re-optimizing each step. All reuse `consoleOptimize`. Effort: M.

**E7. Per-constraint history and objective sensitivity display.**
Pro. `ma_OptimRecorder` stores only fval and max violation per iteration. Record the full constraint vector, plot individual violations over iterations in the observe window, and offer a tornado chart of objective and constraint sensitivities from the existing Jacobian heat-map computation. Effort: S–M.

**E8. Objective evaluation at the initial node and at extrema.**
Pro. `GenericObjectiveFcn` supports `eventNode` in the underlying constraint but the UI exposes only the final state. Expose it, and allow the objective to be an `ExtremumValueConstraint` or `CalculusCalculationValueConstraint` (e.g. minimize peak q, minimize ∫q dt). Effort: S.

**E9. Multi-objective via weighted or ε-constraint sweeps in the Case Matrix.**
Pro. Rather than adding a Pareto solver, let a Case Matrix sweep the composite-objective scale factors or a constraint bound (see G1) and collect the resulting objective values; a Pareto front falls out with the existing optimizer. Effort: S once G1 exists.

**E10. Path constraints with smooth aggregation.**
Pro. Constraints evaluate only at an event's initial or final node (`ConstraintStateComparisonNodeEnum`); "q ≤ q_max over the whole burn" is done today with an extremum recorder, which is non-smooth for gradient solvers. Add a `PathConstraint` evaluation type on `AbstractConstraint` that samples the event's state-log entries and aggregates with a Kreisselmeier–Steinhauser or p-norm function (user-selectable ρ), returning one smooth scalar. Works for any GA quantity through `GenericMAConstraint`. Effort: M.

**E11. Infeasibility diagnostics.**
KSP, Pro. When a run fails to converge, report variables with all-zero Jacobian columns (no effect on anything), constraints with all-zero rows (unaffected by any variable), and Jacobian rank and condition number. The heat map already computes the matrix; this is interpretation layered on it, presented in the scorecard. Effort: S.

### F. Analysis, geometry and output

**F1. B-plane targeting quantities and constraints.**
Pro (and KSP gravity-assist designers). B·T, B·R, |B|, θ, and the incoming v∞ vector relative to a selected target body are absent. Add them as GA tasks (target body chosen through the task's frame or a new "target body" task parameter) and they become constraints via `GenericMAConstraint` and objectives via `GenericObjectiveFcn`. This is the standard way to formulate flyby and arrival targeting in POST/GMAT-class tools and complements the existing continuity-constraint workflow for MFMS imports. Effort: S–M.

**F2. Additional GA quantities.**
KSP, Pro. Present already: T/W, C3, β angle, eclipse, Mach, q, ground-object az/el/range, AoA. Missing and cheap: specific orbital energy, specific angular momentum, argument of latitude / true longitude, apsis latitude and longitude, sensed acceleration (total, axial, normal, in g), cumulative ΔV expended (∫T/m dt, with per-event and per-stage splits), remaining ΔV capability from the rocket equation using current mass and active-engine Isp, per-engine thrust/Isp/mass flow, ground-object range rate and elevation rate, sun phase angle, penumbra fraction (after D5), heating indicators (D2), downrange distance from launch site. Effort: S per group.

**F3. ΔV budget report.**
KSP, Pro. Mission Architect has one; LVD does not. Per event and per stage: impulsive ΔV from `AddDeltaVAction`, finite-burn ideal ΔV, and loss breakdown (gravity, drag, steering) computed from the state log by integrating the acceleration components against the velocity direction. Effort: S–M.

**F4. Contact and access intervals for ground objects and sensors.**
Pro. Ground-object LoS and sensor coverage exist only as per-timestep booleans (GA task, Excel sheet). Add interval extraction (rise/set UT, duration, max elevation, gap and revisit statistics), an aggregate "any station in view" quantity, a per-object minimum-elevation mask, and a `GroundObjLoSConstraint` (LoS is already a GA quantity but not a constraint). Effort: M.

**F5. Sensors as optimization quantities.**
Pro. Sensors contribute zero GA tasks or constraints (verified: no "sensor" match under `Optimization` or `process_data`). Expose "target in FOV" boolean per target, instantaneous and cumulative coverage fraction, and boresight angle as GA tasks, so sensor pointing and orbit design can be optimized, not just reported. Effort: M.

**F6. Geometry additions.**
Pro. Unit-vector and vector-sum objects, dot-product scalar (as an "angle"-class scalar), point-to-plane distance, vector–plane intersection point, dihedral angle between planes, a "frame from three points / from two vectors" reference frame, and a CSV-ephemeris point (time-tagged r,v in a chosen frame) so external targets can be imported. `LvdDataPoint` already handles other LVD cases; the ephemeris point is the same interface. Effort: S–M.

**F7. Graphical Analysis output and comparison.**
KSP, Pro. Export is CSV only; add Excel and copy-to-clipboard, a state-log table viewer (MA has `viewStateLog`), and a multi-run overlay mode that loads one or more saved cases and plots the same tasks on shared axes (nominal versus variant). Replace the silent `-1` sentinel written by `LvdGraphicalAnalysis.executeTasks` on evaluation failure with `NaN` plus a warning list. Add "event-relative time" and "downrange distance" as independent variables. Effort: S–M.

**F8. 3-D view: playback, video export, camera follow, colour-by-quantity.**
KSP. The time slider works but there is no play button, no `VideoWriter`/GIF export anywhere in LVD, no chase-camera mode, and no colouring of the trajectory by a GA quantity (altitude, throttle, q). All are view-profile options on top of `Generic3DTrajectoryViewType` and the existing marker-update path in `timeSliderStateChanged`. Add an "export image" button while there. Effort: M.

**F9. Ephemeris export.**
Pro. A CSV/CCSDS-OEM-style state ephemeris export (UT, r, v in a chosen frame, uniform step via the existing `integratorStepSize` or resampled by interpolation) for hand-off to other tools. Effort: S.

**F10. Instantaneous impact point trace.**
Pro (range safety), KSP (booster recovery). `TwoBodyImpactPoint*` exist as GA tasks and endpoint constraints. Plot the IIP locus on the 2-D ground-track view as the vehicle flies, optionally with a drag-inclusive impact estimate, and allow a lat/long keep-out polygon as a path constraint (via E10). Effort: S–M.

**F11. Launch window and azimuth tool.**
KSP, Pro. `computeLaunchWindows.m` lives only under `ksptot_ma/launch_window/`. Give LVD a dialog that, for a target plane (inclination and RAAN, or a target object's orbit from a geometry point), solves launch UT and azimuth for the current launch site and writes them into the initial state (or the initial-state variable bounds). Pairs with B5. Effort: S–M.

### G. Trade studies and robustness

**G1. Case Matrix over any parameter.**
KSP, Pro. `LvdCaseMatrixTaskParameter` pins plugin variables only, so sweeping T/W, stage dry mass, pitch-program coefficients, a constraint bound, or launch epoch requires first wiring each through a plugin variable. Generalize the parameter to any `AbstractOptimizationVariable` element (temporarily deactivating it, exactly as is done for plugin vars), to any constraint bound, and to a set of "vehicle knobs" (engine thrust/Isp multipliers, stage dry mass, tank mass, `globalDragMultiplier`). Add Latin-hypercube and random sampling alongside full factorial, a propagate-only mode (no optimization) for fast surveys, MAT output alongside Excel, and a simple carpet/scatter plot viewer. Fix the `LvdCaseMatrixTask.lvdData` load-on-every-read accessor while there. Effort: M–L.

**G2. Monte Carlo dispersion analysis.**
KSP, Pro. Built on G1's random sampling: define distributions (normal/uniform/triangular) on the vehicle knobs, initial-state elements, wind (D1), and Cd; run N propagate-only samples in parallel; report percentiles of any GA quantity at any event (insertion error ellipses, ΔV margin, max-q, landing footprint). Most of the plumbing is G1; the new pieces are the distribution objects, the seed handling, and a statistics viewer. Effort: M on top of G1.

**G3. Sensitivity report.**
Pro. The Jacobian heat map computes everything needed for a tornado chart of constraints and objective versus variables; add the chart and a CSV export of the Jacobian. Effort: S.

**G4. Jettisoned-stage child trajectories and engine-out sweeps.**
KSP, Pro. The script propagates one state. A `SetStageActiveStateAction` that deactivates a stage could optionally spawn a child `LvdData` seeded from that state with the discarded stage's mass and a chosen drag model, propagated ballistically after the main run (never inside the optimizer loop) to give splashdown/impact points and, with G2, a debris footprint. Engine-out survivability is a Case Matrix sweep (G1) over the time of a `SetEngineActiveStateAction` with re-optimization of the remainder; no new engine code is needed. Effort: M–L.

### H. Workflow and quality

**H1. Script templates.**
KSP. "New from template": two-stage-to-orbit, gravity-turn ascent, Hohmann transfer, flyby with continuity constraints, powered landing, halo-orbit insertion. Templates are just `.mat` cases with documented variables, shipped in `examples/` and surfaced in the File menu. Effort: S.

**H2. Autosave and crash recovery.**
KSP, Pro. Undo/redo exists in memory only; there is no autosave (`grep -i autosave` finds nothing). Write a timestamped recovery file on a timer and after each optimization run, and offer it on startup. Effort: S.

**H3. Headless batch runner.**
Pro. A `lvd_runCaseHeadless(matPath, opts)` function (propagate, optionally optimize, write GA CSV and updated `.mat`) usable from the in-app console and from MATLAB scripts, enabling regression and scripted studies without the GUI. Most pieces exist in `LvdCaseMatrixTask.runTask`. Effort: S.

**H4. Mission diff.**
Pro. Compare two `.mat` cases and list differences in vehicle, script, variables, constraints, and settings. Useful for reviewing optimizer changes and for team work. Effort: M.

**H5. Halo Orbit Constructor hand-off and CR3BP initial states.**
Pro. The constructor computes a manifold state but only fills fields in its own Results tab; the user must copy numbers by hand. Add "Use as initial state" and "Create geometric point". Related: `InitialStateModel.set.orbitModel` errors on legacy `CR3BPOrbitStateModel` and `ElementSetEnum` has no CR3BP entry, so CR3BP initial states are unreachable in new files. Add a CR3BP element set. Effort: S–M.

**H6. Validators for silent failure modes.**
KSP, Pro. Add checks for: engine with no connected tank (zero thrust with no warning), tank feeding nothing, engine active on an inactive stage, throttle below `minThrottle`, zero or negative dry mass, EC exhausted with electric engines commanded on, lift model with zero area, GA task returning the failure sentinel, harmonics file missing (D3), loops present (A7), stub termination conditions selected (A4). Each validator is a ~30-line class under `Validation/Validators`. Effort: S.

**H7. Plugin improvements.**
Pro. Plugin code is inline text executed with `eval` under a keyword blacklist that also blocks legitimate `load`; there is no way to reference a `.m` file, and no plugin hook for a custom force, steering, or throttle law (only observation and value return). Add file-backed plugins, an allow-listed data-load helper, and `CustomForce`, `CustomSteering`, `CustomThrottle` exec locations that return a force vector or DCM/throttle. Also fill in `PluginConstraint`'s missing unit. Effort: M.

**H8. Search, filter, and tagging in the large list boxes.**
KSP, Pro. Events, constraints, variables, geometry objects, and GA tasks all live in flat list boxes. The GA task picker already has a search field (`SearchTaskText`); give the same treatment to the constraints, variables, and geometry dialogs, and allow free-text tags on events and constraints that the filter honours. Effort: S.

**H9. Defects worth fixing alongside the above.**
Found during the review; each is small. *Status 2026-09-15: all items below have been fixed, with regression tests in `tests/lvd_tests` (EventReferenceTrackingTest, KosExportTest, LvdCodebaseHygieneTest, KwtDragSliceTest, plus additions to IntegratorTest, SteeringThrottleModelTest, OptimizationVariableTest, EventActionTest). Example-case propagation was verified bit-identical before and after. Note on the aliasing item: SetKinematicStateAction also returns a fresh object by design; ConditionalAction was brought in line with the simple actions rather than the other way round, because deep-copying every action would have changed the logged intermediate states of existing missions.*
- `deleteEvent_Callback` checks `evt.usesEvent(evt)` (does the event reference itself) instead of scanning other sequential and non-sequential events; `advanceScriptToSelectedEventMenu_Callback` does the cross-check correctly and is the pattern to copy. `SetNextEventAction` also lacks a `usesEvent` override, so its target can be deleted.
- `ConditionalAction` overrides none of the `usesX` predicates, so a stage/tank/engine referenced only inside a branch can be deleted; its `removeActionVariables` references a non-existent `lvdData` property.
- `SetKinematicStateAction.usesEvent` ignores stage, engine, and EPS sink/source inherit-from-event links; `LaunchVehicleNonSeqEvents.usesCalculusCalc` calls `usesExtremum`.
- Actions return the incoming handle (`newStateLogEntry = stateLogEntry`), so an N-action event appends N aliases of one object to the state log; `ConditionalAction` deep-copies, making behaviour inconsistent.
- `ThrottleInterpolatedModel.setTimeOffsets` references a property that does not exist.
- `OptimizationVariableSet.getTypicalScaledXVector` takes `log10` of negative scaled bounds; variables with `lb == ub` bypass the [-1,1] scaling and mix raw magnitudes into x.
- `ObjectiveFunctionEnum` and `CompositeObjectiveFcn.upgradeExistingObjFuncs` reference three objective classes that no longer exist.
- `Simulation/ode/` is a superseded duplicate of the propagator logic (no SRP or EPS states, calls a removed driver member, contains a `disp('STOP!')`).
- `AbstractFixedStepIntegrator.stepOnce` hard-codes the ODE5 tableau ("needs to be generalized"), and `ODE5Integrator.integrate` discards its own options object.
- `ThreeDimKWTDragCoefficientModelSlice.isAxisMonotonicallyIncreasing` always returns true.
- The kOS export requires hand-editing `fPath` in `exec_lvd_control.ks`; write the `.ks` alongside the CSV with the path filled in.

---

## 3. Recommended priorities

**Tier 1: high value, low-to-medium effort, purely additive.**
A1 multiple termination conditions · A2 GA-quantity termination condition · A5 bypass/duplicate/reorder · A9 ΔV frames · B2 q-/g-limited throttle · C1 tank capacity · C2 fuel priority · D2 heating and load indicators · E1 single propagation and single Jacobian pass · E3 one-sided constraints and failure semantics · E4 variable/constraint tables · E11 infeasibility diagnostics · F1 B-plane · F2 GA quantities · F3 ΔV budget · H2 autosave · H6 validators · H8 search/filter · H9 defects.

**Tier 2: substantial capability, medium effort.**
A3 Nth crossing · A6 groups · A7 loop safety · B1 selectable throttle models · B3 pointing steering · B4 PEG · B5 ascent wizard · B6 angular-acceleration limits · C3 engine transients · C5 craft import completion · D1 wind · D3 quick J2 · E2 sparsity · E6 snapshots/multi-start/continuation · E10 path constraints · F4 contact intervals · F5 sensor quantities · F7 GA output/overlay · F8 view playback/export · F10 IIP trace · F11 launch window tool · G1 generalized Case Matrix · H1 templates · H3 headless runner · H5 halo hand-off/CR3BP.

**Tier 3: larger investments that build on Tier 2.**
G2 Monte Carlo (needs G1, D1) · G4 child trajectories and engine-out sweeps · E5 linked variables · E9 Pareto sweeps (needs G1) · H7 plugin force/steering hooks · H4 mission diff · C6 live vessel import.

**Suggested first release bundle.** A1 + A2 + A5 + A9 (event model), E1 + E3 + E4 (optimizer usability and speed), F1 + F2 + F3 (analysis), C1 + C2 (vehicle fidelity that fixes wrong answers today), and H6 + H9 (robustness). Together they change the day-to-day experience for both audiences without touching the simulation core.
