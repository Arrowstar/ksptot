classdef NomadSurrogateOptionsDialogTest < KsptotTestCase
    %NomadSurrogateOptionsDialogTest Full round-trip UI tests for the NOMAD
    %surrogate options editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editNomadSurrogateOptionsGUI_App.mlapp
    %   ('Edit NOMAD Surrogate Options'; modern startupFcn(app,
    %   nomadSurrOpts, output) -- the NomadSurrogateOptions handle is
    %   edited in place).  The object under test is
    %   NomadOptions.surrogateOptions (verified in
    %   helper_methods/.../optimizers/options/nomad/@NomadOptions/NomadOptions.m),
    %   the same object the NOMAD dialog's surrogate button passes.
    %   Optimize-checkbox names (OptimizeDegreeValueCheckBox,
    %   OptimizeRidgeValueCheckBox, OptimizeKernelTypeCheckBox,
    %   OptimizeKernelShapeValueCheckBox, OptimizeDistanceTypeCheckBox)
    %   verified against the .mlapp matlab/document.xml.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  This modern dialog wires its
    %   Save button to saveAndCloseButtonPushed(app, event), which the
    %   pushButton helper fires the same way.  The dialog has no Cancel
    %   button (Save & Close only), so dismissal-without-save is the
    %   window-X close.
    %
    % COVERED
    %   Open shows stored values; each Optimize checkbox toggles its
    %   field's Enable; no-edit Save changes nothing (numeric/logical
    %   snapshot); edit+save writes every field through; an out-of-range
    %   Lambda P is rejected leaving the dialog open and the model alone;
    %   switching model type updates the parameter panels; window-X close
    %   preserves the model.

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
            [surrOpts, ~, ~] = testCase.buildFixture();
            surrOpts.type = NomadSurrogateModelTypeEnum.RBF;
            surrOpts.degree = 3;
            surrOpts.degree_optim = false;
            surrOpts.ridge = 0.01;
            surrOpts.ridge_optim = false;
            surrOpts.kernel_type = NomadSurrogateKernelTypeEnum.I1;
            surrOpts.kernel_shape = 2;
            surrOpts.distance_type = NomadSurrogateDistanceTypeEnum.NORM1;
            surrOpts.weight = NomadSurrogateWeightTypeEnum.WTA1;
            surrOpts.metric = NomadSurrogateMetricTypeEnum.RMSE;
            surrOpts.budget = 50;

            app = testCase.openDialog(surrOpts);

            testCase.verifyEqual(app.ModelTypeDropdown.Value, NomadSurrogateModelTypeEnum.RBF);
            testCase.verifyEqual(app.DegreeSpinner.Value, 3);
            testCase.verifyFalse(app.OptimizeDegreeValueCheckBox.Value);
            testCase.verifyEqual(str2double(app.RidgeEditField.Value), 0.01, 'RelTol', 1e-12);
            testCase.verifyFalse(app.OptimizeRidgeValueCheckBox.Value);
            testCase.verifyEqual(app.KernelTypeDropDown.Value, NomadSurrogateKernelTypeEnum.I1);
            testCase.verifyEqual(str2double(app.KernelShapeEditField.Value), 2, 'AbsTol', 1e-12);
            testCase.verifyEqual(app.DistanceFunctionDropDown.Value, NomadSurrogateDistanceTypeEnum.NORM1);
            testCase.verifyEqual(app.WeightTypeDropDown.Value, NomadSurrogateWeightTypeEnum.WTA1);
            testCase.verifyEqual(app.MetricTypeDropDown.Value, NomadSurrogateMetricTypeEnum.RMSE);
            testCase.verifyEqual(app.BudgetSpinner.Value, 50);
        end

        function optimizeCheckboxesToggleTheirFields(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            app = testCase.openDialog(surrOpts);

            % OPTIM on (the default) disables the corresponding field.
            testCase.verifyEqual(string(app.DegreeSpinner.Enable), "off");
            testCase.verifyEqual(string(app.RidgeEditField.Enable), "off");
            testCase.verifyEqual(string(app.KernelTypeDropDown.Enable), "off");
            testCase.verifyEqual(string(app.KernelShapeEditField.Enable), "off");
            testCase.verifyEqual(string(app.DistanceFunctionDropDown.Enable), "off");

            app.OptimizeDegreeValueCheckBox.Value = false;
            testCase.fireValueChanged(app.OptimizeDegreeValueCheckBox);
            testCase.verifyEqual(string(app.DegreeSpinner.Enable), "on", ...
                'Clearing OPTIM must enable the degree field.');

            app.OptimizeRidgeValueCheckBox.Value = false;
            testCase.fireValueChanged(app.OptimizeRidgeValueCheckBox);
            testCase.verifyEqual(string(app.RidgeEditField.Enable), "on", ...
                'Clearing OPTIM must enable the ridge field.');

            app.OptimizeKernelTypeCheckBox.Value = false;
            testCase.fireValueChanged(app.OptimizeKernelTypeCheckBox);
            testCase.verifyEqual(string(app.KernelTypeDropDown.Enable), "on");

            app.OptimizeKernelShapeValueCheckBox.Value = false;
            testCase.fireValueChanged(app.OptimizeKernelShapeValueCheckBox);
            testCase.verifyEqual(string(app.KernelShapeEditField.Enable), "on");

            app.OptimizeDistanceTypeCheckBox.Value = false;
            testCase.fireValueChanged(app.OptimizeDistanceTypeCheckBox);
            testCase.verifyEqual(string(app.DistanceFunctionDropDown.Enable), "on");
        end

        function savingWithoutEditsChangesNothing(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            before = testCase.snapshot(surrOpts);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(surrOpts, out);
            fig = app.EditNOMADSurrogateOptionsUIFigure;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            after = testCase.snapshot(surrOpts);
            f = fieldnames(before);
            for i = 1:numel(f)
                testCase.verifyTrue(isequaln(before.(f{i}), after.(f{i})), ...
                    sprintf('%s changed on a no-edit save.', f{i}));
            end
        end

        function editAndSaveWritesThrough(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(surrOpts, out);

            % RBF ignores the degree panel but still stores its value; the
            % OPTIM checkboxes stay on so degree/ridge/shape skip validation.
            app.ModelTypeDropdown.Value = NomadSurrogateModelTypeEnum.RBF;
            app.DegreeSpinner.Value = 4;
            app.RidgeEditField.Value = '0.02';
            app.KernelTypeDropDown.Value = NomadSurrogateKernelTypeEnum.I1;
            app.KernelShapeEditField.Value = '1.5';
            app.DistanceFunctionDropDown.Value = NomadSurrogateDistanceTypeEnum.NORM1;
            app.SizeParameterEditField.Value = '0.002';
            app.SigmaMultiplierEditField.Value = '8';
            app.LambdaPEditField.Value = '4';
            app.LambdaPiEditField.Value = '0.3';
            app.BudgetSpinner.Value = 60;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(surrOpts.type, NomadSurrogateModelTypeEnum.RBF);
            testCase.verifyEqual(surrOpts.degree, 4);
            testCase.verifyEqual(surrOpts.ridge, 0.02, 'RelTol', 1e-12);
            testCase.verifyEqual(surrOpts.kernel_type, NomadSurrogateKernelTypeEnum.I1);
            testCase.verifyEqual(surrOpts.kernel_shape, 1.5, 'RelTol', 1e-12);
            testCase.verifyEqual(surrOpts.distance_type, NomadSurrogateDistanceTypeEnum.NORM1);
            testCase.verifyEqual(surrOpts.size_param, 0.002, 'RelTol', 1e-12);
            testCase.verifyEqual(surrOpts.sigma_mult, 8, 'AbsTol', 1e-12);
            testCase.verifyEqual(surrOpts.lambda_p, 4, 'AbsTol', 1e-12);
            testCase.verifyEqual(surrOpts.lambda_pi, 0.3, 'AbsTol', 1e-12);
            testCase.verifyEqual(surrOpts.budget, 60);
        end

        function invalidLambdaPIsRejected(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            testCase.assertEqual(surrOpts.lambda_p, 3);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(surrOpts, out);

            app.LambdaPEditField.Value = '-1';
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'An out-of-range Lambda P must not save.');
            testCase.verifyTrue(isvalid(app.EditNOMADSurrogateOptionsUIFigure), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(surrOpts.lambda_p, 3, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function modelTypeSwitchUpdatesPanels(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            app = testCase.openDialog(surrOpts);

            app.ModelTypeDropdown.Value = NomadSurrogateModelTypeEnum.ENSEMBLE_STAT;
            testCase.fireValueChanged(app.ModelTypeDropdown);

            testCase.verifyEqual(string(app.ENSEMBLEParametersPanel.Enable), "on", ...
                'ENSEMBLE_STAT must enable the ENSEMBLE panel.');
            testCase.verifyEqual(string(app.ENSEMBLESTATParametersPanel.Enable), "on", ...
                'ENSEMBLE_STAT must enable the ENSEMBLE_STAT panel.');
            testCase.verifyEqual(string(app.DegreePanel.Enable), "off", ...
                'ENSEMBLE_STAT must disable the degree panel.');
        end

        function closeWithoutSavingPreservesModel(testCase)
            [surrOpts, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(surrOpts, out);
            fig = app.EditNOMADSurrogateOptionsUIFigure;

            app.BudgetSpinner.Value = 60;
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(surrOpts.budget, 100, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [surrOpts, lvdData, out] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            nomadWrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Nomad);
            surrOpts = nomadWrapper.getOptions().surrogateOptions;
            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, surrOpts, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editNomadSurrogateOptionsGUI_App(surrOpts, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() NomadSurrogateOptionsDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function fireValueChanged(~, comp)
            evt = struct('Source', comp, 'EventName', 'ValueChanged', ...
                'Value', comp.Value, 'PreviousValue', comp.Value);
            comp.ValueChangedFcn(comp, evt);
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
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit NOMAD Surrogate Options')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit NOMAD Surrogate Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
