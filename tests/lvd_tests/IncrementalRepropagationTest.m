classdef IncrementalRepropagationTest < KsptotTestCase
    %IncrementalRepropagationTest Incremental re-propagation caching in LVD.
    %
    % Validates that during optimization-style evaluations the script can
    % (a) resume propagation from the earliest event whose optimization
    % variables changed while producing state logs bit-identical to a full
    % propagation, (b) serve the cached log without integrating anything
    % when nothing changed, and (c) fall back to full propagation whenever
    % reuse would be unsafe (script looping actions, plugins, disabled
    % setting).

    properties(Constant, Access=private)
        Gmu = 3531.6;          %Kerbin GM, km^3/s^2
        Smi = 7000;            %orbit radius, km
        EvtDur = 600;          %nominal event duration, s
    end

    methods(Test)

        %% Resuming from a late event reproduces the full-run log bitwise

        function resumeFromStaticFloorMatchesFullRun(testCase)
            lvdData = testCase.makeThreeEventScript();

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();

            %Full run establishes the cached log for events 1..N.
            vars.updateObjsWithScaledVarValues(x0);
            logFull = testCase.runScript(lvdData, 1, false);
            fpFull = testCase.fingerprint(logFull);

            %Second evaluation with identical inputs but a static floor on
            %event 2 (cold committed-x baseline -> static floor path).
            vars.updateObjsWithScaledVarValues(x0);
            logResumed = testCase.runScript(lvdData, 2, true);
            fpResumed = testCase.fingerprint(logResumed);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 1);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 2);
            testCase.verifyFingerprintsMatch(fpFull, fpResumed, 'Resumed state log differs from the full-propagation log');
        end

        %% A change to a late-event variable resumes at that event only

        function changedLateVarResumesAtThatEvent(testCase)
            lvdData = testCase.makeThreeEventScript();
            vars = lvdData.optimizer.vars;

            x0 = vars.getTotalScaledXVector();

            %Baseline at x0.
            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            %Perturb only the event-2 duration; dynamic detection must
            %resume from event 2.
            x1 = x0;
            x1(end) = testCase.scaledDuration(700);

            vars.updateObjsWithScaledVarValues(x1);
            logInc = testCase.runScript(lvdData, 2, true);
            fpInc = testCase.fingerprint(logInc);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 1);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 2);

            %The incremental result must match a full run at x1 bitwise.
            vars.updateObjsWithScaledVarValues(x1);
            logRef = testCase.runScript(lvdData, 1, false);
            fpRef = testCase.fingerprint(logRef);

            testCase.verifyFingerprintsMatch(fpRef, fpInc, 'Incremental result at perturbed x differs from full propagation');
        end

        %% An evaluation with unchanged inputs integrates nothing

        function unchangedXServesCachedLog(testCase)
            lvdData = testCase.makeThreeEventScript();
            vars = lvdData.optimizer.vars;

            x0 = vars.getTotalScaledXVector();

            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            x1 = x0;
            x1(end) = testCase.scaledDuration(700);

            vars.updateObjsWithScaledVarValues(x1);
            testCase.runScript(lvdData, 2, true);

            %Repeat evaluation at the same x: must not integrate anything.
            vars.updateObjsWithScaledVarValues(x1);
            logSkip = testCase.runScript(lvdData, 2, true);

            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 0);
            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 3);
        end

        %% A changed early-event variable forces full re-propagation

        function changedEarlyVarForcesFullRun(testCase)
            lvdData = testCase.makeThreeEventScript(true);
            vars = lvdData.optimizer.vars;

            x0 = vars.getTotalScaledXVector();

            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            %Perturb the event-1 duration: nothing may be reused.
            x1 = x0;
            x1(1) = testCase.scaledDuration(650);

            vars.updateObjsWithScaledVarValues(x1);
            logInc = testCase.runScript(lvdData, 3, true);
            fpInc = testCase.fingerprint(logInc);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 0);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 3);

            vars.updateObjsWithScaledVarValues(x1);
            logRef = testCase.runScript(lvdData, 1, false);

            testCase.verifyFingerprintsMatch(testCase.fingerprint(logRef), fpInc, 'Full-run-forced result differs from reference full propagation');
        end

        %% A changed non-event-owned variable forces full re-propagation

        function changedInitialStateVarForcesFullRun(testCase)
            lvdData = testCase.makeThreeEventScript();

            %Initial-state epoch time variable: not owned by any event, so
            %it must map to "affects everything".
            initVar = InitialStateVariable(lvdData.initStateModel);
            initVar.useTf = true;
            initVar.lb = -10000;
            initVar.ub = 10000;
            lvdData.optimizer.vars.addVariable(initVar);

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();

            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            x1 = x0;
            x1(1) = testCase.scaledInitTime(500);  %initial-state epoch shifts every event

            vars.updateObjsWithScaledVarValues(x1);
            logInc = testCase.runScript(lvdData, 3, true);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 0);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 3);
        end

        %% SetNextEventAction disables all reuse

        function setNextEventActionDisablesReuse(testCase)
            lvdData = testCase.makeThreeEventScript();

            %Flow-neutral here (event 2 is next anyway), but its presence
            %must still disable caching outright.
            loopAction = SetNextEventAction(lvdData.script.getEventForInd(2));
            evt1 = lvdData.script.getEventForInd(1);
            evt1.addAction(loopAction);

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();

            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            x1 = x0;
            x1(end) = testCase.scaledDuration(700);

            vars.updateObjsWithScaledVarValues(x1);
            logInc = testCase.runScript(lvdData, 2, true);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 0);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 3);

            %Even though reuse was refused, the full propagation that ran
            %is a valid baseline for the next evaluation.
            testCase.verifyFalse(isempty(vars.getCommittedX()));
        end

        %% Disabling the setting restores classic full-propagation behavior

        function settingDisabledForcesFullRun(testCase)
            lvdData = testCase.makeThreeEventScript();
            lvdData.settings.enableIncrementalRepropagation = false;

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();

            vars.updateObjsWithScaledVarValues(x0);
            testCase.runScript(lvdData, 1, false);

            x1 = x0;
            x1(end) = testCase.scaledDuration(700);

            vars.updateObjsWithScaledVarValues(x1);
            logInc = testCase.runScript(lvdData, 2, true);

            testCase.verifyEqual(lvdData.script.lastNumEvtsSkipped, 0);
            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 3);
            testCase.verifyFalse(lvdData.script.lastRunUsedIncremental);
            testCase.verifyEmpty(vars.getCommittedX());
        end
    end

    methods(Access=private)

        function lvdData = makeThreeEventScript(testCase, varargin)
            %makeThreeEventScript Coast-only three-event two-body script.
            %   Optional second input adds an event-1 duration variable.
            if(nargin < 2)
                addEvt1Var = false;
            else
                addEvt1Var = varargin{1};
            end

            ksptotAddProjectPaths();

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            %Circular-ish low Kerbin orbit starting at epoch 0.
            elems = KeplerianElementSet(0, testCase.Smi, 0.01, 0.1, 0, 0, 0, testCase.kerbinFrame);
            lvdData.initStateModel.orbitModel = elems;

            %Three coast events on the two-body propagator.
            evt1 = lvdData.script.getEventForInd(1);
            testCase.configureCoastEvent(evt1, testCase.EvtDur);

            evt2 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt2, testCase.EvtDur);
            lvdData.script.addEvent(evt2);

            evt3 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt3, testCase.EvtDur);
            lvdData.script.addEvent(evt3);

            %Duration variables.
            if(addEvt1Var)
                var1 = EventDurationOptimizationVariable(evt1.termCond);
                var1.useTf = true;
                var1.lb = 10;
                var1.ub = 100000;
                lvdData.optimizer.vars.addVariable(var1);
            end

            var2 = EventDurationOptimizationVariable(evt2.termCond);
            var2.useTf = true;
            var2.lb = 10;
            var2.ub = 100000;
            lvdData.optimizer.vars.addVariable(var2);
        end

        function configureCoastEvent(~, evt, duration)
            evt.termCond = EventDurationTermCondition(duration);
            evt.propagatorObj = evt.twoBodyPropagator;
        end

        function stateLog = runScript(~, lvdData, startEvtInd, allowIncrementalReuse)
            stateLog = lvdData.script.executeScript(false, ...
                lvdData.script.getEventForInd(startEvtInd), ...
                false, false, false, false, allowIncrementalReuse);
        end

        function xs = scaledDuration(~, unscaledDur)
            %Maps an unscaled event duration onto the variable''s scaled
            %space for the fixture bounds lb=10, ub=100000.
            lb = 10;
            ub = 100000;
            xs = (unscaledDur - (lb + ub)/2) / ((ub - lb)/2);
        end

        function xs = scaledInitTime(~, unscaledTime)
            %Maps an unscaled initial-state epoch onto scaled space for
            %the fixture bounds lb=-10000, ub=10000.
            lb = -10000;
            ub = 10000;
            xs = (unscaledTime - (lb + ub)/2) / ((ub - lb)/2);
        end

        function fp = fingerprint(~, stateLog)
            fp = stateLogToFingerprint(stateLog);
        end

        function verifyFingerprintsMatch(testCase, fpA, fpB, msg)
            %verifyFingerprintsMatch Bitwise comparison with actionable diagnostics.
            if(fpA.numEntries ~= fpB.numEntries)
                testCase.verifyFail(sprintf('%s: entry counts differ (%d vs %d).', ...
                    msg, fpB.numEntries, fpA.numEntries));
                return;
            end

            diffRow = NaN;
            diffCol = NaN;
            for(i = 1:fpA.numEntries)
                for(j = 1:fpA.numCols)
                    a = fpA.matrix(i, j);
                    b = fpB.matrix(i, j);
                    if(not(isnan(a) && isnan(b)) && not(a == b))
                        diffRow = i;
                        diffCol = j;
                        break;
                    end
                end
                if(not(isnan(diffRow)))
                    break;
                end
            end

            if(isnan(diffRow))
                testCase.verifyTrue(true, msg);
                return;
            end

            testCase.verifyFail(sprintf( ...
                '%s: fingerprints differ at entry %d, col %d (%.17g vs %.17g).', ...
                msg, diffRow, diffCol, fpB.matrix(diffRow, diffCol), fpA.matrix(diffRow, diffCol)));
        end
    end
end







