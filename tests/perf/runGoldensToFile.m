%RUNCENSUSTOFILE Runs lvdRepropCensus with diary logging so results survive
% client timeouts. Output lands in tests/perf/censusOutput.txt.
logFile = fullfile(ksptotTestRoot(), 'tests', 'perf', 'censusOutput.txt');

if(exist(logFile, 'file'))
    delete(logFile);
end

diary(logFile);
cleanupObj = onCleanup(@() diary('off')); %#ok<NASGU>

fprintf('Golden capture started %s\n\n', datestr(now));
lvdRepropGoldenRunner('capture');
fprintf('\nGolden capture finished %s\n', datestr(now));
