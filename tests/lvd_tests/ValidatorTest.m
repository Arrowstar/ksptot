classdef ValidatorTest < KsptotTestCase
    %ValidatorTest All 13 AbstractLaunchVehicleDataValidator subclasses.
    %
    % SUBJECT UNDER TEST
    %   helper_methods/ksptot_lvd/classes/Validation/Validators/*
    %   helper_methods/ksptot_lvd/classes/Validation/@LaunchVehicleDataValidation
    %
    % WHAT A VALIDATOR IS
    %   [errors, warnings] = validate(obj) inspects an LvdData object -- its
    %   settings, its script, and the state log left behind by the last run --
    %   and returns arrays of LaunchVehicleDataValidationError /
    %   ...Warning objects.  There is no numerical modelling here: every rule
    %   is a predicate over data the test can construct directly.  So the
    %   "independent oracle" for this file is simply the rule restated in the
    %   test, and the discipline that matters is BOTH POLARITIES: every rule is
    %   driven once with data that must NOT trip it and once with data that
    %   must, with only the single relevant dial moved between the two.
    %   Where a rule contains an inequality, the exact boundary is driven too,
    %   since >= versus > is precisely the sort of thing that rots silently.
    %
    % FIXTURE STRATEGY
    %   makeRunMission() builds a two-event coasting mission in a 100 km
    %   circular Kerbin orbit and actually runs it, so the state log contains
    %   real entries with real central bodies and force-model states.
    %   Individual checks then mutate one thing -- a settings field, a
    %   state-log entry's position, an event's propagator -- rather than
    %   re-propagating, which keeps this file fast and keeps the "only one dial
    %   moved" property obvious.
    %
    %   The baseline mission is deliberately chosen so that twelve of the
    %   thirteen validators are silent on it: altitude 100 km is above Kerbin's
    %   70 km atmosphere and far inside its sphere of influence, both events
    %   coast on two-body propagators with zero throttle, and the default
    %   settings thresholds are all slack.  The one exception is
    %   NoOptimizationVariablesValidator, which fires on any script without
    %   optimization variables; checkValidationOrchestrator handles that
    %   explicitly.
    %
    % SKIPPED (documented)
    %   * LaunchVehicleDataValidation.writeOutputsToUI and
    %     writeOutputsToUITable -- pure uicontrol/uitable manipulation, and
    %     writeOutputsToUITable's argument block requires a live
    %     matlab.ui.control.Table.
    %   * AbstractLaunchVehicleValidatorOutput.writeToLabel and
    %     getUiTableStringAndRowStyle -- styling only; the latter calls
    %     uistyle(), which needs a figure.
    %   * getEventNumberForVar.m -- exercised indirectly here, but owned by
    %     OptimizationVariableTest, which covers the variable-location matrix.
    %   * The StateComparison arm of ConstraintValidator -- it differs from the
    %     FixedBounds arm only in reading c/ceq instead of value/lb/ub, and
    %     ConstraintTest already covers state-comparison c/ceq generation at
    %     the source.  The FixedBounds arm below covers this validator's own
    %     logic: the bounds predicate, the event numbering, and the two-part
    %     message assembly.
    %
    % REGRESSION GUARDS
    %   Several checks below assert behaviour that was once wrong in
    %   production and carry a comment naming the defect they guard against:
    %   the one-argument-short sprintf truncation shared by four validators,
    %   the duplicated MaxFixedStepsReached warning, the fresh-event
    %   propagator identity, and the empty-state-log index.  Keep the
    %   explanation with the assertion; it is what stops the assertion from
    %   being "corrected" back to the broken value.

    properties(TestParameter)
        caseName = { ...
            'NoOptimizationVariables', ...
            'OptimizationVariablesNearBounds', ...
            'MaxSimTimeReached', ...
            'MaxPropTimeReached', ...
            'MinAltitudeReached', ...
            'AtmoWithNoDragModel', ...
            'ThrottleWithNoThrustModel', ...
            'RadiusOutsideSoI', ...
            'ForceModelPropagatorWithNoForceModels', ...
            'ThirdBodyGravity', ...
            'MaxFixedStepsReached', ...
            'SomeEventsNotPlotted', ...
            'ConstraintValidatorFixedBounds', ...
            'ValidationOrchestrator', ...
            'FreshEventPropagatorIdentity', ...
            'ForceModelValidatorSkipsEmptyStateLog', ...
        };
    end

    properties(Constant, Access=private)
        Smi    = 700;   %km, circular Kerbin orbit -> 100 km altitude
        EvtDur = 600;   %sec
    end

    methods(Test)
        function validatorsMatchRuleRestatement(testCase, caseName)
            testCase.(['check' caseName])();
        end
    end

    methods(Access=private)

        %% ------------------------------------------------------------------
        %  Settings-driven rules
        %  ------------------------------------------------------------------

        function checkNoOptimizationVariables(testCase)
            %Rule: warn when the script has zero enabled optimization
            %variables.  The count comes from the LENGTH of the scaled x
            %vector, not from the number of variable objects, so a variable
            %that exists but is disabled still counts as zero.
            lvdData = testCase.makeRunMission();
            v = NoOptimizationVariablesValidator(lvdData);

            %POSITIVE: no variables at all.
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors, only warnings.');
            testCase.verifyNumElements(warnings, 1, 'A script with no variables must warn.');
            testCase.verifyEqual(warnings(1).str, 'No optimization variables enabled on script.', ...
                'Unexpected message text for the no-variables warning.');

            %Add a variable object but leave it DISABLED.  useTf == false makes
            %getXsForVariable return [], so the x vector stays empty and the
            %rule still fires.
            evt2 = lvdData.script.getEventForInd(2);
            var = EventDurationOptimizationVariable(evt2.termCond);
            var.useTf = false;
            var.lb = 10;
            var.ub = 100000;
            lvdData.optimizer.vars.addVariable(var);

            [~, warningsDisabled] = v.validate();
            testCase.verifyNumElements(warningsDisabled, 1, ...
                'A variable that exists but is disabled must still count as zero.');

            %NEGATIVE: enable it.  Only this one dial moved.
            var.useTf = true;
            [errorsOn, warningsOn] = v.validate();
            testCase.verifyEmpty(errorsOn, 'Still no errors once a variable is enabled.');
            testCase.verifyEmpty(warningsOn, 'One enabled variable must silence the validator.');
        end

        function checkOptimizationVariablesNearBounds(testCase)
            %Rule: warn when a scaled variable value sits in the outer 1% of
            %its range, i.e. normX = (x - lb)/(ub - lb) >= 0.99 or <= 0.01,
            %all measured in the SCALED space.
            %
            %AbstractOptimizationVariable.getScaledXsForVariable maps
            %[lb, ub] linearly onto [-1, +1] whenever ub - lb > 1e-10, so
            %normX in scaled space equals normX in unscaled space:
            %    xS = (x - (lb+ub)/2) / ((ub-lb)/2)
            %    (xS - (-1)) / (1 - (-1)) = (x - lb)/(ub - lb)
            %That identity is what lets this test place the variable at a
            %chosen fraction of its range by setting the raw event duration.
            %
            %The threshold is BRACKETED rather than hit exactly.  Placing the
            %variable at normX == 0.01 to the last bit would require the
            %round trip unscaled -> scaled -> normX to reproduce the double
            %nearest 0.01 exactly, and it does not: with lb = 10, ub = 100000
            %it lands a few ulp above, so an exact-equality probe would test
            %the arithmetic of the test rather than the rule.  Instead the
            %threshold is straddled by +/- eps below, which pins the
            %comparison to within 0.0005 of a range and cannot pass for a
            %validator that has, say, dropped the lower-bound clause.
            lb = 10;
            ub = 100000;
            eps = 0.0005;
            atFraction = @(f) lb + f*(ub - lb);

            %NEGATIVE: comfortably mid-range.
            lvdData = testCase.makeRunMission();
            var = testCase.addDurationVar(lvdData, 2, lb, ub);
            var.varObj.duration = atFraction(0.5);

            v = OptimizationVariablesNearBoundsValidator(lvdData);
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A variable at 50% of its range must not warn.');

            %BOUNDARY (upper): just inside the threshold is silent, just past
            %it warns.
            var.varObj.duration = atFraction(0.99 - eps);
            [~, w098] = v.validate();
            testCase.verifyEmpty(w098, 'normX just below 0.99 is inside the 1% band and must not warn.');

            var.varObj.duration = atFraction(0.99 + eps);
            [~, w099] = v.validate();
            testCase.verifyNumElements(w099, 1, ...
                'normX just above 0.99 must warn.');
            testCase.verifyTrue(contains(w099(1).str, 'near optimization bounds'), ...
                'Unexpected message text for the near-bounds warning.');

            %BOUNDARY (lower), symmetric.
            var.varObj.duration = atFraction(0.01 + eps);
            [~, w002] = v.validate();
            testCase.verifyEmpty(w002, 'normX just above 0.01 is inside the 1% band and must not warn.');

            var.varObj.duration = atFraction(0.01 - eps);
            [~, w001] = v.validate();
            testCase.verifyNumElements(w001, 1, ...
                'normX just below 0.01 must warn.');

            %The detail line quotes the UNSCALED triple lb <= x <= ub, so the
            %reader can see which variable is pinned and where.
            testCase.verifyTrue(contains(w001(1).str, sprintf('%0.3f', lb)), ...
                'Near-bounds message must quote the unscaled lower bound.');
            testCase.verifyTrue(contains(w001(1).str, sprintf('%0.3f', ub)), ...
                'Near-bounds message must quote the unscaled upper bound.');
            testCase.verifyTrue(contains(w001(1).str, sprintf('%0.3f', atFraction(0.01 - eps))), ...
                'Near-bounds message must quote the unscaled current value.');

            %Degenerate range lb == ub: the scaling code leaves x unscaled with
            %lb == ub, so normX is 0/0 = NaN and NEITHER inequality fires.  The
            %dedicated third clause (ub == lb && x == lb) is the only thing
            %that catches this case.
            lvdData2 = testCase.makeRunMission();
            varPinned = testCase.addDurationVar(lvdData2, 2, testCase.EvtDur, testCase.EvtDur);
            varPinned.varObj.duration = testCase.EvtDur;
            v2 = OptimizationVariablesNearBoundsValidator(lvdData2);
            [~, wPinned] = v2.validate();
            testCase.verifyNumElements(wPinned, 1, ...
                'A variable with lb == ub == x must warn via the degenerate-range clause.');
        end

        function checkMaxSimTimeReached(testCase)
            %Rule: warn when (tEnd - tStart) of the state log reaches or
            %exceeds settings.simMaxDur.  The mission below coasts through two
            %600 s events, so the span is 1200 s.
            lvdData = testCase.makeRunMission();
            [tStart, tEnd] = lvdData.stateLog.getStartAndEndTimes();
            span = tEnd - tStart;
            testCase.assertGreaterThan(span, 0, 'Fixture broken: the state log spans no time.');

            v = MaxSimTimeReachedValidator(lvdData);

            %NEGATIVE: threshold above the span.
            lvdData.settings.simMaxDur = span + 1;
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A simMaxDur above the actual span must not warn.');

            %BOUNDARY: exactly equal trips, because the test is >=.
            lvdData.settings.simMaxDur = span;
            [~, wEqual] = v.validate();
            testCase.verifyNumElements(wEqual, 1, ...
                'simMaxDur exactly equal to the span must warn (the test is >=).');

            %POSITIVE: threshold below the span.
            lvdData.settings.simMaxDur = span/2;
            [~, wBelow] = v.validate();
            testCase.verifyNumElements(wBelow, 1, 'A simMaxDur below the span must warn.');
            testCase.verifyEqual(wBelow(1).str, ...
                sprintf(['Maximum simulation time of %.3f sec reached or exceeded.  ' ...
                         'Propagation terminated.  Consider increasing the maximum ' ...
                         'simulation time.'], span/2), ...
                'The warning must quote the configured simMaxDur, not the actual span.');
        end

        function checkMaxPropTimeReached(testCase)
            %Rule: warn when script.lastRunExecTime (WALL-CLOCK seconds spent
            %propagating, not mission time) reaches settings.maxScriptPropTime.
            %
            %lastRunExecTime is produced by the run itself, so the test drives
            %the threshold rather than the measurement -- that is the only dial
            %available without making the machine slow on purpose.
            lvdData = testCase.makeRunMission();
            execTime = lvdData.script.lastRunExecTime;
            testCase.assertGreaterThan(execTime, 0, ...
                'Fixture broken: lastRunExecTime was not recorded by executeScript.');

            v = MaxPropTimeReachedValidator(lvdData);

            %NEGATIVE.
            lvdData.settings.maxScriptPropTime = execTime + 1000;
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A generous maxScriptPropTime must not warn.');

            %BOUNDARY: exactly equal trips (the test is >=).
            lvdData.settings.maxScriptPropTime = execTime;
            [~, wEqual] = v.validate();
            testCase.verifyNumElements(wEqual, 1, ...
                'maxScriptPropTime exactly equal to lastRunExecTime must warn.');

            %POSITIVE.
            lvdData.settings.maxScriptPropTime = 0;
            [~, wZero] = v.validate();
            testCase.verifyNumElements(wZero, 1, 'A zero maxScriptPropTime must warn.');
            testCase.verifyTrue(contains(wZero(1).str, 'Maximum script propagation time of 0.000 sec'), ...
                'The warning must quote the configured maxScriptPropTime.');
        end

        function checkMinAltitudeReached(testCase)
            %Rule: warn when ANY state log entry's altitude is at or below
            %settings.minAltitude.  altitude is a Dependent property equal to
            %norm(position) - centralBody.radius, so the test can drive it from
            %either end: move the threshold, or move the vehicle.
            lvdData = testCase.makeRunMission();
            entries = lvdData.stateLog.getAllEntries();
            minAlt = min([entries.altitude]);

            v = MinAltitudeReachedValidator(lvdData);

            %NEGATIVE: the default minAltitude is -1 km, far below a 100 km orbit.
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A 100 km orbit must not trip a -1 km floor.');

            %BOUNDARY: a threshold exactly at the lowest altitude trips (<=).
            lvdData.settings.minAltitude = minAlt;
            [~, wEqual] = v.validate();
            testCase.verifyNumElements(wEqual, 1, ...
                'minAltitude exactly equal to the lowest altitude must warn (the test is <=).');

            %...and a hair below it does not.
            lvdData.settings.minAltitude = minAlt - 1e-6;
            [~, wJustBelow] = v.validate();
            testCase.verifyEmpty(wJustBelow, ...
                'A minAltitude just below the lowest altitude must not warn.');

            %POSITIVE via the other dial: drop the vehicle instead of raising
            %the floor.  Only entry 1 is moved, so only event 1 is named.
            lvdData.settings.minAltitude = 0;
            entries(1).position = [testCase.kerbin.radius - 10; 0; 0];
            [~, wSunk] = v.validate();
            testCase.verifyNumElements(wSunk, 1, 'A sub-surface entry must warn.');
            testCase.verifyTrue(contains(wSunk(1).str, 'Minimum altitude of 0.000 km'), ...
                'The warning must quote the configured minAltitude.');
            testCase.verifyTrue(contains(wSunk(1).str, '(Events: 1)'), ...
                'The warning must name only the event that actually went low.');
        end

        %% ------------------------------------------------------------------
        %  State-log-driven rules
        %  ------------------------------------------------------------------

        function checkAtmoWithNoDragModel(testCase)
            %Rule: for each event whose propagator is two-body, or is a
            %force-model propagator without the Drag model, warn when any of
            %that event's state log entries sits at an altitude in
            %[0, centralBody.atmohgt].
            %
            %Both ends of that interval matter.  A vehicle BELOW the surface
            %(negative altitude) is deliberately excluded: that is the
            %min-altitude validator's job, not this one's.
            lvdData = testCase.makeRunMission();
            atmoHgt = testCase.kerbin.atmohgt;
            R = testCase.kerbin.radius;
            testCase.assertGreaterThan(atmoHgt, 0, 'Fixture broken: Kerbin has no atmosphere.');

            v = AtmoWithNoDragModelValidator(lvdData);

            %NEGATIVE: a 100 km orbit is above the 70 km atmosphere.
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'An orbit above the atmosphere must not warn.');

            entries = lvdData.stateLog.getAllEntries();

            %BOUNDARY (upper): exactly at atmohgt trips, because the test is
            %altitude <= atmohgt.
            entries(1).position = [R + atmoHgt; 0; 0];
            [~, wAtTop] = v.validate();
            testCase.verifyNumElements(wAtTop, 1, ...
                'An entry exactly at atmohgt must warn (the test is <=).');

            %...and a hair above it does not.
            entries(1).position = [R + atmoHgt + 1e-6; 0; 0];
            [~, wAboveTop] = v.validate();
            testCase.verifyEmpty(wAboveTop, 'An entry just above atmohgt must not warn.');

            %BOUNDARY (lower): exactly at the surface trips (altitude >= 0)...
            entries(1).position = [R; 0; 0];
            [~, wAtSurface] = v.validate();
            testCase.verifyNumElements(wAtSurface, 1, ...
                'An entry exactly at the surface must warn (the test is >= 0).');

            %...but below the surface does NOT, by design.
            entries(1).position = [R - 1; 0; 0];
            [~, wBelowSurface] = v.validate();
            testCase.verifyEmpty(wBelowSurface, ...
                'A sub-surface entry is excluded from the atmosphere warning by design.');

            %POSITIVE, mid-atmosphere, and the message names only event 1.
            entries(1).position = [R + atmoHgt/2; 0; 0];
            [~, wInAtmo] = v.validate();
            testCase.verifyNumElements(wInAtmo, 1, 'A mid-atmosphere entry must warn.');
            testCase.verifyTrue(contains(wInAtmo(1).str, 'Drag model is disabled'), ...
                'Unexpected message text for the atmosphere warning.');
            testCase.verifyTrue(contains(wInAtmo(1).str, '(Events: 1)'), ...
                'The warning must name only the event with the low entry.');

            %NEGATIVE (the other dial): switch event 1 to a force-model
            %propagator that DOES include Drag.  The entry stays in the
            %atmosphere; only the force model list moves.
            evt1 = lvdData.script.getEventForInd(1);
            evt1.propagatorObj = evt1.forceModelPropagator;
            evt1.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Drag];
            [~, wWithDrag] = v.validate();
            testCase.verifyEmpty(wWithDrag, ...
                'An event with the Drag force model active must not warn.');

            %...and removing Drag again re-trips it, which confirms the force
            %model list is what silenced it.
            evt1.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            [~, wDragRemoved] = v.validate();
            testCase.verifyNumElements(wDragRemoved, 1, ...
                'Removing the Drag force model must re-trip the atmosphere warning.');

            %The message must be a complete, self-contained line.
            %
            %This validator's format string used to end '(Events: %s)\n%s'
            %while supplying only ONE argument, so sprintf emitted text up to
            %the conversion it had no argument for and stopped: the user got
            %the summary followed by a dangling blank line and no detail.  The
            %same one-argument-short bug lived in
            %  @ThrottleWithNoThrustModelValidator/...m  line 56
            %  @SomeEventsNotPlottedValidator/...m       line 29
            %  @MaxFixedStepsReachedValidator/...m       line 38
            %and each is asserted the same way in its own check below.
            %ConstraintValidator.m line 64 is the sibling that legitimately
            %does carry a detail substring, and
            %checkConstraintValidatorFixedBounds asserts that text is present
            %-- so a validator emitting a bare trailing newline is a defect,
            %not a house style.
            testCase.verifyFalse(endsWith(wDragRemoved(1).str, newline), ...
                'The warning must not end in a dangling newline from an unsupplied conversion.');
            testCase.verifyEqual(wDragRemoved(1).str, ...
                'Drag model is disabled on events that exist in an atmosphere. (Events: 1)', ...
                'Unexpected atmosphere warning text.');
        end

        function checkThrottleWithNoThrustModel(testCase)
            %Rule: warn when an event whose propagator has no Thrust force
            %model (two-body always qualifies) has a state log entry with
            %throttle > 0 -- EXCLUDING the entry at the event's final time,
            %because an action at the end of an event legitimately turns the
            %throttle on for the NEXT event.
            %
            %throttle is Dependent and delegates to the entry's throttleModel,
            %so the dial is: install a constant-throttle polynomial model on
            %one entry.  A FRESH model object is installed per entry rather
            %than mutating an existing one.  LaunchVehicleStateLogEntry
            %declares, at line 24,
            %    throttleModel AbstractThrottleModel = ThrottlePolyModel.getDefaultThrottleModel();
            %and a property default initialiser is evaluated once per class
            %load, so every entry that has not been given its own model shares
            %ONE handle.  Calling setPolyTerms on it would arm every entry in
            %the log at once and make the final-time exclusion below
            %untestable -- it would pass vacuously.
            lvdData = testCase.makeRunMission();
            v = ThrottleWithNoThrustModelValidator(lvdData);

            %NEGATIVE: a coasting mission has zero throttle everywhere.
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A zero-throttle coast must not warn.');

            evt1 = lvdData.script.getEventForInd(1);
            evt1Entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt1);
            testCase.assertGreaterThanOrEqual(numel(evt1Entries), 2, ...
                'Fixture broken: event 1 needs at least two state log entries.');

            %Identify the final-time entry the way the validator does, by
            %max(time), rather than assuming it is last in the array.
            [~, iLast] = max([evt1Entries.time]);
            iFirst = 1;
            testCase.assertNotEqual(iLast, iFirst, ...
                'Fixture broken: the first and final entries of event 1 coincide.');

            %BOUNDARY: the final-time entry of the event is exempt.
            evt1Entries(iLast).throttleModel = testCase.constantThrottleModel(0.5);
            [~, wFinalOnly] = v.validate();
            testCase.verifyEmpty(wFinalOnly, ...
                'Throttle on the final-time entry of an event is exempt by design.');

            %POSITIVE: a non-final entry is not exempt.
            evt1Entries(iFirst).throttleModel = testCase.constantThrottleModel(0.5);
            [~, wNonFinal] = v.validate();
            testCase.verifyNumElements(wNonFinal, 1, ...
                'Throttle on a non-final entry must warn.');
            testCase.verifyTrue(contains(wNonFinal(1).str, 'Throttle is greater than 0'), ...
                'Unexpected message text for the throttle warning.');
            testCase.verifyTrue(contains(wNonFinal(1).str, '(Events: 1)'), ...
                'The warning must name only the event with the live throttle.');

            %BOUNDARY: a throttle of exactly 0 on a non-final entry is not a
            %warning, because the test is strictly greater than zero.
            evt1Entries(iFirst).throttleModel = testCase.constantThrottleModel(0);
            evt1Entries(iLast).throttleModel  = testCase.constantThrottleModel(0);
            [~, wZero] = v.validate();
            testCase.verifyEmpty(wZero, 'A throttle of exactly 0 must not warn.');

            %NEGATIVE (the other dial): re-arm the non-final entry, then give
            %event 1 a force-model propagator that includes Thrust.
            evt1Entries(iFirst).throttleModel = testCase.constantThrottleModel(0.5);
            evt1.propagatorObj = evt1.forceModelPropagator;
            evt1.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Thrust];
            [~, wWithThrust] = v.validate();
            testCase.verifyEmpty(wWithThrust, ...
                'An event with the Thrust force model active must not warn about throttle.');
        end

        function checkRadiusOutsideSoI(testCase)
            %Rule: warn when any state log entry's radius exceeds the central
            %body's sphere-of-influence radius by more than 100 m.  The 0.1 km
            %pad exists so an entry sitting exactly on an SoI boundary -- which
            %is precisely where a legitimate SoI transition leaves it -- does
            %not warn.
            lvdData = testCase.makeRunMission();
            bodyInfo = testCase.kerbin;
            rSoI = getSOIRadius(bodyInfo, bodyInfo.getParBodyInfo(testCase.celBodyData));
            testCase.assertGreaterThan(rSoI, testCase.Smi, ...
                'Fixture broken: the test orbit must start inside the SoI.');

            v = RadiusOutsideSoIValidator(lvdData);

            %NEGATIVE.
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'An orbit inside the SoI must not warn.');

            entries = lvdData.stateLog.getAllEntries();

            %BOUNDARY: exactly on the SoI boundary is inside the 0.1 km pad.
            entries(1).position = [rSoI; 0; 0];
            [~, wOnBoundary] = v.validate();
            testCase.verifyEmpty(wOnBoundary, ...
                'An entry exactly on the SoI boundary is within the 0.1 km pad and must not warn.');

            %BOUNDARY: exactly at the far edge of the pad is still inside,
            %because the test is strictly greater than rSoI + 0.1.
            entries(1).position = [rSoI + 0.1; 0; 0];
            [~, wAtPad] = v.validate();
            testCase.verifyEmpty(wAtPad, ...
                'An entry exactly at rSoI + 0.1 km must not warn (the test is strictly >).');

            %POSITIVE: past the pad.
            entries(1).position = [rSoI + 1; 0; 0];
            [~, wOutside] = v.validate();
            testCase.verifyNumElements(wOutside, 1, 'An entry beyond the SoI pad must warn.');
            testCase.verifyTrue(contains(wOutside(1).str, 'outside of SoI radius'), ...
                'Unexpected message text for the SoI warning.');
            testCase.verifyTrue(contains(wOutside(1).str, '(Events: 1)'), ...
                'The warning must name only the event that left the SoI.');
        end

        function checkForceModelPropagatorWithNoForceModels(testCase)
            %Rule: warn when an event uses THE EVENT'S OWN force-model
            %propagator but its only active force model is plain Gravity AND
            %the central body has non-spherical gravity switched off -- i.e.
            %the expensive force-model integrator is doing exactly what the
            %cheap two-body propagator would do.
            %
            %Three dials each independently silence the rule; the test moves
            %them one at a time.
            lvdData = testCase.makeRunMission();
            evt1 = lvdData.script.getEventForInd(1);

            v = ForceModelPropagatorWithNoForceModelsValidator(lvdData);

            %NEGATIVE (dial 1): two-body propagator, so the rule does not apply.
            testCase.assertTrue(evt1.propagatorObj == evt1.twoBodyPropagator, ...
                'Fixture broken: event 1 should start on the two-body propagator.');
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A two-body event must not warn.');

            %POSITIVE: switch to the force-model propagator with Gravity only.
            evt1.propagatorObj = evt1.forceModelPropagator;
            evt1.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            testCase.assertFalse(testCase.kerbin.usenonsphericalgrav, ...
                'Fixture broken: Kerbin should not use non-spherical gravity.');

            [~, wGravOnly] = v.validate();
            testCase.verifyNumElements(wGravOnly, 1, ...
                'A force-model event with Gravity as its only model must warn.');
            testCase.verifyTrue(contains(wGravOnly(1).str, 'no force models active'), ...
                'Unexpected message text for the redundant-force-model warning.');
            testCase.verifyTrue(contains(wGravOnly(1).str, '(Events: 1)'), ...
                'The warning must name only event 1.');

            %NEGATIVE (dial 2): add a second force model.  The rule requires
            %length(forceModels) == 1, so two models silence it.
            evt1.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Drag];
            [~, wTwoModels] = v.validate();
            testCase.verifyEmpty(wTwoModels, ...
                'Two active force models must silence the validator.');

            %NEGATIVE (dial 3): back to Gravity only, but turn on non-spherical
            %gravity so the force-model propagator really is doing more than
            %two-body would.
            evt1.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            [~, wBackOn] = v.validate();
            testCase.assertNumElements(wBackOn, 1, ...
                'Fixture broken: restoring Gravity-only should re-trip the rule.');

            %The validator reads usenonsphericalgrav off the FIRST state log
            %entry's central body, so a copy is installed on that entry rather
            %than mutating the shared celestial body database.
            entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt1);
            bodyCopy = testCase.copyBodyInfo(testCase.kerbin);
            bodyCopy.usenonsphericalgrav = true;
            entries(1).centralBody = bodyCopy;

            [~, wNonSpherical] = v.validate();
            testCase.verifyEmpty(wNonSpherical, ...
                'Non-spherical gravity on the central body must silence the validator.');
        end

        function checkThirdBodyGravity(testCase)
            %Rule: two independent, opposite warnings, both applying only to
            %events on the event's own force-model propagator.
            %  (a) Gravity3rdBody is active but the event's INITIAL state has
            %      no third-body sources selected -> the model does nothing.
            %  (b) third-body sources ARE selected but Gravity3rdBody is off
            %      -> the user's selection is silently ignored.
            lvdData = testCase.makeRunMission();
            evt1 = lvdData.script.getEventForInd(1);
            firstEntry = lvdData.stateLog.getFirstStateLogForEvent(evt1);
            testCase.assertNotEmpty(firstEntry, 'Fixture broken: event 1 has no state log entry.');

            v = ThirdBodyGravityValidator(lvdData);

            %NEGATIVE (not a force-model event): even with a contradictory
            %configuration, the rule does not look at two-body events.
            firstEntry.thirdBodyGravity.bodies = testCase.mun;
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'A two-body event is never examined by this rule.');

            evt1.propagatorObj = evt1.forceModelPropagator;

            %POSITIVE (b): sources selected, force model off.
            evt1.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            [~, wHasBodies] = v.validate();
            testCase.verifyNumElements(wHasBodies, 1, ...
                'Third-body sources with the force model off must warn.');
            testCase.verifyTrue(contains(wHasBodies(1).str, ...
                'third body gravity sources active in the event''s initial state but the Third Body Gravity force model is inactive'), ...
                'Wrong message for the "sources but no model" case.');
            testCase.verifyTrue(contains(wHasBodies(1).str, '(Events: 1)'), ...
                'The warning must name event 1.');

            %NEGATIVE: turn the model on -- both halves now agree.
            evt1.forceModelPropagator.forceModels = [ForceModelsEnum.Gravity, ForceModelsEnum.Gravity3rdBody];
            [~, wAgree] = v.validate();
            testCase.verifyEmpty(wAgree, ...
                'Model on and sources present is a consistent configuration.');

            %POSITIVE (a): model on, no sources.
            firstEntry.thirdBodyGravity.bodies = KSPTOT_BodyInfo.empty(1,0);
            [~, wNoBodies] = v.validate();
            testCase.verifyNumElements(wNoBodies, 1, ...
                'The force model with no sources must warn.');
            testCase.verifyTrue(contains(wNoBodies(1).str, ...
                'Third Body Gravity force model active but there are no third body gravity sources'), ...
                'Wrong message for the "model but no sources" case.');

            %NEGATIVE: both off is also consistent.
            evt1.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            [~, wBothOff] = v.validate();
            testCase.verifyEmpty(wBothOff, 'Model off and no sources is a consistent configuration.');
        end

        function checkMaxFixedStepsReached(testCase)
            %Rule: warn when an event integrates with a FIXED step (step size
            %> 0) and the number of state log entries it produced reaches the
            %configured maximum -- the signal that integration was cut short
            %rather than ended by its own termination condition.
            %
            %Both the step size and the cap live on the event's integrator
            %options object.  That object is a handle (AbstractIntegratorOptions
            %derives from matlab.mixin.SetGet) and is constructed per
            %integrator inside ODE45Integrator's constructor, so each event has
            %its own and the test can move one event's dials without touching
            %the other's.  The assertion below makes that assumption explicit.
            lvdData = testCase.makeRunMission();
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = lvdData.script.getEventForInd(2);
            opts1 = evt1.integratorObj.getOptions();
            opts2 = evt2.integratorObj.getOptions();
            testCase.assertFalse(opts1 == opts2, ...
                'Fixture broken: the two events share one integrator options object.');

            nEvt1 = numel(lvdData.stateLog.getAllStateLogEntriesForEvent(evt1));
            nEvt2 = numel(lvdData.stateLog.getAllStateLogEntriesForEvent(evt2));
            testCase.assertGreaterThanOrEqual(nEvt1, 2, ...
                'Fixture broken: event 1 needs at least two state log entries.');

            v = MaxFixedStepsReachedValidator(lvdData);

            %NEGATIVE (dial 1): variable step (step size -1 by default), so the
            %rule does not apply no matter how small the cap is.
            testCase.assertLessThanOrEqual(opts1.getIntegratorStepSize(), 0, ...
                'Fixture broken: the default integrator should be variable step.');
            opts1.maxNumFixedSteps = 1;
            opts2.maxNumFixedSteps = 1;
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, ...
                'A variable-step event must not warn even with a cap of one step.');

            %NEGATIVE (dial 2): fixed step, but the cap is above the entry count
            %on both events.  Nothing is re-propagated, so the entry counts stay
            %exactly as recorded above.
            opts1.setIntegratorStepSize(10);
            opts1.maxNumFixedSteps = nEvt1 + 1;
            opts2.maxNumFixedSteps = 1e9;
            [~, wUnderCap] = v.validate();
            testCase.verifyEmpty(wUnderCap, 'An entry count below the cap must not warn.');

            %BOUNDARY: exactly at the cap trips, because the test is >=.
            opts1.maxNumFixedSteps = nEvt1;
            [~, wAtCap] = v.validate();
            testCase.verifyNotEmpty(wAtCap, ...
                'An entry count exactly at the cap must warn (the test is >=).');
            testCase.verifyTrue(contains(wAtCap(1).str, 'Maximum number of fixed step sizes reached'), ...
                'Unexpected message text for the fixed-step warning.');
            testCase.verifyTrue(contains(wAtCap(1).str, '(Events: 1)'), ...
                'The warning must name event 1.');

            %ONE warning, naming all offending events -- the way every other
            %multi-event validator in this folder does it (compare
            %RadiusOutsideSoIValidator.m, whose emit block sits after its event
            %loop, not inside it).  This validator used to emit from INSIDE the
            %`for(i=1:length(evts))` loop, so once warnEvtNums went non-empty
            %every remaining iteration appended another identical copy.
            numEvts = numel(lvdData.script.evts);
            testCase.assertEqual(numEvts, 2, 'Fixture broken: expected a two-event script.');
            testCase.verifyNumElements(wAtCap, 1, ...
                'One warning must be emitted regardless of how many events follow the offending one.');

            %The count must also not depend on WHICH event offends.  Making
            %only the LAST event trip is the control case: a misplaced emit
            %block has no later iteration to duplicate into and so produces
            %exactly one warning here even when it produced numEvts above.
            opts1.setIntegratorStepSize(-1);
            opts2.setIntegratorStepSize(10);
            opts2.maxNumFixedSteps = nEvt2;
            [~, wEvt2Only] = v.validate();
            testCase.verifyNumElements(wEvt2Only, 1, ...
                'A trip on the last event must also produce exactly one warning.');
            testCase.verifyTrue(contains(wEvt2Only(1).str, '(Events: 2)'), ...
                'The warning must name event 2.');

            %No dangling newline from an unsupplied sprintf conversion; see the
            %fuller note in checkAtmoWithNoDragModel.
            testCase.verifyFalse(endsWith(wEvt2Only(1).str, newline), ...
                'The warning must not end in a dangling newline from an unsupplied conversion.');
            testCase.verifyTrue(endsWith(wEvt2Only(1).str, '(Events: 2)'), ...
                'The warning must end with the event list, with no truncated detail after it.');
        end

        function checkSomeEventsNotPlotted(testCase)
            %Rule: warn when the selected view profile has plotAllEvents off
            %AND a non-empty eventsToPlot list that does not cover every event.
            %The non-empty guard is deliberate: an empty list means "nothing
            %configured yet", which is not worth nagging about.
            lvdData = testCase.makeRunMission();
            profile = lvdData.viewSettings.selViewProfile;
            evts = lvdData.script.evts;
            testCase.assertEqual(numel(evts), 2, 'Fixture broken: expected a two-event script.');

            v = SomeEventsNotPlottedValidator(lvdData);

            %NEGATIVE (dial 1): plotAllEvents is on by default.
            testCase.assertTrue(profile.plotAllEvents, ...
                'Fixture broken: a default view profile should plot all events.');
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, 'plotAllEvents == true must never warn.');

            %NEGATIVE (dial 2): plotAllEvents off but the list is empty --
            %"nothing configured", explicitly exempted.
            profile.plotAllEvents = false;
            profile.eventsToPlot = LaunchVehicleEvent.empty(1,0);
            [~, wEmptyList] = v.validate();
            testCase.verifyEmpty(wEmptyList, ...
                'An empty eventsToPlot list is exempt by design.');

            %NEGATIVE (dial 3): the list covers every event.
            profile.eventsToPlot = evts;
            [~, wCoversAll] = v.validate();
            testCase.verifyEmpty(wCoversAll, ...
                'An eventsToPlot list covering every event must not warn.');

            %POSITIVE: the list omits event 2.
            profile.eventsToPlot = evts(1);
            [~, wPartial] = v.validate();
            testCase.verifyNumElements(wPartial, 1, ...
                'An eventsToPlot list missing an event must warn.');
            testCase.verifyTrue(contains(wPartial(1).str, 'not being plotted'), ...
                'Unexpected message text for the not-plotted warning.');
            testCase.verifyTrue(contains(wPartial(1).str, '(Events: 2)'), ...
                'The warning must name exactly the omitted event, not the plotted one.');

            %No dangling newline from an unsupplied sprintf conversion; see the
            %fuller note in checkAtmoWithNoDragModel.
            testCase.verifyFalse(endsWith(wPartial(1).str, newline), ...
                'The warning must not end in a dangling newline from an unsupplied conversion.');
            testCase.verifyEqual(wPartial(1).str, ...
                'The following events are not being plotted. (Events: 2)', ...
                'Unexpected not-plotted warning text.');
        end

        function checkConstraintValidatorFixedBounds(testCase)
            %Rule (FixedBounds arm): warn when a constraint's last evaluated
            %value sits at or outside its own bounds -- value <= lb or
            %value >= ub.  Note that "exactly at the bound" counts: an ACTIVE
            %constraint is worth surfacing, not just a violated one, which is
            %why the message says "active or violated".
            %
            %lastRunValues is a side effect of evaluating the constraint set,
            %so the fixture calls evalConstraints rather than fabricating the
            %record by hand.  tfRunScript is false and stateLogToEval is empty,
            %which makes evalConstraints reuse the state log already on
            %lvdData -- no re-propagation, and the constraint value is
            %therefore exactly the coasting mission's throttle: zero percent.
            lvdData = testCase.makeRunMission();
            evt2 = lvdData.script.getEventForInd(2);
            constraints = lvdData.optimizer.constraints;

            %NEGATIVE: bounds that straddle the actual value of 0%.
            const = ThrottleConstraint(evt2, -10, 90);
            constraints.addConstraint(const);
            constraints.evalConstraints([], false, [], false, []);

            v = ConstraintValidator(lvdData);
            [errors, warnings] = v.validate();
            testCase.verifyEmpty(errors, 'This validator never produces errors.');
            testCase.verifyEmpty(warnings, ...
                'A constraint comfortably inside its bounds must not warn.');

            %BOUNDARY: a lower bound exactly at the value trips, because the
            %test is value <= lb.
            const.lb = 0;
            constraints.evalConstraints([], false, [], false, []);
            [~, wAtLb] = v.validate();
            testCase.verifyNumElements(wAtLb, 1, ...
                'A value exactly on the lower bound must warn (the test is <=).');

            %BOUNDARY: an upper bound exactly at the value trips too (>=).
            const.lb = -10;
            const.ub = 0;
            constraints.evalConstraints([], false, [], false, []);
            [~, wAtUb] = v.validate();
            testCase.verifyNumElements(wAtUb, 1, ...
                'A value exactly on the upper bound must warn (the test is >=).');

            %POSITIVE: move the whole window above the value.  Only the bounds
            %move; the mission is untouched.
            const.lb = 10;
            const.ub = 90;
            constraints.evalConstraints([], false, [], false, []);
            [~, wViolated] = v.validate();
            testCase.verifyNumElements(wViolated, 1, ...
                'A constraint outside its bounds must warn.');
            testCase.verifyTrue(contains(wViolated(1).str, 'active or violated'), ...
                'Unexpected message text for the constraint warning.');
            testCase.verifyTrue(contains(wViolated(1).str, '(Events: 2)'), ...
                'The warning must name the event the constraint is attached to.');

            %The detail line must quote the numbers on its own line after the
            %summary.  ConstraintValidator is the one validator here that
            %genuinely has a two-part message: line 64 supplies both sprintf
            %arguments (the second being strjoin(detailStrs,'\n')), so a
            %newline must be present.  That contrast is why the bare trailing
            %newline the other four validators used to emit was a truncation
            %rather than house style -- see checkAtmoWithNoDragModel.
            testCase.verifyTrue(contains(wViolated(1).str, newline), ...
                'The constraint warning must carry a detail line after a newline.');
            testCase.verifyTrue(contains(wViolated(1).str, 'Constraint (Event 2'), ...
                'The detail line must identify the constraint type and event number.');
            testCase.verifyTrue(contains(wViolated(1).str, 'Value = 0.000000'), ...
                'The detail line must quote the evaluated constraint value.');
            testCase.verifyTrue(contains(wViolated(1).str, 'Bounds: [10.000000'), ...
                'The detail line must quote the constraint bounds.');

            %NEGATIVE (the other dial): deactivate the constraint.  It is then
            %skipped by evalConstraints, so lastRunValues no longer contains it
            %and the validator has nothing to complain about.
            const.active = false;
            constraints.evalConstraints([], false, [], false, []);
            [~, wInactive] = v.validate();
            testCase.verifyEmpty(wInactive, ...
                'A deactivated constraint must not appear in the validation output.');
        end

        %% ------------------------------------------------------------------
        %  Orchestrator
        %  ------------------------------------------------------------------

        function checkValidationOrchestrator(testCase)
            %LaunchVehicleDataValidation owns registration, concatenation and
            %the "all clear" sentinel.
            lvdData = testCase.makeRunMission();
            validation = lvdData.validation;

            %The maximum-propagation-time rule compares against WALL CLOCK time
            %and its default threshold is only 5 seconds, so on a cold or
            %loaded machine it can fire for reasons that have nothing to do
            %with what this check is about.  Take it out of the picture
            %explicitly; checkMaxPropTimeReached covers the rule itself.
            lvdData.settings.maxScriptPropTime = inf;

            expectedOrder = { ...
                'NoOptimizationVariablesValidator', ...
                'OptimizationVariablesNearBoundsValidator', ...
                'ConstraintValidator', ...
                'MaxSimTimeReachedValidator', ...
                'MaxPropTimeReachedValidator', ...
                'ThrottleWithNoThrustModelValidator', ...
                'AtmoWithNoDragModelValidator', ...
                'MinAltitudeReachedValidator', ...
                'RadiusOutsideSoIValidator', ...
                'ForceModelPropagatorWithNoForceModelsValidator', ...
                'ThirdBodyGravityValidator', ...
                'MaxFixedStepsReachedValidator', ...
                'SomeEventsNotPlottedValidator'};

            testCase.verifyNumElements(validation.validators, numel(expectedOrder), ...
                'Wrong number of registered validators.');
            for(i = 1:numel(expectedOrder))
                testCase.verifyEqual(class(validation.validators(i)), expectedOrder{i}, ...
                    sprintf('Registered validator %u is not %s.', i, expectedOrder{i}));
            end

            %The baseline mission trips exactly one rule: it has no
            %optimization variables.
            validation.clearOutputs();
            validation.validate();
            testCase.verifyNumElements(validation.outputs, 1, ...
                'The baseline mission should produce exactly one warning.');
            testCase.verifyClass(validation.outputs(1), 'LaunchVehicleDataValidationWarning', ...
                'The baseline output should be a warning, not an error or an OK.');

            %Silence that one rule and the orchestrator must emit the OK
            %sentinel rather than leaving the output array empty.  The bounds
            %straddle the actual 600 s duration symmetrically so the
            %near-bounds validator, which is registered immediately after,
            %does not take its place.
            testCase.addDurationVar(lvdData, 2, testCase.EvtDur/2, testCase.EvtDur*1.5);
            validation.clearOutputs();
            validation.validate();
            testCase.verifyNumElements(validation.outputs, 1, ...
                'A clean mission should produce exactly one output.');
            testCase.verifyClass(validation.outputs(1), 'LaunchVehicleDataValidationOK', ...
                'A clean mission must produce the OK sentinel.');
            testCase.verifyEqual(validation.outputs(1).str, 'No errors or warnings found.', ...
                'Unexpected OK message text.');

            %clearOutputs must empty the array.
            validation.clearOutputs();
            testCase.verifyEmpty(validation.outputs, 'clearOutputs did not empty the outputs.');

            %Outputs pushed in from outside must survive a validate() call and
            %must suppress the OK sentinel, because the sentinel is emitted
            %only when outputs was ALREADY empty.  That is the mechanism
            %plugins rely on to report their own errors.
            validation.outputs(end+1) = LaunchVehicleDataValidationError('injected');
            validation.validate();
            testCase.verifyNumElements(validation.outputs, 1, ...
                'A pre-existing output must survive validate() on an otherwise clean mission.');
            testCase.verifyClass(validation.outputs(1), 'LaunchVehicleDataValidationError', ...
                'A pre-existing error must not be replaced by the OK sentinel.');

            %Warnings from several rules accumulate into one flat array in
            %registration order.  Trip the two cheapest ones and confirm both
            %survive concatenation, in order.
            validation.clearOutputs();
            lvdData.settings.simMaxDur = 1;
            lvdData.settings.minAltitude = 1e9;
            validation.validate();
            testCase.verifyNumElements(validation.outputs, 2, ...
                'Two tripped rules must produce two accumulated outputs.');
            testCase.verifyTrue(contains(validation.outputs(1).str, 'Maximum simulation time'), ...
                'Outputs must appear in registration order (sim time is registered fourth).');
            testCase.verifyTrue(contains(validation.outputs(2).str, 'Minimum altitude'), ...
                'Outputs must appear in registration order (min altitude is registered eighth).');
        end

        %% ------------------------------------------------------------------
        %  Checks spanning more than one validator
        %  ------------------------------------------------------------------

        function checkFreshEventPropagatorIdentity(testCase)
            %A freshly constructed LaunchVehicleEvent must have
            %propagatorObj ALIASING forceModelPropagator, not pointing at a
            %separate anonymous ForceModelPropagator.
            %
            %Two validators gate on that handle identity --
            %  @ForceModelPropagatorWithNoForceModelsValidator/...m line 24
            %  @ThirdBodyGravityValidator/...m               line 23
            %    if(evt.propagatorObj == evt.forceModelPropagator)
            %-- so if the constructor hands out two distinct objects, both
            %validators skip every fresh event silently, and the force model
            %list the user edits through evt.forceModelPropagator is not the
            %list living on the object propagatorObj points at.  The
            %constructor did exactly that until it was fixed.
            %
            %That aliasing is the intended invariant rather than an accident
            %is confirmed by LaunchVehicleEvent.loadobj, which repairs this
            %very case on load:
            %    if(isempty(obj.propagatorObj))
            %        obj.propagatorObj = obj.forceModelPropagator;
            lvdData = testCase.makeRunMission();

            %A fresh event, configured the way the GUI's "add event" path leaves
            %it, except for a termination condition so the script can run.  Its
            %propagator is deliberately NOT reassigned.
            evt3 = LaunchVehicleEvent(lvdData.script);
            evt3.termCond = EventDurationTermCondition(testCase.EvtDur);
            lvdData.script.addEvent(evt3);
            lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), ...
                false, false, false, false, false);

            testCase.assertEqual(evt3.propagatorObj.propagatorEnum, PropagatorEnum.ForceModel, ...
                'Fixture broken: a fresh event should default to force-model propagation.');

            testCase.verifyTrue(evt3.propagatorObj == evt3.forceModelPropagator, ...
                ['A fresh event must alias propagatorObj to its own ' ...
                 'forceModelPropagator, not to a separate anonymous one.']);

            %Configure the event so that BOTH identity-gated validators must
            %fire: Gravity as the only force model (redundant on a body
            %without non-spherical gravity), plus a third-body source with the
            %third-body force model switched off.
            evt3.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;
            firstEntry = lvdData.stateLog.getFirstStateLogForEvent(evt3);
            testCase.assertNotEmpty(firstEntry, 'Fixture broken: event 3 produced no state log entries.');
            firstEntry.thirdBodyGravity.bodies = testCase.mun;

            vFm  = ForceModelPropagatorWithNoForceModelsValidator(lvdData);
            vTbg = ThirdBodyGravityValidator(lvdData);

            [~, wForceModel] = vFm.validate();
            testCase.verifyNumElements(wForceModel, 1, ...
                'A fresh force-model event with only Gravity must raise the redundant-force-model warning.');
            testCase.verifyTrue(contains(wForceModel(1).str, '(Events: 3)'), ...
                'The redundant-force-model warning must name event 3.');

            [~, wThirdBody] = vTbg.validate();
            testCase.verifyNumElements(wThirdBody, 1, ...
                'A fresh force-model event with a third body but no third-body force model must warn.');
            testCase.verifyTrue(contains(wThirdBody(1).str, '(Events: 3)'), ...
                'The third-body warning must name event 3.');

            %Control: switching event 3 to two-body propagation breaks the
            %identity both validators gate on, and both must then fall silent.
            %This confirms the warnings above are produced by the force-model
            %path rather than by something else about event 3.
            evt3.propagatorObj = evt3.twoBodyPropagator;

            [~, wForceModelTwoBody] = vFm.validate();
            testCase.verifyEmpty(wForceModelTwoBody, ...
                'A two-body event must not raise the redundant-force-model warning.');

            [~, wThirdBodyTwoBody] = vTbg.validate();
            testCase.verifyEmpty(wThirdBodyTwoBody, ...
                'A two-body event must not raise the third-body warning.');
        end

        function checkForceModelValidatorSkipsEmptyStateLog(testCase)
            %An event with no state log entries -- which happens whenever the
            %log has been trimmed, or a run terminated before reaching that
            %event -- must simply be skipped, the way ThirdBodyGravityValidator
            %skips it with an explicit not(isempty(stateLogEntry)) test at
            %@ThirdBodyGravityValidator/ThirdBodyGravityValidator.m line 27.
            %
            %ForceModelPropagatorWithNoForceModelsValidator used to write its
            %guard as numel(stateLogEntries(1)) >= 1, which can never be false:
            %MATLAB evaluates stateLogEntries(1) before numel sees the result,
            %so on an empty array the indexing throws MATLAB:badsubscript
            %first.  That aborted the entire validation pass, silently dropping
            %every validator registered after it.
            lvdData = testCase.makeRunMission();
            evt1 = lvdData.script.getEventForInd(1);
            evt2 = lvdData.script.getEventForInd(2);

            %Event 2 uses its own force-model propagator with Gravity only, so
            %it reaches the faulty line...
            evt2.propagatorObj = evt2.forceModelPropagator;
            evt2.forceModelPropagator.forceModels = ForceModelsEnum.Gravity;

            %...and then its state log entries are removed, leaving event 1's
            %behind.  Nothing else about the mission changes.
            evt1Entries = lvdData.stateLog.getAllStateLogEntriesForEvent(evt1);
            testCase.assertNotEmpty(evt1Entries, 'Fixture broken: event 1 has no state log entries.');
            lvdData.stateLog.clearStateLog();
            lvdData.stateLog.appendStateLogEntries(evt1Entries);
            testCase.assertEmpty(lvdData.stateLog.getAllStateLogEntriesForEvent(evt2), ...
                'Fixture broken: event 2 should have no state log entries.');

            v = ForceModelPropagatorWithNoForceModelsValidator(lvdData);
            [errFm, warnFm] = v.validate();
            testCase.verifyEmpty(errFm, ...
                'This validator never produces errors.');
            testCase.verifyEmpty(warnFm, ...
                'An event with no state log entries must be skipped, not indexed into.');

            %Control: the sibling validator with a correctly placed guard
            %handles the same fixture without complaint, which shows the fixture
            %is legitimate and the difference is the guard.
            vTbg = ThirdBodyGravityValidator(lvdData);
            [errTbg, warnTbg] = vTbg.validate();
            testCase.verifyEmpty(errTbg, ...
                'ThirdBodyGravityValidator must tolerate an event with no state log entries.');
            testCase.verifyEmpty(warnTbg, ...
                'ThirdBodyGravityValidator must skip an event with no state log entries.');
        end

        %% ------------------------------------------------------------------
        %  Fixtures
        %  ------------------------------------------------------------------

        function lvdData = makeRunMission(testCase)
            %Two coasting events in a 100 km circular Kerbin orbit, actually
            %propagated so the state log holds real entries.
            ksptotAddProjectPaths();

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            elems = KeplerianElementSet(0, testCase.Smi, 0, 0.1, 0, 0, 0, testCase.kerbinFrame);
            lvdData.initStateModel.orbitModel = elems;

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(testCase.EvtDur);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            evt2 = LaunchVehicleEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(testCase.EvtDur);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), ...
                false, false, false, false, false);

            testCase.assertNotEmpty(lvdData.stateLog.getAllEntries(), ...
                'Fixture broken: executeScript left the state log empty.');
        end

        function var = addDurationVar(~, lvdData, evtInd, lb, ub)
            %Adds an ENABLED duration variable on the given event.  The returned
            %object exposes varObj, the termination condition whose `duration`
            %property is the unscaled variable value, so callers can place the
            %variable at an exact point in its range without going through the
            %scaled x vector.
            evt = lvdData.script.getEventForInd(evtInd);
            var = EventDurationOptimizationVariable(evt.termCond);
            var.useTf = true;
            var.lb = lb;
            var.ub = ub;
            lvdData.optimizer.vars.addVariable(var);
        end

        function model = constantThrottleModel(~, value)
            %A ThrottlePolyModel whose constant term is the requested value and
            %whose linear and quadratic terms are zero, so getThrottleAtTime
            %returns `value` at every epoch.  A FRESH object every call: these
            %models are handles and are shared between state log entries by
            %default.
            model = ThrottlePolyModel.getDefaultThrottleModel();
            model.setT0(0);
            model.setPolyTerms(value, 0, 0);
        end
    end
end
