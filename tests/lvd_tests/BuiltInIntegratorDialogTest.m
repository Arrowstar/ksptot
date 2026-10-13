classdef BuiltInIntegratorDialogTest < KsptotTestCase
    %BuiltInIntegratorDialogTest Full round-trip UI tests for the built-in
    %integrator options editor (Phase 4: propagation).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/propagation/integration/lvd_builtInIntegratorOptionsGUI_App.mlapp
    %   ('Edit Integrator Options'; GUIDE-migrated, uiwait).
    %   backing class: BuiltInIntegratorOptions
    %   production caller: BuiltInIntegratorOptions.openOptionsDialog
    %   (helper_methods/ksptot_lvd/classes/Simulation/integrator/options/@BuiltInIntegratorOptions/BuiltInIntegratorOptions.m:52-56):
    %   lvd_builtInIntegratorOptionsGUI_App(obj, output), i.e. the ctor takes
    %   the OPTIONS object (not the integrator wrapper) plus the output struct.
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
    %   Open shows stored tolerances/steps/sizes/checkbox; Save & Close
    %   writes every field back; a blank tolerance saves as the NaN default
    %   (validateDoubleValue allow-empty); a negative tolerance, a zero
    %   refinement factor and a below-minimum max-fixed-steps are rejected
    %   and leave the model alone; window-X preserves the model.
    %
    % NOTES
    %   The dialog has no Cancel button (Save & Close only, verified in
    %   document.xml: the only uibutton), so the close-without-save path is
    %   driven with close(fig) (the FiniteDiffOptionsDialogTest pattern). A
    %   negative output step is NOT rejected here: the built-in dialog
    %   validates it on (-Inf, Inf) because <= 0 means "native output".
    %   Never propagates: only the options object is touched.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            testCase.assertTrue(isa(opts, 'BuiltInIntegratorOptions'), ...
                'Fixture must hand the dialog a BuiltInIntegratorOptions.');
            opts.AbsTol = 1e-9;
            opts.RelTol = 1e-10;
            opts.NormControl = true;
            opts.Refine = 3;
            opts.InitialStep = 0.5;
            opts.MaxStep = 60;
            opts.integratorStepSize = 10;
            opts.maxNumFixedSteps = 5000;

            app = testCase.openDialog(opts);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.absTolText, 'String')), 1e-9, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.relTolText, 'String')), 1e-10, 'RelTol', 1e-9);
            testCase.verifyTrue(logical(handles.normControlCheckbox.Value), ...
                'The norm-control checkbox must reflect the stored flag.');
            testCase.verifyEqual(str2double(get(handles.refineText, 'String')), 3);
            testCase.verifyEqual(str2double(get(handles.initialStepSizeText, 'String')), 0.5, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxStepSizeText, 'String')), 60, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.integratorOutputStepText, 'String')), 10, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxFixedStepsText, 'String')), 5000);
        end

        function saveAndCloseWritesEveryField(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_builtInIntegratorOptionsGUI;

            set(handles.absTolText, 'String', '1e-9');
            set(handles.relTolText, 'String', '1e-8');
            handles.normControlCheckbox.Value = 1;
            set(handles.integratorOutputStepText, 'String', '5');
            set(handles.initialStepSizeText, 'String', '0.25');
            set(handles.refineText, 'String', '4');
            set(handles.maxStepSizeText, 'String', '100');
            set(handles.maxFixedStepsText, 'String', '7777');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(opts.AbsTol, 1e-9, 'RelTol', 1e-9);
            testCase.verifyEqual(opts.RelTol, 1e-8, 'RelTol', 1e-9);
            testCase.verifyTrue(opts.NormControl, 'The checkbox must write through.');
            testCase.verifyEqual(opts.integratorStepSize, 5, 'RelTol', 1e-9);
            testCase.verifyEqual(opts.InitialStep, 0.25, 'RelTol', 1e-9);
            testCase.verifyEqual(opts.Refine, 4);
            testCase.verifyEqual(opts.MaxStep, 100, 'RelTol', 1e-9);
            testCase.verifyEqual(opts.maxNumFixedSteps, 7777);
        end

        function blankToleranceSavesAsNaNDefault(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            opts.AbsTol = 1e-9;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.absTolText, 'String', '');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A blank tolerance means "use default" and must save.');
            testCase.verifyTrue(isnan(opts.AbsTol), ...
                'A blank tolerance must save as NaN (validateDoubleValue allow-empty).');
        end

        function negativeAbsTolIsRejected(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            opts.AbsTol = 1e-9;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.absTolText, 'String', '-1e-6');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative tolerance must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(opts.AbsTol, 1e-9, 'RelTol', 1e-9, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function zeroRefineIsRejected(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            before = opts.Refine;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.refineText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero refinement factor must not save (minimum 1).');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI));
            testCase.verifyEqual(opts.Refine, before, 'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function maxFixedStepsBelowMinimumIsRejected(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            before = opts.maxNumFixedSteps;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxFixedStepsText, 'String', '1');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'Max fixed steps below 2 must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_builtInIntegratorOptionsGUI));
            testCase.verifyEqual(opts.maxNumFixedSteps, before, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function closeWithoutSavePreservesModel(testCase)
            [opts, lvdData] = testCase.fixture(); %#ok<ASGLU>
            opts.AbsTol = 1e-9;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(opts, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_builtInIntegratorOptionsGUI;

            set(handles.absTolText, 'String', '1e-5');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyEqual(opts.AbsTol, 1e-9, 'RelTol', 1e-9, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [opts, lvdData] = fixture(testCase)
            %The dialog edits the event's own options handle, reached the
            %way ValidatorTest does: evt.integratorObj.getOptions().
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            opts = evt.integratorObj.getOptions();
        end

        function app = openDialog(testCase, opts, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_builtInIntegratorOptionsGUI_App(opts, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() BuiltInIntegratorDialogTest.deleteIfValid(app));
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
