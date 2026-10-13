classdef OptimizerSelectionDialogTest < matlab.uitest.TestCase
    %OptimizerSelectionDialogTest Full round-trip UI tests for the optimizer
    %algorithm selection dialog (Phase 1: optimization).
    %
    % SUBJECT UNDER TEST
    %   kspTOT_LaunchVehicleDesigner/optimization/optimizer/lvd_OptimizerSelectionGUI_App.mlapp
    %   ('Optimizer Algorithm Selection'; single-arg ctor (lvdData), no
    %   output arg -- Save writes straight into lvdData.optimizer).
    %   Model fields: LvdOptimization.optAlgo / .gradAlgo (both verified in
    %   helper_methods/ksptot_lvd/classes/Optimization/@LvdOptimization/LvdOptimization.m).
    %
    % PATTERN
    %   The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    %   uiwait so the constructor returns the live app (the
    %   TankConstraintDialogTest pattern).  Buttons are fired through their
    %   ButtonPushedFcn with a minimal event struct because these
    %   GUIDE-migrated dialogs read event.Source.  The options buttons open
    %   nested options dialogs; those are stubbed with whenShown handlers
    %   that press their Save & Close (no-edit dismiss -- none of these
    %   dialogs has a Cancel button) and the fixture error log is asserted
    %   empty.
    %
    % COVERED
    %   Open shows stored optAlgo/gradAlgo and their descriptions; both
    %   combos list every enum member; changing both combos and saving
    %   writes lvdData.optimizer.optAlgo/.gradAlgo; a non-gradient
    %   optimizer disables the gradient controls; the gradient-options
    %   button follows each gradient algo's disableOptions flag; the
    %   optimizer-options and gradient-options buttons open the selected
    %   dialogs; window-X close preserves the model.

    properties(Access=private)
        celBodyData
        fixture UiwaitInterceptorFixture
    end

    methods(TestClassSetup)
        function addPaths(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();
        end
    end

    methods(TestMethodSetup)
        function shadowUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
        end
    end

    methods(Test)
        function dialogShowsStoredSelections(testCase)
            lvdData = testCase.lvdFixture();
            lvdData.optimizer.optAlgo = LvdOptimizerAlgoEnum.Ipopt;
            lvdData.optimizer.gradAlgo = LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences;

            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.verifyEqual(handles.optimizerSelectionCombo.Value, ...
                LvdOptimizerAlgoEnum.getIndForName(LvdOptimizerAlgoEnum.Ipopt.name), ...
                'The optimizer combo must show the stored optAlgo.');
            testCase.verifyEqual(handles.gradientSelCombo.Value, ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences.name), ...
                'The gradient combo must show the stored gradAlgo.');
            testCase.verifyEqual(handles.optimAlgDescTextLbl.String, LvdOptimizerAlgoEnum.Ipopt.desc);
            testCase.verifyEqual(handles.optimGradAlgDescTextLbl.String, ...
                LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences.desc);
        end

        function combosListEveryOptimizerAndGradientAlgo(testCase)
            lvdData = testCase.lvdFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            optItems = cellstr(handles.optimizerSelectionCombo.String);
            testCase.verifyEqual(numel(optItems), numel(enumeration('LvdOptimizerAlgoEnum')), ...
                'Every optimizer algorithm must be offered.');
            expOpt = cellstr(LvdOptimizerAlgoEnum.getListBoxStr());
            testCase.verifyEqual(sort(optItems(:)), sort(expOpt(:)));

            gradItems = cellstr(handles.gradientSelCombo.String);
            testCase.verifyEqual(numel(gradItems), numel(enumeration('LvdOptimizerGradientCalculationAlgoEnum')), ...
                'Every gradient algorithm must be offered.');
            expGrad = cellstr(LvdOptimizerGradientCalculationAlgoEnum.getListBoxStr());
            testCase.verifyEqual(sort(gradItems(:)), sort(expGrad(:)));
        end

        function changingSelectionAndSavingWritesModel(testCase)
            lvdData = testCase.lvdFixture();
            lvdData.optimizer.optAlgo = LvdOptimizerAlgoEnum.Fmincon;
            lvdData.optimizer.gradAlgo = LvdOptimizerGradientCalculationAlgoEnum.BuiltIn;
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_OptimizerSelectionGUI;

            handles.optimizerSelectionCombo.Value = ...
                LvdOptimizerAlgoEnum.getIndForName(LvdOptimizerAlgoEnum.Nomad.name);
            handles.gradientSelCombo.Value = ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.DerivEst.name);
            testCase.pushButton(app.saveAndCloseButton);

            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the dialog.');
            testCase.verifyEqual(lvdData.optimizer.optAlgo, LvdOptimizerAlgoEnum.Nomad, ...
                'Save must write the optimizer selection into lvdData.optimizer.optAlgo.');
            testCase.verifyEqual(lvdData.optimizer.gradAlgo, ...
                LvdOptimizerGradientCalculationAlgoEnum.DerivEst, ...
                'Save must write the gradient selection into lvdData.optimizer.gradAlgo.');
        end

        function nonGradientOptimizerDisablesGradientControls(testCase)
            lvdData = testCase.lvdFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            % NOMAD does not use gradients (reqGrad == false).
            testCase.choose(app.optimizerSelectionCombo, ...
                LvdOptimizerAlgoEnum.getIndForName(LvdOptimizerAlgoEnum.Nomad.name));

            testCase.verifyEqual(get(handles.gradientSelCombo, 'Enable'), 'off', ...
                'A non-gradient optimizer must disable the gradient combo.');
            testCase.verifyEqual(get(handles.editSelectedGradAlgoOptions, 'Enable'), 'off', ...
                'A non-gradient optimizer must disable the gradient options button.');

            testCase.choose(app.optimizerSelectionCombo, ...
                LvdOptimizerAlgoEnum.getIndForName(LvdOptimizerAlgoEnum.Fmincon.name));

            testCase.verifyEqual(get(handles.gradientSelCombo, 'Enable'), 'on', ...
                'A gradient optimizer must re-enable the gradient combo.');
        end

        function gradOptionsButtonFollowsDisableOptions(testCase)
            lvdData = testCase.lvdFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            % Only the FiniteDifferences gradient method offers options.
            testCase.choose(app.gradientSelCombo, ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences.name));
            testCase.verifyEqual(get(handles.editSelectedGradAlgoOptions, 'Enable'), 'on');

            testCase.choose(app.gradientSelCombo, ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.BuiltIn.name));
            testCase.verifyEqual(get(handles.editSelectedGradAlgoOptions, 'Enable'), 'off', ...
                'The built-in gradient method exposes no options dialog.');
        end

        function optimizerOptionsButtonOpensSelectedDialog(testCase)
            lvdData = testCase.lvdFixture();
            before = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Fmincon).getOptions().maxIter;
            app = testCase.openDialog(lvdData);

            seen = containers.Map();
            testCase.fixture.whenShown('Edit FMINCON Options', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.editSelectedOptimizerOptionsButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit FMINCON Options'), ...
                'The options button must open the selected optimizer''s dialog.');
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            testCase.verifyTrue(isvalid(handles.lvd_OptimizerSelectionGUI), ...
                'Dismissing the nested dialog must leave the selection dialog open.');
            after = lvdData.optimizer.getOptimizerForEnum(LvdOptimizerAlgoEnum.Fmincon).getOptions().maxIter;
            testCase.verifyEqual(after, before, 'A no-edit dismiss must leave the options alone.');
        end

        function gradOptionsButtonOpensFiniteDiffDialog(testCase)
            lvdData = testCase.lvdFixture();
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);

            testCase.choose(app.gradientSelCombo, ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.FiniteDifferences.name));

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Finite Differences Options', @(fig) recordAndPush(fig, seen, 'Save & Close'));
            testCase.pushButton(app.editSelectedGradAlgoOptions);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Finite Differences Options'), ...
                'The gradient options button must open the finite-differences dialog.');
        end

        function closeWithoutSavingPreservesModel(testCase)
            lvdData = testCase.lvdFixture();
            lvdData.optimizer.optAlgo = LvdOptimizerAlgoEnum.Fmincon;
            lvdData.optimizer.gradAlgo = LvdOptimizerGradientCalculationAlgoEnum.BuiltIn;
            app = testCase.openDialog(lvdData);
            [~, ~, handles] = convertToGUIDECallbackArguments(app);
            fig = handles.lvd_OptimizerSelectionGUI;

            handles.optimizerSelectionCombo.Value = ...
                LvdOptimizerAlgoEnum.getIndForName(LvdOptimizerAlgoEnum.Surrogate.name);
            handles.gradientSelCombo.Value = ...
                LvdOptimizerGradientCalculationAlgoEnum.getIndForName( ...
                    LvdOptimizerGradientCalculationAlgoEnum.DerivEst.name);
            close(fig);
            drawnow;

            testCase.verifyFalse(isvalid(fig), 'Close must close the dialog.');
            testCase.verifyEqual(lvdData.optimizer.optAlgo, LvdOptimizerAlgoEnum.Fmincon, ...
                'Closing without saving must leave optAlgo alone.');
            testCase.verifyEqual(lvdData.optimizer.gradAlgo, ...
                LvdOptimizerGradientCalculationAlgoEnum.BuiltIn, ...
                'Closing without saving must leave gradAlgo alone.');
        end
    end

    methods(Access=private)
        function lvdData = lvdFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
        end

        function app = openDialog(testCase, lvdData)
            % The selection dialog takes only lvdData (no output arg).
            app = lvd_OptimizerSelectionGUI_App(lvdData);
            drawnow;
            testCase.assertTrue(~isempty(app), 'The dialog constructor returned nothing.');
            testCase.addTeardown(@() OptimizerSelectionDialogTest.deleteIfValid(app));
        end

        function pushButton(~, btn)
            evt = struct('Source', btn, 'EventName', 'ButtonPushed');
            btn.ButtonPushedFcn(btn, evt);
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
                if isvalid(figs(i)) && strcmp(figs(i).Name, 'Optimizer Algorithm Selection')
                    try %#ok<TRYNC>
                        close(figs(i));
                    end
                end
            end
        end
    end
end

function recordAndPush(fig, seen, buttonText)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, buttonText);
end
