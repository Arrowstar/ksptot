classdef IpoptOptionsDialogTest < KsptotTestCase
    %IpoptOptionsDialogTest Full round-trip UI tests for the IPOPT options
    %editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editIpoptOptionsGUI_App.mlapp
    %   ('Edit IPOPT Options'; ctor (wrapper, output) per
    %   IpOptOptimizer.openOptionsDialog -- the wrapper's getOptions()
    %   handle is edited in place).
    %   Options class: helper_methods/.../optimizers/options/ipopt/@IpoptOptions/IpoptOptions.m
    %   (property/control map tol<->tolText, constr_viol_tol<->
    %   constrViolTolText, dual_inf_tol<->dualInfTolText, max_iter<->
    %   maxIterText, corrector_type<->correctorTypeCombo, useParallel<->
    %   useParallelCombo, numWorkers<->numParaWorkersText).
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
    %   edit+save writes texts and combos through; a negative maxIter is
    %   rejected leaving the dialog open and the model alone; a blank
    %   field stores NaN; window-X close preserves the model.

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
            opt.tol = 1e-7;
            opt.constr_viol_tol = 1e-5;
            opt.dual_inf_tol = 0.5;
            opt.max_iter = 1500;
            opt.max_cpu_time = 3600;
            opt.corrector_type = IpOptCorrectorTypeEnum.Affine;
            opt.useParallel = IpoptUseParallelEnum.UseParallel;

            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.tolText, 'String')), 1e-7, 'RelTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.constrViolTolText, 'String')), 1e-5, 'RelTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.dualInfTolText, 'String')), 0.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.maxIterText, 'String')), 1500, 'AbsTol', 0);
            testCase.verifyEqual(str2double(get(handles.maxCpuTime, 'String')), 3600, 'AbsTol', 1e-9);
            testCase.verifyEqual(handles.correctorTypeCombo.Value, ...
                IpOptCorrectorTypeEnum.getIndForName(opt.corrector_type.name));
            testCase.verifyEqual(handles.useParallelCombo.Value, ...
                IpoptUseParallelEnum.getIndForName(opt.useParallel.name));
            testCase.verifyEqual(str2double(get(handles.numParaWorkersText, 'String')), ...
                opt.numWorkers, 'AbsTol', 0);
        end

        function combosOfferEveryEnumChoice(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.correctorTypeCombo.String)), ...
                numel(enumeration('IpOptCorrectorTypeEnum')), 'Every corrector type must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.alphaForYCombo.String)), ...
                numel(enumeration('IpOptAlphaForYEnum')), 'Every alpha-for-y mode must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.recalcYCombo.String)), ...
                numel(enumeration('IpOptRecalcYEnum')), 'Every recalc-y mode must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.useParallelCombo.String)), ...
                numel(enumeration('IpoptUseParallelEnum')), 'Both parallel modes must be offered.');
        end

        function savingWithoutEditsChangesNothing(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            before = testCase.snapshot(wrapper.getOptions());
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editIpoptOptionsGUI;

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

            set(handles.maxIterText, 'String', '1200');
            set(handles.tolText, 'String', '1e-7');
            set(handles.constrViolTolText, 'String', '1e-5');
            handles.correctorTypeCombo.Value = ...
                IpOptCorrectorTypeEnum.getIndForName(IpOptCorrectorTypeEnum.Affine.name);
            handles.useParallelCombo.Value = ...
                IpoptUseParallelEnum.getIndForName(IpoptUseParallelEnum.UseParallel.name);
            opt = wrapper.getOptions();

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(opt.max_iter, 1200, 'AbsTol', 0);
            testCase.verifyEqual(opt.tol, 1e-7, 'RelTol', 1e-12);
            testCase.verifyEqual(opt.constr_viol_tol, 1e-5, 'RelTol', 1e-12);
            testCase.verifyEqual(opt.corrector_type, IpOptCorrectorTypeEnum.Affine);
            testCase.verifyEqual(opt.useParallel, IpoptUseParallelEnum.UseParallel);
        end

        function negativeMaxIterIsRejected(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            testCase.assertEqual(wrapper.getOptions().max_iter, 3000);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxIterText, 'String', '-3');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative maxIter must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editIpoptOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(wrapper.getOptions().max_iter, 3000, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function blankTextMeansDefaultNaN(testCase)
            %Empty is explicitly legal in validateDoubleValue (it implies
            %the solver default) and round-trips as NaN.
            [wrapper, ~, ~] = testCase.buildFixture();
            wrapper.getOptions().tol = 1e-7;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.tolText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A blank field must save as the default.');
            testCase.verifyTrue(isnan(wrapper.getOptions().tol), ...
                'A blank tol must store NaN (solver default).');
        end

        function closeWithoutSavingPreservesModel(testCase)
            [wrapper, ~, ~] = testCase.buildFixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editIpoptOptionsGUI;

            set(handles.maxIterText, 'String', '9999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(wrapper.getOptions().max_iter, 3000, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [wrapper, lvdData, out] = buildFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            wrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Ipopt);
            out = AppDesignerGUIOutput({false});
        end

        function app = openDialog(testCase, wrapper, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editIpoptOptionsGUI_App(wrapper, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() IpoptOptionsDialogTest.deleteIfValid(app));
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
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit IPOPT Options')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit IPOPT Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
