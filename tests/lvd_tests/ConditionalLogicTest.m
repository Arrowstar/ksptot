classdef ConditionalLogicTest < KsptotTestCase
    %ConditionalLogicTest NOT conditionals and quantity-at-event comparisons.
    %
    % Covers LogicalNotActionConditional (truth table, nesting, tree string),
    % QuantityComparisonActionCondition in its "Quantity at Event" mode
    % (initial/final state of a previously propagated event, false when the
    % event has not been propagated), and the usesEvent bookkeeping that
    % keeps the delete-event guard honest when a condition references an
    % event.

    methods(Test)
        function notConditionalTruthTable(testCase)
            [~, entry] = testCase.buildEntry();

            notTrue = LogicalNotActionConditional(AlwaysTrueActionCondition());
            notFalse = LogicalNotActionConditional(AlwaysFalseActionCondition());
            notEmpty = LogicalNotActionConditional();

            testCase.verifyFalse(notTrue.evaluateConditional(entry), 'NOT TRUE');
            testCase.verifyTrue(notFalse.evaluateConditional(entry), 'NOT FALSE');
            testCase.verifyFalse(notEmpty.evaluateConditional(entry), 'NOT of nothing follows the empty AND/OR convention (inner TRUE)');

            testCase.verifyEqual(notTrue.enum, ConditionalTypeEnum.LogicalNot);
            testCase.verifyEqual(char(notFalse.getConditionalString()), 'NOT (FALSE)');
            testCase.verifyEqual(char(notEmpty.getConditionalString()), 'NOT (TRUE)');
            testCase.verifyEqual(notTrue.getListboxStr(), 'NOT Conditional');

            %Nested in AND / OR.
            andCond = LogicalAndActionConditional([AlwaysTrueActionCondition(), notFalse]);
            testCase.verifyTrue(andCond.evaluateConditional(entry), 'TRUE AND NOT FALSE');

            orCond = LogicalOrActionConditional([notTrue, AlwaysFalseActionCondition()]);
            testCase.verifyFalse(orCond.evaluateConditional(entry), 'NOT TRUE OR FALSE');

            %Double negation.
            notNot = LogicalNotActionConditional(notTrue);
            testCase.verifyTrue(notNot.evaluateConditional(entry), 'NOT NOT TRUE');
        end

        function notConditionalChildManagement(testCase)
            notCond = LogicalNotActionConditional();
            testCase.verifyFalse(notCond.hasConditional());

            child = AlwaysTrueActionCondition();
            notCond.addConditional(child);
            testCase.verifyTrue(notCond.hasConditional());
            testCase.verifySameHandle(notCond.conditional(1), child);

            replacement = AlwaysFalseActionCondition();
            notCond.substituteConditional(child, replacement);
            testCase.verifySameHandle(notCond.conditional(1), replacement);

            notCond.removeConditional(child); %not the current child: no-op
            testCase.verifyTrue(notCond.hasConditional());

            notCond.removeConditional(replacement);
            testCase.verifyFalse(notCond.hasConditional());

            [listBoxStr, ~] = ConditionalTypeEnum.getListBoxStr();
            testCase.verifyTrue(any(listBoxStr == "Logical Not"), 'The editor type list must offer Logical Not.');
        end

        function eventQuantityComparesAgainstAnotherEventsState(testCase)
            [lvdData, evt1, evt2] = testCase.buildTwoEventMission();
            stateLog = lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false);

            evt1Entries = stateLog.getAllStateLogEntriesForEvent(evt1);
            evt2Entries = stateLog.getAllStateLogEntriesForEvent(evt2);
            testCase.assertNotEmpty(evt1Entries);
            testCase.assertNotEmpty(evt2Entries);

            current = evt2Entries(end);
            frame = current.centralBody.getBodyCenteredInertialFrame();

            %Altitude now vs altitude at the END of event 1.
            cond = testCase.makeAltitudeCondition(frame, ComparisonTypeEnum.GreaterThan, evt1, ConstraintStateComparisonNodeEnum.FinalState);
            expectedGt = current.altitude > evt1Entries(end).altitude;
            testCase.verifyEqual(cond.evaluateConditional(current), expectedGt, 'Altitude > Altitude @ Event 1 (final)');

            cond.comparisonType = ComparisonTypeEnum.LessThan;
            testCase.verifyEqual(cond.evaluateConditional(current), current.altitude < evt1Entries(end).altitude, 'Altitude < Altitude @ Event 1 (final)');

            %...and vs the START of event 1.
            cond.compareEventNode = ConstraintStateComparisonNodeEnum.InitialState;
            cond.comparisonType = ComparisonTypeEnum.GreaterThan;
            testCase.verifyEqual(cond.evaluateConditional(current), current.altitude > evt1Entries(1).altitude, 'Altitude > Altitude @ Event 1 (initial)');

            %Equality against its own final state, with a small tolerance.
            condSelf = testCase.makeAltitudeCondition(frame, ComparisonTypeEnum.Equals, evt2, ConstraintStateComparisonNodeEnum.FinalState);
            condSelf.tol = 1e-9;
            testCase.verifyTrue(condSelf.evaluateConditional(current), 'A quantity equals itself at the same log entry');

            %Sanity check that the two reference altitudes really differ, so
            %the > / < checks above exercised both truth values.
            testCase.verifyNotEqual(evt1Entries(1).altitude, evt1Entries(end).altitude, ...
                'Fixture: the coast must change altitude for the comparisons to be meaningful.');

            %Human readable strings mention the event and node.
            str = cond.getListboxStr();
            testCase.verifySubstring(str, 'Event 1');
            testCase.verifySubstring(str, 'Initial State');

            [listBoxStr, ~] = CompareAgainstEnum.getListBoxStr();
            testCase.verifyTrue(any(listBoxStr == "Quantity at Event"));
        end

        function eventQuantityIsFalseWhenEventHasNoLoggedState(testCase)
            [lvdData, ~, evt2] = testCase.buildTwoEventMission();
            stateLog = lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false);
            current = stateLog.getAllStateLogEntriesForEvent(evt2);
            current = current(end);
            frame = current.centralBody.getBodyCenteredInertialFrame();

            %An event that exists in the script but was never propagated.
            evt3 = LaunchVehicleEvent(lvdData.script);
            evt3.termCond = EventDurationTermCondition(10);
            lvdData.script.addEvent(evt3);

            cond = testCase.makeAltitudeCondition(frame, ComparisonTypeEnum.GreaterThan, evt3, ConstraintStateComparisonNodeEnum.FinalState);
            testCase.verifyFalse(cond.evaluateConditional(current), 'No logged state for the compare event: condition does not hold');

            %No event configured at all.
            cond.compareEvent = LaunchVehicleEvent.empty(1,0);
            testCase.verifyFalse(cond.evaluateConditional(current), 'No compare event: condition does not hold');
            testCase.verifySubstring(cond.getListboxStr(), '<No Event>');
        end

        function usesEventPropagatesThroughConditionsAndActions(testCase)
            [lvdData, evt1, evt2] = testCase.buildTwoEventMission();
            frame = lvdData.initialState.centralBody.getBodyCenteredInertialFrame();

            cond = testCase.makeAltitudeCondition(frame, ComparisonTypeEnum.GreaterThan, evt1, ConstraintStateComparisonNodeEnum.FinalState);
            testCase.verifyTrue(cond.usesEvent(evt1));
            testCase.verifyFalse(cond.usesEvent(evt2));

            %Constant and quantity comparisons reference no event.
            plain = QuantityComparisonActionCondition(GraphicalAnalysisTask('Altitude', frame), 0, ComparisonTypeEnum.Equals, 0, frame);
            testCase.verifyFalse(plain.usesEvent(evt1));
            testCase.verifyFalse(AlwaysTrueActionCondition().usesEvent(evt1));

            notCond = LogicalNotActionConditional(cond);
            andCond = LogicalAndActionConditional([AlwaysTrueActionCondition(), notCond]);
            orCond = LogicalOrActionConditional([AlwaysFalseActionCondition(), andCond]);
            testCase.verifyTrue(notCond.usesEvent(evt1), 'NOT');
            testCase.verifyTrue(andCond.usesEvent(evt1), 'AND -> NOT');
            testCase.verifyTrue(orCond.usesEvent(evt1), 'OR -> AND -> NOT');
            testCase.verifyFalse(orCond.usesEvent(evt2));

            %Through a ConditionalAction on event 2: if-condition...
            condAction = ConditionalAction();
            condAction.ifCondition = orCond;
            evt2.addAction(condAction);
            testCase.verifyTrue(condAction.usesEvent(evt1), 'ConditionalAction.usesEvent must consult its if-condition');
            testCase.verifyTrue(evt2.usesEvent(evt1), 'LaunchVehicleEvent.usesEvent must see the condition');

            [inUse, reasons] = lvdData.script.getEventUsageReport(evt1);
            testCase.verifyTrue(inUse, 'The delete-event guard must report the condition reference.');
            testCase.verifyTrue(any(contains(reasons, 'Event 2')));

            %...and elseif-condition.
            condAction2 = ConditionalAction();
            condAction2.ifCondition = AlwaysFalseActionCondition();
            elseIfCond = testCase.makeAltitudeCondition(frame, ComparisonTypeEnum.LessThan, evt1, ConstraintStateComparisonNodeEnum.InitialState);
            condAction2.addElseIfConditional(elseIfCond);
            testCase.verifyTrue(condAction2.usesEvent(evt1), 'ConditionalAction.usesEvent must consult its elseif-conditions');
            testCase.verifyFalse(condAction2.usesEvent(evt2));
        end
    end

    methods
        function [lvdData, entry] = buildEntry(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            entry = lvdData.initStateModel.getInitialStateLogEntry();
        end

        function [lvdData, evt1, evt2] = buildTwoEventMission(testCase)
            %Two two-body coasts of different lengths from the default state.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(100);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(50);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);
        end

        function cond = makeAltitudeCondition(~, frame, comparisonType, compareEvent, node)
            task = GraphicalAnalysisTask('Altitude', frame);
            cond = QuantityComparisonActionCondition(task, 0, comparisonType, 0, frame);
            cond.compareAgainst = CompareAgainstEnum.EventQuantity;
            cond.compareEvent = compareEvent;
            cond.compareEventNode = node;
        end
    end
end
