classdef FiniteDiffOptionsDialogTest < KsptotTestCase
    %FiniteDiffOptionsDialogTest Full round-trip UI tests for the finite
    %differences options editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_finiteDiffOptionsGUI_App.mlapp
    %   backing class: CustomFiniteDiffsCalculationMethod, reached as the
    %   same object its openOptionsDialog hands to the dialog
    %   (lvdData.optimizer.customFiniteDiffsCalcMethod).  The DERIVEst
    %   method shares the openOptionsDialog entry point but carries none of
    %   the edited properties (see bug note in the test report).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows the stored step/points/type/sparsity; the type dropdown
    %   offers every FiniteDiffTypeEnum option; Save & Close writes every
    %   edited field back; a zero step and a negative step are rejected and
    %   leave the model alone; window-X preserves the model.
    %
    % NOTES
    %   The dialog has no Cancel button (Save & Close only), so the
    %   close-without-save path is driven with close(fig).  A blank step
    %   field is not covered by the rejection tests: validateDoubleValue
    %   lets blanks through while the save parses them with str2double, so
    %   blank input would store NaN rather than being rejected.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [gradMethod] = testCase.fixture();
            gradMethod.h = 1e-7;
            gradMethod.numPts = 4;
            gradMethod.diffType = FiniteDiffTypeEnum.Central;
            gradMethod.computeSparsity = true;

            app = testCase.openDialog(gradMethod);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.pertStepHText, 'String')), 1e-7, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.numPointsText, 'String')), 4);
            testCase.verifyEqual(handles.finDiffTypeCombo.Value, FiniteDiffTypeEnum.getIndForName(gradMethod.diffType.name));
            testCase.verifyTrue(logical(handles.computeSparsityCheckbox.Value));
        end

        function typeComboOffersEveryFiniteDiffType(testCase)
            [gradMethod] = testCase.fixture();
            app = testCase.openDialog(gradMethod);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(enumeration('FiniteDiffTypeEnum')), 3, ...
                'Production must define exactly three finite-difference types.');
            expTypes = cellstr(FiniteDiffTypeEnum.getListBoxStr());
            testCase.verifyEqual(sort(cellstr(handles.finDiffTypeCombo.String(:))), sort(expTypes(:)), ...
                'Every finite-difference type must be offered.');
        end

        function noEditSaveChangesNothing(testCase)
            [gradMethod] = testCase.fixture();
            before = testCase.snapshot(gradMethod);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(gradMethod, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_finiteDiffOptionsGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A no-edit save must succeed.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            after = testCase.snapshot(gradMethod);
            testCase.verifyEqual(after.h, before.h, 'RelTol', 1e-9, 'A no-edit save must not move the step.');
            testCase.verifyEqual(after.numPts, before.numPts);
            testCase.verifyEqual(after.diffType, before.diffType);
            testCase.verifyEqual(after.computeSparsity, before.computeSparsity);
        end

        function editAndSaveWritesEveryField(testCase)
            [gradMethod] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(gradMethod, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pertStepHText, 'String', '1e-5');
            set(handles.numPointsText, 'String', '3');
            handles.finDiffTypeCombo.Value = FiniteDiffTypeEnum.getIndForName(FiniteDiffTypeEnum.Backward.name);
            handles.computeSparsityCheckbox.Value = false;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyEqual(gradMethod.h, 1e-5, 'RelTol', 1e-9);
            testCase.verifyEqual(double(gradMethod.numPts), 3);
            testCase.verifyEqual(gradMethod.diffType, FiniteDiffTypeEnum.Backward);
            testCase.verifyFalse(gradMethod.computeSparsity);
        end

        function zeroStepIsRejected(testCase)
            [gradMethod] = testCase.fixture();
            gradMethod.h = 1e-6;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(gradMethod, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.pertStepHText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero step must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_finiteDiffOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(gradMethod.h, 1e-6, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function negativeStepIsRejected(testCase)
            [gradMethod] = testCase.fixture();
            gradMethod.h = 1e-6;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(gradMethod, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.numPointsText, 'String', '3');
            set(handles.pertStepHText, 'String', '-1e-6');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative step must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_finiteDiffOptionsGUI));
            testCase.verifyEqual(gradMethod.h, 1e-6, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function closeWithoutSavePreservesModel(testCase)
            [gradMethod] = testCase.fixture();
            gradMethod.h = 1e-6;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(gradMethod, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_finiteDiffOptionsGUI;

            set(handles.pertStepHText, 'String', '1e-5');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(gradMethod.h, 1e-6, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [gradMethod] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            gradMethod = lvdData.optimizer.customFiniteDiffsCalcMethod;
        end

        function app = openDialog(testCase, gradMethod, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_finiteDiffOptionsGUI_App(gradMethod, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() FiniteDiffOptionsDialogTest.deleteIfValid(app));
        end

        function s = snapshot(~, gradMethod)
            s = struct('h', gradMethod.h, 'numPts', double(gradMethod.numPts), ...
                'diffType', gradMethod.diffType.name, ...
                'computeSparsity', logical(gradMethod.computeSparsity));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
            drawnow;
        end

        function closeAlerts(~)
            figs = findall(groot, 'Type', 'figure');
            for i = 1:numel(figs)
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Finite Differences Options')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Finite Differences Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
