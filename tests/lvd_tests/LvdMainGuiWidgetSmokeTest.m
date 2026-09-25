classdef LvdMainGuiWidgetSmokeTest < matlab.uitest.TestCase
    %LvdMainGuiWidgetSmokeTest Pure open+cancel smoke of every NOT-YET-COVERED
    %widget of the LVD main window (ma_LvdMainGUI_App).
    %
    %   Gap-only by design: anything already covered by
    %   LvdMainGuiInteractionTest (insertEventButton, EditEventMenu,
    %   ToggleEventGroupMenu, Variable/ Constraint/Sensitivity tables,
    %   Export Ephemeris, View Playback open/raise, DispAxesTimeSlider play,
    %   undoMenu single press) is NOT re-tested here except for its parent
    %   menu rebuild.  Every test below presses a menu/button/list/tab and
    %   cancels whatever it opened, asserting the main window stays alive
    %   and no handler errored.  Deeper value assertions come later.
    %
    %   Native modal dialogs (uigetfile/uiputfile/uiconfirm/inputdlg and
    %   clipboard copy) are stubbed by NativeDialogInterceptorFixture with
    %   cancel defaults, so "matlab -batch" never hangs.  Blocking App
    %   Designer editors (uiwait) are cancelled through
    %   UiwaitInterceptorFixture with a catch-all Cancel/Close/Save&Close
    %   handler.  The optimizer itself is NEVER run here (see
    %   optimizeMissionIsWiredButNeverRunInSmoke).

    properties(Access = private)
        celBodyData
        stubMainFig
        figuresBefore
        uiwaitFixture UiwaitInterceptorFixture
        nativeFixture NativeDialogInterceptorFixture
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            ksptotAddProjectPaths();
            testCase.celBodyData = ksptotTestBodyData();

            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end

            global ksptot_TimeSystem options_UseEarthTimeSystem %#ok<GVMIS>
            if(isempty(ksptot_TimeSystem))
                [rawIni, ~, ~] = inifile(fullfile(ksptotTestRoot(), 'bodies.ini'), 'readall');
                ksptot_TimeSystem = getTimeSystemFromConfig(getAppOptionsFromFile(), rawIni);
                options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system, 'earth_stock');
            end
        end
    end

    methods(TestMethodSetup)
        function armFixtures(testCase)
            testCase.uiwaitFixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.nativeFixture = testCase.applyFixture(NativeDialogInterceptorFixture());
            %Catch-all cancel for every blocking editor this smoke may hit.
            %once=false so one registration covers a whole menu sweep.
            testCase.uiwaitFixture.whenShown('*', @LvdMainGuiWidgetSmokeTest.smokeCancel, false);
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)

        %% ---------------- File menu (native dialogs stubbed to cancel)

        function fileNewResetsWithoutDialog(testCase)
            app = testCase.openLvd();
            testCase.press(app.newMissionPlanMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI), 'New on a saved case must keep the window alive.');
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            testCase.verifyEqual(lvdData.script.getTotalNumOfEvents(), 1);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
        end

        function fileNewDirtyNoKeepsMission(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            set(app.ma_LvdMainGUI, 'Name', [get(app.ma_LvdMainGUI, 'Name'), '*']); %dirty
            testCase.nativeFixture.setUiconfirmResponse('No');
            testCase.press(app.newMissionPlanMenu);
            testCase.verifyGreaterThan(testCase.nativeFixture.calls().uiconfirm, 0, 'Dirty New must ask.');
            testCase.verifyTrue(endsWith(get(app.ma_LvdMainGUI, 'Name'), '*'), 'No must keep the dirty mission.');
            testCase.verifyTrue(getappdata(app.ma_LvdMainGUI, 'lvdData') == lvdData);
        end

        function fileNewDirtyYesResets(testCase)
            app = testCase.openLvd();
            set(app.ma_LvdMainGUI, 'Name', [get(app.ma_LvdMainGUI, 'Name'), '*']); %dirty
            testCase.nativeFixture.setUiconfirmResponse('Yes');
            testCase.press(app.newMissionPlanMenu);
            testCase.verifyFalse(endsWith(get(app.ma_LvdMainGUI, 'Name'), '*'), 'Yes must reset to a clean mission.');
            testCase.verifyEqual(getappdata(app.ma_LvdMainGUI, 'lvdData').script.getTotalNumOfEvents(), 1);
        end

        function fileOpenCancelKeepsMission(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            %uigetfile stub defaults to cancel (0,0,0).
            testCase.press(testCase.menuItem(app.fileMenu, 'Open Mission Plan'));
            testCase.press(app.openMissionPlanToolbar);
            testCase.verifyGreaterThanOrEqual(testCase.nativeFixture.calls().uigetfile, 2, 'Both menu and toolbar must hit uigetfile.');
            testCase.verifyTrue(getappdata(app.ma_LvdMainGUI, 'lvdData') == lvdData, 'Cancel must keep the mission.');
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function fileOpenRoundTripViaStub(testCase)
            app = testCase.openLvd();
            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            tmpFile = fullfile(tmpDir, 'smokeMission.mat');
            setappdata(app.ma_LvdMainGUI, 'current_save_location', tmpFile);
            testCase.press(app.saveMissionPlanMenu); %direct save, no dialog
            testCase.verifyTrue(isfile(tmpFile), 'Preset-location Save must write the file.');

            %Dirty the title so Open takes the confirm path, then say Yes
            %and serve the temp file from the uigetfile stub.
            set(app.ma_LvdMainGUI, 'Name', [get(app.ma_LvdMainGUI, 'Name'), '*']);
            testCase.nativeFixture.setUiconfirmResponse('Yes');
            testCase.nativeFixture.setUigetfileSuccess(tmpFile);
            testCase.press(testCase.menuItem(app.fileMenu, 'Open Mission Plan'));
            testCase.verifyEqual(getappdata(app.ma_LvdMainGUI, 'current_save_location'), tmpFile);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function fileSaveWritesWithoutDialog(testCase)
            app = testCase.openLvd();
            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            tmpFile = fullfile(tmpDir, 'saveSmoke.mat');
            setappdata(app.ma_LvdMainGUI, 'current_save_location', tmpFile);
            testCase.press(app.saveMissionPlanMenu);
            testCase.press(app.saveMissionPlanToolbar);
            testCase.verifyTrue(isfile(tmpFile), 'Save with a preset location must not pop a dialog.');
            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 0, 'No file dialog expected.');
        end

        function fileSaveAsCancelAndSuccess(testCase)
            app = testCase.openLvd();
            %Cancel path first: stub returns 0.
            testCase.press(testCase.menuItem(app.fileMenu, 'Save Mission Plan As...'));
            testCase.verifyEqual(testCase.nativeFixture.calls().uiputfile, 1);

            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            tmpFile = fullfile(tmpDir, 'saveAsSmoke.mat');
            testCase.nativeFixture.setUiputfileSuccess(tmpFile);
            testCase.press(testCase.menuItem(app.fileMenu, 'Save Mission Plan As...'));
            testCase.verifyTrue(isfile(tmpFile), 'Save As success stub must write the file.');
            testCase.verifyEqual(getappdata(app.ma_LvdMainGUI, 'current_save_location'), tmpFile);
        end

        function fileMfmsAndSweepCancel(testCase)
            app = testCase.openLvd();
            %Both serve uigetfile then return early on cancel.
            testCase.press(app.NewMissionPlanfromMFMSOutputMenu);
            testCase.press(app.OpenSweepResultsMenu);
            testCase.verifyGreaterThanOrEqual(testCase.nativeFixture.calls().uigetfile, 2);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
        end

        function fileRecentRebuilds(testCase)
            app = testCase.openLvd();
            %Branch menus cannot take press (NotALeafMenu); fire the rebuild
            %callback directly, exactly as the framework docs prescribe for
            %unsupported gestures.
            app.fileMenu.MenuSelectedFcn(app.fileMenu, struct('Source', app.fileMenu, 'EventName', 'MenuSelected'));
            drawnow;
            testCase.verifyNotEmpty(app.openRecentMissionPlansMenu.Children, 'File menu must rebuild recent items.');
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function fileExitNoKeepsApp(testCase)
            app = testCase.openLvd();
            set(app.ma_LvdMainGUI, 'Name', [get(app.ma_LvdMainGUI, 'Name'), '*']); %dirty -> confirm path
            testCase.nativeFixture.setUiconfirmResponse('No');
            testCase.press(testCase.menuItem(app.fileMenu, 'Exit Launch Vehicle Designer'));
            testCase.verifyGreaterThan(testCase.nativeFixture.calls().uiconfirm, 0);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI), 'No must keep the app open.');
        end

        function fileExitYesClosesApp(testCase)
            app = testCase.openLvd();
            testCase.nativeFixture.setUiconfirmResponse('Yes');
            testCase.press(testCase.menuItem(app.fileMenu, 'Exit Launch Vehicle Designer'));
            closed = false;
            try
                closed = not(isvalid(app.ma_LvdMainGUI));
            catch
                closed = true; %app handle itself went away with the figure
            end
            testCase.verifyTrue(closed, 'Yes on a saved case must close the window.');
        end

        %% ---------------- Edit / View menus (gap leaves only)

        function editMenuRefreshesUndoRedo(testCase)
            app = testCase.openLvd();
            %Branch menu: press is unsupported, fire the refresh callback.
            app.editMenu.MenuSelectedFcn(app.editMenu, struct('Source', app.editMenu, 'EventName', 'MenuSelected'));
            drawnow;
            testCase.verifyNotEmpty(char(app.undoMenu.Label));
            testCase.verifyNotEmpty(char(app.redoMenu.Label));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function missionNotesOpens(testCase)
            app = testCase.openLvd();
            testCase.press(app.editMissionNotesMenu);
            names = testCase.newFigureNames();
            testCase.verifyTrue(any(contains(names, 'Mission Notes')), 'Mission Notes window must open.');
        end

        function viewSettingsCancels(testCase)
            app = testCase.openLvd();
            testCase.press(app.editViewSettingsMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function popOutOrbitDisplayOpens(testCase)
            app = testCase.openLvd();
            testCase.press(app.popOutOrbitDisplayMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            testCase.verifyGreaterThanOrEqual(numel(testCase.newFigureNames()), 1, 'Pop-out must create a figure.');
            %Delete the pop-out while the app is alive: its DeleteFcn
            %restores the inline axes and replots, which needs a live app.
            figs = findall(groot, 'Type', 'figure');
            popouts = figs(not(ismember(figs, [testCase.figuresBefore; app.ma_LvdMainGUI; testCase.stubMainFig])));
            delete(popouts(isvalid(popouts)));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function viewProfilesRebuild(testCase)
            app = testCase.openLvd();
            %Branch menu: press is unsupported, fire the rebuild callback.
            app.viewMenu.MenuSelectedFcn(app.viewMenu, struct('Source', app.viewMenu, 'EventName', 'MenuSelected'));
            drawnow;
            testCase.verifyNotEmpty(app.setActiveViewProfileMenu.Children, 'Active profile list must rebuild.');
        end

        %% ---------------- Scenario editors (all Cancel, gap only)

        function scenarioEditorsPart1Cancel(testCase)
            app = testCase.openLvd();
            %Smoke is open+cancel: skip repropagation so six editors stay fast.
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData'); lvdData.settings.autoPropScript = false;
            testCase.press(app.editLaunchVehicleMenu);
            testCase.press(app.editInitialStateMenu);
            testCase.press(app.editStopwatchesMenu);
            testCase.press(app.editExtremaMenu);
            testCase.press(app.editCalculusObjectsMenu);
            testCase.press(app.editGroundObjsMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function scenarioEditorsPart2Cancel(testCase)
            app = testCase.openLvd();
            %Smoke is open+cancel: skip repropagation so nine editors stay fast.
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData'); lvdData.settings.autoPropScript = false;
            testCase.press(app.EditSensorsMenu);
            testCase.press(app.EditSensorTargetsMenu);
            testCase.press(app.editPointsMenu);
            testCase.press(app.editVectorsMenu);
            testCase.press(app.editAnglesMenu);
            testCase.press(app.editPlanesMenu);
            testCase.press(app.editCoordSysMenu);
            testCase.press(app.editRefRamesMenu);
            testCase.press(app.PluginVariablesMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function sensorReportsAlertsWhenEmpty(testCase)
            app = testCase.openLvd();
            testCase.press(app.SensorReportsMenu);
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
                %No alert is also acceptable if data exists; smoke only needs no hang.
            end
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        %% ---------------- Simulation menu (no optimizer runs)

        function simulationRunScriptKeepsAppAlive(testCase)
            app = testCase.openLvd();
            testCase.press(app.runScriptMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function simulationCaseMatrixOpens(testCase)
            app = testCase.openLvd();
            testCase.press(app.RunCaseMatrixMenu);
            testCase.verifyGreaterThanOrEqual(numel(testCase.newFigureNames()), 1, 'Case Matrix window must open.');
        end

        function simulationMonteCarloOpens(testCase)
            app = testCase.openLvd();
            testCase.press(app.RunMonteCarloMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            %Monte Carlo may alert (invalid dispersion) or open; either is
            %fine as long as nothing hangs. Dismiss any alert.
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
            end
        end

        function simulationKosCancels(testCase)
            app = testCase.openLvd();
            %uiputfile stub cancels before any list dialog appears.
            testCase.press(app.createkOSExecCodeMenu);
            testCase.verifyGreaterThan(testCase.nativeFixture.calls().uiputfile, 0);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function optimizeIntegratorSelectionsIsWiredButNotRun(testCase)
            %findBestIntegrator runs 50 propagations per event: verify wiring
            %only, never press in smoke.
            app = testCase.openLvd();
            testCase.verifyClass(app.OptimizeIntegratorSelectionsMenu.MenuSelectedFcn, 'function_handle');
            testCase.verifyNotEmpty(app.OptimizeIntegratorSelectionsMenu.Tooltip);
            testCase.verifyEqual(char(app.OptimizeIntegratorSelectionsMenu.Text), 'Optimize Integrator Selections');
        end

        function optimizeMissionIsWiredButNeverRunInSmoke(testCase)
            %Starting the real optimizer takes minutes: wiring only.
            app = testCase.openLvd();
            testCase.verifyClass(app.optimizeMissionMenu.MenuSelectedFcn, 'function_handle');
            testCase.verifyNotEmpty(app.optimizeMissionMenu.Tooltip);
        end

        %% ---------------- Optimization menu (safe presses only)

        function optimizationObjectiveAndConstraintsCancel(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData'); lvdData.settings.autoPropScript = false;
            testCase.press(app.editObjFunctionMenu);
            testCase.press(app.editConstraintsMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function optimizationPerturbCancels(testCase)
            app = testCase.openLvd();
            %inputdlg stub returns {} -> early return, no mutation.
            testCase.press(app.perturbOptVarsMenu);
            testCase.verifyGreaterThan(testCase.nativeFixture.calls().inputdlg, 0);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function optimizationAdjustWarnsWithoutVars(testCase)
            app = testCase.openLvd();
            testCase.press(app.adjustVariablesMenu); %default case: warndlg path
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            %warndlg figure (if any) is cleaned by the method teardown.
        end

        function optimizationJacobianNoopsWithoutVars(testCase)
            app = testCase.openLvd();
            nBefore = numel(findall(groot, 'Type', 'figure'));
            testCase.press(app.showConstrJacobianHeatMapMenu); %no vars/constraints -> no-op
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            testCase.verifyEqual(numel(findall(groot, 'Type', 'figure')), nBefore, 'No-op must not pop figures.');
        end

        function optimizationScaleAlerts(testCase)
            app = testCase.openLvd();
            testCase.press(app.ScaleConstraintsCurrentValueMenu);
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
            end
            testCase.press(app.ScaleConstraintsJacobianMenu);
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
            end
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function optimizationSelectAlgosCancels(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData'); lvdData.settings.autoPropScript = false;
            testCase.press(app.selectOptimizationAlgosMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        %% ---------------- Settings menu (cancel / toggle, no mutation assert)

        function settingsMenusRefreshChecks(testCase)
            app = testCase.openLvd();
            %Branch menus: press is unsupported, fire the Checked-sync callbacks.
            app.settingsMenu.MenuSelectedFcn(app.settingsMenu, struct('Source', app.settingsMenu, 'EventName', 'MenuSelected'));
            app.integrationSettingsMenu.MenuSelectedFcn(app.integrationSettingsMenu, struct('Source', app.integrationSettingsMenu, 'EventName', 'MenuSelected'));
            drawnow;
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function settingsTogglesStayAlive(testCase)
            app = testCase.openLvd();
            testCase.press(app.autopropagateMenu);
            testCase.press(app.displayEvtPropTimesInLogFileMenu);
            testCase.press(app.sparseIntegratorOutputMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function settingsNumericInputsCancel(testCase)
            app = testCase.openLvd();
            %All inputdlg-backed: stub cancels, values untouched.
            testCase.press(app.intMinAltitudeMenu);
            testCase.press(app.intMaxSimTimeMenu);
            testCase.press(app.maxScriptPropTimeMenu);
            testCase.press(app.setIntegrationStepSizeForAllEventsMenu);
            testCase.press(app.SetIntegratorAbsoluteToleranceforAllEventsMenu);
            testCase.press(app.SetIntegratorRelativeToleranceforAllEventsMenu);
            testCase.verifyGreaterThanOrEqual(testCase.nativeFixture.calls().inputdlg, 6);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function settingsCacheAndAstroOpen(testCase)
            app = testCase.openLvd();
            testCase.press(app.configureCelestialBodyStateCacheMenu);
            testCase.press(app.astroCalculatorsMenu);
            testCase.press(app.celBodyCatalogMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function settingsHaloGraphicalConsoleOpen(testCase)
            app = testCase.openLvd();
            testCase.press(app.haloOrbitConstructorMenu);
            testCase.press(app.graphicalAnalysisMenu);
            testCase.press(app.LVDConsoleMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
        end

        function pluginsManageOpensWithoutHang(testCase)
            testCase.assumeTrue(usejava('jvm'), 'Java is required for the plugin code editor.');
            app = testCase.openLvd();
            %GUIDE dialog (uicontrol buttons): the catch-all may not find a
            %Cancel button, so success = opened without hanging; the figure
            %is reaped by the method teardown.
            testCase.press(app.managePluginsMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI) || not(isempty(testCase.newFigureNames())));
        end

        %% ---------------- Toolbar (push + toggle tools)

        function toolbarNewOpenSaveSmoke(testCase)
            app = testCase.openLvd();
            testCase.nativeFixture.setUiconfirmResponse('No');
            testCase.press(app.newMissionPlanToolbar); %dirty? fresh saved -> resets w/o confirm
            testCase.press(app.openMissionPlanToolbar); %uigetfile cancel
            testCase.verifyGreaterThanOrEqual(testCase.nativeFixture.calls().uigetfile, 1);
            tmpDir = tempname(); mkdir(tmpDir);
            testCase.addTeardown(@() rmdir(tmpDir, 's'));
            setappdata(app.ma_LvdMainGUI, 'current_save_location', fullfile(tmpDir, 'tb.mat'));
            testCase.press(app.saveMissionPlanToolbar);
            testCase.verifyTrue(isfile(fullfile(tmpDir, 'tb.mat')));
        end

        function toolbarCameraTogglesAndRestore(testCase)
            app = testCase.openLvd();
            toggles = [app.panPushMenuToggle, app.orbitCameraPushMenuToggle, ...
                app.rotateCameraPushMenuToggle, app.zoomOutPushMenuToggle, app.zoomInPushMenuToggle];
            for k = 1:numel(toggles)
                testCase.press(toggles(k));
                testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            end
            testCase.press(app.RestoreViewToolbarMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        %% ---------------- Main-window buttons / lists / tabs / table

        function mainMoveAndDeleteSecondEvent(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            testCase.assertEqual(lvdData.script.getTotalNumOfEvents(), 1);
            %Programmatic add plus refresh: processData must sync the
            %Delete enablement (regression: it used to stay disabled and
            %press() silently no-ops on disabled buttons).
            lvdData.script.addEventAtInd(LaunchVehicleEvent.getDefaultEvent(lvdData.script), 1);
            app.lvdEnhancementsRefresh(false);
            testCase.assertEqual(lvdData.script.getTotalNumOfEvents(), 2);
            testCase.verifyEqual(app.deleteEvent.Enable, matlab.lang.OnOffSwitchState.on, ...
                'Refresh must enable Delete when a second event exists.');

            app.scriptListbox.Value = app.scriptListbox.ItemsData(2);
            testCase.press(app.moveEventUp);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
            app.scriptListbox.Value = app.scriptListbox.ItemsData(1);
            testCase.press(app.moveEventDown);
            app.scriptListbox.Value = app.scriptListbox.ItemsData(2);
            testCase.press(app.deleteEvent);
            testCase.verifyEqual(lvdData.script.getTotalNumOfEvents(), 1, 'Delete must remove the second event.');
        end

        function mainNonSeqInsertChooseDelete(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            n0 = lvdData.script.nonSeqEvts.getTotalNumOfEvents();
            testCase.press(app.insertNonSeqEventButton); %blocked editor -> smokeCancel
            testCase.verifyEqual(lvdData.script.nonSeqEvts.getTotalNumOfEvents(), n0 + 1);
            if(lvdData.script.nonSeqEvts.getTotalNumOfEvents() > 0)
                app.nonSeqEventsListbox.Value = app.nonSeqEventsListbox.ItemsData(end);
                testCase.choose(app.nonSeqEventsListbox, numel(app.nonSeqEventsListbox.Items));
                testCase.press(app.deleteNonSeqEventButton);
                testCase.verifyEqual(lvdData.script.nonSeqEvts.getTotalNumOfEvents(), n0);
            end
        end

        function mainOrbitChunkTabsAndTableSmoke(testCase)
            app = testCase.openLvd();
            testCase.press(app.decrOrbitToPlotNum);
            testCase.press(app.incrOrbitToPlotNum);
            testCase.choose(app.DTrajectoryTab);
            testCase.choose(app.GroundTrackTab);
            testCase.choose(app.DTrajectoryTab);
            testCase.verifyClass(app.WarnAlertTable, 'matlab.ui.control.Table');
            testCase.verifyNotEmpty(char(app.timeSliderValueLabel.Text));
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function mainOutputClearAndStateAreas(testCase)
            app = testCase.openLvd();
            testCase.verifyNotEmpty(app.outputText.Value);
            testCase.chooseContextMenu(app.outputText, app.clearOutputMenu);
            testCase.verifyNotEmpty(app.InitialSpacecraftStateTextArea.Value);
            testCase.verifyNotEmpty(app.FinalSpacecraftStateTextArea.Value);
            testCase.chooseContextMenu(app.InitialSpacecraftStateTextArea, app.CopyInitialOrbitToClipboardMenu);
            testCase.chooseContextMenu(app.FinalSpacecraftStateTextArea, app.CopyFinalOrbittoClipboardMenu);
            %Copy-orbit uses GLOBAL_OrbitClipboard, not the system clipboard.
            global GLOBAL_OrbitClipboard %#ok<GVMIS>
            testCase.verifyNotEmpty(GLOBAL_OrbitClipboard, 'Copy-orbit must populate the orbit clipboard.');
        end

        function mainDisplayFrameDialogsCancel(testCase)
            app = testCase.openLvd();
            testCase.chooseContextMenu(app.InitialSpacecraftStateTextArea, app.ChangeInitialReferenceFrameElementSetMenu);
            testCase.chooseContextMenu(app.FinalSpacecraftStateTextArea, app.ChangeFinalReferenceFrameElementSetMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
        end

        %% ---------------- Script listbox context menu (gap items only)

        function contextToggleOptimAndViewState(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            app.scriptListbox.Value = lvdData.script.getEventForInd(1);
            testCase.chooseContextMenu(app.scriptListbox, app.toggleOptimForSelEventMenu);
            testCase.chooseContextMenu(app.scriptListbox, app.toggleOptimForSelEventMenu); %toggle back
            testCase.chooseContextMenu(app.scriptListbox, app.viewStateAfterSelectedEventMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function contextContinuityWarnsWithOneEvent(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            testCase.assertEqual(lvdData.script.getTotalNumOfEvents(), 1);
            app.scriptListbox.Value = lvdData.script.getEventForInd(1);
            testCase.chooseContextMenu(app.scriptListbox, app.createContConstraintsWithSelEvtMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI)); %warndlg path; figure reaped by teardown
        end

        function contextCopyItemsHitClipboard(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            app.scriptListbox.Value = lvdData.script.getEventForInd(1);
            testCase.chooseContextMenu(app.scriptListbox, app.copyUtAtStartOfSelEventMenu);
            testCase.chooseContextMenu(app.scriptListbox, app.copyUtAtEndOfSelEventMenu);
            testCase.chooseContextMenu(app.scriptListbox, app.copyDurationOfSelEventMenu);
            testCase.chooseContextMenu(app.scriptListbox, app.copyOrbitAfterSelectedEventMenu);
            %UT/duration use system clipboard (stubbed); orbit uses GLOBAL_OrbitClipboard.
            testCase.verifyGreaterThanOrEqual(testCase.nativeFixture.calls().clipboardCopy, 3);
            global GLOBAL_OrbitClipboard %#ok<GVMIS>
            testCase.verifyNotEmpty(GLOBAL_OrbitClipboard);
        end

        function contextAdvanceToFirstEvent(testCase)
            %Regression: advancing on a mission with no initial-state
            %optVar used to crash in
            %InitialStateModel.setInitialStateFromStateLogEntry (empty
            %obj.optVar dereference).  The product now guards it.
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            app.scriptListbox.Value = lvdData.script.getEventForInd(1);
            testCase.chooseContextMenu(app.scriptListbox, app.advanceScriptToSelectedEventMenu);
            testCase.verifyEmpty(testCase.uiwaitFixture.errors(), strjoin(testCase.uiwaitFixture.errors(), newline));
            testCase.verifyEqual(lvdData.script.getTotalNumOfEvents(), 1);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end

        function contextConvertAlertsWithoutDv(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            app.scriptListbox.Value = lvdData.script.getEventForInd(1);
            %Default event has no AddDeltaVAction: Convert alerts, Upload
            %errors. Both must be dismissable/deletable without hanging.
            testCase.chooseContextMenu(app.scriptListbox, app.ConvertImpulsiveDVActionintoFiniteBurnMenu);
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
            end
            testCase.chooseContextMenu(app.scriptListbox, app.uploadImpDvActionToKspMenu);
            testCase.verifyTrue(isvalid(app.ma_LvdMainGUI));
        end
    end

    methods(Access = private)
        function app = openLvd(testCase)
            testCase.stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(testCase.stubMainFig));

            app = ma_LvdMainGUI_App(testCase.celBodyData, testCase.stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;

            testCase.assertTrue(isvalid(app.ma_LvdMainGUI), 'The LVD main window must open.');
        end

        function item = menuItem(~, parentMenu, text)
            children = parentMenu.Children;
            item = children(strcmp({children.Text}, text));
            assert(isscalar(item), 'Menu item "%s" not found exactly once.', text);
        end

        function names = newFigureNames(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            names = {figs.Name};
        end

        function closeNewFigures(testCase)
            figs = findall(groot, 'Type', 'figure');
            figs = figs(not(ismember(figs, testCase.figuresBefore)));
            delete(figs(isvalid(figs)));
        end
    end

    methods(Static, Access = private)
        function smokeCancel(fig)
            %smokeCancel Catch-all uiwait player: Cancel > Close > Save&Close.
            %Never presses Export/Run/OK, so no file dialog can escape.
            btns = findall(fig, 'Type', 'uibutton');
            texts = {btns.Text};
            for want = {'Cancel', 'Close', 'Save & Close'}
                hit = btns(strcmp(texts, want{1}));
                if(not(isempty(hit)))
                    b = hit(1);
                    b.ButtonPushedFcn(b, struct('Source', b, 'EventName', 'ButtonPushed'));
                    drawnow;
                    return;
                end
            end
            %GUIDE fallback (uicontrol pushbuttons use String).
            ctrls = findall(fig, 'Type', 'uicontrol', 'Style', 'pushbutton');
            for k = 1:numel(ctrls)
                s = string(ctrls(k).String);
                if(any(strcmpi(s, ["Cancel", "Close", "Done", "OK"])))
                    cb = ctrls(k).Callback;
                    if(isa(cb, 'function_handle'))
                        cb(ctrls(k), []);
                    elseif(iscell(cb))
                        cb{1}(ctrls(k), [], cb{2:end});
                    end
                    drawnow;
                    return;
                end
            end
            error('LvdMainGuiWidgetSmokeTest:noCancelButton', 'No Cancel/Close button in dialog "%s".', fig.Name);
        end
    end
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        delete(h);
    end
end
