# Launch Vehicle Designer (LVD) — Deep Dive & Enhancement Roadmap

## Part 1: What LVD Does Today

LVD (`kspTOT_LaunchVehicleDesigner/` + engine code in `helper_methods/ksptot_lvd/`) is an event-scripted, force-model-integrating launch/spacecraft mission design tool with embedded trajectory optimization.

### Vehicle Modeling
- **Stages/engines/tanks** with pressure-dependent thrust/Isp curves, fluid types, engine-tank connections
- **Tank-to-tank connections** = propellant crossfeed → asparagus staging (see `examples/LaunchVehicleDesigner/lvdExample_ComplexDrag_AsparagusStaging.mat`)
- **Electrical Power System**: sinks, fixed/rotating solar panels, RTGs, batteries, state-of-charge tracking
- Stopwatches, extrema recorders, calculus objects (integrals/derivatives of logged quantities)

### Simulation Engine
- **3 propagators**: two-body, second-order grav-only, full force-model; SoI transitions auto-create events; forward/backward propagation
- **10 integrators**: adaptive ODE23/23s/45/113/15s + fixed-step ODE5/ODE78/ODE89/RKN1210
- **Force models**: gravity (+ non-spherical), third-body, drag (constant / 1-D / 2-D / 3-D "Kerbal Wind Tunnel" CSV slices / kOS-derived), lift, normal force, SRP (spherical + solar sail)
- **~30 event actions** incl. conditional AND/OR logic trees; **~25 termination conditions** (attitude angles, q-bar, lat/lon, tank mass, SoI, EPS charge…); non-sequential (concurrent) events

### Guidance & Control
- **12 steering models**: linear tangent, polynomial, sum-of-sines, quaternion interpolation (generic + tabular), RPY/aero-angle polynomials in inertial/NED/wind frames, FitNet neural net, and the recently added **PEG** (`classes/ForceModels/steering/@PoweredExplicitGuidance`)
- Throttle: T2W-targeted, tabular-interpolated, polynomial; hold-down clamps

### Optimization & Analysis
- **8 solvers** (fmincon, IPOPT, NOMAD+DiscoMADS surrogate, pattern search, surrogate opt, custom SQP w/ user gradients, AdamNLOpt) × gradient methods (built-in, custom FD, DERIVEST)
- ~50 optimization variable types, ~40 constraint types, continuity constraints between events, composite weighted objectives
- **Case Matrix** batch runner with parallel workers and plugin-variable sweeps
- **Graphical Analysis**: hundreds of quantities vs. any independent variable; constraint Jacobian heatmap; 13 pre-run validators
- Geometry suite (points/vectors/planes/angles/frames, Lagrange points), ground objects, sensors (conical/rect FOV) vs. targets (point/grid) visibility reports
- Halo Orbit Constructor (Richardson + differential correction + manifolds), MFMS multi-flyby import, kOS open-loop control export, plugin system with optimizable plugin variables

## Part 2: Proposed New Functionality

Gaps verified against the codebase (e.g., no Monte Carlo/heating anywhere):

### High Value
1. **Monte Carlo dispersion analysis** — extend Case Matrix to sample stochastic dispersions (mass, Isp, thrust ramp-up, wind, Cd error, initial state errors). Report insertion accuracy scatter, ΔV margins, percentiles. Currently only deterministic sweeps exist.
2. **Aerodynamic heating model** — stagnation-point heat flux/heat load as GA tasks + constraints (q̇ limits on ascent/reentry). Pairs with existing q-bar termination.
3. **Automated launch/insertion planner** — given target orbit, auto-generate launch time, azimuth, gravity-turn pitch program, and staging events as a starting script (removes the biggest new-user hurdle).
4. **Multi-objective (Pareto) optimization** — objectives today are scalar composites only; add NSGA-II/MOEA to trade payload vs. GLOW vs. residuals directly.
5. **KSP craft-file import → vehicle builder** — parse `.craft` part trees into stages/tanks/engines automatically (KSPTOTConnect already imports orbits/masses).

### Simulation Fidelity
6. **Wind models** (steady + gust profiles, direction shear) as force-model inputs and dispersion sources.
7. **Full spherical-harmonic gravity** (user-supplied C/S coefficient sets) beyond current non-spherical support.
8. **Atmosphere density scale-height perturbation / user CSV atmospheres** for non-catalog bodies.
9. **Parachute descent model** (deploy actions, drag-area events) for landing missions.
10. **Powered landing guidance** (suicide-burn/divert steering) + landing accuracy analysis vs. ground object.

### Analysis & Workflow
11. **Sensitivity reports** — tornado charts/Sobol indices from the Jacobian heatmap data; payload-to-orbit sensitivity sweeps (payload vs. inclination/altitude curves).
12. **CCSDS OEM / GMAT-STK ephemeris export** for interoperability beyond kOS export.
13. **Headless CLI batch runner** — run `.mat` cases from command line (no GUI) for CI-style regression and scripted studies; complements the in-app console.
14. **Script template library** — ascent profiles, flyby chains, landings as parameterized starting points.
15. **Rendezvous/targeting helpers** — phasing-angle constraint and CW-equation relative-motion GA tasks against another vehicle or ground object.

### UX Polish
16. Mission-plan diff tool (case file comparison), autosave checkpoints (undo/redo exists but not persistence), and inline porkchop plotting inside LVD rather than switching tools.

Items 1–3 give the biggest capability leap: they turn LVD from "design a nominal trajectory" into "certify a vehicle design," which is what real launch-vehicle tools (POST/OTIS-class) differentiate on.

## Part 3: Additional 3DOF-Specific Suggestions

LVD is fundamentally a 3DOF translational tool (r, v, m). These additions stay squarely in that lane — no rotational dynamics required.

### Targeting & Mission Design
1. **B-plane targeting** — B·T/B·R constraints and optimization variables for flyby and arrival states. Classic 3DOF interplanetary capability; today only two-body impact-point lat/lon/time constraints exist.
2. **Built-in Lambert solver + inline porkchop plotting** — generate Lambert-arc initial guesses between any two states/bodies to seed optimizations, and scan departure UT × TOF for ΔV-minimal windows without leaving LVD.
3. **Aerocapture/entry corridor toolkit** — periapsis-altitude sweep vs. capture/no-capture outcome, atmospheric-exit state targeting, and landing-footprint analysis. Purely translational.
4. **Patched-conic flyby chain generator** — build multi-body gravity-assist event scripts natively (MFMS import exists; a native generator would close the loop).

### Optimization Formulation
5. **Multiple-shooting / segmented transcription option** — break long coast-heavy arcs into nodes so optimizer sensitivities don't degrade over full-event spans; complements the existing single-shooting-per-event approach.
6. **Homotopy/continuation assistant** — auto-ramp constraint targets (e.g., final altitude 70→200 km in steps) when convergence stalls. Cheap to build on the existing optimizer plumbing.
7. **Case Matrix: sweep *any* optimization variable or constraint target** — currently only plugin variables are sweepable. Native sweeps over e.g. T/W, pitch-program coefficients, staging altitudes would make trade studies first-class.

### Performance
8. **Incremental re-propagation caching** — during optimization, skip re-integrating events whose inputs didn't change since the last iteration. Big speedup for multi-event scripts.
9. **Centralized parallel finite-difference Jacobians** — fan out FD perturbations across `parpool` regardless of solver (some solvers have their own parallel flags today).

### Analysis Output
10. **Auto-generated ΔV budget report** — per-event/per-stage table summing impulsive actions + idealized finite-burn ΔV; instant mission cost summary.
11. **Multi-run comparison overlays in Graphical Analysis** — plot quantities from several saved cases (nominal vs. variant) on shared axes.
12. **Resonant/repeat-ground-track orbit helper** — given body rotation rate and desired repeat cycle, solve for semimajor axis and inject as initial state (J2-aware where applicable).

Items 1–4 are the strongest pure-3DOF additions — they are standard features of POST/OTIS-class trajectory tools and directly serve interplanetary and aerocapture mission classes that LVD's event engine already supports mechanically.
