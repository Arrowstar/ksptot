classdef OptimizationEntryPointTest < KsptotTestCase
    %OptimizationEntryPointTest Production optimization entry-point coverage.
    %
    % These tests exercise the EXACT functions the LVD optimizers invoke --
    % CompositeObjectiveFcn.evalObjFcn and ConstraintSet.evalConstraints
    % (plus its gradient form) -- rather than calling executeScript
    % directly.  This guards against wiring regressions between the
    % optimizer wrappers and the script runner, such as argument-count
    % mismatches that surface only as NaN objectives during real
    % optimizations while every direct-call test stays green.

    properties(Constant, Access=private)
        Gmu = 3531.6;          %Kerbin GM, km^3/s^2
        Smi = 7000;            %orbit radius, km
        EvtDur = 600;          %nominal event duration, s
    end

    properties(TestParameter)
        enableIncremental = {false, true};
    end

    methods(Test)

        %% Objective wrapper returns a finite value (toggle off and on)

        function objectiveWrapperReturnsFiniteValue(testCase, enableIncremental)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = enableIncremental;

            x0 = lvdData.optimizer.vars.getTotalScaledXVector();

            f = lvdData.optimizer.objFcn.evalObjFcn(x0, ...
                lvdData.script.getEventForInd(2));

            testCase.verifyTrue(isa(f, 'double'), 'Objective did not return a double.');
            testCase.verifyFalse(isnan(f), 'Objective returned NaN (likely swallowed exception).');
            testCase.verifyFalse(isinf(f), 'Objective returned Inf.');
        end

        %% Constraint wrapper returns finite, correctly-sized vectors

        function constraintWrapperReturnsFiniteValues(testCase, enableIncremental)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = enableIncremental;

            x0 = lvdData.optimizer.vars.getTotalScaledXVector();

            [c, ceq] = lvdData.optimizer.constraints.evalConstraints(x0, true, ...
                lvdData.script.getEventForInd(2), false, []);

            testCase.verifyTrue(isempty(c) || all(isfinite(c)), 'Inequality constraints contain NaN/Inf.');
            testCase.verifyTrue(isempty(ceq) || all(isfinite(ceq)), 'Equality constraints contain NaN/Inf.');
            testCase.verifyTrue(~(isempty(c) && isempty(ceq)), 'No constraints were evaluated at all.');
        end

        %% Repeat evaluation through the objective wrapper skips integration

        function repeatEvalThroughWrapperSkipsIntegration(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = true;

            x0 = lvdData.optimizer.vars.getTotalScaledXVector();
            startEvt = lvdData.script.getEventForInd(2);

            f1 = lvdData.optimizer.objFcn.evalObjFcn(x0, startEvt);
            intAfterFirst = lvdData.script.lastNumEvtsIntegrated;

            f2 = lvdData.optimizer.objFcn.evalObjFcn(x0, startEvt);

            testCase.verifyEqual(lvdData.script.lastNumEvtsIntegrated, 0, ...
                'Second identical evaluation should not integrate any events.');
            testCase.verifyEqual(f2, f1, 'Repeat evaluation changed the objective value.');
            testCase.verifyTrue(intAfterFirst > 0, 'First evaluation never integrated anything.');
        end

        %% Gradient form of the constraint wrapper returns finite Jacobians

        function constraintGradientWrapperReturnsFiniteJacobians(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = true;

            x0 = lvdData.optimizer.vars.getTotalScaledXVector();

            [cAtX0, cEqAtX0, DC, DCeq] = lvdData.optimizer.constraints.evalConstraintsWithGradients( ...
                x0, true, lvdData.script.getEventForInd(2), false, []);

            testCase.verifyTrue(all(isfinite(DC(:))), 'Constraint Jacobian DC contains NaN/Inf.');
            testCase.verifyTrue(all(isfinite(DCeq(:))), 'Constraint Jacobian DCeq contains NaN/Inf.');
            testCase.verifyEqual(size(DC, 1), numel(x0), 'DC rows do not match variable count.');
            testCase.verifyEqual(size(DCeq, 1), numel(x0), 'DCeq rows do not match variable count.');

            %Sanity: baseline values inside the gradient routine match a
            %direct evaluation at the same point.
            [c2, ceq2] = lvdData.optimizer.constraints.evalConstraints(x0, true, ...
                lvdData.script.getEventForInd(2), false, []);
            testCase.verifyEqual(c2, cAtX0);
            testCase.verifyEqual(ceq2, cEqAtX0);
        end

        %% Serial custom finite-difference gradient through the objective wrapper

        function serialCustomFdGradientMatchesLoopReference(testCase)
            %Regression: computeGradAtPoint's serial path used an inline
            %parfor with a struct auto-creation trick that returned all-NaN
            %gradients when the wrapped function closed over large object
            %graphs (like LVD missions).  Pin the fixed behavior against a
            %hand-rolled loop reference.

            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = true;

            lvdOpt = lvdData.optimizer;
            startEvt = lvdData.script.getEventForInd(2);
            objFun = @(x) lvdOpt.objFcn.evalObjFcn(x, startEvt);

            fd = CustomFiniteDiffsCalculationMethod();
            x0 = lvdOpt.vars.getTotalScaledXVector();
            f0 = objFun(x0);
            testCase.verifyFalse(isnan(f0), 'Baseline objective is NaN.');

            g = fd.computeGrad(objFun, x0, f0, false);

            testCase.verifyTrue(all(isfinite(g)), 'Serial custom-FD gradient contains NaN/Inf.');

            gRef = zeros(1, numel(x0));
            for(j = 1:numel(x0))
                xp = x0;
                xp(j) = xp(j) + fd.h;
                gRef(j) = (objFun(xp) - f0) / fd.h;
            end

            testCase.verifyLessThanOrEqual(max(abs(g - gRef)), 1E-8 * max(1, max(abs(gRef))), ...
                'Serial custom-FD gradient disagrees with loop reference.');
        end

        %% Row and column x vectors must produce identical results

        function mixedShapeXEvalsAgree(testCase)
            %Regression: finite-difference machinery passes x as a COLUMN
            %while earlier evaluations used rows.  Change detection stored
            %the raw shapes and the element-wise diff silently expanded to
            %a matrix, corrupting resume decisions.  Both shapes must yield
            %identical objectives and a working incremental path.

            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = true;

            lvdOpt = lvdData.optimizer;
            x0 = lvdOpt.vars.getTotalScaledXVector();
            startEvt = lvdData.script.getEventForInd(2);

            fRowFirst = lvdOpt.objFcn.evalObjFcn(x0, startEvt);           %row
            fColSecond = lvdOpt.objFcn.evalObjFcn(x0(:), startEvt);       %column, same values
            fRowAgain = lvdOpt.objFcn.evalObjFcn(x0(:).', startEvt);      %row again

            testCase.verifyEqual(fColSecond, fRowFirst);
            testCase.verifyEqual(fRowAgain, fRowFirst);

            %Perturbation in column form through the incremental path.
            x1col = x0(:);
            x1col(end) = testCase.scaledDuration(700);
            fPertCol = lvdOpt.objFcn.evalObjFcn(x1col, startEvt);

            x1row = x1col(:).';
            fPertRow = lvdOpt.objFcn.evalObjFcn(x1row, startEvt);

            testCase.verifyEqual(fPertRow, fPertCol);
            testCase.verifyFalse(isnan(fPertCol));
        end

        %% Perturbed evaluation differs from the cached one

        function perturbedEvalThroughWrapperChangesObjective(testCase)
            lvdData = testCase.makeScriptWithObjectiveAndConstraints();
            lvdData.settings.enableIncrementalRepropagation = true;

            vars = lvdData.optimizer.vars;
            x0 = vars.getTotalScaledXVector();
            startEvt = lvdData.script.getEventForInd(2);

            f1 = lvdData.optimizer.objFcn.evalObjFcn(x0, startEvt);

            x1 = x0;
            x1(end) = testCase.scaledDuration(700);
            f2 = lvdData.optimizer.objFcn.evalObjFcn(x1, startEvt);

            testCase.verifyFalse(isnan(f2), 'Perturbed evaluation returned NaN.');
            testCase.verifyNotEqual(f2, f1, 'Changing an active variable did not change the objective.');
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

            %Objective: final altitude after event 3 (responds to event durations).
            massConstraint = GenericMAConstraint('Altitude', evt3, ...
                0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            genObjFcn = GenericObjectiveFcn(evt3, testCase.kerbinFrame, massConstraint, ...
                1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.addObjFunc(genObjFcn);

            %Constraints: bounded altitude after events 2 and 3.
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

        function xs = scaledDuration(~, unscaledDur)
            lb = 10;
            ub = 100000;
            xs = (unscaledDur - (lb + ub)/2) / ((ub - lb)/2);
        end
    end
end

