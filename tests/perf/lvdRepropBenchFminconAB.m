function results = lvdRepropBenchFminconAB()
%LVDREPROPBENCHFMINCONAB Real fmincon A/B benchmark for incremental re-propagation.
%
%   Runs the SAME capped fmincon optimization twice on freshly loaded
%   mission data -- once with incremental re-propagation disabled
%   (classic behavior) and once enabled -- and reports wall time.
%
%   The objective and constraint wrappers are exactly the ones the LVD
%   optimizers hand to fmincon (CompositeObjectiveFcn.evalObjFcn /
%   ConstraintSet.evalConstraints), so this exercises the production
%   evaluation path including finite-difference gradient sampling.
%
%   Uses L1HaloOrbit because its optimization variables live exclusively
%   on events 3-4 of a 4-event script, so classic mode re-integrates the
%   entire halo insertion arcs on every evaluation while incremental mode
%   re-integrates only the affected tail (or nothing at all for repeated
%   evaluations of the same point).

    ksptotAddProjectPaths();

    root = ksptotTestRoot();
    files = dir(fullfile(root, 'examples', 'LaunchVehicleDesigner', '**', 'lvdExample_L1HaloOrbit.mat'));
    thisFile = fullfile(files(1).folder, files(1).name);

    maxIter = 12;

    %OFF pass
    [tOff, exitOff, fOff] = runCappedFmincon(thisFile, false, maxIter);

    %ON pass
    [tOn, exitOn, fOn] = runCappedFmincon(thisFile, true, maxIter);

    fprintf('\n===== FMINCON A/B RESULTS (maxIter=%d) =====\n', maxIter);
    fprintf('OFF: %.2f s | exitflag=%d | f(x)=%.8g\n', tOff, exitOff, fOff);
    fprintf('ON : %.2f s | exitflag=%d | f(x)=%.8g\n', tOn, exitOn, fOn);
    fprintf('Speedup: %.2fx | objective agreement: %.3g (rel)\n', ...
        tOff / max(tOn, eps), abs(fOff - fOn) / max(1, abs(fOff)));

    results.timeOff = tOff;
    results.timeOn = tOn;
    results.exitOff = exitOff;
    results.exitOn = exitOn;
    results.fOff = fOff;
    results.fOn = fOn;
end

function [elapsed, exitflag, fval] = runCappedFmincon(thisFile, enableIncremental, maxIter)
    loaded = load(thisFile, 'lvdData');
    lvdData = loaded.lvdData;
    lvdData.stateLog.clearStateLog();
    lvdData.settings.enableIncrementalRepropagation = enableIncremental;

    lvdOpt = lvdData.optimizer;

    x0 = lvdOpt.vars.getTotalScaledXVector();
    [lbAll, ubAll] = lvdOpt.vars.getTotalScaledBndsVector();

    evtFloor = lvdData.script.getEventForInd(lvdData.script.getTotalNumOfEvents());
    objFun = @(x) lvdOpt.objFcn.evalObjFcn(x, evtFloor);
    nonlcon = @(x) lvdOpt.constraints.evalConstraints(x, true, evtFloor, false, []);

    opts = optimoptions('fmincon', ...
        'Algorithm', 'interior-point', ...
        'Display', 'off', ...
        'MaxIterations', maxIter, ...
        'MaxFunctionEvaluations', 10000, ...
        'FiniteDifferenceType', 'forward');

    tic;
    [xSol, fval, exitflag] = fmincon(objFun, x0, [], [], [], [], lbAll, ubAll, nonlcon, opts); %#ok<NASGU>
    elapsed = toc;

    if(isempty(fval))
        fval = NaN;
    end
end
