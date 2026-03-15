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

    % Store current directory as project root
    projectRoot = strrep(pwd(), '\', '/');

    % Get current branch to restore later
    [status, cmdOut] = system('git rev-parse --abbrev-ref HEAD');
    if status ~= 0
        error('Git not found or not a git repository');
    end
    originalBranch = strtrim(cmdOut);
    fprintf('Original branch is %s. Will restore after benchmark.\n', originalBranch);

    % Results directory
    resultsDir = fullfile('tests', 'benchmark', 'results');
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    % Persistence: Copy benchmarkLvdPerformance to a temp location so it's
    % available even if the current commit doesn't have it.
    tempBenchDir = fullfile(tempdir, ['lvd_bench_', char(regexp(tempname, '(?<=\\)[^\\]+$', 'match'))]);
    mkdir(tempBenchDir);
    copyfile(fullfile(pwd, 'tests', 'benchmark', 'benchmarkLvdPerformance.m'), tempBenchDir);
    fprintf('Persisted benchmark script to %s\n', tempBenchDir);

    try
        for i = 1:length(commits)
            commit = commits{i};
            fprintf('\n--- Benchmarking Commit: %s ---\n', commit);
            
            % Checkout commit (FORCE to handle changes in benchmark scripts)
            [status, cmdOut] = system(sprintf('git checkout -f %s', commit));
            if status ~= 0
                fprintf('Failed to checkout %s: %s\n', commit, cmdOut);
                continue;
            end
            
            % For each case, run benchmark in a fresh MATLAB process
            for j = 1:length(lvdCases)
                casePath = lvdCases{j};
                [~, caseName] = fileparts(casePath);
                
                outputFile = fullfile(pwd(), resultsDir, sprintf('results_%s_%s.mat', commit, caseName));
                
                % Use forward slashes for the MATLAB command string to avoid escaping hell on Windows
                forwardTempDir = strrep(tempBenchDir, '\', '/');
                forwardCasePath = strrep(casePath, '\', '/');
                forwardOutputFile = strrep(outputFile, '\', '/');
                forwardProjectRoot = projectRoot;
                
                matlabCmd = sprintf('matlab -batch "addpath(''%s''); fprintf(''Running from: %%s\\n'', which(''benchmarkLvdPerformance'')); benchmarkLvdPerformance(''%s'', ''%s'', true, ''%s''); exit;"', ...
                                    forwardTempDir, forwardCasePath, forwardOutputFile, forwardProjectRoot);
                
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

    % Restore original branch (FORCE)
    fprintf('\nRestoring original branch: %s\n', originalBranch);
    system(sprintf('git checkout -f %s', originalBranch));
    
    % Cleanup temp script
    if exist(tempBenchDir, 'dir')
        rmdir(tempBenchDir, 's');
    end
    
    fprintf('\nHistorical benchmark run complete.\n');
end
