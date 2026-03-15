function runHistoricalBenchmark(commits, lvdCases)
    % runHistoricalBenchmark Orchestrates benchmarks across different git commits
    %
    % commits: Cell array of commit hashes/branch names
    % lvdCases: Cell array of paths to LVD .mat files

    if nargin < 2
        % Default cases if none provided
        lvdCases = {
            fullfile('examples', 'LaunchVehicleDesigner', 'ComplexDragModel', 'lvdExample_ComplexDrag_AsparagusStaging.mat'),
            fullfile('examples', 'LaunchVehicleDesigner', 'lvdExample_L2HaloOrbit.mat')
        };
    end

    % Get current branch to restore later
    [status, cmdOut] = system('git rev-parse --abbrev-ref HEAD');
    if status ~= 0
        error('Git not found or not a git repository');
    end
    originalBranch = strtrim(cmdOut);
    fprintf('Original branch is %s. Will restore after benchmark.\n', originalBranch);

    % NO STASHING HERE - Recommend user to commit/stash first to avoid conflicts
    fprintf('Warning: This script assumes a clean workspace for git checkouts to succeed.\n');

    % Results directory
    resultsDir = fullfile('tests', 'benchmark', 'results');
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    try
        for i = 1:length(commits)
            commit = commits{i};
            fprintf('\n--- Benchmarking Commit: %s ---\n', commit);
            
            % Checkout commit (force if necessary, but careful)
            [status, cmdOut] = system(sprintf('git checkout %s', commit));
            if status ~= 0
                fprintf('Failed to checkout %s: %s\n', commit, cmdOut);
                fprintf('Skipping this commit. Please ensure workspace is clean.\n');
                continue;
            end
            
            % For each case, run benchmark in a fresh MATLAB process
            for j = 1:length(lvdCases)
                casePath = lvdCases{j};
                [~, caseName] = fileparts(casePath);
                
                outputFile = fullfile(pwd, resultsDir, sprintf('results_%s_%s.mat', commit, caseName));
                
                % Construct MATLAB batch command
                % Use full paths for robustness
                benchDir = fullfile(pwd, 'tests', 'benchmark');
                
                matlabCmd = sprintf('matlab -batch "addpath(genpath(''%s'')); benchmarkLvdPerformance(''%s'', ''%s'', true); exit;"', ...
                                    benchDir, casePath, outputFile);
                
                fprintf('Running benchmark for %s...\n', caseName);
                tic;
                [status, cmdOut] = system(matlabCmd);
                runTime = toc;
                
                if status ~= 0
                    fprintf('Benchmark failed for %s at commit %s\n', caseName, commit);
                    fprintf('Output Log:\n%s\n', cmdOut);
                else
                    fprintf('Benchmark completed in %.2f seconds.\n', runTime);
                end
            end
        end
    catch ME
        fprintf('Error during historical benchmark: %s\n', ME.message);
    end

    % Restore original branch
    fprintf('\nRestoring original branch: %s\n', originalBranch);
    system(sprintf('git checkout %s', originalBranch));
    
    fprintf('\nHistorical benchmark run complete.\n');
end
