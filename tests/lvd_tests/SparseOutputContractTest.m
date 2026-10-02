classdef SparseOutputContractTest < KsptotTestCase
    %SparseOutputContractTest The sparse/dense state log contract.
    %
    % A sparse state log keeps only the endpoints of each event.  Anything
    % that reads more than the one entry it is anchored to -- a path
    % integral such as cumulative Delta-V, or an extremum -- then returns a
    % plausible but badly wrong number with no warning.  Two defects came
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
    %
    % The behavioural halves below are the parts that would actually have
    % caught these: the cumulative Delta-V oracle is spelled out here
    % rather than borrowed from lvd_CumulativeDeltaVTasks.

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
    end

    methods(Access=private)

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
