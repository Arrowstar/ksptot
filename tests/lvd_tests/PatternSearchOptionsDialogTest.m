classdef PatternSearchOptionsDialogTest < KsptotTestCase
    %PatternSearchOptionsDialogTest Full round-trip UI tests for the pattern
    %search options editor (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_editPatternSearchOptionsGUI_App.mlapp
    %   backing class: PatternSearchOptions, reached through the
    %   PatternSearchOptimizer wrapper
    %   (lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.PatternSearch)).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   PatchedMlappDialogsTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.
    %
    % COVERED
    %   Open shows stored tolerances/mesh/limits/enums; Save & Close writes
    %   every edited field back; a negative max-evals and a non-numeric
    %   tolerance are rejected and leave the model alone; window-X preserves
    %   the model; every poll/search/parallel enum option is offered.
    %
    % NOTES
    %   The dialog has no Cancel button (Save & Close only), so the
    %   close-without-save path is driven with close(fig).  A blank edit
    %   field is not a rejection: validateDoubleValue treats blank as
    %   "use default" and the save writes NaN, so rejection tests use
    %   out-of-range and non-numeric input instead.

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredValues(testCase)
            [wrapper, opt] = testCase.fixture();
            opt.meshExpFact = 3;
            opt.meshContrFact = 0.25;
            opt.initMeshSize = 2;
            opt.maxFunEvals = 1234;
            opt.maxIters = 321;
            opt.stepTol = 1e-7;
            opt.meshTol = 2e-7;
            opt.funTol = 3e-7;
            opt.conTol = 4e-7;
            opt.pollMethod = PattSrchPollMethodEnum.MADSPositiveBasis2N;
            opt.pollOrder = PattSrchPollOrderEnum.Random;
            opt.searchFunc = PattSrchSearchFcnEnum.LatinHypercube;
            opt.useParallel = PatternSearchUseParallelEnum.UseParallel;

            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(str2double(get(handles.meshExpFactorText, 'String')), 3, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.meshContrFactorText, 'String')), 0.25, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.initMeshSizeText, 'String')), 2, 'AbsTol', 1e-12);
            testCase.verifyEqual(str2double(get(handles.maxFunEvalsText, 'String')), 1234);
            testCase.verifyEqual(str2double(get(handles.maxIterText, 'String')), 321);
            testCase.verifyEqual(str2double(get(handles.stepTolText, 'String')), 1e-7, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.meshTolText, 'String')), 2e-7, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.funcTolText, 'String')), 3e-7, 'RelTol', 1e-9);
            testCase.verifyEqual(str2double(get(handles.conTolText, 'String')), 4e-7, 'RelTol', 1e-9);
            testCase.verifyEqual(handles.pollMethodCombo.Value, PattSrchPollMethodEnum.getIndForName(opt.pollMethod.name));
            testCase.verifyEqual(handles.pollOrderCombo.Value, PattSrchPollOrderEnum.getIndForName(opt.pollOrder.name));
            testCase.verifyEqual(handles.searchFuncCombo.Value, PattSrchSearchFcnEnum.getIndForName(opt.searchFunc.name));
            testCase.verifyEqual(handles.useParallelCombo.Value, PatternSearchUseParallelEnum.getIndForName(opt.useParallel.name));
        end

        function combosOfferEveryEnumOption(testCase)
            [wrapper, ~] = testCase.fixture();
            app = testCase.openDialog(wrapper);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(numel(cellstr(handles.pollMethodCombo.String)), numel(enumeration('PattSrchPollMethodEnum')), ...
                'Every poll method must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.pollOrderCombo.String)), numel(enumeration('PattSrchPollOrderEnum')), ...
                'Every poll order must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.searchFuncCombo.String)), numel(enumeration('PattSrchSearchFcnEnum')), ...
                'Every search function must be offered.');
            testCase.verifyEqual(numel(cellstr(handles.useParallelCombo.String)), numel(enumeration('PatternSearchUseParallelEnum')), ...
                'Every parallel mode must be offered.');
        end

        function noEditSaveChangesNothing(testCase)
            [wrapper, opt] = testCase.fixture();
            before = testCase.snapshot(opt);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editPatternSearchOptionsGUI;

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'A no-edit save must succeed.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifySnapshotEqual(before, testCase.snapshot(opt));
        end

        function editAndSaveWritesMeshLimitsAndEnums(testCase)
            [wrapper, opt] = testCase.fixture();
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.meshExpFactorText, 'String', '4');
            set(handles.meshContrFactorText, 'String', '0.25');
            set(handles.initMeshSizeText, 'String', '2');
            set(handles.maxIterText, 'String', '777');
            set(handles.maxFunEvalsText, 'String', '4321');
            set(handles.funcTolText, 'String', '1e-9');
            set(handles.numParaWorkersText, 'String', '1');
            handles.pollMethodCombo.Value = PattSrchPollMethodEnum.getIndForName(PattSrchPollMethodEnum.MADSPositiveBasis2N.name);
            handles.useParallelCombo.Value = PatternSearchUseParallelEnum.getIndForName(PatternSearchUseParallelEnum.UseParallel.name);

            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report success.');
            testCase.verifyEqual(opt.meshExpFact, 4, 'AbsTol', 1e-12);
            testCase.verifyEqual(opt.meshContrFact, 0.25, 'AbsTol', 1e-12);
            testCase.verifyEqual(opt.initMeshSize, 2, 'AbsTol', 1e-12);
            testCase.verifyEqual(double(opt.maxIters), 777);
            testCase.verifyEqual(double(opt.maxFunEvals), 4321);
            testCase.verifyEqual(opt.funTol, 1e-9, 'RelTol', 1e-9);
            testCase.verifyEqual(opt.numWorkers, 1);
            testCase.verifyEqual(opt.pollMethod, PattSrchPollMethodEnum.MADSPositiveBasis2N);
            testCase.verifyEqual(opt.useParallel, PatternSearchUseParallelEnum.UseParallel);
        end

        function negativeMaxItersIsRejected(testCase)
            [wrapper, opt] = testCase.fixture();
            defaultIters = double(opt.maxIters);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.maxIterText, 'String', '-3');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative max-iterations must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editPatternSearchOptionsGUI), ...
                'Failed validation must leave the dialog open.');
            testCase.verifyEqual(double(opt.maxIters), defaultIters, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function nonNumericStepTolIsRejected(testCase)
            [wrapper, opt] = testCase.fixture();
            defaultTol = opt.stepTol;
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            set(handles.stepTolText, 'String', 'abc');
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A non-numeric tolerance must not save.');
            testCase.verifyTrue(isvalid(handles.lvd_editPatternSearchOptionsGUI));
            testCase.verifyEqual(opt.stepTol, defaultTol, ...
                'Rejected input must leave the model alone.');
            testCase.closeAlerts();
        end

        function closeWithoutSavePreservesModel(testCase)
            [wrapper, opt] = testCase.fixture();
            defaultIters = double(opt.maxIters);
            out = AppDesignerGUIOutput({false});
            app = testCase.openDialog(wrapper, out);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_editPatternSearchOptionsGUI;

            set(handles.maxIterText, 'String', '9999');
            close(fig);
            drawnow;

            testCase.verifyFalse(out.output{1}, 'Closing without saving must not report success.');
            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(double(opt.maxIters), defaultIters, ...
                'Closing without saving must leave the model alone.');
        end
    end

    methods(Access=private)
        function [wrapper, opt] = fixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            wrapper = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.PatternSearch);
            opt = wrapper.getOptions();
        end

        function app = openDialog(testCase, wrapper, out)
            if nargin < 3 || isempty(out)
                out = AppDesignerGUIOutput({false});
            end
            app = lvd_editPatternSearchOptionsGUI_App(wrapper, out);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() PatternSearchOptionsDialogTest.deleteIfValid(app));
        end

        function s = snapshot(~, opt)
            s = struct('meshExpFact', opt.meshExpFact, 'meshContrFact', opt.meshContrFact, ...
                'initMeshSize', opt.initMeshSize, 'maxIters', double(opt.maxIters), ...
                'maxFunEvals', double(opt.maxFunEvals), 'stepTol', opt.stepTol, ...
                'meshTol', opt.meshTol, 'funTol', opt.funTol, 'conTol', opt.conTol, ...
                'cacheTol', opt.cacheTol, 'cacheSize', double(opt.cacheSize), ...
                'initPenalty', opt.initPenalty, 'penaltyFact', opt.penaltyFact, ...
                'numWorkers', opt.numWorkers, 'pollMethod', opt.pollMethod.name, ...
                'pollOrder', opt.pollOrder.name, 'searchFunc', opt.searchFunc.name, ...
                'useParallel', opt.useParallel.name, 'cache', opt.cache.name, ...
                'useCompletePoll', opt.useCompletePoll.name, ...
                'useCompleteSearch', opt.useCompleteSearch.name, ...
                'accelMesh', opt.accelMesh.name, 'meshRotate', opt.meshRotate.name, ...
                'scaleMesh', opt.scaleMesh.name);
        end

        function verifySnapshotEqual(testCase, before, after)
            f = fieldnames(before);
            for i = 1:numel(f)
                v0 = before.(f{i});
                v1 = after.(f{i});
                if isnumeric(v0)
                    testCase.verifyEqual(v1, v0, 'RelTol', 1e-9, 'AbsTol', 1e-15, ...
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
                if isvalid(figs(i)) && ~strcmp(figs(i).Name, 'Edit Pattern Search Options')
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Edit Pattern Search Options')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end
