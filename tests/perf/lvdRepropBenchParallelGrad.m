function results = lvdRepropBenchParallelGrad()
%LVDREPROPBENCHPARALLELGRAD Verifies incremental re-propagation under parallel gradients.
%
%   Computes objective gradients for L1HaloOrbit three ways and checks
%   agreement:
%
%     1. Serial custom finite differences (single process)
%     2. Parallel custom finite differences, cold-ish workers
%        (first parallel pass after the client established the baseline;
%         each worker inherits the serialized mission state and evaluates
%         its share of FD perturbations)
%     3. Parallel custom finite differences, warm workers
%        (identical second pass: every worker has already seen these exact
%         perturbations, so incremental caching should skip or heavily
%         trim re-integration)
%
%   Correctness criterion: all three gradients agree within a tight
%   relative tolerance.  Bitwise equality across different integration
%   histories is not expected (force-model caches introduce ~1e-15
%   relative path dependence); FD noise dominates anyway.
%
%   Timing is reported as evidence that per-worker caching functions
%   under parfor scheduling (round 3 should beat round 2 on wall time).

    ksptotAddProjectPaths();

    root = ksptotTestRoot();
    files = dir(fullfile(root, 'examples', 'LaunchVehicleDesigner', '**', 'lvdExample_L1HaloOrbit.mat'));
    thisFile = fullfile(files(1).folder, files(1).name);

    numWorkers = 2;

    %Build the production objective wrapper exactly like FminconOptimizer.
    loaded = load(thisFile, 'lvdData');
    lvdData = loaded.lvdData;
    lvdData.stateLog.clearStateLog();
    lvdData.settings.enableIncrementalRepropagation = true;

    lvdOpt = lvdData.optimizer;
    evtFloor = lvdData.script.getEventForInd(lvdData.script.getTotalNumOfEvents());
    objFun = @(x) lvdOpt.objFcn.evalObjFcn(x, evtFloor);

    x0 = lvdOpt.vars.getTotalScaledXVector();
    f0 = objFun(x0);

    fprintf('f(x0) = %.10g | numVars = %d\n', f0, numel(x0));

    fd = CustomFiniteDiffsCalculationMethod();

    %Pass 1: serial gradient (no pool involvement).
    tic;
    gSerial = fd.computeGrad(objFun, x0, f0, false);
    tSerial = toc;

    %Spin up pool.
    pool = gcp('nocreate');
    if(isempty(pool))
        pool = parpool('Processes', numWorkers);
    end
    fprintf('Pool: %d workers\n', pool.NumWorkers);

    %Pass 2: parallel gradient, workers inherit client baseline.
    tic;
    gParCold = fd.computeGrad(objFun, x0, f0, true);
    tParCold = toc;

    %Pass 3: identical parallel request -- workers now hold warm caches
    %for exactly these perturbations.
    tic;
    gParWarm = fd.computeGrad(objFun, x0, f0, true);
    tParWarm = toc;

    relCold = maxAbsRelDiff(gSerial, gParCold);
    relWarm = maxAbsRelDiff(gSerial, gParWarm);
    relCW = maxAbsRelDiff(gParCold, gParWarm);

    fprintf('\n===== PARALLEL GRADIENT RESULTS =====\n');
    fprintf('serial grad : %.1f s\n', tSerial);
    fprintf('par grad #1 : %.1f s (cold workers) | max rel diff vs serial: %.3g\n', tParCold, relCold);
    fprintf('par grad #2 : %.1f s (warm workers) | max rel diff vs serial: %.3g | vs par#1: %.3g\n', ...
        tParWarm, relWarm, relCW);
    fprintf('warm-vs-cold parallel ratio: %.2fx\n', tParCold / max(tParWarm, eps));

    tol = 1E-6;
    results.passed = (relCold < tol) && (relWarm < tol) && (relCW < tol);
    results.maxRelDiffSerialVsParallelCold = relCold;
    results.maxRelDiffSerialVsParallelWarm = relWarm;
    results.tSerial = tSerial;
    results.tParCold = tParCold;
    results.tParWarm = tParWarm;

    if(results.passed)
        fprintf('PASS: parallel gradients agree with serial within %.0e.\n', tol);
    else
        fprintf('FAIL: gradient disagreement exceeds %.0e.\n', tol);
    end
end

function r = maxAbsRelDiff(a, b)
    r = max(abs(a - b) ./ max(1, abs(a)));
end

