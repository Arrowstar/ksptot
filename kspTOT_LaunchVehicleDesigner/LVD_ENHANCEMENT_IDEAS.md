# Launch Vehicle Designer — Capability Review and Enhancement Ideas

Survey of `helper_methods/ksptot_lvd/` (model/engine) and `kspTOT_LaunchVehicleDesigner/`
(App Designer UIs), followed by proposed new functionality.

Scope note: LVD is a **3DOF trajectory design tool**. Suggestions below deliberately exclude
6DOF concerns (attitude dynamics, guidance/autopilot algorithms, control law design).

Date of review: 2026-08-27

---

## Part 1 — Existing Functionality

### Core architecture

`LvdData` (`classes/@LvdData/LvdData.m`) is the root aggregate:
`script` (events), `launchVehicle`, `initStateModel`, `stateLog`, `optimizer`, `geometry`,
`groundObjs`, `sensors`/`sensorTgts`, `graphAnalysis`, `viewSettings`, `plugins`/`pluginVars`,
`validation`, `settings`, `celBodyData`.

Execution is **explicit shooting**: `LaunchVehicleScript` is an ordered list of
`LaunchVehicleEvent`s, each with its own propagator, integrator, termination condition, and
action list. Results accumulate into a `LaunchVehicleStateLog` of `LaunchVehicleStateLogEntry`
objects.

### Vehicle model

- Stages -> engines + tanks + dry mass; EPS (power sources/sinks/storage per stage)
- Engines: thrust-vs-pressure curve, Isp-vs-pressure curve, fuel/throttle curve, min/max
  throttle, body-frame thrust vector, alternator output and EC draw
- Tanks: fluid types, tank<->tank connections, engine<->tank connections (all toggleable
  mid-flight via actions)
- Auxiliary state: stopwatches, extrema recorders (running max/min of any quantity), calculus
  objects (running derivative and integral of a quantity), hold-down clamps

### Force models (`ForceModels/`)

Point-mass gravity with optional **spherical harmonics** (C/S coefficients from file,
selectable max degree) - third-body gravity - thrust - drag - lift - normal force - SRP
(spherical and **solar sail**).

Drag coefficient models: constant CdA, 1-D table against any of {altitude, body-fixed velocity,
pressure, density, dynamic pressure, **Mach**}, 2-D and 3-D Kerbal Wind Tunnel tables, kOS
model. Lift: cylindrical + coefficient curves.

### Steering and throttle

Seven steering models — RPY polynomial, body-fixed aero-angle polynomial, inertial aero-angle
polynomial, generic-angle polynomial, quaternion interpolation (spline + tabular), and a
"generic selectable" model where each of the three angles independently picks
polynomial / sum-of-sines / linear-tangent / **fitnet neural net**, with per-angle continuity
flags. Control frames: inertial, NED, wind, plus arbitrary user reference frames.
`PoweredExplicitGuidance` also exists. Throttle models: polynomial, interpolated table,
T/W-hold.

### Events

- **26 termination conditions**: altitude, apo/peri altitude, asc/desc node, dynamic pressure,
  duration, FPA, height-above-terrain, latitude, longitude, net charge rate, sea-level T/W,
  SoI transition, stopwatch, tank mass, throttle, state-of-charge, true anomaly, plus
  AoA / sideslip / bank / pitch / roll / yaw
- **~35 actions**: delta-V, add mass, set engine/stage/tank-conn/clamp state, set steering
  model, set throttle model, set kinematic state, **set next event** (branching), sensor
  state/steering/angles, power src/sink/storage, plugin variables, extrema, stopwatches,
  aero/SRP property swaps, and conditional wrappers
- **Non-sequential events**: interrupt-style events with bounding events and max-execution
  counts
- Per-event forward/backward propagation, per-event integrator
  (ODE45/113/78/89/23/23s/15s/RKN1210/ODE5) and tolerances, SoI transition detection, and
  typed termination causes

### Geometry engine (`Geometry/`)

A full geometry stack: points (celestial body, fixed-in-frame, ground object, **Lagrange
point**, two-body, vehicle-relative), vectors, planes (three-point, point-vector), angles
(two-vector, vector-plane), coordinate systems (aligned-constrained, parallel-to-frame,
parallel-to-frame-at-time), reference frames. Ground objects support waypoints (moving sites).
Sensors: conical and rectangular with their own steering, against point / lat-long-grid /
circle-grid targets, producing coverage reports (az, el, range, boresight angle) to CSV.

### Optimization (`Optimization/`)

- **~45 variable types**: initial state in Cartesian/Keplerian/geographic/universal element
  sets, event durations, termination-condition values, every steering and throttle model's
  coefficients, tank initial masses, stage dry mass, delta-V action components, stopwatches,
  plugin variables
- **~42 constraint classes** plus `GenericMAConstraint`, which exposes the ~75 Mission
  Architect dependent variables (orbital elements, C3, equinoctial, relative-orbit RIC terms,
  solar beta, eclipse, Mach, dynamic pressure, atmospheric state, etc.). Constraints evaluate
  at an event's **initial or final state**, with either fixed bounds or **state-to-state
  comparison** between two events
- Objectives: min distance to body, max vehicle mass, generic (any constraint quantity), and
  composite (Sum / RSS / Max / Min)
- **Seven optimizers**: fmincon, SQP, IPOPT, NOMAD (MADS), patternsearch, surrogateopt,
  Adam/NLopt. Gradient methods: built-in FD, custom FD, DERIVest. Parallel gradient support
- Tooling: constraint auto-scaling (by value or by Jacobian), **Jacobian heat map**, variable
  perturbation, auto-generated continuity constraints, near-bounds validators

### Analysis and output

3D trajectory view + 2D ground track with view profiles (bodies, vectors, points, planes,
frames, sensors, sun lighting/terminator, skybox, camera control, time slider) - graphical
analysis (multi-task plots of ~75 dependent variables, subplots, tabular text) - **case
matrix** parametric sweeps over plugin variables with warm-start ordering and retry logic -
plugin system (user MATLAB functions with exec locations and optimization variables) -
undo/redo - validation framework - mission notes - console app - kOS control CSV export -
CSV state export - MFMS import - KSP `.craft` import - halo orbit constructor -
impulsive-to-finite-burn conversion.

### Assessment

This is a remarkably complete general-purpose 3DOF trajectory design environment. It is
stronger than most comparable tools in geometry, event scripting, and steering
parameterization. The gaps are concentrated in four areas: **statistical analysis**, **path
constraints and load indicators**, **atmospheric environment**, and **workflow/reporting**.

---

## Part 2 — Proposed New Functionality

### Tier 1 — Biggest capability gaps

#### 1. Monte Carlo / dispersion analysis

There is no `montecarlo`, `dispersion`, or `covariance` anywhere in the LVD tree. Add
distribution definitions (normal, uniform, triangular, tabular) on initial state, Isp, thrust,
dry mass, propellant load, CdA, atmospheric density, and ignition timing; run N samples in
parallel; report statistics, histograms, scatter plots, and 3-sigma ellipses on any dependent
variable or constraint quantity.

*Leverage*: the Case Matrix infrastructure (`LvdCaseMatrix`, `LvdCaseMatrixTask`, parallel
execution, retry logic) is roughly 70% of the required plumbing. This is largely a new sampling
front-end plus a statistics/plotting back-end.

#### 2. Load-indicator quantities: q-alpha, load factor, heating

Grepping for `qalpha`/`qbar` returns nothing. Dynamic pressure exists, but the quantities that
actually size a launch vehicle do not:

- q*alpha and q*beta (bending moment proxies)
- Axial and lateral load factor (sensed acceleration, in g)
- Free-molecular heating rate (Qdot = k * sqrt(rho) * V^3)
- Integrated heat load
- Max sensed acceleration

Each needs to appear in four places at once — as a graphical-analysis dependent variable, an
extremum-recordable quantity, a constraint, and a termination condition. The
`LaunchVehicleExtrema` and `AbstractConstraint` patterns make each addition mechanical once the
underlying computation exists.

#### 3. Wind

`DragForceModel.getForce` computes drag from `vVectECEF` only — a rotating-atmosphere
assumption with no wind term. Add altitude-tabulated wind profiles (u/v vs. altitude), wind
shear and discrete gust models, and monthly/seasonal profile libraries. This propagates into
relative velocity, AoA, dynamic pressure, and q-alpha, and is the single largest fidelity gap
for day-of-launch analysis. Pairs naturally with #1 (wind dispersions) and #2 (q-alpha limits).

#### 4. True path constraints

Constraints today evaluate only at `InitialState` or `FinalState` nodes of an event
(`ConstraintStateComparisonNodeEnum`). Extremum recorders provide a workaround for max/min, but
there is no first-class "enforce q <= q_max over this whole interval." Add a path-constraint
type using either interior sampling nodes or a smooth aggregation (KS / p-norm). Smooth
aggregation is also better-behaved for the gradient optimizers than the current extremum
approach.

#### 5. Analytic gradients via variational equations

All three gradient methods (`BuiltInGradientCalculationMethod`,
`CustomFiniteDiffsCalculationMethod`, `DERIVEstFiniteDiffsCalculationMethod`) are finite
differences, meaning N+1 full script propagations per Jacobian. Propagating a state transition
matrix alongside the state — or complex-step differentiation through the force models — would
give exact derivatives at a fraction of the cost and substantially improve fmincon/IPOPT
convergence on hard problems.

---

### Tier 2 — High value, moderate effort

#### 6. Optimizer dashboard and run history

Live plots of objective, max constraint violation, and variable values vs. iteration;
pause/resume; snapshot and restart from any iterate; save and diff optimization runs. Today the
user gets status text and a post-hoc Jacobian heat map.

#### 7. Multi-start and homotopy

Latin-hypercube seeding across variable bounds with parallel solves, keeping the best; and
continuation, where a constraint bound or force-model term is ramped in gradually. Both are
thin wrappers over the existing `lvd_executeOptimProblem` driver.

#### 8. Payload / performance curve generation

Automated re-optimization sweeps producing payload-vs-altitude, payload-vs-inclination, and
payload-vs-C3 curves, plus Pareto fronts (e.g. payload vs. max-q limit). Case Matrix can sweep
parameters but does not re-optimize per case.

#### 9. Multi-body / jettisoned-stage propagation

The state log tracks a single vehicle. Spent stages, fairings, and boosters should spawn child
trajectories with their own drag and mass properties, giving splashdown/impact points and —
combined with #1 — debris footprint ellipses.

#### 10. Range safety

`TwoBodyImpactPointLatitude/Longitude/Time` constraints exist as endpoint constraints. Extend
to a continuous instantaneous impact point (IIP) trace overlaid on the 2D ground track, IIP
computed with drag, and keep-out polygon / destruct-line constraints for overflight exclusion
zones.

#### 11. Launch window and azimuth targeting

`computeLaunchWindows.m` lives only under `ksptot_ma/launch_window/`. LVD should have its own
launch-window tool: given a target plane (inclination + RAAN, or a target object's orbit),
solve for launch time and azimuth, and sweep the window reporting the performance penalty at
each opening.

#### 12. Mission report generator

Publish a PDF/HTML report: event table, per-event delta-V budget, mass statement with margins,
propellant consumption per tank, key event conditions, and selected plots. Currently the only
summary is the "Final Spacecraft State" readout, and export is raw CSV.

#### 13. Standard-format ephemeris exchange

Export CCSDS OEM/OMM, STK `.e`, SPICE SPK, GMAT script, and CZML (Cesium); import target
ephemerides in the same formats. Today the only external interfaces are kOS CSV and KSP
`.craft`.

---

### Tier 3 — Fidelity and refinement

#### 14. Engine transients

Thrust build-up and tail-off profiles, throttle rate limits, minimum impulse bit, start/stop
delays. Currently throttle changes are instantaneous.

#### 15. Engine-out analysis

Fail engine *k* at time *t* and re-optimize the remainder; sweep failure times to build a
survivability envelope. Builds directly on the existing `SetEngineActiveStateAction` and the
branching `SetNextEventAction`.

#### 16. Propellant boiloff and settling

`LaunchVehicleTank` has only `initialMass` and a fluid type — no boiloff. Add heat-rate /
time-based boiloff and ullage burn modeling for long upper-stage coasts.

#### 17. Conical shadow model for SRP

`SphericalSolarRadiationPressureModel` uses a boolean `hasSunLoS`. A proper umbra/penumbra
model with a smooth shadow function would improve both SRP accuracy and — importantly — the
smoothness of integration through terminator crossings.

#### 18. Importable atmosphere tables

Atmosphere comes from KSP-style pressure/temperature curve fits on `KSPTOT_BodyInfo`. Support
importing tabulated density/pressure/temperature/speed-of-sound profiles (US Std 1976,
GRAM-style monthly means, or measured soundings) with density dispersion multipliers.

#### 19. Steering rate limits

Body angular velocity constraints exist (`BodyAngularVelX/Y/Z`,
`TotalBodyAngularVelConstraint`). Add angular *acceleration* constraints and rate-limited
steering parameterizations so the optimizer cannot produce profiles that are un-flyable even at
the 3DOF level. This is a constraint on the parameterization, not a guidance law.

#### 20. Terrain clearance

`HeightAboveTerrainCondition` exists and bodies carry heightmaps. Add a terrain-clearance path
constraint and a terrain-profile-along-ground-track plot.

---

### Tier 4 — Workflow and usability

#### 21. Text-based mission file format

Cases are `.mat`, which cannot be diffed, merged, or code-reviewed. A JSON/YAML serialization
would make missions version-controllable — significant for a tool with this much configuration
state.

#### 22. Headless scriptable API

The console app exists; formalize a documented programmatic API and CLI runner so cases can be
built, run, and optimized from scripts and CI without the GUI.

#### 23. Case comparison / diff

Load two cases and overlay their graphical-analysis plots and event tables with delta
reporting. Becomes essential once #8 and #1 start generating case families.

#### 24. Mission templates

A wizard for common architectures (e.g. two-stage-to-orbit from a named site to a target orbit)
that auto-builds the event sequence, steering models, variables, and constraints. The current
empty-case starting point is a steep ramp.

#### 25. Search, filter, and tagging in the large lists

Constraints, variables, geometry objects, and events all live in flat listboxes that become
unwieldy on realistic problems.

#### 26. Infeasibility diagnostics

When the optimizer fails, report which constraints are mutually unsatisfiable, which variables
have no effect on any constraint (zero Jacobian columns), and Jacobian rank/conditioning. The
Jacobian is already computed for the heat map — this is interpretation layered on existing
data.

---

## Recommended starting point

If limited to three: **Monte Carlo (#1)**, **q-alpha / load-factor / heating quantities (#2)**,
and **wind (#3)**. They are mutually reinforcing, they close the largest gap between LVD and
professional launch vehicle trajectory tools, and #1 in particular reuses a large amount of the
Case Matrix machinery that already exists.
