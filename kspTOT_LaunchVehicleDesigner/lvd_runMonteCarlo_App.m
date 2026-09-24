classdef lvd_runMonteCarlo_App < matlab.apps.AppBase
    %lvd_runMonteCarlo_App Monte Carlo dispersion runner for LVD (G2).
    %   Programmatic App Designer (uifigure) window in the style of
    %   lvd_ViewPlaybackGUI_App.  Launched from the LVD main window as
    %
    %       lvd_runMonteCarlo_App(lvdData, mainApp);
    %
    %   Same sweep engine as the Case Matrix, dispersion-shaped: a table of
    %   parameters each with a distribution (Uniform/Normal/Triangular,
    %   defaulted around the parameter's current value), N, seed, workers, a
    %   response table, run/cancel/progress and Open Results.  Runs are always
    %   propagate-only and always sampled (Latin hypercube or random).
    %
    %   Dispersible groups are plugin variables, optimization-variable
    %   elements and vehicle knobs (LvdSweepParameterFactory.getDispersionGroups).
    %   Constraint bounds are NOT offered: a propagate-only case never
    %   evaluates constraints, so dispersing a bound is meaningless (they
    %   remain a G1 Case Matrix sweep parameter).  Wind (D1) is unbuilt and
    %   is not a source either.
    %
    %   The window edits a deep copy of lvdData.monteCarloSetup; pressing Run
    %   writes it back so the definition survives save/load.  Cancelling out
    %   leaves the mission untouched.
    %
    %   lvd_runMonteCarlo_App(lvdData, mainApp, false) builds the window
    %   hidden, which the unit tests use.  The public methods below the
    %   constructor are the test seam and never open a dialog.

    properties (Access = public)
        UIFigure
        MainGrid
        TitleLabel
        TabGroup

        DispTab
        DispGrid
        ParamSearchText
        AvailableParamListbox
        ParamButtonGrid
        AddParamButton
        RemoveParamButton
        DistTypeLabel
        DistTypeDropdown
        DispTable

        RunTab
        RunGrid
        SamplingLabel
        SamplingDropdown
        RunModeLabel
        RunModeDropdown
        NumSamplesLabel
        NumSamplesText
        SeedLabel
        SeedText
        RandomizeSeedButton
        RandomSeedCheckbox
        WorkersLabel
        NumWorkersText
        MaxAttemptsLabel
        MaxRunAttemptsText
        OutputLabel
        RunLocationSelector
        RunNameLabel
        RunNameText
        WriteXlsxCheckbox
        WriteMatCheckbox
        WriteCsvCheckbox
        PersistCaseFilesCheckbox
        NumCasesLabel

        RespTab
        RespGrid
        RespSearchText
        RespTaskListbox
        RespNodeDropdown
        RespEventDropdown
        RespFrameSelector
        RespButtonGrid
        AddRespButton
        RemoveRespButton
        RespTable

        StatusTab
        StatusGrid
        RunStatusTable
        StatusButtonGrid
        RunButton
        CancelButton
        OpenResultsButton
        StoreResultsButton

        StoredTab
        StoredGrid
        StoredRunsTable
        StoredButtonGrid
        OpenStoredButton
        DeleteStoredButton

        StatusLabel
        RunTimeCounterLabel
        SpinnerIcon

        %Test seam: the Run button asks for confirmation before an optimize
        %run.  Tests set this false so the run proceeds dialog-free.
        ConfirmOptimizeRuns(1,1) logical = true;
    end

    properties (Access = private)
        LastRunTic uint64 = uint64(0);
        LvdData
        MainApp
        Setup LvdSweepSetup
        AvailParams
        RespTaskStrs cell = {};
        CaseMatrix LvdCaseMatrix
        LastResults LvdSweepResults
    end

    methods (Access = public)
        function app = lvd_runMonteCarlo_App(varargin)
            createComponents(app);

            %Deliberately NOT registerApp (see lvd_ViewPlaybackGUI_App).
            %The destroy listener commits the setup first, so closing by
            %any path (window X, close(), figure deletion) keeps the
            %definitions -- not just the Run button.
            addlistener(app.UIFigure, 'ObjectBeingDestroyed', @(~,~) app.onCloseRequest());
            app.startupFcn(varargin{:});

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if(not(isempty(app.UIFigure)) && isvalid(app.UIFigure))
                delete(app.UIFigure);
            end
        end

        function onCloseRequest(app)
            %onCloseRequest Commits the edited definition to the mission so
            %it survives save/load even when no run happened, then closes.
            app.saveSetupToMission();
            delete(app);
        end

        function saveSetupToMission(app)
            %saveSetupToMission Writes the window's deep-copied setup back
            %onto the mission.  Called on close and after every run.
            try
                if(not(isempty(app.LvdData)) && isvalid(app.LvdData) && not(isempty(app.Setup)))
                    app.LvdData.monteCarloSetup = app.Setup.deepCopy();
                end
            catch
            end
        end

        function setup = getSetup(app)
            %getSetup The edited (deep-copied) setup (test seam).
            setup = app.Setup;
        end

        function ids = getTaskIds(app)
            %getTaskIds Ids of the current run's tasks, in table-row order
            %(empty when nothing has run).  Test seam for live-update tests.
            if(isempty(app.CaseMatrix) || isempty(app.CaseMatrix.tasks))
                ids = [];
            else
                ids = [app.CaseMatrix.tasks.id];
            end
        end

        function addFirstAvailableParameter(app)
            %addFirstAvailableParameter Adds the first listed parameter with
            %a default distribution (test seam).
            if(isempty(app.AvailParams))
                return;
            end
            inds = app.AvailableParamListbox.ItemsData;
            if(isempty(inds))
                return;
            end
            app.addParametersByAvailInds(inds(1));
        end

        function addResponseByTaskStr(app, taskStr)
            %addResponseByTaskStr Adds a FinalState whole-mission response for
            %the named GA task (test seam).
            frame = app.getSelectedResponseFrame();
            task = GraphicalAnalysisTask(taskStr, frame);
            app.Setup.addResponse(LvdSweepResponse(task, LvdSweepResponseNodeEnum.FinalState, 0));
            app.refreshRespTable();
        end

        function setNumSamples(app, n)
            app.Setup.numSamples = n;
            app.NumSamplesText.Value = fullAccNum2Str(n);
            app.refreshCaseCountLabel();
        end

        function results = runHeadless(app, outputDir)
            %runHeadless Validates, runs via the engine in the setup's own
            %run mode, writes the setup back and returns the results (test
            %seam).  Dialog-free: no confirm, no pool offer (Optimize mode
            %needs a pool and errors clearly without one).
            arguments
                app
                outputDir(1,:) char
            end
            app.Setup.outputLocation = outputDir;
            [ok, msg] = app.Setup.validate(app.LvdData);
            if(not(ok))
                error('lvd_runMonteCarlo_App:invalidSetup', '%s', msg);
            end
            cm = LvdCaseMatrix(app.LvdData, outputDir);
            cm.runName = app.Setup.runName;
            cm.createTasksFromSetup(app.Setup);
            cm.runAllTasks();
            app.CaseMatrix = cm;
            app.LastResults = cm.results;
            app.saveSetupToMission();
            results = cm.results;
            app.refreshStatusTable();
        end

        function openResults(app, ~, ~)
            if(isempty(app.LastResults))
                return;
            end
            lvd_SweepResultsGUI_App(app.LastResults);
        end

        function storeCurrentResults(app, ~, ~)
            %storeCurrentResults Files the last run onto the mission (unique
            %name, newest last) and refreshes the stored-runs table.  Public
            %as a test seam; the Store Results button calls it.
            if(isempty(app.LastResults))
                return;
            end
            app.LvdData.storeMonteCarloResults(app.LastResults);
            app.refreshStoredRunsTable();
        end

        function openStoredResults(app, ~, ~)
            sel = app.StoredRunsTable.Selection;
            if(isempty(sel))
                return;
            end
            r = min(sel(:,1));
            stored = app.LvdData.monteCarloResults;
            if(r < 1 || r > numel(stored))
                return;
            end
            lvd_SweepResultsGUI_App(stored(r));
        end

        function deleteStoredResults(app, ~, ~)
            sel = app.StoredRunsTable.Selection;
            if(isempty(sel))
                return;
            end
            app.LvdData.deleteMonteCarloResultsAtInd(unique(sel(:,1)));
            app.refreshStoredRunsTable();
        end

        function onStoredTableEdit(app, evt)
            %onStoredTableEdit Renames a stored run in place.  Uniqueness
            %is enforced against the other rows (not itself, so keeping a
            %name is a no-op); blanks revert.
            r = evt.Indices(1);
            c = evt.Indices(2);

            stored = app.LvdData.monteCarloResults;
            if(r < 1 || r > numel(stored) || c ~= 1)
                app.refreshStoredRunsTable();
                return;
            end

            newName = strtrim(attemptStrEval(evt.NewData));
            if(isempty(newName))
                app.refreshStoredRunsTable();
                return;
            end

            taken = {stored.runName};
            taken(r) = [];
            base = newName;
            k = 2;
            while(ismember(newName, taken))
                newName = sprintf('%s (%u)', base, k);
                k = k + 1;
            end

            stored(r).runName = newName;
            app.refreshStoredRunsTable();
        end

        function onProgressMessage(app, s)
            %onProgressMessage One live optimizer report: refreshes that
            %case's Iter/Objective/MaxViol/Optimality cells.  Runs on the
            %client via the run's DataQueue; guarded so a late message
            %after a rebuild cannot throw inside the queue callback.  Public
            %as a test seam (the pool-gated button test aside, tests drive
            %it directly against a finished propagate run's table).
            try
                if(isempty(app.CaseMatrix) || isempty(app.CaseMatrix.tasks))
                    return;
                end

                ids = [app.CaseMatrix.tasks.id];
                r = find(ids == s.taskId, 1, 'first');
                if(isempty(r))
                    return;
                end

                data = app.RunStatusTable.Data;
                if(r > size(data, 1))
                    return;
                end

                nP = app.Setup.getNumParameters();
                data{r, 2+nP} = s.iter;
                data{r, 3+nP} = s.fval;
                data{r, 4+nP} = s.viol;

                if(isnan(s.optim))
                    data{r, 5+nP} = '';
                else
                    data{r, 5+nP} = sprintf('%.3g', s.optim);
                end

                app.RunStatusTable.Data = data;
                drawnow('limitrate');
            catch
            end
        end
    end

    methods (Access = private)
        function startupFcn(app, lvdData, mainApp, showFigure)
            arguments
                app
                lvdData(1,1) LvdData
                mainApp = []
                showFigure(1,1) logical = true
            end

            app.LvdData = lvdData;
            app.MainApp = mainApp;
            app.Setup = lvdData.monteCarloSetup.deepCopy();
            app.Setup.runMode = LvdCaseMatrixRunModeEnum.PropagateOnly;

            app.AvailParams = LvdSweepParameterFactory.enumerate(lvdData, ...
                LvdSweepParameterFactory.getDispersionGroups());

            dists = AbstractLvdDistribution.getAllDistributionTypes();
            names = cell(1, numel(dists));
            for(i=1:numel(dists))
                names{i} = dists(i).getTypeName();
            end
            app.DistTypeDropdown.Items = names;

            app.SamplingDropdown.Items = {'Latin Hypercube', 'Random'};
            if(app.Setup.samplingMode == LvdSweepSamplingEnum.Random)
                app.SamplingDropdown.Value = 'Random';
            else
                app.SamplingDropdown.Value = 'Latin Hypercube';
            end

            app.RunModeDropdown.Items = LvdCaseMatrixRunModeEnum.getListBoxStr();
            app.RunModeDropdown.Value = app.Setup.runMode.name;

            app.RespNodeDropdown.Items = LvdSweepResponseNodeEnum.getListBoxStr();
            app.RespTaskStrs = lvd_getGraphAnalysisTaskList(lvdData, getLvdGAExcludeList());
            app.populateRespEventDropdown();
            app.RespFrameSelector.initializeWithFrames(lvdData);
            initBody = lvdData.initStateModel.centralBody;
            if(not(isempty(initBody)))
                app.RespFrameSelector.setSelectedFrame(initBody.getBodyCenteredInertialFrame());
            end

            app.refreshAvailableParamListbox();
            app.refreshDispTable();
            app.refreshRespTaskListbox();
            app.refreshRespTable();
            app.refreshStoredRunsTable();

            app.NumSamplesText.Value = fullAccNum2Str(app.Setup.numSamples);
            app.SeedText.Value = fullAccNum2Str(app.Setup.seed);
            app.RandomSeedCheckbox.Value = app.Setup.randomizeSeedEachRun;
            app.updateSeedEnables();

            if(isempty(app.Setup.outputLocation) || not(isfolder(app.Setup.outputLocation)))
                app.Setup.outputLocation = pwd;
            end
            app.RunLocationSelector.Value = app.Setup.outputLocation;

            app.RunNameText.Value = app.Setup.runName;

            pp = gcp('nocreate');
            if(app.Setup.numWorkers <= 1)
                if(not(isempty(pp)))
                    app.Setup.numWorkers = pp.NumWorkers;
                else
                    app.Setup.numWorkers = feature('numCores');
                end
            end
            app.NumWorkersText.Value = fullAccNum2Str(app.Setup.numWorkers);
            app.MaxRunAttemptsText.Value = fullAccNum2Str(app.Setup.maxNumAttempts);

            app.WriteXlsxCheckbox.Value = app.Setup.writeXlsx;
            app.WriteMatCheckbox.Value = app.Setup.writeMat;
            app.WriteCsvCheckbox.Value = app.Setup.writeCsv;
            app.PersistCaseFilesCheckbox.Value = app.Setup.persistCaseFiles;
            app.updatePersistForRunMode();

            app.refreshCaseCountLabel();

            app.SpinnerIcon.Visible = false;
            app.CancelButton.Visible = false;
            app.StatusLabel.Text = 'Ready';
            app.RunTimeCounterLabel.Text = '';
            app.RunTimeCounterLabel.Visible = false;
            app.OpenResultsButton.Enable = false;

            centerUIFigure(app.UIFigure);
            applySelectedThemeToApp(app);

            if(showFigure)
                app.UIFigure.Visible = 'on';
            end
        end

        function populateRespEventDropdown(app)
            numEvts = app.LvdData.script.getTotalNumOfEvents();
            items = cell(1, numEvts + 1);
            items{1} = 'Whole Mission';
            for(i=1:numEvts)
                items{i+1} = sprintf('Event %u: %s', i, app.LvdData.script.getEventForInd(i).name);
            end
            app.RespEventDropdown.Items = items;
            app.RespEventDropdown.ItemsData = 0:numEvts;
            app.RespEventDropdown.Value = 0;
        end

        function frame = getSelectedResponseFrame(app)
            %getSelectedResponseFrame The response frame from the standard
            %frame selector, as used everywhere else in LVD.
            frame = app.RespFrameSelector.getSelectedFrame();
        end

        function refreshAvailableParamListbox(app)
            filter = lower(strtrim(app.ParamSearchText.Value));
            [groupNames, indsByGroup] = LvdSweepParameterFactory.groupParameters(app.AvailParams);
            items = {};
            data = [];
            for(g=1:numel(groupNames))
                inds = indsByGroup{g};
                for(k=1:numel(inds))
                    label = sprintf('%s | %s', groupNames{g}, app.AvailParams(inds(k)).getFullLabel());
                    if(not(isempty(filter)) && not(contains(lower(label), filter)))
                        continue;
                    end
                    items{end+1} = label; %#ok<AGROW>
                    data(end+1) = inds(k); %#ok<AGROW>
                end
            end
            if(isempty(items))
                app.AvailableParamListbox.Items = {};
                app.AvailableParamListbox.ItemsData = [];
            else
                app.AvailableParamListbox.Items = items;
                app.AvailableParamListbox.ItemsData = data;
            end
        end

        function refreshDispTable(app)
            n = app.Setup.getNumParameters();
            data = cell(n, 5);
            for(i=1:n)
                param = app.Setup.params(i);
                variation = app.Setup.variations(i);
                data{i,1} = param.getFullLabel();
                if(isa(variation, 'LvdSweepDistVariation'))
                    data{i,2} = variation.dist.getTypeName();
                    v = variation.dist.getParamValues();
                else
                    data{i,2} = 'Grid';
                    v = [variation.lowerBnd, variation.upperBnd, variation.step];
                end
                for(k=1:3)
                    if(k <= numel(v))
                        data{i,2+k} = fullAccNum2Str(v(k));
                    else
                        data{i,2+k} = '';
                    end
                end
            end
            app.DispTable.Data = data;
            app.refreshCaseCountLabel();
        end

        function refreshRespTaskListbox(app)
            filter = lower(strtrim(app.RespSearchText.Value));
            items = app.RespTaskStrs;
            if(not(isempty(filter)))
                items = items(contains(lower(items), filter));
            end
            if(isempty(items))
                app.RespTaskListbox.Items = {};
            else
                app.RespTaskListbox.Items = items;
            end
        end

        function refreshRespTable(app)
            n = app.Setup.getNumResponses();
            data = cell(n, 1);
            for(i=1:n)
                data{i,1} = app.Setup.responses(i).getName();
            end
            app.RespTable.Data = data;
            app.refreshCaseCountLabel();
        end

        function refreshCaseCountLabel(app)
            numCases = app.Setup.getNumCases();
            app.NumCasesLabel.Text = sprintf('%u sample(s) will run, harvesting %u response(s) from each.', ...
                                             numCases, app.Setup.getNumResponses());
        end

        function refreshStoredRunsTable(app)
            %refreshStoredRunsTable Lists every run stored on the mission.
            stored = app.LvdData.monteCarloResults;
            n = numel(stored);

            data = cell(n, 4);
            for(i=1:n)
                data{i,1} = stored(i).runName;

                if(stored(i).timestamp > 0)
                    data{i,2} = datestr(stored(i).timestamp, 'yyyy-mm-dd HH:MM:SS'); %#ok<DATST>
                else
                    data{i,2} = '';
                end

                data{i,3} = stored(i).getNumCases();
                data{i,4} = stored(i).runMode.name;
            end

            app.StoredRunsTable.Data = data;
        end

        function refreshStatusTable(app)
            if(isempty(app.CaseMatrix) || isempty(app.CaseMatrix.tasks))
                return;
            end
            tableData = app.CaseMatrix.getUITableData();
            app.RunStatusTable.ColumnName = app.CaseMatrix.getStatusTableColumns();
            app.RunStatusTable.Data = tableData;
            app.OpenResultsButton.Enable = not(isempty(app.LastResults));
        end

        function addParametersByAvailInds(app, inds)
            for(k=1:numel(inds))
                if(inds(k) < 1 || inds(k) > numel(app.AvailParams))
                    continue;
                end
                param = app.AvailParams(inds(k));
                %Skip what is already dispersed: the same id twice would
                %write the same target twice per case.
                already = false;
                for(j=1:numel(app.Setup.params))
                    if(app.Setup.params(j) == param)
                        already = true;
                        break;
                    end
                end
                if(already)
                    continue;
                end
                dist = AbstractLvdDistribution.createByTypeName(app.DistTypeDropdown.Value, ...
                    param.getCurrentValue());
                app.Setup.addParameter(param, LvdSweepDistVariation(dist));
            end
            app.refreshDispTable();
        end

        function addParamButtonPushed(app, ~, ~)
            %Value is in ItemsData space: the indices into AvailParams.
            sel = app.AvailableParamListbox.Value;
            if(isempty(sel))
                return;
            end
            app.addParametersByAvailInds(sel(:)');
        end

        function removeParamButtonPushed(app, ~, ~)
            sel = app.DispTable.Selection;
            if(isempty(sel))
                return;
            end
            rows = unique(sel(:,1), 'sorted');
            for(k=numel(rows):-1:1)
                app.Setup.removeParameterAtInd(rows(k));
            end
            app.refreshDispTable();
        end

        function onDispTableEdit(app, evt)
            r = evt.Indices(1);
            c = evt.Indices(2);
            if(r < 1 || r > app.Setup.getNumParameters())
                return;
            end
            if(c >= 3 && c <= 5)
                variation = app.Setup.variations(r);
                if(not(isa(variation, 'LvdSweepDistVariation')))
                    app.refreshDispTable();
                    return;
                end
                v = variation.dist.getParamValues();
                newVal = str2double(attemptStrEval(evt.NewData));
                if(isnan(newVal))
                    app.refreshDispTable();
                    return;
                end
                if((c-2) <= numel(v))
                    v(c-2) = newVal;
                    try
                        variation.dist.setParamValues(v);
                    catch
                    end
                end
            end
            app.refreshDispTable();
        end

        function distTypeChanged(app, ~, ~)
            sel = app.DispTable.Selection;
            if(isempty(sel))
                return;
            end
            r = min(sel(:,1));
            if(r < 1 || r > app.Setup.getNumParameters())
                return;
            end
            param = app.Setup.params(r);
            dist = AbstractLvdDistribution.createByTypeName(app.DistTypeDropdown.Value, ...
                param.getCurrentValue());
            app.Setup.setVariationAtInd(r, LvdSweepDistVariation(dist));
            app.refreshDispTable();
        end

        function addRespButtonPushed(app, ~, ~)
            sel = app.RespTaskListbox.Value;
            if(isempty(sel))
                return;
            end
            [nodeEnum, ~] = LvdSweepResponseNodeEnum.getEnumForListboxStr(app.RespNodeDropdown.Value);
            eventNum = app.RespEventDropdown.Value;
            frame = app.getSelectedResponseFrame();
            for(k=1:numel(sel))
                task = GraphicalAnalysisTask(sel{k}, frame);
                app.Setup.addResponse(LvdSweepResponse(task, nodeEnum, eventNum));
            end
            app.refreshRespTable();
        end

        function removeRespButtonPushed(app, ~, ~)
            sel = app.RespTable.Selection;
            if(isempty(sel))
                return;
            end
            rows = unique(sel(:,1), 'sorted');
            for(k=numel(rows):-1:1)
                app.Setup.removeResponseAtInd(rows(k));
            end
            app.refreshRespTable();
        end

        function samplingChanged(app, ~, ~)
            if(strcmp(app.SamplingDropdown.Value, 'Random'))
                app.Setup.samplingMode = LvdSweepSamplingEnum.Random;
            else
                app.Setup.samplingMode = LvdSweepSamplingEnum.LatinHypercube;
            end
            app.refreshCaseCountLabel();
        end

        function runModeChanged(app, ~, ~)
            [enum, ~] = LvdCaseMatrixRunModeEnum.getEnumForListboxStr(app.RunModeDropdown.Value);
            app.Setup.runMode = enum;
            app.updatePersistForRunMode();
            app.refreshCaseCountLabel();
        end

        function updatePersistForRunMode(app)
            %updatePersistForRunMode Optimize mode cannot run without its
            %per-case files (the warm start and the retry path read them),
            %so the checkbox follows the mode: forced on and locked in
            %Optimize, free otherwise.
            optimizeMode = app.Setup.runMode == LvdCaseMatrixRunModeEnum.Optimize;

            if(optimizeMode)
                app.Setup.persistCaseFiles = true;
                app.PersistCaseFilesCheckbox.Value = true;
                app.PersistCaseFilesCheckbox.Enable = 'off';
            else
                app.PersistCaseFilesCheckbox.Enable = 'on';
            end
        end

        function onMaxAttemptsEdit(app)
            v = str2double(attemptStrEval(app.MaxRunAttemptsText.Value));
            if(isfinite(v) && v >= 1)
                app.Setup.maxNumAttempts = round(v);
            end
            app.MaxRunAttemptsText.Value = fullAccNum2Str(app.Setup.maxNumAttempts);
        end

        function onPersistCheckbox(app, ~, ~)
            app.Setup.persistCaseFiles = logical(app.PersistCaseFilesCheckbox.Value);
        end

        function randomizeSeed(app, ~, ~)
            app.Setup.seed = LvdSweepSampler.getRandomSeed();
            app.SeedText.Value = fullAccNum2Str(app.Setup.seed);
        end

        function onRandomSeedCheckbox(app, ~, ~)
            app.Setup.randomizeSeedEachRun = logical(app.RandomSeedCheckbox.Value);
            app.updateSeedEnables();
        end

        function updateSeedEnables(app)
            %updateSeedEnables A randomized seed comes from the generator at
            %run start, so the field and the one-shot button go quiet while
            %it is on.
            manualSeed = not(app.Setup.randomizeSeedEachRun);

            if(manualSeed)
                app.SeedText.Enable = 'on';
                app.RandomizeSeedButton.Enable = 'on';
            else
                app.SeedText.Enable = 'off';
                app.RandomizeSeedButton.Enable = 'off';
            end
        end

        function runButtonPushed(app, ~, ~)
            arguments
                app(1,1) lvd_runMonteCarlo_App
                ~
                ~
            end

            app.Setup.outputLocation = app.RunLocationSelector.Value;
            [ok, msg] = app.Setup.validate(app.LvdData);
            if(not(ok))
                uialert(app.UIFigure, msg, 'Invalid Dispersion Run', 'Icon', 'error');
                return;
            end

            optimizeMode = app.Setup.runMode == LvdCaseMatrixRunModeEnum.Optimize;

            if(optimizeMode)
                %An optimize run costs a full optimization per case: always
                %confirm, and insist on a parallel pool (offering to start
                %one, exactly as the Case Matrix does).
                if(app.ConfirmOptimizeRuns)
                    answer = uiconfirm(app.UIFigure, ...
                        sprintf(['This will optimize %u cases', ...
                                 ' (up to %u attempts each) and may take a long time.\n\n', ...
                                 'Responses and the final objective are harvested from each converged case.'], ...
                                app.Setup.getNumCases(), app.Setup.maxNumAttempts), ...
                        'Confirm Optimize Run', ...
                        'Options', {'Run', 'Cancel'}, 'DefaultOption', 2, 'Icon', 'warning');
                    if(not(strcmp(answer, 'Run')))
                        return;
                    end
                end

                pp = gcp('nocreate');
                if(isempty(pp))
                    startAnswer = uiconfirm(app.UIFigure, ...
                        'Optimize mode needs a parallel pool and none is running.  Start one now?', ...
                        'No Parallel Pool', ...
                        'Options', {'Start Pool', 'Cancel'}, 'DefaultOption', 2, 'Icon', 'question');
                    if(strcmp(startAnswer, 'Start Pool'))
                        startParallelPool(app.UIFigure, @(varargin) disp(''), app.Setup.numWorkers);
                        pp = gcp('nocreate');
                    end
                    if(isempty(pp))
                        uialert(app.UIFigure, ...
                            'Optimize mode requires a parallel pool: each case is optimized on a worker.  Use Propagate Only mode to run without one.', ...
                            'No Parallel Pool', 'Icon', 'error');
                        return;
                    end
                end

                app.Setup.persistCaseFiles = true;
                app.PersistCaseFilesCheckbox.Value = true;
            end

            if(app.Setup.randomizeSeedEachRun)
                app.Setup.seed = LvdSweepSampler.getRandomSeed();
                app.SeedText.Value = fullAccNum2Str(app.Setup.seed);
            end

            app.RunButton.Enable = 'off';
            app.TabGroup.SelectedTab = app.StatusTab;
            app.SpinnerIcon.Visible = true;
            app.CancelButton.Visible = true;
            app.CancelButton.Enable = true;
            app.RunTimeCounterLabel.Text = '00:00:00';
            app.RunTimeCounterLabel.Visible = true;
            app.LastRunTic = tic;
            timerFcn = @(src, evt) app.updateRuntimeLabel(src, evt);
            tmr = timer('TimerFcn', timerFcn, 'Period', 0.5, 'ExecutionMode', 'fixedRate');
            start(tmr);
            try
                cm = LvdCaseMatrix(app.LvdData, app.Setup.outputLocation);
                cm.runName = app.Setup.runName;
                cm.maxNumAttempts = app.Setup.maxNumAttempts;
                cm.createTasksFromSetup(app.Setup);
                app.CaseMatrix = cm;
                tableData = cm.getUITableData();
                app.RunStatusTable.ColumnName = cm.getStatusTableColumns();
                app.RunStatusTable.Data = tableData;
                for(i=1:numel(cm.tasks))
                    task = cm.tasks(i);
                    addlistener(task, 'StatusUpdated', @(src,evt) app.onTaskStatus(src,evt));
                    addlistener(task, 'OutputMessageUpdated', @(src,evt) app.onTaskMessage(src,evt));
                end
                drawnow;
                if(optimizeMode)
                    cm.runAllTasks(@(s) app.onProgressMessage(s));
                else
                    cm.runAllTasks();
                end
                app.LastResults = cm.results;
                tableData = cm.getUITableData();
                app.RunStatusTable.ColumnName = cm.getStatusTableColumns();
                app.RunStatusTable.Data = tableData;
                app.LvdData.monteCarloSetup = app.Setup.deepCopy();
                app.StatusLabel.Text = sprintf('Run finished: %u case(s).', cm.results.getNumCases());
            catch ME
                app.StatusLabel.Text = sprintf('Run failed: %s', ME.message);
            end
            stop(tmr);
            delete(tmr);
            app.SpinnerIcon.Visible = false;
            app.CancelButton.Visible = false;
            app.RunButton.Enable = 'on';
            app.RunTimeCounterLabel.Visible = false;
            app.OpenResultsButton.Enable = not(isempty(app.LastResults));
        end

        function cancelButtonPushed(app, ~, ~)
            app.CancelButton.Enable = false;
            drawnow;
            if(not(isempty(app.CaseMatrix)))
                app.CaseMatrix.cancelRun();
            end
            app.CancelButton.Enable = true;
        end

        function onTaskStatus(app, ~, evt)
            try
                caseNum = evt.task.caseNumber;
                data = app.RunStatusTable.Data;
                caseNums = cell2mat(data(:,1));
                bool = caseNum == caseNums;
                data{bool, end-1} = evt.updatedData.newStatus.name;
                app.RunStatusTable.Data = data;
                drawnow;
            catch
            end
        end

        function onTaskMessage(app, ~, evt)
            try
                caseNum = evt.task.caseNumber;
                data = app.RunStatusTable.Data;
                caseNums = cell2mat(data(:,1));
                bool = caseNum == caseNums;
                data{bool, end} = evt.updatedData;
                app.RunStatusTable.Data = data;
                drawnow;
            catch
            end
        end

        function updateRuntimeLabel(app, ~, ~)
            t = toc(app.LastRunTic);
            s = seconds(t);
            s.Format = 'hh:mm:ss';
            app.RunTimeCounterLabel.Text = string(s);
            drawnow;
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 900 640];
            app.UIFigure.Name = 'Run Monte Carlo Dispersion';
            app.UIFigure.Icon = 'logoSquare_48px_transparentBg.png';
            app.UIFigure.HandleVisibility = 'callback';
            app.UIFigure.CloseRequestFcn = @(~,~) app.onCloseRequest();

            app.MainGrid = uigridlayout(app.UIFigure, [3 1]);
            app.MainGrid.RowHeight = {28, '1x', 44};
            app.MainGrid.ColumnWidth = {'1x'};

            app.TitleLabel = uilabel(app.MainGrid);
            app.TitleLabel.Text = 'Monte Carlo Dispersion';
            app.TitleLabel.HorizontalAlignment = 'center';
            app.TitleLabel.FontSize = 16;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = 1;

            app.TabGroup = uitabgroup(app.MainGrid);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = 1;

            % ---- Dispersions tab ----
            app.DispTab = uitab(app.TabGroup, 'Title', 'Dispersions');
            app.DispGrid = uigridlayout(app.DispTab, [3 2]);
            app.DispGrid.RowHeight = {24, '1x', 60};
            app.DispGrid.ColumnWidth = {'1x', '1.4x'};

            app.ParamSearchText = uieditfield(app.DispGrid, 'text');
            app.ParamSearchText.Placeholder = 'Search parameters...';
            app.ParamSearchText.ValueChangedFcn = @(~,~) app.refreshAvailableParamListbox();
            app.ParamSearchText.Tooltip = 'Filters the available parameters below.  Searches the group and the parameter name.';
            app.ParamSearchText.Layout.Row = 1;
            app.ParamSearchText.Layout.Column = 1;

            app.AvailableParamListbox = uilistbox(app.DispGrid);
            app.AvailableParamListbox.Multiselect = 'on';
            app.AvailableParamListbox.DoubleClickedFcn = @(src,evt) app.addParamButtonPushed(src,evt);
            app.AvailableParamListbox.Tooltip = 'Double-click adds the parameter, like Add >>.';
            app.AvailableParamListbox.Layout.Row = 2;
            app.AvailableParamListbox.Layout.Column = 1;

            app.ParamButtonGrid = uigridlayout(app.DispGrid, [2 2]);
            app.ParamButtonGrid.ColumnWidth = {'1x', '1x'};
            app.ParamButtonGrid.RowHeight = {26, 26};
            app.ParamButtonGrid.Padding = [0 0 0 0];
            app.ParamButtonGrid.Layout.Row = 3;
            app.ParamButtonGrid.Layout.Column = 1;

            app.AddParamButton = uibutton(app.ParamButtonGrid, 'push');
            app.AddParamButton.Text = 'Add >>';
            app.AddParamButton.ButtonPushedFcn = @(src,evt) app.addParamButtonPushed(src,evt);
            app.AddParamButton.Tooltip = 'Disperses the selected available parameters with the chosen distribution.';
            app.AddParamButton.Layout.Row = 1;
            app.AddParamButton.Layout.Column = 1;

            app.RemoveParamButton = uibutton(app.ParamButtonGrid, 'push');
            app.RemoveParamButton.Text = '<< Remove';
            app.RemoveParamButton.ButtonPushedFcn = @(src,evt) app.removeParamButtonPushed(src,evt);
            app.RemoveParamButton.Tooltip = 'Removes the selected dispersion rows.';
            app.RemoveParamButton.Layout.Row = 1;
            app.RemoveParamButton.Layout.Column = 2;

            app.DistTypeLabel = uilabel(app.ParamButtonGrid);
            app.DistTypeLabel.Text = 'Distribution';
            app.DistTypeLabel.HorizontalAlignment = 'right';
            app.DistTypeLabel.Layout.Row = 2;
            app.DistTypeLabel.Layout.Column = 1;

            app.DistTypeDropdown = uidropdown(app.ParamButtonGrid);
            app.DistTypeDropdown.Items = {};
            app.DistTypeDropdown.ValueChangedFcn = @(src,evt) app.distTypeChanged(src,evt);
            app.DistTypeDropdown.Tooltip = 'Distribution for the selected dispersion row.';
            app.DistTypeDropdown.Layout.Row = 2;
            app.DistTypeDropdown.Layout.Column = 2;

            app.DispTable = uitable(app.DispGrid);
            app.DispTable.ColumnName = {'Parameter', 'Distribution', 'A', 'B', 'C'};
            app.DispTable.ColumnEditable = [false, false, true, true, true];
            app.DispTable.RowName = {};
            app.DispTable.CellEditCallback = @(src,evt) app.onDispTableEdit(evt);
            app.DispTable.Tooltip = 'A/B/C are the distribution parameters (Uniform: lower/upper; Normal: mean/sigma; Triangular: min/mode/max).';
            app.DispTable.Layout.Row = [1 3];
            app.DispTable.Layout.Column = 2;

            % ---- Run tab ----
            app.RunTab = uitab(app.TabGroup, 'Title', 'Sampling and Run');
            app.RunGrid = uigridlayout(app.RunTab, [10 2]);
            app.RunGrid.RowHeight = {24, 24, 24, 24, 24, 24, 24, 24, 60, 24};
            app.RunGrid.ColumnWidth = {130, '1x'};

            app.SamplingLabel = uilabel(app.RunGrid);
            app.SamplingLabel.Text = 'Sampling';
            app.SamplingLabel.HorizontalAlignment = 'right';
            app.SamplingLabel.Layout.Row = 1;
            app.SamplingLabel.Layout.Column = 1;

            app.SamplingDropdown = uidropdown(app.RunGrid);
            app.SamplingDropdown.ValueChangedFcn = @(src,evt) app.samplingChanged(src,evt);
            app.SamplingDropdown.Tooltip = 'Latin Hypercube stratifies each parameter into N equal-probability strata; Random draws independently.  Every run is reproducible from its seed.';
            app.SamplingDropdown.Layout.Row = 1;
            app.SamplingDropdown.Layout.Column = 2;

            app.RunModeLabel = uilabel(app.RunGrid);
            app.RunModeLabel.Text = 'Run Mode';
            app.RunModeLabel.HorizontalAlignment = 'right';
            app.RunModeLabel.Tooltip = 'Propagate Only surveys the design space without optimizing.  Optimize re-runs the optimizer on every case (requires a parallel pool).';
            app.RunModeLabel.Layout.Row = 2;
            app.RunModeLabel.Layout.Column = 1;

            app.RunModeDropdown = uidropdown(app.RunGrid);
            app.RunModeDropdown.ValueChangedFcn = @(src,evt) app.runModeChanged(src,evt);
            app.RunModeDropdown.Tooltip = app.RunModeLabel.Tooltip;
            app.RunModeDropdown.BackgroundColor = [1 1 1];
            app.RunModeDropdown.Layout.Row = 2;
            app.RunModeDropdown.Layout.Column = 2;

            app.NumSamplesLabel = uilabel(app.RunGrid);
            app.NumSamplesLabel.Text = 'Num Samples';
            app.NumSamplesLabel.HorizontalAlignment = 'right';
            app.NumSamplesLabel.Layout.Row = 3;
            app.NumSamplesLabel.Layout.Column = 1;

            app.NumSamplesText = uieditfield(app.RunGrid, 'text');
            app.NumSamplesText.ValueChangedFcn = @(~,~) app.onNumSamplesEdit();
            app.NumSamplesText.Tooltip = 'Number of cases (samples) to run.';
            app.NumSamplesText.Layout.Row = 3;
            app.NumSamplesText.Layout.Column = 2;

            app.SeedLabel = uilabel(app.RunGrid);
            app.SeedLabel.Text = 'Seed';
            app.SeedLabel.HorizontalAlignment = 'right';
            app.SeedLabel.Layout.Row = 4;
            app.SeedLabel.Layout.Column = 1;

            seedGrid = uigridlayout(app.RunGrid, [1 3]);
            seedGrid.ColumnWidth = {'1x', 110, 150};
            seedGrid.Padding = [0 0 0 0];
            seedGrid.Layout.Row = 4;
            seedGrid.Layout.Column = 2;

            app.SeedText = uieditfield(seedGrid, 'text');
            app.SeedText.ValueChangedFcn = @(~,~) app.onSeedEdit();
            app.SeedText.Tooltip = 'Seed for the sampler.  A run is reproducible from its seed alone; see the recorded seed in the results.';
            app.SeedText.Layout.Row = 1;
            app.SeedText.Layout.Column = 1;

            app.RandomizeSeedButton = uibutton(seedGrid, 'push');
            app.RandomizeSeedButton.Text = 'Randomize';
            app.RandomizeSeedButton.ButtonPushedFcn = @(src,evt) app.randomizeSeed(src,evt);
            app.RandomizeSeedButton.Tooltip = 'Draws a fresh random seed into the Seed field.';
            app.RandomizeSeedButton.Layout.Row = 1;
            app.RandomizeSeedButton.Layout.Column = 2;

            app.RandomSeedCheckbox = uicheckbox(seedGrid);
            app.RandomSeedCheckbox.Text = 'Random each run';
            app.RandomSeedCheckbox.ValueChangedFcn = @(src,evt) app.onRandomSeedCheckbox(src,evt);
            app.RandomSeedCheckbox.Tooltip = 'Draw a fresh seed at every run start (recorded in the results, so the run stays reproducible).  Off uses the Seed field.';
            app.RandomSeedCheckbox.Layout.Row = 1;
            app.RandomSeedCheckbox.Layout.Column = 3;

            app.WorkersLabel = uilabel(app.RunGrid);
            app.WorkersLabel.Text = 'Workers';
            app.WorkersLabel.HorizontalAlignment = 'right';
            app.WorkersLabel.Layout.Row = 5;
            app.WorkersLabel.Layout.Column = 1;

            app.NumWorkersText = uieditfield(app.RunGrid, 'text');
            app.NumWorkersText.ValueChangedFcn = @(~,~) app.onWorkersEdit();
            app.NumWorkersText.Tooltip = 'Parallel workers used to run the cases.  Optimize mode requires a pool.';
            app.NumWorkersText.Layout.Row = 5;
            app.NumWorkersText.Layout.Column = 2;

            app.MaxAttemptsLabel = uilabel(app.RunGrid);
            app.MaxAttemptsLabel.Text = 'Max Attempts';
            app.MaxAttemptsLabel.HorizontalAlignment = 'right';
            app.MaxAttemptsLabel.Tooltip = 'Per-case retry budget in Optimize mode (failed cases are retried after a full pass).  Unused in Propagate Only mode.';
            app.MaxAttemptsLabel.Layout.Row = 6;
            app.MaxAttemptsLabel.Layout.Column = 1;

            app.MaxRunAttemptsText = uieditfield(app.RunGrid, 'text');
            app.MaxRunAttemptsText.ValueChangedFcn = @(~,~) app.onMaxAttemptsEdit();
            app.MaxRunAttemptsText.HorizontalAlignment = 'center';
            app.MaxRunAttemptsText.Tooltip = 'Per-case retry budget in Optimize mode.  Unused in Propagate Only mode.';
            app.MaxRunAttemptsText.Layout.Row = 6;
            app.MaxRunAttemptsText.Layout.Column = 2;

            app.OutputLabel = uilabel(app.RunGrid);
            app.OutputLabel.Text = 'Output Folder';
            app.OutputLabel.HorizontalAlignment = 'right';
            app.OutputLabel.Layout.Row = 7;
            app.OutputLabel.Layout.Column = 1;

            app.RunLocationSelector = wt.FileSelector(app.RunGrid);
            app.RunLocationSelector.SelectionType = 'folder';
            app.RunLocationSelector.Layout.Row = 7;
            app.RunLocationSelector.Layout.Column = 2;

            app.RunNameLabel = uilabel(app.RunGrid);
            app.RunNameLabel.Text = 'Run Name';
            app.RunNameLabel.HorizontalAlignment = 'right';
            app.RunNameLabel.Tooltip = 'Display and file name for runs of this definition.  Stored runs can be renamed again in the Stored Runs table.';
            app.RunNameLabel.Layout.Row = 8;
            app.RunNameLabel.Layout.Column = 1;

            app.RunNameText = uieditfield(app.RunGrid, 'text');
            app.RunNameText.ValueChangedFcn = @(~,~) app.onRunNameEdit();
            app.RunNameText.Tooltip = 'Display and file name for runs of this definition.';
            app.RunNameText.Layout.Row = 8;
            app.RunNameText.Layout.Column = 2;

            outGrid = uigridlayout(app.RunGrid, [1 4]);
            outGrid.ColumnWidth = {'1x', '1x', '1x', '1.2x'};
            outGrid.RowHeight = {'1x'};
            outGrid.Padding = [0 0 0 0];
            outGrid.Layout.Row = 9;
            outGrid.Layout.Column = [1 2];

            app.WriteXlsxCheckbox = uicheckbox(outGrid);
            app.WriteXlsxCheckbox.Text = 'Excel (.xlsx)';
            app.WriteXlsxCheckbox.ValueChangedFcn = @(src,evt) app.onOutputCheckbox(src,evt);
            app.WriteXlsxCheckbox.Tooltip = 'Write the results workbook (.xlsx) with the results and run info sheets.';
            app.WriteXlsxCheckbox.Layout.Row = 1;
            app.WriteXlsxCheckbox.Layout.Column = 1;

            app.WriteMatCheckbox = uicheckbox(outGrid);
            app.WriteMatCheckbox.Text = 'MAT (.mat)';
            app.WriteMatCheckbox.ValueChangedFcn = @(src,evt) app.onOutputCheckbox(src,evt);
            app.WriteMatCheckbox.Tooltip = 'Write the results object (.mat) that the results viewer loads.';
            app.WriteMatCheckbox.Layout.Row = 1;
            app.WriteMatCheckbox.Layout.Column = 2;

            app.WriteCsvCheckbox = uicheckbox(outGrid);
            app.WriteCsvCheckbox.Text = 'CSV (.csv)';
            app.WriteCsvCheckbox.ValueChangedFcn = @(src,evt) app.onOutputCheckbox(src,evt);
            app.WriteCsvCheckbox.Tooltip = 'Write the results table (.csv).';
            app.WriteCsvCheckbox.Layout.Row = 1;
            app.WriteCsvCheckbox.Layout.Column = 3;

            app.PersistCaseFilesCheckbox = uicheckbox(outGrid);
            app.PersistCaseFilesCheckbox.Text = 'Case .mat files';
            app.PersistCaseFilesCheckbox.ValueChangedFcn = @(src,evt) app.onPersistCheckbox(src,evt);
            app.PersistCaseFilesCheckbox.Tooltip = 'One .mat per case.  Forced on in Optimize mode (the warm start and the retry path read them).';
            app.PersistCaseFilesCheckbox.Layout.Row = 1;
            app.PersistCaseFilesCheckbox.Layout.Column = 4;

            app.NumCasesLabel = uilabel(app.RunGrid);
            app.NumCasesLabel.HorizontalAlignment = 'center';
            app.NumCasesLabel.FontAngle = 'italic';
            app.NumCasesLabel.Layout.Row = 10;
            app.NumCasesLabel.Layout.Column = [1 2];

            % ---- Responses tab ----
            app.RespTab = uitab(app.TabGroup, 'Title', 'Responses');
            app.RespGrid = uigridlayout(app.RespTab, [4 2]);
            app.RespGrid.RowHeight = {24, 120, 30, '1x'};
            app.RespGrid.ColumnWidth = {'1x', '1.2x'};

            app.RespSearchText = uieditfield(app.RespGrid, 'text');
            app.RespSearchText.Placeholder = 'Search quantities...';
            app.RespSearchText.ValueChangedFcn = @(~,~) app.refreshRespTaskListbox();
            app.RespSearchText.Tooltip = 'Filters the graphical analysis quantities below.';
            app.RespSearchText.Layout.Row = 1;
            app.RespSearchText.Layout.Column = 1;

            app.RespTaskListbox = uilistbox(app.RespGrid);
            app.RespTaskListbox.Multiselect = 'on';
            app.RespTaskListbox.DoubleClickedFcn = @(src,evt) app.addRespButtonPushed(src,evt);
            app.RespTaskListbox.Tooltip = 'Double-click adds the response, like Add >>.';
            app.RespTaskListbox.Layout.Row = 2;
            app.RespTaskListbox.Layout.Column = 1;

            app.RespNodeDropdown = uidropdown(app.RespGrid);
            app.RespNodeDropdown.Tooltip = 'Where in the scoped span the response is read.';
            app.RespNodeDropdown.Layout.Row = 3;
            app.RespNodeDropdown.Layout.Column = 1;

            evtBodyGrid = uigridlayout(app.RespGrid, [2 1]);
            evtBodyGrid.RowHeight = {26, '1x'};
            evtBodyGrid.Padding = [0 0 0 0];
            evtBodyGrid.Layout.Row = [1 2];
            evtBodyGrid.Layout.Column = 2;

            app.RespEventDropdown = uidropdown(evtBodyGrid);
            app.RespEventDropdown.Tooltip = 'Whole mission or one event.';
            app.RespEventDropdown.Layout.Row = 1;
            app.RespEventDropdown.Layout.Column = 1;

            app.RespFrameSelector = referenceFrameSelectComp(evtBodyGrid);
            app.RespFrameSelector.Layout.Row = 2;
            app.RespFrameSelector.Layout.Column = 1;

            app.RespButtonGrid = uigridlayout(app.RespGrid, [1 2]);
            app.RespButtonGrid.ColumnWidth = {'1x', '1x'};
            app.RespButtonGrid.RowHeight = {'1x'};
            app.RespButtonGrid.Padding = [0 0 0 0];
            app.RespButtonGrid.Layout.Row = 3;
            app.RespButtonGrid.Layout.Column = 2;

            app.AddRespButton = uibutton(app.RespButtonGrid, 'push');
            app.AddRespButton.Text = 'Add >>';
            app.AddRespButton.ButtonPushedFcn = @(src,evt) app.addRespButtonPushed(src,evt);
            app.AddRespButton.Tooltip = 'Harvests the selected quantities (at the chosen node and scope) from every case.';
            app.AddRespButton.Layout.Row = 1;
            app.AddRespButton.Layout.Column = 1;

            app.RemoveRespButton = uibutton(app.RespButtonGrid, 'push');
            app.RemoveRespButton.Text = '<< Remove';
            app.RemoveRespButton.ButtonPushedFcn = @(src,evt) app.removeRespButtonPushed(src,evt);
            app.RemoveRespButton.Tooltip = 'Removes the selected response rows.';
            app.RemoveRespButton.Layout.Row = 1;
            app.RemoveRespButton.Layout.Column = 2;

            app.RespTable = uitable(app.RespGrid);
            app.RespTable.ColumnName = {'Response'};
            app.RespTable.RowName = {};
            app.RespTable.Tooltip = 'One row per harvested response.  Select rows and press << Remove to drop them.';
            app.RespTable.Layout.Row = 4;
            app.RespTable.Layout.Column = [1 2];

            % ---- Status tab ----
            app.StatusTab = uitab(app.TabGroup, 'Title', 'Status');
            app.StatusGrid = uigridlayout(app.StatusTab, [2 1]);
            app.StatusGrid.RowHeight = {'1x', 34};
            app.StatusGrid.ColumnWidth = {'1x'};

            app.RunStatusTable = uitable(app.StatusGrid);
            app.RunStatusTable.ColumnName = {'Case', 'Status', 'Message'};
            app.RunStatusTable.RowName = {};
            app.RunStatusTable.Tooltip = 'One row per case: inputs, live optimizer progress in Optimize mode, and the final status.';
            app.RunStatusTable.Layout.Row = 1;
            app.RunStatusTable.Layout.Column = 1;

            app.StatusButtonGrid = uigridlayout(app.StatusGrid, [1 4]);
            app.StatusButtonGrid.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.StatusButtonGrid.RowHeight = {'1x'};
            app.StatusButtonGrid.Padding = [0 0 0 0];
            app.StatusButtonGrid.Layout.Row = 2;
            app.StatusButtonGrid.Layout.Column = 1;

            app.RunButton = uibutton(app.StatusButtonGrid, 'push');
            app.RunButton.Text = 'Run Dispersion';
            app.RunButton.ButtonPushedFcn = @(src,evt) app.runButtonPushed(src,evt);
            app.RunButton.Tooltip = 'Runs the dispersion.  Optimize mode asks for confirmation first.';
            app.RunButton.Layout.Row = 1;
            app.RunButton.Layout.Column = 1;

            app.CancelButton = uibutton(app.StatusButtonGrid, 'push');
            app.CancelButton.Text = 'Cancel';
            app.CancelButton.ButtonPushedFcn = @(src,evt) app.cancelButtonPushed(src,evt);
            app.CancelButton.Tooltip = 'Stops dispatching new cases; running cases finish.';
            app.CancelButton.Layout.Row = 1;
            app.CancelButton.Layout.Column = 2;

            app.OpenResultsButton = uibutton(app.StatusButtonGrid, 'push');
            app.OpenResultsButton.Text = 'Open Results...';
            app.OpenResultsButton.ButtonPushedFcn = @(src,evt) app.openResults(src,evt);
            app.OpenResultsButton.Tooltip = 'Opens the last run in the sweep results viewer.';
            app.OpenResultsButton.Layout.Row = 1;
            app.OpenResultsButton.Layout.Column = 3;

            app.StoreResultsButton = uibutton(app.StatusButtonGrid, 'push');
            app.StoreResultsButton.Text = 'Store Results';
            app.StoreResultsButton.ButtonPushedFcn = @(src,evt) app.storeCurrentResults(src,evt);
            app.StoreResultsButton.Tooltip = 'Files the last run onto the mission so it survives save/load.  Stored runs accumulate on the Stored Runs tab.';
            app.StoreResultsButton.Layout.Row = 1;
            app.StoreResultsButton.Layout.Column = 4;

            % ---- Stored Runs tab ----
            app.StoredTab = uitab(app.TabGroup, 'Title', 'Stored Runs');
            app.StoredGrid = uigridlayout(app.StoredTab, [2 1]);
            app.StoredGrid.RowHeight = {'1x', 34};
            app.StoredGrid.ColumnWidth = {'1x'};

            app.StoredRunsTable = uitable(app.StoredGrid);
            app.StoredRunsTable.ColumnName = {'Run', 'Completed', 'Cases', 'Mode'};
            app.StoredRunsTable.ColumnEditable = [true, false, false, false];
            app.StoredRunsTable.RowName = {};
            app.StoredRunsTable.CellEditCallback = @(src,evt) app.onStoredTableEdit(evt);
            app.StoredRunsTable.Tooltip = 'Runs stored on this mission, newest last.  Edit the Run cell to rename; select a row to open or delete it.';
            app.StoredRunsTable.Layout.Row = 1;
            app.StoredRunsTable.Layout.Column = 1;

            app.StoredButtonGrid = uigridlayout(app.StoredGrid, [1 2]);
            app.StoredButtonGrid.ColumnWidth = {'1x', '1x'};
            app.StoredButtonGrid.RowHeight = {'1x'};
            app.StoredButtonGrid.Padding = [0 0 0 0];
            app.StoredButtonGrid.Layout.Row = 2;
            app.StoredButtonGrid.Layout.Column = 1;

            app.OpenStoredButton = uibutton(app.StoredButtonGrid, 'push');
            app.OpenStoredButton.Text = 'Open...';
            app.OpenStoredButton.ButtonPushedFcn = @(src,evt) app.openStoredResults(src,evt);
            app.OpenStoredButton.Tooltip = 'Opens the selected stored run in the sweep results viewer.';
            app.OpenStoredButton.Layout.Row = 1;
            app.OpenStoredButton.Layout.Column = 1;

            app.DeleteStoredButton = uibutton(app.StoredButtonGrid, 'push');
            app.DeleteStoredButton.Text = 'Delete';
            app.DeleteStoredButton.ButtonPushedFcn = @(src,evt) app.deleteStoredResults(src,evt);
            app.DeleteStoredButton.Tooltip = 'Deletes the selected stored runs from the mission.';
            app.DeleteStoredButton.Layout.Row = 1;
            app.DeleteStoredButton.Layout.Column = 2;

            bottomGrid = uigridlayout(app.MainGrid, [1 3]);
            bottomGrid.ColumnWidth = {25, '1x', 90};
            bottomGrid.RowHeight = {'1x'};
            bottomGrid.Padding = [0 0 0 0];
            bottomGrid.Layout.Row = 3;
            bottomGrid.Layout.Column = 1;

            app.SpinnerIcon = uiimage(bottomGrid);
            app.SpinnerIcon.ImageSource = 'Spin-1s-200px_transparentBg.gif';
            app.SpinnerIcon.Layout.Row = 1;
            app.SpinnerIcon.Layout.Column = 1;

            app.StatusLabel = uilabel(bottomGrid);
            app.StatusLabel.Text = 'Ready';
            app.StatusLabel.Layout.Row = 1;
            app.StatusLabel.Layout.Column = 2;

            app.RunTimeCounterLabel = uilabel(bottomGrid);
            app.RunTimeCounterLabel.HorizontalAlignment = 'center';
            app.RunTimeCounterLabel.Layout.Row = 1;
            app.RunTimeCounterLabel.Layout.Column = 3;
        end

        function onNumSamplesEdit(app)
            v = str2double(attemptStrEval(app.NumSamplesText.Value));
            if(isfinite(v) && v >= 1)
                app.Setup.numSamples = round(v);
                app.NumSamplesText.Value = fullAccNum2Str(app.Setup.numSamples);
            else
                app.NumSamplesText.Value = fullAccNum2Str(app.Setup.numSamples);
            end
            app.refreshCaseCountLabel();
        end

        function onSeedEdit(app)
            v = str2double(attemptStrEval(app.SeedText.Value));
            if(isfinite(v))
                app.Setup.seed = v;
            end
            app.SeedText.Value = fullAccNum2Str(app.Setup.seed);
        end

        function onWorkersEdit(app)
            v = str2double(attemptStrEval(app.NumWorkersText.Value));
            if(isfinite(v) && v >= 1)
                app.Setup.numWorkers = round(v);
            end
            app.NumWorkersText.Value = fullAccNum2Str(app.Setup.numWorkers);
        end

        function onRunNameEdit(app)
            v = strtrim(app.RunNameText.Value);
            if(isempty(v))
                v = app.Setup.runName;
            end
            app.Setup.runName = v;
            app.RunNameText.Value = v;
        end

        function onOutputCheckbox(app, ~, ~)
            app.Setup.writeXlsx = logical(app.WriteXlsxCheckbox.Value);
            app.Setup.writeMat = logical(app.WriteMatCheckbox.Value);
            app.Setup.writeCsv = logical(app.WriteCsvCheckbox.Value);
        end
    end
end
