classdef MonteCarloGuiTest < KsptotTestCase
    %MonteCarloGuiTest The Monte Carlo dispersion window (G2).
    %
    % Covers lvd_runMonteCarlo_App with the window hidden: the available
    % list offers the dispersion groups only (never constraint bounds),
    % adding/removing dispersions and responses drives the tables, an empty
    % setup refuses to run with a message, and a 3-sample serial run
    % completes and writes the setup back onto the mission.
    %
    % Fixture: the default mission on a 0.2-eccentricity orbit with one
    % 600 s two-body event, as in SweepResponseTest.

    methods(Test)
        function availableParametersExcludeConstraintBounds(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            items = app.AvailableParamListbox.Items;

            testCase.verifyNotEmpty(items, 'The default mission must offer something to disperse');
            testCase.verifyTrue(any(startsWith(items, 'Vehicle Knobs |')), ...
                'Vehicle knobs must be dispersible');
            testCase.verifyFalse(any(startsWith(items, 'Constraint Bounds |')), ...
                'Constraint bounds are meaningless propagate-only and must not be offered');
        end

        function addingAParameterDefaultsToAUniformDispersion(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();

            data = app.DispTable.Data;
            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data{1, 2}, 'Uniform');
        end

        function addingTheSameParameterTwiceKeepsOneRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addFirstAvailableParameter();

            testCase.verifyEqual(height(app.DispTable.Data), 1, ...
                'Dispersing one target twice would write it twice per case');
        end

        function doubleClickingAParameterAddsItLikeTheAddButton(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.AvailableParamListbox.Value = app.AvailableParamListbox.ItemsData(1);
            app.AvailableParamListbox.DoubleClickedFcn(app.AvailableParamListbox, []);

            testCase.verifyEqual(height(app.DispTable.Data), 1);
        end

        function removingAParameterClearsItsRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.DispTable.Selection = [1 1];
            app.RemoveParamButton.ButtonPushedFcn(app.RemoveParamButton, []);

            testCase.verifyEqual(height(app.DispTable.Data), 0);
        end

        function addingAResponseByTaskNameAddsARow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addResponseByTaskStr('Altitude');

            testCase.verifyEqual(height(app.RespTable.Data), 1);
            testCase.verifyTrue(contains(app.RespTable.Data{1, 1}, 'Altitude'));
        end

        function doubleClickingAResponseAddsItLikeTheAddButton(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.RespTaskListbox.Value = {'Altitude'};
            app.RespTaskListbox.DoubleClickedFcn(app.RespTaskListbox, []);

            testCase.verifyEqual(height(app.RespTable.Data), 1);
        end

        function switchingToOptimizeForcesPersistOnAndLocked(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.RunModeDropdown.Value = 'Optimize Each Case';
            app.RunModeDropdown.ValueChangedFcn(app.RunModeDropdown, []);

            testCase.verifyEqual(app.getSetup().runMode, LvdCaseMatrixRunModeEnum.Optimize);
            testCase.verifyTrue(app.getSetup().persistCaseFiles, ...
                'Optimize mode cannot run without its per-case files');
            testCase.verifyTrue(app.PersistCaseFilesCheckbox.Value);
            testCase.verifyEqual(string(app.PersistCaseFilesCheckbox.Enable), "off");

            app.RunModeDropdown.Value = 'Propagate Only (No Optimization)';
            app.RunModeDropdown.ValueChangedFcn(app.RunModeDropdown, []);

            testCase.verifyEqual(app.getSetup().runMode, LvdCaseMatrixRunModeEnum.PropagateOnly);
            testCase.verifyEqual(string(app.PersistCaseFilesCheckbox.Enable), "on");
        end

        function attemptsEditWritesSetupAndRejectsGarbage(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.MaxRunAttemptsText.Value = '4';
            app.MaxRunAttemptsText.ValueChangedFcn(app.MaxRunAttemptsText, []);

            testCase.verifyEqual(app.getSetup().maxNumAttempts, 4);

            app.MaxRunAttemptsText.Value = 'banana';
            app.MaxRunAttemptsText.ValueChangedFcn(app.MaxRunAttemptsText, []);

            testCase.verifyEqual(app.getSetup().maxNumAttempts, 4, ...
                'Garbage input must leave the setup untouched');
            testCase.verifyEqual(str2double(app.MaxRunAttemptsText.Value), 4, ...
                'Garbage input must be replaced by the stored value');
        end

        function progressMessageWithUnknownTaskIdIsIgnored(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            before = app.RunStatusTable.Data;
            app.onProgressMessage(struct('taskId', -1, 'iter', 3, 'fval', 1.5, 'viol', 0.1, 'optim', NaN));

            testCase.verifyEqual(app.RunStatusTable.Data, before, ...
                'A late message for a gone case must not touch the table');
        end

        function progressMessageUpdatesTheRightRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.runHeadless(outDir);

            data = app.RunStatusTable.Data;
            nP = app.getSetup().getNumParameters();
            testCase.assertEqual(size(data, 1), 2, 'Fixture broken: expected two status rows');

            ids = app.getTaskIds();
            testCase.assertEqual(numel(ids), 2, 'Fixture broken: expected two task ids');

            row2Before = data(2, :);

            app.onProgressMessage(struct('taskId', ids(1), 'iter', 7, 'fval', 1.5, 'viol', 0.02, 'optim', 1e-4));

            data = app.RunStatusTable.Data;
            testCase.verifyEqual(data{1, 2+nP}, 7);
            testCase.verifyEqual(data{1, 3+nP}, 1.5, 'RelTol', 1e-12);
            testCase.verifyEqual(data{1, 4+nP}, 0.02, 'RelTol', 1e-12);
            testCase.verifyEqual(data{1, 5+nP}, '0.0001');
            testCase.verifyEqual(data(2, :), row2Before, ...
                'Only the addressed row may change');

            app.onProgressMessage(struct('taskId', ids(1), 'iter', 8, 'fval', 1.4, 'viol', 0.01, 'optim', NaN));
            data = app.RunStatusTable.Data;
            testCase.verifyEqual(data{1, 5+nP}, '', ...
                'A missing optimality reads blank, not NaN');
        end

        function optimizeButtonRunsCasesWithLiveColumns(testCase)
            testCase.assumeFalse(isempty(gcp('nocreate')), ...
                'Optimize mode needs a parallel pool, which this session does not have');

            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);
            app.ConfirmOptimizeRuns = false;

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            app.RunModeDropdown.Value = 'Optimize Each Case';
            app.RunModeDropdown.ValueChangedFcn(app.RunModeDropdown, []);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.RunLocationSelector.Value = outDir;

            app.RunButton.ButtonPushedFcn(app.RunButton, []);

            testCase.verifyTrue(contains(app.StatusLabel.Text, 'Run finished'), ...
                sprintf('The run did not finish cleanly: %s', app.StatusLabel.Text));
            testCase.verifyEqual(string(app.OpenResultsButton.Enable), "on");

            data = app.RunStatusTable.Data;
            nP = app.getSetup().getNumParameters();
            iters = cell2mat(data(:, 2+nP));
            testCase.verifyTrue(all(isfinite(iters)), ...
                'Every case must report iterations');

            exits = data(:, 5+nP+1);
            testCase.verifyTrue(all(ismember(exits, {'Converged', 'Limit'})), ...
                'Every finished case must carry an exit tag');
        end

        function editsSurviveCloseWithoutARun(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.SamplingDropdown.Value = 'Random';
            app.SamplingDropdown.ValueChangedFcn(app.SamplingDropdown, []);
            app.RandomSeedCheckbox.Value = true;
            app.RandomSeedCheckbox.ValueChangedFcn(app.RandomSeedCheckbox, []);

            delete(app.UIFigure);
            clear app;

            app2 = testCase.hiddenWindow(fx.lvdData);
            testCase.verifyEqual(app2.getSetup().samplingMode, LvdSweepSamplingEnum.Random, ...
                'Setup edits must reach the mission on close, not only on Run');
            testCase.verifyTrue(app2.getSetup().randomizeSeedEachRun);
            testCase.verifyTrue(app2.RandomSeedCheckbox.Value);
            testCase.verifyEqual(string(app2.SeedText.Enable), "off");
        end

        function randomFlagDrawsAFreshSeedAtRunStart(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            app.SeedText.Value = '42';
            app.SeedText.ValueChangedFcn(app.SeedText, []);
            app.RandomSeedCheckbox.Value = true;
            app.RandomSeedCheckbox.ValueChangedFcn(app.RandomSeedCheckbox, []);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.RunLocationSelector.Value = outDir;

            app.RunButton.ButtonPushedFcn(app.RunButton, []);

            testCase.verifyTrue(contains(app.StatusLabel.Text, 'Run finished'), ...
                sprintf('The run did not finish cleanly: %s', app.StatusLabel.Text));
            testCase.verifyNotEqual(app.getSetup().seed, 42, ...
                'A randomized run must not use the field seed');

            resFile = fullfile(outDir, 'MonteCarlo_results.mat');
            testCase.assertTrue(isfile(resFile), 'Fixture broken: the results .mat was not written');
            s = load(resFile, 'sweepResults');
            testCase.verifyEqual(s.sweepResults.seed, app.getSetup().seed, ...
                'The drawn seed must be recorded in the results');
        end

        function storedRunsAccumulateWithUniqueNames(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            results = app.runHeadless(outDir);

            app.storeCurrentResults();
            app.storeCurrentResults();

            stored = fx.lvdData.monteCarloResults;
            testCase.verifyEqual(numel(stored), 2);
            testCase.verifyEqual(stored(1).runName, results.runName);
            testCase.verifyEqual(stored(2).runName, sprintf('%s (2)', results.runName), ...
                'Repeated stores must not merge');
            testCase.verifyEqual(stored(1).inputs, results.inputs, ...
                'The stored copy must match the run');

            data = app.StoredRunsTable.Data;
            testCase.verifyEqual(size(data), [2 4]);
            testCase.verifyEqual(data{2, 1}, stored(2).runName);
            testCase.verifyEqual(data{2, 3}, stored(2).getNumCases());

            %The stored copy is independent of later runs.
            app.setNumSamples(3);
            app.runHeadless(outDir);
            testCase.verifyEqual(fx.lvdData.monteCarloResults(1).getNumCases(), 2, ...
                'Re-running must not rewrite stored runs');
        end

        function deletingStoredRunsDropsRows(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.runHeadless(outDir);
            app.storeCurrentResults();

            testCase.assertEqual(numel(fx.lvdData.monteCarloResults), 1);

            app.StoredRunsTable.Selection = [1 1];
            app.DeleteStoredButton.ButtonPushedFcn(app.DeleteStoredButton, []);

            testCase.verifyEmpty(fx.lvdData.monteCarloResults);
            testCase.verifyEqual(height(app.StoredRunsTable.Data), 0);
        end

        function storedRunsSurviveMissionSaveLoad(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            results = app.runHeadless(outDir);
            app.storeCurrentResults();

            misFile = fullfile(outDir, 'missionRt.mat');
            lvdData = fx.lvdData;
            save(misFile, 'lvdData');
            clear lvdData;
            s = load(misFile, 'lvdData');

            testCase.verifyEqual(numel(s.lvdData.monteCarloResults), 1);
            testCase.verifyEqual(s.lvdData.monteCarloResults(1).inputs, results.inputs, ...
                'Inputs must survive the round trip');
            testCase.verifyEqual(s.lvdData.monteCarloResults(1).outputs, results.outputs, ...
                'Outputs must survive the round trip');
        end

        function caseFilesShedStoredRunsButTemplateKeepsThem(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);
            app.getSetup().persistCaseFiles = true;

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            %First run populates LastResults; storing files it on the
            %template, so the second run's cases clone a mission that
            %carries stored results -- exactly what must not leak into
            %per-case files.
            app.runHeadless(outDir);
            app.storeCurrentResults();
            testCase.assertEqual(numel(fx.lvdData.monteCarloResults), 1);

            app.runHeadless(outDir);

            caseFile = fullfile(outDir, 'Case_1.mat');
            testCase.assertTrue(isfile(caseFile), 'Fixture broken: no case file written');
            c = load(caseFile, 'lvdData');
            testCase.verifyEmpty(c.lvdData.monteCarloResults, ...
                'Case-bound clones must shed stored results');
            testCase.verifyEqual(numel(fx.lvdData.monteCarloResults), 1, ...
                'The template must keep its stored runs');
        end

        function runNameFieldNamesTheRunAndItsFiles(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            app.RunNameText.Value = 'DryMassSweep';
            app.RunNameText.ValueChangedFcn(app.RunNameText, []);

            testCase.verifyEqual(app.getSetup().runName, 'DryMassSweep');

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            results = app.runHeadless(outDir);

            testCase.verifyEqual(results.runName, 'DryMassSweep');
            testCase.verifyTrue(isfile(fullfile(outDir, 'DryMassSweep_results.mat')), ...
                'Output files must carry the run name');

            app.RunNameText.Value = '   ';
            app.RunNameText.ValueChangedFcn(app.RunNameText, []);

            testCase.verifyEqual(app.getSetup().runName, 'DryMassSweep', ...
                'A blank name must revert instead of sticking');
        end

        function storedRenameKeepsNamesUnique(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.runHeadless(outDir);

            app.storeCurrentResults();
            app.storeCurrentResults();
            testCase.assertEqual(numel(fx.lvdData.monteCarloResults), 2);

            evt = struct('Indices', [2 1], 'NewData', 'Renamed', 'PreviousData', '');
            app.StoredRunsTable.CellEditCallback(app.StoredRunsTable, evt);

            testCase.verifyEqual(fx.lvdData.monteCarloResults(2).runName, 'Renamed');
            testCase.verifyEqual(app.StoredRunsTable.Data{2, 1}, 'Renamed');

            evt = struct('Indices', [2 1], 'NewData', fx.lvdData.monteCarloResults(1).runName, 'PreviousData', 'Renamed');
            app.StoredRunsTable.CellEditCallback(app.StoredRunsTable, evt);

            names = {fx.lvdData.monteCarloResults.runName};
            testCase.verifyEqual(numel(unique(names)), 2, ...
                'Renaming onto a taken name must suffix, not merge');
            testCase.verifyEqual(app.StoredRunsTable.Data{2, 1}, names{2}, ...
                'The table must show the stored name');
        end

        function storeButtonWiresToStore(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.RunLocationSelector.Value = outDir;
            app.RunButton.ButtonPushedFcn(app.RunButton, []);
            testCase.assertTrue(contains(app.StatusLabel.Text, 'Run finished'), ...
                'Fixture broken: the run did not finish');

            app.StoreResultsButton.ButtonPushedFcn(app.StoreResultsButton, []);

            testCase.verifyEqual(numel(fx.lvdData.monteCarloResults), 1);
            testCase.verifyEqual(height(app.StoredRunsTable.Data), 1);
        end

        function dispTableDistEditWritesThrough(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();

            evt = struct('Indices', [1 3], 'NewData', '7.5', 'PreviousData', '');
            app.DispTable.CellEditCallback(app.DispTable, evt);

            v = app.getSetup().variations(1).dist.getParamValues();
            testCase.verifyEqual(v(1), 7.5, 'RelTol', 1e-12, ...
                'Editing column A must rewrite the distribution parameter');
            testCase.verifyEqual(app.DispTable.Data{1, 3}, fullAccNum2Str(7.5), ...
                'The table must show the edited value');
        end

        function setupRunNameDefaultsAreSensible(testCase)
            testCase.verifyEqual(LvdSweepSetup().runName, 'Sweep', ...
                'Plain setups keep the historical Case Matrix name');
            testCase.verifyEqual(LvdSweepSetup.getDefaultMonteCarloSetup().runName, 'MonteCarlo', ...
                'Dispersion setups default to the Monte Carlo name');
        end

        function storedOpenWiringShowsTheViewer(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.runHeadless(outDir);
            app.storeCurrentResults();

            figsBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeFigsExcept(figsBefore));

            app.StoredRunsTable.Selection = [1 1];
            app.OpenStoredButton.ButtonPushedFcn(app.OpenStoredButton, []);

            figsNow = findall(groot, 'Type', 'figure');
            testCase.verifyEqual(numel(figsNow), numel(figsBefore) + 1, ...
                'Opening a stored run must show exactly one results window');
        end

        function storedNamesDefaultAndDeletesTolerateGarbage(testCase)
            fx = testCase.twoBodyFixture();

            r = LvdSweepResults();
            r.runName = '   ';
            fx.lvdData.storeMonteCarloResults(r);

            testCase.verifyEqual(fx.lvdData.monteCarloResults(1).runName, 'MonteCarlo', ...
                'A blank run name must fall back instead of storing blank');

            fx.lvdData.deleteMonteCarloResultsAtInd([99, -1, 1]);

            testCase.verifyEmpty(fx.lvdData.monteCarloResults, ...
                'Out-of-range indices must be ignored, valid ones removed');
        end

        function anEmptySetupRefusesToRunWithAMessage(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            testCase.verifyError(@() app.runHeadless(outDir), 'lvd_runMonteCarlo_App:invalidSetup', ...
                'A run with nothing dispersed must fail with the setup message, not a crash');
        end

        function threeSamplesRunSeriallyAndWriteTheSetupBack(testCase)
            testCase.assumeEmpty(gcp('nocreate'), ...
                'A parallel pool is open in this session, so the no-pool path cannot be exercised');

            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(3);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            results = app.runHeadless(outDir);

            testCase.verifyEqual(results.getNumCases(), 3);
            testCase.verifyEqual(width(results.outputs), 1);
            testCase.verifyTrue(all(isfinite(results.outputs)), ...
                sprintf('Not every sample completed: %s', strjoin(results.messages, ' | ')));

            testCase.verifyEqual(fx.lvdData.monteCarloSetup.getNumParameters(), 1, ...
                'Running must write the definition back so it survives save/load');
            testCase.verifyEqual(fx.lvdData.monteCarloSetup.numSamples, 3);
        end

        function opensOnAMissionWithAGeometricReferenceFrame(testCase)
            %Regression: referenceFrameSelectComp.initializeWithFrames
            %assigned refFrames(1) raw onto a UserDefinedGeometricFrame
            %property, so any mission with a CoordSysPointRefFrame (or any
            %other AbstractGeometricRefFrame) crashed the window on open.
            %The first non-vehicle-dependent geometric frame is now wrapped
            %in a UserDefinedGeometricFrame instead.
            fx = testCase.twoBodyFixture();
            testCase.addGeometricRefFrame(fx.lvdData);

            app = testCase.hiddenWindow(fx.lvdData);

            testCase.verifyNotEmpty(app.AvailableParamListbox.Items);
        end

        function pressingRunRunsTheDispersionThroughTheButton(testCase)
            %End-to-end through runButtonPushed (not the runHeadless seam):
            %covers the timer, the run-start accessors and the results
            %hand-off to Open Results.
            testCase.assumeEmpty(gcp('nocreate'), ...
                'A parallel pool is open in this session, so the no-pool path cannot be exercised');

            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();
            app.addResponseByTaskStr('Altitude');
            app.setNumSamples(2);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            app.RunLocationSelector.Value = outDir;
            app.RunButton.ButtonPushedFcn(app.RunButton, []);

            testCase.verifyEqual(height(app.RunStatusTable.Data), 2);
            testCase.verifyTrue(contains(app.StatusLabel.Text, 'Run finished'), ...
                sprintf('The run did not finish cleanly: %s', app.StatusLabel.Text));
            testCase.verifyEqual(string(app.OpenResultsButton.Enable), "on");
        end

        function cancellingOutLeavesTheMissionSetupUntouched(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.addFirstAvailableParameter();

            testCase.verifyEqual(fx.lvdData.monteCarloSetup.getNumParameters(), 0, ...
                'Editing the window must not touch the mission until a run writes it back');
        end
    end

    methods(Access=private)
        function app = hiddenWindow(testCase, lvdData)
            app = lvd_runMonteCarlo_App(lvdData, [], false);
            testCase.addTeardown(@() delete(app));
        end

        function closeFigsExcept(~, figsBefore)
            %closeFigsExcept Closes figures opened since (results viewers).
            figsNow = findall(groot, 'Type', 'figure');
            for(i=1:numel(figsNow))
                if(not(any(figsNow(i) == figsBefore)))
                    try
                        delete(figsNow(i));
                    catch
                    end
                end
            end
        end

        function fx = twoBodyFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, 900, 0.2, ...
                0, 0, 0, pi/2, testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(600);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            fx = struct('lvdData', lvdData);
        end

        function addGeometricRefFrame(testCase, lvdData)
            o = [300; 400; 500];
            origin = FixedPointInFrame(o, testCase.kerbinFrame, 'origin', lvdData);
            primary = FixedPointInFrame(o + [0; 0; 7], testCase.kerbinFrame, 'primary', lvdData);
            planePt = FixedPointInFrame(o + [0; 2; 1], testCase.kerbinFrame, 'plane', lvdData);

            cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
            lvdData.geometry.refFrames.addRefFrame(CoordSysPointRefFrame(cs, origin, 'rf', lvdData));
        end
    end
end
