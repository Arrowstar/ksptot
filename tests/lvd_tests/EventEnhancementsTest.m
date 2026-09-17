classdef EventEnhancementsTest < KsptotTestCase
    %EventEnhancementsTest Covers the LVD event-model enhancements A1, A6, A8 and A10.
    %
    % A1  Multiple termination conditions per event, combined with Any or
    %     All logic, and a record in the state log of which condition fired.
    % A6  Event groups (collapsible in the script list box) and per-event notes.
    % A8  Non-sequential events: explicit enable toggle, priority ordering,
    %     and opt-in logging of the discontinuity they introduce.
    % A10 Per-event overrides of the global maximum duration and minimum
    %     altitude, plus a terrain-relative minimum altitude.
    %
    % Every propagation check here uses the two-body propagator on the
    % default LVD mission, so an event's end time is an exact, analytically
    % known quantity (t0 + duration) rather than something that depends on
    % the force model.  Backward-compatibility checks are explicit: the
    % defaults of all new properties must reproduce the pre-enhancement
    % behavior, which is what keeps the example-mission goldens bit-identical.

    properties(Constant)
        EvtDur = 500;   %s, the base coast length used by most fixtures
        Tol = 1e-9;
    end

    methods(Test)

        %% ================================================== A1: data model

        function singleConditionEventLooksUnchanged(testCase)
            %The historical shape of an event: exactly one condition, Any
            %logic, no latches consulted.
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);

            testCase.verifyEqual(evt.getNumTermConds(), 1);
            testCase.verifyEqual(evt.termCondLogic, EventTermCondLogicEnum.Any, ...
                'Any must be the default so existing missions keep their behavior.');
            testCase.verifyEmpty(evt.extraTermConds);
            testCase.verifyEmpty(evt.extraTermCondDirs);

            allConds = evt.getAllTermConds();
            testCase.verifyEqual(numel(allConds), 1);
            testCase.verifyTrue(allConds(1) == evt.termCond, ...
                'Condition 1 must still be the stored termCond object.');

            allDirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(numel(allDirs), 1);
            testCase.verifyEqual(allDirs(1), evt.termCondDir);
        end

        function addAndRemoveTerminationConditions(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            cond1 = evt.termCond;

            cond2 = EventDurationTermCondition(100);
            evt.addTermCond(cond2, EventTermCondDirectionEnum.Increasing);

            cond3 = EventDurationTermCondition(200);
            evt.addTermCond(cond3);   %direction omitted -> NoDir

            testCase.verifyEqual(evt.getNumTermConds(), 3);

            allConds = evt.getAllTermConds();
            testCase.verifyTrue(allConds(1) == cond1);
            testCase.verifyTrue(allConds(2) == cond2);
            testCase.verifyTrue(allConds(3) == cond3);

            allDirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(allDirs(1), evt.termCondDir);
            testCase.verifyEqual(allDirs(2), EventTermCondDirectionEnum.Increasing);
            testCase.verifyEqual(allDirs(3), EventTermCondDirectionEnum.NoDir, ...
                'addTermCond must default an omitted direction to NoDir.');

            %Removing a middle condition leaves the others in order.
            evt.removeTermCondByInd(2);
            allConds = evt.getAllTermConds();
            testCase.verifyEqual(evt.getNumTermConds(), 2);
            testCase.verifyTrue(allConds(1) == cond1);
            testCase.verifyTrue(allConds(2) == cond3);
        end

        function removingConditionOnePromotesConditionTwo(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            cond2 = EventDurationTermCondition(100);
            evt.addTermCond(cond2, EventTermCondDirectionEnum.Decreasing);

            evt.removeTermCondByInd(1);

            testCase.verifyEqual(evt.getNumTermConds(), 1);
            testCase.verifyTrue(evt.termCond == cond2, ...
                'Removing condition 1 must promote condition 2 into termCond.');
            testCase.verifyEqual(evt.termCondDir, EventTermCondDirectionEnum.Decreasing, ...
                'The promoted condition must bring its direction with it.');
            testCase.verifyEmpty(evt.extraTermConds);
        end

        function cannotRemoveTheOnlyTerminationCondition(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            cond1 = evt.termCond;

            evt.removeTermCondByInd(1);
            testCase.verifyEqual(evt.getNumTermConds(), 1);
            testCase.verifyTrue(evt.termCond == cond1, ...
                'An event must always keep at least one termination condition.');

            %Out-of-range indices are ignored rather than erroring.
            evt.addTermCond(EventDurationTermCondition(100));
            evt.removeTermCondByInd(0);
            evt.removeTermCondByInd(99);
            testCase.verifyEqual(evt.getNumTermConds(), 2);
        end

        function mismatchedDirectionArrayIsNormalized(testCase)
            %A hand-edited or partially constructed mission may have fewer
            %(or more) directions than conditions; getAllTermCondDirs must
            %still hand the integrator one direction per condition.
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            evt.extraTermConds = [EventDurationTermCondition(10), EventDurationTermCondition(20)];
            evt.extraTermCondDirs = EventTermCondDirectionEnum.empty(1,0);

            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(numel(dirs), 3);
            testCase.verifyEqual(dirs(2), EventTermCondDirectionEnum.NoDir);
            testCase.verifyEqual(dirs(3), EventTermCondDirectionEnum.NoDir);

            evt.extraTermCondDirs = repmat(EventTermCondDirectionEnum.Increasing, 1, 5);
            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(numel(dirs), 3, ...
                'Surplus directions must be trimmed to the condition count.');
        end

        %% =============================================== A1: latch + active list

        function activeConditionListUnderAnyLogic(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            evt.addTermCond(EventDurationTermCondition(100));
            evt.termCondLogic = EventTermCondLogicEnum.Any;

            %Latches are irrelevant to Any logic: everything stays armed.
            evt.latchTermCond(1);

            [fhs, dirs, condInds] = evt.getActiveTermCondFuncHandles();
            testCase.verifyEqual(numel(fhs), 2);
            testCase.verifyEqual(numel(dirs), 2);
            testCase.verifyEqual(condInds, [1 2]);
            testCase.verifyClass(fhs, 'cell');
            testCase.verifyClass(fhs{1}, 'function_handle');
        end

        function activeConditionListUnderAllLogicDropsLatched(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            evt.addTermCond(EventDurationTermCondition(100));
            evt.addTermCond(EventDurationTermCondition(200));
            evt.termCondLogic = EventTermCondLogicEnum.All;

            testCase.verifyEqual(numel(evt.getActiveTermCondFuncHandles()), 3);

            evt.latchTermCond(2);
            [fhs, ~, condInds] = evt.getActiveTermCondFuncHandles();
            testCase.verifyEqual(numel(fhs), 2);
            testCase.verifyEqual(condInds, [1 3], ...
                'A latched condition must be dropped, and the map must point at the survivors.');

            %All latched: the integrator still needs one terminal event, so
            %the last condition is kept as a fallback.
            evt.latchTermCond(1);
            evt.latchTermCond(3);
            testCase.verifyTrue(evt.allTermCondsLatched());
            [fhs, ~, condInds] = evt.getActiveTermCondFuncHandles();
            testCase.verifyEqual(numel(fhs), 1);
            testCase.verifyEqual(condInds, 3);
        end

        function latchesResetOnInitButNotOnRestart(testCase)
            [lvdData, evt] = testCase.buildCoastMission(testCase.EvtDur);
            evt.addTermCond(EventDurationTermCondition(100));
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.event = evt;

            evt.latchTermCond(1);
            testCase.verifyEqual(evt.getTermCondLatches(), [true false]);

            evt.initEventOnRestart(entry);
            testCase.verifyEqual(evt.getTermCondLatches(), [true false], ...
                'A restart continues the same event, so latches must survive it.');

            evt.initEvent(entry);
            testCase.verifyEqual(evt.getTermCondLatches(), [false false], ...
                'Starting the event afresh must clear every latch.');
        end

        function latchArrayResizesWithConditionCount(testCase)
            [~, evt] = testCase.buildCoastMission(testCase.EvtDur);
            testCase.verifyEqual(evt.getTermCondLatches(), false);

            evt.addTermCond(EventDurationTermCondition(100));
            testCase.verifyEqual(evt.getTermCondLatches(), [false false], ...
                'The latch array must follow the condition count without an explicit reset.');

            %Out-of-range latch indices are ignored.
            evt.latchTermCond(7);
            testCase.verifyEqual(evt.getTermCondLatches(), [false false]);
        end

        function logicEnumListboxRoundTrip(testCase)
            strs = EventTermCondLogicEnum.getListboxStr();
            testCase.verifyEqual(numel(strs), 2);

            for(i=1:numel(strs)) %#ok<*NO4LP>
                [enumVal, ind] = EventTermCondLogicEnum.getEnumForListboxStr(strs{i});
                testCase.verifyEqual(ind, i);
                testCase.verifyEqual(enumVal.name, strs{i});
            end

            testCase.verifyEqual(EventTermCondLogicEnum.getEnumForListboxStr(strs{1}), ...
                EventTermCondLogicEnum.Any);
        end

        %% ================================================ A1: propagation

        function anyLogicEndsAtTheFirstConditionToFire(testCase)
            [lvdData, evt] = testCase.buildCoastMission(1000);
            evt.addTermCond(EventDurationTermCondition(300));
            evt.termCondLogic = EventTermCondLogicEnum.Any;

            stateLog = testCase.runScript(lvdData);
            entries = stateLog.entries;
            t0 = entries(1).time;

            testCase.verifyEqual(entries(end).time - t0, 300, 'AbsTol', 1e-6, ...
                'Any logic must end the event when the earliest condition fires.');
        end

        function allLogicWaitsForEveryCondition(testCase)
            [lvdData, evt] = testCase.buildCoastMission(700);
            evt.addTermCond(EventDurationTermCondition(300));
            evt.termCondLogic = EventTermCondLogicEnum.All;

            stateLog = testCase.runScript(lvdData);
            entries = stateLog.entries;
            t0 = entries(1).time;

            testCase.verifyEqual(entries(end).time - t0, 700, 'AbsTol', 1e-6, ...
                'All logic must keep propagating until the last condition fires.');
            testCase.verifyTrue(evt.allTermCondsLatched(), ...
                'Every condition must be latched once the event completes.');
        end

        function allLogicIsOrderIndependent(testCase)
            %The same pair of conditions in the opposite order must end at
            %the same time: "All" is about the last condition, not the list
            %position.
            [lvdDataA, evtA] = testCase.buildCoastMission(300);
            evtA.addTermCond(EventDurationTermCondition(700));
            evtA.termCondLogic = EventTermCondLogicEnum.All;

            [lvdDataB, evtB] = testCase.buildCoastMission(700);
            evtB.addTermCond(EventDurationTermCondition(300));
            evtB.termCondLogic = EventTermCondLogicEnum.All;

            entriesA = testCase.runScript(lvdDataA).entries;
            entriesB = testCase.runScript(lvdDataB).entries;

            durA = entriesA(end).time - entriesA(1).time;
            durB = entriesB(end).time - entriesB(1).time;

            testCase.verifyEqual(durA, 700, 'AbsTol', 1e-6);
            testCase.verifyEqual(durB, 700, 'AbsTol', 1e-6);
            testCase.verifyEqual(durA, durB, 'AbsTol', 1e-9);
        end

        function stateLogRecordsWhichConditionFired(testCase)
            [lvdData, evt] = testCase.buildCoastMission(1000);
            cond2 = EventDurationTermCondition(250);
            evt.addTermCond(cond2);

            stateLog = testCase.runScript(lvdData);
            finalEntry = stateLog.entries(end);

            testCase.verifyEqual(finalEntry.termCondFiredInd, 2, ...
                'The state log must identify the condition that actually fired.');
            testCase.verifyEqual(finalEntry.termCondFiredName, char(cond2.getName()));
        end

        function firedConditionRecordDefaultsToUnset(testCase)
            %Entries that do not close out a segment, and segments that end
            %for a reason other than a termination condition, carry no record.
            entry = LaunchVehicleStateLogEntry();
            testCase.verifyEqual(entry.termCondFiredInd, 0);
            testCase.verifyEqual(entry.termCondFiredName, '');

            [lvdData, ~] = testCase.buildCoastMission(400);
            stateLog = testCase.runScript(lvdData);
            entries = stateLog.entries;

            testCase.verifyEqual(entries(1).termCondFiredInd, 0, ...
                'Only the entry that ends a segment may carry the fired-condition record.');
            testCase.verifyEqual(entries(end).termCondFiredInd, 1);
        end

        function firedConditionRecordSurvivesDeepCopy(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();

            entry.termCondFiredInd = 3;
            entry.termCondFiredName = 'Some Condition';

            copied = entry.deepCopy();
            testCase.verifyEqual(copied.termCondFiredInd, 3);
            testCase.verifyEqual(copied.termCondFiredName, 'Some Condition');
        end

        function multipleConditionsDoNotPerturbTheSingleConditionResult(testCase)
            %Backward compatibility: adding the multi-condition machinery
            %must not move a single-condition event's trajectory at all.
            [lvdDataRef, ~] = testCase.buildCoastMission(400);
            entriesRef = testCase.runScript(lvdDataRef).entries;

            [lvdDataDup, evtDup] = testCase.buildCoastMission(400);
            %A second, identical condition under Any logic fires at the same
            %instant, so the trajectory must be bit-identical.
            evtDup.addTermCond(EventDurationTermCondition(400));
            entriesDup = testCase.runScript(lvdDataDup).entries;

            testCase.verifyEqual(numel(entriesDup), numel(entriesRef));
            testCase.verifyTrue(isequaln([entriesRef.time], [entriesDup.time]), ...
                'A duplicate condition must not change the integration at all.');
            testCase.verifyTrue(isequaln([entriesRef.position], [entriesDup.position]));
        end

        function termCondSummaryStringCountsTheExtraConditions(testCase)
            %The event editor shows this in place of condition 1's bare name.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);

            testCase.verifyEqual(evt.getTermCondSummaryStr(), evt.termCond.getName(), ...
                'With one condition the summary must be exactly the condition name (the pre-A1 label).');

            evt.addTermCond(AltitudeTermCondition(70), EventTermCondDirectionEnum.Increasing);
            evt.addTermCond(AltitudeTermCondition(10), EventTermCondDirectionEnum.Decreasing);

            str = evt.getTermCondSummaryStr();
            testCase.verifyTrue(startsWith(str, evt.termCond.getName()));
            testCase.verifyTrue(contains(str, '+2 more'));
            testCase.verifyTrue(contains(str, 'first to fire'));

            evt.termCondLogic = EventTermCondLogicEnum.All;
            testCase.verifyTrue(contains(evt.getTermCondSummaryStr(), 'all must fire'));
        end

        %% ============================================= A1: rollups over conditions

        function usesQueriesConsultEveryCondition(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            tank = lvdData.launchVehicle.stages(1).tanks(1);

            evt.termCond = EventDurationTermCondition(100);
            testCase.verifyFalse(evt.usesTank(tank));

            evt.addTermCond(TankMassTermCondition(tank, 0));
            testCase.verifyTrue(evt.usesTank(tank), ...
                'usesTank must look past condition 1 into the extra conditions.');
        end

        function optimizationVariableRollupSeesExtraConditions(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);

            extraCond = EventDurationTermCondition(200);
            evt.addTermCond(extraCond);

            var = EventDurationOptimizationVariable(extraCond);
            var.useTf = true;
            var.lb = 10;
            var.ub = 1000;
            lvdData.optimizer.vars.addVariable(var);

            evt.clearActiveOptVarsCache();
            [tf, vars] = evt.hasActiveOptVars();

            testCase.verifyTrue(tf, 'An optimization variable on an extra condition must count.');
            testCase.verifyTrue(any(vars == var));
        end

        function removingAConditionRemovesItsOptimizationVariable(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(100);

            extraCond = EventDurationTermCondition(200);
            evt.addTermCond(extraCond);

            var = EventDurationOptimizationVariable(extraCond);
            var.useTf = true;
            var.lb = 10;
            var.ub = 1000;
            lvdData.optimizer.vars.addVariable(var);
            numVarsBefore = numel(lvdData.optimizer.vars.vars);

            evt.removeTermCondByInd(2);

            numVarsAfter = numel(lvdData.optimizer.vars.vars);
            testCase.verifyEqual(numVarsAfter, numVarsBefore - 1, ...
                'Removing a condition must remove the optimization variable attached to it.');
        end

        function deletingAnEventRemovesEveryConditionVariable(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(100);

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(100);
            extraCond = EventDurationTermCondition(200);
            evt2.addTermCond(extraCond);
            lvdData.script.addEvent(evt2);

            for(cond = [evt2.termCond, extraCond])
                var = EventDurationOptimizationVariable(cond);
                var.useTf = true;
                var.lb = 10;
                var.ub = 1000;
                lvdData.optimizer.vars.addVariable(var);
            end
            testCase.assertEqual(numel(lvdData.optimizer.vars.vars), 2);

            lvdData.script.removeEvent(evt2);

            testCase.verifyEmpty(lvdData.optimizer.vars.vars, ...
                'Deleting an event must clean up the variables of all of its conditions.');
        end

        %% ================================ script editing with no selection

        function addEventAtIndAppendsWhenNoIndexIsGiven(testCase)
            %The main window's Insert button passes the selected event's
            %index; with nothing selected that is empty.  Empty (and invalid)
            %indices must append rather than replace the whole event list,
            %which is what [evts(1:[]), new, evts([]+1:end)] silently did.
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;
            originals = script.evts;

            newEvt = LaunchVehicleEvent(script);
            newEvt.name = 'Appended';
            script.addEventAtInd(newEvt, []);

            testCase.verifyEqual(script.getTotalNumOfEvents(), 5, 'An empty index must append, not replace.');
            testCase.verifyTrue(all(ismember(originals, script.evts)), 'Every original event must survive.');
            testCase.verifyTrue(script.getEventForInd(5) == newEvt, 'The new event goes at the end.');

            %Out of range and NaN behave the same way.
            evt6 = LaunchVehicleEvent(script);
            script.addEventAtInd(evt6, 99);
            evt7 = LaunchVehicleEvent(script);
            script.addEventAtInd(evt7, NaN);
            testCase.verifyEqual(script.getTotalNumOfEvents(), 7);
            testCase.verifyTrue(script.getEventForInd(6) == evt6);
            testCase.verifyTrue(script.getEventForInd(7) == evt7);

            %A valid index still inserts right after that event, and 0 first.
            evtMid = LaunchVehicleEvent(script);
            script.addEventAtInd(evtMid, 2);
            testCase.verifyTrue(script.getEventForInd(3) == evtMid);
            testCase.verifyEqual(script.getTotalNumOfEvents(), 8);

            evtFirst = LaunchVehicleEvent(script);
            script.addEventAtInd(evtFirst, 0);
            testCase.verifyTrue(script.getEventForInd(1) == evtFirst);
            testCase.verifyEqual(script.getTotalNumOfEvents(), 9);
        end

        function nonSeqAddEventAtIndAppendsWhenNoIndexIsGiven(testCase)
            %Same guard for the non-sequential list, whose Insert button has
            %the identical selected-index arithmetic.
            [lvdData, nonSeqA] = testCase.buildNonSeqMission(300, false);
            nonSeqB = testCase.addNonSeqEvent(lvdData, 400, false);
            list = lvdData.script.nonSeqEvts;
            testCase.assertEqual(list.getTotalNumOfEvents(), 2);

            newEvt = LaunchVehicleNonSeqEvent(LaunchVehicleEvent(lvdData.script));
            list.addEventAtInd(newEvt, []);

            testCase.verifyEqual(list.getTotalNumOfEvents(), 3, 'An empty index must append, not replace.');
            testCase.verifyTrue(list.getEventForInd(1) == nonSeqA);
            testCase.verifyTrue(list.getEventForInd(2) == nonSeqB);
            testCase.verifyTrue(list.getEventForInd(3) == newEvt);

            mid = LaunchVehicleNonSeqEvent(LaunchVehicleEvent(lvdData.script));
            list.addEventAtInd(mid, 1);
            testCase.verifyTrue(list.getEventForInd(2) == mid, 'A valid index still inserts after that event.');
            testCase.verifyEqual(list.getTotalNumOfEvents(), 4);
        end

        %% ===================================================== A6: groups & notes

        function groupMembershipAndEnumeration(testCase)
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;

            testCase.verifyEqual(script.getGroupNames(), {'Ascent', 'Coast'});
            testCase.verifyEqual(numel(script.getEventsInGroup('Ascent')), 2);
            testCase.verifyEqual(numel(script.getEventsInGroup('Coast')), 1);
            testCase.verifyEmpty(script.getEventsInGroup('Nonexistent'));

            testCase.verifyTrue(script.getEventForInd(1).isInGroup('Ascent'));
            testCase.verifyFalse(script.getEventForInd(1).isInGroup('Coast'));
            testCase.verifyTrue(script.getEventForInd(4).isInGroup(''), ...
                'An ungrouped event is "in" the empty group.');
        end

        function listboxShowsGroupHeadersAndStaysAligned(testCase)
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;

            [strs, evts] = script.getListboxStr();
            testCase.verifyEqual(numel(strs), 4, 'Expanded groups must show every event.');
            testCase.verifyEqual(numel(evts), 4, ...
                'Items and ItemsData must stay the same length for the list box.');
            testCase.verifyTrue(contains(strs{1}, '[Ascent]'));
            testCase.verifyTrue(startsWith(strs{1}, char(9660)), ...
                'An expanded group must be marked with the open triangle.');
            testCase.verifyFalse(contains(strs{2}, '[Ascent]'), ...
                'Only the first event of a group carries the header.');
            testCase.verifyTrue(contains(strs{3}, '[Coast]'));
            testCase.verifyFalse(contains(strs{4}, '['));
        end

        function collapsingAGroupHidesItsMembers(testCase)
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;

            script.setGroupCollapsed('Ascent', true);
            testCase.verifyTrue(script.isGroupCollapsed('Ascent'));

            [strs, evts] = script.getListboxStr();
            testCase.verifyEqual(numel(strs), 3, ...
                'A collapsed two-event group must occupy a single row.');
            testCase.verifyEqual(numel(evts), 3);
            testCase.verifyTrue(startsWith(strs{1}, char(9654)), ...
                'A collapsed group must be marked with the closed triangle.');
            testCase.verifyTrue(contains(strs{1}, '(2 events)'));
            testCase.verifyTrue(evts(1) == script.getEventForInd(1), ...
                'The collapsed header row must still select the first event of the group.');

            script.setGroupCollapsed('Ascent', false);
            testCase.verifyEqual(numel(script.getListboxStr()), 4);
        end

        function collapseStateIsIdempotentAndToggles(testCase)
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;

            script.setGroupCollapsed('Ascent', true);
            script.setGroupCollapsed('Ascent', true);
            testCase.verifyEqual(numel(script.collapsedGroupNames), 1, ...
                'Collapsing twice must not record the group twice.');

            script.setGroupCollapsed('Ascent', false);
            script.setGroupCollapsed('Ascent', false);
            testCase.verifyEmpty(script.collapsedGroupNames);

            script.toggleGroupCollapsed('Coast');
            testCase.verifyTrue(script.isGroupCollapsed('Coast'));
            script.toggleGroupCollapsed('Coast');
            testCase.verifyFalse(script.isGroupCollapsed('Coast'));

            %The empty (ungrouped) "group" can never be collapsed.
            script.setGroupCollapsed('', true);
            testCase.verifyEmpty(script.collapsedGroupNames);
        end

        function htmlListboxHonorsGroups(testCase)
            lvdData = testCase.buildFourEventScript();
            script = lvdData.script;
            script.setGroupCollapsed('Ascent', true);

            [strs, evts] = script.getHtmlListboxStr();
            testCase.verifyEqual(numel(strs), 3);
            testCase.verifyEqual(numel(evts), 3);
            testCase.verifyTrue(contains(strs{1}, '[Ascent]'));
        end

        function ungroupedScriptListboxIsUnchanged(testCase)
            %Backward compatibility: with no groups set, the list box text is
            %exactly the per-event string, as before A6.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            [strs, evts] = script.getListboxStr();
            testCase.verifyEqual(numel(strs), numel(script.evts));
            for(i=1:numel(strs))
                testCase.verifyEqual(strs{i}, script.evts(i).getListboxStr());
                testCase.verifyTrue(evts(i) == script.evts(i));
            end
        end

        function notesAreMarkedInTheListboxString(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);

            testCase.verifyEqual(evt.notes, '', 'Events must start with no notes.');
            plainStr = evt.getListboxStr();

            evt.notes = 'Remember to check the staging here.';
            notedStr = evt.getListboxStr();

            testCase.verifyTrue(startsWith(notedStr, plainStr), ...
                'The notes marker must be appended, not replace the existing text.');
            testCase.verifyGreaterThan(strlength(notedStr), strlength(plainStr), ...
                'An event with notes must be visibly marked in the script list.');
            testCase.verifyTrue(contains(notedStr, evt.name), ...
                'The notes marker must not displace the event name.');

            %Clearing the notes must take the marker away again.
            evt.notes = '';
            testCase.verifyEqual(evt.getListboxStr(), plainStr);
        end

        %% ============================================ A8: non-sequential events

        function nonSeqEventActivityTruthTable(testCase)
            [~, nonSeqEvt] = testCase.buildNonSeqMission(300, false);

            testCase.verifyTrue(nonSeqEvt.enabled, 'Non-seq events must default to enabled.');
            testCase.verifyEqual(nonSeqEvt.priority, 0, 'Priority must default to 0.');
            testCase.verifyFalse(nonSeqEvt.logExecutions, ...
                'Logging must default off so existing missions produce identical state logs.');

            testCase.verifyTrue(nonSeqEvt.isActive());

            nonSeqEvt.enabled = false;
            testCase.verifyFalse(nonSeqEvt.isActive(), 'A disabled event is never active.');

            nonSeqEvt.enabled = true;
            nonSeqEvt.numExecsRemaining = 0;
            testCase.verifyFalse(nonSeqEvt.isActive(), 'An exhausted event is never active.');
        end

        function priorityOrderingIsDescendingAndStable(testCase)
            evts = LaunchVehicleNonSeqEvent.empty(1,0);
            for(i=1:4)
                evts(i) = LaunchVehicleNonSeqEvent(LaunchVehicleEvent.empty(1,0));
            end
            evts(1).priority = 0;
            evts(2).priority = 5;
            evts(3).priority = 0;
            evts(4).priority = 5;

            sorted = LaunchVehicleNonSeqEvents.sortByPriority(evts);

            testCase.verifyTrue(sorted(1) == evts(2));
            testCase.verifyTrue(sorted(2) == evts(4), ...
                'Equal priorities must keep the user''s list order.');
            testCase.verifyTrue(sorted(3) == evts(1));
            testCase.verifyTrue(sorted(4) == evts(3));
        end

        function priorityOrderingIsANoOpWhenPrioritiesMatch(testCase)
            evts = LaunchVehicleNonSeqEvent.empty(1,0);
            for(i=1:3)
                evts(i) = LaunchVehicleNonSeqEvent(LaunchVehicleEvent.empty(1,0));
            end

            sorted = LaunchVehicleNonSeqEvents.sortByPriority(evts);
            for(i=1:3)
                testCase.verifyTrue(sorted(i) == evts(i), ...
                    'With equal priorities the order must be exactly the input order.');
            end

            testCase.verifyEmpty(LaunchVehicleNonSeqEvents.sortByPriority(LaunchVehicleNonSeqEvent.empty(1,0)));
        end

        function disabledNonSeqEventIsNotArmed(testCase)
            [lvdData, nonSeqEvt] = testCase.buildNonSeqMission(300, false);
            scriptEvt = lvdData.script.getEventForInd(1);

            armed = lvdData.script.nonSeqEvts.getNonSeqEventsForScriptEvent(scriptEvt);
            testCase.verifyEqual(numel(armed), 1);

            nonSeqEvt.enabled = false;
            armed = lvdData.script.nonSeqEvts.getNonSeqEventsForScriptEvent(scriptEvt);
            testCase.verifyEmpty(armed, ...
                'A disabled non-sequential event must not arm on any script event.');
        end

        function terminationConditionListFiltersAndOrdersByPriority(testCase)
            [lvdData, nonSeqEvtA] = testCase.buildNonSeqMission(300, false);
            nonSeqEvtB = testCase.addNonSeqEvent(lvdData, 400, false);
            nonSeqEvtC = testCase.addNonSeqEvent(lvdData, 500, false);

            nonSeqEvtA.priority = 1;
            nonSeqEvtB.priority = 9;
            nonSeqEvtC.enabled = false;

            armed = lvdData.script.nonSeqEvts.getNonSeqEventsForScriptEvent(lvdData.script.getEventForInd(1));
            testCase.verifyEqual(numel(armed), 2, 'The disabled event must be filtered out.');

            [conds, causes] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(armed);
            testCase.verifyEqual(numel(conds), 2);
            testCase.verifyEqual(numel(causes), 2);
            testCase.verifyTrue(causes(1).nonSeqEvt == nonSeqEvtB, ...
                'The highest-priority armed event must come first in the integrator event vector.');
            testCase.verifyTrue(causes(2).nonSeqEvt == nonSeqEvtA);
        end

        function nonSeqExecutionsAreNotLoggedByDefault(testCase)
            %A8 leaves logExecutions off so that existing mission files keep
            %producing the state log they always did.  The propagation still
            %stops and restarts across the trigger, so two entries share the
            %trigger time (the pre-action stop and the post-action restart),
            %but the action itself contributes no third entry.
            [lvdDataOff, nonSeqEvt] = testCase.buildNonSeqMission(300, false);
            bareNonSeqEvt = LaunchVehicleNonSeqEvent(LaunchVehicleEvent.empty(1,0));
            testCase.assertFalse(bareNonSeqEvt.logExecutions, ...
                'A fresh non-sequential event must default to not logging.');

            entriesOff = testCase.runScript(lvdDataOff).entries;
            tTrigger = entriesOff(1).time + 300;

            testCase.verifyFalse(nonSeqEvt.logExecutions);
            testCase.verifyEqual(testCase.countEntriesAtTime(entriesOff, tTrigger), 2, ...
                'With logging off only the stop/restart pair may sit at the trigger time.');

            %The delta-V is still applied, it is just not separately logged.
            testCase.verifyGreaterThan(testCase.velocityJumpAtTime(entriesOff, tTrigger), 1e-6, ...
                'The non-sequential action must still change the state.');
        end

        function nonSeqExecutionsAreLoggedWhenRequested(testCase)
            [lvdDataOff, ~] = testCase.buildNonSeqMission(300, false);
            entriesOff = testCase.runScript(lvdDataOff).entries;

            [lvdDataOn, ~] = testCase.buildNonSeqMission(300, true);
            entriesOn = testCase.runScript(lvdDataOn).entries;

            testCase.verifyEqual(numel(entriesOn), numel(entriesOff) + 1, ...
                'Logging a single-action non-sequential event must add exactly one entry.');

            tTrigger = entriesOn(1).time + 300;
            testCase.verifyEqual(testCase.countEntriesAtTime(entriesOn, tTrigger), 3, ...
                'Logging must add one more entry at the trigger time.');

            %Everything away from the trigger time must be untouched: turning
            %logging on records the execution, it does not change the flight.
            offAway = entriesOff(abs([entriesOff.time] - tTrigger) > 1e-9);
            onAway = entriesOn(abs([entriesOn.time] - tTrigger) > 1e-9);
            testCase.assertEqual(numel(onAway), numel(offAway));
            testCase.verifyTrue(isequaln([onAway.time], [offAway.time]));
            testCase.verifyTrue(isequaln([onAway.position], [offAway.position]), ...
                'Logging an execution must not perturb the trajectory.');
        end

        function nonSeqListboxStringShowsEnableAndPriority(testCase)
            [~, nonSeqEvt] = testCase.buildNonSeqMission(300, false);
            baseStr = nonSeqEvt.getListboxStr();
            testCase.verifyEqual(baseStr, nonSeqEvt.evt.name, ...
                'A default non-seq event must read exactly as it did before A8.');

            nonSeqEvt.enabled = false;
            testCase.verifyTrue(contains(nonSeqEvt.getListboxStr(), 'disabled'));

            nonSeqEvt.enabled = true;
            nonSeqEvt.priority = 3;
            testCase.verifyTrue(contains(nonSeqEvt.getListboxStr(), 'priority 3'));
        end

        function nonSeqEventArmsEveryOneOfItsConditions(testCase)
            %A1 on non-sequential events: each condition becomes its own
            %integrator event, all sharing the same cause object type and
            %pointing back at the same non-sequential event (first-of logic).
            [lvdData, nonSeqEvt] = testCase.buildNonSeqMission(300, false);

            testCase.verifyEqual(numel(nonSeqEvt.getTerminationConditions()), 1);

            nonSeqEvt.evt.addTermCond(EventDurationTermCondition(150), EventTermCondDirectionEnum.NoDir);
            nonSeqEvt.evt.addTermCond(AltitudeTermCondition(1e6), EventTermCondDirectionEnum.Increasing);

            handles = nonSeqEvt.getTerminationConditions();
            testCase.verifyEqual(numel(handles), 3);
            testCase.verifyTrue(all(cellfun(@(h) isa(h, 'function_handle'), handles)));

            armed = lvdData.script.nonSeqEvts.getNonSeqEventsForScriptEvent(lvdData.script.getEventForInd(1));
            [conds, causes] = LaunchVehicleSimulationDriver.getNonSeqEvtTermConds(armed);
            testCase.verifyEqual(numel(conds), 3, 'One integrator event per condition.');
            testCase.verifyEqual(numel(causes), 3, 'One cause per integrator event.');
            testCase.verifyTrue(all(arrayfun(@(c) c.nonSeqEvt == nonSeqEvt, causes)), ...
                'Every cause must point back at the same non-sequential event.');

            %The single-condition accessor still exists and is condition 1.
            testCase.verifyTrue(isa(nonSeqEvt.getTerminationCondition(), 'function_handle'));
        end

        function nonSeqEventFiresOnWhicheverConditionCrossesFirst(testCase)
            %Condition 1 would fire at 300 s; a second condition at 150 s must
            %win, and with one execution allowed nothing happens at 300 s.
            [lvdDataOne, ~] = testCase.buildNonSeqMission(300, false);
            entriesOne = testCase.runScript(lvdDataOne).entries;
            t0 = entriesOne(1).time;

            [lvdDataTwo, nonSeqEvt] = testCase.buildNonSeqMission(300, false);
            nonSeqEvt.evt.addTermCond(EventDurationTermCondition(150), EventTermCondDirectionEnum.NoDir);
            entriesTwo = testCase.runScript(lvdDataTwo).entries;

            testCase.verifyGreaterThan(testCase.velocityJumpAtTime(entriesOne, t0 + 300), 1e-6, ...
                'Baseline: the single-condition event fires at 300 s.');
            testCase.verifyEqual(testCase.velocityJumpAtTime(entriesOne, t0 + 150), 0, 'AbsTol', 1e-12);

            testCase.verifyGreaterThan(testCase.velocityJumpAtTime(entriesTwo, t0 + 150), 1e-6, ...
                'The earlier of the two conditions must trigger the non-sequential event.');
            testCase.verifyEqual(testCase.velocityJumpAtTime(entriesTwo, t0 + 300), 0, 'AbsTol', 1e-12, ...
                'With one execution allowed the later condition must not fire it again.');
        end

        %% ======================================= A10: per-event limit overrides

        function perEventMaxDurationTruncatesTheEvent(testCase)
            [lvdData, evt] = testCase.buildCoastMission(5000);
            evt.useEvtMaxDur = true;
            evt.evtMaxDur = 400;

            entries = testCase.runScript(lvdData).entries;
            testCase.verifyEqual(entries(end).time - entries(1).time, 400, 'AbsTol', 1e-6, ...
                'The per-event maximum duration must cut the event short.');
        end

        function perEventMaxDurationOnlyTightens(testCase)
            %A generous per-event limit must not loosen the global one.
            [lvdData, evt] = testCase.buildCoastMission(5000);
            lvdData.settings.simMaxDur = 600;
            evt.useEvtMaxDur = true;
            evt.evtMaxDur = 1e9;

            entries = testCase.runScript(lvdData).entries;
            testCase.verifyEqual(entries(end).time - entries(1).time, 600, 'AbsTol', 1e-6, ...
                'The global simulation limit must still apply.');
        end

        function perEventMaxDurationIsIgnoredWhenDisabled(testCase)
            [lvdData, evt] = testCase.buildCoastMission(400);
            evt.useEvtMaxDur = false;
            evt.evtMaxDur = 10;   %would be very restrictive if honored

            entries = testCase.runScript(lvdData).entries;
            testCase.verifyEqual(entries(end).time - entries(1).time, 400, 'AbsTol', 1e-6, ...
                'A disabled override must not affect propagation.');
        end

        function effectiveMinimumAltitudeFollowsTheOverride(testCase)
            [lvdData, evt] = testCase.buildCoastMission(400);
            lvdData.settings.minAltitude = 25;
            driver = lvdData.script.simDriver;

            [alt, isTerrain] = driver.getEffectiveMinAltitude(evt);
            testCase.verifyEqual(alt, 25, 'Without an override the global floor applies.');
            testCase.verifyFalse(isTerrain);

            evt.useEvtMinAltitude = true;
            evt.evtMinAltitude = 90;
            evt.minAltIsTerrainRelative = true;

            [alt, isTerrain] = driver.getEffectiveMinAltitude(evt);
            testCase.verifyEqual(alt, 90);
            testCase.verifyTrue(isTerrain);

            %Terrain-relative is meaningless without the override and must
            %not leak into the global case.
            evt.useEvtMinAltitude = false;
            [~, isTerrain] = driver.getEffectiveMinAltitude(evt);
            testCase.verifyFalse(isTerrain);
        end

        function perEventMinimumAltitudeStopsTheEventEarly(testCase)
            %A descending ellipse whose periapsis sits at 20 km altitude.  The
            %event's own condition is a long duration, so only an altitude
            %floor can end it.  Raising the floor for this event alone must
            %end the event higher up and sooner.
            lvdData = testCase.buildDescendingEllipseMission(3000);
            lvdData.settings.minAltitude = 5;

            entriesGlobal = testCase.runScript(lvdData).entries;
            testCase.assertEqual(testCase.altitudeOf(entriesGlobal(end)), 5, 'AbsTol', 1e-3, ...
                'Fixture check: with a 5 km floor the descent must end at 5 km.');

            lvdData2 = testCase.buildDescendingEllipseMission(3000);
            lvdData2.settings.minAltitude = 5;
            evt2 = lvdData2.script.getEventForInd(1);
            evt2.useEvtMinAltitude = true;
            evt2.evtMinAltitude = 60;

            entriesEvt = testCase.runScript(lvdData2).entries;

            testCase.verifyEqual(testCase.altitudeOf(entriesEvt(end)), 60, 'AbsTol', 1e-3, ...
                'The per-event altitude floor must terminate the event at that altitude.');
            testCase.verifyLessThan(entriesEvt(end).time, entriesGlobal(end).time, ...
                'The raised floor must end the event sooner than the global one.');
        end

        function perEventAndGlobalMinimumAltitudeAgree(testCase)
            %Overriding the floor for the only event in the script must give
            %exactly what setting the same floor globally gives: the override
            %substitutes the value, it does not change how it is applied.
            lvdData = testCase.buildDescendingEllipseMission(3000);
            lvdData.settings.minAltitude = 60;
            entriesGlobal = testCase.runScript(lvdData).entries;

            lvdData2 = testCase.buildDescendingEllipseMission(3000);
            lvdData2.settings.minAltitude = 5;
            evt2 = lvdData2.script.getEventForInd(1);
            evt2.useEvtMinAltitude = true;
            evt2.evtMinAltitude = 60;
            entriesEvt = testCase.runScript(lvdData2).entries;

            testCase.verifyEqual(testCase.altitudeOf(entriesGlobal(end)), 60, 'AbsTol', 1e-3);
            testCase.verifyEqual(numel(entriesEvt), numel(entriesGlobal));
            testCase.verifyTrue(isequaln([entriesEvt.time], [entriesGlobal.time]), ...
                'A per-event override must reproduce the global setting bit for bit.');
            testCase.verifyTrue(isequaln([entriesEvt.position], [entriesGlobal.position]));
        end

        function terrainHeightMatchesTheHeightmap(testCase)
            bodyInfo = testCase.kerbin;
            heightMapGI = bodyInfo.getHeightMap();
            testCase.assumeNotEmpty(heightMapGI, 'Kerbin is expected to carry a heightmap.');

            rVect = (bodyInfo.radius + 100) * [1; 0.2; 0.3] / norm([1; 0.2; 0.3]);
            vVect = [0; 2; 0];
            ut = 0;

            h = AbstractPropagator.getTerrainHeight(ut, rVect, vVect, bodyInfo);

            %Independent oracle: the heightmap sampled at the body-fixed
            %latitude/longitude under the vehicle.
            cartElem = CartesianElementSet(ut, rVect, vVect, bodyInfo.getBodyCenteredInertialFrame());
            geo = cartElem.convertToFrame(bodyInfo.getBodyFixedFrame(), true).convertToGeographicElementSet();
            expected = heightMapGI(angleNegPiToPi(geo.lat), angleNegPiToPi(geo.long));

            testCase.verifyEqual(h, expected, 'AbsTol', 1e-12);
            testCase.verifyTrue(isfinite(h));
        end

        function terrainHeightIsZeroWithoutAHeightmap(testCase)
            %A body with no heightmap file must contribute no terrain
            %correction at all, so the flag is inert on such a body.
            %copyBodyInfo deliberately leaves the heightmap memo behind, so
            %clearing the file is enough to make the copy heightmap-less.
            bodyInfo = testCase.copyBodyInfo(testCase.kerbin);
            bodyInfo.heightmapfile = '';

            rVect = (bodyInfo.radius + 100) * [1; 0.2; 0.3] / norm([1; 0.2; 0.3]);
            vVect = [0; 2; 0];

            h = AbstractPropagator.getTerrainHeight(0, rVect, vVect, bodyInfo);
            testCase.verifyEqual(h, 0, ...
                'A body with no heightmap must report zero terrain height.');
        end

        function terrainRelativeFlagShiftsOnlyTheAltitudeEvent(testCase)
            %Turning the flag on must move the minimum-altitude entry of the
            %integrator event vector by exactly the terrain height under the
            %vehicle, and must leave every other entry untouched.
            [lvdData, evt] = testCase.buildCoastMission(400);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            [~, y0] = entry.getFirstOrderIntegratorStateRepresentation();
            y0 = y0(:);

            args = {entry, {evt.termCond.getEventTermCondFuncHandle()}, evt.termCondDir, ...
                    1e9, false, {}, AbstractIntegrationTerminationCause.empty(1,0), 0, testCase.celBodyData};

            valuePlain = AbstractPropagator.odeEvents(entry.time, y0, args{:}, false);
            valueTerrain = AbstractPropagator.odeEvents(entry.time, y0, args{:}, true);

            terrainHeight = AbstractPropagator.getTerrainHeight(entry.time, y0(1:3), y0(4:6), entry.centralBody);

            testCase.verifyEqual(numel(valueTerrain), numel(valuePlain));
            testCase.verifyEqual(valueTerrain(2), valuePlain(2) - terrainHeight, 'AbsTol', 1e-12, ...
                'The altitude entry must be measured against the terrain.');

            others = [1, 3:numel(valuePlain)];
            testCase.verifyTrue(isequaln(valuePlain(others), valueTerrain(others)), ...
                'No other entry of the event vector may move.');
        end

        function minimumAltitudeFloorEntersTheEventVector(testCase)
            %The effective floor really is what odeEvents is given: raising it
            %lowers the altitude event value one-for-one.
            [lvdData, evt] = testCase.buildCoastMission(400);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            [~, y0] = entry.getFirstOrderIntegratorStateRepresentation();
            y0 = y0(:);

            head = {entry, {evt.termCond.getEventTermCondFuncHandle()}, evt.termCondDir, ...
                    1e9, false, {}, AbstractIntegrationTerminationCause.empty(1,0)};

            valueLow  = AbstractPropagator.odeEvents(entry.time, y0, head{:}, 0,  testCase.celBodyData, false);
            valueHigh = AbstractPropagator.odeEvents(entry.time, y0, head{:}, 60, testCase.celBodyData, false);

            testCase.verifyEqual(valueHigh(2), valueLow(2) - 60, 'AbsTol', 1e-9);
        end

        function odeEventsAcceptsBothConditionForms(testCase)
            %The integrator event vector must be identical whether the single
            %termination condition is handed over bare (the historical form)
            %or wrapped in a one-element cell (the A1 form).
            [lvdData, evt] = testCase.buildCoastMission(400);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            [~, y0] = entry.getFirstOrderIntegratorStateRepresentation();

            fh = evt.termCond.getEventTermCondFuncHandle();
            dir = evt.termCondDir;
            tail = {1e9, false, {}, AbstractIntegrationTerminationCause.empty(1,0), 0, testCase.celBodyData};

            [vBare, itBare, dBare] = AbstractPropagator.odeEvents(entry.time, y0(:), entry, fh, dir, tail{:});
            [vCell, itCell, dCell] = AbstractPropagator.odeEvents(entry.time, y0(:), entry, {fh}, dir, tail{:});

            testCase.verifyTrue(isequaln(vBare, vCell));
            testCase.verifyTrue(isequaln(itBare, itCell));
            testCase.verifyTrue(isequaln(dBare, dCell));
        end

        function odeEventsCausesIdentifyEachCondition(testCase)
            [lvdData, evt] = testCase.buildCoastMission(400);
            evt.addTermCond(EventDurationTermCondition(100));
            entry = lvdData.initStateModel.getInitialStateLogEntry();
            entry.event = evt;
            evt.initEvent(entry);
            [~, y0] = entry.getFirstOrderIntegratorStateRepresentation();

            [fhs, dirs] = evt.getActiveTermCondFuncHandles();
            [value, ~, ~, causes] = AbstractPropagator.odeEvents(entry.time, y0(:), entry, fhs, dirs, ...
                1e9, false, {}, AbstractIntegrationTerminationCause.empty(1,0), 0, testCase.celBodyData);

            testCase.verifyEqual(numel(value), numel(causes));

            termCauses = causes(arrayfun(@(c) isa(c,'EventTermCondIntTermCause'), causes));
            testCase.verifyEqual(numel(termCauses), 2, ...
                'Each termination condition must contribute one entry to the event vector.');
            testCase.verifyEqual(termCauses(1).termCondInd, 1);
            testCase.verifyEqual(termCauses(2).termCondInd, 2);
        end
    end

    methods(Access=private)

        function [lvdData, evt] = buildCoastMission(testCase, duration)
            %A single two-body coast of the given length.  The default LVD
            %initial state sits on the launch pad, which a coast would simply
            %drop through the minimum-altitude floor, so the vehicle is put in
            %a circular 300 km orbit first.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = ...
                KeplerianElementSet(0, testCase.kerbin.radius + 300, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);

            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(duration);
            evt.propagatorObj = evt.twoBodyPropagator;
        end

        function lvdData = buildDescendingEllipseMission(testCase, duration)
            %An ellipse with apoapsis at 300 km and periapsis at 20 km
            %altitude, started at apoapsis so the vehicle descends.
            bodyInfo = testCase.kerbin;
            rA = bodyInfo.radius + 300;
            rP = bodyInfo.radius + 20;
            sma = (rA + rP) / 2;
            ecc = (rA - rP) / (rA + rP);

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, sma, ecc, 0.1, 0, 0, pi, ...
                                                                    testCase.kerbinFrame);

            evt = lvdData.script.getEventForInd(1);
            evt.termCond = EventDurationTermCondition(duration);

            %The force model propagator, not the analytic two body one: the
            %analytic propagator advances in closed form and so never
            %evaluates the integrator's minimum altitude event, which is the
            %very thing these tests are about.
            evt.propagatorObj = evt.forceModelPropagator;
        end

        function alt = altitudeOf(~, entry)
            alt = norm(entry.position) - entry.centralBody.radius;
        end

        function lvdData = buildFourEventScript(testCase)
            %Events 1-2 in "Ascent", event 3 in "Coast", event 4 ungrouped.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            evt1 = script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(100);

            for(i=2:4)
                evt = LaunchVehicleEvent(script);
                evt.termCond = EventDurationTermCondition(100);
                script.addEvent(evt);
            end

            script.getEventForInd(1).groupName = 'Ascent';
            script.getEventForInd(2).groupName = 'Ascent';
            script.getEventForInd(3).groupName = 'Coast';
            script.getEventForInd(4).groupName = '';
        end

        function [lvdData, nonSeqEvt] = buildNonSeqMission(testCase, triggerDur, logExecutions)
            %A coast with one non-sequential event that applies a small
            %impulsive dV partway through.
            [lvdData, ~] = testCase.buildCoastMission(testCase.EvtDur);
            nonSeqEvt = testCase.addNonSeqEvent(lvdData, triggerDur, logExecutions);
        end

        function nonSeqEvt = addNonSeqEvent(testCase, lvdData, triggerDur, logExecutions) %#ok<INUSD>
            script = lvdData.script;

            innerEvt = LaunchVehicleEvent(script);
            innerEvt.name = sprintf('NonSeq %g', triggerDur);
            innerEvt.termCond = EventDurationTermCondition(triggerDur);
            innerEvt.addAction(AddDeltaVAction([0; 0.01; 0], DeltaVFrameEnum.Inertial, false));

            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            nonSeqEvt.maxNumExecs = 1;
            nonSeqEvt.numExecsRemaining = 1;
            nonSeqEvt.logExecutions = logExecutions;

            script.nonSeqEvts.addEvent(nonSeqEvt);
        end

        function num = countEntriesAtTime(~, entries, ut)
            num = sum(abs([entries.time] - ut) < 1e-9);
        end

        function dv = velocityJumpAtTime(~, entries, ut)
            %The largest velocity step between consecutive entries that share
            %the given time: the size of the impulsive discontinuity there.
            dv = 0;

            for(i=2:numel(entries))
                if(abs(entries(i).time - ut) < 1e-9 && abs(entries(i-1).time - ut) < 1e-9)
                    dv = max(dv, norm(entries(i).velocity - entries(i-1).velocity));
                end
            end
        end

        function stateLog = runScript(~, lvdData)
            stateLog = lvdData.script.executeScript(false, ...
                lvdData.script.getEventForInd(1), false, false, false, false, false);
        end
    end
end
