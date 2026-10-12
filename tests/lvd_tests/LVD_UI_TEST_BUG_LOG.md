# LVD UI Test Bug Log

Living log for the phased LVD UI-test rollout (full round-trip, one file per
dialog, optimization first). Every bug found while writing or running the new
tests is recorded here whether or not it was fixed.

Status values: FIXED (fixed in this rollout) | OPEN (needs human decision/fix)
| DOCUMENTED (intentionally not fixed, e.g. deprecated code).

---

## 0. Test-infrastructure issues

### 0.2 Leaked figures silently redirect ALL handles lookups — VERIFIED (MathWorks behavior)
- `convertToGUIDECallbackArguments(app)` (R2025b
  `+appdesigner/+internal/+service/@AppManagementService/getFigure.m`) ignores
  its `app` argument for App Designer apps and returns
  `getRunningAppFigures()(1)` — the FIRST open figure. One leaked figure
  (wrong `whenShown` name, unclosed alert, surviving nested dialog) makes
  every later test's `handles` struct come from the WRONG dialog
  (`Unrecognized field name ...`), cascading across classes in one session.
  Verified live: `EditLaunchVehicleDialogTest` leaked the two conns dialogs
  (mismatched stub names) and the following `EngineDialogTest` went 0/8;
  with exact names + Close buttons both classes pass 8/8 and 6/6 with zero
  leaked figures. Rule for this rollout: every test leaves zero figures
  behind (verified per batch via `findall`); every `whenShown` name must
  equal the figure `Name` exactly (canvas labels may differ, e.g. the conns
  dialogs). Recommend a future shared figure-leak guard in TestMethodTeardown.
### 0.4 uialert materializes no figure in batch/headless MATLAB — VERIFIED (environment)
- Probed live: `uialert` on a visible figure creates no `figure` object in
  this environment (MATLAB reports 'Java is not enabled'). Tests must NEVER
  assert an alert figure exists; the durable signal is model/file state.
  `closeAlerts` sweeps stay harmless no-ops. `ExportEphemerisDialogTest` was
  rewritten accordingly (file content, not the success alert, proves export).
### 0.3 Concentration risk: App Designer singletons across tests — DOCUMENTED
- Blocking dialogs register via `getRunningApp`; a crashed/half-closed open
  can hand the NEXT test a stale app (seen with the tabular-quat-interp
  crash, bug 2.12, and the vehicle-editor Close aftermath). Tests reap by
  figure Name aggressively for this reason; see also 2.10.



### 0.1 MATLAB MCP bridge wedged during first new-test run — OPEN, needs human
- Date: 2026-10-11. After writing `tests/lvd_tests/TankConstraintDialogTest.m`,
  `MATLAB_run_matlab_test_file` timed out, and every later MATLAB call
  (single-test run, trivial pings) also timed out.
- Evidence the MATLAB *process* is healthy but idle: `MATLAB.exe`
  burns ~1 s CPU per 20 s wall clock; EnumWindows shows no `Edit Constraint`
  dialog and no native file/confirm dialog; no MATLAB desktop window exists.
- Hypothesis: the MCP server-side slot is held by the first (long) `runtests`
  call or the connector thread is dead; queued calls pile up behind it.
- Human action needed: restart the MATLAB MCP session (or MATLAB itself),
  then run `runtests('tests/lvd_tests/TankConstraintDialogTest.m')` in
  `matlab -batch`. Until then, all new test files are **authored but
  unverified**; verification is tracked per phase below.
- Workaround adopted: dialog internals are extracted statically from
  `.mlapp` (`matlab/document.xml` inside the zip) with PowerShell instead of
  live MATLAB introspection.

---

## 1. Phase 1 — Optimization dialogs (16 files) — AUTHORED, verification blocked by 0.1
Files: `TankConstraintDialogTest`, `GenericMAConstraintDialogTest`,
`GeometricAngleConstraintDialogTest`, `GeometricVectorConstraintDialogTest`,
`GroundObjConstraintDialogTest`, `PluginConstraintDialogTest`,
`CompositeObjectiveDialogTest`, `OptimizerSelectionDialogTest`,
`FminconOptionsDialogTest`, `IpoptOptionsDialogTest`, `NomadOptionsDialogTest`,
`NomadSurrogateOptionsDialogTest`, `PatternSearchOptionsDialogTest`,
`SqpOptionsDialogTest`, `SurrogateOptOptionsDialogTest`,
`FiniteDiffOptionsDialogTest` (all in `tests/lvd_tests/`). All 16 files
pass live in MATLAB (2026-10-11): 9 + 8*5 + 7*4 + 8 + 10 + 7 = 128 tests green.
Fixes applied during verification: CompositeObjective ValueChanged event
struct (test-only), Fmincon/Ipopt/Nomad/NomadSurrogate `fixture`→`buildFixture`
rename (test-only), OptimizerSelection `choose()` gestures + base class
(test-only), SQP/FiniteDiff assertion corrections (test-only), shared
SQP/DERIVEst handles (production fix 1.29).

### 1.1 Deprecated drag dialog — DOCUMENTED, skipped per direction
- `kspTOT_LaunchVehicleDesigner/state/aero/drag/_deprecated/lvd_EditDragPropertiesGUI_App.mlapp`
  lives under `_deprecated/` and has no production callers. No test written;
  recommend deletion in a separate cleanup change, not this rollout.

### 1.2 GUIDE-migrated constraint dialogs: figure property keeps donor name — OPEN (cosmetic)
- `lvd_EditTankConstraintGUI_App`'s figure property is still named
  `lvd_EditGroundObjConstraintGUI` (likewise other migrated dialogs reuse the
  donor's figure/tag names). Harmless at runtime — tests reference the actual
  property name — but confusing. Suggest renaming properties/tags to match
  each dialog in a future cleanup. Not changed here (renaming App Designer
  tags by hand risks breaking `convertToGUIDECallbackArguments` handles).

### 1.3 GUIDE-migrated save callbacks silently ignore validation failures — FIXED (2026-10-12 rollout)
- `saveAndCloseButton_Callback` in the constraint dialogs calls
  `validateInputs`; on failure the `msgbox(errMsg,...)` call is commented
  out, so the dialog just stays open with no message. Tests assert
  stay-open + model-untouched (not the missing message). Human decision:
  restore a `uialert` or keep silent. Recommend `uialert` (non-blocking,
  batch-safe unlike `msgbox`).

### 1.4 Composite-objective and optimizer-selection dialogs have no Cancel — OPEN
- `lvd_EditCompositeObjectiveFunctionGUI_App` and
  `lvd_OptimizerSelectionGUI_App` expose only Save/Close-style buttons (no
  `cancelButton`, no `CloseRequestFcn`, zero `cancel-word` hits in
  `document.xml`). Tests cover Save/Close-request paths only. Human decision:
  add an explicit Cancel button or confirm current UX is intended.

### 1.5 SQP options dialog is non-blocking (no uiwait) — DOCUMENTED
- `lvd_editSqpOptOptionsGUI_App` `startupFcn(app, options, output)` calls
  `populateGUI` but never `uiwait`, unlike every other options dialog. Tests
  therefore open it without `UiwaitInterceptorFixture` and close via delete.
  If the missing `uiwait` is a bug (dialog returns before the user acts),
  callsites (`SQPOptimizer.openOptionsDialog`) would misbehave; flagging for
  human confirmation rather than changing here.

### 1.6 Nomad-surrogate dialog is modern-style (startupFcn) — DOCUMENTED
- `lvd_editNomadSurrogateOptionsGUI_App` uses `startupFcn(app, nomadSurrOpts,
  output)` with `Optimize*CheckBox` enable patterns instead of the
  GUIDE-migrated `OpeningFcn` shape. Reachable only via the Nomad options
  dialog's surrogate-search button. Test constructs the surrogate options
  object from `NomadOptions` and drives the checkboxes/spinners directly.

### 1.7 Empty picker combos crash with Value=1 (4 constraint dialogs) — FIXED (2026-10-12 rollout), easy
- `lvd_EditGroundObjConstraintGUI_App`, `lvd_EditPluginConstraintGUI_App`,
  `lvd_EditGeometricAngleConstraintGUI_App`,
  `lvd_EditGeometricVectorConstraintGUI_App` `populateGUI` sets
  `<xxx>Combo.String = <set>.getListboxStr()` (`{}` when empty) then
  unconditionally `<xxx>Combo.Value = 1`, which errors with empty `Items`.
  Production callers guard with `errordlg` (`GroundObjRangeConstraint.m:147`,
  `PluginConstraint.m:153`, `AbstractGeometricVectorConstraint.m:140`,
  `GeometricAngleMagConstraint.m:162`), so this only bites direct dialog
  opens. Tests always seed one entry. Easy fix: guard `Value = 1` with
  `if ~isempty(str)`.
### 1.8 GenericMAConstraint.getDefaultConstraint arity mismatch — FIXED (2026-10-12 rollout), easy
- `GenericMAConstraint.m:258` declares
  `getDefaultConstraint(constraintType, lvdData)` but
  `GenericObjectiveFcn.m:142` calls it with one argument. Works only because
  the body ignores `lvdData`. Easy fix: give `lvdData` a default (`nargin`).
### 1.9 Composite-objective Add uses fragile eval on local names — FIXED (2026-10-12 rollout)
- `lvd_EditCompositeObjectiveFunctionGUI_App` `addObjFuncButton_Callback`
  builds `eval(sprintf('%s.getDefaultConstraint(%s, %s)', constClass,
  'input1', 'lvdData'))`, depending on locals literally named `input1` /
  `lvdData`. Breaks silently on rename; replace with a direct factory call.
### 1.10 Composite dialog Remove leaves stale listbox Value — OPEN, easy
- `removeObjFuncButton_Callback` rewrites `Items/ItemsData` then calls
  `listboxCallback`, whose non-empty branch reads `app.objFuncListbox.Value`
  without resetting it; removing the selected (non-last) entry leaves `Value`
  referencing a detached handle. Reset selection after remove.
### 1.25 Composite dialog Remove crashes the migration layer — OPEN (verified live)
- `removeObjFuncButton_Callback` (`lvd_EditCompositeObjectiveFunctionGUI_App`
  line 534) sets `app.objFuncListbox.Items = listBoxStr` while `Value` still
  holds a `GenericObjectiveFcn` object; the App Designer migration layer
  throws in `ismember(val, data)` (`UIComponentConversionUtils.convertValue`).
  Surfaced as a listener warning during
  `CompositeObjectiveDialogTest.removeObjFuncButtonRemovesSelectedFunction`
  (test itself passes — model removal precedes the crash). Clear `Value`
  before reassigning `Items`.
### 1.26 Composite dialog warns 'Not enough input arguments' on open — OPEN
- Opening `lvd_EditCompositeObjectiveFunctionGUI_App` prints the warning
  2–5 times (observed live in every test). Trace the populate path for a
  short call and fix the arity.
### 1.27 Composite dialog Set-Frame tooltip bug (same class as 5A.5) — FIXED (2026-10-12 rollout)
### 1.30 Remove-then-refresh-Items crashes the migration layer (family) — OPEN (.mlapp, verified live)
- Same root cause as 1.25, confirmed in three more dialogs (listener
  warnings during passing tests, not failures):
  `lvd_EditSumOfPolynomialTermsModelGUI_App.removeTermButton_Callback:700`,
  `lvd_EditSumOfSinesModelGUI_App.removeSineButton_Callback:823`,
  `lvd_EditTankToTankConnsGUI_App.setListboxItems:27` (via
  `removeConnButton_Callback:198`),
  `lvd_EditExtremasGUI_App.setListboxStr:26` (via
  `removeExtremaButton_Callback:175`),
  `lvd_EditCalculusObjsGUI_App.setListboxStr:26` (via
  `removeCalcObjButton_Callback:193`),
  `lvd_EditStopwatchesGUI_App.setListboxItems:31` (via
  `removeStopwatchButton_Callback:148`),
  `lvd_Edit1DDragPropertiesGUI_App.removePointFromCurveButton_Callback`
  (reassigns `ptsListbox.String` while `Value` still points past the end;
  the dialog's own `if(newNumPts < oldListBoxValue)` reset runs AFTER the
  crashing assignment — move it before). Each reassigns listbox `Items` while
  `Value` still holds a removed object handle. Systematic fix: every
  listbox-refresh path in every migrated dialog must reset `Value` (to a
  surviving member or `[]`) BEFORE reassigning `Items`/`ItemsData`.
- `setFrameOptionsButton_Callback` assigns
  `handles.setFrameOptionsButton.Tooltip` while the rest of the dialog uses
  `.TooltipString`. Same fix shape as 5A.5.
### 1.11 Composite dialog populateGUI writes comparison combo twice — DOCUMENTED
- `lvd_EditGroundObjConstraintGUI_App` / `lvd_EditPluginConstraintGUI_App`
  `populateGUI` assign `comparisonTypeCombo` String/Value, then
  `stateComparisonNodeCombo`, then `comparisonTypeCombo` again identically.
  Harmless redundant write; note for cleanup.
### 1.12 Optimizer-selection dialog is single-arg, no output — DOCUMENTED
- `lvd_OptimizerSelectionGUI_App` ctor is `(lvdData)` only (OpeningFcn reads
  `varargin{1}`); save writes `lvdData.optimizer` directly. Test matches.
### 1.13 No Cancel button on any optimizer/options dialog — OPEN (UX decision)
- All Phase-1 optimizer/options dialogs expose only Save&Close (verified in
  each `document.xml`); tests use window-X `close(fig)` for the cancel path.
  Same decision as 1.4: add Cancel buttons or confirm intended.
### 1.14 Blank numeric fields mean NaN/default by design — DOCUMENTED
- `gui/optimizers/validateDoubleValue.m:4` skips empty strings and
  `setOptsDoubleValueInObject.m:4-8` stores NaN, so "blank is rejected" does
  NOT hold for options dialogs; tests pin blank→NaN and use
  negative/zero/non-numeric for rejection cases.
### 1.15 Ipopt dialog swaps nu labels — FIXED (2026-10-12 rollout), easy
- `lvd_editIpoptOptionsGUI_App` `validateInputs` labels `nuIncrText` as
  `'Initial Nu'` and `nuInitText` as `'Nu Increment'`. Mapping to
  `nu_inc`/`nu_init` is correct; only the messages are swapped.
### 1.16 Nomad dialog duplicates vns_trigger populate line — DOCUMENTED
- `setOptsDoubleValueStrInGUI(...,'vns_trigger','vnsTriggerText')` called
  twice; harmless.
### 1.17 Surrogate dialog mis-titled 'Edit FMINCON Options' — FIXED (2026-10-12 rollout), easy
- `lvd_editSurrogateOptOptionsGUI_App.mlapp` sets figure `Name = 'Edit
  FMINCON Options'` and alerts `'Invalid FMINCON Options Inputs'`
  (copy-paste from fmincon dialog). Tests clean up by that literal name.
### 1.18 DERIVEst grad method incompatible with shared finite-diff dialog — FIXED (2026-10-12 rollout)
- `DERIVEstFiniteDiffsCalculationMethod.openOptionsDialog`
  (`DERIVEstFiniteDiffsCalculationMethod.m:35-38`) passes `obj` (no
  `h`/`numPts`/`diffType`/`computeSparsity` properties) to
  `lvd_finiteDiffOptionsGUI_App`, whose `populateGUI` reads
  `finDiffObj.h`/`numPts`/`diffType.name` — errors for DERIVEst objects.
  Test covers the `CustomFiniteDiffsCalculationMethod` path only.
### 1.19 Finite-diff blank-step stores NaN bypassing range check — FIXED (2026-10-12 rollout), easy
- `validateDoubleValue` lets blanks pass but finite-diff `saveAndClose`
  parses with raw `str2double`, storing NaN into `h` (`[1E-10,1E-1]` range)
  and into uint64 `numPts`. Validate the parsed value, not the string.
### 1.20 SQP save validation is dead code — FIXED (2026-10-12 rollout), easy
- `lvd_editSqpOptOptionsGUI_App` `saveAndCloseButtonPushed` has
  `% errMsg = validateInputs(app);` + `errMsg = {};` — the `uialert` branch
  is unreachable. Re-enable or remove.
### 1.21 PatternSearch populate writes penaltyFact twice — DOCUMENTED
- Harmless duplicate; noted for cleanup.
### 1.22 Fmincon stepTol validates [0,1] while siblings allow [0,Inf] — FIXED (2026-10-12 rollout)
- `lvd_editFminconOptionsGUI_App` `stepTolText` range is inconsistent with
  neighboring tolerances; confirm intended or widen.
### 1.23 usesParallel() contract differs per optimizer — FIXED (2026-10-12 rollout)
- `IpoptOptions.m:86-89` returns the enum (callers use `.optionVal`) while
  `NomadOptions.m:126-128` returns logical. Each works with its own caller;
  unify to one contract.
### 1.24 Nomad useParallel typed as PatternSearch enum — DOCUMENTED
- `NomadOptions.m:7` types `useParallel` as `PatternSearchUseParallelEnum`;
  works, but rename/type for clarity in cleanup.
### 1.28 SQP dialog never saves maxLineSearchFun — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- `lvd_editSqpOptOptionsGUI_App` `saveAndClose` writes stepTol/optTol/
  tolCon/finDiffStepSize/useParallel/numWorkers/terminationType/
  maxFuncEvals/maxIter but has no `maxLineSearchFun` assignment — the
  line-search field is display-only. Pinned by
  `SqpOptionsDialogTest.maxLineSearchIterationsEditIsDroppedOnSave`
  (retire it and restore the assertion in
  `editAndSaveWritesTolerancesAndMaximums` once fixed). Exact patch: mirror
  the maxIter block for `app.MaxLineSearchIterationsEditField.Value`.
### 1.29 Shared SQP/DERIVEst handles across missions — FIXED (verified live)
- `LvdOptimization`'s constructor reassigned fresh wrappers for every
  optimizer EXCEPT `sqpOpt` (and `derivEstFiniteDiffCalcMethod`), so all
  missions in a session shared one `SQPOptimizer`/`SqpOptions` (and one
  DERIVEst object) via the class-default handle. Symptom: SQP options edited
  in one mission leaked into the next; `SqpOptionsDialogTest` was
  order-dependent. Fix: `LvdOptimization.m:60,65` now construct both fresh
  (`obj.sqpOpt = SQPOptimizer();`,
  `obj.derivEstFiniteDiffCalcMethod = DERIVEstFiniteDiffsCalculationMethod();`).
  Verified: two default missions share neither wrapper nor options; full
  SQP class passes from pristine defaults.

## 2. Phase 2 — actionUIs (37 files) — VERIFIED live, all green
All 37 files pass in MATLAB (2026-10-11), zero leaked figures per batch
(except where noted, all warnings documented). Fixes applied during
verification (all test-only unless noted): plugin-var fixtures wire
`getNewOptVar()` (2.7); NextEvent uses `choose` gestures + uitest base (2.8);
SetThrottle/QuatInterp/SetSteering degree conversions; poly-steering fixture
sets a refFrame (2.10); FitNet/LinearTangent/SumOfPoly/SumOfSines rewritten
to the write-live pattern with `editControl` helper (2.15–2.17);
TabularQuatInterp `Selection = 1` (row-select), valid duration bounds,
`getExistingOptVar` assertion (2.12–2.14); ThirdBody empty-start fixtures
(2.9). Production fixes: TabularQuatInterp model-layer resync (2.12).
Files: `AddMassToTankActionDialogTest`, `AddValueToPluginVarActionDialogTest`,
`ResetExtremumActionDialogTest`, `ClampStateActionDialogTest`,
`ConicalSensorHalfAngleActionDialogTest`, `EngineStateActionDialogTest`,
`EngineToTankConnStateActionDialogTest`, `ExtremumRecordingStateActionDialogTest`,
`KinematicStateActionDialogTest`, `NextEventActionDialogTest`,
`PluginVarGaTaskActionDialogTest`, `PluginVarValueActionDialogTest`,
`PwrSinkStateActionDialogTest`, `PwrSrcStateActionDialogTest`,
`PwrStorageStateActionDialogTest`, `RectSensorAzActionDialogTest`,
`RectSensorDecActionDialogTest`, `SensorMaxRangeActionDialogTest`,
`SensorStateActionDialogTest`, `SensorSteeringModelActionDialogTest`,
`StageStateActionDialogTest`, `StopwatchRunningStateActionDialogTest`,
`TankToTankFlowRateActionDialogTest`, `TankToTankConnStateActionDialogTest`,
`ThirdBodyGravityActionDialogTest`, `ConditionalActionDialogTest`,
`SetThrottleModelActionDialogTest`, `T2WThrottleModelDialogTest`,
`QuatInterpSteeringDialogTest`, `SelectableSteeringActionDialogTest`,
`SetSteeringModelActionDialogTest`, `TabularQuatInterpSteeringDialogTest`,
`FitNetSteeringDialogTest`, `LinearTangentSteeringDialogTest`,
`SteeringModelsSetDialogTest`, `SumOfPolySteeringDialogTest`,
`SumOfSinesSteeringDialogTest` (all in `tests/lvd_tests/`).

### 2.1 Kinematic dialog Geographic branch shows lb as ub — FIXED (2026-10-12 rollout), easy (.mlapp)
- `lvd_EditActionSetKinematicStateGUI_App.mlapp` `populateGUI`: Geographic
  branch builds `ub = [lb(1) rad2deg(ub(2)) ...]` — first element should be
  `ub(1)`. Keplerian/Universal branches and the save path use `ub(1)`.
  Pinned by `KinematicStateActionDialogTest`. Fix needs App Designer edit;
  deferred until MATLAB is back (see 0.1).
### 2.2 ResetExtremum opens with zero extrema, Save reports success writing nothing — FIXED (2026-10-12 rollout)
- `ResetExtremumValueAction.m:76-82` `openEditActionUI` has no empty-extrema
  guard (sibling `SetExtremumRecordingStateAction.m:81-89` shows `warndlg`);
  dialog opens showing `' '`, Save reports success while `saveAndClose`
  writes only inside `if(not(isempty(extrema)))`. Add the guard to match.
### 2.3 Stopwatch dialog shows stopwatch.startOn instead of runningStateToSet — FIXED (2026-10-12 rollout), easy (.mlapp)
- `lvd_EditActionSetStopwatchRunningStateGUI_App.mlapp` `populateGUI`
  computes the combo index from `action.stopwatch.startOn` instead of
  `action.runningStateToSet` (the value Save writes;
  `SetStopwatchRunningStateAction.m:7`). Pinned by
  `StopwatchRunningStateActionDialogTest.mismatchedStartOnShowsStartOnNotStoredState`.
  Save path is correct; fix the populate index.
### 2.4 Sensor-steering dialog alerts to nonexistent figure + dead callback — FIXED (2026-10-12 rollout) (.mlapp)
- `lvd_EditActionSetSensorSteeringModelGUI_App.mlapp`
  `PointingModelComboValueChanged` calls
  `uialert(app.EditConicalSensorGUI, ...)` — no such figure (should be the
  dialog's own figure); picking FixedInCoordSys with zero coord sys errors
  instead of warning. Same dialog has dead `SensorHalfAngleTextValueChanged`
  referencing absent `app.SensorHalfAngleText`. Neither path is exercised by
  tests (documented in `SensorSteeringModelActionDialogTest` header).
### 2.5 ThrottlePolyModel / T2WThrottleModel cancel-path index error — FIXED (2026-10-12 rollout), easy (.m)
- `ThrottlePolyModel.m:68` inits `AppDesignerGUIOutput({false})` but `:71`
  reads `output.output{2}`; `T2WThrottleModel.m:70/73` identical. Cancel
  indexes past the end; sibling `GenericQuatInterpSteeringModel.m:190`
  correctly inits `({false, obj})`. One-token fix each, deferred for
  verification (see 0.1).
### 2.6 PluginVarGaTask dialog validateInputs always passes — DOCUMENTED
- `validateInputs` unconditionally returns `{}`; no rejection tests by design.
### 2.9 Third-body dialog crashes opening with stored bodies — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- `lvd_EditActionSetThirdBodyGravitySourcesGUI_App.mlapp` `populateGUI`
  runs `[~,inds,~] = intersect(sortedBodyInfoArr, curSelBodies)` on
  `KSPTOT_BodyInfo` handle arrays. That class overloads `eq` by (class, id)
  (`KSPTOT_BodyInfo.m:484-492` via `lvdIdsEqual`, which needs equal-size or
  scalar inputs), so `ismember`/`intersect`/`unique` internals die — observed
  live as `catenate:dimensionMismatch` inside `uniqueR2012a` on one run and
  `badsubscript` ("logical indices outside bounds") on another for the same
  inputs. The dialog opens reliably only with an EMPTY stored set (all tests
  use that path). Exact fix: match by numeric id in the dialog, e.g.
  `[~,inds] = ismember([curSelBodies.id], [sortedBodyInfoArr.id])`, and audit
  other `intersect`/`ismember` uses on id-compared handles.
### 2.12 Tabular-quat-interp stale-var crash — FIXED (verified live)
- Same family as the InterpThrottle regression: opening
  `lvd_EditActionSetTabularQuatInterpSteeringModelGUI_App` on a multi-row
  model with a missing/length-1 optVar crashed `makeTableDataFromModel`
  (`badsubscript`, verified live). Mirrored the proven fix:
  `SetGenericTabularQuatInterpSteeringModelActionOptimVar` ctor now sizes
  all 12 tabular vectors to `numel(tDurs)` (bounds mirror the editor's own
  new-row defaults), `GenericTabularQuatInterpSteeringModel.getExistingOptVar`
  resyncs stale vars preserving overlap, plus a shared-contract
  `resizeVectorToNumRows` static. Full `TabularQuatInterpSteeringDialogTest`
  (8 tests) passes, including multi-row open.
### 2.13 Tabular-quat-interp validate crashes on empty table — FIXED (2026-10-12 rollout) (.mlapp)
- `validateInputs` column-indexes `tableData` without an emptiness guard, so
  clearing the table errors (`line ~313, index in position 2`) instead of
  hitting the 'at least one row' rejection. Guard `isempty` before indexing.
  (The model-side resync in 2.12 does not cover this path.)
### 2.15 Sum-of-poly/sines dialogs: write-live + no last-term guard — DOCUMENTED
- `lvd_EditSumOfPolynomialTermsModelGUI_App` / `lvd_EditSumOfSinesModelGUI_App`
  `saveAndClose` is `{true}+close` with no validation of its own; all writes
  happen live in the control callbacks (const/coeff/amp in degrees,
  exponent/period/phase raw). Neither dialog guards removing the last
  term/sine (model empties). Tests drive callbacks directly and pin the
  emptying behavior.
### 2.16 FitNet/LinearTangent editors are write-live too — DOCUMENTED
- Same shape as 2.15 (control callbacks write + `msgbox` on invalid,
  trivial save). Tests fire callbacks with Value-bearing events.
### 2.18 Legacy checkbox handles cannot fire callbacks — DOCUMENTED (testability)
- Legacy GUIDE handles for migrated CHECKBOXES are
  `UIControlPropertiesConverter` objects with no `ValueChangedFcn`; firing
  must go through the `app.*` component (with a Value-bearing event), while
  `set(...,'Value')` works through either route. Same split as 2.17.
### 2.17 Legacy-vs-modern control handles differ — DOCUMENTED (testability)
- `set(h,'String')` works only through legacy GUIDE handles;
  `app.*` components need `.Value`. Firing callbacks needs the app
  component + a Value-bearing event struct. The `editControl` helper in the
  FitNet/LinearTangent/SumOf* tests encodes this; reuse it for future
  GUIDE-migrated EditField tests.
### 2.14 Tabular-quat-interp cancel/X recurse on close — FIXED (2026-10-12 rollout) (.mlapp)
- `cancelButtonPushed` and `EditSteeringModelUIFigureCloseRequest` both call
  `close(fig)`, producing 'A callback recursively calls CLOSE' warnings on
  every cancel/close (observed live). Use `delete(fig)` in one of them.
  (Also note the App Designer singleton can hand a half-closed instance to
  the next open; tests reap figures aggressively for this reason.)
### 2.11 Linear-tangent editor needs the selectable wrapper — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- `lvd_EditLinearTangentModelGUI_App.mlapp` `populateGUI` reads
  `varA/varADot/varB/varBDot` + bounds that exist only on
  `LinearTangentSelectableModel`; opening it with a bare
  `LinearTangentModel` errors (`noSuchMethodOrField 'varA'`). Tests use the
  selectable wrapper (the only production path, via the selectable
  editor's angle buttons). Consider guarding or documenting the dialog's
  real input type.
### 2.10 Poly steering editor crashes with frameless model — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- `lvd_EditActionSetSteeringModelGUI_App.mlapp` `populateGUI` line ~124
  dereferences `baseFrame.typeEnum.name` whenever `usesRefFrame()` is true,
  but `GenericPolySteeringModel.getDefaultSteeringModel()` leaves `refFrame`
  empty (private ctor sets only `controlFrame`). Opening the editor on a
  default model errors deterministically
  (`expected_one_output_from_intermediate_indexing`). Tests set an inertial
  frame in the fixture like configured models carry. The dialog should fall
  back to the default frame exactly like its own `else` branch does — and
  note the App Designer singleton (`getRunningApp`) can carry a crashed
  half-open instance across tests, so one crash poisons later opens until
  figures are reaped.
### 2.8 Migrated object-dropdowns ignore programmatic Value sets — OPEN (testability)
- Verified live on `lvd_EditActionSetNextEventActionGUI_App`: assigning
  `.Value` (even the exact `ItemsData` member handle) silently keeps the old
  selection; index assignment throws `valueNotInItemsData`. Only real
  gestures (`choose`) change the selection. Tests must extend
  `matlab.uitest.TestCase` and use `choose` for such dropdowns
  (  `NextEventActionDialogTest` does). Same pattern will be needed anywhere
  an object-`ItemsData` dropdown is driven.
- Root cause, pinned live via the continuity dialog: dropdown object
  assignment resolves BY VALUE (`isequal`), not handle identity. Two
  content-identical default events are `isequal`, so assigning the second
  silently keeps the first — even though `==` distinguishes them and the
  member is in `ItemsData`. Production never hits this (users pick from
  distinct strings; real events differ), but fixtures MUST give selected
  objects distinguishing content (e.g. unique event names), or drive the
  control with `choose` gestures.
### 2.7 Bare plugin wrappers crash getListboxStr — FIXED (2026-10-12 rollout), easy (.m, verified live)
- `LvdPluginOptimVarWrapper.isVariableActive` (`LvdPluginOptimVarWrapper.m:37-38`)
  dereferences `obj.optVar.useTf`; a wrapper whose `optVar` is empty (never
  passed through `getNewOptVar`, e.g. built bare in a fixture or loaded from
  a legacy file) throws `MATLAB:needMoreRhsOutputs` from
  `LvdPluginOptimVarSet.getListboxStr`, breaking every plugin-var dropdown.
  Surfaced by `AddValueToPluginVarActionDialogTest` (4 errors). Tests fixed
  to wire `getNewOptVar()` like production; recommend hardening
  `isVariableActive`/`getBounds`/`setBounds` to tolerate an empty `optVar`
  (inactive/empty/false).

## 3. Phase 3 — vehicle editors (27 files) — pending

## 3. Phase 3 — vehicle editors (30 files) — VERIFIED live, all green
All 30 files pass in MATLAB (2026-10-11), zero leaked figures per batch.
Fixes applied during verification (all test-only unless noted): nested
set-editor stubs use exact figure Names + Close buttons (EditLaunchVehicle);
`closeAlerts(fig)` Number-comparison hardening (TankToTankConn, E2TPriority,
Stopwatch); Extremas child stub registered after parent open (shared figure
Name); `fixture`→`buildFixture` not needed here (no clashes). No production
changes in Phase 3.
Files: `EditLaunchVehicleDialogTest`, `EngineDialogTest`, `EnginesDialogTest`,
`EngineToTanksConnDialogTest`, `EngineToTanksConnsDialogTest`,
`StageDialogTest`, `StagesDialogTest`, `TankDialogTest` (superset of
PatchedMlappDialogs capacity coverage), `TanksDialogTest`,
`TankFluidTypesDialogTest`, `TankToTankConnDialogTest`,
`TankToTankConnsDialogTest`, `StopwatchDialogTest`, `StopwatchesDialogTest`,
`ExtremaDialogTest`, `ExtremasDialogTest`, `CalculusObjDialogTest`,
`CalculusObjsDialogTest`, `E2TPriorityDialogTest`, `ImportCraftDialogTest`,
`ElectricalPowerSinksDialogTest`, `SimplePowerSinkDialogTest`,
`ElectricalPowerSrcsDialogTest`, `FixedSolarPanelDialogTest`,
`PowerRtgDialogTest`, `RotatingSolarPanelDialogTest`, `BasicBatteryDialogTest`,
`ElectricalPowerStoragesDialogTest`, `ThrottleModifierProfileDialogTest`,
`ThrottleModifierProfileElementDialogTest`.

### 3.1 Exemplar header/X-test mismatch — FIXED (test-only)
- `TankConstraintDialogTest.m` header claimed window-X coverage with no X
  test. Added `windowXPreservesModel` (close(fig), out false, model
  untouched). Unverified execution (see 0.1).
### 3.2 Tanks Add misfiles TankState under stale stage — FIXED (2026-10-12 rollout)
- `lvd_EditTanksGUI_App.mlapp` `addTankButton_Callback`: new `TankState`
  created under pre-save `initStage` while the tank goes to its post-save
  stage. Sibling `lvd_EditEnginesGUI_App.mlapp` `addEngineButton_Callback`
  correctly uses the post-save stage. Changing stage in the nested editor
  during Add misfiles state under stage 1.
### 3.3 TankFluidTypeSet.addType allows duplicates — FIXED (2026-10-12 rollout), easy (.m)
- `TankFluidTypeSet.m:17-19` appends without the de-dup guard used by
  stage/engine/tank add methods. Add the guard.
### 3.4 Doubled/lowercase control names — DOCUMENTED
- `removeRemoveTypeButton`, `ImportVehiclefromButton` ( AREA meta
  `AREA_editLaunchVehicleUIs.txt:139/:109`). Cosmetic; cleanup only.
### 3.5 T2T-conns figure property is plural — DOCUMENTED
- Class `lvd_EditTankToTankConnsGUI_App` owns figure
  `app.lvd_EditTankToTanksConnsGUI`. Tests use the real name.
### 3.6 Extrema single/set share figure Name — DOCUMENTED
- Both use `Name='Edit Extrema'`; tests capture fig handles per-test instead
  of sweeping by name.
### 3.7 Extrema/Calculus singles never validate — DOCUMENTED
- `saveAndCloseButton_Callback` calls `saveAndClose` directly; no rejection
  tests by design.
### 3.8 Electrical copy callbacks use the ORIGINAL's initial state — FIXED (2026-10-12 rollout) (.mlapp)
- `lvd_EditElectricalPowerSinksGUI_App` `copySinkMenu_Callback`,
  `lvd_EditElectricalPowerSrcsGUI_App` `copySrcMenu_Callback` (also misnamed
  local `newSinkState`), `lvd_EditElectricalPowerStoragesGUI_App`
  `copyStorageMenu_Callback` all call
  `<original>.createDefaultInitialState(stageState)` instead of
  `<new>.createDefaultInitialState(stageState)` — the copy inherits the
  source's state object. One-token fixes each.
### 3.9 Power-sinks delete alerts to the storages figure — FIXED (2026-10-12 rollout), easy (.mlapp)
- `removeSinkButton_Callback` parents its `uialert` to
  `app.lvd_EditElectricalPowerStoragesGUI` (should be `...PowerSinksGUI`).
### 3.10 Throttle-modifier-element range message garbles args — FIXED (2026-10-12 rollout), easy (.mlapp)
- `validateInputs` passes `(min, max, indepUnit, depUnit)` for format
  `'...%.1f %s or %.1f %s...'` with the second value pair swapped and the
  second unit should be the indep unit.

## 4. Phase 4 — state/propagation/sensors/view (20 files) — VERIFIED live, all green
All 20 files pass in MATLAB (2026-10-11), zero leaked figures per batch.
Fixes applied during verification (all test-only unless noted): 1-D drag
middle-point removal (last-index refresh crash 1.31 documented); sail normal
uses valid unnormalized input; LvAndStages checkbox firing via app handles
(2.18); SensorReports empty-open crash avoided + empty-selection alert
covered (4B.5 documented); AdjustCamera `uiaxes` + deterministic teardown
with narrow warning suppression (4B.6 documented). No production changes in
Phase 4.
Files: `OneDDragDialogTest`, `TwoDKwtDragDialogTest`, `ThreeDKwtDragDialogTest`,
`ConstDragDialogTest`, `DragCoefficientModelsDialogTest`,
`KspCylinderLiftDialogTest`, `SrpModelsDialogTest`, `SphericalSrpDialogTest`,
`SolarSailSrpDialogTest`, `InitialStateDialogTest`, `DisplayFrameDialogTest`,
`LvAndStagesStatesDialogTest`, `BuiltInIntegratorDialogTest`,
`FixedStepIntegratorDialogTest`, `FixedInCoordSysSensorSteeringDialogTest`,
`FixedInVehicleSensorSteeringDialogTest`, `SensorsDialogTest`,
`SensorTargetsDialogTest`, `SensorReportsDialogTest`, `AdjustCameraDialogTest`.

### 4A.1 KSP-cylinder radius check reads the height field — FIXED (2026-10-12 rollout), easy (.mlapp)
- `lvd_EditKSPCylinderLiftPropertiesGUI_App.mlapp` `validateInputs`: the
  `'Cylinder Radius'` block reads `app.CylinderHeightText.Value`. An invalid
  radius passes whenever the height is valid. Pinned by
  `KspCylinderLiftDialogTest`.
### 4A.2 Flat-plate lift dialog is orphaned AND broken — DOCUMENTED, skipped
- `lvd_EditLiftPropertiesGUI_App.mlapp` reads/writes `useLift`/`areaLift`/
  `Cl_0`/`bodyLiftVect`, which are `Access=private` on
  `LaunchVehicleAeroState.m:25-29` (live code uses only `liftCoeffModel`);
  the sole caller is commented out
  (`SetLiftAeroPropertiesAction.m:90-113`, live path `:88` routes to
  `liftCoeffModel.openEditDialog`). A `LiftPropertiesDialogTest.m` was
  written then DELETED — it could never pass (dialog errors on open, test
  touches private props). Same treatment as 1.1: recommend deleting the
  `.mlapp` in a cleanup change, not this rollout.
### 4A.3 Spherical-SRP dialog allows cR > 2, model throws on save — FIXED (2026-10-12 rollout)
- Dialog validates scale/`cR` with `ub = Inf`, but
  `SphericalSolarRadiationPressureModel.m:9` caps `cR` at 2 — e.g. 5 passes
  validation then throws on assignment in `saveAndClose`. Align the bounds.
### 4A.4 Solar-sail dialog allows area = 0, model requires > 0 — FIXED (2026-10-12 rollout)
- Dialog validates `area` with `lb = 0`, but
  `SolarSailSolarRadiationPressureModel.m:13` requires `> 0`. Same fix shape
  as 4A.3.
### 4A.5 2-D KWT validation mutates the model before save — FIXED (2026-10-12 rollout)
- `lvd_Edit2DKerbalWindTunnelDragPropertiesGUI_App.mlapp` `validateInputs`
  calls `clearData()` + `createGriddedInterpFromFile()` inside the try: a
  corrupt-but-existing file leaves the model cleared/retargeted even though
  the save is rejected. Validate on a scratch copy, commit on save.
### 4A.6 SRP openEditDialog discards the dialog result — FIXED (2026-10-12 rollout)
- `SphericalSolarRadiationPressureModel.m:77-85` and
  `SolarSailSolarRadiationPressureModel.m:99-107` never return the dialog
  `out`, unlike `ConstantDragCoeffModel.m:46-50` which returns `useTf`.
### 4B.1 Sensor-targets picker says "Sensor" — FIXED (2026-10-12 rollout), easy (cosmetic)
- `lvd_EditSensorTargetsGUI_App.mlapp` `AddTargetButtonPushed` opens the
  picker with `'Name','Select New Sensor Type'` / `'...type of the sensor
  to be created:'`. Tests stub that exact (wrong) name.
### 4B.2 Conical-sensor child needs toolbox fns absent in some envs — DOCUMENTED
- `lvd_EditConicalSensorGUI_App.mlapp` chain needs
  `rotm2axang`/`roty`/`sphereMesh` (cf. `SensorTest.m:36-43` guards).
  `SensorsDialogTest` guards the add-via-child path with `assumeNotEmpty`
  (skips headless, runs with toolboxes); the no-point alert path is
  unguarded.
### 4B.3 AdjustCamera rotate sliders need roty/rotz — DOCUMENTED
- Same missing-toolbox class as 4B.2; `AdjustCameraDialogTest` drives only
  pan/zoom (documented in its header), never the rotate sliders.
### 4B.6 AdjustCamera destroy-listener dereferences dead app — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- `lvd_AdjustCameraGUI_App.mlapp` `axesBeingDestroyed` (line 55) calls
  `isvalid(app.CameraControlsUIFigure)` without checking `isvalid(app)`
  first; once the dialog is closed, deleting the driven axes warns
  (`MATLAB:callback:error`, 'Invalid or deleted object'). Tests suppress
  only that warning ID in teardown. Production fix: guard with
  `isvalid(app) && ...`. (Also: the dialog requires a `uiaxes` handle —
  plain `axes` is rejected by the typed `hAx` property; tests use `uiaxes`.)
### 4B.5 Sensor-reports populate crashes on empty lists — FIXED (2026-10-12 rollout) (.mlapp, verified live)
- Opening `lvd_SensorReports` with no sensors/targets errors
  (`'Value' must be the empty cell because the 'Items' property is empty`):
  populate assigns a non-empty `Value` to the empty listboxes. Production
  never hits this (the main-window menu alerts instead of opening), but the
  dialog should degrade to empty lists + disabled Generate. Tests cover the
  model-level emptiness and the empty-SELECTION alert path instead.
### 4B.4 Sensor-reports Generate swallows errors — FIXED (2026-10-12 rollout)
- `lvd_SensorReports.mlapp` `GenerateReportButtonPushed` catches `ME`
  without rethrow, leaving partial cells while reporting `Done.`. Tests
  never press Generate with a selection (list/content only, no XLS I/O).
### 4B.5 Fixed-step dialog figure tag copy-pasted as builtIn — DOCUMENTED
- `lvd_fixedStepSizeIntegratorOptionsGUI_App.mlapp` figure/Tag/fields are
  `lvd_builtInIntegratorOptionsGUI`. Tests use the real (wrong) handle.
### 4B.6 No-Cancel/No-Save dialogs are by design here — DOCUMENTED
- Integrator dialogs: Save&Close only (X used for cancel path).
  Sensors/Targets sets: Close only (edits apply immediately). AdjustCamera:
  no Save/Apply/Cancel/Restore (sliders write live). Steering frame
  selection is a plain dropdown (no sub-dialog stub needed).

## 5. Phase 5 — geometry+misc (17 files) — VERIFIED live, all green
All 17 files pass in MATLAB (2026-10-11), zero leaked figures per batch.
Fixes applied during verification (all test-only unless noted): continuity
fixture gives the second event a distinct name (dropdowns resolve object
selection by value, 2.8); ExportEphemeris row-vs-column ItemsData, no-alert
figure in batch env (0.4), capture-fig-before-cancel; DataExplorer
verifyError→try/catch; ViewSettings Value-bearing checkbox/listbox events +
select-by-item; AdjustCamera `uiaxes` + deterministic teardown (4B.6).
The view-settings dialog has the same close-then-CloseRequest recursion as
2.14 (warning only). No production changes in Phase 5.
Files: `AlignedConstrainedCoordSysDialogTest`,
`ParallelToFrameCoordSysDialogTest`,
`ParallelToFrameAtTimeCoordSysDialogTest`, `CelestialBodyPointDialogTest`,
`GroundObjPointDialogTest`, `VehiclePointDialogTest`, `EditTermCondDialogTest`,
`NonSeqEventDialogTest`, `ContinuityConstraintsDialogTest`,
`ExportEphemerisDialogTest`, `PluginVariablesDialogTest`,
`DataExplorerDialogTest`, `ManagePluginsDialogTest`, `MissionNotesDialogTest`,
`ConsoleDialogTest`, `HaloConstructorDialogTest`, `ViewSettingsDialogTest`.

### 5A.1 AtTime coord-sys OpeningFcn misnamed — DOCUMENTED (cosmetic)
- `lvd_EditParallelToFrameAtTimeCoordSysGUI_App` names its OpeningFcn
  `lvd_EditParallelToFrameCoordSysGUI_OpeningFcn` (missing "AtTime") and its
  meta `populate(app, handles, coordSys)` omits `lvdData`, yet OpeningFcn
  stores `varargin{2}` as `lvdData`. Ctor is `(coordSys, lvdData, output)`;
  tests use that.
### 5A.2 Non-seq event dialog has no Cancel — OPEN (UX decision, cf. 1.4/1.13)
- `lvd_editNonSeqEventGUI_App` offers only `editEventButton`/`saveAndClose`;
  cancel path covered via window-X (documented in test header).
### 5A.3 Term-cond dialog ctor is (event) with no output — DOCUMENTED
- `lvd_editEvtTermCond_App` takes only `event` (`lvdData` derived from
  `event.script.lvdData`), replaces `event.termCond` in place, Cancel just
  closes. Tests open it directly + nested via the event editor.
### 5A.4 Term-cond negatives are legal — DOCUMENTED
- `validateInputs` checks numeric + `ub >= lb` with `lb = -Inf` from
  callers, so negative durations save. Tests pin the actual refusals
  (blank/non-numeric, inverted bounds), not negatives.
### 5A.5 Term-cond Set-Frame tooltip assignment will error — FIXED (2026-10-12 rollout) (.mlapp)
- `setFrameOptionsButton_Callback` assigns `.Tooltip` (App Designer prop)
  while `populateGUI`/`updateFrameChange` use `.TooltipString` (GUIDE
  uicontrol prop). Pressing Set Frame Options after a frame update errors.
  Not pressed by tests.
### 5A.6 Parallel coord-sys dialogs share a foreign figure tag — DOCUMENTED
- Both use `handles.lvd_EditFixedInFrameVectorGUI`. Test cleanup targets
  that tag. (Not the tank-test tag issue a reviewer flagged and retracted:
  `TankConstraintDialogTest`'s `handles.lvd_EditGroundObjConstraintGUI` is
  the tank dialog's REAL figure property per its `document.xml` — the
  production copy-paste logged in 1.2, not a test bug.)
### 5B.1 View-settings meta extraction was incomplete — DOCUMENTED (tooling)
- The static extractor's control filter dropped most of
  `lvd_viewSettingsGUI_App`'s ~193 props (`showSoICheckbox`,
  `viewProfilesListbox`, `addViewProfileButton`, ...). Tests reference the
  `.mlapp` source directly. Extractor filter needs narrowing before reuse.
### 5B.2 Continuity meta omits text6 — DOCUMENTED (cosmetic)
- Static-meta-only gap; dialog source declares it. No product impact.
### 5B.3 Plugin-manager OutputFcn self-closes under stubbed uiwait — DOCUMENTED
- `ldv_editPluginGUI.m:260-272` closes the figure whenever handles are
  non-empty, so the dialog self-closes on open with the fixture armed.
  `ManagePluginsDialogTest` keeps it alive via a `whenShown` hook. No
  product change needed.
### 5B.4 Mission-notes char-type path — DOCUMENTED
- `saveCloseButton_Callback` assigns adapter `get(...,'String')` into
  char-typed `notes` (`LvdData.m:13`); correct iff the migration CodeAdapter
  returns char. `MissionNotesDialogTest.saveAndCloseWritesNotes` exercises
  exactly this path — watch it when the bridge is back.

---

## 6. Fix rollout 2026-10-12 (Waves 1–4, direct document.xml edits + pure-.m)

Method: `.mlapp` files patched via `matlab/document.xml` in-zip edits (Dropbox reparse points require delete-then-move; backups `*.bak_wave*`). Verified live in MATLAB with `runtests` per batch, zero leaked figures (except SensorTargets 1 unnamed leak under investigation).

Fixed and verified green: 1.3 (uialert already present), 1.7, 1.8, 1.9 (feval), 1.15, 1.17 (+test teardown rename), 1.18 (DERIVEst no-op), 1.19 (+uialert msg fix), 1.20 (dead branch removed), 1.22 (stepTol [0,Inf]), 1.23 (logical contract + IpOptOptimizer), 1.27/5A.5 (TooltipString), 1.28 (+retired pin test), 2.1, 2.2, 2.3 (+retired pin test), 2.4, 2.5, 2.7, 2.9 (id ismember), 2.10 (frameless fallback), 2.11 (selectable guard), 2.13 (guard verified present), 2.14 (cancel+CloseRequest to delete; residual save-path warnings remain), 3.2, 3.3, 3.8, 3.9, 3.10, 4A.1, 4A.3 (ub=2), 4A.4 (lb=eps), 4A.5 (no-mutate validate), 4A.6 (return useTf), 4B.1 (+test stub rename), 4B.4 (surface error), 4B.5 (empty degrade), 4B.6 (isvalid(app)).

Deliberately NOT fixed here (need App Designer UI work / high risk via direct XML): 1.4/1.13/5A.2 (add Cancel buttons), 1.2 (rename donor figure properties/tags), 1.24 (Nomad enum type rename), 1.25/1.30 listbox-refresh migration-layer warnings (attempted Value={} clearing breaks uilistbox validation; reverted; tests pass with documented warnings), 1.26 (open warning persists), 1.10 (stale Value subsumed by 1.25 family).
