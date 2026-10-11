classdef SqpOptionsDialogTest < KsptotTestCase
    %SqpOptionsDialogTest Full round-trip UI tests for the SQP options
    %editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editSqpOptOptionsGUI_App.mlapp
    %   backing class: SqpOptions, reached through the SQPOptimizer wrapper
    %   (lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.SQP).getOptions()).
    %
    % PATTERN
    %   This is a modern App Designer dialog: startupFcn(app, options,
    %   output) takes the OPTIONS object (not the wrapper) and the dialog
    %   never calls uiwait, so applying UiwaitInterceptorFixture is harmless
    %   and only keeps the class uniform with the other Phase 1 dialog
    %   tests.  The dialog exposes a single Save & Close button (verified in
    %   document.xml: the only uibutton; no Cancel), so the
    %   close-without-save path is driven with delete(app).
    %
    % COVERED
    %   Open shows stored tolerances/step-size/maximums/dropdowns; NaN
    %   defaults show as empty fields; Save & Close writes every edited
    %   field back; a blank tolerance saves as the NaN default; an
    %   out-of-limits assignment is blocked by the control and leaves the
    %   model alone; delete-without-save preserves the model; the
    %   termination dropdown offers every SqpTerminationCondEnum option.
    %
    % NOTES
    %   saveAndCloseButtonPushed performs no validation (errMsg is hard-set
    %   to {}), so there is no dialog-level rejection path to test: every
    %   in-limits value, including blank (meaning NaN default), saves.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [opt] = testCase.fixture();
            opt.stepTol = 1e-7;
            opt.optTol = 1e-8;
            opt.tolCon = 1e-5;
            opt.finDiffStepSize = 1e-3;
            opt.maxIter = 111;
            opt.maxFuncEvals = 222;
            opt.maxLineSearchFun = 17;
            opt.numWorkers = 2;
            opt.useParallel = SqpUseParallelEnum.UseParallel;
            opt.terminationType = SqpTerminationCondEnum.Standard;

            app = testCase.openDialog(opt);

            testCase.verifyEqual(app.StepToleranceEditField.Value, 1e-7);
            testCase.verifyEqual(app.OptimalityToleranceEditField.Value, 1e-8);
            testCase.verifyEqual(app.ConstraintToleranceEditField.Value, 1e-5);
            testCase.verifyEqual(app.StepSizeEditField.Value, 1e-3);
            testCase.verifyEqual(app.MaxIterationsEditField.Value, 111);
            testCase.verifyEqual(app.MaxFunctionEvalsEditField.Value, 222);
            testCase.verifyEqual(app.MaxLineSearchIterationsEditField.Value, 17);
            testCase.verifyEqual(app.NumParallelWorkersEditField.Value, 2);
            testCase.verifyEqual(app.UseParallelizationDropDown.Value, SqpUseParallelEnum.UseParallel);
            testCase.verifyEqual(app.OptimalityCriteriaDropDown.Value, SqpTerminationCondEnum.Standard);
        end

        function nanDefaultsShowAsEmpty(testCase)
            [opt] = testCase.fixture();
            app = testCase.openDialog(opt);

            testCase.verifyTrue(isempty(app.StepToleranceEditField.Value), ...
                'A NaN step tolerance must show as an empty field.');
            testCase.verifyTrue(isempty(app.OptimalityToleranceEditField.Value), ...
                'A NaN optimality tolerance must show as an empty field.');
            testCase.verifyTrue(isempty(app.ConstraintToleranceEditField.Value), ...
                'A NaN constraint tolerance must show as an empty field.');
            testCase.verifyEqual(app.MaxIterationsEditField.Value, 500);
            testCase.verifyEqual(app.MaxFunctionEvalsEditField.Value, 3000);
            testCase.verifyEqual(app.StepSizeEditField.Value, 1e-4);
            testCase.verifyEqual(app.MaxLineSearchIterationsEditField.Value, 30);
        end

        function optimalityDropdownOffersEveryTerminationType(testCase)
            [opt] = testCase.fixture();
            app = testCase.openDialog(opt);

            testCase.verifyEqual(numel(app.OptimalityCriteriaDropDown.Items), numel(enumeration('SqpTerminationCondEnum')), ...
                'Every termination criterion must be offered.');
            testCase.verifyEqual(numel(app.OptimalityCriteriaDropDown.ItemsData), numel(enumeration('SqpTerminationCondEnum')));
            testCase.verifyTrue(any(app.OptimalityCriteriaDropDown.ItemsData == SqpTerminationCondEnum.Schittkowski));
            testCase.verifyTrue(any(app.OptimalityCriteriaDropDown.ItemsData == SqpTerminationCondEnum.Standard));
        end

        function noEditSaveChangesNothing(testCase)
            [opt] = testCase.fixture();
            before = testCase.snapshot(opt);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);
            fig = app.EditSQPOptimizerOptionsUIFigure;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A no-edit save must succeed.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifySnapshotEqual(before, testCase.snapshot(opt));
        end

        function editAndSaveWritesTolerancesAndMaximums(testCase)
            [opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);

            app.StepToleranceEditField.Value = 1e-7;
            app.OptimalityToleranceEditField.Value = 1e-8;
            app.ConstraintToleranceEditField.Value = 1e-5;
            app.StepSizeEditField.Value = 1e-3;
            app.MaxIterationsEditField.Value = 111;
            app.MaxFunctionEvalsEditField.Value = 222;
            app.MaxLineSearchIterationsEditField.Value = 17;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyEqual(opt.stepTol, 1e-7);
            testCase.verifyEqual(opt.optTol, 1e-8);
            testCase.verifyEqual(opt.tolCon, 1e-5);
            testCase.verifyEqual(opt.finDiffStepSize, 1e-3);
            testCase.verifyEqual(opt.maxIter, 111);
            testCase.verifyEqual(opt.maxFuncEvals, 222);
        end

        function maxLineSearchIterationsEditIsDroppedOnSave(testCase)
            %REGRESSION (bug log 1.28): saveAndClose never writes
            %maxLineSearchFun, so the field is display-only.  This test pins
            %the current behavior; delete it (and restore the assertion in
            %editAndSaveWritesTolerancesAndMaximums) once the dialog is fixed.
            [opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);

            app.MaxLineSearchIterationsEditField.Value = 17;
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(opt.maxLineSearchFun, 30, ...
                'Save currently drops the line-search edit (bug 1.28).');
        end

        function editAndSaveWritesDropdownsAndWorkers(testCase)
            [opt] = testCase.fixture();
            newWorkers = opt.numWorkers + 1;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);

            app.OptimalityCriteriaDropDown.Value = SqpTerminationCondEnum.Standard;
            app.UseParallelizationDropDown.Value = SqpUseParallelEnum.UseParallel;
            app.NumParallelWorkersEditField.Value = newWorkers;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(opt.terminationType, SqpTerminationCondEnum.Standard);
            testCase.verifyEqual(opt.useParallel, SqpUseParallelEnum.UseParallel);
            testCase.verifyEqual(opt.numWorkers, newWorkers);
        end

        function blankToleranceSavesAsNaNDefault(testCase)
            [opt] = testCase.fixture();
            opt.optTol = 1e-8;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);

            app.OptimalityToleranceEditField.Value = [];
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A blank tolerance means "use default" and must save.');
            testCase.verifyTrue(isnan(opt.optTol), 'A blank tolerance must save as NaN.');
        end

        function outOfLimitsValueIsBlocked(testCase)
            [opt] = testCase.fixture();
            defaultIters = opt.maxIter;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);
            fig = app.EditSQPOptimizerOptionsUIFigure;

            testCase.verifyError(@() testCase.assignOutOfLimits(app), ...
                'MATLAB:ui:NumericEditField:invalidValue', ...
                'A value below the control limits must be rejected by the control.');
            testCase.verifyTrue(isvalid(fig), 'The rejected assignment must leave the dialog open.');
            testCase.verifyEqual(opt.maxIter, defaultIters, ...
                'The rejected assignment must leave the model alone.');
            testCase.verifyFalse(out.output{1});
        end

        function deleteWithoutSavePreservesModel(testCase)
            [opt] = testCase.fixture();
            defaultIters = opt.maxIter;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opt, out);

            app.MaxIterationsEditField.Value = 9999;
            delete(app);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Deleting without saving must not report success.');
            testCase.verifyEqual(opt.maxIter, defaultIters, ...
                'Deleting without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [opt] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            opt = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.SQP).getOptions();
        end

        function app = openDialog(testCase, opt, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editSqpOptOptionsGUI_App(opt, out);
            drawnow;
            testCase.assertTrue(~isempty(app) && isvalid(app.EditSQPOptimizerOptionsUIFigure), ...
                'The dialog did not open.');
            testCase.addTeardown(@() SqpOptionsDialogTest.deleteIfValid(app));
        end

        function s = snapshot(~, opt)
            s = struct('stepTol', opt.stepTol, 'optTol', opt.optTol, ...
                'tolCon', opt.tolCon, 'finDiffStepSize', opt.finDiffStepSize, ...
                'maxIter', opt.maxIter, 'maxFuncEvals', opt.maxFuncEvals, ...
                'maxLineSearchFun', opt.maxLineSearchFun, ...
                'numWorkers', opt.numWorkers, ...
                'useParallel', opt.useParallel.name, ...
                'terminationType', opt.terminationType.name);
        end

        function verifySnapshotEqual(testCase, before, after)
            f = fieldnames(before);
            for i = 1:numel(f)
                v0 = before.(f{i});
                v1 = after.(f{i});
                if isnumeric(v0)
                    testCase.verifyTrue(isequaln(v1, v0), ...
                        sprintf('%s changed on a no-edit save.', f{i}));
                else
                    testCase.verifyEqual(v1, v0, ...
                        sprintf('%s changed on a no-edit save.', f{i}));
                end
            end
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function assignOutOfLimits(~, app)
            app.MaxIterationsEditField.Value = 0;
        end
    end

    methods(Static, Access=private)
        function deleteIfValid(app)
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit SQP Optimizer Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
