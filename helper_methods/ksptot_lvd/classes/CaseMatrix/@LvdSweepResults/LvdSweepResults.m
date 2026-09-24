classdef LvdSweepResults < matlab.mixin.SetGet
    %LvdSweepResults The table of numbers a sweep or Monte Carlo run
    %produces, plus the statistics over it.
    %
    %   Saved as <run name>_results.mat under the single variable
    %   sweepResults, which is what lvd_SweepResultsGUI_App loads.  It holds
    %   no mission objects at all -- just the inputs, the outputs and enough
    %   provenance (sampling mode, seed, run mode, timestamp) to repeat the
    %   run -- so it stays small at any sample count and can be handed
    %   around without dragging a mission with it.

    properties
        runName(1,:) char = 'Sweep';

        %N x P applied parameter values, and N x R harvested responses.
        %NaN in outputs means that case could not produce that response.
        inputs double = [];
        outputs double = [];

        %Optimize-mode summary columns, one row per case: the final
        %objective value and the optimizer exit flag.  All NaN in
        %propagate-only mode, where nothing optimizes.
        objectiveValues double = [];
        exitflags double = [];

        statuses(1,:) LvdCaseMatrixTaskStatusEnum = LvdCaseMatrixTaskStatusEnum.empty(1,0);
        messages(1,:) cell = {};
        caseFilePaths(1,:) cell = {};

        paramLabels(1,:) cell = {};
        responseLabels(1,:) cell = {};
        responseUnits(1,:) cell = {};

        samplingMode(1,1) LvdSweepSamplingEnum = LvdSweepSamplingEnum.FullFactorial;
        seed(1,1) double = 0;
        runMode(1,1) LvdCaseMatrixRunModeEnum = LvdCaseMatrixRunModeEnum.Optimize;

        timestamp(1,1) double = 0;   %now() at the end of the run
        ksptotVer(1,:) char = '';

        id(1,1) double = 0;
    end

    properties(Constant)
        %+/- 1, 2 and 3 sigma of a normal distribution, plus the median.  The
        %defaults a dispersion report is expected to quote.
        DefaultPercentiles = [0.13, 2.28, 15.87, 50, 84.13, 97.72, 99.87];
    end

    methods
        function obj = LvdSweepResults()
            obj.id = rand();
        end

        function n = getNumCases(obj)
            n = height(obj.inputs);
        end

        function tf = getValidMask(obj, respInd)
            %getValidMask Cases that completed AND produced a finite value
            %for the given response (all responses when respInd is omitted).
            arguments
                obj(1,1) LvdSweepResults
                respInd double = [];
            end

            n = obj.getNumCases();

            if(numel(obj.statuses) == n)
                tf = (obj.statuses == LvdCaseMatrixTaskStatusEnum.Completed);
                tf = tf(:);
            else
                tf = true(n, 1);
            end

            if(not(isempty(respInd)) && respInd >= 1 && respInd <= width(obj.outputs))
                tf = tf & isfinite(obj.outputs(:, respInd));
            end
        end

        function T = toTable(obj)
            %toTable One row per case: inputs, outputs, status and message.
            n = obj.getNumCases();

            vars = {};
            names = {};

            vars{end+1} = (1:n)';
            names{end+1} = 'Case';

            for(i=1:width(obj.inputs)) %#ok<*NO4LP>
                vars{end+1} = obj.inputs(:,i); %#ok<AGROW>
                names{end+1} = obj.paramLabels{i}; %#ok<AGROW>
            end

            for(i=1:width(obj.outputs))
                vars{end+1} = obj.outputs(:,i); %#ok<AGROW>

                lbl = obj.responseLabels{i};
                if(i <= numel(obj.responseUnits) && not(isempty(obj.responseUnits{i})))
                    lbl = sprintf('%s (%s)', lbl, obj.responseUnits{i});
                end
                names{end+1} = lbl; %#ok<AGROW>
            end

            %Optimize-mode columns appear only when at least one case has
            %them, so propagate-only tables are byte-for-byte what they were.
            if(numel(obj.objectiveValues) == n && any(isfinite(obj.objectiveValues)))
                vars{end+1} = obj.objectiveValues(:);
                names{end+1} = 'Objective (final)';
            end

            if(numel(obj.exitflags) == n && any(not(isnan(obj.exitflags))))
                tags = cell(n, 1);
                for(i=1:n)
                    tags{i} = LvdSweepResults.exitStatusTag(obj.exitflags(i));
                end
                vars{end+1} = tags;
                names{end+1} = 'Exit Status';
            end

            if(numel(obj.statuses) == n)
                vars{end+1} = {obj.statuses.name}';
                names{end+1} = 'Status';
            end

            if(numel(obj.messages) == n)
                vars{end+1} = obj.messages(:);
                names{end+1} = 'Message';
            end

            T = table(vars{:}, 'VariableNames', matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(names)));
            T.Properties.VariableDescriptions = names;
        end

        function S = getStatistics(obj, pctLevels)
            %getStatistics Per-response summary over the cases that completed.
            %
            %   Percentiles are the plain nearest-rank-with-interpolation
            %   definition on the sorted valid samples, written out here
            %   rather than calling prctile so a dispersion report does not
            %   require the Statistics and Machine Learning Toolbox.
            arguments
                obj(1,1) LvdSweepResults
                pctLevels(1,:) double = LvdSweepResults.DefaultPercentiles;
            end

            numResp = width(obj.outputs);

            S = struct('label', {}, 'unit', {}, 'n', {}, 'nValid', {}, ...
                       'mean', {}, 'std', {}, 'min', {}, 'max', {}, ...
                       'pctLevels', {}, 'pctValues', {});

            for(j=1:numResp)
                validTf = obj.getValidMask(j);
                v = obj.outputs(validTf, j);

                if(isempty(v))
                    entry = struct('label', obj.responseLabels{j}, ...
                                   'unit', obj.getResponseUnit(j), ...
                                   'n', obj.getNumCases(), 'nValid', 0, ...
                                   'mean', NaN, 'std', NaN, 'min', NaN, 'max', NaN, ...
                                   'pctLevels', pctLevels, ...
                                   'pctValues', NaN(size(pctLevels)));
                else
                    entry = struct('label', obj.responseLabels{j}, ...
                                   'unit', obj.getResponseUnit(j), ...
                                   'n', obj.getNumCases(), 'nValid', numel(v), ...
                                   'mean', mean(v), 'std', std(v), ...
                                   'min', min(v), 'max', max(v), ...
                                   'pctLevels', pctLevels, ...
                                   'pctValues', LvdSweepResults.percentile(v, pctLevels));
                end

                S(end+1) = entry; %#ok<AGROW>
            end
        end

        function [C, validTf] = getResponseCovariance(obj, respIndA, respIndB)
            %getResponseCovariance 2x2 covariance of two responses over the
            %cases where both are valid.  This is what draws the error
            %ellipse in the statistics view.
            arguments
                obj(1,1) LvdSweepResults
                respIndA(1,1) double
                respIndB(1,1) double
            end

            validTf = obj.getValidMask(respIndA) & obj.getValidMask(respIndB);

            a = obj.outputs(validTf, respIndA);
            b = obj.outputs(validTf, respIndB);

            if(numel(a) < 2)
                C = NaN(2,2);
                return;
            end

            C = cov([a, b]);
        end

        function unit = getResponseUnit(obj, j)
            if(j >= 1 && j <= numel(obj.responseUnits))
                unit = obj.responseUnits{j};
            else
                unit = '';
            end
        end

        function writeExcel(obj, filePath)
            %writeExcel Results sheet plus a run info sheet.
            arguments
                obj(1,1) LvdSweepResults
                filePath(1,:) char
            end

            writetable(obj.toTable(), filePath, 'Sheet', 'Results', 'WriteMode', 'overwritesheet');

            info = obj.getRunInfoCell();
            writecell(info, filePath, 'Sheet', 'Run Info', 'WriteMode', 'overwritesheet');
        end

        function writeCsv(obj, filePath)
            arguments
                obj(1,1) LvdSweepResults
                filePath(1,:) char
            end

            writetable(obj.toTable(), filePath);
        end

        function writeMat(obj, filePath)
            %writeMat Saved under the fixed variable name the results window
            %looks for.
            arguments
                obj(1,1) LvdSweepResults
                filePath(1,:) char
            end

            sweepResults = obj; %#ok<NASGU>
            save(filePath, 'sweepResults');
        end

        function info = getRunInfoCell(obj)
            info = {'Run Name',      obj.runName; ...
                    'Run Mode',      obj.runMode.name; ...
                    'Sampling',      obj.samplingMode.name; ...
                    'Seed',          obj.seed; ...
                    'Cases',         obj.getNumCases(); ...
                    'Cases Completed', sum(obj.getValidMask()); ...
                    'KSPTOT Version', obj.ksptotVer};

            if(obj.timestamp > 0)
                info(end+1,:) = {'Completed', datestr(obj.timestamp, 'yyyy-mm-dd HH:MM:SS')}; %#ok<DATST>
            end
        end
    end

    methods(Static)
        function [tag, color] = exitStatusTag(exitflag)
            %exitStatusTag One-word optimality verdict for an optimizer exit
            %flag, solver-agnostic: positive means the solver reports
            %success, zero an iteration/resource limit, negative failure
            %(-Inf is this codebase's "error" sentinel).  The solver's own
            %message (in the case message column) carries the details.
            arguments
                exitflag(1,1) double
            end

            if(isnan(exitflag))
                tag = '';
                color = [0.55 0.55 0.55];
            elseif(exitflag == -Inf)
                tag = 'Error';
                color = [0.80 0.20 0.20];
            elseif(exitflag > 0)
                tag = 'Converged';
                color = [0.20 0.60 0.20];
            elseif(exitflag == 0)
                tag = 'Limit';
                color = [0.80 0.60 0.10];
            else
                tag = 'Failed';
                color = [0.80 0.20 0.20];
            end
        end

        function v = percentile(x, levels)
            %percentile Linear-interpolation percentile on sorted samples.
            %
            %   Uses MATLAB's own prctile convention: sample k of n sits at
            %   percentile 100*(k - 0.5)/n, with the extremes clamped.  Spelt
            %   out so this works without the Statistics toolbox and so the
            %   tests can check it against a hand computed oracle.
            x = sort(x(:));
            n = numel(x);

            v = NaN(size(levels));

            if(n == 0)
                return;
            end

            if(n == 1)
                v(:) = x;
                return;
            end

            samplePcts = 100*((1:n)' - 0.5)/n;

            for(i=1:numel(levels))
                p = levels(i);

                if(p <= samplePcts(1))
                    v(i) = x(1);
                elseif(p >= samplePcts(end))
                    v(i) = x(end);
                else
                    v(i) = interp1(samplePcts, x, p, 'linear');
                end
            end
        end

        function [ex, ey] = getErrorEllipse(C, center, nSigma, numPts)
            %getErrorEllipse Points of the nSigma covariance ellipse, for the
            %insertion-error / landing-footprint plot.
            arguments
                C(2,2) double
                center(1,2) double
                nSigma(1,1) double = 1;
                numPts(1,1) double = 200;
            end

            ex = [];
            ey = [];

            if(any(not(isfinite(C(:)))))
                return;
            end

            [V, D] = eig(C);
            d = diag(D);
            d(d < 0) = 0;

            t = linspace(0, 2*pi, numPts);
            circle = [cos(t); sin(t)];

            pts = V * diag(nSigma * sqrt(d)) * circle;

            ex = pts(1,:) + center(1);
            ey = pts(2,:) + center(2);
        end

        function obj = loadobj(obj)
            if(obj.id == 0)
                obj.id = rand();
            end
        end

        function results = loadFromFile(filePath)
            %loadFromFile Reads a results .mat, erroring clearly when the
            %file is not one.
            arguments
                filePath(1,:) char
            end

            if(not(isfile(filePath)))
                error('LvdSweepResults:fileNotFound', 'Results file not found: %s', filePath);
            end

            s = load(filePath, 'sweepResults');

            if(not(isfield(s, 'sweepResults')))
                error('LvdSweepResults:notAResultsFile', ...
                      'The file "%s" does not contain sweep results.', filePath);
            end

            results = s.sweepResults;
        end
    end
end
