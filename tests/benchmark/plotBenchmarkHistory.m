function plotBenchmarkHistory()
    % plotBenchmarkHistory Scans results directory and plots performance trends

    resultsDir = fullfile('tests', 'benchmark', 'results');
    if ~exist(resultsDir, 'dir')
        error('Results directory not found: %s', resultsDir);
    end

    files = dir(fullfile(resultsDir, 'results_*.mat'));
    if isempty(files)
        error('No result files found in %s', resultsDir);
    end

    % Parse files and group by LVD case
    data = struct();
    
    for i = 1:length(files)
        filePath = fullfile(resultsDir, files(i).name);
        res = load(filePath);
        results = res.results;
        
        [~, caseName] = fileparts(results.casePath);
        
        % Try to extract commit from filename (format: results_<commit>_<casename>.mat)
        tokens = regexp(files(i).name, 'results_(.*)_(.*)\.mat', 'tokens');
        if isempty(tokens)
            % Fallback for test files without commit hash
            commit = 'current';
        else
            commit = tokens{1}{1};
        end
        
        if ~isfield(data, caseName)
            data.(caseName) = struct('commit', {}, 'avgTime', {}, 'stdTime', {}, 'bottlenecks', {});
        end
        
        idx = length(data.(caseName)) + 1;
        data.(caseName)(idx).commit = commit;
        data.(caseName)(idx).avgTime = results.avgExecutionTime;
        data.(caseName)(idx).stdTime = results.stdExecutionTime;
        if isfield(results, 'bottlenecks')
            data.(caseName)(idx).bottlenecks = results.bottlenecks;
        end
    end

    % Plot trends
    caseNames = fieldnames(data);
    numCases = length(caseNames);
    
    if numCases == 0
        fprintf('No valid benchmark data found.\n');
        return;
    end
    
    figure('Name', 'LVD Performance Trends', 'Color', 'w');
    
    for i = 1:numCases
        caseName = caseNames{i};
        caseData = data.(caseName);
        
        subplot(numCases, 1, i);
        
        avgTimes = [caseData.avgTime];
        stdTimes = [caseData.stdTime];
        commits = {caseData.commit};
        
        if length(avgTimes) > 1
            errorbar(1:length(avgTimes), avgTimes, stdTimes, '-o', 'LineWidth', 1.5);
            set(gca, 'XTick', 1:length(commits), 'XTickLabel', commits);
            xtickangle(45);
        else
            bar(avgTimes);
            set(gca, 'XTickLabel', commits);
        end
        
        grid on;
        title(sprintf('Performance: %s', caseName), 'Interpreter', 'none');
        ylabel('Avg Execution Time (s)');
    end
    
    % Bottleneck Analysis
    fprintf('\n--- Bottleneck Analysis ---\n');
    for i = 1:numCases
        caseName = caseNames{i};
        caseData = data.(caseName);
        if length(caseData) >= 1
             fprintf('\nCase: %s (Latest commit: %s)\n', caseName, caseData(end).commit);
             if isfield(caseData(end), 'bottlenecks') && ~isempty(caseData(end).bottlenecks)
                 fprintf('Top 5 Bottlenecks:\n');
                 for b = 1:min(5, length(caseData(end).bottlenecks))
                     bn = caseData(end).bottlenecks(b);
                     fprintf('  %-40s: %.4fs (%d calls)\n', bn.FunctionName, bn.TotalTime, bn.NumCalls);
                 end
             end
             
             if length(caseData) > 1
                 last = caseData(end);
                 prev = caseData(end-1);
                 fprintf('Change from %s to %s: %.2f%% (%.4fs -> %.4fs)\n', ...
                     prev.commit, last.commit, (last.avgTime - prev.avgTime)/prev.avgTime * 100, ...
                     prev.avgTime, last.avgTime);
             end
        end
    end
end
