classdef OptimizationEvalCacheAndJacobianTest < KsptotTestCase
    %OptimizationEvalCacheAndJacobianTest Same-x propagation cache, single-pass
    %constraint Jacobian with user FD settings, structural Jacobian sparsity,
    %per-constraint optimization history, and the sensitivity tornado chart.
    %
    % SUBJECTS UNDER TEST
    %   LvdOptimization.propagateForX            (same-x cache, E1)
    %   ConstraintSet.evalConstraintsWithGradients (one FD pass, user h/type, E1)
    %   ConstraintSet.getConstraintJacobianSparsity (E2)
    %   computeGradAtPoint matrix sparsity          (E2)
    %   IpOptOptimizer.getJacobianSparsity          (E2)
    %   ma_OptimRecorder constraint history + lvd_recordConstraintHistory (E7)
    %   lvd_plotConstraintHistoryTile, lvd_showSensitivityTornado          (E7)
    %
    % FIXTURE
    %   Three two-body coast events about Kerbin with duration variables on
    %   events 2 and 3, bounded-altitude constraints on events 2 and 3 (two
    %   inequality rows each), and a final-altitude objective.  Under two-body
    %   motion the altitude after event 2 is exactly independent of event 3's
    %   duration, so the structural sparsity pattern has a known analytic
    %   answer and the "masked" Jacobian entries are genuinely zero.
    %
    % NOTE
    %   The optimizer output functions (FminconOptimizer.getOutputFunction and
    %   friends) are private static methods that also need the observe-window
    %   uicontrols, so the recording path is exercised through the helper they
    %   call, lvd_recordConstraintHistory, rather than by invoking them.

    properties(Constant, Access=private)
        Smi = 7000;            %orbit radius, km
        EvtDur = 600;          %nominal event duration, s
        VarLb = 10;
        VarUb = 100000;
    end

    methods(Test)

        %% ------------------------------------------------------------------
        %  E1: same-x propagation cache
        %  ------------------------------------------------------------------

        function sameXCacheServesConstraintsAfterObjective(testCase)
            fx = testCase.makeFixture();
            fx.lvdData.settings.enableIncrementalRepropagation = false;
            lvdOpt = fx.lvdData.optimizer;
            script = fx.lvdData.script;

            f = lvdOpt.objFcn.evalObjFcn(fx.x0, fx.evt1);
            testCase.assertFalse(isnan(f), 'Fixture broken: objective is NaN.');
            counterAfterObj = script.propagationCounter;
            testCase.assertGreaterThan(counterAfterObj, 0, 'executeScript must bump propagationCounter.');

            [c, ceq] = lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);

            testCase.verifyEqual(script.propagationCounter, counterAfterObj, ...
                'Constraint evaluation at the same x must be served from the cache, not re-propagated.');
            testCase.verifyEqual(script.lastNumEvtsIntegrated, 0, ...
                'A served cache hit must report zero integrated events.');
            testCase.verifyEqual(numel(c), 4, 'Fixture broken: expected 4 inequality rows.');
            testCase.verifyEmpty(ceq);

            [hits, misses] = lvdOpt.getPropagationCacheStats();
            testCase.verifyEqual(hits, 1);
            testCase.verifyEqual(misses, 1);
        end

        function cacheMissesWhenAnyKeyElementChanges(testCase)
            fx = testCase.makeFixture();
            fx.lvdData.settings.enableIncrementalRepropagation = false;
            lvdOpt = fx.lvdData.optimizer;
            script = fx.lvdData.script;

            lvdOpt.propagateForX(fx.x0, false, fx.evt1, false);
            c0 = script.propagationCounter;

            %same everything -> hit
            lvdOpt.propagateForX(fx.x0, false, fx.evt1, false);
            testCase.verifyEqual(script.propagationCounter, c0, 'Identical request must hit.');

            %different x -> miss
            x1 = fx.x0;
            x1(1) = x1(1) + 1E-3;
            lvdOpt.propagateForX(x1, false, fx.evt1, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 1, 'Changed x must miss.');

            %same x, different sparse flag -> miss
            lvdOpt.propagateForX(x1, true, fx.evt1, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 2, 'Changed sparse flag must miss.');

            %same x and flag, different start event -> miss
            lvdOpt.propagateForX(x1, true, fx.evt2, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 3, 'Changed start event must miss.');

            %external propagation in between -> miss even though the key matches
            script.executeScript(false, fx.evt1, false, false, false, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 4);
            lvdOpt.propagateForX(x1, true, fx.evt2, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 5, ...
                'An executeScript call made by anyone else must invalidate the cache.');

            %column vs row form of the same x -> hit
            lvdOpt.propagateForX(x1(:), true, fx.evt2, false);
            testCase.verifyEqual(script.propagationCounter, c0 + 5, 'Row/column shape of x must not affect the key.');
        end

        function cacheCanBeDisabledFromSettings(testCase)
            fx = testCase.makeFixture();
            fx.lvdData.settings.enableIncrementalRepropagation = false;
            fx.lvdData.settings.enableSameXPropagationCache = false;
            lvdOpt = fx.lvdData.optimizer;
            script = fx.lvdData.script;

            lvdOpt.objFcn.evalObjFcn(fx.x0, fx.evt1);
            c0 = script.propagationCounter;
            lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);

            testCase.verifyEqual(script.propagationCounter, c0 + 1, ...
                'With the cache disabled the constraints must propagate again.');
        end

        function cachedLogIsBitIdenticalToForcedPropagation(testCase)
            fx = testCase.makeFixture();
            fx.lvdData.settings.enableIncrementalRepropagation = false;
            lvdOpt = fx.lvdData.optimizer;

            lvdOpt.propagateForX(fx.x0, false, fx.evt1, false);
            servedLog = lvdOpt.propagateForX(fx.x0, false, fx.evt1, false);
            fpServed = stateLogToFingerprint(servedLog);

            lvdOpt.clearPropagationCache();
            forcedLog = lvdOpt.propagateForX(fx.x0, false, fx.evt1, false);
            fpForced = stateLogToFingerprint(forcedLog);

            testCase.verifyTrue(isequaln(fpServed.matrix, fpForced.matrix), ...
                'The cache must never change the propagated state log.');
        end

        function incrementalRepropagationStillWorksThroughTheCache(testCase)
            %With incremental re-propagation on, the objective/constraint pair
            %must still evaluate to finite values and the repeated-x path must
            %integrate nothing (matches OptimizationEntryPointTest semantics).
            fx = testCase.makeFixture();
            fx.lvdData.settings.enableIncrementalRepropagation = true;
            lvdOpt = fx.lvdData.optimizer;

            f1 = lvdOpt.objFcn.evalObjFcn(fx.x0, fx.evt2);
            [c1, ~] = lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt2, false, []);
            f2 = lvdOpt.objFcn.evalObjFcn(fx.x0, fx.evt2);

            testCase.verifyEqual(fx.lvdData.script.lastNumEvtsIntegrated, 0);
            testCase.verifyEqual(f2, f1);
            testCase.verifyTrue(all(isfinite(c1)));
        end

        %% ------------------------------------------------------------------
        %  E1: single-pass Jacobian honouring the user's FD settings
        %  ------------------------------------------------------------------

        function singlePassJacobianMatchesPerBlockReference(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;
            fd = lvdOpt.customFiniteDiffsCalcMethod;

            [cAtX0, cEqAtX0, DC, DCeq] = lvdOpt.constraints.evalConstraintsWithGradients(fx.x0, true, fx.evt1, false, []);

            testCase.verifyEqual(size(DC), [numel(fx.x0), numel(cAtX0)], 'DC must be [numX x numC] for fmincon.');
            testCase.verifyEqual(size(DCeq), [numel(fx.x0), numel(cEqAtX0)], 'DCeq must be [numX x numCeq] for fmincon.');

            %Reference: the pre-change two-pass computation, but with the
            %user's settings rather than the old literals.
            fC = @(x) fx.cOnly(x);
            refDC = computeGradAtPoint(fC, fx.x0, cAtX0(:)', fd.h, fd.diffType, double(fd.numPts), [], false);

            testCase.verifyEqual(DC, refDC, 'AbsTol', 1E-9 * max(1, max(abs(refDC(:)))), ...
                'Single-pass DC must equal the per-block reference.');
        end

        function jacobianHonoursConfiguredStepAndDifferenceType(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;
            fd = lvdOpt.customFiniteDiffsCalcMethod;

            [~, ~, DCDefault] = lvdOpt.constraints.evalConstraintsWithGradients(fx.x0, true, fx.evt1, false, []);

            fd.h = 1E-3;
            fd.diffType = FiniteDiffTypeEnum.Central;
            fd.numPts = 2;

            [cAtX0, ~, DCCentral] = lvdOpt.constraints.evalConstraintsWithGradients(fx.x0, true, fx.evt1, false, []);
            refCentral = computeGradAtPoint(@(x) fx.cOnly(x), fx.x0, cAtX0(:)', 1E-3, FiniteDiffTypeEnum.Central, 2, [], false);

            testCase.verifyEqual(DCCentral, refCentral, 'AbsTol', 1E-9 * max(1, max(abs(refCentral(:)))), ...
                'Jacobian must use the configured h and difference type.');
            testCase.verifyNotEqual(DCCentral, DCDefault, ...
                'Changing the FD settings must change the computed Jacobian (it was previously hard-coded).');
        end

        %% ------------------------------------------------------------------
        %  E2: structural sparsity
        %  ------------------------------------------------------------------

        function sparsityPatternFollowsEventOrdering(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;

            xEvtNums = lvdOpt.vars.getXElementEvtNums();
            testCase.assertEqual(xEvtNums, [2 3], 'Fixture broken: expected one variable on event 2 and one on event 3.');

            lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);
            sp = lvdOpt.constraints.getConstraintJacobianSparsity();

            testCase.verifyClass(sp, 'logical');
            testCase.verifyEqual(size(sp), [4, 2]);

            lrv = lvdOpt.constraints.lastRunValues;
            rowEvts = lrv.cEventInds;
            expected = true(4, 2);
            expected(rowEvts == 2, 2) = false; %event 3's duration cannot move event 2's altitude
            testCase.verifyEqual(sp, expected);

            %And the masked entries really are zero derivatives.
            [~, ~, DC] = lvdOpt.constraints.evalConstraintsWithGradients(fx.x0, true, fx.evt1, false, []);
            testCase.verifyEqual(DC(2, rowEvts == 2), zeros(1, nnz(rowEvts == 2)));
            testCase.verifyTrue(any(DC(2, rowEvts == 3) ~= 0), 'Event 3 duration must influence event 3 altitude.');
            testCase.verifyTrue(all(DC(1, :) ~= 0), 'Event 2 duration influences both events.');
        end

        function sparsityIsDenseWhenEventOrderIsDynamic(testCase)
            %SetNextEventAction hidden inside a ConditionalAction branch
            fx = testCase.makeFixture();
            cond = ConditionalAction();
            cond.addIfAction(SetNextEventAction(fx.evt2));
            fx.evt1.addAction(cond);
            fx.lvdData.optimizer.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);
            sp = fx.lvdData.optimizer.constraints.getConstraintJacobianSparsity();
            testCase.verifyTrue(all(sp(:)), 'A SetNextEventAction inside a conditional must force a dense pattern.');

            %Non-sequential event
            fx = testCase.makeFixture();
            innerEvt = LaunchVehicleEvent(fx.lvdData.script);
            innerEvt.termCond = EventDurationTermCondition(1E9);
            fx.lvdData.script.nonSeqEvts.addEvent(LaunchVehicleNonSeqEvent(innerEvt));
            fx.lvdData.optimizer.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);
            sp = fx.lvdData.optimizer.constraints.getConstraintJacobianSparsity();
            testCase.verifyTrue(all(sp(:)), 'A non-sequential event must force a dense pattern.');

            %Plugin
            fx = testCase.makeFixture();
            fx.lvdData.plugins.addPlugin(LvdPlugin());
            fx.lvdData.optimizer.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);
            sp = fx.lvdData.optimizer.constraints.getConstraintJacobianSparsity();
            testCase.verifyTrue(all(sp(:)), 'A plugin must force a dense pattern.');
        end

        function computeGradAtPointMatrixSparsitySkipsColumnsAndMasks(testCase)
            evalCount = 0;
            function y = fun(x)
                evalCount = evalCount + 1;
                y = [x(1)^2; x(1)*x(2); x(3)];
            end

            x0 = [1.5; -2; 0.25];
            f0 = fun(x0);
            evalCount = 0;

            gDense = computeGradAtPoint(@fun, x0, f0, 1E-6, FiniteDiffTypeEnum.Forward, 2, [], false);
            denseEvals = evalCount;
            testCase.verifyEqual(denseEvals, 3, 'Forward 2-point dense: one evaluation per variable.');

            %[numX x numOut] pattern with x2's row all-zero -> column skipped;
            %(1,3) structurally zero although dense gives exactly 0 anyway;
            %(2,2) is a TRUE nonzero (d(x1 x2)/dx2 = x1) that the mask forces to 0.
            pattern = logical([1 1 0; 0 0 0; 0 0 1]);
            evalCount = 0;
            gSparse = computeGradAtPoint(@fun, x0, f0, 1E-6, FiniteDiffTypeEnum.Forward, 2, pattern, false);

            testCase.verifyEqual(evalCount, 2, 'The all-zero x2 column must not be evaluated.');
            testCase.verifyEqual(gSparse(2, :), [0 0 0]);
            testCase.verifyEqual(gSparse(1, 1:2), gDense(1, 1:2));
            testCase.verifyEqual(gSparse(3, 3), gDense(3, 3));
            testCase.verifyEqual(gSparse(pattern), gDense(pattern), 'Structurally nonzero entries must match the dense result.');
            testCase.verifyTrue(all(gSparse(~pattern) == 0), 'Structurally zero entries must be exactly 0.');

            %Vector sparsity behaviour is unchanged.
            evalCount = 0;
            gVec = computeGradAtPoint(@fun, x0, f0, 1E-6, FiniteDiffTypeEnum.Forward, 2, [1; 0; 1], false);
            testCase.verifyEqual(evalCount, 2);
            testCase.verifyEqual(gVec([1 3], :), gDense([1 3], :));
            testCase.verifyEqual(gVec(2, :), [0 0 0]);

            %Wrong-shaped matrix is rejected.
            testCase.verifyError(@() computeGradAtPoint(@fun, x0, f0, 1E-6, FiniteDiffTypeEnum.Forward, 2, true(3, 2), false), ...
                'computeGradAtPoint:badSparsity');
        end

        function ipoptStructureIsConstraintsByVariables(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;
            lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);

            spConstr = lvdOpt.constraints.getConstraintJacobianSparsity(); %[rows x numX]
            spIpopt = IpOptOptimizer.getJacobianSparsity(lvdOpt, 4, 2);

            testCase.verifyEqual(size(spIpopt), [4, 2], 'IPOPT wants [numConstrs x numVars].');
            testCase.verifyEqual(spIpopt, spConstr);

            %Mismatched sizes fall back to dense rather than erroring.
            spFallback = IpOptOptimizer.getJacobianSparsity(lvdOpt, 3, 5);
            testCase.verifyEqual(spFallback, true(3, 5));
            testCase.verifyEqual(IpOptOptimizer.getJacobianSparsity([], 2, 2), true(2, 2));
        end

        %% ------------------------------------------------------------------
        %  E7: constraint history and plots
        %  ------------------------------------------------------------------

        function recorderStoresPerIterationConstraintVectors(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;

            recorder = ma_OptimRecorder();
            testCase.verifyFalse(recorder.hasConstraintHistory());

            %Mimic the output-function order: max violation, then history.
            recorder.iterNums(end+1) = 0;
            recorder.xVals(end+1) = {fx.x0};
            recorder.fVals(end+1) = 1;
            recorder.maxCVal(end+1) = 0;
            lvd_recordConstraintHistory(recorder, lvdOpt, fx.x0, fx.evt1);

            x1 = fx.x0;
            x1(2) = x1(2) + 1E-3;
            recorder.iterNums(end+1) = 1;
            recorder.xVals(end+1) = {x1};
            recorder.fVals(end+1) = 0.5;
            recorder.maxCVal(end+1) = 0;
            lvd_recordConstraintHistory(recorder, lvdOpt, x1, fx.evt1);

            testCase.verifyTrue(recorder.hasConstraintHistory());
            testCase.verifyEqual(numel(recorder.cVals), 2);
            testCase.verifyEqual(numel(recorder.cVals{1}), 4);
            testCase.verifyEqual(numel(recorder.cNames), 4);
            testCase.verifyEqual(recorder.ceqMask, false(1, 4));
            testCase.verifyTrue(all(contains(recorder.cNames, 'Altitude')), 'Names must come from the constraints.');
            testCase.verifyTrue(any(contains(recorder.cNames, 'Lwr Bnd')) && any(contains(recorder.cNames, 'Upr Bnd')));

            [c1, ~] = lvdOpt.constraints.evalConstraints(fx.x0, true, fx.evt1, false, []);
            testCase.verifyEqual(recorder.cVals{1}, c1(:)', 'Stored row must be the constraint vector at that x.');

            [viol, names, iters] = recorder.getConstraintViolationHistory();
            testCase.verifyEqual(size(viol), [2, 4]);
            testCase.verifyEqual(names, recorder.cNames);
            testCase.verifyEqual(iters, [0 1]);
            testCase.verifyTrue(all(viol(:) >= 0), 'Violations are max(0,c) for inequalities.');

            %Mission Architect's use of the recorder is unaffected.
            [iterNum, xBest, fBest, cBest] = recorder.getIterWithLowestFVal();
            testCase.verifyEqual(iterNum, 1);
            testCase.verifyEqual(xBest, x1);
            testCase.verifyEqual(fBest, 0.5);
            testCase.verifyEqual(cBest, 0);
        end

        function constraintHistoryTileDrawsOnlyWhenDataAndRoomExist(testCase)
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(hFig));

            %The observe window is laid out up front from the recorder flag.
            recorder = ma_OptimRecorder();
            testCase.verifyEqual(lvd_numObserveTiles(recorder), 3);
            recorder.expectConstraintHistory = true;
            testCase.verifyEqual(lvd_numObserveTiles(recorder), 4);

            tl = tiledlayout(hFig, lvd_numObserveTiles(recorder), 1);
            nexttile(tl, 1); nexttile(tl, 2); nexttile(tl, 3);

            hAx = lvd_plotConstraintHistoryTile(tl, recorder, 4);
            testCase.verifyEmpty(hAx, 'No history yet: no tile drawn.');
            testCase.verifyEqual(tl.GridSize, [4 1], 'Layout untouched.');

            recorder.iterNums = [0 1 2];
            recorder.recordConstraintValues([-1 0.5], 2, {'A (Lwr Bnd)', 'A (Upr Bnd)', 'B (Eq)'});
            recorder.recordConstraintValues([-1 0.1], 1, {});
            recorder.recordConstraintValues([-1 0.0], 0, {});

            hAx = lvd_plotConstraintHistoryTile(tl, recorder, 4);
            testCase.verifyClass(hAx, 'matlab.graphics.axis.Axes');
            hLines = findobj(hAx, 'Type', 'Line');
            testCase.verifyNumElements(hLines, 3, 'One line per constraint row.');

            %A three-tile layout (legacy / no constraints) is left alone even
            %when history exists: TiledChartLayout cannot grow once populated.
            hFig3 = figure('Visible', 'off');
            cleanup3 = onCleanup(@() close(hFig3));
            tl3 = tiledlayout(hFig3, 3, 1);
            nexttile(tl3, 1); nexttile(tl3, 2); nexttile(tl3, 3);
            hAx3 = lvd_plotConstraintHistoryTile(tl3, recorder, 4);
            testCase.verifyEmpty(hAx3);
            testCase.verifyEqual(tl3.GridSize, [3 1]);

            [viol, ~, ~] = recorder.getConstraintViolationHistory();
            testCase.verifyEqual(viol, [0 0.5 2; 0 0.1 1; 0 0 0]);
        end

        function tornadoChartRunsHeadlessAndRestoresMission(testCase)
            fx = testCase.makeFixture();
            lvdOpt = fx.lvdData.optimizer;
            xBefore = lvdOpt.vars.getTotalScaledXVector();

            [hFig, sens] = lvd_showSensitivityTornado(fx.lvdData, [], 'Visible', 'off');
            cleanup = onCleanup(@() close(hFig));

            testCase.verifyClass(hFig, 'matlab.ui.Figure');

            hObjBars = findobj(hFig, 'Tag', 'objectiveSensitivityBars');
            hConstrBars = findobj(hFig, 'Tag', 'constraintSensitivityBars');
            testCase.verifyNumElements(hObjBars, 1);
            testCase.verifyNumElements(hConstrBars, 1);
            testCase.verifyEqual(numel(hObjBars.YData), 2, 'One objective bar per variable.');
            testCase.verifyEqual(numel(hConstrBars.YData), 2, 'One constraint bar per variable.');

            testCase.verifyEqual(size(sens.constrJac), [4, 2]);
            testCase.verifyEqual(numel(sens.objGrad), 2);
            testCase.verifyEqual(numel(sens.constrNames), 4);
            testCase.verifyTrue(all(isfinite(sens.objGrad)));
            testCase.verifyTrue(all(isfinite(sens.constrJac(:))));
            testCase.verifyTrue(all(sens.objMag > 0), 'Both durations move the final altitude.');
            rowEvts = lvdOpt.constraints.lastRunValues.cEventInds(:)';
            testCase.verifyEqual(sens.constrJac(rowEvts == 2, 2), zeros(nnz(rowEvts == 2), 1), ...
                'Event 3 duration must have exactly zero sensitivity on event 2 constraints.');

            xAfter = lvdOpt.vars.getTotalScaledXVector();
            testCase.verifyEqual(xAfter, xBefore, 'Sensitivity computation must leave the mission at the original x.');

            %Drawing into an existing figure reuses it.
            hFig2 = figure('Visible', 'off');
            cleanup2 = onCleanup(@() close(hFig2));
            hOut = lvd_showSensitivityTornado(fx.lvdData, hFig2);
            testCase.verifyTrue(hOut == hFig2);

            %No variables -> a clear error, not a blank chart.
            lvdData2 = LvdData.getDefaultLvdData(testCase.celBodyData);
            testCase.verifyError(@() lvd_showSensitivityTornado(lvdData2, [], 'Visible', 'off'), ...
                'lvd_showSensitivityTornado:noVariables');
        end
    end

    methods(Access=private)

        function fx = makeFixture(testCase)
            ksptotAddProjectPaths();

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.settings.enableIncrementalRepropagation = false;

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
            var2.lb = testCase.VarLb;
            var2.ub = testCase.VarUb;
            lvdData.optimizer.vars.addVariable(var2);

            var3 = EventDurationOptimizationVariable(evt3.termCond);
            var3.useTf = true;
            var3.lb = testCase.VarLb;
            var3.ub = testCase.VarUb;
            lvdData.optimizer.vars.addVariable(var3);

            objConst = GenericMAConstraint('Altitude', evt3, 0, 0, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            genObjFcn = GenericObjectiveFcn(evt3, testCase.kerbinFrame, objConst, 1, lvdData.optimizer, lvdData);
            lvdData.optimizer.objFcn.addObjFunc(genObjFcn);

            const2 = GenericMAConstraint('Altitude', evt2, 0, 1E9, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            lvdData.optimizer.constraints.addConstraint(const2);

            const3 = GenericMAConstraint('Altitude', evt3, 0, 1E9, struct([]), struct([]), KSPTOT_BodyInfo.empty(1,0));
            lvdData.optimizer.constraints.addConstraint(const3);

            fx = struct();
            fx.lvdData = lvdData;
            fx.evt1 = evt1;
            fx.evt2 = evt2;
            fx.evt3 = evt3;
            fx.x0 = lvdData.optimizer.vars.getTotalScaledXVector();

            fx.cOnly = @(x) testCase.cOnlyRow(lvdData, x, evt1);
        end

        function c = cOnlyRow(~, lvdData, x, startEvt)
            [c, ~] = lvdData.optimizer.constraints.evalConstraints(x, true, startEvt, false, []);
            c = c(:)';
        end

        function configureCoastEvent(~, evt, duration)
            evt.termCond = EventDurationTermCondition(duration);
            evt.propagatorObj = evt.twoBodyPropagator;
        end
    end
end
