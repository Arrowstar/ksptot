classdef SweepOptimizeRunTest < KsptotTestCase
    %SweepOptimizeRunTest Optimize-mode case runs (dispersion-of-optimum).
    %
    % Covers the Phase-1/2/5 engine work: the serial-forcing helper and its
    % restore semantics, the per-case harvest (exitflag, final objective,
    % max violation, iterations), the live progress listener, the results
    % columns, and the exit-status tags.
    %
    % Fixture: the default mission on a circular-ish orbit with one 60 s
    % two-body event, one initial-state variable (Rx), no objective
    % functions (f = 0, so fmincon converges in a handful of iterations)
    % and no constraints (violation must come back 0).  Everything runs
    % serially with no pool: getGradientUseParallelFlag degrades, and the
    % single task is driven with runTask directly rather than runAllTasks
    % (which rightly requires a pool in Optimize mode).

    properties(Access=private)
        ProgressCalls cell = {};
    end

    methods(Test)
        function forceSerialRestoresTheUsersSetting(testCase)
            lvdData = testCase.optimizeFixture();

            optimizer = lvdData.optimizer.getSelectedOptimizer();
            opts = optimizer.getOptions();
            prop = testCase.parallelPropName(opts);
            members = enumeration(opts.(prop));
            parallelMember = members(find([members.optionVal], 1, 'first'));
            testCase.assertNotEmpty(parallelMember, 'Fixture broken: no parallel enum member to start from');

            opts.(prop) = parallelMember;

            restoreFcn = LvdCaseMatrixTask.forceSerialOptimizerForCase(lvdData);

            serialMember = opts.(prop);
            testCase.verifyFalse(serialMember.optionVal, ...
                'Forcing must select the serial member');
            testCase.verifyTrue(logical(lvdData.optimizer.usesParallel()) == false, ...
                'usesParallel() must read serial after forcing');

            restoreFcn();
            testCase.verifyTrue(opts.(prop).optionVal, ...
                'Restoring must put the parallel member back');
        end

        function singleOptimizeCaseHarvestsTheFullSummary(testCase)
            [cm, ~, ctx] = testCase.optimizeSweep();

            optimizer = ctx.lvdData.optimizer.getSelectedOptimizer();
            opts = optimizer.getOptions();
            prop = testCase.parallelPropName(opts);
            members = enumeration(opts.(prop));
            opts.(prop) = members(find([members.optionVal], 1, 'first'));

            task = cm.tasks(1);
            testCase.ProgressCalls = {};
            [runStatus, message, task] = task.runTask('', @(iter,fval,maxViol,optim) testCase.recordProgressCall(iter,fval,maxViol,optim));

            testCase.verifyEqual(runStatus, LvdCaseMatrixTaskRunStatusEnum.RunSuceeded, ...
                sprintf('The case did not succeed: %s', message));
            testCase.verifyGreaterThan(task.optExitflag, 0, ...
                'A completed case must carry a positive exit flag');
            testCase.verifyTrue(isfinite(task.optFval), ...
                'The final objective value must be harvested');
            testCase.verifyEqual(task.optMaxViol, 0, ...
                'With no constraints the violation must be exactly 0');
            testCase.verifyTrue(isfinite(task.optIters) && task.optIters >= 0, ...
                'Iterations must be recorded live during the run');

            testCase.verifyGreaterThan(numel(testCase.ProgressCalls), 0, ...
                'The progress listener must have fired at least once');
            iters = cellfun(@(c) c.iter, testCase.ProgressCalls);
            testCase.verifyTrue(all(isfinite(iters)), ...
                'Reported iterations must be finite');
            testCase.verifyTrue(all(diff(iters) >= 0), ...
                'Reported iterations must not go backwards');

            %The template keeps its setting (forcing ran on the clone)...
            testCase.verifyTrue(opts.(prop).optionVal, ...
                'The template mission must keep its parallel setting');
            %...and so does the persisted case file (restored before save).
            s = load(task.lvdFilePath, 'lvdData');
            fileOpts = s.lvdData.optimizer.getSelectedOptimizer().getOptions();
            testCase.verifyTrue(fileOpts.(prop).optionVal, ...
                'The saved case file must carry the restored setting, not the forced-serial one');

            %Results columns flow through collectResults.
            results = cm.collectResults();
            testCase.verifyEqual(numel(results.objectiveValues), 2);
            testCase.verifyEqual(numel(results.exitflags), 2);
            testCase.verifyTrue(isfinite(results.objectiveValues(1)), ...
                'The ran case must contribute a finite objective value');
            testCase.verifyTrue(isnan(results.objectiveValues(2)), ...
                'The unrun case must stay NaN');
            testCase.verifyGreaterThan(results.exitflags(1), 0);
            testCase.verifyTrue(isnan(results.exitflags(2)));

            T = results.toTable();
            testCase.verifyTrue(any(strcmp(T.Properties.VariableDescriptions, 'Objective (final)')), ...
                'The data table must carry the final objective column');
            testCase.verifyTrue(any(strcmp(T.Properties.VariableDescriptions, 'Exit Status')), ...
                'The data table must carry the exit status column');
        end

        function exitStatusTagMapsEveryFlagFamily(testCase)
            [tags, colors] = arrayfun(@(e) LvdSweepResults.exitStatusTag(e), ...
                [NaN, -Inf, 1, 0, -2], 'UniformOutput', false);

            testCase.verifyEqual(tags, {'', 'Error', 'Converged', 'Limit', 'Failed'});
            testCase.verifyTrue(all(cellfun(@(c) isequal(size(c), [1 3]), colors)), ...
                'Every tag carries an RGB triple for the table highlights');
        end

        function setupSeedFlagSurvivesSaveLoad(testCase)
            setup = LvdSweepSetup();
            setup.randomizeSeedEachRun = true;
            setup.seed = 12345;

            f = [tempname(), '.mat'];
            testCase.addTeardown(@() SweepOptimizeRunTest.deleteIfPresent(f));
            save(f, 'setup');

            s = load(f, 'setup');

            testCase.verifyTrue(s.setup.randomizeSeedEachRun, ...
                'The per-run seed flag must survive a save/load round trip');
            testCase.verifyEqual(s.setup.seed, 12345);
        end

        function propagateResultsOmitTheOptimizeColumns(testCase)
            results = LvdSweepResults();
            results.inputs = [1; 2];
            results.outputs = [10; 20];
            results.paramLabels = {'P'};
            results.responseLabels = {'R'};

            T = results.toTable();
            testCase.verifyFalse(any(strcmp(T.Properties.VariableDescriptions, 'Objective (final)')), ...
                'Propagate-only tables must look exactly as before');
            testCase.verifyFalse(any(strcmp(T.Properties.VariableDescriptions, 'Exit Status')), ...
                'Propagate-only tables must look exactly as before');
        end

        function statusHeaderMatchesDataWidth(testCase)
            [cm, ~, ~] = testCase.optimizeSweep();

            data = cm.tasks.getArrayOfParamValues(); %#ok<NASGU>
            header = cm.getStatusTableColumns();
            tableData = cm.getUITableData();

            testCase.verifyEqual(numel(header), size(tableData, 2), ...
                'Headers must match the widened data columns');
            testCase.verifyEqual(header(1:2), {'Case', 'Initial State Rx'});
            testCase.verifyEqual(header(end-6:end), ...
                {'Iter', 'Objective', 'Max Viol', 'Optimality', 'Exit', 'Status', 'Message'});
        end
    end

    methods(Access=private)
        function recordProgressCall(testCase, iter, fval, maxViol, optim)
            testCase.ProgressCalls{end+1} = struct( ...
                'iter', iter, 'fval', fval, 'maxViol', maxViol, 'optim', optim);
        end

        function prop = parallelPropName(~, opts)
            if(isprop(opts, 'useParallel'))
                prop = 'useParallel';
            else
                prop = 'parallel';
            end
        end

        function [lvdData, ctx] = optimizeFixture(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = ...
                CartesianElementSet(0, [testCase.kerbin.radius + 300; 0; 0], [0; 2.2; 0], testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(60);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            %Two active elements (epoch and Rx); the sweep pins the swept
            %Rx element off during each case, leaving the epoch to
            %optimize.  Without a surviving variable the optimizer would
            %have nothing to do and bail before iterating.
            initStateVar = InitialStateVariable(lvdData.initStateModel);
            initStateVar.setUseTfForVariable([true true false false false false false]);
            lvdData.optimizer.vars.addVariable(initStateVar);

            ctx = struct('initStateVar', initStateVar);
        end

        function [cm, setup, ctx] = optimizeSweep(testCase)
            [lvdData, fx] = testCase.optimizeFixture();

            initStateVar = fx.initStateVar;

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            param = LvdSweepOptimVarParameter(initStateVar, 2, 'Initial State Rx', 'none');

            setup = LvdSweepSetup();
            setup.addParameter(param, LvdSweepGridVariation(900, 950, 50));
            setup.samplingMode = LvdSweepSamplingEnum.FullFactorial;
            setup.runMode = LvdCaseMatrixRunModeEnum.Optimize;
            setup.persistCaseFiles = true;
            setup.writeGaTimeSeries = false;
            setup.writeXlsx = false;
            setup.writeMat = false;
            setup.writeCsv = false;
            setup.outputLocation = outDir;

            setup.addResponse(LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), ...
                                               LvdSweepResponseNodeEnum.InitialState, 0));

            [tf, msg] = setup.validate(lvdData);
            testCase.assertTrue(tf, sprintf('Fixture broken: the setup does not validate (%s)', msg));

            cm = LvdCaseMatrix(lvdData, outDir);
            cm.runName = 'OptimizeTest';
            cm.createTasksFromSetup(setup);

            testCase.assertEqual(numel(cm.tasks), 2, 'Fixture broken: expected a two case grid');

            ctx = struct('outDir', outDir, 'lvdData', lvdData);
        end
    end

    methods(Static, Access=private)
        function deleteIfPresent(paths)
            if(ischar(paths))
                paths = {paths};
            end
            for(i = 1:numel(paths))
                if(isfile(paths{i}))
                    delete(paths{i});
                end
            end
        end
    end
end
