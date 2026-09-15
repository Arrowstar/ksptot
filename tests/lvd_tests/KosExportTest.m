classdef KosExportTest < KsptotTestCase
    %KosExportTest lvd_writeKosExecScript, the helper behind the kOS export.
    %
    % The "Create kOS Control CSV File" menu used to write only the CSV and
    % leave the user to hand-edit the fPath variable in exec_lvd_control.ks.
    % The helper now writes a copy of the script (fPath pre-set) plus the
    % KSLib libraries next to the CSV.  Oracle: the written script must be
    % the repository template with exactly the fPath line changed.

    methods(Test)
        function writesScriptWithFPathAndLibsNextToCsv(testCase)
            outDir = testCase.makeTempDir();
            csvPath = fullfile(outDir, 'my launch profile.csv');
            testCase.writeDummyFile(csvPath);

            [ksFilePath, msg] = lvd_writeKosExecScript(csvPath);

            testCase.verifyEqual(ksFilePath, fullfile(outDir, 'exec_lvd_control.ks'), ...
                'The script must be written next to the CSV under its canonical name.');
            testCase.assertTrue(isfile(ksFilePath), 'The kOS script file was not written.');
            testCase.verifySubstring(msg, 'my launch profile.csv', 'The status message must name the CSV.');

            written = fileread(ksFilePath);
            fPathLines = regexp(written, '^\s*set\s+fPath\s+to\s+"([^"]*)"\.', 'tokens', 'lineanchors');
            testCase.assertEqual(numel(fPathLines), 1, 'Exactly one fPath assignment must be present.');
            testCase.verifyEqual(fPathLines{1}{1}, 'my launch profile.csv', ...
                'fPath must be set to the CSV file name (no directory).');
            testCase.verifyFalse(contains(written, 'bigLauncher1.csv'), ...
                'The template placeholder file name must be gone.');

            %Everything except the fPath line must match the template.
            template = fileread(fullfile(ksptotTestRoot(), 'kos_scripts', 'exec_lvd_control.ks'));
            expected = regexprep(template, '^(\s*set\s+fPath\s+to\s+")[^"\r\n]*(")', '$1my launch profile.csv$2', 'once', 'lineanchors');
            testCase.verifyEqual(written, expected, ...
                'Only the fPath line may differ from the shipped template.');

            for lib = {'lib_navball.ks', 'lib_num_to_formatted_str.ks'}
                testCase.verifyTrue(isfile(fullfile(outDir, lib{1})), sprintf( ...
                    'KSLib dependency %s must be copied next to the script.', lib{1}));
                testCase.verifyEqual(fileread(fullfile(outDir, lib{1})), ...
                                     fileread(fullfile(ksptotTestRoot(), 'kos_scripts', lib{1})), sprintf( ...
                    '%s must be a verbatim copy.', lib{1}));
            end

            %The CSV itself is left alone.
            testCase.verifyEqual(fileread(csvPath), 'dummy', 'The CSV must not be touched.');
        end

        function acceptsExplicitTemplateDirectory(testCase)
            outDir = testCase.makeTempDir();
            tmplDir = testCase.makeTempDir();

            testCase.writeTextFile(fullfile(tmplDir, 'exec_lvd_control.ks'), sprintf('// header\n\tset fPath to "old.csv". // c\nprint fPath.\n'));
            testCase.writeTextFile(fullfile(tmplDir, 'lib_navball.ks'), 'nav');
            %lib_num_to_formatted_str.ks deliberately missing

            csvPath = fullfile(outDir, 'ctrl.csv');
            testCase.writeDummyFile(csvPath);

            [ksFilePath, msg] = lvd_writeKosExecScript(csvPath, tmplDir);

            testCase.assertTrue(isfile(ksFilePath));
            testCase.verifyEqual(fileread(ksFilePath), sprintf('// header\n\tset fPath to "ctrl.csv". // c\nprint fPath.\n'), ...
                'Only the quoted file name may change; comments and surrounding lines must survive.');
            testCase.verifyTrue(isfile(fullfile(outDir, 'lib_navball.ks')));
            testCase.verifyFalse(isfile(fullfile(outDir, 'lib_num_to_formatted_str.ks')));
            testCase.verifySubstring(msg, 'lib_num_to_formatted_str.ks', ...
                'A missing library must be reported, not silently skipped.');
        end

        function fallsBackGracefullyWhenTemplateMissing(testCase)
            outDir = testCase.makeTempDir();
            emptyDir = testCase.makeTempDir();
            csvPath = fullfile(outDir, 'ctrl.csv');
            testCase.writeDummyFile(csvPath);

            [ksFilePath, msg] = lvd_writeKosExecScript(csvPath, emptyDir);

            testCase.verifyEmpty(ksFilePath, 'No script path may be returned when nothing was written.');
            testCase.verifySubstring(msg, 'could not be found');
            testCase.verifySubstring(msg, 'ctrl.csv', 'The fallback instructions must tell the user the CSV name to set.');

            listing = dir(outDir);
            names = {listing(~[listing.isdir]).name};
            testCase.verifyEqual(names, {'ctrl.csv'}, 'Nothing but the CSV may exist in the output folder.');
        end

        function refusesAmbiguousTemplate(testCase)
            outDir = testCase.makeTempDir();
            tmplDir = testCase.makeTempDir();
            testCase.writeTextFile(fullfile(tmplDir, 'exec_lvd_control.ks'), sprintf('set fPath to "a.csv".\nset fPath to "b.csv".\n'));

            csvPath = fullfile(outDir, 'ctrl.csv');
            testCase.writeDummyFile(csvPath);

            [ksFilePath, msg] = lvd_writeKosExecScript(csvPath, tmplDir);

            testCase.verifyEmpty(ksFilePath, 'A template with two fPath lines must not be rewritten blindly.');
            testCase.verifySubstring(msg, 'exactly one');
            testCase.verifyFalse(isfile(fullfile(outDir, 'exec_lvd_control.ks')));
        end
    end

    methods(Access=private)
        function d = makeTempDir(testCase)
            d = tempname();
            mkdir(d);
            testCase.addTeardown(@() rmdir(d, 's'));
        end
    end

    methods(Static, Access=private)
        function writeDummyFile(path)
            KosExportTest.writeTextFile(path, 'dummy');
        end

        function writeTextFile(path, text)
            fid = fopen(path, 'w');
            fprintf(fid, '%s', text);
            fclose(fid);
        end
    end
end
