classdef SelectableThrottleModelTest < KsptotTestCase
    %SelectableThrottleModelTest Throttle parity with steering (B1).
    %
    % SUBJECT UNDER TEST
    %   SelectableThrottleModel, ThrottleModelEnum.Selectable, the
    %   selectableThrottle slot of ThrottleModelsSet,
    %   SetSelectableThrottleModelActionOptimVar,
    %   lvd_EditSelectableThrottleModelGUI_App, and the selectable base
    %   option in lvd_EditLimitedThrottleModelGUI_App /
    %   lvd_EditThrottleModelsSet_App.
    %
    % ORACLE STRATEGY
    %   Each math branch is checked against its documented closed form,
    %   restated here by hand (not by calling the branch): const +
    %   sum(coeff*dt^exponent), const + sum(amp*sin(2*pi/period*(dt+phase))),
    %   atan((a+a_dot*dt)*dt + (b+b_dot*dt)).  Clamping, continuity,
    %   t0/offset fan-out, deep-copy independence and the enum/model-set
    %   round trips follow the LimitedThrottleModelTest precedent.
    %
    %   The optimizer-variable checks pin the two deliberate departures
    %   from the steering selectable variable: getVarsStoredInRad is all
    %   false (throttle fractions are not angles) and only the 0-1
    %   fractions display as percents.
    %
    %   Dialog tests open the real programmatic windows with
    %   UiwaitInterceptorFixture standing in for uiwait (the
    %   PatchedMlappDialogsTest pattern) and drive every control:
    %   math-model dropdown, continuity checkbox, both const fields, both
    %   tables (cell edit, add, remove incl. the last-row guard), all four
    %   linear-tangent fields, Save & Close (valid and invalid), Cancel,
    %   and the return/escape key handler.

    properties(TestParameter)
        caseName = {'PolyBranchMatchesClosedForm', 'SinesBranchMatchesClosedForm', ...
                    'LinTanBranchMatchesClosedForm', 'ClampsToUnitInterval', ...
                    'ContinuitySeedsConstAndT0', 'T0AndTimeOffsetFanOut', ...
                    'BranchSwitchPreservesUnselected', 'RejectsFitNet', ...
                    'DeepCopyIsIndependent', 'DefaultInstancesAreIndependent', ...
                    'EnumAndModelSetRoundTrip', 'ModelSetLoadobjGuard', ...
                    'HeterogeneousModelArraysCompareAsHandles', ...
                    'OptVarRoundTrip', 'OptVarUnitFlags', 'OptVarRejectsMismatchedUseTf', ...
                    'OptVarScaledRoundTrip', 'LimitedWrapsSelectable'};
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function selectableThrottleMatchesRule(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Test)
        %% --------------------------------------- selectable dialog: layout

        function selectableDialogOffersThreeMathModelsNoFitNet(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            testCase.verifyEqual(numel(app.MathModelCombo.Items), 3, 'Exactly the three non-FitNet math models must be offered.');
            testCase.verifyFalse(any(app.MathModelCombo.ItemsData == SteerMathModelTypeEnum.FitNet), 'FitNet must not be offered for throttle.');
            testCase.verifyEqual(app.MathModelCombo.Value, SteerMathModelTypeEnum.GenericPoly);
            testCase.verifyTrue(app.PolyPanel.Visible == matlab.lang.OnOffSwitchState.on, 'The polynomial branch must show initially.');
            testCase.verifyTrue(app.SinesPanel.Visible == matlab.lang.OnOffSwitchState.off);
            testCase.verifyTrue(app.LinTanPanel.Visible == matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(size(app.PolyTermsTable.Data, 1), 1, 'The default polynomial branch carries one term.');

            %Switching branches swaps the visible panel and the selector.
            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.SumOfSines);
            testCase.verifyEqual(model.selModel, SteerMathModelTypeEnum.SumOfSines);
            testCase.verifyTrue(app.SinesPanel.Visible == matlab.lang.OnOffSwitchState.on);
            testCase.verifyTrue(app.PolyPanel.Visible == matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(size(app.SinesTable.Data, 1), 1, 'The default sines branch carries one sine.');

            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.LinearTangent);
            testCase.verifyEqual(model.selModel, SteerMathModelTypeEnum.LinearTangent);
            testCase.verifyTrue(app.LinTanPanel.Visible == matlab.lang.OnOffSwitchState.on);
            testCase.verifyTrue(app.SinesPanel.Visible == matlab.lang.OnOffSwitchState.off);

            testCase.pushButton(app.CancelButton);
            testCase.verifyFalse(out.output{1});
        end

        %% ----------------------------------------- selectable dialog: poly

        function selectableDialogEditsPolyBranch(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            %Constant offset field writes through to the live branch.
            app.PolyConstText.Value = '0.7';
            app.PolyConstText.ValueChangedFcn(app.PolyConstText, struct('Source', app.PolyConstText));
            testCase.verifyEqual(model.polyModel.const, 0.7, 'AbsTol', 1e-12);

            %Add appends a zero-contribution linear term.
            testCase.pushButton(app.AddPolyTermButton);
            testCase.verifyEqual(model.polyModel.getNumTerms(), 2);
            testCase.verifyEqual(size(app.PolyTermsTable.Data, 1), 2, 'The table must show the new term.');

            %Cell edits write the coefficient and exponent of row 2.
            app.PolyTermsTable.CellEditCallback(app.PolyTermsTable, struct('Indices', [2 1], 'NewData', '0.002'));
            app.PolyTermsTable.CellEditCallback(app.PolyTermsTable, struct('Indices', [2 2], 'NewData', '2'));
            testCase.verifyEqual(model.polyModel.terms(2).coeff, 0.002, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.terms(2).exponent, 2);

            %A non-numeric cell edit is rejected and the table reverts.
            app.PolyTermsTable.CellEditCallback(app.PolyTermsTable, struct('Indices', [2 1], 'NewData', 'abc'));
            testCase.verifyEqual(model.polyModel.terms(2).coeff, 0.002, 'AbsTol', 1e-12, 'A rejected edit must leave the model alone.');
            testCase.verifyEqual(app.PolyTermsTable.Data{2,1}, fullAccNum2Str(0.002), 'A rejected edit must revert the table cell.');
            testCase.closeAlertFigures();

            %Removing the selected row drops row 1 and keeps row 2's values.
            app.PolyTermsTable.Selection = [1 1];
            testCase.pushButton(app.RemovePolyTermButton);
            testCase.verifyEqual(model.polyModel.getNumTerms(), 1);
            testCase.verifyEqual(model.polyModel.terms(1).coeff, 0.002, 'AbsTol', 1e-12, 'Removing row 1 must keep row 2.');

            %Save commits: throttle(ut) follows the edited program.
            model.setT0(0);
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifySameHandle(out.output{2}, model);
            testCase.verifyEqual(model.getThrottleAtTime(10, [],[],[],[],[],[],[],[],[],[]), 0.7 + 0.002*10^2, 'AbsTol', 1e-9);
        end

        %% ---------------------------------------- selectable dialog: sines

        function selectableDialogEditsSinesBranch(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));
            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.SumOfSines);

            app.SinesConstText.Value = '0.5';
            app.SinesConstText.ValueChangedFcn(app.SinesConstText, struct('Source', app.SinesConstText));
            testCase.verifyEqual(model.sinesModel.const, 0.5, 'AbsTol', 1e-12);

            testCase.pushButton(app.AddSineButton);
            testCase.verifyEqual(model.sinesModel.getNumSines(), 2);
            testCase.verifyEqual(size(app.SinesTable.Data, 1), 2);

            app.SinesTable.CellEditCallback(app.SinesTable, struct('Indices', [2 1], 'NewData', '0.1'));
            app.SinesTable.CellEditCallback(app.SinesTable, struct('Indices', [2 2], 'NewData', '40'));
            app.SinesTable.CellEditCallback(app.SinesTable, struct('Indices', [2 3], 'NewData', '3'));
            testCase.verifyEqual(model.sinesModel.sines(2).amp, 0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.sinesModel.sines(2).period, 40, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.sinesModel.sines(2).phase, 3, 'AbsTol', 1e-12);

            %No selection removes the last row.
            app.SinesTable.Selection = [];
            testCase.pushButton(app.RemoveSineButton);
            testCase.verifyEqual(model.sinesModel.getNumSines(), 1);

            model.setT0(0);
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyTrue(out.output{1});
            ut = 10;
            testCase.verifyEqual(model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]), ...
                0.5 + 0*sin((2*pi/1000)*ut), 'AbsTol', 1e-9, ...
                'After removing the added sine only the constant plus the default sine remain.');
        end

        %% --------------------------------------- selectable dialog: lintan

        function selectableDialogEditsLinTanBranch(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));
            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.LinearTangent);

            app.LinTanAText.Value = '0.02';
            app.LinTanAText.ValueChangedFcn(app.LinTanAText, struct('Source', app.LinTanAText));
            app.LinTanADotText.Value = '0.001';
            app.LinTanADotText.ValueChangedFcn(app.LinTanADotText, struct('Source', app.LinTanADotText));
            app.LinTanBText.Value = '0.6';
            app.LinTanBText.ValueChangedFcn(app.LinTanBText, struct('Source', app.LinTanBText));
            app.LinTanBDotText.Value = '-0.002';
            app.LinTanBDotText.ValueChangedFcn(app.LinTanBDotText, struct('Source', app.LinTanBDotText));

            branch = model.linTanModel;
            testCase.verifyEqual([branch.a, branch.a_dot, branch.b, branch.b_dot], [0.02, 0.001, 0.6, -0.002], 'AbsTol', 1e-12);

            %A non-numeric field edit is ignored.
            app.LinTanBText.Value = 'xyz';
            app.LinTanBText.ValueChangedFcn(app.LinTanBText, struct('Source', app.LinTanBText));
            testCase.verifyEqual(branch.b, 0.6, 'AbsTol', 1e-12);

            %Restore a valid field (the rejected text stays visible until
            %replaced, and Save validates what is shown).
            app.LinTanBText.Value = '0.6';
            app.LinTanBText.ValueChangedFcn(app.LinTanBText, struct('Source', app.LinTanBText));

            model.setT0(0);
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyTrue(out.output{1});
            dt = 20;
            testCase.verifyEqual(model.getThrottleAtTime(dt, [],[],[],[],[],[],[],[],[],[]), ...
                atan((0.02 + 0.001*dt)*dt + (0.6 - 0.002*dt)), 'AbsTol', 1e-9);
        end

        %% ----------------------------------- selectable dialog: validation

        function selectableDialogRejectsInvalidInput(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            %A blank constant blocks Save and leaves the dialog open.
            app.PolyConstText.Value = '';
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyFalse(out.output{1}, 'A blank constant must not be saved.');
            testCase.verifyTrue(isvalid(app.UIFigure), 'A failed validation must leave the dialog open.');
            testCase.closeAlertFigures();

            %A zero sine period blocks Save too.
            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.SumOfSines);
            app.SinesTable.CellEditCallback(app.SinesTable, struct('Indices', [1 2], 'NewData', '0'));
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyFalse(out.output{1}, 'A zero sine period must not be saved.');
            testCase.verifyTrue(isvalid(app.UIFigure));
            testCase.closeAlertFigures();

            %Fixing both lets the save through.
            app.SinesTable.CellEditCallback(app.SinesTable, struct('Indices', [1 2], 'NewData', '50'));
            app.SinesConstText.Value = '0.4';
            app.SinesConstText.ValueChangedFcn(app.SinesConstText, struct('Source', app.SinesConstText));
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyTrue(out.output{1});
        end

        function selectableDialogRemoveGuardsLastRow(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            testCase.pushButton(app.RemovePolyTermButton);
            testCase.verifyEqual(model.polyModel.getNumTerms(), 1, 'The last polynomial term must be kept.');
            testCase.closeAlertFigures();

            testCase.setCombo(app, app.MathModelCombo, SteerMathModelTypeEnum.SumOfSines);
            testCase.pushButton(app.RemoveSineButton);
            testCase.verifyEqual(model.sinesModel.getNumSines(), 1, 'The last sine must be kept.');
            testCase.closeAlertFigures();

            testCase.pushButton(app.CancelButton);
        end

        function selectableDialogContinuityCheckbox(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            testCase.verifyEqual(app.ContinuityCheckbox.Value, false);
            app.ContinuityCheckbox.Value = true;
            testCase.pushButton(app.SaveCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(model.throttleContinuity, 'Save must commit the continuity checkbox.');

            %With useContinuity off the checkbox is hidden.
            out2 = AppDesignerGUIOutput({false});
            app2 = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], false, out2));
            testCase.verifyTrue(app2.ContinuityCheckbox.Visible == matlab.lang.OnOffSwitchState.off);
            testCase.pushButton(app2.CancelButton);
        end

        function selectableDialogKeyPress(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out));

            %Return saves when the inputs are valid.  Closing the figure
            %deletes the registered app object, so the figure handle is
            %captured first.
            fig = app.UIFigure;
            app.UIFigure.WindowKeyPressFcn(app.UIFigure, struct('Key', 'return'));
            testCase.verifyTrue(out.output{1}, 'Return must trigger Save & Close.');
            testCase.verifyFalse(isvalid(fig), 'Save must close the figure.');

            %Escape cancels.
            out2 = AppDesignerGUIOutput({false});
            app2 = testCase.openDialog(@() lvd_EditSelectableThrottleModelGUI_App(model, [], true, out2));
            fig2 = app2.UIFigure;
            app2.UIFigure.WindowKeyPressFcn(app2.UIFigure, struct('Key', 'escape'));
            testCase.verifyFalse(out2.output{1}, 'Escape must trigger Cancel.');
            testCase.verifyFalse(isvalid(fig2), 'Cancel must close the figure.');
        end

        %% --------------------------------- other dialogs gain the new type

        function throttleModelsSetDialogOffersSelectable(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            throttleModels = ThrottleModelsSet();
            out = AppDesignerGUIOutput({false});

            app = testCase.openDialog(@() lvd_EditThrottleModelsSet_App(throttleModels, lvdData, out, true));

            testCase.verifyTrue(any(app.ThrottleModelCombo.ItemsData == ThrottleModelEnum.Selectable), ...
                'The selectable throttle model must be offered in the model set dialog.');

            app.ThrottleModelCombo.Value = ThrottleModelEnum.Selectable;
            testCase.pushButton(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(isa(throttleModels.selectedModel, 'SelectableThrottleModel'));
            testCase.verifySameHandle(throttleModels.selectedModel, throttleModels.selectableThrottle);
        end

        function limitedDialogAcceptsSelectableBase(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            model = LimitedThrottleModel.getDefaultThrottleModel();
            out = AppDesignerGUIOutput({false, model});

            app = testCase.openDialog(@() lvd_EditLimitedThrottleModelGUI_App(model, lvdData.launchVehicle, true, out));

            testCase.verifyTrue(any(app.BaseModelCombo.ItemsData == ThrottleModelEnum.Selectable), ...
                'The selectable model must be offered as a Limited base model.');

            app.BaseModelCombo.Value = ThrottleModelEnum.Selectable;
            app.BaseModelCombo.ValueChangedFcn(app.BaseModelCombo, struct('Source', app.BaseModelCombo));
            testCase.pushButton(app.SaveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(isa(model.baseModel, 'SelectableThrottleModel'), ...
                'Save must commit the selectable base model.');
        end

        function selectableProgramPropagatesThroughScript(testCase)
            %End to end: SetThrottleModelAction -> initAction -> propagator
            %-> state log.  The logged throttle at every step after the
            %action runs must equal the selectable program at that time.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            evt1.execActionsNode = ActionExecNodeEnum.BeforeProp;
            evt1.termCond.duration = 60;

            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.polyModel.const = 0.65;
            model.polyModel.terms(1).coeff = 0.0001;
            model.polyModel.terms(1).exponent = 1;

            evt1.addAction(SetThrottleModelAction(model));
            stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);

            entries = stateLog.getAllStateLogEntriesForEvent(evt1);
            testCase.assertNotEmpty(entries, 'The event must log states.');

            %The first logged entry is the pre-action state the propagator
            %appends before running the event's actions
            %(LaunchVehicleScript.executeEvent), so it still carries the
            %previous throttle model.  Every entry from the action on must
            %follow the selectable program.
            testCase.assertGreaterThan(numel(entries), 1);
            t0 = model.getT0();
            for(i = 2:numel(entries)) %#ok<*NO4LP>
                expected = 0.65 + 0.0001*(entries(i).time - t0);
                testCase.verifyEqual(entries(i).throttle, expected, 'AbsTol', 1e-9, ...
                    sprintf('Logged throttle at t=%g must follow the selectable program.', entries(i).time));
            end
        end
    end

    methods(Access=private)
        %% ------------------------------------------------- math branches

        function checkPolyBranchMatchesClosedForm(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.selModel = SteerMathModelTypeEnum.GenericPoly;
            model.polyModel.const = 0.6;
            model.polyModel.terms(1).t0 = 10;
            model.polyModel.terms(1).coeff = 0.02;
            model.polyModel.terms(1).exponent = 1;
            model.polyModel.addTerm(PolynominalTermModel(10, -0.001, 2));
            model.setT0(10);

            for ut = [10, 40, 70]
                dt = ut - 10;
                expected = 0.6 + 0.02*dt^1 - 0.001*dt^2;
                actual = model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, min(max(expected,0),1), 'AbsTol', 1e-10, ...
                    sprintf('Selectable poly throttle does not match const + sum(coeff*dt^exp) at ut=%g', ut));
            end
        end

        function checkSinesBranchMatchesClosedForm(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            model.sinesModel.const = 0.5;
            model.sinesModel.sines(1).t0 = 0;
            model.sinesModel.sines(1).amp = 0.2;
            model.sinesModel.sines(1).period = 40;
            model.sinesModel.sines(1).phase = 0;
            model.sinesModel.addSine(SineModel(0, 0.05, 2*pi/60, 3));
            model.setT0(0);

            for ut = [0, 7.5, 33]
                expected = 0.5 + 0.2*sin((2*pi/40)*ut) + 0.05*sin((2*pi/60)*(ut+3));
                actual = model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, min(max(expected,0),1), 'AbsTol', 1e-9, ...
                    sprintf('Selectable sines throttle does not match const + sum(amp*sin) at ut=%g', ut));
            end
        end

        function checkLinTanBranchMatchesClosedForm(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.selModel = SteerMathModelTypeEnum.LinearTangent;
            model.throttleMathModel = LinearTangentSelectableModel(5, 0.01, 0.002, 0.5, -0.001);
            model.setT0(5);

            for ut = [5, 25, 60]
                dt = ut - 5;
                expected = atan((0.01 + 0.002*dt)*dt + (0.5 - 0.001*dt));
                actual = model.getThrottleAtTime(ut, [],[],[],[],[],[],[],[],[],[]);
                testCase.verifyEqual(actual, min(max(expected,0),1), 'AbsTol', 1e-10, ...
                    sprintf('Selectable linear-tangent throttle does not match atan(a*dt+b) at ut=%g', ut));
            end
        end

        function checkClampsToUnitInterval(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();

            model.polyModel.const = 5;
            testCase.verifyEqual(model.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 1, ...
                'Throttle above 1 must clamp to 1.');

            model.polyModel.const = -5;
            testCase.verifyEqual(model.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 0, ...
                'Throttle below 0 must clamp to 0.');

            %The clamp applies to every branch, including atan's (-pi/2, pi/2).
            model.selModel = SteerMathModelTypeEnum.LinearTangent;
            model.throttleMathModel = LinearTangentSelectableModel(0, 0, 0, 100, 0);
            testCase.verifyEqual(model.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 1, ...
                'Linear-tangent output above 1 must clamp to 1.');
        end

        %% --------------------------------------------- time bookkeeping

        function checkContinuitySeedsConstAndT0(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.throttleContinuity = true;
            %The default term (coeff 0, exponent 0) contributes coeff*dt^0
            %= coeff at every ut including t0, so a nonzero coeff makes the
            %seeding check non-vacuous however entry.throttle reads.
            model.polyModel.terms(1).coeff = 0.2;
            model.polyModel.addTerm(PolynominalTermModel(0, 0.01, 1));
            model.initThrottleModel(entry);

            testCase.verifyEqual(model.getT0(), entry.time, 'initThrottleModel must set t0 from the state.');
            testCase.verifyEqual(model.polyModel.const, entry.throttle - 0.2, 'AbsTol', 1e-12, ...
                'Continuity must seed the constant from the prior throttle minus the terms'' value at t0.');
            testCase.verifyEqual(model.getThrottleAtTime(entry.time, [],[],[],[],[],[],[],[],[],[]), ...
                min(max(entry.throttle,0),1), 'AbsTol', 1e-12, ...
                'The seeded program must start exactly at the prior throttle.');

            %Without the flag the constant is untouched but t0 still moves.
            model2 = SelectableThrottleModel.getDefaultThrottleModel();
            model2.polyModel.const = 0.42;
            model2.initThrottleModel(entry);
            testCase.verifyEqual(model2.polyModel.const, 0.42, 'AbsTol', 1e-15);
            testCase.verifyEqual(model2.getT0(), entry.time);
        end

        function checkT0AndTimeOffsetFanOut(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.setT0(77);
            testCase.verifyEqual(model.polyModel.getT0(), 77, 'setT0 must reach the poly branch.');
            testCase.verifyEqual(model.sinesModel.getT0(), 77, 'setT0 must reach the sines branch.');
            testCase.verifyEqual(model.linTanModel.getT0(), 77, 'setT0 must reach the linear-tangent branch.');

            model.setTimeOffsets(3);
            testCase.verifyEqual(model.polyModel.getTimeOffset(), 3);
            testCase.verifyEqual(model.sinesModel.getTimeOffset(), 3);
            testCase.verifyEqual(model.linTanModel.getTimeOffset(), 3);

            %getT0/getTimeOffsets follow the active branch.
            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            testCase.verifyEqual(model.getT0(), 77);
            testCase.verifyEqual(model.getTimeOffsets(), 3);

            %setInitialThrottleFromState re-anchors t0 and shifts the
            %active branch offset, mirroring ThrottlePolyModel.
            model.setInitialThrottleFromState(entry, 2.5);
            testCase.verifyEqual(model.getT0(), entry.time);
            testCase.verifyEqual(model.sinesModel.getTimeOffset(), 5.5, 'AbsTol', 1e-12);
        end

        %% ------------------------------------------------- branch plumbing

        function checkBranchSwitchPreservesUnselected(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.polyModel.const = 0.7;
            model.sinesModel.const = 0.4;

            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            testCase.verifyEqual(model.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 0.4, 'AbsTol', 1e-12);

            model.selModel = SteerMathModelTypeEnum.GenericPoly;
            testCase.verifyEqual(model.polyModel.const, 0.7, 'AbsTol', 1e-15, 'Switching away and back must not lose the poly configuration.');
            testCase.verifyEqual(model.getThrottleAtTime(0, [],[],[],[],[],[],[],[],[],[]), 0.7, 'AbsTol', 1e-12);

            %The dependent setter routes by class.
            replacement = SumOfSinesModel(0.25);
            model.throttleMathModel = replacement;
            testCase.verifySameHandle(model.sinesModel, replacement);
            testCase.verifyEqual(model.sinesModel.const, 0.25, 'AbsTol', 1e-15);
        end

        function checkRejectsFitNet(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            testCase.verifyError(@() testCase.selectFitNet(model), ?MException, ...
                'Selecting FitNet for throttle must be rejected.');

            fitNet = FitNetModel(5);
            testCase.verifyError(@() testCase.assignMathBranch(model, fitNet), ?MException, ...
                'Assigning a FitNet branch must be rejected.');
        end

        function checkDeepCopyIsIndependent(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            model.polyModel.const = 0.7;
            model.sinesModel.const = 0.4;
            model.sinesModel.sines(1).amp = 0.1;
            model.linTanModel.a = 0.03;
            model.throttleContinuity = true;
            model.setT0(11);

            copied = model.deepCopy();
            testCase.verifyClass(copied, 'SelectableThrottleModel');
            testCase.verifyFalse(copied == model, 'deepCopy must return a distinct handle.');
            testCase.verifyEqual(copied.selModel, model.selModel, 'deepCopy must preserve the selector.');
            testCase.verifyTrue(copied.throttleContinuity);

            for branch = {'polyModel', 'sinesModel', 'linTanModel'}
                testCase.verifyFalse(copied.(branch{1}) == model.(branch{1}), ...
                    sprintf('The %s slot must be a copy, not a shared handle.', branch{1}));
            end
            testCase.verifyEqual(copied.polyModel.const, 0.7, 'AbsTol', 1e-15);
            testCase.verifyEqual(copied.sinesModel.sines(1).amp, 0.1, 'AbsTol', 1e-15);
            testCase.verifyEqual(copied.linTanModel.a, 0.03, 'AbsTol', 1e-15);

            testCase.verifyEqual(copied.getThrottleAtTime(30, [],[],[],[],[],[],[],[],[],[]), ...
                model.getThrottleAtTime(30, [],[],[],[],[],[],[],[],[],[]), 'AbsTol', 1e-15, ...
                'The copy must throttle identically.');

            copied.polyModel.const = 0.1;
            testCase.verifyEqual(model.polyModel.const, 0.7, 'AbsTol', 1e-15, 'Mutating the copy must not disturb the original.');
        end

        function checkDefaultInstancesAreIndependent(testCase)
            %Property default expressions are evaluated once at class load:
            %the private constructor must mint fresh math-model handles or
            %every default model would share one branch object.
            m1 = SelectableThrottleModel.getDefaultThrottleModel();
            m2 = SelectableThrottleModel.getDefaultThrottleModel();

            m1.polyModel.const = 0.9;
            m1.sinesModel.const = 0.8;
            m1.linTanModel.b = 0.5;
            testCase.verifyEqual(m2.polyModel.const, 0, 'Two default models must not share the poly branch.');
            testCase.verifyEqual(m2.sinesModel.const, 0, 'Two default models must not share the sines branch.');
            testCase.verifyEqual(m2.linTanModel.b, 0, 'Two default models must not share the linear-tangent branch.');
        end

        %% -------------------------------------------- enum / set plumbing

        function checkEnumAndModelSetRoundTrip(testCase)
            [names, enums] = ThrottleModelEnum.getThrottleModelTypeNameStrs();
            testCase.verifyTrue(any(enums == ThrottleModelEnum.Selectable), 'Selectable must be a ThrottleModelEnum member.');
            testCase.verifyTrue(any(contains(names, 'Selectable')), 'The Selectable enum must have a listbox name.');
            testCase.verifyEqual(ThrottleModelEnum.Selectable.classNameStr, 'SelectableThrottleModel');

            model = SelectableThrottleModel.getDefaultThrottleModel();
            testCase.verifyEqual(model.getThrottleModelTypeEnum(), ThrottleModelEnum.Selectable);
            testCase.verifyEqual(ThrottleModelEnum.getIndOfListboxStrsForThrottleModel(model), find(enums == ThrottleModelEnum.Selectable));
            testCase.verifyEqual(ThrottleModelEnum.getEnumForListboxStr(ThrottleModelEnum.Selectable.nameStr), ThrottleModelEnum.Selectable);

            set = ThrottleModelsSet();
            testCase.verifyClass(set.selectableThrottle, 'SelectableThrottleModel', 'The model set must carry a selectable slot.');
            set2 = ThrottleModelsSet();
            testCase.verifyNotSameHandle(set.selectableThrottle, set2.selectableThrottle, 'Each set must own its own selectable model instance.');

            set.selectedModel = model;
            testCase.verifySameHandle(set.selectableThrottle, model, 'Selecting a selectable model must store it in the selectable slot.');
            testCase.verifySameHandle(set.getModelForEnum(ThrottleModelEnum.Selectable), model);
            testCase.verifySameHandle(set.getModelForEnum(ThrottleModelEnum.PolyModel), set.polyThrottle);
            all5 = set.getAllModels();
            testCase.verifyNumElements(all5, 5, 'The set now carries five models.');
            testCase.verifySameHandle(all5(4), model, 'The selectable model sits in enumeration order.');

            model2 = SelectableThrottleModel.getDefaultThrottleModel();
            set.setModelForEnum(ThrottleModelEnum.Selectable, model2);
            testCase.verifySameHandle(set.selectableThrottle, model2);
            testCase.verifySameHandle(set.selectedModel, model2, 'Replacing the selected slot must move the selection to the new model.');
            testCase.verifyError(@() set.setModelForEnum(ThrottleModelEnum.PolyModel, model2), ?MException, ...
                'Storing a model in the wrong slot must be rejected.');

            action = SetThrottleModelAction(model2);
            testCase.verifySameHandle(action.throttleModels.selectedModel, model2);
            testCase.verifySameHandle(action.throttleModels.selectableThrottle, model2);
            testCase.verifyTrue(contains(action.getName(), 'Selectable'), 'The action name must identify the selectable model type.');
        end

        function checkModelSetLoadobjGuard(testCase)
            mc = ?ThrottleModelsSet;
            prop = findobj(mc.PropertyList, 'Name', 'selectableThrottle');
            testCase.assertNotEmpty(prop);
            classDefault = prop.DefaultValue;

            set = ThrottleModelsSet();
            set.selectableThrottle = classDefault;
            set = ThrottleModelsSet.loadobj(set);
            testCase.verifyNotSameHandle(set.selectableThrottle, classDefault, 'loadobj must replace the shared class default.');
            testCase.verifyClass(set.selectableThrottle, 'SelectableThrottleModel');

            own = SelectableThrottleModel.getDefaultThrottleModel();
            own.polyModel.const = 0.33;
            set2 = ThrottleModelsSet();
            set2.selectableThrottle = own;
            set2 = ThrottleModelsSet.loadobj(set2);
            testCase.verifySameHandle(set2.selectableThrottle, own, 'loadobj must not touch a set with its own selectable model.');
        end

        function checkHeterogeneousModelArraysCompareAsHandles(testCase)
            models = ThrottleModelsSet();
            all = models.getAllModels();
            testCase.assertEqual(numel(all), 5);

            sel = models.selectableThrottle;
            others = all(all ~= sel);

            testCase.verifyEqual(numel(others), 4, 'Every model but the selected one must survive the filter.');
            testCase.verifyFalse(any(others == sel));
            testCase.verifyTrue(any(all == sel));
            testCase.verifyTrue(isa(others, 'AbstractThrottleModel'));
        end

        %% -------------------------------------------------- optimizer var

        function checkOptVarRoundTrip(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            model.polyModel.const = 0.6;
            model.polyModel.terms(1).coeff = 0.01;
            model.polyModel.terms(1).exponent = 1;

            optVar = model.getNewOptVar();
            testCase.verifyClass(optVar, 'SetSelectableThrottleModelActionOptimVar');
            testCase.verifySameHandle(model.getExistingOptVar(), optVar, 'The model must link back to its variable.');

            %Default poly branch: tOffset + const + 1 term (coeff, exponent).
            testCase.verifyEqual(optVar.getMaxNumVars(), 4);

            optVar.setUseTfForVariable(true(1,4));
            x = optVar.getXsForVariable();
            testCase.verifyNumElements(x, 4);

            %Write through the variable and read it back.
            optVar.updateObjWithVarValue([1.5, 0.75, 0.03, 2]);
            testCase.verifyEqual(model.polyModel.getTimeOffset(), 1.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.const, 0.75, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.terms(1).coeff, 0.03, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.terms(1).exponent, 2);

            %Bounds round-trip, full-length and useTf-length.
            optVar.setBndsForVariable([0 0 -1 0], [10 1 1 5]);
            [lb, ub] = optVar.getBndsForVariable();
            testCase.verifyEqual(lb, [0 0 -1 0], 'AbsTol', 1e-15);
            testCase.verifyEqual(ub, [10 1 1 5], 'AbsTol', 1e-15);
            [alb, aub] = optVar.getAllBndsForVariable();
            testCase.verifyNumElements(alb, 4);
            testCase.verifyEqual(aub, [10 1 1 5], 'AbsTol', 1e-15);

            optVar.setUseTfForVariable([true false true false]);
            testCase.verifyEqual(optVar.getXsForVariable(), [1.5 0.03], 'AbsTol', 1e-12, 'Only the flagged elements are exposed.');
            optVar.updateObjWithVarValue([2.5, 0.09]);
            testCase.verifyEqual(model.polyModel.getTimeOffset(), 2.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.terms(1).coeff, 0.09, 'AbsTol', 1e-12);
            testCase.verifyEqual(model.polyModel.const, 0.75, 'AbsTol', 1e-15, 'Unflagged elements are untouched.');

            %Names: one per element, filtered by useTf.
            names = optVar.getStrNamesOfVars(2, '');
            testCase.verifyNumElements(names, 2);
            testCase.verifyTrue(contains(names{1}, 'Event 2') && contains(names{1}, 'Time Offset'));

            %SetThrottleModelAction surfaces the variable.
            action = SetThrottleModelAction(model);
            [tf, vars] = action.hasActiveOptimVar();
            testCase.verifyTrue(tf);
            testCase.verifySameHandle(vars(1), optVar);
        end

        function checkOptVarUnitFlags(testCase)
            %THE trap test: the shared steering math models report their
            %constant/coefficient/amplitude elements as stored in radians.
            %Throttle fractions must never be degree-converted.
            model = SelectableThrottleModel.getDefaultThrottleModel();
            optVar = model.getNewOptVar();

            testCase.verifyEqual(optVar.getVarsStoredInRad(), false(1, optVar.getMaxNumVars()), ...
                'No selectable-throttle variable is stored in radians.');

            %Poly (const + 1 term): tOffset no, const yes, coeff yes, exponent no.
            testCase.verifyEqual(optVar.getVarsDisplayedAsPercents(), [false true true false], ...
                'Only the poly constant and coefficient display as percents.');

            %Sines (const + 1 sine): const and amplitude only.
            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            testCase.verifyEqual(optVar.getMaxNumVars(), 5);
            testCase.verifyEqual(optVar.getVarsStoredInRad(), false(1,5));
            testCase.verifyEqual(optVar.getVarsDisplayedAsPercents(), [false true true false false], ...
                'Only the sines constant and amplitude display as percents.');

            %Linear tangent: tan-space parameters never display as percents.
            model.selModel = SteerMathModelTypeEnum.LinearTangent;
            testCase.verifyEqual(optVar.getMaxNumVars(), 5);
            testCase.verifyEqual(optVar.getVarsStoredInRad(), false(1,5));
            testCase.verifyEqual(optVar.getVarsDisplayedAsPercents(), false(1,5));
        end

        function checkOptVarRejectsMismatchedUseTf(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            optVar = model.getNewOptVar();

            %Default poly branch takes 4 flags; anything else is a caller
            %bug (e.g. flags built for another branch) and must fail fast.
            testCase.verifyError(@() optVar.setUseTfForVariable(true(1,3)), ?MException);
            testCase.verifyError(@() optVar.setUseTfForVariable(true(1,6)), ?MException);

            %Flags built for the sines branch do not fit the poly branch.
            model.selModel = SteerMathModelTypeEnum.SumOfSines;
            testCase.verifyError(@() optVar.setUseTfForVariable(true(1,4)), ?MException);
            optVar.setUseTfForVariable(true(1,5)); %this fits and must work
            testCase.verifyNumElements(optVar.getXsForVariable(), 5);
        end

        function checkOptVarScaledRoundTrip(testCase)
            model = SelectableThrottleModel.getDefaultThrottleModel();
            optVar = model.getNewOptVar();
            optVar.setUseTfForVariable(true(1, optVar.getMaxNumVars()));
            optVar.setBndsForVariable([-5 0 -1 0], [5 1 1 4]);

            x0 = optVar.getXsForVariable();
            [xS, lbS, ubS] = optVar.getScaledXsForVariable();
            testCase.verifyEqual(lbS, -ones(size(xS)), 'Scaled bounds must be the [-1, 1] box.');
            testCase.verifyEqual(ubS, ones(size(xS)));

            optVar.updateObjWithScaledVarValue(xS);
            testCase.verifyEqual(optVar.getXsForVariable(), x0, 'AbsTol', 1e-12, ...
                'A scaled round trip must reproduce the variable values.');

            %perturbVar stays inside the bounds.
            optVar.updateObjWithVarValue([0 0.5 0.1 1]);
            optVar.perturbVar(10);
            x = optVar.getXsForVariable();
            [lb, ub] = optVar.getBndsForVariable();
            testCase.verifyTrue(all(x >= lb - 1e-12 & x <= ub + 1e-12), 'Perturbed values must respect the bounds.');
        end

        %% -------------------------------------------------- limited interop

        function checkLimitedWrapsSelectable(testCase)
            [~, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = testCase.buildFixture();

            base = SelectableThrottleModel.getDefaultThrottleModel();
            base.polyModel.const = 0.8;
            base.setT0(0);

            model = LimitedThrottleModel.getThrottleModelWithBase(base);
            testCase.verifySameHandle(model.baseModel, base);

            rVect = (bodyInfo.radius + 300) * [1; 0; 0];
            vVect = [0; 2.0; 0];
            actual = model.getThrottleAtTime(10, rVect, vVect, tankMasses, dryMass, entry.stageStates, entry.lvState, tankStates, bodyInfo, storageSoCs, pwrStates);
            testCase.verifyEqual(actual, 0.8, 'AbsTol', 1e-12, 'With limits off the wrapper must pass the selectable throttle through.');

            %Time bookkeeping and variables delegate to the selectable base.
            model.initThrottleModel(entry);
            testCase.verifyEqual(base.getT0(), entry.time, 'initThrottleModel must reach the selectable base.');
            testCase.verifyClass(model.getNewOptVar(), 'SetSelectableThrottleModelActionOptimVar', ...
                'The wrapper must expose the selectable base variable.');
        end
    end

    methods(Access=private)
        function selectFitNet(~, model)
            model.selModel = SteerMathModelTypeEnum.FitNet;
        end

        function assignMathBranch(~, model, branch)
            model.throttleMathModel = branch;
        end

        %% ------------------------------------------------------------ fixtures

        function [lvdData, entry, bodyInfo, tankMasses, dryMass, tankStates, storageSoCs, pwrStates] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            bodyInfo = entry.centralBody;

            tankStates = entry.getAllActiveTankStates();
            tankMasses = [tankStates.tankMass];
            dryMass = entry.getTotalVehicleDryMass();
            pwrStates = entry.getAllActivePwrStorageStates();
            storageSoCs = zeros(1, numel(pwrStates));
            for(i = 1:numel(pwrStates)) %#ok<*NO4LP>
                storageSoCs(i) = pwrStates(i).getStateOfCharge();
            end
        end

        function app = openDialog(testCase, launchFcn)            %openDialog Runs a dialog constructor (whose uiwait is a no-op
            %while this test class runs) and returns the live app.
            app = launchFcn();
            drawnow;

            testCase.assertTrue(not(isempty(app)), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SelectableThrottleModelTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            %pushButton Fires a button's callback the way a click would.
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function setCombo(~, ~, combo, value)
            %setCombo Selects a dropdown value and fires its change handler.
            combo.Value = value;
            combo.ValueChangedFcn(combo, struct('Value', value));
            drawnow;
        end

        function closeAlertFigures(~)
            %closeAlertFigures Dismisses uialert figures raised by rejected
            %input so they do not linger between tests.
            figs = findall(groot, 'Type', 'figure');
            for(i = 1:numel(figs))
                if(isvalid(figs(i)) && not(strcmp(figs(i).Name, 'Edit Selectable Throttle Model')) ...
                        && not(strcmp(figs(i).Name, 'Edit Limited Throttle Model')) ...
                        && not(startsWith(figs(i).Name, 'Throttle Models')))
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
            drawnow;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if(not(isempty(app)) && isvalid(app))
                delete(app);
            end
        end
    end
end
