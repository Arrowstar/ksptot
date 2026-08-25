%RUNCENSUSTOFILE Runs lvdRepropCensus with diary logging so results survive
% client timeouts. Output lands in tests/perf/censusOutput.txt.
logFile = fullfile(ksptotTestRoot(), 'tests', 'perf', 'censusOutput.txt');

if(exist(logFile, 'file'))
    delete(logFile);
end

diary(logFile);
cleanupObj = onCleanup(@() diary('off'));

fprintf('Census started %s\n\n', datestr(now));
census = lvdRepropCensus();
save(fullfile(ksptotTestRoot(), 'tests', 'perf', 'censusResults.mat'), 'census');
fprintf('\nCensus finished %s\n', datestr(now));
