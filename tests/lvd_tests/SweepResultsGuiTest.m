classdef SweepResultsGuiTest < KsptotTestCase
    %SweepResultsGuiTest The shared sweep/Monte Carlo results viewer (G1/G2).
    %
    % Covers lvd_SweepResultsGUI_App against a synthetic LvdSweepResults, so
    % no mission or propagation is involved: the data tab mirrors the
    % results object, the percentile table matches a hand-computed oracle,
    % the error-ellipse points satisfy the defining quadratic form, the
    % scatter dropdowns resolve to the right columns, and CSV export
    % round-trips through readtable.

    methods(Test)
        function dataTableHasOneRowPerCaseWithInputsOutputsAndStatus(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            T = app.getDataTable();

            testCase.verifyEqual(height(T), 6, 'One row per case');
            testCase.verifyEqual(T.Case, (1:6)');
            testCase.verifyTrue(any(contains(T.Properties.VariableDescriptions, 'Knob (km)')), ...
                'An input column carries the parameter label');
        end

        function defaultPercentilesMatchHandComputedOracle(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            S = app.getStatsStruct(50);

            %Response A valid values: completed rows with finite values
            %(10, 12, 16).  Median is 12.
            testCase.verifyEqual(S(1).n, 6);
            testCase.verifyEqual(S(1).nValid, 3);
            testCase.verifyEqual(S(1).pctValues, 12, 'AbsTol', 1e-12);
            testCase.verifyEqual(S(1).mean, mean([10 12 16]), 'RelTol', 1e-12);
            testCase.verifyEqual(S(1).min, 10);
            testCase.verifyEqual(S(1).max, 16);

            %Response B valid values exclude the failed case, the NaN and
            %the Inf.
            testCase.verifyEqual(S(2).nValid, 3);
        end

        function ellipsePointsSatisfyTheQuadraticForm(testCase)
            %Five jointly valid points, so the covariance is full rank (the
            %shared synthetic fixture has only two rows where both
            %responses are valid, which is a degenerate ellipse).
            r = LvdSweepResults();
            r.inputs = (1:5)';
            r.outputs = [10 100; 12 107; 14 109; 16 116; 18 121];
            r.statuses = repmat(LvdCaseMatrixTaskStatusEnum.Completed, 1, 5);
            r.paramLabels = {'Knob (km)'};
            r.responseLabels = {'Response A', 'Response B'};
            r.responseUnits = {'km', 'km'};
            app = testCase.hiddenWindow(r);

            [ex, ey] = app.getEllipsePoints(1, 2, 2);

            testCase.verifyEqual(numel(ex), 200);
            testCase.verifyEqual(numel(ey), 200);

            a = r.outputs(:, 1);
            b = r.outputs(:, 2);
            C = cov([a, b]);
            center = [mean(a), mean(b)];

            d = ([ex(:) - center(1), ey(:) - center(2)] / C) .* [ex(:) - center(1), ey(:) - center(2)];
            testCase.verifyEqual(sqrt(sum(d, 2)), repmat(2, size(ex(:))), 'RelTol', 1e-9, ...
                'Ellipse points must sit 2 sigma from the center in Mahalanobis distance');
        end

        function scatterSelectionsResolveToTheRightColumns(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            app.setScatterSelections('Knob (km)', 'Response A (km)', '(none)');
            [x, y, c] = app.getScatterData();

            %Row-aligned: the failed case still plots its input against its
            %harvested response; only the NaN rows drop out of both.
            testCase.verifyEqual(x, [1; 2; 3; 4]);
            testCase.verifyEqual(y, [10; 12; 99; 16]);
            testCase.verifyEmpty(c);

            app.setScatterSelections('Knob (km)', 'Response A (km)', 'Response B (km)');
            [~, ~, c2] = app.getScatterData();
            testCase.verifyEqual(c2, [100; 110; 120], ...
                'The colour column further restricts to rows where IT is finite');
        end

        function csvExportRoundTripsThroughReadtable(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            outFile = fullfile(tempdir(), 'sweepResultsGuiTest.csv');
            testCase.addTeardown(@() SweepResultsGuiTest.deleteIfPresent(outFile));

            app.exportCsv(outFile);

            testCase.verifyTrue(isfile(outFile), 'Export must write the file');
            T = readtable(outFile);
            testCase.verifyEqual(height(T), 6);
            testCase.verifyEqual(width(T), width(app.getDataTable()));
        end

        function emptyResultsConstructWithoutError(testCase)
            r = LvdSweepResults();
            app = testCase.hiddenWindow(r);

            testCase.verifyEqual(height(app.getDataTable()), 0);
            testCase.verifyEqual(numel(app.getStatsStruct()), 0);
            testCase.verifyEqual(app.ScatterStatusLabel.Text, '0 of 0 cases plotted.');
            testCase.verifyEqual(app.StatsStatusLabel.Text, 'No responses in these results.');
        end

        function scatterBannerCountsExcludedCases(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            app.setScatterSelections('Knob (km)', 'Response A (km)', '(none)');

            testCase.verifyEqual(app.ScatterStatusLabel.Text, ...
                '4 of 6 cases plotted (2 excluded: failed, unpropagated or unevaluable responses).');
        end

        function statsBannerCountsValidSamples(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            testCase.verifyEqual(app.StatsStatusLabel.Text, ...
                'Response A: 3 of 6 valid (3 excluded: failed, unpropagated or unevaluable).');
        end

        function statsBannerFollowsTheSelectedResponse(testCase)
            app = testCase.hiddenWindow(testCase.syntheticResults());

            app.RespDropDown.Value = 'Response B';
            app.RespDropDown.ValueChangedFcn(app.RespDropDown, []);

            testCase.verifyEqual(app.StatsStatusLabel.Text, ...
                'Response B: 3 of 6 valid (3 excluded: failed, unpropagated or unevaluable).');
        end

        function bannersShowFullCountsWhenNothingIsExcluded(testCase)
            r = LvdSweepResults();
            r.inputs = (1:4)';
            r.outputs = [10 100; 12 110; 14 120; 16 130];
            r.statuses = repmat(LvdCaseMatrixTaskStatusEnum.Completed, 1, 4);
            r.paramLabels = {'Knob (km)'};
            r.responseLabels = {'Response A', 'Response B'};
            r.responseUnits = {'km', 'km'};
            app = testCase.hiddenWindow(r);

            app.setScatterSelections('Knob (km)', 'Response A (km)', '(none)');

            testCase.verifyEqual(app.ScatterStatusLabel.Text, '4 of 4 cases plotted.');
            testCase.verifyEqual(app.StatsStatusLabel.Text, 'Response A: all 4 samples valid.');
        end
    end

    methods(Access=private)
        function app = hiddenWindow(testCase, results)
            app = lvd_SweepResultsGUI_App(results, false);
            testCase.addTeardown(@() delete(app));
        end

        function results = syntheticResults(~)
            results = LvdSweepResults();
            results.runName = 'GuiTest';
            results.inputs = (1:6)';
            results.outputs = [ 10   100; ...
                                12   110; ...
                                99   120; ...
                                16   NaN; ...
                               NaN   130; ...
                               NaN   Inf];
            results.statuses = [LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Failed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed, ...
                                LvdCaseMatrixTaskStatusEnum.Completed];
            results.messages = repmat({'ok'}, 1, 6);
            results.paramLabels = {'Knob (km)'};
            results.responseLabels = {'Response A', 'Response B'};
            results.responseUnits = {'km', 'km'};
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
