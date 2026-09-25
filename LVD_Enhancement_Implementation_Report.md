# LVD Enhancement Implementation Report

**Date:** 2026-09-16
**Branch:** `v1.6.11` (working tree — **nothing has been committed**)
**Scope:** the fourteen items requested from `LVD_Enhancement_Report.md` — A1, A6, A8, A9, A10, A11, B2, C1, E1, E2, E4, E7, F6, F9

---

## 1. Headline results

| Check | Result |
| --- | --- |
| Full test suite (`ksptotRunTests('all',1)`), final run after §7.4e | **1161 total: 1136 passed, 0 failed**, 25 documented skips (an earlier run showed 4 `OptimizerSmokeTest` license-checkout errors while every Optimization Toolbox seat was taken by other MATLAB sessions; they pass with a seat available). |
| The 25 incompletes | All pre-existing `assume()` scope guards (degenerate-orbit cases in `ElementConversionTest` / `KeplerSolverTest` / `OrbitGeometryTest`, plus one toolbox-gated `SensorTest` case). No new skips. |
| Golden mission fingerprints (final run) | **23 passed, 0 failed, 2 skipped — bit-identical** to the pre-change baseline |
| New tests written | **191** — 164 across twelve new test classes (39 of them App Testing Framework UI tests in `LvdMainGuiInteractionTest` and `EditEventDialogTest`), plus 21 added to `LvdGeometryTest`, 5 to `EventEnhancementsTest`, 1 to `LimitedThrottleModelTest` |
| Code Analyzer on every new/edited `.m` file | clean (remaining messages in touched files are on pre-existing lines) |
| `.mlapp` code-data drift (all 11 touched apps, `lvdfixCodeDataDrift`) | **0 user-code lines missing from the App Designer code data** — see §7 for why the first version of this table was wrong |
| UI additions on the App Designer canvas | **all of them** — every widget and menu item this work added to a `.mlapp` is a component of that app's model with a named callback (§7.4b, §7.4c); nothing is created at run time |

The two skipped goldens (`lvdExample_ToEelooViaJool_BackPropExample`, `lvdExample_TwoStageToOrbit_PluginVar`) are on the known-skip list: they error under headless MATLAB for reasons that predate this work, so no baseline fingerprint exists for them on either side of the change.

---

## 2. What was implemented, item by item

### A1 — Multiple termination conditions per event (first-of / all-of)

An event now carries an arbitrary number of termination conditions with an explicit combination rule.

- New enumeration `EventTermCondLogicEnum` (`FirstOf`, `All`) at
  `helper_methods/ksptot_lvd/classes/Events/@EventTermCondLogicEnum/`.
- `LaunchVehicleEvent` gained `extraTermConds`, `extraTermCondDirs` and `termCondLogic`, plus the accessor family
  `getAllTermConds`, `getAllTermCondDirs`, `getNumTermConds`, `addTermCond`, `removeTermCondByInd`,
  `setTermCondByInd`, `setTermCondDirByInd`.
- The integrator builds one event function per condition. `FirstOf` terminates on the earliest crossing;
  `All` requires every condition to have been satisfied, and terminates at the crossing that completes the set.
- `EventTermCondIntTermCause` / `NonSeqEventTermCondIntTermCause` report *which* condition fired.

**Backward compatibility is exact by construction:** condition 1 continues to live in the original `termCond` /
`termCondDir` properties, and only conditions 2..N go in the new `extra*` arrays. A mission loaded from disk with
one condition therefore produces the same event function, in the same order, as before — which is why the goldens
are unchanged.

### A6 — Event groups, collapsible sections, per-event notes

- `LaunchVehicleEvent.groupName` and `.notes`.
- `LaunchVehicleScript` gained `collapsedGroupNames`, `getGroupNames`, `isGroupCollapsed`,
  `toggleGroupCollapsed`, `setGroupCollapsed`.
- `LaunchVehicleScript.getListboxStr` folds a collapsed group into a single `▶ [GroupName] (n events)` heading row
  and prefixes members of an expanded group with `▼`. Collapse state is a view property only — it never reaches
  the propagator.

### A8 — Non-sequential events: enable toggle, priority order, logged discontinuities

- `LaunchVehicleNonSeqEvent` gained `enabled`, `priority` and `logExecutions`.
- `LaunchVehicleNonSeqEvents` filters disabled events out of evaluation and sorts the active set by `priority`
  (ascending, stable within ties so existing order is preserved when priorities are equal).
- When `logExecutions` is on, each firing appends a record of the state discontinuity it caused.

> **Flagged, per the bit-identity requirement:** `logExecutions` defaults to **`false`**. Three shipped example
> missions use non-sequential events (`lvdExample_TwoStageToOrbit` ×1,
> `lvdExample_ComplexDrag_AsparagusStaging` ×1, `SLS` ×5). Defaulting the flag to `true` would have added log
> records to those runs and changed their golden fingerprints. The feature is opt-in per event from the new
> non-sequential options dialog.

### A9 — More ΔV frames for `AddDeltaVAction`

- `DeltaVFrameEnum` extended with the additional reference frames called for in the report.
- New `DeltaVParamTypeEnum` selects between Cartesian components and a **polar** (magnitude / in-plane angle /
  out-of-plane angle) parameterisation.
- `AddDeltaVActionVariable` optimises whichever parameterisation is active, with the correct bounds and scaling
  for angles versus components.
- `lvd_AddDeltaVActionGUI_App.mlapp` updated to expose the frame and parameterisation choices.

### A10 — Per-event min-altitude / max-duration overrides; terrain-aware minimum altitude

- `LaunchVehicleEvent` gained `useEvtMinAltitude`, `evtMinAltitude`, `minAltIsTerrainRelative`, `useEvtMaxDur`,
  `evtMaxDur`.
- When an override is active it replaces the mission-wide `LvdSettings` value for that event only; when it is not,
  the mission-wide value is used exactly as before.
- `minAltIsTerrainRelative` measures the floor against the terrain height under the vehicle rather than the mean
  body radius.

### A11 — NOT conditional and cross-event comparisons

- New `LogicalNotActionConditional` (single child, inverted).
- `CompareAgainstEnum` extended so a `QuantityComparisonActionCondition` can compare the current value against the
  value that quantity had at the end of a **named earlier event**, not just against a constant.
- `AbstractActionConditional`, `ConditionalAction`, `ConditionalTypeEnum`, `LogicalAndActionConditional` and
  `LogicalOrActionConditional` updated for the new node type and comparison target.
- `lvd_EditActionConditionalGUI_App.mlapp` updated.

### B2 — Dynamic-pressure-limited and acceleration-limited throttle laws

- New `LimitedThrottleModel` (`helper_methods/ksptot_lvd/classes/ForceModels/throttle/@LimitedThrottleModel/`)
  throttles back to hold a dynamic-pressure or sensed-acceleration ceiling, falling back to the underlying
  throttle setting whenever the limit is not binding.
- `ThrottleModelEnum` and `ThrottleModelsSet` updated; `promptForThrottleModelType` offers the new type.
- New dialog `lvd_EditLimitedThrottleModelGUI_App.m` (plain `.m` App Designer-style class).

### C1 — Separate tank capacity from initial mass

- `LaunchVehicleTank.capacity` (mT, a non-negative scalar, **always defined**) is distinct from the initial
  propellant load, so a tank can start partly filled and be refilled up to its real capacity. The fuel-remaining
  percentage that drives engine throttle curves is `mass / capacity`; `TankToTankConnection` stops filling a tank
  that holds its capacity; new `TankCapacityValidator` warns when a tank's initial mass exceeds its capacity.
- There is deliberately **no "undefined" capacity** (see §7.4d for the decision): a tank created by the code has
  capacity 0 until it is given one; the stock vehicle and imported craft are created full (`capacity = initialMass`);
  a mission saved before capacities existed gets `capacity = initialMass` on load — raised to the optimisation upper
  bound when the initial mass is an active variable — which reproduces the old fuel-remaining percentage exactly
  (`LaunchVehicle.loadobj`, `LaunchVehicleTank.getLegacyCapacity`).
- `lvd_EditTankGUI_App.mlapp`: Capacity row (canvas components, §7.4c). The field is required, must be ≥ the initial
  propellant mass, and an active optimisation upper bound may not exceed it. While the capacity equals the initial
  mass it follows edits to the initial mass, so the usual "full tank" case is one entry.

### E1 — Single propagation per x for all solvers; single Jacobian pass

- `LvdOptimization` now evaluates the mission **once** per decision vector and serves the objective, every
  constraint and the run's state log out of that single evaluation, keyed on `x`.
- `FminconOptimizer`, `IpOptOptimizer`, `SQPOptimizer` and `AdamNlOptOptimizer` all route through the shared
  evaluator, so switching optimiser no longer changes how many propagations a run costs.
- The Jacobian is produced in one pass rather than one pass per constraint.

### E2 — Constraint Jacobian sparsity and unified parallel finite differences

- `ConstraintSet` computes which decision variables each constraint actually depends on and publishes the sparsity
  pattern.
- `CustomFiniteDiffsCalculationMethod` and `computeGradAtPoint` share one parallel finite-difference path that
  skips structurally-zero entries.
- Numerically this is a no-op on the goldens: the skipped entries are the ones that were computing zero anyway.

### E4 — Variable table and constraint status table

- `helper_methods/ksptot_lvd/classes/Optimization/tables/` holds the table-building code.
- `lvd_VariableTableGUI_App.m` — every optimisation variable with bounds, current value and active state.
- `lvd_ConstraintTableGUI_App.m` — every constraint with bounds, current value and satisfaction status.
- **Both are now reachable from the main window** (see §3).

### E7 — Per-constraint history and objective sensitivity display

- `lvd_recordConstraintHistory.m`, `lvd_plotConstraintHistoryTile.m`, `lvd_numObserveTiles.m` — per-constraint
  history is recorded through `ma_OptimRecorder` and plotted as a tile per constraint.
- `lvd_showSensitivityTornado.m` — tornado chart of each variable's influence on the objective and the
  constraints.
- **The tornado chart is now reachable from the main window** (see §3).

### F6 — Geometry additions

Five new geometry types, each with its own editor dialog and each registered in the corresponding enum
(`GeometricPointEnum`, `GeometricVectorEnum`, `GeometricAngleEnum`) and dependency graph:

| Type | Editor |
| --- | --- |
| `UnitVector` | `lvd_EditUnitVectorGUI_App.m` |
| `VectorSumVector` | `lvd_EditVectorSumVectorGUI_App.m` |
| `TwoPlaneAngle` (dihedral angle between two planes) | `lvd_EditTwoPlaneAngleGUI_App.m` |
| `VectorPlaneIntersectionPoint` | `lvd_EditVectorPlaneIntersectionPointGUI_App.m` |
| `EphemerisFilePoint` (point driven by a CSV ephemeris) | `lvd_EditEphemerisFilePointGUI_App.m` |

The three geometry `.mlapp` browsers were updated to list the new types.

### F9 — Ephemeris export

- `lvd_exportEphemeris.m` writes the propagated trajectory as CSV or CCSDS OEM;
  `lvd_readEphemerisCsv.m` reads it back (and is what `EphemerisFilePoint` uses).
- `lvd_ExportEphemerisGUI_App.m` is the export dialog.
- **Now reachable from the main window** (see §3).

---

## 3. GUI work

### 3.1 The new Advanced Event Options dialog

`kspTOT_LaunchVehicleDesigner/event/lvd_AdvancedEventOptionsGUI_App.m` (~640 lines) is a single modal-style
dialog covering A1, A6, A8 and A10 for one event:

- **Termination conditions** — a list box of every condition with its crossing direction, plus Add / Edit / Remove
  and the FirstOf/All logic selector. Editing condition *k* reuses the existing single-condition editor
  (`lvd_editEvtTermCond_App`) by temporarily swapping condition *k* into `event.termCond` under an `onCleanup`
  guard and writing the result back through `setTermCondByInd`, so there is exactly one termination-condition
  editor in the program.
- **Group and notes** — an editable dropdown pre-populated with the script's existing group names plus a
  `<No Group>` placeholder, and a free-text notes area.
- **Per-event limits** — minimum altitude (with the terrain-relative check box) and maximum duration, each behind
  its own "override" check box.
- **Non-sequential settings** — enabled / priority / log executions. This panel is hidden and its grid row
  collapsed to zero height when the dialog was opened for an ordinary event.

Design notes: condition add/edit/remove apply immediately (they are list operations on the event); everything else
is deferred to **Save & Close**. The dialog deliberately does **not** set `WindowStyle = 'modal'`, because the
termination-condition editor it opens *is* modal and would end up behind a modal parent; `uiwait` still blocks the
caller. A `showFigure` argument (default `true`, mirroring `lvd_VariableTableGUI_App`) lets tests build and drive
the dialog without displaying it.

Layout follows the existing design language: `uigridlayout` throughout with no absolute pixel positioning,
bold panel titles, the standard 10.667 pt font, white dropdown backgrounds, tooltips on every control, the standard
`logoSquare_48px_transparentBg.png` icon, `centerUIFigure` and `applySelectedThemeToApp`.

### 3.2 Making the new apps reachable — menu items on the main window

Several of the requested features (E4, E7, F9) had working apps that nothing in the UI could launch. The main window
(`ma_LvdMainGUI_App.mlapp`) now has these menu items as **real App Designer components** (visible on the canvas, each
with a named `MenuSelectedFcn` callback and a tooltip):

| Where | Component | Item | Item covers |
| --- | --- | --- | --- |
| Optimization menu (after Optimize Mission, with a separator) | `VariableTableMenu` | Variable Table... | E4 |
| Optimization menu | `ConstraintTableMenu` | Constraint Status Table... | E4 |
| Optimization menu | `SensitivityMenu` | Objective/Constraint Sensitivities... | E7 |
| File menu (just above Exit, with a separator) | `ExportEphemerisMenu` | Export Ephemeris... | F9 |
| Script list right-click (directly under Edit Event) | `ToggleEventGroupMenu` | Expand/Collapse Event Group | A6 |

Existing menu items are neither moved nor renamed. Per-event options (A1 / A6 / A8 / A10) are edited on the Edit
Event window itself (§7.4b), so there is no separate options dialog and no extra context menu on the non-sequential
list.

> **History.** The first delivery created these items at run time from `helper_methods/gui_setup/LvdEnhancementMenus.m`
> (the `LvdMouseCameraHandler` pattern) to keep the `.mlapp` footprint minimal. The user asked for everything to be
> visible on the App Designer canvas instead, so the helper was retired and the items were written into the component
> model (§7.4c).

### 3.3 The `.mlapp` footprint

`ma_LvdMainGUI_App.mlapp` carries the five menu components above with their five callbacks, and one small public
methods block with two helpers, `lvdEnhancementsAddUndo(undoStr)` and `lvdEnhancementsRefresh(rerunScript)`, which
give the menu callbacks (and the UI tests) access to the app's undo stack and its repropagate/redraw path without
needing GUIDE-style `handles` at the call site.

**How code-only patches were applied durably.** Patching the `document.xml` CDATA alone leaves `appModel.mat`
stale, and App Designer then silently regenerates the code from the model and throws the patch away. Code edits
therefore go through App Designer's own code round trip (component additions go through the full serializer instead —
§7.4b / §7.4c):

```
appdesigner.internal.comparison.getAppData(path)              % -> codeData (EditableSectionCode, StartupCallback, ...)
appdesigner.internal.codegeneration.getAppFileCode(path)      % -> generated class text
appdesigner.internal.comparison.saveAppCode(src, dst, text, codeData, true)   % code-only update, components untouched
```

This is `MLAPPSerializer.updateAppCodeData` underneath — a code-only update that leaves the component tree alone
and keeps `appModel.mat`, the stored code and the generated class text in agreement. The patched file was verified
to contain the change in all three representations, and the generated class text parses with zero errors.

> **Correction (second-pass audit, §7).** The first version of this report claimed all eight touched `.mlapp` files
> had been checked for drift between the stored class text and the App Designer code data. That check was vacuous:
> `appdesigner.internal.codegeneration.getAppFileCode` returns the *stored* text, so it was comparing the text with
> itself. A real check (`lvdfixCodeDataDrift`, which compares the user-code region of the text against
> `EditableSectionCode` / `StartupCallback` / `Callbacks`) found that seven of the dialogs — and the committed H9
> edits to the main GUI — existed only in the class text and would have been discarded by the next App Designer
> save. All eleven touched `.mlapp` files were re-synchronised through `saveAppCode` and now report zero drift; see §7.

---

## 4. Tests

### 4.1 New test classes

| Test class | Tests | Covers |
| --- | ---: | --- |
| `EventEnhancementsTest` | 48 | A1, A6, A8, A10 |
| `EditEventDialogTest` (App Testing Framework) | 21 | the rebuilt Edit Event window: condition list, Advanced tab, save/validate (§7.4b) |
| `LvdMainGuiInteractionTest` (App Testing Framework) | 18 | the real main window and dialogs by gesture (§7.4a, §7.4c, §7.4d) |
| `TermCondIndexedAccessorsTest` | 8 | `setTermCondByInd` / `setTermCondDirByInd` |
| `OptimizationEvalCacheAndJacobianTest` | 14 | E1, E2 |
| `AddDeltaVFrameTest` | 11 | A9 |
| `OptimTablesGuiTest` | 13 | E4, E7 (+3 in §7.4e) |
| `LimitedThrottleModelTest` | 9 | B2 |
| `EphemerisExportTest` | 7 | F9 |
| `TankCapacityTest` | 7 | C1 |
| `ConditionalLogicTest` | 5 | A11 |
| `PatchedMlappDialogsTest` | 6 | the patched dialogs open with their new controls and save them (§7.3) |
| **Total new classes** | **163** | |
| `LvdGeometryTest` (+21 tests) | 37 | F6 |
| `ValidatorTest` (updated) | 16 | C1 validator registration |

Plus one new test helper, `tests/helpers/UiwaitInterceptorFixture.m` (§7.4a), which stands in for the blocking
`uiwait` every LVD editor calls so that app flows which open dialogs can be driven headlessly, with a handler playing
the user on each dialog. (An earlier stub of the main window, `LvdMainGuiStub`, went away with the run-time menu
helper it existed to test — the menu tests now run against the real `ma_LvdMainGUI_App`.)

### 4.2 What the GUI tests actually assert

`EditEventDialogTest` drives the rebuilt Edit Event window with App Testing Framework gestures (`press`, `choose`,
`dismissAlertDialog`): the tab structure, what the condition list shows when opened, selection and per-condition
direction, Add (opens the single-condition editor) / Edit... / Remove (last condition refused), the Advanced tab's
group picker, notes and limit fields, what Save & Close writes to the event, the non-sequential panel and its save,
and input validation. `LvdMainGuiInteractionTest` does the same against the real main window and the AddDeltaV,
tank, throttle, conditional and Edit Event dialogs (§7.4a, §7.4c). Because these are gestures on the real
components, a broken callback wiring in a `.mlapp` fails a test rather than surfacing in the running app.

### 4.3 Golden verification

The goldens were captured from a clean baseline worktree at the pre-change commit and compared byte-for-byte
against the same missions run against the modified tree:

```
===== LVDFIX GOLDEN VERIFY =====
passed: 23   failed: 0   skipped: 2
ALL GOLDENS BIT-IDENTICAL
```

Bit-identity held because every new behaviour is opt-in and defaults to the old behaviour: one termination
condition still lives in `termCond` and still builds the same single event function; `groupName`/`notes` are
metadata; non-sequential `enabled` defaults true / `priority` defaults equal / `logExecutions` defaults false;
per-event limit overrides default off; the E1/E2 changes reorganise *when* evaluations happen, not what they
compute; and the new geometry, throttle, ΔV-frame and tank-capacity features are only reachable by explicitly
selecting them.

---

## 5. Defects found and fixed while doing this work

- `LaunchVehicleEvent.getAllTermConds()` takes no index argument (it returns
  `horzcat(termCond, extraTermConds)`); four call sites in the new test were using it as an indexed accessor.
- `LvdEnhancementMenus` originally named its app-handle property `app`, which the local `app = obj.app;` inside
  every method shadowed — 27 Code Analyzer warnings. Renamed to `mainApp`.
- The File menu's exit item is `'Exit Launch Vehicle Designer'`, not `'Exit'`; the menu-insertion anchor was wrong
  and silently left Export Ephemeris in the wrong slot.
- `uialert` refuses to attach to a hidden figure, which the "collapse an ungrouped event" test path hit; the test
  now shows the stub window for that one case.
- Deleting an App Designer app's figure deletes the app object with it, so `app.UIFigure` cannot be read after
  Save & Close; the test now captures the figure handle first.

---

## 6. State of the tree

- **Nothing is committed.** All 107 changed/new paths are in the working tree (62 modified, 1 deleted, 44 new — including this report).
- `kspTOT_LaunchVehicleDesigner/LVD_ENHANCEMENT_IDEAS.md` shows as deleted in `git status`. That deletion predates
  this work and is unrelated to it.
- Scratch tooling used for verification lives outside the repo, in `C:\Users\aharden\lvdfix\` (golden capture and
  compare, the `.mlapp` sync tool, the `.mlapp` consistency checker). A backup of the pre-patch main GUI is at
  `C:\Users\aharden\lvdfix\ma_LvdMainGUI_App.mlapp.bak`.

---

## 7. Second-pass audit (2026-09-16, later the same day)

The user asked for every claim in this report to be re-verified — UI work included — and for anything still
outstanding from the original fourteen items to be finished. This section records what that audit found, what it
changed, and how the result was verified. Everything above this section has been corrected where the audit proved
it wrong (the `.mlapp` consistency claim in §1 and §3.3).

### 7.1 Method

- Every engine-side diff (events, script, propagator, simulation driver, optimizer, constraint set, gradients,
  throttle, tanks, geometry, actions, conditionals) was read against the corresponding item text in
  `LVD_Enhancement_Report.md`.
- The generated class text of every touched `.mlapp` was diffed against `HEAD` and then — the step that mattered —
  the user-code region of that text was compared line by line against the App Designer *code data*
  (`EditableSectionCode`, `StartupCallback.Code`, `Callbacks(i).Code`), which is what App Designer regenerates the
  text from when it saves.
- Every `.mlapp` dialog that gained controls was opened and driven headlessly by a new test class (§7.4).
- KSPTOT was launched for real (`projectMain`) in the interactive MATLAB session, LVD opened from it, and the new
  menus exercised (§7.5).

### 7.2 Findings and fixes

1. **`.mlapp` code-data drift (severe).** Seven dialogs (`lvd_AddDeltaVActionGUI_App`,
   `lvd_EditActionConditionalGUI_App`, `lvd_EditThrottleModelsSet_App`, `lvd_EditTankGUI_App`, and the three
   geometry browsers) carried their enhancement code **only in the class text**; the code data still held the
   pre-change methods. So did the H9 `kOS export` and `deleteEvent` edits to `ma_LvdMainGUI_App` that were committed
   in `ce04b8b5`. The next App Designer save of any of them would have silently discarded the work. The earlier
   "verification" was vacuous because `appdesigner.internal.codegeneration.getAppFileCode` simply reads the stored
   text. Fix: `lvdfixResyncMlappCode` parses the class text back into the three code-data pieces and writes them
   through `appdesigner.internal.comparison.saveAppCode`; `lvdfixCodeDataDrift` now reports **0 missing lines on
   all eleven touched apps**. Backups of every pre-resync file are in `C:\Users\aharden\lvdfix\backup_resync\`.
2. **`lvd_AddDeltaVActionGUI_App` could not open at all.** Its run-time controls carried `Tag`s, so the GUIDE
   compatibility layer (`convertToGUIDECallbackArguments` → `UIControlPropertiesConverter`) tried to convert the
   user-frame dropdown, whose `ItemsData` holds objects, and errored inside the opening function. Fix: run-time
   controls no longer have `Tag`s (same precaution applied to the tank dialog).
3. **`lvd_EditThrottleModelsSet_App` errored on Save & Close** (`allModels ~= selModel` on a heterogeneous array;
   `ne` was not sealed on `AbstractThrottleModel`). Fix: `eq`/`ne` sealed on the base class, as the geometry base
   classes already do. Test added.
4. **`lvd_EditActionConditionalGUI_App` errored on open with any non-quantity root (i.e. the default).**
   Pre-existing at `HEAD`: the dialog set `.Enable` on `referenceFrameSelectComp`, whose property is `.Enabled`.
   Fixed because it blocks the A11 UI.
5. **Non-sequential events ignored termination conditions 2..N**, yet the Advanced Options dialog let you add them.
   Fix: `LaunchVehicleNonSeqEvent.getTerminationConditions` arms one integrator event per condition, all sharing
   the event's cause (first-of logic); the dialog locks the logic selector to *Any* for non-sequential events.
   Single-condition missions build exactly the same event vector as before (goldens unchanged).
6. **The Edit Event dialog showed only condition 1** with no sign that others existed. Fix:
   `LaunchVehicleEvent.getTermCondSummaryStr` ("… (+2 more; first to fire ends event)") is now what the label shows.
7. The main-GUI shims read `handles = guidata(app.ma_LvdMainGUI)` directly instead of through
   `convertToGUIDECallbackArguments(app)`, whose app-to-figure lookup can return another open App Designer figure.
8. Cosmetic: a mis-indented `end` in `TankToTankConnection`; stale `%#ok<NASGU>` suppressions removed.

### 7.3 F6 completed

- `VectorDotProductAngle` — the dot-product scalar, in the angle family as the report proposed.
  `AbstractGeometricAngle.isDimensionless` (default false) tells `lvd_GeometricAngleTasks`,
  `GeometricAngleMagConstraint` and `LaunchVehicleViewProfile.createAngleData` to report it raw (no deg conversion,
  no unit) and not to draw an arc. Editor: `lvd_EditVectorDotProductAngleGUI_App.m`; listed in the angle browser.
- `ThreePointCoordSystem` — origin, primary-axis and plane points with the same selectable axis assignment as the
  Aligned/Constrained system; degenerate (coincident/collinear) points fall back to a proper rotation instead of
  NaN. Paired with its origin in the existing `CoordSysPointRefFrame` it is the "frame from three points"; the
  "frame from two vectors" is the existing Aligned/Constrained system. Editor: `lvd_EditThreePointCoordSysGUI_App.m`;
  listed in the coordinate-system browser.
- Point-to-plane distance is the magnitude of the existing `PlaneToPointVector`, already a Graphical Analysis
  quantity, so no duplicate type was added.

### 7.4 Tests added

| Test class | Added | What it pins |
| --- | ---: | --- |
| `PatchedMlappDialogsTest` (new) | 6 | The five patched `.mlapp` dialogs open with their new controls and save them (AddDeltaV frames + polar save, conditional quantity-at-event controls, tank capacity edit/clear, throttle Limited model selection, Edit Event condition hint). Blocking `uiwait` is neutralised headlessly by placing a no-op `uiwait.m` at the top of the path for the test's duration — `uiresume` from a timer does not release `uiwait` under `-batch`. |
| `LvdGeometryTest` | 9 | Dot product value/units/view skip; three-point axes, axis assignment, degeneracy, frame composition; dependencies; enum/browser registration |
| `EventEnhancementsTest` | 3 | Condition summary string; non-seq events arm every condition; the earlier condition wins |
| `AdvancedEventOptionsGuiTest` (since replaced by `EditEventDialogTest`, §7.4b) | 1 | The editor locks the logic to Any for a non-sequential event |
| `LimitedThrottleModelTest` | 1 | Heterogeneous throttle-model arrays compare as handles |

Full suite after all of the above: **1152 tests, 1127 passed, 0 failed, 25 documented `assume()` skips**. Goldens:
**23 passed, 0 failed, 2 known skips — bit-identical.**

### 7.4a App Testing Framework coverage (added after the audit)

After the live check the user reported that **Insert Sequential Event** appeared to edit the existing event instead
of creating one, on a freshly opened default case but not on a loaded example. The first version of this section
wrongly blamed a stale dialog: my first UI test pre-selected the event before pressing, which hid the real cause.
Re-run against the fresh-open state (nothing selected) it reproduces on R2025b and R2026a, **and on an untouched
`HEAD` worktree** — a pre-existing defect, not a regression:

- on a fresh default case `scriptListbox.Value` is `{}` (a loaded case always has a selection), so the insert
  callback's `selEvtNum = find(ItemsData == Value, 1)` is empty;
- `LaunchVehicleScript.addEventAtInd(evt, [])` then evaluates `[evts(1:[]), newEvt, evts([]+1:end)]`, which
  **replaces the whole event list with the new event**. The new default event is also called "Untitled Event", so
  it looks as if the existing one was edited.

Fixes: `LaunchVehicleScript.addEventAtInd` and `LaunchVehicleNonSeqEvents.addEventAtInd` (the non-sequential
Insert button has the identical arithmetic) append when the index is empty, `NaN` or out of range, and still insert
in place for a valid index (0 = first) — unit tests `EventEnhancementsTest/addEventAtIndAppendsWhenNoIndexIsGiven`
and `nonSeqAddEventAtIndAppendsWhenNoIndexIsGiven`. `ma_LvdMainGUI_App.processData` now selects the first event
whenever the list is non-empty and nothing is selected, so a fresh window behaves like a loaded one.
`LvdMainGuiInteractionTest/insertSequentialEventAddsANewEvent` presses the real button in the fresh-open state and
passes on **both R2025b and R2026a** (the release the user runs).

To make that class of regression visible in CI rather than in the running app, UI-interaction tests were added on
MathWorks' App Testing Framework:

- **`tests/helpers/UiwaitInterceptorFixture.m`** — every LVD editor blocks in `uiwait`, which cannot be released
  from a timer under `-batch`. The fixture installs a stand-in `uiwait` for the test's duration; when an app flow
  opens a dialog, a handler registered for that dialog's `Name` plays the user (fills controls, presses
  Save & Close) at the moment the app would have blocked, and the flow continues with the dialog's output set.
  Unhandled dialogs and handler errors are recorded so the test can assert on them. `PatchedMlappDialogsTest` now
  uses the same fixture.
- **`tests/lvd_tests/LvdMainGuiInteractionTest.m`** (15 tests at this point; 17 after §7.4c, `matlab.uitest.TestCase`) — drives the **real**
  `ma_LvdMainGUI_App` and the real dialogs with `press`, `choose`, `chooseContextMenu`, `dismissAlertDialog`:
  Insert Sequential Event adds an event; Edit Event via context menu opens on the selected event and shows the
  condition-count hint; Advanced Event Options round-trips from the context menu (group written, list refreshed,
  undo state pushed); Expand/Collapse toggles the group header; Optimization menu opens both tables; the
  sensitivities item is graceful without variables; File › Export Ephemeris opens the dialog and Exit stays last;
  the non-sequential list has its options menu; AddDeltaV saves a polar ΔV and offers every frame (user frame
  refused without a geometric frame); tank capacity edit and negative-capacity rejection; throttle Limited model
  selection; conditional dialog enables the quantity-at-event controls; Advanced Options *Add* opens the
  per-condition editor and *All* logic saves.

Framework limits found while writing them, recorded for the next person: `press` works on `uimenu` items and
buttons, `chooseContextMenu` on list boxes, `choose` on a `TreeNode` (not on the `Tree`); `type` always ends with
Enter, and every LVD editor binds Enter to Save & Close, so `type` closes the dialog under the gesture — values are
set directly and the Save press is the gesture. A related observation not yet verified on the pre-existing fields
(license outage, below): pressing Enter inside a text field saves before the field's text is committed.

Full-suite run with these classes included: **1167 tests, 1142 passed, 0 failed, 25 documented skips** (the two UI
classes 21/21); goldens **23/23 bit-identical**. After the Insert fix above the suite is 1169 tests; its final run
passed everything except four `OptimizerSmokeTest` cases blocked by Optimization Toolbox seat exhaustion (see §1),
goldens again bit-identical, and `LvdMainGuiInteractionTest` passes 15/15 on both R2025b and R2026a. (An earlier
attempt showed 24 failures that were all `Aerospace_Toolbox` checkout errors from a briefly unreachable license
server; re-run once it answered.)

### 7.4b Advanced options moved onto the Edit Event window (canvas components)

The user did not want the per-event options in a separate right-click dialog. They now live on the Edit Event
window (`lvd_editEventGUI_App.mlapp`) itself, at the same window width, as **real App Designer canvas components**:

- The window's content sits in a new tab group. The **Event** tab holds the original content unchanged except for the
  Termination Condition panel, which became a list editor: every condition with its crossing direction, **Add** (which
  opens the single-condition editor for the new condition), **Edit...**, **Remove**, and the Crossing Direction and
  Condition Logic (Any / All) selectors. The **Advanced** tab holds *Group and Notes*, *Event Limit Overrides* and,
  when the window is opened for a non-sequential event, the *Non-Sequential Event* panel (enabled / priority / log
  executions), with the logic selector locked to Any as before. The window grew from 663 to 735 px tall to make room
  for the tab strip and the list.
- How it was built (`C:\Users\aharden\lvdfix\lvdfixRebuildEditEventApp.m`): the component model was loaded with
  App Designer's deserializer, the new components were created under their parents with a `DesignTimeProperties`
  record (code name + generated component code, callbacks stored by name exactly as App Designer does), the existing
  Panel was reparented into the Event tab, the code data (populate / save / validate, seven new callbacks) was patched,
  the properties block and `createComponents` were regenerated from the model, and the whole thing was written with
  `MLAPPSerializer.save()`. Read-back shows all 91 components with design-time records and zero code-data drift, so the
  new controls appear on the App Designer canvas and survive App Designer saves.
- The standalone `lvd_AdvancedEventOptionsGUI_App` and its two context-menu items (`Advanced Event Options...`,
  `Non-Sequential Event Options...`) were removed; `Expand/Collapse Event Group` remains. The run-time menu helper and
  its tests were trimmed accordingly at this point, and retired altogether in §7.4c.
- Tests: `EditEventDialogTest` (21 App Testing Framework tests on the rebuilt window: tabs, list contents, selection,
  add/edit/remove, direction, logic, group/notes/limits save, non-seq panel and save, validation), plus the updated
  `LvdMainGuiInteractionTest` (group an event from the context menu's Edit Event, non-seq settings by gesture, add a
  condition and set logic by gesture) and `PatchedMlappDialogsTest`.
- One defect was introduced and caught by these tests before delivery: a replace-all code patch also rewrote the
  identical line inside the new `editSelectedTermCond` helper, making it recurse; fixed with a context-sensitive
  replace (`replaceAt` op added to `lvdfixPatchMlapp`).

Numbers after this change: **full suite 1163 tests, 1138 passed, 0 failed, 25 documented skips**; goldens
**23/23 bit-identical**; code-data drift 0 on all eleven touched `.mlapp` files.

### 7.4c Every other UI addition moved onto the App Designer canvas

The user then asked for the same treatment for the rest of the session's UI work: anything created at run time should
be a component of its `.mlapp` so it shows on the App Designer canvas. Four apps were affected:

| App | What was created at run time | Now canvas components |
| --- | --- | --- |
| `lvd_AddDeltaVActionGUI_App.mlapp` (A9) | user-frame and parameterization rows, row reshuffle, +50 px | `userFrameLabel`, `userFrameCombo`, `paramTypeLabel`, `paramTypeCombo` (callback `paramTypeComboValueChanged`); `GridLayout3` is seven rows with the X/Y/Z rows and the mass checkbox moved down; figure 266 px tall |
| `lvd_EditActionConditionalGUI_App.mlapp` (A11) | "At Event" / "Event State" rows, +50 px | `CompareEventLabel`, `CompareEventDropDown` (`CompareEventDropDownValueChanged`), `CompareEventNodeLabel`, `CompareEventNodeDropDown` (`CompareEventNodeDropDownValueChanged`); `GridLayout16` four rows, `GridLayout8` 460 px, frame selector on row 4; figure 689 px tall |
| `lvd_EditTankGUI_App.mlapp` (C1) | capacity row, +25 px | `text15` (Capacity), `GridLayout5`, `capacityText` (`capacityTextValueChanged`), `text7` (mT), `text8` (hint label); `GridLayout3` five rows; figure 214 px tall |
| `ma_LvdMainGUI_App.mlapp` (E4, E7, F9, A6) | five menu items from `LvdEnhancementMenus` | `VariableTableMenu`, `ConstraintTableMenu`, `SensitivityMenu` (end of Optimization), `ExportEphemerisMenu` (directly above Exit), `ToggleEventGroupMenu` (directly under Edit Event), each with a `…MenuSelected` callback holding the former helper's logic |

In each app the `createRuntimeComponents` method, its call at the top of the opening function and the "components
created at run time" properties block were deleted, and the anonymous callbacks became named App Designer callbacks
(stored by name in the model, emitted as `createCallbackFcn(app, @name, true)` in `createComponents`). The
`LvdEnhancementMenus.setup` try/catch was removed from the main window's opening function, and
`helper_methods/gui_setup/LvdEnhancementMenus.m`, `tests/helpers/LvdMainGuiStub.m` and `LvdEnhancementMenusTest`
were deleted; the two `lvdEnhancements*` helper methods stay as the shared refresh path (§3.3). The eleven
programmatic `.m` dialogs (variable table, constraint table, ephemeris export, …) were never `.mlapp` files and are
out of scope by the user's choice.

How: the Edit Event rebuild's builder was generalised into `C:\Users\aharden\lvdfix\lvdfixCanvasize.m` (load the
component model with `MLAPPDeserializer`, apply a per-app mutation through `LvdfixCanvasCtx` — `create` a component
from its App Designer style code lines with a `DesignTimeProperties` record, `setProp` to change a live property and
its stored code line together, an explicit creation-order key so a new menu item lands exactly where the run-time
code had placed it — apply the code deletions identically to the code data and the class text, append the new
callbacks, regenerate the properties block and `createComponents` from the model, write with
`MLAPPSerializer.save()`, read back). `lvdfixCanvasizeAll.m` holds the four specs. Verification per app: generated
text parses (0 errors), read-back model contains every new code name, `lvdfixCodeDataDrift` 0 (main GUI: the same 7
auto-generated comment lines as before), and the class text differs from the previous one only in the intended
places (checked by diff; two generator fixes came out of that diff — toolbar `ClickedCallback` lines and App
Designer's menu-first ordering of the properties block).

Tests: `PatchedMlappDialogsTest` (6) and `LvdMainGuiInteractionTest` pass unchanged against the converted dialogs
(the same component names and layouts, now from the model), and `LvdMainGuiInteractionTest` gained
`enhancementMenusAreCanvasComponentsInTheRightPlaces` (the five items are `app.` components in the right positions,
Variable Table and Export Ephemeris carry separators, each has a function-handle callback and a tooltip, the context
menu has exactly one new item) and `collapsingAnUngroupedEventShowsAnAlertAndChangesNothing`. The eight accessor
tests from `LvdEnhancementMenusTest` moved unchanged to `TermCondIndexedAccessorsTest`.

Numbers after this change: **full suite 1157 tests, 1132 passed, 0 failed, 25 documented skips** (R2025b); goldens
**23/23 bit-identical**; the four UI/dialog classes (52 tests) pass **52/52 on both R2025b and R2026a**; code-data
drift 0. The user then opened the apps in App Designer and re-saved `lvd_EditTankGUI_App.mlapp` from it; the capacity
row survived the round trip (App Designer only normalised whitespace and two `BackgroundColor` lines), which is the
durability check this whole approach was for.

### 7.4d Tank capacity is always defined (2026-09-17)

A review of how `capacity` flows through LVD surfaced that the "empty = no limit" design kept two behaviours alive
in every consumer (`hasCapacity()` branches in the fuel-remaining percentage, the crossfeed clamp, the validator, the
summary and the dialog) — and that the property default in the working tree had meanwhile drifted to `0`, which made
`hasCapacity()` true for every tank and failed `TankCapacityTest`. The user's decision: **capacity is always a
number; there is no blank/undefined state; users who want the old behaviour set capacity = initial mass.**

What changed:

- `LaunchVehicleTank.capacity(1,1) double {mustBeNonnegative} = 0`. `hasCapacity` and `getFuelRemainingCapacity`
  are gone; `getCapacity()` returns the number; the summary always prints both load and capacity.
  `LaunchVehicleStateLogEntry` measures fuel remaining against `getCapacity()`; `TankToTankConnection` clamps
  unconditionally (`mass >= capacity` ⇒ full — a 0 mT tank is always full); `TankCapacityValidator` warns whenever
  `initialMass > capacity`.
- Creation sites give tanks a capacity: the stock vehicle's tank (`LaunchVehicle`, 4 mT) and craft-import tanks
  (`lvd_import_createLaunchVehicle`, the part database's `maxAmount` masses, i.e. full) get `capacity = initialMass`.
  Tanks constructed bare (`LaunchVehicleTank(stage)`, as the Tanks dialog's *Add* does before opening the editor) hold
  0 until the editor sets a capacity.
- Legacy missions: `LaunchVehicle.loadobj` gives every tank that loads with capacity 0 its
  `getLegacyCapacity()` — the initial mass, raised to the optimisation upper bound when the tank's initial mass is
  an *active* variable with a finite bound (so an optimiser that was allowed to fill the tank to 10 mT still can).
  This reproduces the previous fuel-remaining percentage (`mass / initialMass`) exactly, and the goldens stay
  bit-identical. (A file saved during the one day the property was `(1,:)`-empty loads with a MATLAB property
  validation warning and then takes the same legacy path.)
- Edit Tank dialog (`lvdfixTankCapacityRequired.m`, via `lvdfixCanvasize`): the Capacity field always shows the
  number; `validateInputs` requires a finite value ≥ 0 **and ≥ the initial propellant mass**, and when the
  optimisation checkbox is on the upper bound may not exceed the capacity; `saveAndClose` writes the number; the
  hint label reads "(at least the initial mass)". While the capacity equals the initial mass (the usual full tank),
  editing the initial mass moves the capacity with it (`initPropMassText_Callback`).
- Tests: `TankCapacityTest` rewritten (7 cases: defaults/accessors incl. rejection of `[]` and negatives, fuel
  remaining vs capacity, crossfeed clamp incl. the 0 mT case, validator, copy/summary, **legacy load migration**
  with plain / active-variable / inactive-variable / unbounded / explicit tanks, and a shipped example mission
  loading with every tank at its legacy capacity). `PatchedMlappDialogsTest.tankDialogEditsCapacity` now asserts
  blank and below-initial-mass capacities are refused; `LvdMainGuiInteractionTest` gained
  `tankDialogCapacityFollowsTheInitialMassByGesture`. Test fixtures that build tanks by hand
  (`VehiclePropulsionMassFlowTest`, `EventActionTest`, `EventTerminationConditionTest`, `ConstraintTest`) set
  `capacity = initialMass` explicitly, as production code now must.

Final numbers after this change: **full suite 1158 tests, 1133 passed, 0 failed, 25 documented skips** (R2025b);
goldens **23/23 bit-identical** (including `lvdExample_ComplexDrag_AsparagusStaging`, whose crossfeed now runs
against migrated capacities); `PatchedMlappDialogsTest` + `LvdMainGuiInteractionTest` + `TankCapacityTest` pass
**31/31 on R2026a**; code-data drift 0 on `lvd_EditTankGUI_App.mlapp`.

### 7.4e Constraint status table: state-comparison rows (2026-09-17)

The user asked whether the table handles "quantity at event A must equal the same quantity at event B" correctly,
since a satisfied row has Y − X = 0 while Y itself is far from 0. Review of `LvdOptimTableModel` found three defects,
one of them exactly that:

1. **Status leaked the magnitude of Y into a difference.** `classifyViolation` called a row *ok* only when the
   violation was exactly 0 and *marginal* when it was below 10⁻³ of |value| (= |Y|). Two consequences for a
   continuity constraint: a converged one (|Y − X| ≈ 10⁻¹²) never showed green, because a floating-point equality
   residual is never exactly 0; and a real 5 km position mismatch on a 7000 km radius showed amber "Marginal"
   because 5/7000 < 10⁻³. Status is now judged on the **scaled violation** — the `c`/`ceq` value the optimizer
   itself sees (violation / scale factor): ≤ 10⁻⁶ (fmincon's default `ConstraintTolerance`) is *ok*, < 10⁻³ is
   *marginal*, otherwise *violated*; the unscaled violation stands in when no scaled value was recorded. The relative
   violation is still reported in the row metadata for information only. The Value / Lower / Upper / Violation
   columns themselves were already right (Y, X, X, |Y − X|).
2. **Bound columns ignored the direction of an inequality comparison.** For `>=` and `<=` comparisons both bound
   columns showed X. They now show `[X, Inf]` for `>=` and `[−Inf, X]` for `<=`; `==` keeps `[X, X]`.
3. **Rows could be shifted onto the wrong constraint** (pre-existing, in `ConstraintSet.evalConstraints`). A
   constraint whose event produced no state-log entries and that had never been evaluated before contributed
   *nothing* to the per-constraint arrays (`value`, `lb`, `ub`, `type`, `eventNum`, `valueStateComps`) while still
   being appended to `consts`, so every later constraint's values landed one row up — in the status table, the
   constraint validator and the constraint list tooltips alike. It now contributes a NaN row (and, as before, no `c`
   / `ceq` entries), and the table labels it "Not evaluated".

The window's header comment and table tooltip describe the new colour rule. Tests (`OptimTablesGuiTest`, 13 → 16):
`satisfiedStateComparisonReadsOkWhateverTheMagnitude` (Y = X = 50 → violation 0, *ok*; a 10⁻⁹ residual → *ok*; a
1-unit mismatch on the same values → *violated*), `comparisonBoundsShowTheDirectionOfTheInequality`,
`aConstraintWhoseEventNeverRanKeepsTheOtherRowsAligned` (also runs `ConstraintValidator` over the aligned arrays),
and the classification cases in `violationMathCoversAllComparisonTypes` were rewritten for the scaled rule.

Not changed, but noted: `ConstraintValidator` lists a state-comparison constraint whenever `ceq ~= 0` exactly, so a
converged continuity constraint is always listed under "constraints are **active** or violated" — consistent with
its wording (an equality constraint is always active), so it was left alone.

Final numbers after this change: **full suite 1161 tests, 1136 passed, 0 failed, 25 documented skips**; goldens
**23/23 bit-identical** (the `ConstraintSet` change only adds NaN bookkeeping rows; `c`/`ceq` are untouched).

**Legibility under dark themes (user screenshot, same day).** The green/amber/red highlight cells kept the theme's
default font colour, which under a dark theme is light-on-light. Both table windows now pin a dark font colour
(`[0.10 0.10 0.10]`) on every highlight style (`lvd_ConstraintTableGUI_App.styleCells`, the on-bound row style in
`lvd_VariableTableGUI_App`), and the grey "inactive row" style is added *before* the cell highlights so the
highlight's font wins where they overlap. Test `OptimTablesGuiTest/highlightedCellsPinTheirFontColour` (every style
with a background has a dark font colour; row greying precedes cell highlights) — class 14/14.

Remaining manual check for the user: open the four apps in App Designer and confirm the new components are on the
canvas (AddDeltaV rows 2–3, Conditional's Quantity Comparison panel rows 2–3, Tank row 5, and the five menu items in
the main window's menu bar / context menu).

### 7.4f 3-D view playback, camera scripting, vehicle mesh and export — F8 (2026-09-17)

The user asked for report item F8 with three changes: no colour-by-quantity; an imported 3-D mesh rendered at the
vehicle (with scale, rotational offset and translation so the mesh axes can be aligned with the body axes); and a
scripted camera — an ordered set of camera poses interpolated in time, with holds and with keyframe times tied to
absolute UT or to an event's start/end. The UI had to be a **separate window written as a programmatic uifigure
(no new `.mlapp`)**, and everything had to have tests, including App Testing Framework tests. Three design choices
were confirmed with the user before starting: keyframes may be either scene-fixed (camera position/target/up in the
view frame) or vehicle-relative (azimuth/elevation/range about the vehicle, looking at it) and a script may mix
both; the mesh geometry is embedded in the mission (plus the source path for reload); and the one launcher menu item
goes onto the main window's App Designer canvas through `lvdfixCanvasize`.

**What changed.** Nothing about propagation or optimization; every new setting defaults to the previous behaviour.

| Area | Files | Notes |
|---|---|---|
| Saved settings on the view profile | `LaunchVehicleViewProfile` (+ `cameraMode`, `chaseCamera`, `cameraScript`, `vehicleMesh`, `playbackSettings`; `ensureF8Defaults`, `getCameraDriver`, `createVehicleMeshData`, `firstVehPosAtTime`), `LaunchVehicleViewSettings` | The four handle-valued settings deliberately have **no declaration default** — a handle default is built once per class load and would be shared by every profile — so they are constructed in the profile constructor and back-filled by `loadobj` (struct and object branches) for missions saved before F8. |
| Camera model | `LvdCameraModeEnum`, `LvdCameraKeyframeAnchorEnum`, `LvdCameraKeyframeRefEnum`, `LvdCameraEasingEnum`, `LvdCameraKeyframe`, `LvdCameraScript`, `LvdChaseCameraSettings`, `LvdCameraMath` | `LvdCameraScript.evaluate(time, timeResolverFcn, vehPosFcn, defaultVA)` is a pure function: keyframes are sorted by resolved time, each occupies `[t, t + hold]`, the gap to the next keyframe is blended with the earlier keyframe's easing (linear or smooth-step), the pose is clamped before the first and after the last keyframe. Two vehicle-relative keyframes blend az/el/range (shortest arc in azimuth) so the camera keeps chasing through the transition; any other pair blends Cartesian poses (position/target lerp, up slerp, view-angle lerp). Vehicle-relative geometry is spherical about the vehicle in the view frame (az from +X toward +Y, el from the XY plane), matching Mission Architect's animator. Event-anchored keyframes resolve from the state log honouring `EventPlottingMethodEnum`; an unresolvable anchor falls back to the keyframe's stored absolute time. |
| Deleting an anchored event | `LaunchVehicleViewProfile.removeEventFromListOfPlottedEvents(evt, stateLog)`, `LvdCameraScript.removeEventReferences` | The main window's delete path already calls the view settings' event-removal hook; the keyframe is frozen at its last resolved absolute time. Deletion is **not** blocked (`getEventUsageReport` is unchanged), which is what `CameraScriptTest/eventDeletionIsNotBlockedByACameraKeyframe` pins. |
| Runtime camera | `LvdSceneCameraDriver` (Transient, one per profile), `LvdMouseCameraHandler.enabled` | The main window's `PostSet` listeners copy every axes camera change back into the profile's saved manual camera. The driver snapshots that camera when a non-Manual mode is entered, re-asserts the snapshot on the profile immediately after each scripted camera write (the listeners run synchronously), and puts it back on the axes when Manual is re-selected — so Chase/Scripted never corrupts the saved view. Mouse drags are disabled outside Manual mode. |
| Render path | `lvd_renderSceneAtTime.m` (new), `timeSliderStateChanged.m` (now a throttled wrapper), `Generic3DTrajectoryViewType.plotStateLog` (creates the mesh data; skips the manual camera restore in non-Manual modes) | The slider callback's 50 ms throttle and `drawnow limitrate` would drop frames during export, so its body became `lvd_renderSceneAtTime(time, lvdData, handles, app, drawMode)` with `"limitrate" | "full" | "none"`; slider drags behave as before. |
| Vehicle mesh | `lvd_readMeshFile.m` (binary/ASCII STL with vertex welding, OBJ with `v/vt/vn` tokens, negative indices and fan triangulation; self-contained because the repo's `z_gptoolbox/external/stlread.m` shadows MATLAB's), `LvdVehicleMeshSettings`, `LaunchVehicleViewProfileVehicleMeshData` | Mesh→body transform is `p_body = scale·Rz(yaw)Ry(pitch)Rx(roll)·p_mesh + t` (`eul2rotmARH(...,'ZYX')`; note that helper returns nothing when the sequence is omitted). The renderer clones `LaunchVehicleViewProfileBodyAxesData`: one `hgtransform` per trajectory segment holding a `patch` tagged `LvdVehicleMesh`, matrix `[R p; 0 1]` where `R` is the pchip-interpolated body→view DCM **re-orthonormalised by SVD** (element-wise interpolation does not preserve SO(3)). `refreshAppearance()` pushes colour/alpha/edges/vertices without a replot. |
| Playback / export | `LvdViewPlaybackController` (timer state machine; `advance`, `stepTo`, `frameSchedule` are pure and tested without real time), `LvdViewExporter` (frame-exact `VideoWriter` MPEG-4 / Motion JPEG AVI, animated GIF via `rgb2ind`+`imwrite` append, `exportgraphics` stills, `copygraphics`; even-dimension and first-frame-size normalisation; cancel deletes the partial file) | `getframe(uiaxes)` and `exportgraphics(uiaxes)` were verified to work on hidden uifigures in R2025b, so export captures `app.dispAxes` directly. |
| The window | `kspTOT_LaunchVehicleDesigner/view/lvd_ViewPlaybackGUI_App.m` | Non-modal, singleton (a second open raises the existing window), three tabs — Playback (transport, speed/fps/loop, video/image export), Camera (mode, chase offsets, keyframe table + editor with Add-from-camera / Capture / Preview / Move / Remove), Vehicle Mesh (import/reload/clear, scale + fit-longest-side, yaw/pitch/roll, translation, colour/opacity/edges/lighting, body-frame preview axes with an RGB triad). All components are public (the themer walks them); the two `Constant` name/tag properties had to be made private for the same reason. Public methods (`play`, `stepTo`, `exportVideo(path, opts)`, `exportImage`, `importMeshFromFile`, `addKeyframeFromCurrentCamera`, `applyKeyframeEdits`, …) are the test seam and never open a dialog. The window listens for `ScriptPropagationFinished` (stops playback, adopts the new time range) and for the main window's destruction. (The first build pushed no undo states, matching the other view-profile edits; the follow-up below changed that.) |
| Launcher | `ma_LvdMainGUI_App.mlapp` via `C:\Users\aharden\lvdfix\lvdfixCanvasizeF8.m` | One `uimenu` `ViewPlaybackMenu` under the View menu after "Pop Out Orbit Display", callback `ViewPlaybackMenuSelected` → `lvd_ViewPlaybackGUI_App(lvdData, app)`. `check` showed 10 added lines and 0 removed; `apply` read back identically; `lvdfixCodeDataDrift` reports the same 7 pre-existing comment-only lines before and after (verified against the tool's own backup), i.e. no new drift. |

**Tests** (nine new classes, 109 tests, all passing on R2025b):
`CameraMathTest` (18: spherical offsets, slerp, easing, shortest-arc blending, SVD orthonormalisation, axes I/O),
`MeshFileReaderTest` (10: binary/ASCII STL cube welds to 8 vertices, OBJ quads/fan/relative indices, error ids),
`VehicleMeshSettingsTest` (13: transform math, file I/O, fit, and the renderer against real
`LaunchVehicleViewPosVelInterp`/`LaunchVehicleViewProfileAttitudeData` objects), `CameraScriptTest` (20: holds,
clamps, linear vs smooth-step, ordering, overlaps, vehicle-relative tracking and blending, event anchors on a
propagated mission, the delete-event fallback, and that deletion is not blocked), `ViewProfileF8PersistenceTest`
(6: per-profile independence of the settings objects, `loadobj` back-fill, `.mat` round trip incl. a keyframe's
event handle, a shipped pre-F8 example loading warning-free), `PlaybackControllerTest` (13), `ViewExporterTest`
(11: frame counts via `VideoReader`/`imfinfo`, cancel, stills), `RenderSceneAtTimeTest` (5, real main window: mesh
pose against an independent frame-conversion oracle, chase/scripted camera, saved-camera protection, mouse handler,
slider path) and `ViewPlaybackGuiTest` (13, `matlab.uitest` gestures on the real main window and the new window:
menu launch, play/pause/stop/step, drop-down camera modes, keyframe add/edit/anchor/move/remove/preview, mesh
import/fit/appearance/clear, image and video export through the seams, re-propagation, un-propagated mission,
main-window close). Two App Testing Framework facts cost a round each: gestures need a **visible** window and the
component's **tab must be selected** first (`testCase.choose(app.CameraTab)`).

**First live use (user report, same day): "I'm not seeing the mesh", with the 3-D display blank.** The user's Orion
STL (34 511 vertices) imported and previewed correctly, but at its true size — 0.02 km after "Fit" — it is far below
one pixel in a view that spans the planet, and zooming the camera onto it blanks the whole axes. Reproduced headless
on R2025b and R2026a: MATLAB's depth buffer covers the scene's full extent (~2700 km here), so anything a few tens of
metres across collapses into the near clipping plane and every close-up (chase camera at 0.08 km or 0.5 km range)
renders nothing but the axes background — dark grey under a dark theme, exactly the screenshot. At a 12 km display
size the same mesh renders cleanly from a 30–50 km chase camera (verified by image). Changes: (1) importing a mesh
now auto-fits its longest side to the **"Fit longest side to"** length, whose default is **2% of the central body
radius** (`LvdVehicleMeshSettings.defaultDisplayLengthKm`; Kerbin 12 km), and the status line says so; (2) a
**"Show in Chase Camera"** button on the Mesh tab switches to Chase mode at four times the mesh's longest side;
(3) an italic note on the Mesh tab explains that the mesh is a display model and why true scale cannot be drawn;
(4) the window sets `HandleVisibility = 'callback'` like the other LVD dialogs, so `close all` (and the MCP tool's
figure sweep, which is how this was noticed) no longer kills it. Tests: `VehicleMeshSettingsTest`
(+`defaultDisplayLengthIsTwoPercentOfTheBodyRadius`), `ViewPlaybackGuiTest/meshImportShowsThePatchAndThePreview`
extended for the auto-fit and the chase button.

**Second user report (same day): "pan, orbit and dolly don't work on the 3-D axes any more."** Root cause: the
first F8 build *disabled* `LvdMouseCameraHandler` whenever the profile's camera mode was not Manual, so that a drag
would not fight the chase/scripted camera. After "Show in Chase Camera" the profile stays in Chase mode, the flag
stayed off when the playback window was closed, every slider move re-asserted it, and nothing in the main window
said why (reproduced headless: fresh open → enabled; after Show in Chase → disabled; after closing the window →
still disabled; after a slider move → still disabled). The design was wrong, not just the clean-up. Now the mouse
works in every mode: the handler is never disabled by LVD; it gained public `beginDrag` / `applyDrag` / `endDrag`
(the window callbacks call these, so tests can drive the exact code path) and a `cameraDragFcn` hook reporting
`"motion"` and `"end"`. `lvd_renderSceneAtTime` points the hook at the profile's `LvdSceneCameraDriver.onUserCameraDrag`,
which in **Chase** mode turns the dragged camera into new chase offsets (`LvdChaseCameraSettings.setFromCamera`,
re-centred on the vehicle, saved manual camera untouched) so the camera keeps following from where the user put it,
and in **Scripted** mode hands the camera back to the user: the dragged view becomes the saved manual camera and the
profile drops to Manual (the script is kept). The driver fires `CameraChangedByUser` and the playback window mirrors
the change on its Camera tab. Regression tests: `RenderSceneAtTimeTest` (+4: drag math and phases for
orbit/pan/dolly; Chase drag retunes range/azimuth with no snap-back on the next render; Scripted drag takes manual
control; and the exact reported sequence — Show in Chase, close the window, move the slider — leaves orbit, dolly
and pan working) and `ViewPlaybackGuiTest/cameraTabMirrorsMouseDrags`.

*Follow-up (user): "in chase mode the target should be on the vehicle so an orbit orbits it — it isn't."* The
camera **toolbar** modes (orbit / pan / dolly / zoom toggles, which drive `cameratoolbar`) bypass the mouse handler
entirely, so their changes never reached the driver, and the main window's `updateCamTgtPos` listener moves the
camera target along the sight line during a toolbar dolly. The driver now `attach`es its own PostSet listeners to the
axes camera (`CameraPosition/Target/UpVector/ViewAngle`); any change it did not make itself (an `isApplying` guard),
while the mouse handler is dragging *or* a camera toolbar mode is active, is handled as user input — Chase: the
camera position becomes the new chase offset and the **target is pinned back onto the vehicle**; Scripted: manual
control. Programmatic changes with no gesture in progress (plot resets, limit changes) are ignored, so the chase pose
is simply re-applied on the next frame. `LvdCameraMath.applyPoseToAxes` now writes the position before the target so
the target write is the final word even under the dolly listener. Tests: `RenderSceneAtTimeTest`
(+2: toolbar orbit keeps the target on the vehicle and retunes azimuth, toolbar dolly re-pins the target and retunes
range, a programmatic change is ignored and the pose re-applied; toolbar orbit in Scripted mode hands the camera
back). *Also requested:* mesh import and reload now show an indeterminate `uiprogressdlg` ("Importing Mesh — Reading
file… / Drawing N faces…") while the file is read and drawn; the window records every dialog title in a hidden
`ProgressDialogLog` so `ViewPlaybackGuiTest` can assert it appeared.

*Follow-up (user): "close to the target the mouse dolly is really touchy — a tiny movement rams through the target
and out the other side."* `LvdMouseCameraHandler` scaled its dolly and pan steps by the **axes limits** (the
whole scene, ~2700 km here): about 70 km per pixel of dolly, whatever the camera distance. Both are now scaled by
the camera-to-target distance: dolly multiplies the distance by `exp(-pixels * DollyRatePerPixel)` (default 0.01, so
100 px ≈ 37% of the distance; it can never cross the target and is exactly reversible), and pan moves the scene
one-for-one with the pointer at the target's depth (`worldUnitsPerPixel` = visible height / axes pixel height, gain
`PanGain`). Orbit stays angular (`OrbitDegPerPixel`). `beginDrag` also switches the four camera modes to `manual`, as
`camdolly`/`camorbit` do: with the view angle left in `auto`, MATLAB re-fits it after every camera move, which partly
cancels a dolly and changed the pan scale mid-drag (that is what first failed the new drag-math assertion). Tests:
`RenderSceneAtTimeTest` drag-math case updated to the
exponential/one-for-one laws, plus `dollyAndPanStayGentleCloseToTheTargetAndNeverPassThroughIt` (camera 50 m from a
chased vehicle in a planet-scale scene: one pixel = 1% of the distance, a 1000 px drag never crosses the target,
dragging back returns exactly, the chase target stays on the vehicle, a short pan stays near the vehicle).

*Follow-up (user, same day): three requests — every edit in the window must create a labelled undo state; add a
user-defined **data overlay** (any Graphical Analysis quantity drawn on the view and so into exported video) with
control of position, per-quantity precision and font; and make it abundantly clear that all of this lives on the
current view profile.*

- **Undo.** Every edit made through the window goes through `pushUndo(label)` → the main app's
  `lvdEnhancementsAddUndo(label)` (the existing `LVD_UndoRedoStateSet.addState`, called *before* the edit as LVD
  does everywhere), with descriptive labels: "Change Camera Mode", "Edit Chase Camera", "Add / Edit / Remove /
  Reorder Camera Keyframe", "Import / Reload / Clear Vehicle Mesh", "Edit Vehicle Mesh Transform / Appearance",
  "Edit Playback Settings", "Toggle Data Overlay", "Add / Edit / Remove / Reorder Data Overlay Quantity", "Edit Data
  Overlay". Field edits are compared against the profile first (`applyStructIfChanged`, with `isequaln` so blank
  optional export times do not read as a change) so re-applying unchanged values records nothing. Mouse-driven camera
  changes record one state per gesture through the driver's `undoFcn` ("Adjust Chase Camera by Mouse", "Take
  Manual Camera Control"). Because Edit > Undo
  **replaces the `LvdData` object** in the main window, `lvd_renderSceneAtTime` now calls
  `lvd_notifyPlaybackWindows(lvdData, app)` on every frame and the window re-binds (`bindToLvdData`: listeners,
  controller, all tabs) when the object it holds is no longer the one the main window has. A hidden `UndoLog` keeps
  the labels for tests.
- **Data overlay.** `LvdViewOverlaySettings` (saved on the profile as `overlay`: enabled, title, epoch / UT / mission
  elapsed time / current event header lines, the quantity `items`, corner, margin, font name/size/weight/colour,
  background box + colour) and `LvdViewOverlayItem` (a `GraphicalAnalysisTask` — quantity + reference frame — plus
  label, decimals, Fixed / Scientific / Auto format, units on/off). The Transient renderer
  `LaunchVehicleViewProfileOverlayData` evaluates each quantity over the whole state log once with the same
  `GraphicalAnalysisTask.executeTask` the plots use, grouped by event (a later event owns a shared boundary time so
  discontinuities are kept) and interpolated linearly inside an event; the block is one `text` object in
  normalized axes units (tagged `LvdViewOverlayText`) so it stays put under every camera change and is captured by
  `getframe`. Text backgrounds in MATLAB are opaque, so there is no alpha control. The **Data Overlay** tab offers
  the full Graphical Analysis quantity list (99 tasks) with a live search box, the standard
  `referenceFrameSelectComp`, an editable table (Label / Decimals / Format / Units per row), Move Up / Down / Remove,
  a corner drop-down, margin, font, bold, text and box colour pickers, and a live one-line preview of what the
  overlay reads at the current time. Adding the first quantity switches the overlay on. Deleting a geometric
  reference frame removes the overlay items expressed in it or in a frame built on it
  (`LaunchVehicleViewProfile.removeGeoRefFrameFromList`).
- **Profile clarity.** The window title is "LVD 3-D View Playback | View Profile: *name*"; a banner under the
  title says everything in the window belongs to the active view profile and is saved with it, and how to switch
  profiles; the status line names the profile; the tab tooltips repeat it. `LaunchVehicleViewSettings` now fires an
  `ActiveProfileChanged` event from `setProfileAsActive` (only on a real change) and the window repopulates every
  tab from the newly active profile.
- Bugs found by the tests along the way: `isequal(NaN, NaN)` made "unchanged" playback fields record an undo state;
  a quantity expressed *directly* in a user-defined geometric frame was not recognised as using that frame
  (`GraphicalAnalysisTask.usesGeometricRefFrame` only walks the frame's dependencies, so the overlay item checks
  identity too); and the overlay style panel was clipped at the window's original height, which put the
  "Background box" checkbox off-screen — the App Testing Framework press then silently did nothing, so the window
  grew to 800 px and the two overlay panels have fixed content heights.
- **A pre-existing hazard exposed by the undo test.** Pressing the main window's Edit > Undo with the playback
  window open threw `Unrecognized field name "ma_LvdMainGUI"` from `editMenu_Callback`. Every GUIDE-migrated callback
  in the main window gets its `handles` from `convertToGUIDECallbackArguments`, which asks
  `AppManagementService.getFigure(app)` for the app's figure — and that function ignores `app` and returns the
  **first registered App Designer figure in the groot children list** (`findall(groot, ..., '-property',
  'RunningAppInstance')`), i.e. whichever registered window is in front. With the playback window on top, the main
  window's callbacks built `handles` from the playback window and failed. The same thing can happen with any
  non-modal `matlab.apps.AppBase` dialog that calls `registerApp` (the Variable Table and Constraint Status windows
  from H9 are candidates; the modal `uiwait` dialogs are not, because the main window cannot be clicked while they
  are up). The playback window therefore does **not** call `registerApp`; it reproduces the two things registration
  did that matter (deleting the app when the figure is destroyed; running `startupFcn`) itself. The other
  programmatic dialogs were left alone in this batch — worth a follow-up.
- Tests: new `ViewOverlayTest` (11: formatting, per-event interpolation and boundaries, anchors, copy, frame
  deletion, active-profile event), `RenderSceneAtTimeTest/overlayTextIsDrawnInTheMainAxesAndFollowsTime`, and in
  `ViewPlaybackGuiTest` `windowNamesTheActiveProfileAndFollowsProfileChanges`,
  `editsRecordUndoStatesAndUndoRebindsTheWindow` (presses the real Edit > Undo menu and checks the window follows the
  restored mission) and `overlayTabAddsFormatsAndRemovesQuantities` (gestures on the tab: search, choose, add, table
  edits, corner/bold/background, header lines, reorder, remove).

*Follow-up (user, same day): "when I want to create new keyframes I move the camera, but then the camera mode
goes back to Manual — make the Camera Script easier to use."* Root cause: the mouse-always-works fix treated any
camera gesture in Camera Script mode as "the user wants the camera back" and dropped the profile to Manual, which
is right for viewing and wrong for authoring, where moving the camera is how a keyframe is defined. Changes:

- **Detached state instead of Manual.** In Camera Script mode a drag or toolbar move now *detaches* the camera from
  the script (`LvdSceneCameraDriver.detachFromScript`; the mode stays Camera Script, nothing saved changes, so no
  undo state). While detached the script does not move the camera: with vehicle-relative authoring (the default)
  the camera keeps the user's azimuth / elevation / range about the vehicle as the time is scrubbed, so the vehicle
  stays framed; with scene-fixed authoring it stays where it was left. `resumeScript()` re-attaches. The saved
  manual camera is protected throughout. A mode change always ends the detachment.
- **One authoring loop on the Camera tab.** "Add Keyframe Here" (any mode) creates a keyframe at the current time
  from the current camera; "Update Selected From Camera" overwrites the selected keyframe's pose (time and
  reference type kept); "Resume Script" re-attaches without a change; playing re-attaches automatically. Add and
  Update re-attach the script, which now passes through the new pose, so nothing jumps. A bold **state line**
  always says who is driving the camera and what to do next ("Script is driving the camera (now on
  'Wide shot')…", "Camera DETACHED from the script: adjust the view, then …", Manual, Chase, empty script), and
  the buttons enable to match.
- **"New keyframes are:" [Vehicle-Relative | Scene-Fixed] "anchored to:" [start of the active event + offset |
  absolute time (UT)].** Defaults: vehicle-relative and event-anchored, so a keyframe reads "start of Event 2
  +37.5 s" and survives re-optimisation; the later event owns a shared boundary time. Vehicle-relative keyframes
  can now be created from the camera (`LvdCameraKeyframe.fromCameraRelativeToVehicle`), and the reference choice
  also sets whether a detached camera follows the vehicle.
- **Clicking a table row goes to that keyframe** (slider on its time, camera on its pose) and selects it, so
  "click, nudge, Update Selected" is the edit loop; the Preview button is gone. The table is shown in **play
  order** (sorted by resolved time, which is how `LvdCameraScript.evaluate` orders keyframes anyway) with the
  keyframe the script is currently on in **bold**; Move Up / Move Down are gone because they only ever affected
  ties. The nine position / target / up and az / el / range fields are behind a "Show numeric pose (advanced)"
  checkbox.
- Undo labels: "Update Camera Keyframe" joins the list; "Take Manual Camera Control" and "Reorder Camera
  Keyframes" are no longer produced (detaching / resuming records nothing because nothing saved changes).
- Tests: `RenderSceneAtTimeTest` — `mouseDragInScriptedModeDetachesTheCameraAndKeepsScriptMode` (mode kept,
  detached, saved camera untouched, vehicle stays framed at the dragged range while scrubbing, scene-fixed
  authoring stays put, resume restores the script pose) and `toolbarCameraModesInScriptedModeDetachTheCamera`;
  `ViewPlaybackGuiTest` — `cameraTabMirrorsMouseDrags` (state line, Resume button), `keyframesCanBeAddedEditedRemovedAndPlayed`
  (toggles, advanced-pose checkbox, row click navigation, play-order table),
  `addKeyframeHereDefaultsToVehicleRelativeEventAnchoredAndReattaches` (event 2 anchor with the right offset,
  az/el/range reproduce the camera, re-attach with no jump), `updateSelectedFromCameraReattachesTheScript`,
  `playingResumesADetachedScript`.
- **A last leak found by `toolbarCameraModesInScriptedModeDetachTheCamera`.** With the detach logic in place the test
  still failed: a toolbar orbit in Camera Script mode detached the camera correctly but the profile's *saved* manual
  camera changed anyway. Root cause was outside every `.m` file — the main window's own camera write-back handler
  `recordFinalAxesPanZoomAfterRotation` (a PostSet / `ActionPostCallback` handler that lives **inside the binary
  `.mlapp`**, so `grep` never sees it) copies the axes camera into `profile.viewCamera*` after every orbit/pan/zoom,
  with no camera-mode awareness. In Chase mode the driver's `writePose` applies a *different* pose that re-fires the
  listeners and lets the driver's restore win; in Scripted mode `reassertAxesCamera` writes the *same* dragged value,
  and a same-value property write does not reliably re-fire PostSet, so the App's handler got the last word and leaked
  the transient view into the saved camera. Fix: guard that one write-back with
  `&& lvdData.viewSettings.selViewProfile.cameraMode == LvdCameraModeEnum.Manual` (a single line patched durably
  through `lvdfixPatchMlapp`), so in Chase/Scripted mode the `LvdSceneCameraDriver` alone owns the saved manual
  camera. `lvdfixCodeDataDrift` reports the same 7 pre-existing comment-only lines and no new drift; goldens stay
  bit-identical (the main window does not touch propagation).

**Verification** (after the undo / overlay / profile-clarity batch). `ksptotRunTests('lvd_tests')`: **771 tests,
770 passed, 0 failed, 1 documented skip** (the FOV mesh-containment case that needs an absent toolbox);
`ksptotRunTests('all')`: **1295 tests, 1270 passed, 0 failed, 25 documented skips** (the same 25 as before F8). Goldens: the committed `tests/data/goldens` folder is stale
(21/23 mismatch on an unmodified HEAD, as recorded on 2026-09-15), so a fresh baseline was captured from a clean
`git worktree` of HEAD `3d7270c3` into `C:\Users\aharden\lvdfix\baseline_goldens_f8` and the working tree verified
against it: **23/23 bit-identical, 2 known skips** — F8 changes nothing about propagation. `lvdfixCodeDataDrift` on
the main window is unchanged (7 pre-existing comment-only lines, identical on the pre-F8 backup).

**Final verification (after the Camera-Script-detach batch and its `.mlapp` write-back guard, 2026-09-18).**
`ksptotRunTests('lvd_tests')`: **773 tests, 772 passed, 0 failed, 1 documented skip**
(`SensorTest/…ConeContainmentAgainstMeshWhenToolboxPresent`, which needs an absent toolbox); `RenderSceneAtTimeTest`
13/13 and `ViewPlaybackGuiTest` 19/19. Goldens against `baseline_goldens_f8`: **23/23 bit-identical, 2 known skips**.
`lvdfixCodeDataDrift` on the main window: the same **7 pre-existing comment-only lines, zero new drift** — the
`cameraMode == LvdCameraModeEnum.Manual` guard is fully in sync with the App Designer code data.

**Follow-up: a fourth camera mode — Fixed Camera (Tracking) (2026-09-18).** *"Could we also add a camera view
mode that fixes the position of the camera … but tracks the spacecraft? Sort of like what a camera at a launch
pad would do? … fix the position of the camera to either a fixed XYZ coordinate, or to a Ground Object, or to a
Geometric Point."* Added `LvdCameraModeEnum.FixedAnchor` ("Fixed Camera (Tracking)") — the mode appears in the
dropdown automatically — plus a settings class `LvdFixedAnchorCameraSettings` and an anchor-type enum
`LvdCameraAnchorTypeEnum` (Fixed Coordinates / Ground Object / Geometric Point). The pose is simply the inverse of
the chase pose: camera **at the anchor**, **looking at the vehicle**, at a fixed field of view (a new stateless
`LvdCameraMath.trackPose`). The anchor resolves into the view frame each frame: a **fixed XYZ** coordinate in a
**user-pickable reference frame** (default = the view's display frame, so a body-fixed frame rotates the anchor
with the planet like a real pad while an inertial frame keeps it put), one of the mission's **ground objects**, or
a **vehicle-independent geometric point** (vehicle-dependent points are excluded — a fixed anchor must not depend
on the thing it tracks). An unresolvable anchor (an orphaned object, or a time outside a ground object's waypoint
range) degrades to `[]`, and the driver leaves the camera untouched that frame — the same contract Chase has with
an unknown vehicle position. Opt-in and defaulting to nothing (Manual is still the default), so goldens stay
bit-identical. The mouse still always works: in the XYZ case a drag retunes the anchor via
`setFixedPositionFromCamera` and re-pins the target on the vehicle ("Move Fixed Camera by Mouse"); an object anchor
cannot be dragged, so a drag takes manual control, matching the Scripted-takeover helper. The Camera tab gained a
**Fixed Camera (Tracking)** panel (anchor-type dropdown, X/Y/Z fields with a `referenceFrameSelectComp` and a "Set
From Current Camera" button, ground-object and geometric-point dropdowns, and a view-angle field), with the
public test seams `setCameraAnchorType`, `setFixedAnchorPosition`, `setFixedAnchorFromCamera`,
`setAnchorGroundObject`, `setAnchorGeometricPoint`, `setFixedAnchorViewAngle`. The panel's anchor-type widget
groups are held as **private** cell-array properties: `AppThemer.themeApp` iterates the app's public `properties`
and `themeWidget`'s `arguments prop(1,1)` rejects a non-scalar, so a public cell-array property would break every
themed open of the window (caught by the existing `closingThePlaybackWindowInChaseModeLeavesTheMouseWorking`
test). No `.mlapp` change — the launcher menu already exists and the window is fully programmatic. New test
`FixedAnchorCameraTest` (13 cases: anchor resolution for each type, the tracking pose, `[]` fallbacks, `loadobj`
upgrade, "set from camera" round-trip, summary string); `CameraMathTest`, `ViewProfileF8PersistenceTest`,
`RenderSceneAtTimeTest` and `ViewPlaybackGuiTest` extended for the new mode.

### 7.4g Generalized Case Matrix (G1) and Monte Carlo dispersion (G2) (2026-09-23)

Built on the engine already in the tree (parameters, variations, sampler,
responses, setup/results, dual dispatch, `LvdData.caseMatrixSetup` /
`monteCarloSetup`, deprecated `LvdCaseMatrixTaskParameter` subclass,
`LvdOptimization` diary fix, `LvdOptimTableModel` element accessors) by
finishing the plan's GUI and test sections. No wind (D1 unbuilt) and no
constraint bounds as Monte Carlo sources, per the user's scoping decision;
both remain Case Matrix sweep parameters.

- **`lvd_runCaseMatrix_App.mlapp` rebuilt** with `lvdfixCanvasizeG1`
  (+ follow-ups `G1b`/`G1c`/`G1d`): the plugin-variable-only `GridLayout2`
  subtree is gone, replaced by a `CaseMatrixTabs` tab group (Parameters /
  Sampling and Run / Responses / Output / Status) plus an `OpenResultsButton`
  on the status bar — all real canvas components, 67 in the model. The
  private section comes from the plan's `g1_src/editableSection.txt`
  (setup-backed, no plugin-var gate); ~25 UI callbacks are new. The setup
  edited is `lvdData.caseMatrixSetup` itself, so trade studies persist.
- **Fixes found while wiring it:** a listbox with nonempty `ItemsData`
  reports `Value` in `ItemsData` space, so Add reads indices, not labels
  (`G1c`, same fix in the Monte Carlo window); `getEnumForListboxStr`
  returns `[enum, ind]`, which the Add-Response callback had backwards
  (`G1d`); a `uitabgroup` directly under a `uipanel` does not fill it, so
  the tabs sit in a `PanelGrid` (`G1b`). Tooling: `lvdfixCanvasize` now
  ignores blank padding when comparing the editable region with the code
  data (the untouched app differed by blank lines only) and
  `LvdfixCanvasCtx.deleteComponent` callers must purge stale order-map keys
  after a cascading delete (new `purgeStaleKeys` step in `G1`).
- **New programmatic windows** (F8 rule: no `registerApp`):
  `lvd_runMonteCarlo_App.m` (dispersion table, N/seed/workers, responses,
  run/cancel/progress, Open Results; edits a deep copy, writes
  `monteCarloSetup` back on Run) and `lvd_SweepResultsGUI_App.m` (data
  table + CSV, scatter with a two-input-grid carpet overlay, histogram/CDF,
  percentile table, 1/2/3σ covariance ellipses). Scatter vectors are
  row-aligned across NaN responses so inputs stay with their own case.
- **Main GUI:** `RunMonteCarloMenu` + `OpenSweepResultsMenu` in the
  Simulation menu after `RunCaseMatrixMenu` (`lvdfixCanvasizeG2`, canvas
  components with tooltips). Drift still exactly the 7 known pre-existing
  comment lines; case matrix app drift 0.
- **Tests (29 new):** `CaseMatrixGuiTest` (11), `MonteCarloGuiTest` (12, incl.
  a 3-sample serial run and a 2-sample button run), `SweepResultsGuiTest` (6). Engine classes 75/75,
  `CaseMatrixPluginGroundObjTest` 24/24, `OptimTablesGuiTest` 14/14.
- **Not yet done:** fresh golden baseline + full-suite run (goldens are
  stale; engine changes are sweep-only so propagation is untouched, but the
  `LvdData` properties and `executeScript` arg fix warrant the proof), and
  the interactive live check (open LVD, small propagate-only sweep +
  50-sample Monte Carlo, open results, confirm percentiles and ellipse).

### 7.4h G1/G2 follow-up fixes (2026-09-23, same day)

Live use found four defects, all fixed and covered:

- **Response double-click** adds the response in both windows
  (`RespTaskListbox.DoubleClickedFcn`; `lvdfixCanvasizeG1h` for the
  `.mlapp`, direct edit for `lvd_runMonteCarlo_App.m`), with a test in each
  GUI class.
- **Clipped button grids**: every nested grid in a fixed-height row now has
  zero padding (`lvdfixCanvasizeG1g` was a no-op — the G1 spec already had
  them; the MC/Results `.m` windows needed it).
- **`runTimeTic` saga (real root cause: `tic` returns `uint64`).** The MC
  Run button died with "Unrecognized property 'runTimeTic'". A long hunt
  through names, positions, closures and stale classes ended at the type
  system: writing the `uint64` `tic` token into a property defaulting to
  double `0` with no validation fails on R2026a/R2026b with that
  misleading error; with matching `uint64` validation it works, and the
  timer's `toc` needs the unconverted token anyway. Fix: `LastRunTic
  uint64 = uint64(0)` (renamed off the confusing name along the way).
  Lesson for this codebase: `tic`/`toc` tokens must live in `uint64`
  properties, never double-defaulted ones.
- **Case Matrix run path**: `setSetupControlsEnabled` still named the
  deleted `RespBodyDropdown` (fixed by `lvdfixCanvasizeG1j`); it assigned
  logical to `uitable.Enable`, which only takes `'on'`/`'off'`/`'inactive'`
  (fixed by `lvdfixCanvasizeG1k` with strings); `startParallelPool` crashed
  on its own error path when `uiprogressdlg` throws (`ishandle(h)` with `h`
  undefined — now guarded). Both Run buttons are now tested end-to-end:
  `MonteCarloGuiTest/pressingRunRunsTheDispersionThroughTheButton` and
  `CaseMatrixGuiTest/pressingRunInPropagateOnlyModeRunsEveryCase` (the
  latter with one worker and pool/figure teardown).

### 7.4i MC Optimize mode and per-case optimizer status (2026-09-23, same day)

Dispersion of the optimum, not just of the trajectory: the Monte Carlo
window gained an Optimize run mode (each case re-runs the optimizer,
warm-started like the Case Matrix) with live Iter / Objective / Max Viol /
Optimality columns in the status table and final objective + exit status
harvested per case into the results. No constraint-bound dispersions, an
always-confirm dialog for optimize runs, and the pool stays required.

- **Engine.** Tasks carry `optExitflag/optFval/optMaxViol/optIters/optOptim`
  (NaN in propagate mode); the final two come off the already-re-propagated
  log for ~zero extra propagations. `consoleOptimize`/`optimize` take an
  optional `progressFcn(iter,fval,viol,optim)`; all seven optimizers attach
  a GUI-free headless reporter next to (never instead of) the Observe-window
  one, reusing each solver's native hook (OutputFcn, iterfun, IterationFcn).
  Dispatch sends progress through one per-run DataQueue as a direct parfeval
  argument; tasks merge the recorded fields back through both merge paths.
  Results gain `objectiveValues`/`exitflags` (+ table columns, omitted when
  all-NaN so propagate tables are unchanged) and `exitStatusTag`
  (Converged/Limit/Failed/Error).
- **No nested parallelism.** Case runs force the selected optimizer's
  options to serial on the worker clone (one generic helper over all seven
  options classes, Adam's `parallel` included) and restore via explicit call
  before the post-run save plus an `onCleanup` backstop — finish, stop and
  error paths all covered; the template is never touched.
- **Windows.** MC Sampling & Run tab gained run mode, max attempts and case
  files (forced on + locked in Optimize); the Case Matrix window streams the
  same live columns (`lvdfixCanvasizeG1n`, no model change).
- **Two R2026 fixes this work required** (both pre-existing, both block any
  optimization on R2026, both verified by `OptimizerSmokeTest` 12/12):
  `lvd_executeOptimProblem` choked on string-valued `UseParallel`, and the
  vendored `sqp` solver on `DerivativeCheck` (guarded) and a string
  `UseParallel` comparison (guarded) — minimal, behavior-preserving guards
  with repo precedent for patching the vendored file.
- **Tests:** `SweepOptimizeRunTest` (5: serial forcing + restore, one real
  single-task fmincon run harvesting everything incl. the live listener,
  exit tags, propagate-table stability, header/data width match),
  `MonteCarloGuiTest` gains (mode/persist/attempts logic, progress routing,
  pool-gated optimize button run), `CaseMatrixGuiTest` gains (pool-managed
  propagate button run), legacy table guards updated to the widened shape.

### 7.4j Seed control, setup persistence, tooltips (2026-09-23, same day)

- **Random vs fixed seed.** Both windows have "Random each run" next to the
  Seed field (`LvdSweepSetup.randomizeSeedEachRun`, persisted, backfilled on
  load). On: the field + one-shot button disable and a fresh seed is drawn
  at run start, recorded in the results. Off: the field value is used.
  Headless `runHeadless` stays deterministic (no draw). Case Matrix via
  `lvdfixCanvasizeG1o`.
- **Sampling mode now sticks.** The MC window edits a deep copy that only
  reached the mission on Run, so sampling/mode/response edits were lost
  when the window closed first (reproduced headless). The close path now
  writes the copy back (`onCloseRequest` + destroy listener, both
  idempotent), so every edit persists across save/load.
- **Tooltips everywhere.** Audited all three windows; every button, field,
  dropdown, checkbox, listbox and table now has one (Case Matrix via
  `lvdfixCanvasizeG1p`, drift 0).

### 7.4k Stored Monte Carlo runs on the mission (2026-09-23, same day)

- `LvdData.monteCarloResults`: named runs accumulate newest-last and travel
  with the mission file (results are plain numbers, no mission objects).
  Managed in a new Stored Runs tab (Store Results on Status, Open/Delete on
  the tab); names auto-unique (`X`, `X (2)`, ...); independent copies, so
  later runs never rewrite stored ones.
- Case-bound clones shed stored results (`setCaseLvdData`,
  `prepareAndRunCase`) so per-case files and worker traffic stay lean; the
  template keeps everything. Covered by save/load roundtrip, uniqueness,
  delete, and leanness tests.

### 7.4l Excluded-case banners and editable run titles (2026-09-23, same day)

- Failed/unconverged cases appear in both tables but were silently dropped
  from scatter, histogram, CDF and ellipses. The Scatter and Statistics tabs
  now banner "N of M plotted/valid (K excluded...)" from the same validity
  masks, so survivorship bias is visible.
- Runs are titled via `LvdSweepSetup.runName` (MC default `MonteCarlo`),
  editable in a new Run Name field and used for the results files; the Case
  Matrix uses its setup value instead of the `Sweep` literal
  (  `lvdfixCanvasizeG1q`).

### 7.4m Coverage sweep: banners, titles, callback wiring (2026-09-23, same day)

A coverage audit of the newest UI found real gaps, all closed: banner
branches (all-valid, empty, dropdown-following), run-name file naming both
windows, stored rename incl. taken-name suffixing, the Store button's own
wiring (its closure passed `(src,evt)` to an `(app,evt)` method -- the
dispersion-table edit callback had the same latent arity bug, also fixed
and now tested), dispersion cell edits, grid cell edits, stored-open
wiring, setup name defaults, blank-name fallback and out-of-range deletes.
`SweepResultsGuiTest` 10/10, `MonteCarloGuiTest` 29/30 (1 pool-gated skip),
`CaseMatrixGuiTest` 13/13, all fresh.

### 7.4n Optimize-mode pin fixes and pre-run guard (2026-09-24)

A Monte Carlo Optimize run that dispersed the mission's only enabled
variables failed every case with "no optimization variables enabled" while
the untouched template still optimized -- two defects plus a missing guard:

- Rebinds match id AND class.  Variable (and constraint) ids are not
  unique across classes: the complex-drag mission carries distinct
  variables sharing one id, so an optimization-variable dispersion
  rebound onto the wrong variable, wrote its value there, and pinned the
  wrong mask.  New parameters record the class; older setups without one
  keep the previous id-only first hit.
- Knob (and plugin) pins land on the optimizer's own set member, matched
  by id and class, instead of the target's possibly detached `optVar`
  twin -- pinning the twin silently did nothing and the optimizer moved
  the "dispersed" quantity anyway.  Falls back to the twin when no member
  is found, preserving direct applies outside a run.
- `LvdSweepSetup.validate` refuses an Optimize run whose dispersions
  would switch off every enabled element (counted against the same
  scaled-x vector the optimizer reads, duplicates deduped), naming the
  offending dispersions; a mission with nothing enabled is refused with
  its own message.  Both windows gate on `validate`, so both are covered.
  New `SweepOptimGuardTest` (6 tests); `SweepParameterTest` gains the
  class-discriminated rebind, the legacy fallback, the detached-twin pin
  and the plugin pin/pairs tests; the pool-gated MC optimize test now
  enables a variable first (the default mission ships with none). Stored runs rename inline in the Stored Runs table
  with uniqueness enforced. Also fixed en passant: two CellEdit callbacks
  passed `(src,evt)` to `(app,evt)` methods (same arity bug as the Store
  button), found by auditing every closure in both programmatic windows.

### 7.5 Live check in the interactive session

KSPTOT was started with `projectMain` and LVD opened from it. Confirmed: File menu ends `… Export Ephemeris... |
Exit Launch Vehicle Designer`; Optimization menu ends `Variable Table... | Constraint Status Table... |
Objective/Constraint Sensitivities...`; the script-list context menu has `Advanced Event Options...` and
`Expand/Collapse Event Group` directly under `Edit Event`; the non-sequential list has its new context menu; both
shim methods exist. Variable Table and Constraint Status windows open themed and populated; the sensitivities
callback handles a mission with no variables gracefully. The Advanced Event Options dialog opened from its menu,
its **Add** button appended a condition (and, as designed, opened the single-condition editor for it) and the
event afterwards held two conditions. Driving the remaining dialogs by timer from the interactive session got
tangled in nested modal dialogs, so the authoritative UI coverage is the headless `PatchedMlappDialogsTest` /
`EditEventDialogTest` / `LvdMainGuiInteractionTest` runs above; the interactive MATLAB session may still have a dialog
open that needs closing by hand. (This check predates §7.4b/§7.4c; the menu items it lists are now canvas components
and the Advanced Event Options dialog no longer exists.)

### 7.6 Tooling left in `C:\Users\aharden\lvdfix\`

`lvdfixCodeDataDrift` (the real drift check), `lvdfixResyncMlappCode` / `lvdfixResyncAll` (code-data rebuild),
`lvdfixPatchMlapp` (line-level durable patches), `lvdfixApplyF6Patches`, `lvdfixApplyDialogFixes`,
`lvdfixApplyShimFix`, `lvdfixGoldens` (baseline capture/verify), `lvdfixRebuildEditEventApp` (§7.4b),
`lvdfixCanvasize` / `LvdfixCanvasCtx` / `lvdfixCanvasizeAll` (§7.4c — the reusable "add components to a `.mlapp`
model" tool), `lvdfixDumpModelTree` (prints an app's component model), plus backups of every `.mlapp` before each
write (`backup_*` folders).

### 7.7 H8 — search, filter and tagging in the large list boxes (2026-09-24)

Live filtering remains in the constraints, variable, geometry and GA task dialogs; the sequential and
non-sequential event lists intentionally have no search controls. Every remaining search field uses
`uieditfield` `ValueChangingFcn` (filtered on `event.Value`; the field's own `Value` is never written from the
callback) with `ValueChangedFcn` as the programmatic/focus-loss fallback, mirroring the F8 data-overlay
search box. Filtering is strictly view-only — labels are filtered, the domain arrays are never reordered,
and selection is tracked by object handle (constraint/geometry/GA handles; variable handle plus x-vector
index), with prior-selection restore when a query broadens and no silent auto-select of the first match.

- **Shared matching** — `helper_methods/ksptot_lvd/gui/lvd_filterListboxItems.m` provides trimmed,
  case-insensitive substring matching with a logical keep-mask; `lvd_selectVisibleListValue.m` preserves
  object-based selection in the constraints, variable and geometry dialogs.
- **Model** — `LaunchVehicleEvent.tags` and inherited `AbstractConstraint.tags` remain `char = ''`, so old
  missions load unchanged. Event tag suffixes (`[#...]`) appear in event rows, and constraint tag suffixes
  appear in constraint rows. `getSearchText` and `getFilteredListboxStr` remain available as model-level
  helpers, but no main-window callback consumes them after the event search areas were removed.
- **Apps (10 `.mlapp`, all real canvas components via the §7.4c serializer round trip)** — `EventTagsText` on
  the Edit Event Advanced tab, search + tags/Apply in the constraints dialog, search in the variable dialog
  (dropdown carries original x-indices in `ItemsData`), search in all six geometry browsers, and the GA picker
  keeps `SearchTaskText` with selection-preserving, custom-propellant-name-preserving filtering. Modal
  Enter-to-close handlers ignore the search/tag fields.
- **Tests (13 new)** — `H8ListFilterTest` (8 model-level matcher/filter/tag tests) and `H8SearchGuiTest`
  (5 dialog tests covering event-tag round trips plus constraints, variables, geometry and GA search, including
  no-match `ValueChanging`/`ValueChanged` paths, disabled-control behavior, query recovery and warning-free
  empty filtering). Code-data drift is maintained for the ten modified apps; the main app was restored to its
  last valid H6 model after the two event search fields were removed.

---
---
