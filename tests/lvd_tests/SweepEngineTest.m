classdef SweepEngineTest < KsptotTestCase
    %SweepEngineTest A sweep from a setup to the numbers and files it leaves.
    %
    % The end-to-end tests here run in propagate-only mode with NO parallel
    % pool, which is the mode that did not exist before: LvdCaseMatrix.
    % runAllTasks used to hard-error without a pool, so a two-parameter survey
    % on a laptop was not possible at all. The serial fallback runs the cases in
    % this process, which is also why the diary handling matters -- see
    % aSurveyAskedForNoPerCaseFilesAndLeavesNone.
    %
    % The response oracle is deliberately exact rather than approximate. The
    % swept parameter is the initial state's Rx and the first response is the
    % initial state's altitude, so the harvested number must come back as
    % exactly (swept radius - body radius) for every case. A second response,
    % the mission's maximum altitude, must rise with it; a third, universal time
    % at the final state, must NOT move at all -- a response that tracked the
    % parameter when it should not would mean the sweep was writing somewhere it
    % should not.
    %
    % The statistics half needs no propagation, so those tests build an
    % LvdSweepResults directly and check it against cov/prctile and against the
    % defining equation of a covariance ellipse.

    properties(Constant)
        %The template sits at Rx = 900 (300 km up over a 600 km body), and the
        %grid sweeps it to 1000 in 50 km steps.
        TemplateRx = 900;
        GridLb = 900;
        GridUb = 1000;
        GridStep = 50;

        EvtDuration = 600;

        %Element 1 of an InitialStateVariable is the epoch, so Rx is element 2.
        RxElemInd = 2;
    end

    methods(Test)

        function aPropagateOnlySurveyRunsEveryCaseWithNoParallelPoolAtAll(testCase)
            testCase.assumeNoParallelPool();

            [cm, setup] = testCase.gridSweep();

            cm.runAllTasks();

            results = cm.results;
            testCase.assertNotEmpty(results, 'The run produced no results object');

            testCase.verifyEqual([cm.tasks.status], ...
                repmat(LvdCaseMatrixTaskStatusEnum.Completed, 1, numel(cm.tasks)), ...
                sprintf('Not every case completed: %s', strjoin({cm.tasks.taskOutputMessage}, ' | ')));

            %Propagate-only cases are independent, so they keep the sampler's
            %order: case N must be the same case on every rerun.
            testCase.verifyEqual(results.inputs, setup.generateInputMatrix(), ...
                'A survey must run the cases in the order the sampler produced them');

            %Exact oracle: initial altitude is the swept radius less the body's.
            expectedAlt = results.inputs(:,1) - testCase.kerbin.radius;
            testCase.verifyEqual(results.outputs(:,1), expectedAlt, 'AbsTol', 1e-9, ...
                'The harvested initial altitude is not the radius this case applied');

            %A propagated quantity must move with the parameter...
            maxAlt = results.outputs(:,2);
            testCase.verifyTrue(all(diff(maxAlt) > 0), ...
                'The mission maximum altitude did not rise with the initial radius');
            testCase.verifyTrue(all(maxAlt > expectedAlt), ...
                'The maximum altitude over the arc must exceed the altitude it started at');

            %...and a quantity that has nothing to do with it must not.
            testCase.verifyEqual(results.outputs(:,3), ...
                repmat(testCase.EvtDuration, height(results.inputs), 1), 'AbsTol', 1e-6, ...
                'The final epoch moved: the sweep is writing something it should not be');

            testCase.verifyEqual(results.responseUnits, {'km', 'km', 'sec'});
            testCase.verifyEqual(results.paramLabels, {'Initial State Rx'});
            testCase.verifyEqual(results.runMode, LvdCaseMatrixRunModeEnum.PropagateOnly);
            testCase.verifyEqual(results.samplingMode, LvdSweepSamplingEnum.FullFactorial);
            testCase.verifyGreaterThan(results.timestamp, 0, 'A finished run must be stamped');

            %Every case ran exactly once: there is no retry budget to spend
            %when nothing failed.
            testCase.verifyEqual([cm.tasks.numAttempts], ones(1, numel(cm.tasks)));
        end

        function aSurveyAskedForNoPerCaseFilesAndLeavesNone(testCase)
            testCase.assumeNoParallelPool();

            %At dispersion sample counts the per-case .mat and the per-case
            %diary log dominate the run, so propagate-only mode can switch both
            %off -- and then must really not write them.
            [cm, ~, ctx] = testCase.gridSweep();

            %The serial fallback runs the cases in THIS process, so a case that
            %redirects the diary and does not put it back would leave the user's
            %own session logging into a temporary file.
            clientLog = [tempname(), '.log'];
            testCase.addTeardown(@() SweepEngineTest.restoreDiary(clientLog));
            diary('off');
            set(0, 'DiaryFile', clientLog);
            diary('on');

            cm.runAllTasks();

            written = testCase.filesIn(ctx.outDir);

            testCase.verifyTrue(any(endsWith(written, '_results.mat')), 'The results .mat was not written');
            testCase.verifyTrue(any(endsWith(written, '_results.xlsx')), 'The results .xlsx was not written');
            testCase.verifyFalse(any(startsWith(written, 'Case_') & endsWith(written, '.mat')), ...
                'A survey that asked for no case files wrote one anyway');
            testCase.verifyFalse(any(endsWith(written, '_running.log')), ...
                'A survey that asked for no case files still wrote a per-case diary log');

            testCase.verifyEqual(get(0,'Diary'), 'on', ...
                'A case run turned the client''s diary off and left it off');
            testCase.verifyEqual(get(0,'DiaryFile'), clientLog, ...
                'A case run redirected the client''s diary and did not put it back');

            %The same run with the case files asked for does write them, so the
            %test above is not passing because nothing is written at all.
            [cm2, ~, ctx2] = testCase.gridSweep('persistCaseFiles', true);

            cm2.runAllTasks();

            written2 = testCase.filesIn(ctx2.outDir);
            testCase.verifyEqual(sum(startsWith(written2, 'Case_') & endsWith(written2, '.mat')), ...
                numel(cm2.tasks), 'One case file per case was expected');
            testCase.verifyTrue(any(endsWith(written2, '_running.log')), ...
                'A run keeping its case files should keep their diary logs too');

            %And this is the run that actually moves the diary, so it is the one
            %that has to put it back.
            testCase.verifyEqual(get(0,'Diary'), 'on', ...
                'A case that redirected the diary left it off afterwards');
            testCase.verifyEqual(get(0,'DiaryFile'), clientLog, ...
                'A case that redirected the diary did not restore the client''s file');
        end

        function aCaseWhoseParameterHasGoneMissingFailsWithAMessageAndTheRunGoesOn(testCase)
            testCase.assumeNoParallelPool();

            %A sweep definition outlives the mission it was written against, so
            %a parameter whose target was deleted is an ordinary run-time
            %situation.  It has to be a failed case with an explanation, not an
            %exception out of the middle of the run.
            [cm, ~, ctx] = testCase.gridSweep('strayParameter', true);

            cm.runAllTasks();

            testCase.verifyEqual([cm.tasks.status], ...
                repmat(LvdCaseMatrixTaskStatusEnum.Failed, 1, numel(cm.tasks)));

            for(i = 1:numel(cm.tasks)) %#ok<*NO4LP>
                testCase.verifyTrue(contains(cm.tasks(i).taskOutputMessage, 'no longer exists'), ...
                    sprintf('Case %u did not say why it failed: "%s"', i, cm.tasks(i).taskOutputMessage));
            end

            results = cm.results;

            testCase.verifyTrue(all(isnan(results.outputs(:))), ...
                'A case that never ran must not report response values');
            testCase.verifyEqual(results.inputs, cm.tasks.getArrayOfParamValues(), ...
                'A failed run still has to report which cases were attempted');
            testCase.verifyFalse(any(results.getValidMask()), 'No case here was valid');

            %And the run still wrote its outputs: hours of propagation must not
            %be thrown away because a case failed.
            testCase.verifyTrue(any(endsWith(testCase.filesIn(ctx.outDir), '_results.mat')), ...
                'A run with failures must still write its results file');

            stats = results.getStatistics(50);
            testCase.verifyEqual([stats.nValid], zeros(1, numel(stats)));
            testCase.verifyTrue(all(isnan([stats.mean])), ...
                'Statistics over nothing must be NaN, not zero');
        end

        function cancelingMidRunLeavesTheRemainingCasesUnrunAndStillReportsResults(testCase)
            testCase.assumeNoParallelPool();

            [cm, ~, ~] = testCase.gridSweep();

            %Cancel from inside the run, the way the window's Cancel button
            %does: the moment case 1 reports back, ask for the rest to stop.
            %runAllTasks clears runCanceled at the top, so setting it beforehand
            %would prove nothing.
            lh = addlistener(cm.tasks(1), 'StatusUpdated', ...
                @(~,evt) SweepEngineTest.cancelOnceCompleted(cm, evt));
            testCase.addTeardown(@() delete(lh));

            cm.runAllTasks();

            testCase.assertTrue(cm.runCanceled, 'Fixture broken: the run was never canceled');
            testCase.verifyEqual(cm.tasks(1).status, LvdCaseMatrixTaskStatusEnum.Completed, ...
                'The case that had already finished must keep its result');
            testCase.verifyEqual([cm.tasks(2:end).status], ...
                repmat(LvdCaseMatrixTaskStatusEnum.NotRun, 1, numel(cm.tasks) - 1), ...
                'A canceled run kept going');
            testCase.verifyEqual([cm.tasks(2:end).numAttempts], zeros(1, numel(cm.tasks) - 1));

            %A partial run still reports what it got, over every case.
            results = cm.results;
            testCase.verifyEqual(height(results.inputs), numel(cm.tasks), ...
                'Every case must still appear as a row, run or not');
            testCase.verifyFalse(any(isnan(results.outputs(1,:))), ...
                'The case that completed must report its responses');
            testCase.verifyTrue(all(isnan(results.outputs(2:end,:)), 'all'), ...
                'A case that never ran must report NaN, not a stale value');

            stats = results.getStatistics(50);
            testCase.verifyEqual([stats.nValid], ones(1, numel(stats)), ...
                'Only the case that ran may count towards the statistics');
        end

        function cancelingMarksOnlyTheCasesThatWereInFlight(testCase)
            [cm, ~, ~] = testCase.gridSweep();

            cm.tasks(1).status = LvdCaseMatrixTaskStatusEnum.Completed;
            cm.tasks(2).status = LvdCaseMatrixTaskStatusEnum.Running;
            %tasks(3) is left NotRun.

            cm.cancelRun();

            testCase.verifyTrue(cm.runCanceled);
            testCase.verifyEqual(cm.tasks(1).status, LvdCaseMatrixTaskStatusEnum.Completed, ...
                'Canceling must not discard a case that had already finished');
            testCase.verifyEqual(cm.tasks(2).status, LvdCaseMatrixTaskStatusEnum.Canceled);
            testCase.verifyEqual(cm.tasks(2).taskOutputMessage, 'Canceled');
            testCase.verifyEqual(cm.tasks(3).status, LvdCaseMatrixTaskStatusEnum.NotRun, ...
                'A case that never started was not canceled, it simply did not run');
        end

        function optimizeModeStillRefusesToRunWithoutAPoolAndSaysWhy(testCase)
            testCase.assumeNoParallelPool();

            %Optimize mode genuinely needs a pool: its cases are not
            %independent, each one warm starting off the nearest converged case.
            %The point of the propagate-only path is that it does not.
            [cm, ~, ~] = testCase.gridSweep('runMode', LvdCaseMatrixRunModeEnum.Optimize);

            testCase.verifyError(@() cm.runAllTasks(), 'LvdCaseMatrix:noParallelPool');
        end

        function optimizeModeOrdersCasesNearestTheTemplateFirstAndASurveyDoesNot(testCase)
            %No run needed: this is about which case is case 1.
            %
            %Optimize mode walks outwards from the template's own design point
            %so every later case inherits a good starting guess.  A survey has
            %no such coupling and must keep the sampler's order, which is what
            %makes a seeded dispersion run reproducible case by case.
            [cmOpt, setupOpt, ctxOpt] = testCase.gridSweep('runMode', LvdCaseMatrixRunModeEnum.Optimize, ...
                                                           'templateRx', testCase.GridUb);

            X = setupOpt.generateInputMatrix();
            expectedOrder = LvdCaseMatrix.orderNearestFirst(X, ctxOpt.templateRx);

            testCase.assertEqual(expectedOrder(:)', [3 2 1], ...
                'Fixture broken: the nearest-first order is the natural order, so this test proves nothing');

            testCase.verifyEqual(cmOpt.tasks.getArrayOfParamValues(), X(expectedOrder, :), ...
                'Optimize mode did not start from the case nearest the template');

            [cmSurvey, setupSurvey, ~] = testCase.gridSweep('templateRx', testCase.GridUb);

            testCase.verifyEqual(cmSurvey.tasks.getArrayOfParamValues(), setupSurvey.generateInputMatrix(), ...
                'A survey must not reorder its cases');

            %Optimize mode always keeps its case files, whatever the setup says,
            %because the warm start and the retry both read them back.
            testCase.verifyTrue(all([cmOpt.tasks.persistCaseFile]), ...
                'An optimized case must persist its file: the next case warm starts off it');
            testCase.verifyFalse(any([cmSurvey.tasks.persistCaseFile]));
        end

        function percentilesMatchTheStatisticsToolboxAndAHandComputedCase(testCase)
            %Sample k of n sits at percentile 100*(k-0.5)/n, extremes clamped.
            %Spelt out on four points: the plotting positions are 12.5, 37.5,
            %62.5 and 87.5 percent.
            x = [4 1 3 2];   %deliberately unsorted

            testCase.verifyEqual(LvdSweepResults.percentile(x, 12.5), 1, 'AbsTol', 1e-12);
            testCase.verifyEqual(LvdSweepResults.percentile(x, 87.5), 4, 'AbsTol', 1e-12);
            testCase.verifyEqual(LvdSweepResults.percentile(x, 50), 2.5, 'AbsTol', 1e-12, ...
                'The median of four points sits halfway between the middle two');
            testCase.verifyEqual(LvdSweepResults.percentile(x, 25), 1.5, 'AbsTol', 1e-12);

            %Outside the plotting positions the extremes clamp rather than
            %extrapolate, which is what stops the 99.87th percentile of 50
            %samples from inventing a value beyond the largest one seen.
            testCase.verifyEqual(LvdSweepResults.percentile(x, [0 1 99 100]), [1 1 4 4], 'AbsTol', 1e-12);

            %An independent oracle: prctile uses exactly this convention.
            s = RandStream('twister', 'Seed', 20260921);
            y = 100 + 15*randn(s, 137, 1);
            levels = [LvdSweepResults.DefaultPercentiles, 1, 33.3, 66.7, 99];

            testCase.verifyEqual(LvdSweepResults.percentile(y, levels), ...
                                 reshape(prctile(y, levels), 1, []), 'RelTol', 1e-10, ...
                'The hand-rolled percentile disagrees with prctile');

            %Orientation must not matter.
            testCase.verifyEqual(LvdSweepResults.percentile(y', levels), ...
                                 LvdSweepResults.percentile(y, levels));
        end

        function percentilesOfDegenerateSampleSetsAreHonest(testCase)
            testCase.verifyTrue(all(isnan(LvdSweepResults.percentile([], [10 50 90]))), ...
                'No samples means no percentiles, not zero');

            %One sample is the answer at every level -- there is nothing to
            %interpolate between.
            testCase.verifyEqual(LvdSweepResults.percentile(7, [0 50 100]), [7 7 7]);

            testCase.verifyEqual(LvdSweepResults.percentile([5 5 5 5], [1 50 99]), [5 5 5]);

            %The returned shape follows the levels, so a caller can label a
            %percentile table row by row.
            testCase.verifySize(LvdSweepResults.percentile(1:10, [10; 50; 90]), [3 1]);
        end

        function statisticsAreTakenOverTheCasesThatWorkedAndSayHowMany(testCase)
            results = testCase.syntheticResults();

            S = results.getStatistics([25 50 75]);

            testCase.assertEqual(numel(S), 2, 'One statistics entry per response');

            %Response A: case 3 failed outright, cases 5 and 6 evaluated to NaN.
            valid = [10; 12; 16];

            testCase.verifyEqual(S(1).n, 6, 'n is every case attempted');
            testCase.verifyEqual(S(1).nValid, 3, 'nValid is the cases that produced a number');
            testCase.verifyEqual(S(1).mean, mean(valid), 'RelTol', 1e-12);
            testCase.verifyEqual(S(1).std, std(valid), 'RelTol', 1e-12);
            testCase.verifyEqual(S(1).min, min(valid));
            testCase.verifyEqual(S(1).max, max(valid));
            testCase.verifyEqual(S(1).pctValues, LvdSweepResults.percentile(valid, [25 50 75]), 'RelTol', 1e-12);
            testCase.verifyEqual(S(1).label, 'Response A');
            testCase.verifyEqual(S(1).unit, 'km');

            %A failed case must not be counted as a zero -- that is the whole
            %reason the mean is taken over a mask instead of over the column.
            testCase.verifyGreaterThan(S(1).min, 0, ...
                'A failed case was folded into the statistics as a value');
            testCase.verifyNotEqual(S(1).mean, mean([10; 12; 0; 16; 0; 0]));

            %Nor may a case the run marked Failed contribute a number just
            %because the number it left behind happens to be finite.
            testCase.verifyLessThan(S(1).max, 99, ...
                'A Failed case contributed its harvested value to the statistics');

            %Response B: an Inf is not a value a dispersion report can quote
            %either, so it is masked out the same way a NaN is.
            valid2 = [100; 110; 130];
            testCase.verifyEqual(S(2).nValid, 3);
            testCase.verifyEqual(S(2).max, max(valid2), ...
                'An infinite response was counted as a value');
            testCase.verifyTrue(isfinite(S(2).mean));
        end

        function theCovarianceAndItsEllipseDescribeTheSameScatter(testCase)
            results = testCase.syntheticResults();

            [C, validTf] = results.getResponseCovariance(1, 2);

            %Only the cases where BOTH responses are valid contribute.
            testCase.verifyEqual(sum(validTf), 2);
            testCase.verifyEqual(C, cov(results.outputs(validTf, 1), results.outputs(validTf, 2)), 'RelTol', 1e-12);

            %Fewer than two points is not a scatter.
            lonely = LvdSweepResults();
            lonely.inputs = [1; 2];
            lonely.outputs = [1 2; NaN 3];
            lonely.responseLabels = {'A', 'B'};

            lonelyC = lonely.getResponseCovariance(1, 2);
            testCase.verifyTrue(all(isnan(lonelyC(:))), ...
                'A single point has no covariance to report');

            %The ellipse is defined by (p-c)'*inv(C)*(p-c) == nSigma^2, so check
            %its points against that directly rather than against another
            %eigendecomposition.
            Cov = [4 1; 1 9];
            center = [100, -50];

            for(nSigma = [1 2 3])
                [ex, ey] = LvdSweepResults.getErrorEllipse(Cov, center, nSigma, 64);

                testCase.assertNumElements(ex, 64);

                d = zeros(1, numel(ex));
                for(k = 1:numel(ex))
                    p = [ex(k) - center(1); ey(k) - center(2)];
                    d(k) = p' * (Cov \ p);
                end

                testCase.verifyEqual(d, nSigma^2 * ones(1, numel(ex)), 'RelTol', 1e-10, ...
                    sprintf('The %u-sigma ellipse is not the %u-sigma contour of this covariance', nSigma, nSigma));
            end

            %A diagonal covariance puts the semi-axes on the axes, which is the
            %case a reader of an insertion-error plot checks by eye.
            [ex, ey] = LvdSweepResults.getErrorEllipse(diag([4, 9]), [0 0], 2, 361);
            testCase.verifyEqual(max(ex), 4, 'AbsTol', 1e-9);
            testCase.verifyEqual(max(ey), 6, 'AbsTol', 1e-9);
            testCase.verifyEqual(min(ex), -4, 'AbsTol', 1e-9);

            %And an unusable covariance draws nothing rather than erroring
            %inside a plot callback.
            [ex, ey] = LvdSweepResults.getErrorEllipse(NaN(2,2), [0 0]);
            testCase.verifyEmpty(ex);
            testCase.verifyEmpty(ey);
        end

        function resultsRoundTripThroughEveryOutputFormat(testCase)
            results = testCase.syntheticResults();
            results.runName = 'Round Trip';
            results.seed = 1234;

            matPath = [tempname(), '.mat'];
            csvPath = [tempname(), '.csv'];
            xlsPath = [tempname(), '.xlsx'];
            junkPath = [tempname(), '.mat'];
            testCase.addTeardown(@() SweepEngineTest.deleteIfPresent({matPath, csvPath, xlsPath, junkPath}));

            results.writeMat(matPath);
            results.writeCsv(csvPath);
            results.writeExcel(xlsPath);

            reloaded = LvdSweepResults.loadFromFile(matPath);

            testCase.verifyEqual(reloaded.inputs, results.inputs);
            testCase.verifyEqual(reloaded.outputs, results.outputs);
            testCase.verifyEqual(reloaded.statuses, results.statuses);
            testCase.verifyEqual(reloaded.responseLabels, results.responseLabels);
            testCase.verifyEqual(reloaded.seed, results.seed);
            testCase.verifyEqual(reloaded.id, results.id, 'A results file must keep its identity');

            %The spreadsheet and the csv are for reading elsewhere, so what
            %matters is that the numbers survive the trip.
            T = results.toTable();
            fromCsv = readtable(csvPath);

            testCase.verifyEqual(height(fromCsv), results.getNumCases());
            testCase.verifyEqual(width(fromCsv), width(T));
            testCase.verifyEqual(fromCsv{:,2}, results.inputs(:,1), 'RelTol', 1e-9);
            testCase.verifyEqual(fromCsv{:,3}, results.outputs(:,1), 'RelTol', 1e-9);

            %The csv is the lossless format: NaN and Inf both come back as
            %themselves, so a case that failed reads as a failure.
            testCase.verifyEqual(fromCsv{:,4}, results.outputs(:,2), 'RelTol', 1e-9);

            fromXls = readtable(xlsPath, 'Sheet', 'Results');
            testCase.verifyEqual(fromXls{:,2}, results.inputs(:,1), 'RelTol', 1e-9);
            testCase.verifyEqual(fromXls{:,3}, results.outputs(:,1), 'RelTol', 1e-9);

            %A spreadsheet is not: Excel has no Inf, and writetable stores it as
            %65535.  Nothing to fix here -- the statistics mask Inf out anyway,
            %and no response evaluates to it -- but the xlsx comparison has to
            %be made over the values Excel can actually hold, or this test would
            %read as a defect in the writer.
            representable = isnan(results.outputs(:,2)) | isfinite(results.outputs(:,2));
            testCase.assertTrue(any(not(representable)), ...
                'Fixture broken: nothing here exercises the spreadsheet''s numeric limits');
            testCase.verifyEqual(fromXls{representable,4}, results.outputs(representable,2), 'RelTol', 1e-9);

            %The unit belongs with the numbers, in the column heading.
            testCase.verifyTrue(any(contains(T.Properties.VariableDescriptions, '(km)')), ...
                'A response column must be labelled with its unit');

            info = readcell(xlsPath, 'Sheet', 'Run Info');
            testCase.verifyTrue(any(strcmp(info(:,1), 'Seed')));
            testCase.verifyTrue(any(cellfun(@(c) isequal(c, 'Round Trip'), info(:,2))), ...
                'The run info sheet must record which run this was');

            %Both ways reading a results file back can fail.  They are ordinary
            %run-time situations -- a moved folder, a file picked by hand -- so
            %each has its own identifier for the window to catch on.
            testCase.verifyError(@() LvdSweepResults.loadFromFile([tempname(), '.mat']), ...
                'LvdSweepResults:fileNotFound');

            SweepEngineTest.writeJunkMatFile(junkPath);

            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                'MATLAB:load:variableNotFound'));
            testCase.verifyError(@() LvdSweepResults.loadFromFile(junkPath), ...
                'LvdSweepResults:notAResultsFile');
        end
    end

    methods(Access=private)

        function assumeNoParallelPool(testCase)
            %The serial fallback is the thing under test, so a session with a
            %pool open would exercise the other dispatch path instead.  Neither
            %a headless test run nor a fresh desktop has one.
            testCase.assumeEmpty(gcp('nocreate'), ...
                'A parallel pool is open in this session, so the no-pool path cannot be exercised');
        end

        function names = filesIn(~, folder)
            d = dir(folder);
            names = {d(not([d.isdir])).name};
        end

        function [cm, setup, ctx] = gridSweep(testCase, varargin)
            %gridSweep A one-parameter, three-case propagate-only sweep of the
            %initial state's Rx, with three responses whose values are known in
            %advance.
            p = inputParser();
            p.addParameter('runMode', LvdCaseMatrixRunModeEnum.PropagateOnly);
            p.addParameter('templateRx', testCase.TemplateRx);
            p.addParameter('persistCaseFiles', false);
            p.addParameter('strayParameter', false);
            p.parse(varargin{:});
            opts = p.Results;

            outDir = tempname();
            mkdir(outDir);
            testCase.addTeardown(@() rmdir(outDir, 's'));

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = ...
                CartesianElementSet(0, [opts.templateRx; 0; 0], [0; 2.2; 0], testCase.kerbinFrame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(testCase.EvtDuration);
            evt1.propagatorObj = evt1.twoBodyPropagator;

            initStateVar = InitialStateVariable(lvdData.initStateModel);
            initStateVar.setUseTfForVariable(true(1,7));

            %The stray case builds its parameter on a variable that was never
            %added to the mission, which is what a sweep definition looks like
            %after the user deleted the thing it swept.
            if(not(opts.strayParameter))
                lvdData.optimizer.vars.addVariable(initStateVar);
            end

            param = LvdSweepOptimVarParameter(initStateVar, testCase.RxElemInd, 'Initial State Rx', 'none');

            setup = LvdSweepSetup();
            setup.addParameter(param, LvdSweepGridVariation(testCase.GridLb, testCase.GridUb, testCase.GridStep));
            setup.samplingMode = LvdSweepSamplingEnum.FullFactorial;
            setup.runMode = opts.runMode;
            setup.persistCaseFiles = opts.persistCaseFiles;
            setup.writeGaTimeSeries = false;
            setup.writeXlsx = true;
            setup.writeMat = true;
            setup.writeCsv = false;
            setup.outputLocation = outDir;

            setup.addResponse(LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), ...
                                               LvdSweepResponseNodeEnum.InitialState, 0));
            setup.addResponse(LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), ...
                                               LvdSweepResponseNodeEnum.Maximum, 0));
            setup.addResponse(LvdSweepResponse(GraphicalAnalysisTask('Universal Time', testCase.kerbinFrame), ...
                                               LvdSweepResponseNodeEnum.FinalState, 0));

            if(not(opts.strayParameter))
                [tf, msg] = setup.validate(lvdData);
                testCase.assertTrue(tf, sprintf('Fixture broken: the setup does not validate (%s)', msg));
            end

            cm = LvdCaseMatrix(lvdData, outDir);
            cm.runName = 'EngineTest';
            cm.createTasksFromSetup(setup);

            testCase.assertEqual(numel(cm.tasks), 3, 'Fixture broken: expected a three case grid');

            ctx = struct('outDir', outDir, 'lvdData', lvdData, 'param', param, ...
                         'templateRx', opts.templateRx, 'initStateVar', initStateVar);
        end

        function results = syntheticResults(~)
            %syntheticResults Six cases covering both ways a response goes
            %missing: the case itself failed, and the case ran but the response
            %could not be evaluated.
            results = LvdSweepResults();

            results.inputs = (1:6)';
            results.outputs = [ 10   100; ...
                                12   110; ...
                                99   120; ...   %this case failed outright
                                16   NaN; ...   %response B unevaluable
                               NaN   130; ...   %response A unevaluable
                               NaN   Inf];      %and an Inf is not a value either

            results.statuses = [LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Failed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed];

            results.messages = {'ok', 'ok', 'propagation failed', 'ok', 'ok', 'ok'};
            results.paramLabels = {'Knob (km)'};
            results.responseLabels = {'Response A', 'Response B'};
            results.responseUnits = {'km', 'km'};
        end
    end

    methods(Static, Access=private)

        function cancelOnceCompleted(caseMatrix, evt)
            %The Cancel button's effect, driven off a status change instead of a
            %click: as soon as a case reports Completed, stop the run.
            if(evt.updatedData.newStatus == LvdCaseMatrixTaskStatusEnum.Completed)
                caseMatrix.runCanceled = true;
            end
        end

        function restoreDiary(logPath)
            diary('off');
            SweepEngineTest.deleteIfPresent({logPath});
        end

        function writeJunkMatFile(path)
            notAResultsFile = 1; %#ok<NASGU>
            save(path, 'notAResultsFile');
        end

        function deleteIfPresent(paths)
            for(i = 1:numel(paths))
                if(isfile(paths{i}))
                    delete(paths{i});
                end
            end
        end
    end
end
