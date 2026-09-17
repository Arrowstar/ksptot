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

---
