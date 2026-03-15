function benchmarkLvdPerformance(lvdCasePath, outputPath, runProfile)
    % benchmarkLvdPerformance Runs an LVD case and records performance metrics
    %
    % lvdCasePath: Path to the .mat LVD case file
    % outputPath: Path to save the results (.mat file)
    % runProfile: Boolean, whether to run the MATLAB profiler

    if nargin < 3
        runProfile = false;
    end

    % Set up paths
    if ~isdeployed
        % Get the project root assuming this script is in tests/benchmark
        scriptPath = mfilename('fullpath');
        projectRoot = fileparts(fileparts(fileparts(scriptPath)));
        
        origDir = pwd();
        cd(projectRoot);
        
        addpath(genpath('helper_methods'));
        addpath(genpath('formsGUIs'));
        addpath(genpath('kspTOT_RTS'));
        addpath(genpath('kspTOT_MissionArchitect'));
        addpath(genpath('kspTOT_LaunchVehicleDesigner'));
        addpath(genpath('kspTOT_VehicleSizer'));
        addpath(genpath('kspTOT_SingleUIs'));
        addpath(genpath('images'));
        addpath(genpath('kos_scripts'));
        
        cd(origDir);
    end

    % Load the LVD case
    if ~exist(lvdCasePath, 'file')
        error('LVD case file not found: %s', lvdCasePath);
    end
    data = load(lvdCasePath);
    lvdData = data.lvdData;

    % Adjust integrator tolerances for profiling consistency
    for i = 1:length(lvdData.script.evts)
        evt = lvdData.script.getEventForInd(i);
        if ~isempty(evt.integratorObj)
            evt.integratorObj.options.AbsTol = 1E-6;
            evt.integratorObj.options.RelTol = 1E-6;
        end
    end

    % Warm up run
    fprintf('Starting warm-up run for %s...\n', lvdCasePath);
    lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), true, false, false, false);

    % Main execution tracking
    numRuns = 15;
    runTimes = zeros(numRuns, 1);
    
    if runProfile
        profile off; profile on;
    end
    
    for i = 1:numRuns
        fprintf('Run %d/%d...\n', i, numRuns);
        tRun = tic;
        lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), true, false, false, false);
        runTimes(i) = toc(tRun);
    end
    
    totalExecutionTime = sum(runTimes);
    avgExecutionTime = mean(runTimes);
    stdExecutionTime = std(runTimes);
    
    results = struct();
    results.casePath = lvdCasePath;
    results.runTimes = runTimes;
    results.avgExecutionTime = avgExecutionTime;
    results.stdExecutionTime = stdExecutionTime;
    results.timestamp = datetime('now');
    
    if runProfile
        p = profile('info');
        profile off;
        
        % Extract bottleneck functions
        ft = p.FunctionTable;
        [~, idx] = sort([ft.TotalTime], 'descend');
        sortedFT = ft(idx);
        
        % Filter for project-specific functions
        bottlenecks = struct('FunctionName', {}, 'TotalTime', {}, 'NumCalls', {}, 'AvgTime', {});
        count = 0;
        for i = 1:length(sortedFT)
            f = sortedFT(i);
            if contains(f.FileName, 'ksptot') || contains(f.FileName, 'lvd') || contains(f.FileName, 'helper_methods')
                count = count + 1;
                bottlenecks(count).FunctionName = f.FunctionName;
                bottlenecks(count).TotalTime = f.TotalTime;
                bottlenecks(count).NumCalls = f.NumCalls;
                bottlenecks(count).AvgTime = f.TotalTime / f.NumCalls;
            end
            if count >= 30
                break;
            end
        end
        results.bottlenecks = bottlenecks;
    end
    
    % Save results
    save(outputPath, 'results');
    fprintf('Results saved to %s\n', outputPath);
end
