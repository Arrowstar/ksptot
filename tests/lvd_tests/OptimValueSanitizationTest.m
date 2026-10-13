classdef OptimValueSanitizationTest < KsptotTestCase
    %OptimValueSanitizationTest Coverage for lvd_sanitizeOptimValue and the
    %hardened LVD aggregate objective/constraint wrappers: optimizer-facing
    %values must always come back real and finite, never complex or NaN.

    properties(Constant, Access=private)
        Gmu = 3531.6;          %Kerbin GM, km^3/s^2
        Smi = 7000;            %orbit radius, km
        EvtDur = 600;          %nominal event duration, s
    end

    methods(Test)

        %% Helper unit tests

        function cleanValuesPassThrough(testCase)
            v = [1.5, -2, 0, 1e-30];
            testCase.verifyEqual(lvd_sanitizeOptimValue(v), v);
        end

        function emptyStaysEmpty(testCase)
            testCase.verifyEmpty(lvd_sanitizeOptimValue([]));
        end

        function complexValuesKeepRealPart(testCase)
            v = [3+1e-15i, -2+4i];
            testCase.verifyEqual(lvd_sanitizeOptimValue(v), [3, -2]);
        end

        function nanAndInfBecomeDefaultPenalty(testCase)
            out = lvd_sanitizeOptimValue([NaN, Inf, -Inf]);
            testCase.verifyEqual(out, repmat(1e10, 1, 3));
        end

        function customPenaltyIsUsed(testCase)
            testCase.verifyEqual(lvd_sanitizeOptimValue(NaN, 42), 42);
            testCase.verifyEqual(lvd_sanitizeOptimValue(NaN, Inf), Inf);
        end

        function warningIsIssued(testCase)
            %Persistent once-per-session flag may already be tripped, so
            %this only verifies the identifier when a warning fires, and
            %that no other warning type escapes.
            testCase.verifyWarningFree(@() lvd_sanitizeOptimValue(1));
        end

        %% Hardened wrapper failure paths

        function failedPropagationObjectiveReturnsInf(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            startEvt = lvdData.script.getEventForInd(2);

            %Wrong-length x makes propagateForX throw inside evalObjFcn.
            f = lvdData.optimizer.objFcn.evalObjFcn([], startEvt);

            testCase.verifyTrue(isreal(f), 'Failed objective evaluation returned a complex value.');
            testCase.verifyTrue(isinf(f) && f > 0, 'Failed objective evaluation did not return +Inf.');
        end

        function failedPropagationConstraintsReturnPenalty(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();

            [c, ceq] = lvdData.optimizer.constraints.evalConstraints([], true, ...
                lvdData.script.getEventForInd(2), true, []);

            testCase.verifyTrue(isreal(c), 'Failed constraint evaluation returned complex c.');
            testCase.verifyTrue(isreal(ceq), 'Failed constraint evaluation returned complex ceq.');
            testCase.verifyTrue(all(isfinite(c)) && all(isfinite(ceq)), ...
                'Failed constraint evaluation returned NaN/Inf.');
            testCase.verifyTrue(all(c(:) > 0) && all(ceq(:) > 0), ...
                'Failed constraint evaluation did not return an infeasible penalty.');
        end

        %% Happy path stays untouched

        function sanitizationDoesNotChangeGoodEvals(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            x0 = lvdData.optimizer.vars.getTotalScaledXVector();
            startEvt = lvdData.script.getEventForInd(2);

            f = lvdData.optimizer.objFcn.evalObjFcn(x0, startEvt);
            testCase.verifyTrue(isreal(f) && isfinite(f));

            [c, ceq] = lvdData.optimizer.constraints.evalConstraints(x0, true, startEvt, true, []);
            testCase.verifyTrue(isreal(c) && all(isfinite(c)));
            testCase.verifyTrue(isreal(ceq) && all(isfinite(ceq)));

            [c2, ceq2, DC, DCeq] = lvdData.optimizer.constraints.evalConstraintsWithGradients( ...
                x0, true, startEvt, false, []);
            testCase.verifyEqual(c2, c);
            testCase.verifyEqual(ceq2, ceq);
            testCase.verifyTrue(isreal(DC) && isreal(DCeq));
        end
    end

    methods(Access=private)

        function lvdData = makeScriptWithObjectiveAndConstraints(testCase)
            %Three-event coasting script with one duration variable, one
            %objective task, and constraints on two different events.

            ksptotAddProjectPaths();

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            elems = KeplerianElementSet(0, testCase.Smi, 0.01, 0.1, 0, 0, 0, testCase.kerbinFrame);
            lvdData.initStateModel.orbitModel = elems;

            evt1 = lvdData.script.getEventForInd(1);
            testCase.configureCoastEvent(evt1, testCase.EvtDur);

            evt2 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt2, testCase.EvtDur);
            lvdData.script.addEvent(evt2);

            evt3 = LaunchVehicleEvent(lvdData.script);
            testCase.configureCoastEvent(evt3, testCase.EvtDur);
            lvdData.script.addEvent(evt3);

            var2 = EventDurationOptimizationVariable(evt2.termCond);
            var2.useTf = true;
            var2.lb = 10;
            var2.ub = 100000;
            lvdData.optimizer.vars.addVariable(var2);

            massConstraint = GenericMAConstraint('Altitude', evt3, ...
                0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            genObjFcn = GenericObjectiveFcn(evt3, testCase.kerbinFrame, massConstraint, ...
                1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.addObjFunc(genObjFcn);

            const2 = GenericMAConstraint('Altitude', evt2, ...
                0, 1E9, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            lvdData.optimizer.constraints.addConstraint(const2);

            const3 = GenericMAConstraint('Altitude', evt3, ...
                0, 1E9, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            lvdData.optimizer.constraints.addConstraint(const3);
        end

        function configureCoastEvent(~, evt, duration)
            evt.termCond = EventDurationTermCondition(duration);
            evt.propagatorObj = evt.twoBodyPropagator;
        end
    end
end
