classdef AdamNlOptOptionsDialogTest < matlab.unittest.TestCase
    %AdamNlOptOptionsDialogTest The Edit AdamNLOpt Options window
    %(lvd_editAdamNlOptOptionsGUI_App).
    %
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture's stand-in lets
    %   the constructor return so the test can drive it, then Save & Close is
    %   pressed the way a click would.
    %
    %   Pins two AdamNlOpt_Review_Report.md fixes end to end:
    %     D2  - opening the dialog and saving without edits must not change any
    %           option.  The FD step used to round-trip sqrt(eps) through text,
    %           come back 4e-23 off, and silently disable automatic FD-step
    %           calibration for every later solve of the case.
    %     D3  - the physical feasibility gate (constrViolTol) and the row-scaling
    %           cap (autoScaleMaxGradient) are reachable from the dialog.
    %     A8  - the derivative checker (checkGradients) is reachable from the dialog.

    properties(Access = private)
        fixture UiwaitInterceptorFixture
        figuresBefore
    end

    methods(TestClassSetup)
        function addPaths(~)
            ksptotAddProjectPaths();
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)
        function theNewOptionsHaveControls(testCase)
            % Each option control is a public property named after the option.
            app = testCase.open(AdamNlOptOptimizer());
            for name = {'constrViolTol', 'autoScaleMaxGradient', 'checkGradients'}
                testCase.verifyTrue(isprop(app, name{1}) && ~isempty(app.(name{1})) && ...
                    isvalid(app.(name{1})), ...
                    sprintf('%s (D3) must be editable from the dialog', name{1}));
            end
            testCase.verifyEqual(str2double(app.constrViolTol.Value), 1e-4, 'RelTol', 1e-12, ...
                'the field must show the option''s current value');
        end

        function savingWithoutEditsChangesNothing(testCase)
            opt = AdamNlOptOptimizer();
            before = testCase.snapshot(opt.getOptions());
            app = testCase.open(opt);
            UiwaitInterceptorFixture.pushButton(app.UIFigure, 'Save & Close');
            after = testCase.snapshot(opt.getOptions());

            f = fieldnames(before);
            for i = 1:numel(f)
                testCase.verifyTrue(isequaln(before.(f{i}), after.(f{i})), ...
                    sprintf('%s changed on a no-edit save: %s -> %s', f{i}, ...
                            mat2str(before.(f{i})), mat2str(after.(f{i}))));
            end
            % The specific D2 consequence: calibration stays armed.
            ev = adamnlopt.Evaluator(testCase.tinyProblem(), ...
                opt.getOptions().getOptionsForOptimizer([]));
            testCase.verifyFalse(ev.fdStepUserSet, ...
                'a no-edit save must leave the FD step at the solver default');
        end
    end

    methods(Access = private)
        function app = open(testCase, optimizer)
            out = AppDesignerGUIOutput({false});
            app = lvd_editAdamNlOptOptionsGUI_App(optimizer, out);
            testCase.assertTrue(isvalid(app.UIFigure), 'the dialog did not open');
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

        function p = tinyProblem(~)
            p = struct('objFun', @(x) sum(x.^2), 'hasObjGrad', false, ...
                'nlcon', [], 'hasConGrad', false, ...
                'Aineq', zeros(0, 1), 'bineq', zeros(0, 1), ...
                'Aeqlin', zeros(0, 1), 'beqlin', zeros(0, 1), ...
                'n', 1, 'mInl', 0, 'mEnl', 0);
        end

        function closeNewFigures(testCase)
            figs = setdiff(findall(groot, 'Type', 'figure'), testCase.figuresBefore);
            delete(figs);
        end
    end
end
