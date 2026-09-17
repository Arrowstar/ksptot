classdef EditEventDialogTest < matlab.uitest.TestCase
    %EditEventDialogTest The Edit Event window (lvd_editEventGUI_App) after
    %the advanced event options were put onto it as canvas components:
    %the termination condition list editor on the Event tab and the Group &
    %Notes / Event Limit Overrides / Non-Sequential Event panels on the
    %Advanced tab (A1, A6, A8, A10).
    %
    % The dialog blocks in uiwait; UiwaitInterceptorFixture stands in for
    % uiwait so the constructor returns the live app.  Buttons, check boxes,
    % lists and dropdowns are then driven with App Testing Framework
    % gestures (press / choose); numeric fields, the notes box and the
    % editable group picker are set directly because "type" ends with
    % Enter, which this window binds to Save & Close.

    properties(Access = private)
        celBodyData
        fixture UiwaitInterceptorFixture
        figuresBefore
    end

    methods(TestClassSetup)
        function loadBodies(testCase)
            testCase.celBodyData = ksptotTestBodyData();
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
        %% ------------------------------------------------ what it shows

        function theWindowHasAnEventTabAndAnAdvancedTab(testCase)
            [app, ~] = testCase.openFor(testCase.buildThreeCondEvent());

            testCase.verifyEqual({app.EventTabGroup.Children.Title}, {'Event', 'Advanced'});
            testCase.verifyTrue(app.EventTabGroup.SelectedTab == app.EventTab, 'The window opens on the Event tab.');
            testCase.verifyTrue(app.Panel.Parent == app.EventTabGrid, 'The original content sits inside the Event tab.');
            testCase.verifyEmpty(findall(app.lvd_editEventGUI, 'Tag', 'termCondNameLabel'), ...
                'The single-condition label is gone; the list replaces it.');
        end

        function theConditionListShowsEveryConditionWithItsDirection(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());

            items = app.termCondListbox.Items;
            conds = evt.getAllTermConds();
            dirs = evt.getAllTermCondDirs();
            testCase.assertEqual(numel(items), 3);
            for i = 1:3
                testCase.verifyTrue(startsWith(items{i}, sprintf('%u.', i)));
                testCase.verifyTrue(contains(items{i}, conds(i).getName()));
                testCase.verifyTrue(contains(items{i}, dirs(i).name));
            end

            testCase.verifyEqual(app.termCondListbox.Value, 1, 'Condition 1 is selected on open.');
            testCase.verifyEqual(app.eventTermCondDirCombo.Value, EventTermCondDirectionEnum.NoDir.name);
            testCase.verifyEqual(app.termCondLogicCombo.Value, EventTermCondLogicEnum.Any.name);
            testCase.verifyEqual(app.removeTermCondButton.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function selectingAConditionShowsItsOwnDirection(testCase)
            [app, ~] = testCase.openFor(testCase.buildThreeCondEvent());

            testCase.choose(app.termCondListbox, 3);
            testCase.verifyEqual(app.eventTermCondDirCombo.Value, EventTermCondDirectionEnum.Decreasing.name);

            testCase.choose(app.termCondListbox, 2);
            testCase.verifyEqual(app.eventTermCondDirCombo.Value, EventTermCondDirectionEnum.Increasing.name);
        end

        function theAdvancedTabShowsTheEventsGroupNotesAndLimits(testCase)
            evt = testCase.buildThreeCondEvent();
            evt.groupName = 'Ascent';
            evt.notes = sprintf('first line\nsecond line');
            evt.useEvtMinAltitude = true;
            evt.evtMinAltitude = 12.5;
            evt.minAltIsTerrainRelative = true;
            evt.useEvtMaxDur = true;
            evt.evtMaxDur = 300;
            evt.termCondLogic = EventTermCondLogicEnum.All;

            [app, ~] = testCase.openFor(evt);
            testCase.choose(app.AdvancedTab);

            testCase.verifyEqual(app.groupNameCombo.Value, 'Ascent');
            testCase.verifyEqual(app.notesTextArea.Value, {'first line'; 'second line'});
            testCase.verifyTrue(app.useMinAltCheckbox.Value);
            testCase.verifyEqual(app.minAltField.Value, 12.5);
            testCase.verifyTrue(app.terrainRelCheckbox.Value);
            testCase.verifyTrue(app.useMaxDurCheckbox.Value);
            testCase.verifyEqual(app.maxDurField.Value, 300);
            testCase.verifyEqual(app.termCondLogicCombo.Value, EventTermCondLogicEnum.All.name);
            testCase.verifyEqual(app.minAltField.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.maxDurField.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function theGroupPickerOffersEveryGroupAlreadyInTheScript(testCase)
            evt = testCase.buildThreeCondEvent();
            script = evt.script;
            other = LaunchVehicleEvent(script);
            other.termCond = EventDurationTermCondition(10);
            other.groupName = 'Coast';
            script.addEvent(other);

            [app, ~] = testCase.openFor(evt);

            testCase.verifyEqual(app.groupNameCombo.Items{1}, '<No Group>');
            testCase.verifyTrue(any(strcmp(app.groupNameCombo.Items, 'Coast')));
            testCase.verifyEqual(app.groupNameCombo.Value, '<No Group>');
            testCase.verifyEqual(app.groupNameCombo.Editable, matlab.lang.OnOffSwitchState.on, 'New group names can be typed.');
        end

        function limitFieldsFollowTheirCheckboxes(testCase)
            [app, ~] = testCase.openFor(testCase.buildThreeCondEvent());
            testCase.choose(app.AdvancedTab);

            testCase.verifyEqual(app.minAltField.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.terrainRelCheckbox.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.maxDurField.Enable, matlab.lang.OnOffSwitchState.off);

            testCase.press(app.useMinAltCheckbox);
            testCase.verifyTrue(app.useMinAltCheckbox.Value);
            testCase.verifyEqual(app.minAltField.Enable, matlab.lang.OnOffSwitchState.on);
            testCase.verifyEqual(app.terrainRelCheckbox.Enable, matlab.lang.OnOffSwitchState.on);

            testCase.press(app.useMaxDurCheckbox);
            testCase.verifyEqual(app.maxDurField.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function anUnfinishedMaxDurationShowsAsZero(testCase)
            evt = testCase.buildThreeCondEvent();
            evt.evtMaxDur = Inf;
            [app, ~] = testCase.openFor(evt);
            testCase.verifyEqual(app.maxDurField.Value, 0);
        end

        function theNonSequentialPanelIsHiddenForAnOrdinaryEvent(testCase)
            [app, ~] = testCase.openFor(testCase.buildThreeCondEvent());
            testCase.verifyEqual(app.NonSeqPanel.Visible, matlab.lang.OnOffSwitchState.off);
            testCase.verifyEqual(app.AdvancedTabGrid.RowHeight{3}, 0, 'The hidden panel must not leave a gap.');
            testCase.verifyEqual(app.termCondLogicCombo.Enable, matlab.lang.OnOffSwitchState.on);
        end

        function theNonSequentialPanelShowsTheWrappersSettingsAndLocksTheLogic(testCase)
            [~, nonSeqEvt] = testCase.buildNonSeqEvent();
            nonSeqEvt.enabled = false;
            nonSeqEvt.priority = 4;
            nonSeqEvt.logExecutions = true;
            nonSeqEvt.evt.termCondLogic = EventTermCondLogicEnum.All;

            app = testCase.openNonSeq(nonSeqEvt);

            testCase.verifyEqual(app.NonSeqPanel.Visible, matlab.lang.OnOffSwitchState.on);
            testCase.verifyFalse(app.nonSeqEnabledCheckbox.Value);
            testCase.verifyEqual(app.nonSeqPriorityField.Value, 4);
            testCase.verifyTrue(app.nonSeqLogExecCheckbox.Value);
            testCase.verifyEqual(app.nonSeqPriorityField.Enable, matlab.lang.OnOffSwitchState.off, ...
                'A disarmed event has no use for a priority.');

            testCase.verifyEqual(app.termCondLogicCombo.Value, EventTermCondLogicEnum.Any.name);
            testCase.verifyEqual(app.termCondLogicCombo.Enable, matlab.lang.OnOffSwitchState.off, ...
                'Non-sequential events always fire on the first condition to cross.');
        end

        %% --------------------------------------- editing the condition list

        function addingAConditionAppendsItAndOpensItsEditor(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());

            seen = containers.Map();
            testCase.fixture.whenShown('Edit Termination Condition', @(fig) recordAndPush(fig, seen, 'Cancel'));

            testCase.press(app.addTermCondButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.verifyTrue(seen.isKey('Edit Termination Condition'), 'Add must open the editor for the new condition.');
            testCase.verifyEqual(evt.getNumTermConds(), 4);
            testCase.verifyEqual(numel(app.termCondListbox.Items), 4);
            testCase.verifyEqual(app.termCondListbox.Value, 4, 'The new condition is selected.');
            conds = evt.getAllTermConds();
            testCase.verifyClass(conds(4), 'EventDurationTermCondition');
        end

        function removingAConditionDropsTheSelectedOneAndItsDirection(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());

            testCase.choose(app.termCondListbox, 2);
            testCase.press(app.removeTermCondButton);

            testCase.verifyEqual(evt.getNumTermConds(), 2);
            conds = evt.getAllTermConds();
            testCase.verifyClass(conds(1), 'EventDurationTermCondition');
            testCase.verifyClass(conds(2), 'AltitudeTermCondition');
            testCase.verifyEqual(evt.getAllTermCondDirs(), [EventTermCondDirectionEnum.NoDir, EventTermCondDirectionEnum.Decreasing], ...
                'The removed condition''s direction goes with it.');
            testCase.verifyEqual(numel(app.termCondListbox.Items), 2);
            testCase.verifyEqual(app.termCondListbox.Value, 2, 'Selection stays on the same row.');
        end

        function theLastConditionCannotBeRemoved(testCase)
            evt = testCase.buildThreeCondEvent();
            evt.removeTermCondByInd(3);
            evt.removeTermCondByInd(2);
            [app, evt] = testCase.openFor(evt);

            testCase.verifyEqual(app.removeTermCondButton.Enable, matlab.lang.OnOffSwitchState.off, ...
                'The only condition cannot be removed.');
            testCase.verifyEqual(evt.getNumTermConds(), 1);
        end

        function editingASelectedConditionUsesTheSingleConditionEditor(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());
            conds = evt.getAllTermConds();
            cond2 = conds(2);

            editedOn = containers.Map();
            testCase.fixture.whenShown('Edit Termination Condition', @(fig) captureEditedCondition(fig, evt, editedOn));

            testCase.choose(app.termCondListbox, 2);
            testCase.press(app.editTermCondParamsButton);

            testCase.verifyEmpty(testCase.fixture.errors(), strjoin(testCase.fixture.errors(), newline));
            testCase.assertTrue(editedOn.isKey('termCond'));
            testCase.verifyTrue(editedOn('termCond') == cond2, ...
                'While the editor is open, event.termCond must be the selected condition (the editor only edits termCond).');
            conds = evt.getAllTermConds();
            testCase.verifyClass(conds(1), 'EventDurationTermCondition', 'Condition 1 must be restored afterwards.');
            testCase.verifyTrue(conds(2) == cond2);
        end

        function changingTheDirectionWritesItStraightToTheEvent(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());

            testCase.choose(app.termCondListbox, 2);
            testCase.choose(app.eventTermCondDirCombo, EventTermCondDirectionEnum.Decreasing.name);

            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(dirs(2), EventTermCondDirectionEnum.Decreasing);
            testCase.verifyEqual(dirs([1 3]), [EventTermCondDirectionEnum.NoDir, EventTermCondDirectionEnum.Decreasing]);
            testCase.verifyTrue(contains(app.termCondListbox.Items{2}, EventTermCondDirectionEnum.Decreasing.name), ...
                'The list row must be relabelled with the new direction.');
        end

        %% --------------------------------------------------------- saving

        function saveAndCloseWritesEveryAdvancedFieldToTheEvent(testCase)
            [app, evt, out] = testCase.openFor(testCase.buildThreeCondEvent());
            fig = app.lvd_editEventGUI;

            testCase.choose(app.termCondLogicCombo, EventTermCondLogicEnum.All.name);
            testCase.choose(app.AdvancedTab);
            app.groupNameCombo.Value = 'Boostback';
            app.notesTextArea.Value = {'check the grid fins'; 'then relight'};
            testCase.press(app.useMinAltCheckbox);
            app.minAltField.Value = 7.5;
            testCase.press(app.terrainRelCheckbox);
            testCase.press(app.useMaxDurCheckbox);
            app.maxDurField.Value = 33;

            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(out.output{1}, 'Save & Close must report that the event changed.');
            testCase.verifyFalse(isvalid(fig), 'Save & Close must close the window.');
            testCase.verifyEqual(evt.termCondLogic, EventTermCondLogicEnum.All);
            testCase.verifyEqual(evt.groupName, 'Boostback');
            testCase.verifyEqual(evt.notes, sprintf('check the grid fins\nthen relight'));
            testCase.verifyTrue(evt.useEvtMinAltitude);
            testCase.verifyEqual(evt.evtMinAltitude, 7.5);
            testCase.verifyTrue(evt.minAltIsTerrainRelative);
            testCase.verifyTrue(evt.useEvtMaxDur);
            testCase.verifyEqual(evt.evtMaxDur, 33);
        end

        function theNoGroupPlaceholderSavesAsAnEmptyGroupNameAndEmptyNotesTrim(testCase)
            evt = testCase.buildThreeCondEvent();
            evt.groupName = 'Ascent';
            [app, evt] = testCase.openFor(evt);

            testCase.choose(app.AdvancedTab);
            testCase.choose(app.groupNameCombo, '<No Group>');
            app.notesTextArea.Value = {''};
            testCase.press(app.saveAndCloseButton);

            testCase.verifyEqual(evt.groupName, '', 'The placeholder stands for no group.');
            testCase.verifyEqual(evt.notes, '', 'Empty notes save as an empty char row.');
        end

        function aTypedGroupNameIsTrimmedAndKept(testCase)
            [app, evt] = testCase.openFor(testCase.buildThreeCondEvent());
            testCase.choose(app.AdvancedTab);
            app.groupNameCombo.Value = '  Entry Burn  ';
            testCase.press(app.saveAndCloseButton);
            testCase.verifyEqual(evt.groupName, 'Entry Burn');
        end

        function anUncheckedMaximumDurationLeavesTheStoredValueAlone(testCase)
            evt = testCase.buildThreeCondEvent();
            evt.useEvtMaxDur = true;
            evt.evtMaxDur = 600;
            [app, evt] = testCase.openFor(evt);

            testCase.choose(app.AdvancedTab);
            testCase.press(app.useMaxDurCheckbox);   %on -> off
            testCase.press(app.saveAndCloseButton);

            testCase.verifyFalse(evt.useEvtMaxDur);
            testCase.verifyEqual(evt.evtMaxDur, 600, 'Clearing the override must not overwrite the stored duration.');
        end

        function saveAndCloseWritesTheNonSequentialSettings(testCase)
            [~, nonSeqEvt] = testCase.buildNonSeqEvent();
            app = testCase.openNonSeq(nonSeqEvt);

            testCase.choose(app.AdvancedTab);
            testCase.press(app.nonSeqEnabledCheckbox);   %on -> off
            testCase.verifyEqual(app.nonSeqPriorityField.Enable, matlab.lang.OnOffSwitchState.off);
            testCase.press(app.nonSeqEnabledCheckbox);   %off -> on
            app.nonSeqPriorityField.Value = -3;
            testCase.press(app.nonSeqLogExecCheckbox);
            testCase.press(app.saveAndCloseButton);

            testCase.verifyTrue(nonSeqEvt.enabled);
            testCase.verifyEqual(nonSeqEvt.priority, -3);
            testCase.verifyTrue(nonSeqEvt.logExecutions);
            testCase.verifyEqual(nonSeqEvt.evt.termCondLogic, EventTermCondLogicEnum.Any, ...
                'Saving a non-sequential event normalizes its logic to Any.');
        end

        %% ----------------------------------------------------- validation

        function anOverriddenMaximumDurationMustBePositiveAndFinite(testCase)
            [app, evt, out] = testCase.openFor(testCase.buildThreeCondEvent());
            fig = app.lvd_editEventGUI;

            testCase.choose(app.AdvancedTab);
            testCase.press(app.useMaxDurCheckbox);
            app.maxDurField.Value = 0;
            testCase.press(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1}, 'A zero maximum duration must be refused.');
            testCase.verifyTrue(isvalid(fig), 'The window must stay open so the user can fix the value.');
            testCase.verifyFalse(evt.useEvtMaxDur, 'Nothing may be written when validation fails.');
        end

        function anOverriddenMinimumAltitudeMustBeFinite(testCase)
            [app, evt, out] = testCase.openFor(testCase.buildThreeCondEvent());

            testCase.choose(app.AdvancedTab);
            testCase.press(app.useMinAltCheckbox);
            app.minAltField.Value = Inf;
            testCase.press(app.saveAndCloseButton);

            testCase.verifyFalse(out.output{1});
            testCase.verifyFalse(evt.useEvtMinAltitude);
        end
    end

    methods(Access = private)
        function evt = buildThreeCondEvent(testCase)
            %A duration, an altitude and a second altitude, with three
            %different crossing directions so index mix-ups are visible.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);

            evt.termCond = EventDurationTermCondition(100);
            evt.termCondDir = EventTermCondDirectionEnum.NoDir;

            evt.extraTermConds = AbstractEventTerminationCondition.empty(1,0);
            evt.extraTermCondDirs = EventTermCondDirectionEnum.empty(1,0);
            evt.addTermCond(AltitudeTermCondition(70), EventTermCondDirectionEnum.Increasing);
            evt.addTermCond(AltitudeTermCondition(10), EventTermCondDirectionEnum.Decreasing);
        end

        function [lvdData, nonSeqEvt] = buildNonSeqEvent(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            innerEvt = LaunchVehicleEvent(script);
            innerEvt.name = 'Non-seq';
            innerEvt.termCond = EventDurationTermCondition(300);

            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            script.nonSeqEvts.addEvent(nonSeqEvt);
        end

        function [app, evt, out] = openFor(testCase, evt)
            out = AppDesignerGUIOutput({false});
            app = lvd_editEventGUI_App(evt, false, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
        end

        function app = openNonSeq(testCase, nonSeqEvt)
            out = AppDesignerGUIOutput({false});
            app = lvd_editEventGUI_App(nonSeqEvt.evt, true, out);
            drawnow;
            testCase.addTeardown(@() deleteIfValid(app));
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

function recordAndPush(fig, seen, buttonText)
    seen(fig.Name) = true; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, buttonText);
end

function captureEditedCondition(fig, evt, editedOn)
    editedOn('termCond') = evt.termCond; %#ok<NASGU> containers.Map is a handle
    UiwaitInterceptorFixture.pushButton(fig, 'Cancel');
end
