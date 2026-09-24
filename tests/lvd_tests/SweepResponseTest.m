classdef SweepResponseTest < KsptotTestCase
    %SweepResponseTest Harvesting one number per case out of a propagated
    %mission.
    %
    % A response is what turns a sweep's output from a pile of mission files
    % into a table of numbers, so the two things that matter are that it reads
    % the span it claims to read, and that it is honest when it cannot.
    %
    % The honesty half is not hypothetical.  LvdGraphicalAnalysis.executeTasks
    % wraps every evaluated point in a try/catch and substitutes the VALUE -1
    % for anything that throws, which in a results table is indistinguishable
    % from a real answer of -1 -- and -1 is a perfectly ordinary altitude,
    % inclination or delta-v. LvdSweepResponse deliberately does not go
    % through it; a failure is NaN plus a message. These tests pin that.
    %
    % The fixture is a 0.2-eccentricity orbit entered at 90 degrees true
    % anomaly and propagated for about 1.5 periods, so the altitude profile
    % rises through apoapsis, falls through periapsis and rises again. That
    % puts both the minimum and the maximum strictly INSIDE the span, which
    % makes all five node reductions distinct numbers -- on a periapsis-start
    % orbit the minimum coincides with the initial state and a
    % Minimum/InitialState mix-up would pass unnoticed.

    properties(Constant)
        %The altitude profile's turning points sit at entries 7 and 13 of 15.
        Ecc = 0.2;
        Sma = 900;
        TrueAnom = pi/2;
        Dur1 = 2000;
        Dur2 = 2400;
    end

    methods(Test)

        function everyNodeReducesTheScopedSpanTheWayItsNameSays(testCase)
            [lvdData, alt] = testCase.propagatedMissionAndAltitudeOracle();

            testCase.assertEqual(numel(alt), 15, 'Fixture changed: the entry count is not what the oracle indices assume');

            %The five reductions must be five different numbers, or a mix-up
            %between two nodes could pass.
            expected = containers.Map( ...
                {'InitialState', 'FinalState', 'Minimum', 'Maximum', 'Mean'}, ...
                {alt(1), alt(end), min(alt), max(alt), mean(alt)});

            testCase.assertEqual(numel(unique(cell2mat(expected.values()))), 5, ...
                'Fixture broken: two node reductions coincide, so this test could not tell them apart');

            task = testCase.altitudeTask();
            nodes = enumeration('LvdSweepResponseNodeEnum');

            for(i = 1:numel(nodes)) %#ok<*NO4LP>
                node = nodes(i);
                resp = LvdSweepResponse(task, node, 0);

                [value, unit, msg] = resp.evaluate(lvdData);

                testCase.verifyEqual(msg, '', sprintf('Node %s reported a problem: %s', char(node), msg));
                testCase.verifyEqual(unit, 'km', 'The altitude task''s unit must come back with the value');
                testCase.verifyEqual(value, expected(char(node)), 'RelTol', 1e-10, ...
                    sprintf('Node %s did not reduce the span the way its name says', char(node)));
            end
        end

        function theTurningPointsAreFoundInsideTheSpanAndNotAtItsEnds(testCase)
            %A negative control for the test above: if evaluate() only ever
            %looked at the first and last entry (the cheap path the two end
            %nodes take), Minimum and Maximum would come back as one of the
            %endpoints. They must not.
            [lvdData, alt] = testCase.propagatedMissionAndAltitudeOracle();

            task = testCase.altitudeTask();

            minValue = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Minimum, 0).evaluate(lvdData);
            maxValue = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 0).evaluate(lvdData);

            testCase.verifyLessThan(minValue, min(alt(1), alt(end)), ...
                'The minimum was not searched for inside the span');
            testCase.verifyGreaterThan(maxValue, max(alt(1), alt(end)), ...
                'The maximum was not searched for inside the span');

            testCase.verifyTrue(LvdSweepResponseNodeEnum.Minimum.needsWholeSpan());
            testCase.verifyTrue(LvdSweepResponseNodeEnum.Maximum.needsWholeSpan());
            testCase.verifyTrue(LvdSweepResponseNodeEnum.Mean.needsWholeSpan());
            testCase.verifyFalse(LvdSweepResponseNodeEnum.InitialState.needsWholeSpan(), ...
                'An end node must not pay for evaluating the whole span');
            testCase.verifyFalse(LvdSweepResponseNodeEnum.FinalState.needsWholeSpan(), ...
                'An end node must not pay for evaluating the whole span');
        end

        function anEventScopeRestrictsTheResponseToThatEventsEntries(testCase)
            %"Max q during the ascent event" and "max q over the whole
            %mission" are different questions, and a sweep of a multi-event
            %mission needs to be able to ask the first one.
            [lvdData, alt, ctx] = testCase.propagatedMissionAndAltitudeOracle();

            task = testCase.altitudeTask();

            alt1 = testCase.altitudeOf(lvdData.stateLog.getAllStateLogEntriesForEvent(ctx.evt1));
            alt2 = testCase.altitudeOf(lvdData.stateLog.getAllStateLogEntriesForEvent(ctx.evt2));

            testCase.assertNotEmpty(alt1, 'Fixture broken: event 1 logged no entries');
            testCase.assertNotEmpty(alt2, 'Fixture broken: event 2 logged no entries');

            %Apoapsis falls in event 1, periapsis in event 2, so scoping
            %actually changes the answer.
            testCase.assertGreaterThan(max(alt1), max(alt2), ...
                'Fixture broken: the two events do not have distinguishable altitude extremes');

            e1Max = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 1).evaluate(lvdData);
            e2Min = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Minimum, 2).evaluate(lvdData);
            e1Final = LvdSweepResponse(task, LvdSweepResponseNodeEnum.FinalState, 1).evaluate(lvdData);

            testCase.verifyEqual(e1Max, max(alt1), 'RelTol', 1e-10, ...
                'An event-scoped maximum must search only that event''s entries');
            testCase.verifyEqual(e2Min, min(alt2), 'RelTol', 1e-10, ...
                'An event-scoped minimum must search only that event''s entries');
            testCase.verifyEqual(e1Final, alt1(end), 'RelTol', 1e-10, ...
                'An event-scoped final state must be that event''s last entry, not the mission''s');

            %Scoping to an event must give a different answer from scoping to
            %the mission, or the eventNum is being ignored.
            testCase.verifyNotEqual(e2Min, LvdSweepResponse(task, LvdSweepResponseNodeEnum.Minimum, 1).evaluate(lvdData), ...
                'Two different event scopes returned the same number: eventNum is not being honoured');
            testCase.verifyNotEqual(e1Final, alt(end), ...
                'An event-scoped final state returned the mission''s final state');
        end

        function aFailingTaskRecordsNaNAndAMessageRatherThanTheValueMinusOne(testCase)
            %This is the whole reason evaluate() exists instead of calling
            %LvdGraphicalAnalysis.executeTasks, which would have written -1
            %into the results table here.
            lvdData = testCase.propagatedMissionAndAltitudeOracle();

            resp = LvdSweepResponse(GraphicalAnalysisTask('Not A Real Quantity', testCase.kerbinFrame), ...
                                    LvdSweepResponseNodeEnum.FinalState, 0);

            [value, unit, msg] = resp.evaluate(lvdData);

            testCase.verifyTrue(isnan(value), 'An unevaluable task must record NaN');
            testCase.verifyNotEqual(value, -1, 'A failure must never be recorded as the value -1');
            testCase.verifyNotEmpty(msg, 'A failure must carry a message the results window can show');
            testCase.verifyEqual(unit, '', 'A failed evaluation has no unit to report');

            %And it must not throw: one bad response cannot be allowed to
            %lose a case's other responses, or the run itself.
            testCase.verifyWarningFree(@() resp.evaluate(lvdData));
        end

        function anUnpropagatedOrOutOfRangeScopeIsReportedRatherThanThrowing(testCase)
            %A propagate-only case whose script errored out leaves an empty
            %state log; a case whose user deleted event 4 leaves a response
            %scoped to an event that is not there. Both are run-time facts,
            %not programming errors, so both are messages.
            fresh = LvdData.getDefaultLvdData(testCase.celBodyData);
            task = testCase.altitudeTask();

            [value, ~, msg] = LvdSweepResponse(task, LvdSweepResponseNodeEnum.FinalState, 0).evaluate(fresh);
            testCase.verifyTrue(isnan(value), 'An unpropagated mission must evaluate to NaN');
            testCase.verifyNotEmpty(msg);
            testCase.verifyTrue(contains(msg, 'propagated'), ...
                'The message for an unpropagated mission should say so');

            lvdData = testCase.propagatedMissionAndAltitudeOracle();

            [value, ~, msg] = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 9).evaluate(lvdData);
            testCase.verifyTrue(isnan(value), 'A scope event that does not exist must evaluate to NaN');
            testCase.verifyNotEmpty(msg);
        end

        function theUnitComesFromTheTaskAndIsTheSameForEveryNode(testCase)
            lvdData = testCase.propagatedMissionAndAltitudeOracle();

            nodes = enumeration('LvdSweepResponseNodeEnum');

            for(i = 1:numel(nodes))
                [~, unit] = LvdSweepResponse(testCase.altitudeTask(), nodes(i), 0).evaluate(lvdData);
                testCase.verifyEqual(unit, 'km', 'Reducing a span must not change the quantity''s unit');
            end

            %A different quantity brings its own unit, and gives a second,
            %independent check that the value really is read off the state log
            %-- universal time at the final state is just the last entry's
            %epoch, which nothing in the response code computes.
            timeTask = GraphicalAnalysisTask('Universal Time', testCase.kerbinFrame);
            [value, unit] = LvdSweepResponse(timeTask, LvdSweepResponseNodeEnum.FinalState, 0).evaluate(lvdData);

            entries = lvdData.stateLog.getAllEntries();
            testCase.verifyEqual(unit, 'sec');
            testCase.verifyEqual(value, entries(end).time, 'RelTol', 1e-12);
            testCase.verifyEqual(value, testCase.Dur1 + testCase.Dur2, 'RelTol', 1e-12, ...
                'The final epoch must be the sum of the two event durations');
        end

        function reduceIgnoresNaNsAndOnlyReportsNaNWhenEverythingIsNaN(testCase)
            %A task that can be evaluated at some entries but not others
            %(a tank quantity before the tank exists, say) must not poison
            %the whole reduction.
            values = [3, NaN, 1, NaN, 5];

            testCase.verifyEqual(LvdSweepResponseNodeEnum.Minimum.reduce(values), 1);
            testCase.verifyEqual(LvdSweepResponseNodeEnum.Maximum.reduce(values), 5);
            testCase.verifyEqual(LvdSweepResponseNodeEnum.Mean.reduce(values), 3, 'RelTol', 1e-14, ...
                'The mean must be taken over the valid entries only');

            %The end nodes take the first and last VALID value, not a NaN.
            testCase.verifyEqual(LvdSweepResponseNodeEnum.InitialState.reduce([NaN, 7, 8]), 7);
            testCase.verifyEqual(LvdSweepResponseNodeEnum.FinalState.reduce([7, 8, NaN]), 8);

            %Nothing valid at all is genuinely NaN.
            nodes = enumeration('LvdSweepResponseNodeEnum');
            for(i = 1:numel(nodes))
                testCase.verifyTrue(isnan(nodes(i).reduce([NaN NaN NaN])), ...
                    sprintf('%s must report NaN when no value could be evaluated', char(nodes(i))));
                testCase.verifyTrue(isnan(nodes(i).reduce([])), ...
                    sprintf('%s must report NaN for an empty span', char(nodes(i))));
            end

            %Orientation must not matter.
            testCase.verifyEqual(LvdSweepResponseNodeEnum.Mean.reduce([1;2;3]), 2, 'RelTol', 1e-14);
        end

        function responseNamesDistinguishScopeNodeAndTaskAndHonourAnOverride(testCase)
            task = testCase.altitudeTask();

            missionName = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 0).getName();
            eventName = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 2).getName();
            otherNode = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Minimum, 2).getName();

            testCase.verifyTrue(contains(missionName, 'Mission'), ...
                'An unscoped response should say it covers the whole mission');
            testCase.verifyTrue(contains(eventName, 'Event 2'));
            testCase.verifyTrue(contains(missionName, 'Altitude') && contains(eventName, 'Altitude'));

            %Three responses that differ in exactly one field must produce
            %three different column headers.
            testCase.verifyNotEqual(missionName, eventName, 'The scope must show in the name');
            testCase.verifyNotEqual(eventName, otherNode, 'The node must show in the name');

            resp = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Mean, 0);
            resp.label = 'Insertion Altitude';
            testCase.verifyEqual(resp.getName(), 'Insertion Altitude', ...
                'An explicit label must win over the generated name');
        end

        function nodeEnumRoundTripsThroughItsListboxStrings(testCase)
            [listBoxStr, enums] = LvdSweepResponseNodeEnum.getListBoxStr();

            testCase.verifyEqual(numel(listBoxStr), numel(enums));
            testCase.verifyEqual(numel(unique(listBoxStr)), numel(listBoxStr), ...
                'Two nodes share a listbox string, so the dropdown would be ambiguous');

            for(i = 1:numel(enums))
                [enum, ind] = LvdSweepResponseNodeEnum.getEnumForListboxStr(listBoxStr{i});
                testCase.verifyEqual(enum, enums(i), 'A listbox string did not map back to its own enum');
                testCase.verifyEqual(ind, i, 'The listbox index and the enumeration order disagree');

                testCase.verifyEqual(LvdSweepResponseNodeEnum.getIndForName(listBoxStr{i}), i);
            end
        end

        function responsesCarryDistinctIdsAndSurviveAByteStreamClone(testCase)
            task = testCase.altitudeTask();

            a = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 0);
            b = LvdSweepResponse(task, LvdSweepResponseNodeEnum.Maximum, 0);

            testCase.verifyNotEqual(a.id, b.id, ...
                'Two identically configured responses must still be separate rows in the setup');
            testCase.verifyTrue(a == a);
            testCase.verifyTrue(a ~= b);

            %A response is dispatched to a worker by byte stream, and comes
            %back matched to its column by id.
            clone = getArrayFromByteStream(getByteStreamFromArray([a, b]));

            testCase.verifyEqual([clone.id], [a.id, b.id], 'Serializing a response must preserve its id');
            testCase.verifyEqual(clone(1).node, a.node);
            testCase.verifyEqual(clone(1).task.taskStr, a.task.taskStr);
            testCase.verifyEqual(clone(2).eventNum, b.eventNum);

            %And the clone must still evaluate to the same number, which is
            %the only thing that makes a parallel run's results comparable.
            lvdData = testCase.propagatedMissionAndAltitudeOracle();
            testCase.verifyEqual(clone(1).evaluate(lvdData), a.evaluate(lvdData), 'RelTol', 1e-14);
        end
    end

    methods(Access=private)

        function task = altitudeTask(testCase)
            task = GraphicalAnalysisTask('Altitude', testCase.kerbinFrame);
        end

        function alt = altitudeOf(testCase, entries)
            %altitudeOf The independent oracle: altitude straight off each
            %state log entry's position, with no reference to the graphical
            %analysis machinery the response evaluates through.
            alt = arrayfun(@(e) norm(e.position) - testCase.kerbin.radius, entries);
        end

        function [lvdData, alt, ctx] = propagatedMissionAndAltitudeOracle(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, testCase.Sma, testCase.Ecc, ...
                                                                    0, 0, 0, testCase.TrueAnom, testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(testCase.Dur1);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(testCase.Dur2);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            lvdData.script.executeScript(false, evt1, false, false, false, false, false);

            entries = lvdData.stateLog.getAllEntries();
            testCase.assertNotEmpty(entries, 'Fixture broken: the mission did not propagate');

            alt = testCase.altitudeOf(entries);
            ctx = struct('evt1', evt1, 'evt2', evt2);
        end
    end
end
