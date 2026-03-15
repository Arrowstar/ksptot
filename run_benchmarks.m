% run_benchmarks.m
% Wrapper to run multiple LVD benchmarks with profiling

% Add path to the benchmark function
addpath(fullfile(pwd, 'tests', 'benchmark'));

files = { ...
    'examples\LaunchVehicleDesigner\lvdExample_ElecPowerExample.mat', ...
    'examples\LaunchVehicleDesigner\ComplexDragModel\lvdExample_ComplexDrag_AsparagusStaging.mat', ...
    'examples\LaunchVehicleDesigner\lvdExample_TwoStageToOrbit.mat', ...
    'examples\LaunchVehicleDesigner\lvdExample_SolarSailOrbitRaising.mat', ...
    'examples\LaunchVehicleDesigner\lvdExample_L2HaloOrbit.mat' ...
};

numFiles = length(files);
resultsArr = [];

fprintf('Starting LVD Performance Benchmark with PROFILING for %d files...\n', numFiles);

for i = 1:numFiles
    filePath = files{i};
    [~, name, ~] = fileparts(filePath);
    fprintf('------------------------------------------------------------\n');
    fprintf('Benchmarking and Profiling (%d/%d): %s\n', i, numFiles, name);
    
    outputPath = fullfile(pwd, sprintf('benchmark_results_%s.mat', name));
    
    try
        % Call benchmarkLvdPerformance with runProfile = true
        res = benchmarkLvdPerformance(fullfile(pwd, filePath), outputPath, true, pwd);
        
        resultsArr = [resultsArr; res];
        
        % Print top bottlenecks for this case
        if isfield(res, 'bottlenecks') && ~isempty(res.bottlenecks)
            fprintf('\nTop Bottlenecks for %s:\n', name);
            fprintf('%-50s | %-10s | %-10s\n', 'Function Name', 'Total Time', 'Num Calls');
            fprintf('--------------------------------------------------------------------------------\n');
            numToShow = min(10, length(res.bottlenecks));
            for j = 1:numToShow
                bn = res.bottlenecks(j);
                fprintf('%-50s | %10.4f | %10d\n', bn.FunctionName, bn.TotalTime, bn.NumCalls);
            end
        end
        
    catch ME
        fprintf('Error benchmarking %s: %s\n', name, ME.message);
        fprintf('%s\n', getReport(ME));
    end
end

% Display Final Summary Table
fprintf('\n\nLVD Performance Benchmark Summary:\n');
fprintf('--------------------------------------------------------------------------------\n');
fprintf('%-40s | %-15s | %-15s\n', 'Case Name', 'Avg Time (s)', 'Std Dev (s)');
fprintf('--------------------------------------------------------------------------------\n');

for i = 1:length(resultsArr)
    [~, name, ~] = fileparts(resultsArr(i).casePath);
    fprintf('%-40s | %15.4f | %15.4f\n', name, resultsArr(i).avgExecutionTime, resultsArr(i).stdExecutionTime);
end
fprintf('--------------------------------------------------------------------------------\n');
