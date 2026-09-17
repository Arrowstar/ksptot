classdef LvdMainGuiInteractionTest < matlab.uitest.TestCase
    %LvdMainGuiInteractionTest App Testing Framework coverage of the LVD user
    %interactions touched by the 2026-09 enhancement work.
    %
    %   These tests drive the REAL Launch Vehicle Designer main window
    %   (ma_LvdMainGUI_App) and the real editor dialogs with
    %   matlab.uitest gestures (press, choose, type, chooseContextMenu),
    %   so a regression in callback wiring, in the enhancement menu items
    %   (real App Designer components of the main window), or in a dialog's
    %   controls shows up as a failing test rather than as a surprise in the
    %   running app.
    %
    %   Every LVD editor blocks in uiwait until the user closes it, which
    %   cannot be released from a timer under "matlab -batch".
    %   UiwaitInterceptorFixture therefore stands in for uiwait: when an app
    %   flow opens a dialog, a handler registered for that dialog's name
    %   plays the user (fills controls, presses Save & Close) at the moment
    %   the app would have blocked, and the flow then continues with the
    %   dialog's output set.  Dialogs opened directly by a test have no
    %   handler, so their constructors return the live app and the test
    %   applies gestures to it.

    properties(Access = private)
        celBodyData
        stubMainFig
        figuresBefore
        fixture UiwaitInterceptorFixture
    end

    methods(TestClassSetup)
        function setUpEnvironment(testCase)
            testCase.celBodyData = ksptotTestBodyData();

            %The LVD opening function listens on the global theme object the
            %KSPTOT launcher normally creates.
            global GLOBAL_AppThemer %#ok<GVMIS>
            if(isempty(GLOBAL_AppThemer) || not(isvalid(GLOBAL_AppThemer)))
                GLOBAL_AppThemer = AppThemer();
            end

            %Time display in the main window uses the configured time system.
            global ksptot_TimeSystem options_UseEarthTimeSystem %#ok<GVMIS>
            if(isempty(ksptot_TimeSystem))
                [rawIni, ~, ~] = inifile(fullfile(ksptotTestRoot(), 'bodies.ini'), 'readall');
                ksptot_TimeSystem = getTimeSystemFromConfig(getAppOptionsFromFile(), rawIni);
                options_UseEarthTimeSystem = strcmpi(ksptot_TimeSystem.system, 'earth_stock');
            end
        end
    end

    methods(TestMethodSetup)
        function interceptUiwait(testCase)
            testCase.fixture = testCase.applyFixture(UiwaitInterceptorFixture());
            testCase.figuresBefore = findall(groot, 'Type', 'figure');
            testCase.addTeardown(@() testCase.closeNewFigures());
        end
    end

    methods(Test)

        %% ------------------------------------------- main window: event list

        function insertSequentialEventAddsANewEvent(testCase)
            %The bug report that motivated this class: "Insert Sequential
            %Event" must create a NEW event, leaving the selected one alone.
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            existing = lvdData.script.getEventForInd(1);
            existing.name = 'Original Event';
            existingCond = existing.termCond;
            app.lvdEnhancementsRefresh(false);

            testCase.assertEqual(lvdData.script.getTotalNumOfEvents(), 1);
            testCase.assertEqual(numel(app.scriptListbox.Items), 1);

            %Play the user on the editor that opens for the new event: keep
            %the defaults and press Save & Close.  The list selection is left
            %exactly as the window opened with it (the bug report was against
            %a freshly opened default case).
            testCase.fixture.whenShown('Edit Event*', @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Save & Close'));

            testCase.press(app.insertEventButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEmpty(testCase.fixture.unhandled(), 'Every dialog the flow opened must have been handled.');

            testCase.verifyEqual(lvdData.script.getTotalNumOfEvents(), 2, 'Insert must add an event.');
            testCase.verifyEqual(numel(app.scriptListbox.Items), 2, 'The list box must show both events.');

            evts = lvdData.script.evts;
            testCase.verifyTrue(any(evts == existing), 'The original event must still be in the script.');
            testCase.verifyEqual(existing.name, 'Original Event', 'The original event must be untouched.');
            testCase.verifyTrue(existing.termCond == existingCond, 'The original event must be untouched.');

            newEvt = evts(evts ~= existing);
            testCase.verifyEqual(numel(newEvt), 1);
            testCase.verifyFalse(newEvt == existing, 'The inserted event must be a different object.');
            testCase.verifyEqual(newEvt.name, 'Untitled Event', 'Insert creates a default event.');
        end

        function editEventFromTheContextMenuEditsOnlyTheSelectedEvent(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            evt = lvdData.script.getEventForInd(1);
            evt.addTermCond(EventDurationTermCondition(50), EventTermCondDirectionEnum.NoDir);

            captured = containers.Map();
            testCase.fixture.whenShown('Edit Event*', @(fig) captureAndCancel(fig, captured));

            app.scriptListbox.Value = evt;
            testCase.chooseContextMenu(app.scriptListbox, app.EditEventMenu);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEqual(lvdData.script.getTotalNumOfEvents(), 1, 'Edit Event must not add an event.');
            testCase.assertTrue(captured.isKey('name'));
            testCase.verifyEqual(captured('name'), 'Edit Event #1', 'The editor must open on the selected event.');
            testCase.verifyEqual(captured('numConds'), 2, ...
                'The editor must list every termination condition the event has.');
        end

        function groupingAnEventFromTheEditEventWindowRefreshesTheList(testCase)
            %The advanced options live on the Advanced tab of the Edit Event
            %window; grouping an event there must show up in the script list.
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            evt = lvdData.script.getEventForInd(1);

            testCase.fixture.whenShown('Edit Event*', @(fig) groupAsAscentAndSave(fig));

            app.scriptListbox.Value = evt;
            testCase.chooseContextMenu(app.scriptListbox, app.EditEventMenu);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyEqual(evt.groupName, 'Ascent', 'Save & Close must write the group name to the event.');
            testCase.verifyTrue(startsWith(app.scriptListbox.Items{1}, '▼ [Ascent]'), ...
                'The list box must be refreshed with the group header.');
            testCase.verifyEqual(numel(testCase.contextMenuItem(app, 'Expand/Collapse Event Group')), 1);
            testCase.verifyEmpty(findall(app.scriptListboxContextMenu, 'Text', 'Advanced Event Options...'), ...
                'There is no separate advanced options dialog any more.');
        end

        function expandCollapseGroupFromTheContextMenu(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            evt = lvdData.script.getEventForInd(1);
            evt.groupName = 'Ascent';
            app.lvdEnhancementsRefresh(false);
            testCase.assertTrue(startsWith(app.scriptListbox.Items{1}, '▼ [Ascent]'));

            toggle = testCase.contextMenuItem(app, 'Expand/Collapse Event Group');

            app.scriptListbox.Value = evt;
            testCase.chooseContextMenu(app.scriptListbox, toggle);
            testCase.verifyTrue(lvdData.script.isGroupCollapsed('Ascent'));
            testCase.verifyTrue(startsWith(app.scriptListbox.Items{1}, '▶ [Ascent] (1 events)'));

            app.scriptListbox.Value = evt;
            testCase.chooseContextMenu(app.scriptListbox, toggle);
            testCase.verifyFalse(lvdData.script.isGroupCollapsed('Ascent'));
            testCase.verifyTrue(startsWith(app.scriptListbox.Items{1}, '▼ [Ascent]'));

            testCase.verifyEmpty(testCase.fixture.unhandled(), 'Collapsing must not open any dialog.');
        end

        function collapsingAnUngroupedEventShowsAnAlertAndChangesNothing(testCase)
            app = testCase.openLvd();
            lvdData = getappdata(app.ma_LvdMainGUI, 'lvdData');
            evt = lvdData.script.getEventForInd(1);
            testCase.assertEmpty(evt.groupName);

            app.scriptListbox.Value = evt;
            testCase.chooseContextMenu(app.scriptListbox, app.ToggleEventGroupMenu);

            testCase.verifyEmpty(lvdData.script.collapsedGroupNames, 'An ungrouped event has nothing to collapse.');
            testCase.verifyEqual(numel(app.scriptListbox.Items), 1);
            testCase.dismissAlertDialog(app.ma_LvdMainGUI);
        end

        %% -------------------------------------------- main window: menus

        function enhancementMenusAreCanvasComponentsInTheRightPlaces(testCase)
            %The enhancement menu items are components of the .mlapp (so they
            %appear on the App Designer canvas), each with a named callback and
            %a tooltip, and each sits where the design put it.
            app = testCase.openLvd();

            optTexts = flipud({app.optimizationMenu.Children.Text}');
            testCase.verifyEqual(optTexts(end-2:end), ...
                {'Variable Table...'; 'Constraint Status Table...'; 'Objective/Constraint Sensitivities...'}, ...
                'The three table/sensitivity items close the Optimization menu, in that order.');
            testCase.verifyEqual(app.VariableTableMenu.Separator, matlab.lang.OnOffSwitchState.on, ...
                'A separator keeps the new group distinct from the existing items.');

            fileTexts = flipud({app.fileMenu.Children.Text}');
            testCase.verifyEqual(fileTexts(end-1:end), {'Export Ephemeris...'; 'Exit Launch Vehicle Designer'}, ...
                'Exit stays last; Export Ephemeris goes immediately above it.');
            testCase.verifyEqual(app.ExportEphemerisMenu.Separator, matlab.lang.OnOffSwitchState.on);

            ctxTexts = flipud({app.scriptListboxContextMenu.Children.Text}');
            testCase.verifyEqual(ctxTexts(1:2), {'Edit Event'; 'Expand/Collapse Event Group'}, ...
                'Event editing belongs together at the top of the context menu.');
            testCase.verifyEqual(numel(ctxTexts), 12, 'Exactly one item is added to the context menu.');
            testCase.verifyFalse(any(contains(ctxTexts, 'Advanced Event Options')), ...
                'The advanced options live on the Edit Event window, not in a separate dialog.');

            menus = [app.VariableTableMenu, app.ConstraintTableMenu, app.SensitivityMenu, ...
                     app.ExportEphemerisMenu, app.ToggleEventGroupMenu];
            for(i = 1:numel(menus)) %#ok<*NO4LP>
                testCase.verifyClass(menus(i).MenuSelectedFcn, 'function_handle', ...
                    sprintf('"%s" must be wired to an App Designer callback.', menus(i).Text));
                testCase.verifyNotEmpty(menus(i).Tooltip, sprintf('"%s" must explain itself.', menus(i).Text));
            end
        end

        function optimizationMenuOpensTheVariableAndConstraintTables(testCase)
            app = testCase.openLvd();

            testCase.press(testCase.menuItem(app.optimizationMenu, 'Variable Table...'));
            testCase.press(testCase.menuItem(app.optimizationMenu, 'Constraint Status Table...'));

            names = testCase.newFigureNames();
            testCase.verifyTrue(any(strcmp(names, 'LVD Optimization Variables')), 'The variable table window must open.');
            testCase.verifyTrue(any(strcmp(names, 'LVD Constraint Status')), 'The constraint table window must open.');
        end

        function sensitivitiesMenuIsGracefulWithoutVariables(testCase)
            %The default mission has no optimization variables; the menu must
            %tell the user so rather than erroring.
            app = testCase.openLvd();
            testCase.press(testCase.menuItem(app.optimizationMenu, 'Objective/Constraint Sensitivities...'));
            testCase.verifyEmpty(testCase.fixture.unhandled());
            %An alert dialog is expected; dismiss it so the window is clean.
            try
                testCase.dismissAlertDialog(app.ma_LvdMainGUI);
            catch
                %no alert is also acceptable
            end
        end

        function exportEphemerisMenuOpensTheDialog(testCase)
            app = testCase.openLvd();

            seen = containers.Map();
            testCase.fixture.whenShown('Export Ephemeris', @(fig) recordAndCancel(fig, seen));

            testCase.press(testCase.menuItem(app.fileMenu, 'Export Ephemeris...'));

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Export Ephemeris'), 'The export dialog must open from the File menu.');

            texts = flipud({app.fileMenu.Children.Text}');
            testCase.verifyEqual(texts{end}, 'Exit Launch Vehicle Designer', 'Exit must stay last.');
            testCase.verifyEqual(texts{end-1}, 'Export Ephemeris...');
        end

        function editingANonSequentialEventShowsItsSettingsByGesture(testCase)
            %The Edit Event window opened for a non-sequential event shows the
            %Non-Sequential Event panel on its Advanced tab and saves it.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            innerEvt = LaunchVehicleEvent(lvdData.script);
            innerEvt.termCond = EventDurationTermCondition(300);
            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            lvdData.script.nonSeqEvts.addEvent(nonSeqEvt);
            out = AppDesignerGUIOutput({false});

            app = lvd_editEventGUI_App(innerEvt, true, out);
            testCase.addTeardown(@() deleteIfValid(app));

            testCase.verifyEqual(app.NonSeqPanel.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.termCondLogicCombo.Enable, matlab.lang.OnOffSwitchState.off, ...
                'Non-sequential events always fire on the first condition to cross.');

            testCase.choose(app.AdvancedTab);
            testCase.press(app.nonSeqEnabledCheckbox);         %on -> off
            testCase.verifyFalse(app.nonSeqEnabledCheckbox.Value);
            testCase.verifyEqual(app.nonSeqPriorityField.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.press(app.nonSeqEnabledCheckbox);         %off -> on
            app.nonSeqPriorityField.Value = 5;
            testCase.press(app.nonSeqLogExecCheckbox);
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(nonSeqEvt.enabled);
            testCase.verifyEqual(nonSeqEvt.priority, 5);
            testCase.verifyTrue(nonSeqEvt.logExecutions);
        end

        %% ------------------------------------ editor dialogs, real gestures

        function addDeltaVDialogSavesAPolarDeltaVByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            action = AddDeltaVAction([0.1; 0; 0], DeltaVFrameEnum.Inertial, false);
            out = AppDesignerGUIOutput({false});

            app = lvd_AddDeltaVActionGUI_App(action, lvdData, out);
            testCase.addTeardown(@() deleteIfValid(app));

            testCase.choose(app.paramTypeCombo, DeltaVParamTypeEnum.Polar.nameStr);
            testCase.verifyEqual(app.xCompLabel.Text, 'Magnitude', 'Choosing the polar form must relabel the components.');
            testCase.verifyEqual(app.text15.Text, 'deg');

            %Enter is bound to Save & Close in every LVD editor and the type
            %gesture finishes with Enter, which closes the dialog under the
            %gesture (and, in these GUIDE-migrated dialogs, before the field
            %commits its text).  Values are therefore entered directly and the
            %Save & Close press is the gesture under test.
            app.dvXCompText.Value = '500';
            app.dvYCompText.Value = '30';
            app.dvZCompText.Value = '-10';
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(action.paramType, DeltaVParamTypeEnum.Polar);
            testCase.verifyEqual(action.deltaVVect, [0.5; deg2rad(30); deg2rad(-10)], 'AbsTol', 1e-12);
        end

        function addDeltaVDialogOffersEveryFrameByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            action = AddDeltaVAction([0.1; 0.2; 0.3], DeltaVFrameEnum.Inertial, false);
            out = AppDesignerGUIOutput({false});

            app = lvd_AddDeltaVActionGUI_App(action, lvdData, out);
            testCase.addTeardown(@() deleteIfValid(app));

            testCase.choose(app.dvFrameCombo, DeltaVFrameEnum.OrbitRsw.nameStr);
            testCase.verifyEqual(app.xCompLabel.Text, 'Radial', 'Component labels must follow the frame.');
            testCase.verifyEqual(app.userFrameCombo.Enable, matlab.lang.OnOffSwitchState.off);

            testCase.choose(app.dvFrameCombo, DeltaVFrameEnum.UserFrame.nameStr);
            testCase.verifyEqual(app.userFrameCombo.Enable, matlab.lang.OnOffSwitchState.on, ...
                'The user frame picker enables only for the user-defined frame.');

            %No geometric frames exist in the default mission, so saving in
            %the user frame must be refused with an alert, not accepted.
            testCase.press(app.saveAndCloseButton);
            testCase.verifyFalse(out.output{1}, 'Saving without a user frame must be rejected.');
            testCase.dismissAlertDialog(app.lvd_AddDeltaVActionGUI);

            testCase.choose(app.dvFrameCombo, DeltaVFrameEnum.OrbitVnb.nameStr);
            testCase.press(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(action.frame, DeltaVFrameEnum.OrbitVnb);
        end

        function tankDialogEditsCapacityByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditTankGUI_App(tank, out);
            testCase.addTeardown(@() deleteIfValid(app));

            app.capacityText.Value = '20';
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(tank.capacity, 20);
        end

        function tankDialogRejectsANegativeCapacityByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditTankGUI_App(tank, out);
            testCase.addTeardown(@() deleteIfValid(app));

            app.capacityText.Value = '-5';
            testCase.press(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A negative capacity must not be saved.');
            testCase.verifyEqual(tank.capacity, 4, 'The stored capacity must be left alone.');
            testCase.dismissAlertDialog(app.lvd_EditTankGUI);
        end

        function tankDialogCapacityFollowsTheInitialMassByGesture(testCase)
            %The stock tank is full (capacity == initial mass).  Typing a new
            %initial mass moves the capacity with it, so the common case needs
            %one entry; a capacity the user has set apart stays put.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            tank = lvdData.launchVehicle.stages(1).tanks(1);
            testCase.assertEqual(tank.capacity, tank.initialMass);
            out = AppDesignerGUIOutput({false});

            app = lvd_EditTankGUI_App(tank, out);
            testCase.addTeardown(@() deleteIfValid(app));

            %The initial mass field is a GUIDE-migrated control, so its
            %callback is driven with a ValueChangedData event as the UI would.
            fireValueChanged(app.initPropMassText, '4', '6');
            testCase.verifyEqual(str2double(app.capacityText.Value), 6, 'The capacity must follow the initial mass while they are equal.');

            app.capacityText.Value = '9';
            fireValueChanged(app.initPropMassText, '6', '7');
            testCase.verifyEqual(str2double(app.capacityText.Value), 9, 'A capacity set apart from the initial mass must stay put.');

            testCase.press(app.saveAndCloseButton);
            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(tank.initialMass, 7);
            testCase.verifyEqual(tank.capacity, 9);
        end

        function throttleModelsDialogSelectsTheLimitedModelByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            throttleModels = ThrottleModelsSet();
            out = AppDesignerGUIOutput({false});

            app = lvd_EditThrottleModelsSet_App(throttleModels, lvdData, out, true);
            testCase.addTeardown(@() deleteIfValid(app));

            testCase.choose(app.ThrottleModelCombo, ThrottleModelEnum.Limited.nameStr);
            testCase.verifyEqual(app.ThrottleModelCombo.Value, ThrottleModelEnum.Limited);
            testCase.press(app.saveCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyTrue(isa(throttleModels.selectedModel, 'LimitedThrottleModel'));
        end

        function conditionalDialogTogglesTheQuantityAtEventControlsByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            frame = testCase.celBodyData.kerbin.getBodyCenteredInertialFrame();
            conditional = QuantityComparisonActionCondition(GraphicalAnalysisTask('Altitude', frame), 0, ComparisonTypeEnum.Equals, 0, frame);
            root = LogicalAndActionConditional(conditional);
            out = AppDesignerGUIOutput({root, false});

            app = lvd_EditActionConditionalGUI_App(root, lvdData, out);
            testCase.addTeardown(@() deleteIfValid(app));

            %Select the comparison node so its controls are live.
            node = testCase.findTreeNode(app.ConditionalTree, conditional);
            testCase.assertNotEmpty(node, 'The comparison must be in the tree.');
            testCase.choose(node);

            testCase.choose(app.CompareAgainstDropDown, CompareAgainstEnum.EventQuantity.name);
            testCase.verifyEqual(app.CompareEventDropDown.Enable, matlab.lang.OnOffSwitchState.on, ...
                'Quantity-at-event controls enable when that comparison target is chosen.');
            testCase.verifyEqual(conditional.compareAgainst, CompareAgainstEnum.EventQuantity);

            testCase.choose(app.CompareAgainstDropDown, CompareAgainstEnum.NumericConstant.name);
            testCase.verifyEqual(app.CompareEventDropDown.Enable, matlab.lang.OnOffSwitchState.off);
        end

        function editEventWindowAddsAConditionAndSetsLogicByGesture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            out = AppDesignerGUIOutput({false});

            %Add opens the per-condition editor for the new condition; play
            %the user and cancel it (the default duration condition stays).
            testCase.fixture.whenShown('Edit Termination Condition', @(fig) UiwaitInterceptorFixture.pushButton(fig, 'Cancel'));

            app = lvd_editEventGUI_App(evt, false, out);
            testCase.addTeardown(@() deleteIfValid(app));

            testCase.press(app.addTermCondButton);
            testCase.verifyEqual(evt.getNumTermConds(), 2, 'Add must append a condition.');
            testCase.verifyEqual(numel(app.termCondListbox.Items), 2);
            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));

            testCase.choose(app.termCondListbox, 1);
            testCase.choose(app.eventTermCondDirCombo, EventTermCondDirectionEnum.Increasing.name);
            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(dirs(1), EventTermCondDirectionEnum.Increasing, 'The direction applies to the selected condition at once.');

            testCase.choose(app.termCondLogicCombo, EventTermCondLogicEnum.All.name);
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1});
            testCase.verifyEqual(evt.termCondLogic, EventTermCondLogicEnum.All);
        end
    end

    methods(Access = private)
        function app = openLvd(testCase)
            %openLvd The real LVD main window on the default mission, with a
            %stub standing in for the KSPTOT main window it normally returns to.
            testCase.stubMainFig = figure('Visible', 'off', 'Name', 'KSPTOT main window stub');
            testCase.addTeardown(@() deleteIfValid(testCase.stubMainFig));

            app = ma_LvdMainGUI_App(testCase.celBodyData, testCase.stubMainFig);
            testCase.addTeardown(@() deleteIfValid(app));
            drawnow;

            testCase.assertTrue(isvalid(app.ma_LvdMainGUI), 'The LVD main window must open.');
        end

        function item = contextMenuItem(~, app, text)
            children = app.scriptListboxContextMenu.Children;
            item = children(strcmp({children.Text}, text));
            assert(isscalar(item), 'Context menu item "%s" not found exactly once.', text);
        end

        function item = menuItem(~, parentMenu, text)
            children = parentMenu.Children;
            item = children(strcmp({children.Text}, text));
            assert(isscalar(item), 'Menu item "%s" not found exactly once.', text);
        end

        function node = findTreeNode(testCase, tree, nodeData)
            node = [];
            nodes = findall(tree, 'Type', 'uitreenode');
            for i = 1:numel(nodes)
                if(isequal(nodes(i).NodeData, nodeData))
                    node = nodes(i);
                    return;
                end
            end
            testCase.assertFail('Tree node not found.');
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
end

function deleteIfValid(h)
    if(not(isempty(h)) && isvalid(h))
        delete(h);
    end
end

function captureAndCancel(fig, captured)
    %The event editor has no Cancel button (it is dismissed with the window
    %close box), so with nothing changed Save & Close is the way out.
    captured('name') = fig.Name; %#ok<NASGU> containers.Map is a handle
    %the termination condition list is the list box whose rows are numbered
    lbs = findall(fig, 'Type', 'uilistbox');
    numConds = 0;
    for k = 1:numel(lbs)
        if(not(isempty(lbs(k).Items)) && startsWith(lbs(k).Items{1}, '1.'))
            numConds = numel(lbs(k).Items);
        end
    end
    captured('numConds') = numConds; %#ok<NASGU>
    UiwaitInterceptorFixture.pushButton(fig, 'Save & Close');
end

function groupAsAscentAndSave(fig)
    %The group picker sits on the Advanced tab of the Edit Event window.
    dd = UiwaitInterceptorFixture.findDropDownWithItem(fig, '<No Group>');
    dd.Value = 'Ascent';
    UiwaitInterceptorFixture.pushButton(fig, 'Save & Close');
end

function fireValueChanged(field, previousValue, newValue)
    %Sets a text field and runs its ValueChangedFcn with the event the UI
    %would deliver (the type gesture cannot be used: it ends with Enter, which
    %every LVD editor binds to Save & Close).
    field.Value = newValue;
    %GUIDE-migrated callbacks locate their control through event.Source, so
    %the event is a struct carrying it (as UiwaitInterceptorFixture.pushButton does).
    evt = struct('Source', field, 'EventName', 'ValueChanged', 'Value', newValue, 'PreviousValue', previousValue);
    fcn = field.ValueChangedFcn;
    fcn(field, evt);
end

function recordAndCancel(fig, seen)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, 'Cancel');
end
