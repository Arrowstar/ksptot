function run_all_tests()
    % run_all_tests()
    % Master test runner for KSPTOT.
    % Discovers and executes all tests in the tests/ directory recursively.

    % Get the folder where this script resides
    testDir = fileparts(mfilename('fullpath'));
    
    % Define the subdirectories
    astroTestsDir = fullfile(testDir, 'astro_tests');
    lvdTestsDir = fullfile(testDir, 'lvd_tests');
    
    % Run all tests found in these directories
    fprintf('========================================================\n');
    fprintf('Starting KSPTOT Unified Test Suite\n');
    fprintf('Location: %s\n', testDir);
    fprintf('========================================================\n\n');
    
    try
        % Create suite from folders
        suite = matlab.unittest.TestSuite.fromFolder(testDir, 'IncludingSubfolders', true);
        
        % Filter out any "run_*" scripts that might be picked up accidentally 
        % (though usually only classes/functions starting with 'test' are picked up)
        % No specific filter needed unless we have non-test files starting with 'test'
        
        % Run the suite
        results = run(suite);
        
        % Format and display results
        rt = table(results);
        fprintf('\nTest Results Summary:\n');
        disp(rt(:, {'Name', 'Passed', 'Failed', 'Incomplete', 'Duration'}));
        
        totalTests = length(results);
        passed = sum([results.Passed]);
        failed = sum([results.Failed]);
        incomplete = sum([results.Incomplete]);
        
        fprintf('\nTotals:\n');
        fprintf('  Passed:     %d\n', passed);
        fprintf('  Failed:     %d\n', failed);
        fprintf('  Incomplete: %d\n', incomplete);
        fprintf('  Overall:    %d\n', totalTests);
        fprintf('  Duration:   %.2f seconds\n', sum([results.Duration]));
        
        if failed > 0
            fprintf('\n*** WARNING: %d tests failed! ***\n', failed);
        else
            fprintf('\nAll tests passed successfully.\n');
        end
        
    catch ME
        fprintf('\nError during test execution:\n %s\n', ME.message);
        rethrow(ME);
    end
end
