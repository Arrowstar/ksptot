clc; clear all; format long g; close all;

% Set up paths
addpath(genpath('examples'));
addpath(genpath('helper_methods'));
addpath(genpath('formsGUIs'));
addpath(genpath('kspTOT_RTS'));
addpath(genpath('kspTOT_MissionArchitect'));
addpath(genpath('kspTOT_LaunchVehicleDesigner'));
addpath(genpath('kspTOT_VehicleSizer'));
addpath(genpath('kspTOT_SingleUIs'));
addpath(genpath('images'));
addpath(genpath('kos_scripts'));

% Load the LVD case
lvdCasePath = fullfile('examples', 'LaunchVehicleDesigner', 'lvdExample_L2HaloOrbit.mat');
if ~exist(lvdCasePath, 'file')
    error('LVD case file not found: %s', lvdCasePath);
end
load(lvdCasePath);

% Adjust integrator tolerances for profiling
for i = 1:length(lvdData.script.evts)
    lvdData.script.evts(i).integratorObj.options.AbsTol = 1E-6;
    lvdData.script.evts(i).integratorObj.options.RelTol = 1E-6;
end

% Warm up run
fprintf('Starting warm-up run...\n');
lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false);

% Start profiling
fprintf('Starting profiling runs...\n');
numRuns = 5; % Reduced from 15 to save time while still getting good data
profile off; profile on;
tic;
for i = 1:numRuns
    fprintf('Run %d/%d...\n', i, numRuns);
    lvdData.script.executeScript(false, lvdData.script.evts(1), true, false, false, false);
end
tTotal = toc;
profile off;

p = profile('info');

% Process results
ft = p.FunctionTable;
[~, idx] = sort([ft.TotalTime], 'descend');
sortedFT = ft(idx);

fprintf('\nTop 20 Bottleneck Functions (by Total Time):\n');
fprintf('%-60s | %-12s | %-12s | %-12s\n', 'Function Name', 'Total Time', 'Num Calls', 'Time/Call');
fprintf('%s\n', repmat('-', 1, 105));

for i = 1:min(20, length(sortedFT))
    f = sortedFT(i);
    avgTime = f.TotalTime / f.NumCalls;
    fprintf('%-60s | %12.4f | %12d | %12.6f\n', f.FunctionName, f.TotalTime, f.NumCalls, avgTime);
end

% Look for LVD-specific bottlenecks
fprintf('\nTop 20 LVD/KSPTOT Bottleneck Functions:\n');
fprintf('%-60s | %-12s | %-12s | %-12s\n', 'Function Name', 'Total Time', 'Num Calls', 'Time/Call');
fprintf('%s\n', repmat('-', 1, 105));

count = 0;
for i = 1:length(sortedFT)
    f = sortedFT(i);
    % Filter for project-specific functions (usually have 'lvd' or 'ma' or 'ksptot' or are in our paths)
    % A good proxy is checking if the file path contains our project root or specific folders.
    if contains(f.FileName, 'ksptot') || contains(f.FileName, 'lvd') || contains(f.FileName, 'helper_methods')
        avgTime = f.TotalTime / f.NumCalls;
        fprintf('%-60s | %12.4f | %12d | %12.6f\n', f.FunctionName, f.TotalTime, f.NumCalls, avgTime);
        count = count + 1;
    end
    if count >= 20
        break;
    end
end
