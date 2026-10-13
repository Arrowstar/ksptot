classdef FixedStepIntegratorDialogTest < KsptotTestCase
    %FixedStepIntegratorDialogTest Full round-trip UI tests for the
    %fixed-step integrator options editor (Phase 4: propagation).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/propagation/integration/lvd_fixedStepSizeIntegratorOptionsGUI_App.mlapp
    %   ('Edit Integrator Options'; GUIDE-migrated, uiwait).
    %   backing class: FixedStepSizeIntegratorOptions
    %   production caller: FixedStepSizeIntegratorOptions.openOptionsDialog
    %   (helper_methods/ksptot_lvd/classes/Simulation/integrator/options/@FixedStepSizeIntegratorOptions/FixedStepSizeIntegratorOptions.m:32-36):
    %   lvd_fixedStepSizeIntegratorOptionsGUI_App(obj, output), i.e. the ctor
    %   takes the OPTIONS object (not the integrator wrapper) plus output.
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest / FiniteDiffOptionsDialogTest pattern).
    %   Fields are GUIDE controls, so tests read/write them with
    %   get/set(handles.<field>, 'String') through
    %   convertToGUIDECallbackArguments(app); the Save & Close button is
    %   fired through its ButtonPushedFcn with a minimal event struct.
    %
    % COVERED
    %   Open shows the stored step size and max fixed steps; Save & Close
    %   writes both fields back; a zero step, a negative step and a
    %   below-minimum max-fixed-steps are rejected and leave the model
    %   alone; window-X preserves the model.
    %
    % NOTES
    %   The dialog has no Cancel button (Save & Close only, verified in
    %   document.xml: the only uibutton), so the close-without-save path is
    %   driven with close(fig). A blank field is not covered by the
    %   rejection tests: validateDoubleValue lets blanks through while the
    %   save parses them with str2double, so blank input would store NaN
    %   rather than being rejected. Never propagates.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [opts] = testCase.fixture();
            testCase.assertTrue(isa(opts, 'FixedStepSizeIntegratorOptions'), ...
                'Fixture must hand the dialog a FixedStepSizeIntegratorOptions.');
            opts.setIntegratorStepSize(2.5);
            opts.maxNumFixedSteps = 4000;

            app = testCase.openDialog(opts);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.integratorOutputStepText, 'String')), 2.5, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxFixedStepsText, 'String')), 4000);
        end

        function saveAndCloseWritesBothFields(testCase)
            [opts] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_builtInIntegratorOptionsGUI;

            set(handles.integratorOutputStepText, 'String', '7.5');
            set(handles.maxFixedStepsText, 'String', '1234');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(opts.getIntegratorStepSize(), 7.5, 'RelTol', 1e-9);
            testCase.verifyEqual(opts.maxNumFixedSteps, 1234);
        end

        function zeroStepIsRejected(testCase)
            [opts] = testCase.fixture();
            opts.setIntegratorStepSize(4);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.integratorOutputStepText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero step must not save (minimum 1E-6).');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(opts.getIntegratorStepSize(), 4, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeStepIsRejected(testCase)
            [opts] = testCase.fixture();
            opts.setIntegratorStepSize(4);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.integratorOutputStepText, 'String', '-2');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative step must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI));
            testCase.verifyEqual(opts.getIntegratorStepSize(), 4, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function maxFixedStepsBelowMinimumIsRejected(testCase)
            [opts] = testCase.fixture();
            opts.maxNumFixedSteps = 4000;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxFixedStepsText, 'String', '1');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Max fixed steps below 2 must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI));
            testCase.verifyEqual(opts.maxNumFixedSteps, 4000, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function closeWithoutSavePreservesModel(testCase)
            [opts] = testCase.fixture();
            opts.setIntegratorStepSize(4);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_builtInIntegratorOptionsGUI;

            set(handles.integratorOutputStepText, 'String', '9');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyEqual(opts.getIntegratorStepSize(), 4, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [opts] = fixture(~)
            %Default mission events carry BuiltIn options (ODE45), so the
            %fixed-step object is built directly: it is the same class the
            %ODE5 wrapper owns (ODE5Integrator.m:6,11-16).
            opts = FixedStepSizeIntegratorOptions();
        end

        function app = openDialog(testCase, opts, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_fixedStepSizeIntegratorOptionsGUI_App(opts, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FixedStepIntegratorDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Integrator Options')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Integrator Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
