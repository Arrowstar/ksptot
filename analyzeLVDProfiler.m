clc; clear all; format long g; close all

addpath(genpath('.'));

%% Load LVD example data
load('SLS.mat');

%% Set tolerances for all events in the script
for(i = 1:length(lvdData.script.evts))
    lvdData.script.evts(i).integratorObj.options.AbsTol = 1E-6;
    lvdData.script.evts(i).integratorObj.options.RelTol = 1E-6;
end

%% Run the LVD script with profiling enabled
tic;
profile on;
for(i = 1:15) %#ok<*NO4LP>
    stateLog = lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false);
end
profile off;

%% Extract profiler data programmatically
p = profile('info');

fprintf('\n=== LVD Propagation Performance Analysis ===\n\n');

% Display top functions by execution time
fprintf('Top 10 Functions by Execution Time:\n');
fprintf('------------------------------------\n');
fprintf('%-40s %-20s %-15s\n', 'Function Name', 'Total Time (s)', 'Num Calls');
fprintf('%-40s %-20s %-15s\n', '------------------------', '--------------------', '---------------');

for i = 1:length(p.FunctionTable)
    fprintf('%-40s %-20.6f %-15d\n', ...
        p.FunctionTable(i).FunctionName, p.FunctionTable(i).TotalTime, p.FunctionTable(i).NumCalls);
end

% Calculate total time and average per call
totalTime = 0;
numCallsTotal = 0;
for i = 1:length(p.FunctionTable)
    totalTime = totalTime + p.FunctionTable(i).TotalTime;
    numCallsTotal = numCallsTotal + p.FunctionTable(i).NumCalls;
end
avgPerCall = totalTime / numCallsTotal;

fprintf('\nTotal Execution Time: %.6f seconds\n', totalTime);
fprintf('Average Time Per Call: %.6f seconds\n', avgPerCall);

%% Identify performance bottlenecks
fprintf('\n=== Performance Bottleneck Analysis ===\n');

% Find functions with the highest time percentage
topFunctions = 10;
sortedIdx = sortrows(p.FunctionTable.TotalTime, 'descend');
topIdx = sortedIdx(1:topFunctions);

fprintf('Top %d Functions Contributing to Execution Time:\n', topFunctions);
fprintf('%-40s %-20s %-15s\n', 'Function Name', 'Time (s)', '% of Total');
fprintf('%-40s %-20s %-15s\n', '------------------------', '--------------------', '---------------');

for i = 1:topFunctions
    idx = topIdx(i);
    timePct = p.FunctionTable(idx).TotalTime / totalTime * 100;
    fprintf('%-40s %-20.6f %-15.3f%%\n', ...
        p.FunctionTable(idx).FunctionName, p.FunctionTable(idx).TotalTime, timePct);
end

% Identify the top bottleneck function
maxTimeIdx = sortedIdx(1);
fprintf('\n--- Primary Bottleneck ---\n');
fprintf('Function: %s\n', p.FunctionTable(maxTimeIdx).FunctionName);
fprintf('Execution Time: %.6f seconds (%.3f%% of total)\n', ...
    p.FunctionTable(maxTimeIdx).TotalTime, p.FunctionTable(maxTimeIdx).TotalTime / totalTime * 100);

% Check for nested function calls (potential optimization opportunities)
fprintf('\n=== Nested Function Analysis ===\n');
for i = 1:length(p.FunctionTable)
    % Get parent function name if available in profiler data
    if ~isempty(p.FunctionTable(i).Parents)
        fprintf('Function: %s\n', p.FunctionTable(i).FunctionName);
        for j = 1:length(p.FunctionTable(i).Parents)
            fprintf('  Parent: %s\n', p.FunctionTable(i).Parents{j});
        end
        fprintf('  Time: %.6f seconds (%.3f%%)\n', ...
            p.FunctionTable(i).TotalTime, p.FunctionTable(i).TotalTime / totalTime * 100);
    end
end

fprintf('\n=== Recommendations ===\n');
if topFunctions > 5 && p.FunctionTable(maxTimeIdx).FunctionName(1) ~= 'main'
    fprintf('1. Focus optimization efforts on: %s\n', ...
        p.FunctionTable(maxTimeIdx).FunctionName);
    fprintf('2. Consider vectorizing operations in the bottleneck function\n');
    fprintf('3. Check for redundant calculations or unnecessary function calls\n');
end

fprintf('\nProfiler data saved to HTML file.\n');
