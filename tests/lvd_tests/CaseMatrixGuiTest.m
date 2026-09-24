classdef CaseMatrixGuiTest < KsptotTestCase
    %CaseMatrixGuiTest The rebuilt Case Matrix window (G1).
    %
    % Covers the canvasized lvd_runCaseMatrix_App: it opens on a mission
    % with no plugin variables (the old hard gate is gone), adding a
    % parameter and a response drives the tables and the case-count label,
    % the variation dropdown rewrites the row, duplicates are ignored,
    % removal clears the row, and Open Results stays disabled until a run
    % produces results.
    %
    % The app is modal, so it is constructed visible and hidden again
    % straight away; every interaction below goes through the components'
    % own callbacks.  Each test deletes the app in teardown: the class is
    % a singleton while an instance is alive, and a live instance locks
    % the .mlapp file.
    %
    % Fixture: the default mission on a 0.2-eccentricity orbit with one
    % 600 s two-body event.  Nothing is propagated and nothing runs.

    methods(Test)
        function opensWithoutPluginVariablesAndListsVehicleKnobs(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.verifyTrue(isvalid(app.RunCaseMatrixUIFigure), ...
                'The window must open on a mission with no plugin variables');
            testCase.verifyNotEmpty(app.AvailableParamListbox.Items);
            testCase.verifyTrue(any(startsWith(app.AvailableParamListbox.Items, 'Vehicle Knobs |')), ...
                'Vehicle knobs must be sweepable with no plugin wiring');
            testCase.verifyEqual(numel(app.CaseMatrixTabs.Children), 5, ...
                'Parameters, Sampling and Run, Responses, Output, Status');
        end

        function addingAParameterAddsAGridRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);

            data = app.SelectedParamTable.Data;
            testCase.verifyEqual(height(data), 1);
            testCase.verifyEqual(data{1, 3}, 'Grid');
        end

        function doubleClickingAParameterAddsItLikeTheAddButton(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.AvailableParamListbox.Value = app.AvailableParamListbox.ItemsData(1);
            app.AvailableParamListbox.DoubleClickedFcn(app.AvailableParamListbox, []);

            testCase.verifyEqual(height(app.SelectedParamTable.Data), 1);
        end

        function addingTheSameParameterTwiceKeepsOneRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);
            testCase.pressAddFirst(app);

            testCase.verifyEqual(height(app.SelectedParamTable.Data), 1, ...
                'Sweeping one target twice would write it twice per case');
        end

        function variationDropdownRewritesTheSelectedRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);

            app.VariationTypeDropdown.Value = 'Normal';
            app.VariationTypeDropdown.ValueChangedFcn(app.VariationTypeDropdown, []);

            testCase.verifyEqual(app.SelectedParamTable.Data{1, 3}, 'Normal');
            testCase.verifyEqual(str2double(app.SelectedParamTable.Data{1, 4}), 2.0, 'RelTol', 1e-9, ...
                'A fresh Normal dispersion is centered on the parameter''s current value (2 mT dry mass)');
        end

        function removingAParameterClearsItsRow(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);
            app.SelectedParamTable.Selection = [1 1];
            app.RemoveParamButton.ButtonPushedFcn(app.RemoveParamButton, []);

            testCase.verifyEqual(height(app.SelectedParamTable.Data), 0);
        end

        function addingAResponseDrivesTheTableAndTheCaseCount(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);
            app.RespTaskListbox.Value = {'Altitude'};
            app.AddRespButton.ButtonPushedFcn(app.AddRespButton, []);

            testCase.verifyEqual(height(app.SelectedRespTable.Data), 1);
            testCase.verifyTrue(contains(app.SelectedRespTable.Data{1, 1}, 'Altitude'));
            testCase.verifyTrue(contains(app.NumCasesLabel.Text, '1 response'), ...
                'The case-count label must count responses as well as cases');
        end

        function doubleClickingAResponseAddsItLikeTheAddButton(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.RespTaskListbox.Value = {'Altitude'};
            app.RespTaskListbox.DoubleClickedFcn(app.RespTaskListbox, []);

            testCase.verifyEqual(height(app.SelectedRespTable.Data), 1);
        end

        function gridCellEditRewritesBoundsAndRefreshes(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.pressAddFirst(app);

            evt = struct('Indices', [1 4], 'NewData', '1.5', 'PreviousData', '');
            app.SelectedParamTable.CellEditCallback(app.SelectedParamTable, evt);

            testCase.verifyEqual(app.SelectedParamTable.Data{1, 3}, 'Grid');
            testCase.verifyEqual(app.SelectedParamTable.Data{1, 4}, fullAccNum2Str(1.5), ...
                'Editing column A must rewrite the lower bound and refresh');
            testCase.verifyTrue(contains(app.NumCasesLabel.Text, 'case(s) will run'), ...
                'The case count must refresh after the edit');
        end

        function pressingRunInPropagateOnlyModeRunsEveryCase(testCase)
            %End-to-end through RunCaseMatrixButtonPushed: covers the pool
            %start fallback, runCaseMatrix, the status table and Open
            %Results.  The figure stays visible so the pool-fallback alert
            %has a parent; one worker keeps parpool cheap on any machine.
            %Teardown deletes a started pool and any stray figures (alerts).
            fx = testCase.twoBodyFixture();

            figsBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeFigsExcept(figsBefore));

            app = lvd_runCaseMatrix_App(fx.lvdData);
            testCase.addTeardown(@() testCase.closeApp(app));

            testCase.pressAddFirst(app);
            app.RespTaskListbox.Value = {'Altitude'};
            app.AddRespButton.ButtonPushedFcn(app.AddRespButton, []);

            app.RunModeDropdown.Value = 'Propagate Only (No Optimization)';
            app.RunModeDropdown.ValueChangedFcn(app.RunModeDropdown, []);

            app.NumOfWorkersText.Value = '1';
            app.NumOfWorkersText.ValueChangedFcn(app.NumOfWorkersText, []);

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));
            app.RunLocationSelector.Value = outDir;

            app.RunCaseMatrixButton.ButtonPushedFcn(app.RunCaseMatrixButton, []);

            testCase.verifyEqual(height(app.RunStatusTable.Data), 5, ...
                'The default dry-mass grid has five levels');
            testCase.verifyTrue(contains(app.StatusLabel.Text, 'Run finished'), ...
                sprintf('The run did not finish cleanly: %s', app.StatusLabel.Text));
            testCase.verifyEqual(string(app.OpenResultsButton.Enable), "on");
            testCase.verifyTrue(isfile(fullfile(outDir, 'Sweep_results.xlsx')), ...
                'Output files must carry the setup run name');
        end

        function openResultsStaysDisabledUntilARunProducesResults(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.verifyEqual(string(app.OpenResultsButton.Enable), "off", ...
                'With no run yet there is nothing for the viewer to open');
        end

        function randomSeedCheckboxTogglesFieldAndEnables(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            app.SamplingModeDropdown.Value = 'Latin Hypercube';
            app.SamplingModeDropdown.ValueChangedFcn(app.SamplingModeDropdown, []);

            testCase.verifyFalse(app.RandomSeedCheckbox.Value, ...
                'Random-each-run defaults off');
            testCase.verifyEqual(string(app.SeedText.Enable), "on");

            app.RandomSeedCheckbox.Value = true;
            app.RandomSeedCheckbox.ValueChangedFcn(app.RandomSeedCheckbox, []);

            lvdData = fx.lvdData;
            testCase.verifyTrue(lvdData.caseMatrixSetup.randomizeSeedEachRun, ...
                'The Case Matrix edits the mission setup live');
            testCase.verifyEqual(string(app.SeedText.Enable), "off");
            testCase.verifyEqual(string(app.RandomizeSeedButton.Enable), "off");
        end

        function samplingAndRunModesOfferEveryEngineOption(testCase)
            fx = testCase.twoBodyFixture();
            app = testCase.hiddenWindow(fx.lvdData);

            testCase.verifyEqual(numel(app.SamplingModeDropdown.Items), 3, ...
                'Full Factorial, Latin Hypercube, Random');
            testCase.verifyEqual(numel(app.RunModeDropdown.Items), 2, ...
                'Optimize, Propagate Only');
            testCase.verifyEqual(numel(app.RespNodeDropdown.Items), 5, ...
                'Initial, Final, Minimum, Maximum, Mean');
            testCase.verifyTrue(numel(app.VariationTypeDropdown.Items) >= 4, ...
                'Grid plus the three distributions');
        end
    end

    methods(Access=private)
        function app = hiddenWindow(testCase, lvdData)
            %The app is modal and always builds visible; hide it at once so
            %the suite stays headless.
            app = lvd_runCaseMatrix_App(lvdData);
            app.RunCaseMatrixUIFigure.Visible = 'off';
            testCase.addTeardown(@() testCase.closeApp(app));
        end

        function pressAddFirst(~, app)
            app.AvailableParamListbox.Value = app.AvailableParamListbox.ItemsData(1);
            app.AddParamButton.ButtonPushedFcn(app.AddParamButton, []);
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
    end

    methods(Static, Access=private)
        function closeApp(app)
            try
                if(isvalid(app.RunCaseMatrixUIFigure))
                    delete(app);
                end
            catch
            end
            clear app;
        end

        function closeFigsExcept(figsBefore)
            %closeFigsExcept Closes figures opened since (pool-fallback
            %alerts), and any pool a run started so later tests see a
            %clean session.
            pp = gcp('nocreate');
            if(not(isempty(pp)))
                try
                    delete(pp);
                catch
                end
            end

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
    end
end
