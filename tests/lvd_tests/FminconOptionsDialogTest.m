classdef FminconOptionsDialogTest < KsptotTestCase
    %FminconOptionsDialogTest Full round-trip UI tests for the FMINCON
    %options editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editFminconOptionsGUI_App.mlapp
    %   ('Edit FMINCON Options'; ctor (wrapper, output) per
    %   FminconOptimizer.openOptionsDialog -- the wrapper's getOptions()
    %   handle is edited in place).
    %   Options class: helper_methods/.../optimizers/options/fmincon/@FminconOptions/FminconOptions.m
    %   (note the control/property name mismatch conTolText <-> tolCon,
    %   verified in the dialog's populateGUI/saveAndClose).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The dialog has no Cancel
    %   button (Save & Close only), so dismissal-without-save is the
    %   window-X close.  Blank text fields are legal (empty implies the
    %   solver default, i.e. NaN) -- only out-of-range/non-numeric input is
    %   rejected.
    %
    % COVERED
    %   Open shows stored values; every enum combo lists its members;
    %   no-edit Save changes nothing (numeric/logical snapshot);
    %   edit+save writes texts, combos and checkboxes through; a negative
    %   maxIters is rejected leaving the dialog open and the model alone;
    %   a blank field stores NaN; window-X close preserves the model.

    properties(Access=private)
        fixture UiwaitInterceptorFixture
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            opt = wrapper.getOptions();
            opt.algorithm = LvdFminconAlgorithmEnum.SQP;
            opt.maxIter = 750;
            opt.maxFuncEvals = 5000;
            opt.finDiffStepSize = 0.002;
            opt.finDiffType = FminconFiniteDiffTypeEnum.ThreePtCentralDiff;
            opt.useParallel = FminconUseParallelEnum.UseParallel;
            opt.computeOptimalStepSizes = true;

            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.algoCombo.Value, ...
                LvdFminconAlgorithmEnum.getIndForName(opt.algorithm.name));
            testCase.verifyEqual(str2double(get(handles.maxItersText, 'String')), 750, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.maxFuncEvalsText, 'String')), 5000, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.finiteDiffStepSizeText, 'String')), 0.002, 'AbsTol', 1e-15);
            testCase.verifyEqual(handles.finiteDiffTypeCombo.Value, ...
                FminconFiniteDiffTypeEnum.getIndForName(opt.finDiffType.name));
            testCase.verifyEqual(handles.useParallelCombo.Value, ...
                FminconUseParallelEnum.getIndForName(opt.useParallel.name));
            testCase.verifyEqual(str2double(get(handles.numParaWorkersText, 'String')), ...
                opt.numWorkers, 'AbsTol', 0);
            testCase.verifyEqual(logical(handles.computeOptimalStepCheckbox.Value), true);
        end

        function combosOfferEveryEnumChoice(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.algoCombo.String)), ...
                numel(enumeration('LvdFminconAlgorithmEnum')), 'Every FMINCON algorithm must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.finiteDiffTypeCombo.String)), ...
                numel(enumeration('FminconFiniteDiffTypeEnum')), 'Every finite-difference type must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.typicalXCombo.String)), ...
                numel(enumeration('OptimizerTypicalXEnum')), 'Every TypicalX mode must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.useParallelCombo.String)), ...
                numel(enumeration('FminconUseParallelEnum')), 'Both parallel modes must be offered.');
        end

        function savingWithoutEditsChangesNothing(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            before = testCase.snapshot(wrapper.getOptions());
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editFminconOptionsGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            after = testCase.snapshot(wrapper.getOptions());
            f = fieldnames(before);
            for i = 1:numel(f)
                testCase.verifyTrue(isequaln(before.(f{i}), after.(f{i})), ...
                    sprintf('%s changed on a no-edit save.', f{i}));
            end
        end

        function editAndSaveWritesThrough(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxItersText, 'String', '750');
            set(handles.optTolText, 'String', '1e-7');
            set(handles.conTolText, 'String', '2e-6');
            handles.finiteDiffTypeCombo.Value = ...
                FminconFiniteDiffTypeEnum.getIndForName(FminconFiniteDiffTypeEnum.ThreePtCentralDiff.name);
            handles.useParallelCombo.Value = ...
                FminconUseParallelEnum.getIndForName(FminconUseParallelEnum.UseParallel.name);
            app.FeasibilityModeCheckBox.Value = true;
            opt = wrapper.getOptions();

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(opt.maxIter, 750, 'AbsTol', 0);
            testCase.verifyEqual(opt.optTol, 1e-7, 'RelTol', 1e-12);
            testCase.verifyEqual(opt.tolCon, 2e-6, 'RelTol', 1e-12);
            testCase.verifyEqual(opt.finDiffType, FminconFiniteDiffTypeEnum.ThreePtCentralDiff);
            testCase.verifyEqual(opt.useParallel, FminconUseParallelEnum.UseParallel);
            testCase.verifyTrue(opt.feasibilityMode);
        end

        function negativeMaxItersIsRejected(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            wrapper.getOptions().maxIter = 750;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxItersText, 'String', '-5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative maxIters must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editFminconOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(wrapper.getOptions().maxIter, 750, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankTextMeansDefaultNaN(testCase)
            %Empty is explicitly legal in validateDoubleValue (it implies
            %the solver default) and round-trips as NaN.
            [wrapper, ~, ~] = testCase.buildFixture();
            testCase.assertEqual(wrapper.getOptions().maxIter, 500);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxItersText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A blank field must save as the default.');
            testCase.verifyTrue(isnan(wrapper.getOptions().maxIter), ...
                'A blank maxIters must store NaN (solver default).');
        end

        function closeWithoutSavingPreservesModel(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editFminconOptionsGUI;

            set(handles.maxItersText, 'String', '9999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(wrapper.getOptions().maxIter, 500, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [wrapper, lvdData, out] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            wrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Fmincon);
            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, wrapper, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editFminconOptionsGUI_App(wrapper, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FminconOptionsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function s = snapshot(~, o)
            %SNAPSHOT  Every numeric/logical option property, as a struct.
            s = struct();
            mc = metaclass(o);
            for p = mc.PropertyList.'
                if p.Dependent || p.Constant || ~strcmp(p.GetAccess, 'public'), continue; end
                v = o.(p.Name);
                if isnumeric(v) || islogical(v), s.(p.Name) = v; end
            end
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit FMINCON Options')
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
            if ~isempty(app) && isvalid(app)
                delete(app);
            end
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit FMINCON Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
