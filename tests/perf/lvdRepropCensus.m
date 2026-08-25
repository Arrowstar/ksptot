function census = lvdRepropCensus()
%LVDREPROPCENSUS Surveys all LVD example cases for incremental re-propagation work.
%
%   census = lvdRepropCensus() loads every lvdData example under
%   examples/LaunchVehicleDesigner (recursively), runs one full script
%   propagation per case, and reports the properties that determine
%   whether/how much that case can benefit from incremental re-propagation
%   caching during optimization:
%
%       - number of events and non-sequential events
%       - number of active optimization variables and scalar x elements
%       - the events that host variables (0 = vehicle/initial-state/plugin)
%       - static resume floor (what getEvtNumToStartScriptExecAt computes)
%       - presence of SetNextEventAction (script looping) or plugins,
%         either of which forces a full re-propagation every eval
%       - wall time of a full propagation and state log entry count
%
%   Cases with a static floor > 1 and no loop/plugin guard are the ones
%   expected to benefit; cases with floor == 1 serve as controls.

    ksptotAddProjectPaths();

    root = ksptotTestRoot();
    exampleFiles = dir(fullfile(root, 'examples', 'LaunchVehicleDesigner', '**', '*.mat'));

    numCases = numel(exampleFiles);
    census = struct([]);

    fprintf('%-52s %4s %4s %5s %5s %8s %-14s %3s %3s %9s %7s\n', ...
        'Example', 'Evts', 'NSq', 'Vars', 'Xels', 'VarEvts', 'Floor/Guard', 'SNE', 'Plg', 'PropTime', 'Entries');
    fprintf('%s\n', repmat('-', 1, 130));

    for(k = 1:numCases)
        thisFile = fullfile(exampleFiles(k).folder, exampleFiles(k).name);
        [~, baseName] = fileparts(exampleFiles(k).name);

        try
            lvdData = loadLvdExampleForCensus(thisFile);

            numEvts = lvdData.script.getTotalNumOfEvents();
            numNonSeq = length(lvdData.script.nonSeqEvts.evts);

            [x, actVars] = lvdData.optimizer.vars.getTotalScaledXVector();

            varEvtNums = zeros(1, numel(actVars));
            for(j = 1:numel(actVars))
                evtNum = getEventNumberForVar(actVars(j), lvdData);
                if(isempty(evtNum))
                    evtNum = 0;
                end
                varEvtNums(j) = evtNum;
            end

            staticFloor = computeStaticResumeFloor(lvdData, actVars);
            hasLoopAction = scriptContainsSetNextEventAction(lvdData);
            hasPlugins = lvdData.plugins.getNumPlugins() > 0;

            [propTime, numEntries] = timeFullPropagation(lvdData);

            census(k).name = baseName;
            census(k).file = thisFile;
            census(k).numEvents = numEvts;
            census(k).numNonSeqEvts = numNonSeq;
            census(k).numActiveVars = numel(actVars);
            census(k).numXElements = numel(x);
            census(k).varEvtNums = unique(varEvtNums);
            census(k).staticFloorEvtNum = staticFloor;
            census(k).hasSetNextEventAction = hasLoopAction;
            census(k).hasPlugins = hasPlugins;
            census(k).fullPropTime = propTime;
            census(k).numStateLogEntries = numEntries;
            census(k).loadError = '';

            fprintf('%-52s %4d %4d %5d %5d %8s %-14s %3d %3d %9.3f %7d\n', ...
                baseName, numEvts, numNonSeq, numel(actVars), numel(x), ...
                mat2str(census(k).varEvtNums), ...
                sprintf('%d%s%s', staticFloor, ternary(hasLoopAction, '+L', ''), ternary(hasPlugins, '+P', '')), ...
                hasLoopAction, hasPlugins, propTime, numEntries);
        catch loadME
            census(k).name = baseName;
            census(k).file = thisFile;
            census(k).loadError = loadME.message;

            fprintf('%-52s ERROR: %s\n', baseName, strtrim(loadME.message));
        end
    end
end

function lvdData = loadLvdExampleForCensus(thisFile)
    loaded = load(thisFile, 'lvdData');

    if(isfield(loaded, 'lvdData'))
        lvdData = loaded.lvdData;
    else
        error('File does not contain an lvdData variable.');
    end

    if(~isa(lvdData, 'LvdData'))
        error('lvdData variable is not an LvdData object.');
    end

    %Remove stale cached results so timing reflects propagation only.
    lvdData.stateLog.clearStateLog();
end

function evtNumToStartScriptExecAt = computeStaticResumeFloor(lvdData, actVars)
    %Mirrors LvdOptimization.getEvtNumToStartScriptExecAt (private there).
    evtNumToStartScriptExecAt = lvdData.script.getTotalNumOfEvents();

    for(i = 1:length(actVars))
        var = actVars(i);

        if(isVarInLaunchVehicle(var, lvdData))
            varEvtNum = 1;
        else
            varEvtNum = getEventNumberForVar(var, lvdData);

            if(isempty(varEvtNum))
                varEvtNum = 1;
            end
        end

        if(varEvtNum < evtNumToStartScriptExecAt)
            evtNumToStartScriptExecAt = varEvtNum;
        end

        if(evtNumToStartScriptExecAt == 1)
            break;
        end
    end
end

function [propTime, numEntries] = timeFullPropagation(lvdData)
    numRepeats = 3;

    times = zeros(1, numRepeats);
    numEntries = 0;

    for(i = 1:numRepeats)
        tic;
        stateLog = lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false); %#ok<NASGU>
        times(i) = toc;

        numEntries = stateLog.getNumberOfEntries();
    end

    propTime = median(times);
end

function out = ternary(tf, valTrue, valFalse)
    if(tf)
        out = valTrue;
    else
        out = valFalse;
    end
end
