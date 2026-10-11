classdef SurrogateOptOptionsDialogTest < KsptotTestCase
    %SurrogateOptOptionsDialogTest Full round-trip UI tests for the
    %surrogate optimizer options editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editSurrogateOptOptionsGUI_App.mlapp
    %   backing class: SurrogateOptimizerOptions, reached through the
    %   SurrogateOptimizer wrapper
    %   (lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Surrogate)).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored tolerance/maximums/surrogate/parallel values;
    %   Save & Close writes every edited field back; a negative max-evals
    %   and a zero batch interval are rejected and leave the model alone;
    %   window-X preserves the model; the parallel dropdown offers both
    %   modes.  NaN-backed fields round-trip through blank text (the
    %   blank-means-default convention shared with validateDoubleValue).
    %
    % NOTES
    %   The dialog has no Cancel button (Save & Close only), so the
    %   close-without-save path is driven with close(fig).  The figure is
    %   titled 'Edit FMINCON Options' in production (a copy-paste of the
    %   fmincon dialog title); teardown matches that literal name.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [wrapper, opt] = testCase.fixture();
            opt.tolCon = 1e-5;
            opt.maxFuncEvals = 321;
            opt.batchUpdateInterval = 5;
            opt.minSampleDistance = 0.5;
            opt.minSurrogatePoints = 40;
            opt.numWorkers = 2;
            opt.useParallel = SurrogateOptUseParallelEnum.UseParallel;

            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.conTolText, 'String')), 1e-5, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.maxFuncEvalsText, 'String')), 321);
            testCase.verifyEqual(str2double(get(handles.batchUpdateIntervalText, 'String')), 5);
            testCase.verifyEqual(str2double(get(handles.minSampleDistanceText, 'String')), 0.5, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.minSurrogatePointsText, 'String')), 40);
            testCase.verifyEqual(str2double(get(handles.numParaWorkersText, 'String')), 2);
            testCase.verifyEqual(handles.useParallelCombo.Value, SurrogateOptUseParallelEnum.getIndForName(opt.useParallel.name));
        end

        function parallelComboOffersBothModes(testCase)
            [wrapper, ~] = testCase.fixture();
            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.useParallelCombo.String)), numel(enumeration('SurrogateOptUseParallelEnum')), ...
                'Every parallel mode must be offered.');
        end

        function noEditSaveChangesNothing(testCase)
            [wrapper, opt] = testCase.fixture();
            before = testCase.snapshot(opt);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editSurrogateOptOptionsGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A no-edit save must succeed.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifySnapshotEqual(before, testCase.snapshot(opt));
        end

        function editAndSaveWritesEveryField(testCase)
            [wrapper, opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.conTolText, 'String', '1e-4');
            set(handles.maxFuncEvalsText, 'String', '750');
            set(handles.batchUpdateIntervalText, 'String', '4');
            set(handles.minSampleDistanceText, 'String', '0.1');
            set(handles.minSurrogatePointsText, 'String', '25');
            set(handles.numParaWorkersText, 'String', '1');
            handles.useParallelCombo.Value = SurrogateOptUseParallelEnum.getIndForName(SurrogateOptUseParallelEnum.UseParallel.name);

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyEqual(opt.tolCon, 1e-4, 'RelTol', 1e-9);
            testCase.verifyEqual(opt.maxFuncEvals, 750);
            testCase.verifyEqual(opt.batchUpdateInterval, 4);
            testCase.verifyEqual(opt.minSampleDistance, 0.1, 'AbsTol', 1e-12);
            testCase.verifyEqual(opt.minSurrogatePoints, 25);
            testCase.verifyEqual(opt.numWorkers, 1);
            testCase.verifyEqual(opt.useParallel, SurrogateOptUseParallelEnum.UseParallel);
        end

        function negativeMaxEvalsIsRejected(testCase)
            [wrapper, opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxFuncEvalsText, 'String', '-5');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative max-evals must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editSurrogateOptOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyTrue(isnan(opt.maxFuncEvals), ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function zeroBatchIntervalIsRejected(testCase)
            [wrapper, opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.batchUpdateIntervalText, 'String', '0');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero batch interval must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editSurrogateOptOptionsGUI));
            testCase.verifyTrue(isnan(opt.batchUpdateInterval), ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function closeWithoutSavePreservesModel(testCase)
            [wrapper, opt] = testCase.fixture();
            opt.tolCon = 1e-5;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editSurrogateOptOptionsGUI;

            set(handles.conTolText, 'String', '1e-2');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(opt.tolCon, 1e-5, 'RelTol', 1e-12, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [wrapper, opt] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            wrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Surrogate);
            opt = wrapper.getOptions();
        end

        function app = openDialog(testCase, wrapper, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editSurrogateOptOptionsGUI_App(wrapper, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() SurrogateOptOptionsDialogTest.deleteIfValid(app));
        end

        function s = snapshot(~, opt)
            s = struct('tolCon', opt.tolCon, 'maxFuncEvals', opt.maxFuncEvals, ...
                'batchUpdateInterval', opt.batchUpdateInterval, ...
                'minSampleDistance', opt.minSampleDistance, ...
                'minSurrogatePoints', opt.minSurrogatePoints, ...
                'numWorkers', opt.numWorkers, ...
                'useParallel', opt.useParallel.name);
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
