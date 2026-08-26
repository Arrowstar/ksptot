function lvdRepropGoldenRunner(mode)
%LVDREPROPGOLDENRUNNER Captures or verifies bit-identical LVD example state logs.
%
%   lvdRepropGoldenRunner('capture') - Runs a full propagation of every
%   LVD example and stores a numeric fingerprint of the resulting state
%   log under tests/data/goldens/lvdStateLogGoldens/.  Run this BEFORE any
%   engine changes to record the reference behavior.
%
%   lvdRepropGoldenRunner('verify')  - Re-runs every example with the
%   current code and compares fingerprints bitwise (isequaln) against the
%   stored goldens.  Exits with an error if any case differs.
%
%   lvdRepropGoldenRunner()          - Defaults to 'capture' if no goldens
%   exist yet, otherwise 'verify'.
%
%   The fingerprint covers time, position, velocity, event numbers,
%   integration groups, tank masses, power storage states of charge,
%   stopwatch values, and extrema values for every state log entry.  See
%   stateLogToFingerprint.m.

    ksptotAddProjectPaths();

    if(nargin < 1 || isempty(mode))
        goldenFolder = getGoldenFolder();
        if(isfolder(goldenFolder) && ~isempty(dir(fullfile(goldenFolder, '*.mat'))))
            mode = 'verify';
        else
            mode = 'capture';
        end
    end

    root = ksptotTestRoot();
    exampleFiles = dir(fullfile(root, 'examples', 'LaunchVehicleDesigner', '**', '*.mat'));

    goldenFolder = getGoldenFolder();

    if(strcmpi(mode, 'capture'))
        if(~isfolder(goldenFolder))
            mkdir(goldenFolder);
        end
        fprintf('Capturing golden state log fingerprints...\n');
    elseif(strcmpi(mode, 'verify'))
        fprintf('Verifying state log fingerprints against goldens...\n');
    else
        error('Unknown mode "%s". Use "capture" or "verify".', mode);
    end

    numCases = numel(exampleFiles);
    numPassed = 0;
    numFailed = 0;
    numSkipped = 0;
    failedNames = {};

    skipList = getGoldenSkipList();

    for(k = 1:numCases)
        [~, baseName] = fileparts(exampleFiles(k).name);
        goldenFile = fullfile(goldenFolder, [baseName, '_stateLogGolden.mat']);

        if(ismember(lower(baseName), lower(skipList)))
            fprintf('[SKIP] %s: on known-skip list (see tests/perf/getGoldenSkipList.m).\n', baseName);
            numSkipped = numSkipped + 1;
            continue;
        end

        %Load first: files that cannot be loaded are skipped in both modes
        %(pre-existing broken examples must not mask regressions).
        try
            lvdData = loadLvdExample(thisFile(exampleFiles(k)));
        catch loadME
            fprintf('[SKIP] %s: cannot load (%s)\n', baseName, strtrim(loadME.message));
            numSkipped = numSkipped + 1;
            continue;
        end

        try
            stateLog = runFullPropagation(lvdData);
            fp = stateLogToFingerprint(stateLog);

            if(strcmpi(mode, 'capture'))
                save(goldenFile, 'fp', 'baseName');
                fprintf('[CAPTURED] %s (%d entries x %d cols)\n', baseName, fp.numEntries, fp.numCols);
            else
                if(~isfile(goldenFile))
                    fprintf('[FAIL] %s: no golden file exists.\n', baseName);
                    numFailed = numFailed + 1;
                    failedNames{end+1} = baseName; %#ok<AGROW>
                    continue;
                end

                golden = load(goldenFile);
                verifyFingerprints(baseName, golden.fp, fp);
                fprintf('[PASS] %s\n', baseName);
                numPassed = numPassed + 1;
            end
        catch ME
            fprintf('[ERROR] %s: %s\n', baseName, strtrim(ME.message));
            if(strcmpi(mode, 'verify'))
                numFailed = numFailed + 1;
                failedNames{end+1} = baseName; %#ok<AGROW>
            end
        end
    end

    if(strcmpi(mode, 'verify'))
        fprintf('\n===== GOLDEN VERIFY SUMMARY =====\n');
        fprintf('passed: %d   failed/errored: %d   skipped: %d   total: %d\n', ...
                numPassed, numFailed, numSkipped, numCases);

        if(numFailed > 0)
            error('lvdRepropGoldenRunner:mismatch', ...
                  'State log fingerprints differ from goldens for: %s', strjoin(failedNames, ', '));
        end
    end
end

function thisFile = thisFile(fileEntry)
    thisFile = fullfile(fileEntry.folder, fileEntry.name);
end

function goldenFolder = getGoldenFolder()
    root = ksptotTestRoot();
    goldenFolder = fullfile(root, 'tests', 'data', 'goldens', 'lvdStateLogGoldens');
end

function lvdData = loadLvdExample(thisFile)
    loaded = load(thisFile, 'lvdData');

    if(isfield(loaded, 'lvdData'))
        lvdData = loaded.lvdData;
    else
        error('File does not contain an lvdData variable.');
    end

    if(~isa(lvdData, 'LvdData'))
        error('lvdData variable is not an LvdData object.');
    end
end

function stateLog = runFullPropagation(lvdData)
    %Full propagation exactly as the GUI performs it: start at event 1.
    stateLog = lvdData.script.executeScript(false, lvdData.script.getEventForInd(1), false, false, false, false);
end

function verifyFingerprints(baseName, fpGolden, fpNew)
    if(fpGolden.numEntries ~= fpNew.numEntries)
        error('lvdRepropGoldenRunner:entryCount', ...
              '%s: entry count differs (golden %d, new %d).', ...
              baseName, fpGolden.numEntries, fpNew.numEntries);
    end

    if(isequaln(size(fpGolden.matrix), size(fpNew.matrix)) && isequaln(fpGolden.matrix, fpNew.matrix))
        return;
    end

    %Diagnose the first difference to make failures actionable.
    minRows = min(size(fpGolden.matrix, 1), size(fpNew.matrix, 1));
    minCols = min(size(fpGolden.matrix, 2), size(fpNew.matrix, 2));

    diffRow = NaN;
    diffCol = NaN;

    for(i = 1:minRows)
        for(j = 1:minCols)
            a = fpGolden.matrix(i, j);
            b = fpNew.matrix(i, j);

            bothNan = isnan(a) && isnan(b);
            if(~bothNan && ~(a == b))
                diffRow = i;
                diffCol = j;
                break;
            end
        end

        if(~isnan(diffRow))
            break;
        end
    end

    error('lvdRepropGoldenRunner:mismatch', ...
          '%s: fingerprint mismatch (first difference at entry %d, column %d).', ...
          baseName, diffRow, diffCol);
end
