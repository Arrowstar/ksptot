classdef SparseOutputContractTest < KsptotTestCase
    %SparseOutputContractTest The sparse/dense state log contract.
    %
    % A sparse state log keeps only the endpoints of each event.  Anything
    % that reads more than the one entry it is anchored to -- a path
    % integral such as cumulative Delta-V, or an extremum -- then returns a
    % plausible but badly wrong number with no warning.  Four defects came
    % out of that:
    %
    %   1. GenericMAConstraint declared itself sparse safe unconditionally,
    %      including for 'Cumulative Delta-V Expended', so an optimization
    %      using it as objective or constraint propagated sparsely and
    %      optimized the wrong quantity.
    %   2. ConstraintSet.evalConstraints would evaluate against a sparse
    %      log it was handed (or fell back to) with no check at all, and
    %      the incremental re-propagation path could splice a dense tail
    %      onto a sparse prefix, producing a log that is neither.
    %   3. Readers holding one entry during propagation -- an extremum on
    %      cumulative Delta-V, a quantity-comparison conditional, a
    %      plugin-variable action -- integrated over that lone entry and
    %      always read 0.  A conditional reading it also steers the
    %      mission, so the script must refuse sparse output.
    %   4. Extrema n Value / Calculus n Value tasks were declared sparse
    %      safe, but sparse output drops the integrator samples before
    %      they are folded into those values.
    %
    % The behavioural halves below are the parts that would actually have
    % caught these: the cumulative Delta-V oracle is spelled out here
    % rather than borrowed from lvd_CumulativeDeltaVTasks.  The scripted
    % missions only burn impulsively and coast without mass flow, so the
    % oracle is a sum of burn magnitudes.

    properties(Constant, Access=private)
        Smi = 7000;     %orbit radius, km
        EvtDur = 600;   %event duration, s
    end

    methods(Test)

        %% The sparse-safety predicate, both polarities

        function cumulativeDeltaVIsNotSparseSafe(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);

            conCum = testCase.makeConstraint('Cumulative Delta-V Expended', evt);
            conAlt = testCase.makeConstraint('Altitude', evt);

            testCase.verifyFalse(conCum.canUseSparseOutput(), ...
                'A path integral over the log cannot be evaluated on event endpoints alone.');
            testCase.verifyTrue(conAlt.canUseSparseOutput(), ...
                'A single-entry task must stay sparse safe; forcing dense output for it is pure cost.');

            testCase.verifyTrue(GenericMAConstraint.isHistoryDependentTask('Cumulative Delta-V Expended'));
            testCase.verifyFalse(GenericMAConstraint.isHistoryDependentTask('Altitude'));
        end

        function extremaAndCalculusTasksAreNotSparseSafe(testCase)
            %Sparse output drops samples before extrema and calculus
            %objects see them, so reading their value off one entry is no
            %help.
            testCase.verifyTrue(GenericMAConstraint.isHistoryDependentTask('Extrema 1 Value - "Maximum Altitude"'));
            testCase.verifyTrue(GenericMAConstraint.isHistoryDependentTask('Calculus 12 Value - "x"'));
            testCase.verifyFalse(GenericMAConstraint.isHistoryDependentTask('Stopwatch 1 Value - "x"'), ...
                'A single-entry generated task must stay sparse safe.');
        end

        %% Sparse really does lose the value, not merely resolve it coarsely

        function sparseLogUnderReportsCumulativeDeltaV(testCase)
            [lvdData, entries, expectedDv] = testCase.makeImpulsiveLog();
            evt = lvdData.script.getEventForInd(1);

            con = testCase.makeConstraint('Cumulative Delta-V Expended', evt);

            denseLog = testCase.makeStateLog(lvdData, entries, false);
            [~, ~, denseValue] = con.evalConstraint(denseLog, testCase.celBodyData);

            testCase.verifyEqual(denseValue, expectedDv, 'RelTol', 1e-9, ...
                'Dense log must integrate to the sum of the impulsive magnitudes.');

            %What a sparse run would have left behind: first and last entry
            %only.  Both ends coast (no mass flow), so the whole burn
            %history collapses to exactly zero -- not an approximation.
            sparseLog = testCase.makeStateLog(lvdData, entries([1, end]), true);
            [~, ~, sparseValue] = con.evalConstraint(sparseLog, testCase.celBodyData);

            testCase.verifyEqual(sparseValue, 0, 'AbsTol', 1e-12, ...
                'Endpoints-only evaluation drops the entire burn history: this is the defect.');
            testCase.verifyGreaterThan(expectedDv, 0.01, ...
                'Fixture sanity: the oracle must be a meaningful non-zero Delta-V.');
        end

        %% ConstraintSet refuses a sparse log a constraint cannot use

        function evalConstraintsRejectsSparseLogForDenseOnlyConstraint(testCase)
            [lvdData, entries] = testCase.makeImpulsiveLog();
            evt = lvdData.script.getEventForInd(1);

            set = lvdData.optimizer.constraints;
            set.addConstraint(testCase.makeConstraint('Cumulative Delta-V Expended', evt));

            sparseLog = testCase.makeStateLog(lvdData, entries, true);

            testCase.verifyError(@() set.evalConstraints([], false, [], false, sparseLog), ...
                'ConstraintSet:sparseStateLog', ...
                'A dense-only constraint handed a sparse log must refuse, not return a wrong number.');
        end

        function evalConstraintsAcceptsSparseLogForSparseSafeConstraints(testCase)
            [lvdData, entries] = testCase.makeImpulsiveLog();
            evt = lvdData.script.getEventForInd(1);

            set = lvdData.optimizer.constraints;
            set.addConstraint(testCase.makeConstraint('Altitude', evt));

            sparseLog = testCase.makeStateLog(lvdData, entries, true);

            [~, ~, value] = set.evalConstraints([], false, [], false, sparseLog);

            %Independent oracle: altitude at the final node of the log.
            expected = norm(entries(end).position) - entries(end).centralBody.radius;

            testCase.verifyEqual(value, expected, 'RelTol', 1e-9, ...
                'A set of only sparse-safe constraints must evaluate a sparse log without complaint.');
        end

        function evalConstraintsFallbackLogIsAlsoChecked(testCase)
            %Branch 3: no log handed in, so the set reads lvdData.stateLog.
            [lvdData, entries] = testCase.makeImpulsiveLog();
            evt = lvdData.script.getEventForInd(1);

            lvdData.stateLog.clearStateLog();
            lvdData.stateLog.appendStateLogEntries(entries);
            lvdData.stateLog.wasSparse = true;

            set = lvdData.optimizer.constraints;
            set.addConstraint(testCase.makeConstraint('Cumulative Delta-V Expended', evt));

            testCase.verifyError(@() set.evalConstraints([], false, [], false), ...
                'ConstraintSet:sparseStateLog', ...
                'The fallback log needs the same check as one handed in.');
        end

        %% The main GUI calls evalConstraints with four inputs

        function evalConstraintsToleratesFourInputs(testCase)
            %ma_LvdMainGUI_App's two Jacobian menus call
            %evalConstraints(x, true, evt, false).  Nothing may require the
            %sixth input.
            lvdData = testCase.makeCoastScript();
            evt = lvdData.script.getEventForInd(1);

            set = lvdData.optimizer.constraints;
            set.addConstraint(testCase.makeConstraint('Altitude', evt));

            x = lvdData.optimizer.vars.getTotalScaledXVector();

            testCase.verifyWarningFree(@() set.evalConstraints(x, true, evt, false), ...
                'The four-input GUI call must not depend on stateLogToEval being supplied.');
        end

        %% A granularity flip forces a full re-propagation, never a splice

        function granularityFlipForcesFullRunAndStampsTheLog(testCase)
            lvdData = testCase.makeCoastScript();
            lvdData.settings.enableIncrementalRepropagation = true;

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();

            %Cold dense run: the reference entry count.
            vars.updateObjsWithScaledVarValues(x0);
            logDense = testCase.runScript(lvdData, false, 1, false);
            denseCount = numel(logDense.entries);
            testCase.verifyFalse(logDense.wasSparse, 'A dense run must stamp the log dense.');

            %Sparse run over the same script.
            vars.updateObjsWithScaledVarValues(x0);
            logSparse = testCase.runScript(lvdData, true, 1, true);
            testCase.verifyTrue(logSparse.wasSparse, 'A sparse run must stamp the log sparse.');
            testCase.verifyLessThan(numel(logSparse.entries), denseCount, ...
                'Fixture sanity: sparse output must actually drop entries.');

            %Now flip back to dense WITH incremental reuse enabled.  Nothing
            %of the sparse log may survive: splicing a dense tail onto a
            %sparse prefix is what made wasSparse meaningless.
            vars.updateObjsWithScaledVarValues(x0);
            logFlip = testCase.runScript(lvdData, false, 1, true);

            testCase.verifyFalse(logFlip.wasSparse, ...
                'After flipping to dense the log must no longer be marked sparse.');
            testCase.verifyEqual(numel(logFlip.entries), denseCount, ...
                'A granularity flip must re-propagate everything, not splice onto the sparse prefix.');
        end

        %% Lone-entry readers recover the history from the state log

        function loneEntryCumulativeDeltaVReadsTheLog(testCase)
            [lvdData, entries, expectedDv] = testCase.makeImpulsiveLog();
            dv1 = entries(2).velocity - entries(1).velocity;
            dv2 = entries(4).velocity - entries(3).velocity;
            task = GraphicalAnalysisTask('Cumulative Delta-V Expended', testCase.kerbinFrame);

            lvdData.stateLog.clearStateLog();
            lvdData.stateLog.appendStateLogEntries(entries(1:3));

            %Not in the log yet (actions after propagation work on a copy):
            %the logged history plus its own impulsive segment.
            testCase.verifyEqual(testCase.executeLoneTask(task, entries(4), lvdData), expectedDv, 'RelTol', 1e-9, ...
                'An entry not yet in the log must add its own segment to the logged history.');

            %The log's last element (actions before propagation mutate it
            %in place): same answer...
            lvdData.stateLog.appendStateLogEntries(entries(4));
            testCase.verifyEqual(testCase.executeLoneTask(task, entries(4), lvdData), expectedDv, 'RelTol', 1e-9, ...
                'An entry at the end of the log must read the same cumulative value.');

            %...and it must follow a later mutation, not a memoized copy.
            dvExtra = [0; 0; 0.02];
            entries(4).velocity = entries(4).velocity + dvExtra;
            testCase.verifyEqual(testCase.executeLoneTask(task, entries(4), lvdData), norm(dv1) + norm(dv2 + dvExtra), 'RelTol', 1e-9, ...
                'Mutating the last entry must change the answer: nothing may have memoized it.');

            %In the middle of the log: the prefix up to it, nothing after.
            testCase.verifyEqual(testCase.executeLoneTask(task, entries(2), lvdData), norm(dv1), 'RelTol', 1e-9, ...
                'A mid-log entry must integrate only up to itself.');
        end

        %% Extremum on cumulative Delta-V, conditional on it, sparse veto

        function extremumOnCumulativeDeltaVTracksTheIntegral(testCase)
            [lvdData, ex, dvs] = testCase.makeBurnScript();
            lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false);

            entries = lvdData.stateLog.getAllEntries();
            evts = lvdData.script.evts;
            exInd = find(lvdData.launchVehicle.extrema == ex);

            %The integral steps by norm(dv) at each burn, which ends an
            %event, so the maximum seen during event e is the sum of the
            %burns of events 1..e-1.
            for(e = 1:numel(evts))
                evtEntries = entries([entries.event] == evts(e));
                expected = sum(vecnorm(dvs(:, 1:e-1), 2, 1));
                testCase.verifyEqual(evtEntries(end).extremaStates(exInd).value, expected, 'AbsTol', 1e-12, ...
                    sprintf('Max cumulative Delta-V during event %u must equal the burns before it.', e));
            end

            %Read through a constraint on the extremum's GA task.  That task
            %is now history dependent (not sparse safe) but must still be
            %read off the entry -- not routed into the cumulative integral,
            %which would coincide here only because every burn is
            %positive, so evaluate it at event 2 where they differ: the
            %integral at its final node includes event 2's own burn, the
            %extremum does not.
            exStrs = lvdData.launchVehicle.getExtremaGraphAnalysisTaskStrs();
            con = testCase.makeConstraint(exStrs{exInd}, evts(2));
            testCase.verifyFalse(con.canUseSparseOutput());
            [~, ~, value] = con.evalConstraint(lvdData.stateLog, testCase.celBodyData);
            testCase.verifyEqual(value, norm(dvs(:, 1)), 'AbsTol', 1e-12, ...
                'An extremum task must read the extremum value, not the cumulative integral.');
        end

        function conditionalOnCumulativeDeltaVBranchesOnTheIntegral(testCase)
            %Two burns of known size before event 3.  Its conditional fires
            %a third burn only if it sees their sum; reading the lone entry
            %it saw 0 and never fired.
            [lvdData, ~, dvs] = testCase.makeBurnScript();
            spent = sum(vecnorm(dvs, 2, 1));
            dv3 = [0; 0; 0.07];

            testCase.addCumulativeDvConditional(lvdData, spent - 0.01, dv3);
            testCase.verifyEqual(testCase.runAndMeasureLastBurn(lvdData), dv3, 'AbsTol', 1e-12, ...
                'Threshold just below the Delta-V already spent: the branch must fire.');

            [lvdData, ~, ~] = testCase.makeBurnScript();
            testCase.addCumulativeDvConditional(lvdData, spent + 0.01, dv3);
            testCase.verifyEqual(testCase.runAndMeasureLastBurn(lvdData), [0; 0; 0], 'AbsTol', 1e-12, ...
                'Threshold just above the Delta-V already spent: the branch must not fire.');
        end

        function historyReadingActionVetoesSparseOutput(testCase)
            [lvdData, ~, ~] = testCase.makeBurnScript();
            testCase.verifyTrue(lvdData.script.canUseSparseOutput(), ...
                'Fixture sanity: plain burns do not read history.');
            stateLog = lvdData.script.executeScript(true, lvdData.script.getEventForInd(1), false, false, false, false);
            testCase.verifyTrue(stateLog.wasSparse, 'Without a history reader sparse output must be honoured.');

            [lvdData, ~, ~] = testCase.makeBurnScript();
            testCase.addCumulativeDvConditional(lvdData, 0, [0; 0; 0]);
            testCase.verifyFalse(lvdData.script.canUseSparseOutput(), ...
                'A conditional reading cumulative Delta-V must veto sparse output.');
            stateLog = lvdData.script.executeScript(true, lvdData.script.getEventForInd(1), false, false, false, false);
            testCase.verifyFalse(stateLog.wasSparse, ...
                'executeScript must run dense when an action reads the trajectory history.');
        end
    end

    methods(Access=private)

        function value = executeLoneTask(testCase, task, entry, lvdData)
            propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();
            [value, unit] = task.executeTask(entry, QuantityComparisonActionCondition.maTaskList, 0, [], [], propNames, testCase.celBodyData);
            testCase.verifyEqual(unit, 'km/s');
        end

        function [lvdData, ex, dvs] = makeBurnScript(testCase)
            %makeBurnScript Three two-body coast events, the first two
            %ending in an impulsive inertial burn, plus a maximum extremum
            %on cumulative Delta-V.  Coasting changes no mass, so every
            %coast segment contributes exactly 0 and the integral is the
            %sum of the burn magnitudes.
            lvdData = testCase.makeCoastScript();

            ex = LaunchVehicleExtrema(lvdData);
            ex.quantStr = 'Cumulative Delta-V Expended';
            ex.frame = testCase.kerbinFrame;
            ex.type = LaunchVehicleExtremaTypeEnum.Maximum;
            lvdData.launchVehicle.addExtremum(ex);

            evt3 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt3);
            lvdData.script.addEvent(evt3);

            dvs = [[0.05; 0.02; 0], [0; -0.03; 0.04]];
            for(e = 1:2)
                lvdData.script.getEventForInd(e).addAction(AddDeltaVAction(dvs(:, e), DeltaVFrameEnum.Inertial, false));
            end
        end

        function addCumulativeDvConditional(testCase, lvdData, threshold, dv)
            frame = testCase.kerbinFrame;
            qc = QuantityComparisonActionCondition(GraphicalAnalysisTask('Cumulative Delta-V Expended', frame), ...
                threshold, ComparisonTypeEnum.GreaterThan, 0, frame);

            cond = ConditionalAction();
            cond.ifCondition = qc;
            cond.addIfAction(AddDeltaVAction(dv, DeltaVFrameEnum.Inertial, false));
            lvdData.script.getEventForInd(3).addAction(cond);
        end

        function dv = runAndMeasureLastBurn(~, lvdData)
            %Velocity jump applied by event 3's actions: its final logged
            %entry minus its last integrated one (the first entry at the
            %event's final time).
            lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false);
            entries = lvdData.stateLog.getAllEntries();
            evt3Entries = entries([entries.event] == lvdData.script.getEventForInd(3));
            lastIntegrated = evt3Entries(find([evt3Entries.time] == evt3Entries(end).time, 1, 'first'));
            dv = evt3Entries(end).velocity(:) - lastIntegrated.velocity(:);
        end

        function con = makeConstraint(testCase, type, evt) %#ok<INUSD>
            con = GenericMAConstraint(type, evt, 0, 5, [], [], KSPTOT_BodyInfo.empty(1,0));
        end

        function stateLog = makeStateLog(~, lvdData, entries, wasSparse)
            stateLog = LaunchVehicleStateLog(lvdData);
            stateLog.appendStateLogEntries(entries);
            stateLog.wasSparse = wasSparse;
        end

        function [lvdData, entries, expectedDv] = makeImpulsiveLog(testCase)
            %makeImpulsiveLog Four-entry log holding two impulsive burns
            %separated by a coast.
            %
            %Impulsive pairs (two entries at the same time, differing only
            %in velocity) keep the oracle free of any engine, throttle or
            %mass-flow modelling: the increment is norm(dv) by definition.
            %The coast step in the middle contributes nothing, so the whole
            %dense value is a sum this test file can state outright.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);

            e1 = lvdData.initStateModel.getInitialStateLogEntry();
            e1.position = [0; 0; testCase.kerbin.radius + 2400];
            e1.velocity = [1; 0; 0];
            e1.time = 100;
            e1.event = evt;

            dv1 = [0.05; 0.02; 0];
            e2 = e1.deepCopy();
            e2.event = evt;            %same time: impulsive
            e2.velocity = e2.velocity + dv1;

            e3 = e2.deepCopy();        %coast: no mass flow, no contribution
            e3.event = evt;
            e3.time = 200;

            dv2 = [0; -0.03; 0.04];
            e4 = e3.deepCopy();
            e4.event = evt;            %same time as e3: impulsive
            e4.velocity = e4.velocity + dv2;

            entries = [e1, e2, e3, e4];
            expectedDv = norm(dv1) + norm(dv2);
        end

        function lvdData = makeCoastScript(testCase)
            %makeCoastScript Two coast events on the two-body propagator,
            %with a duration variable so there is an x vector to pass.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            elems = KeplerianElementSet(0, testCase.Smi, 0.01, 0.1, 0, 0, 0, testCase.kerbinFrame);
            lvdData.initStateModel.orbitModel = elems;

            evt1 = lvdData.script.getEventForInd(1);
            testCase.configureCoastEvent(evt1);

            evt2 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt2);
            lvdData.script.addEvent(evt2);

            var = EventDurationOptimizationVariable(evt2.termCond);
            var.useTf = true;
            var.lb = 10;
            var.ub = 100000;
            lvdData.optimizer.vars.addVariable(var);
        end

        function configureCoastEvent(testCase, evt)
            evt.termCond = EventDurationTermCondition(testCase.EvtDur);
            evt.propagatorObj = evt.twoBodyPropagator;
        end

        function stateLog = runScript(~, lvdData, isSparseOutput, startEvtInd, allowIncrementalReuse)
            stateLog = lvdData.script.executeScript(isSparseOutput, ...
                lvdData.script.getEventForInd(startEvtInd), ...
                false, false, false, false, allowIncrementalReuse);
        end
    end
end
