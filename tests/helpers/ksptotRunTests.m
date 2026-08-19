function results = ksptotRunTests(selector, verbosity)
% ksptotRunTests Runs KSPTOT test classes and prints a compact summary.
%
% INPUTS
%   selector  - class name, folder name, or 'all' (default 'all')
%   verbosity - 0 for summary only, 1 to also print each failure's
%               diagnostic message (default 1)
%
% Output is deliberately terse: full matlab.unittest diagnostics are far
% too verbose to read when a suite has hundreds of parameterized cases.

    if(nargin < 1 || isempty(selector))
        selector = 'all';
    end

    if(nargin < 2 || isempty(verbosity))
        verbosity = 1;
    end

    ksptotAddProjectPaths();

    import matlab.unittest.TestSuite

    testsRoot = fullfile(ksptotTestRoot(), 'tests');

    if(strcmpi(selector, 'all'))
        suite = TestSuite.fromFolder(testsRoot, 'IncludingSubfolders', true);
    elseif(isfolder(fullfile(testsRoot, selector)))
        suite = TestSuite.fromFolder(fullfile(testsRoot, selector), 'IncludingSubfolders', true);
    else
        suite = TestSuite.fromClass(meta.class.fromName(selector));
    end

    runner = matlab.unittest.TestRunner.withNoPlugins();
    runner.addPlugin(matlab.unittest.plugins.DiagnosticsRecordingPlugin( ...
        'IncludingPassingDiagnostics', false));

    results = runner.run(suite);

    printSummary(results, verbosity);
end

function printSummary(results, verbosity)

    numPassed   = nnz([results.Passed]);
    numFailed   = nnz([results.Failed]);
    numIncomplete = nnz([results.Incomplete]);

    fprintf('\n===== KSPTOT TEST SUMMARY =====\n');
    fprintf('passed: %d   failed: %d   incomplete/skipped: %d   total: %d\n', ...
            numPassed, numFailed, numIncomplete, numel(results));
    fprintf('elapsed: %.1f s\n', sum([results.Duration]));

    if(numFailed == 0)
        fprintf('\nAll tests passed.\n');
        return;
    end

    fprintf('\n----- FAILURES -----\n');

    failedResults = results([results.Failed]);

    for(i = 1:numel(failedResults)) %#ok<*NO4LP>
        fprintf('\n[%d] %s\n', i, failedResults(i).Name);

        if(verbosity > 0)
            fprintf('%s\n', firstDiagnosticLine(failedResults(i)));
        end
    end
end

function txt = firstDiagnosticLine(result)
%firstDiagnosticLine Extracts a short readable reason from a test result.

    txt = '    (no diagnostic captured)';

    try
        record = result.Details.DiagnosticRecord;

        if(isempty(record))
            return;
        end

        raw = '';
        for(k = 1:numel(record))
            if(~isempty(record(k).Report))
                raw = record(k).Report;
                break;
            end
        end

        if(isempty(raw))
            return;
        end

        lines = strsplit(raw, newline);

        keep = {};
        for(k = 1:numel(lines))
            thisLine = strtrim(lines{k});

            isNoise = isempty(thisLine) || ...
                      startsWith(thisLine, 'Framework Diagnostic') || ...
                      startsWith(thisLine, '---') || ...
                      startsWith(thisLine, '===');

            if(~isNoise)
                keep{end+1} = ['    ' thisLine]; %#ok<AGROW>
            end

            if(numel(keep) >= 6)
                break;
            end
        end

        if(~isempty(keep))
            txt = strjoin(keep, newline);
        end
    catch
        % Fall through to the default message.
    end
end
