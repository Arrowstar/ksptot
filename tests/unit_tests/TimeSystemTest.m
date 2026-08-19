classdef TimeSystemTest < KsptotTestCase
    %TimeSystemTest Unit tests for the KSPTOT custom time/calendar system.
    %
    % Covers the KSPTOT_TimeSystem class, the INI parsing/loading helpers
    % (parseTimeSystemFromINIRows, getTimeSystemFromConfig,
    % getCustomTimeSystem), the getSecondsInVariousTimeUnits() global
    % integration, and the [Time] section skip in processINIBodyInfo().

    properties
        oldTimeSystemGlobal
        oldUseEarthTimeGlobal
    end

    methods (TestMethodSetup)
        function clearTimeSystemGlobals(testCase)
            %Clear the time system globals so stock-behavior tests are
            %hermetic, saving the prior values for teardown.
            global ksptot_TimeSystem options_UseEarthTimeSystem; %#ok<GVMIS>

            testCase.oldTimeSystemGlobal = ksptot_TimeSystem;
            testCase.oldUseEarthTimeGlobal = options_UseEarthTimeSystem;

            ksptot_TimeSystem = [];
            options_UseEarthTimeSystem = [];
        end
    end

    methods (TestMethodTeardown)
        function restoreTimeSystemGlobals(testCase)
            %Restore the time system globals to their prior values.
            global ksptot_TimeSystem options_UseEarthTimeSystem; %#ok<GVMIS>

            ksptot_TimeSystem = testCase.oldTimeSystemGlobal;
            options_UseEarthTimeSystem = testCase.oldUseEarthTimeGlobal;
        end
    end

    methods (Test)
        function testKerbinStockConstants(testCase)
            ts = KSPTOT_TimeSystem.kerbinStock();

            testCase.verifyEqual(ts.system, 'kerbin_stock');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
            testCase.verifyEqual(ts.secondsPerYear, 9201600);
            testCase.verifyEqual(ts.secondsPerHour, 3600);
            testCase.verifyEqual(ts.hoursPerDay, 6);
            testCase.verifyEqual(ts.daysPerYear, 426);
            testCase.verifyEqual(ts.getDescription(), '1 year = 426 days, 1 day = 6 hours');
        end

        function testEarthStockConstants(testCase)
            ts = KSPTOT_TimeSystem.earthStock();

            testCase.verifyEqual(ts.system, 'earth_stock');
            testCase.verifyEqual(ts.secondsPerDay, 86400);
            testCase.verifyEqual(ts.secondsPerYear, 31536000);
            testCase.verifyEqual(ts.secondsPerHour, 3600);
            testCase.verifyEqual(ts.hoursPerDay, 24);
            testCase.verifyEqual(ts.daysPerYear, 365);
            testCase.verifyEqual(ts.getDescription(), '1 year = 365 days, 1 day = 24 hours');
        end

        function testCustomSystemConstants(testCase)
            %JNSQ Rescale 3.2x values from ksptot issue #45.
            ts = KSPTOT_TimeSystem.custom(43200, 16459200);

            testCase.verifyEqual(ts.system, 'custom');
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 16459200);
            testCase.verifyEqual(ts.secondsPerHour, 3600);

            %hoursPerDay is derived from secondsPerDay when not given.
            testCase.verifyEqual(ts.hoursPerDay, 12);
            testCase.verifyEqual(ts.daysPerYear, 16459200/43200);
        end

        function testCustomSystemWithDisplayMetadata(testCase)
            ts = KSPTOT_TimeSystem.custom(43200, 16459200, 'hoursPerDay', 12, 'minutesPerHour', 60, 'secondsPerMinute', 60);

            testCase.verifyEqual(ts.hoursPerDay, 12);
            testCase.verifyEqual(ts.minutesPerHour, 60);
            testCase.verifyEqual(ts.secondsPerMinute, 60);
            testCase.verifyEqual(ts.secondsPerHour, 3600);
        end

        function testKerbinRoundTripConversion(testCase)
            %Year 1, Day 1, 00:00:00 is UT = 0.
            [y, d, h, m, s] = convertSec2YearDayHrMnSec(0);
            testCase.verifyEqual([y d h m s], [1 1 0 0 0]);
            testCase.verifyEqual(convertYearDayHrMnSec2Sec(1, 1, 0, 0, 0), 0);

            %One full Kerbin year: Year 2, Day 1, 00:00:00.
            [y, d, h, m, s] = convertSec2YearDayHrMnSec(9201600);
            testCase.verifyEqual([y d h m s], [2 1 0 0 0]);
            testCase.verifyEqual(convertYearDayHrMnSec2Sec(2, 1, 0, 0, 0), 9201600);

            %Day 2, Hour 1, Minute 1, Second 1.
            ut = 21600 + 3600 + 60 + 1;
            [y, d, h, m, s] = convertSec2YearDayHrMnSec(ut);
            testCase.verifyEqual([y d h m s], [1 2 1 1 1]);
            testCase.verifyEqual(convertYearDayHrMnSec2Sec(1, 2, 1, 1, 1), ut);
        end

        function testCustomRoundTripConversion(testCase)
            global ksptot_TimeSystem; %#ok<GVMIS>
            ksptot_TimeSystem = KSPTOT_TimeSystem.custom(43200, 16459200);

            %One full custom year: Year 2, Day 1, 00:00:00.
            [y, d, h, m, s] = convertSec2YearDayHrMnSec(16459200);
            testCase.verifyEqual([y d h m s], [2 1 0 0 0]);
            testCase.verifyEqual(convertYearDayHrMnSec2Sec(2, 1, 0, 0, 0), 16459200);

            %Day 3, Hour 5, Second 42.
            ut = 2*43200 + 5*3600 + 42;
            [y, d, h, m, s] = convertSec2YearDayHrMnSec(ut);
            testCase.verifyEqual([y d h m s], [1 3 5 0 42]);
            testCase.verifyEqual(convertYearDayHrMnSec2Sec(1, 3, 5, 0, 42), ut);
        end

        function testSecondsInVariousTimeUnitsUsesGlobal(testCase)
            global ksptot_TimeSystem; %#ok<GVMIS>

            ksptot_TimeSystem = KSPTOT_TimeSystem.custom(43200, 16459200);
            [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits();
            testCase.verifyEqual([secInMin secInHr secInDay secInYear], [60 3600 43200 16459200]);

            ksptot_TimeSystem = KSPTOT_TimeSystem.earthStock();
            [secInMin, secInHr, secInDay, secInYear] = getSecondsInVariousTimeUnits();
            testCase.verifyEqual([secInMin secInHr secInDay secInYear], [60 3600 86400 31536000]);
        end

        function testSecondsInVariousTimeUnitsLegacyFallback(testCase)
            %With no KSPTOT_TimeSystem global, the legacy Earth/Kerbin flag
            %drives the constants.
            global options_UseEarthTimeSystem; %#ok<GVMIS>

            options_UseEarthTimeSystem = true;
            [~, ~, secInDay, secInYear] = getSecondsInVariousTimeUnits();
            testCase.verifyEqual([secInDay secInYear], [86400 31536000]);

            options_UseEarthTimeSystem = false;
            [~, ~, secInDay, secInYear] = getSecondsInVariousTimeUnits();
            testCase.verifyEqual([secInDay secInYear], [21600 9201600]);
        end

        function testParseTimeSystemFromINIRowsNoSection(testCase)
            rows = {'Sun','','epoch','0'};
            ts = parseTimeSystemFromINIRows(rows);
            testCase.verifyEmpty(ts);

            ts = parseTimeSystemFromINIRows([]);
            testCase.verifyEmpty(ts);
        end

        function testParseTimeSystemFromINIRowsCustom(testCase)
            rows = {'Time','','system','custom'; ...
                    'Time','','secondsPerDay','43200'; ...
                    'Time','','secondsPerYear','16459200'; ...
                    'Time','','hoursPerDay','12'; ...
                    'Time','','minutesPerHour','60'; ...
                    'Time','','secondsPerMinute','60'};

            ts = parseTimeSystemFromINIRows(rows);

            testCase.verifyNotEmpty(ts);
            testCase.verifyEqual(ts.system, 'custom');
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 16459200);
            testCase.verifyEqual(ts.hoursPerDay, 12);
            testCase.verifyEqual(ts.minutesPerHour, 60);
            testCase.verifyEqual(ts.secondsPerMinute, 60);
        end

        function testParseTimeSystemFromINIRowsStockAliases(testCase)
            rows = {'Time','','system','kerbin'};
            ts = parseTimeSystemFromINIRows(rows);
            testCase.verifyEqual(ts.system, 'kerbin_stock');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
            testCase.verifyEqual(ts.secondsPerYear, 9201600);

            rows = {'Time','','system','earth'};
            ts = parseTimeSystemFromINIRows(rows);
            testCase.verifyEqual(ts.system, 'earth_stock');
            testCase.verifyEqual(ts.secondsPerDay, 86400);
            testCase.verifyEqual(ts.secondsPerYear, 31536000);
        end

        function testParseTimeSystemFromINIRowsStockWithOverrides(testCase)
            %A stock system may still override the base constants.
            rows = {'Time','','system','kerbin_stock'; ...
                    'Time','','secondsPerDay','21600'; ...
                    'Time','','secondsPerYear','9972540'};

            ts = parseTimeSystemFromINIRows(rows);
            testCase.verifyEqual(ts.system, 'kerbin_stock');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
            testCase.verifyEqual(ts.secondsPerYear, 9972540);
        end

        function testParseTimeSystemFromINIRowsMissingCustomValues(testCase)
            %A custom system without secondsPerYear falls back to the stock
            %Kerbin value with a warning; provided values are preserved.
            rows = {'Time','','system','custom'; ...
                    'Time','','secondsPerDay','43200'};

            testCase.verifyWarning(@() parseTimeSystemFromINIRows(rows), 'KSPTOT_TimeSystem:NoSecondsPerYear');

            ts = parseTimeSystemFromINIRows(rows);
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 9201600);
        end

        function testProcessINIBodyInfoIgnoresTimeSection(testCase)
            %A [Time] section must not be turned into a celestial body.
            rows = {'Time','','system','custom'; ...
                    'Time','','secondsPerDay','43200'; ...
                    'Time','','secondsPerYear','16459200'; ...
                    'ksptot','','timesystem','Earth'};

            appOptions = processINIBodyInfo(rows, false, 'appOptions');

            testCase.verifyFalse(isfield(appOptions, 'time'));
            testCase.verifyTrue(isfield(appOptions, 'ksptot'));
            testCase.verifyEqual(appOptions.ksptot.timesystem, 'Earth');
        end

        function testProcessINIBodyInfoIgnoresTimeSectionInBodiesFile(testCase)
            %The stock bodies file plus a [Time] section still parses all
            %bodies and produces no fake "time" body.
            iniPath = fullfile(ksptotTestRoot(), 'bodies.ini');
            [rows, ~, ~] = inifile(iniPath, 'readall');

            rowsWithTime = vertcat(rows, ...
                {'Time','','system','custom'}, ...
                {'Time','','secondsPerDay','43200'}, ...
                {'Time','','secondsPerYear','16459200'});

            bodyInfo = processINIBodyInfo(rowsWithTime, false, 'bodyInfo');

            testCase.verifyFalse(isfield(bodyInfo, 'time'));
            testCase.verifyTrue(isfield(bodyInfo, 'kerbin'));
            testCase.verifyTrue(isfield(bodyInfo, 'sun'));
            testCase.verifyEqual(bodyInfo.kerbin.gm, 3531.6);
        end

        function testGetTimeSystemFromConfigPrefersTimeIni(testCase)
            %time.ini beats the bodies file [Time] section and appOptions.
            oldDir = pwd;

            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.addTeardown(@() cleanupTempDir(oldDir, tmpDir));

            writeIniTextFile(fullfile(tmpDir, 'time.ini'), ...
                {'[Time]', 'system = custom', 'secondsPerDay = 43200', 'secondsPerYear = 16459200'});
            writeIniTextFile(fullfile(tmpDir, 'bodies_custom.ini'), ...
                {'[Time]', 'system = custom', 'secondsPerDay = 21600', 'secondsPerYear = 9972540'});

            appOptions = makeAppOptions('Kerbin', fullfile(tmpDir, 'bodies_custom.ini'));

            cd(tmpDir);

            ts = getTimeSystemFromConfig(appOptions, []);

            testCase.verifyEqual(ts.system, 'custom');
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 16459200);
        end

        function testGetTimeSystemFromConfigPrefersBodiesTimeSection(testCase)
            %Without time.ini, the bodies file [Time] section wins over
            %the appOptions selection.
            oldDir = pwd;

            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.addTeardown(@() cleanupTempDir(oldDir, tmpDir));

            writeIniTextFile(fullfile(tmpDir, 'bodies_custom.ini'), ...
                {'[Time]', 'system = custom', 'secondsPerDay = 21600', 'secondsPerYear = 9972540'});

            appOptions = makeAppOptions('Earth', fullfile(tmpDir, 'bodies_custom.ini'));

            cd(tmpDir);

            ts = getTimeSystemFromConfig(appOptions, []);

            testCase.verifyEqual(ts.system, 'custom');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
            testCase.verifyEqual(ts.secondsPerYear, 9972540);
        end

        function testGetTimeSystemFromConfigUsesAppOptions(testCase)
            %No [Time] section anywhere: the legacy appOptions selection
            %drives the system.
            appOptions = makeAppOptions('Earth', '');
            ts = getTimeSystemFromConfig(appOptions, {});
            testCase.verifyEqual(ts.system, 'earth_stock');
            testCase.verifyEqual(ts.secondsPerDay, 86400);

            appOptions = makeAppOptions('Kerbin', '');
            ts = getTimeSystemFromConfig(appOptions, {});
            testCase.verifyEqual(ts.system, 'kerbin_stock');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
        end

        function testGetTimeSystemFromConfigCustomRequestedButUndefined(testCase)
            %The user selected "custom" but no [Time] section exists:
            %fall back to stock Kerbin with a warning.
            appOptions = makeAppOptions('Custom', '');
            testCase.verifyWarning(@() getTimeSystemFromConfig(appOptions, {}), 'KSPTOT_TimeSystem:NoCustomDefined');

            ts = getTimeSystemFromConfig(appOptions, {});
            testCase.verifyEqual(ts.system, 'kerbin_stock');
        end

        function testGetTimeSystemFromConfigDefaults(testCase)
            %No appOptions timesystem at all: stock Kerbin.
            appOptions = struct();
            ts = getTimeSystemFromConfig(appOptions, {});
            testCase.verifyEqual(ts.system, 'kerbin_stock');
            testCase.verifyEqual(ts.secondsPerDay, 21600);
            testCase.verifyEqual(ts.secondsPerYear, 9201600);
        end

        function testGetTimeSystemFromConfigUsesProvidedBodiesRows(testCase)
            %Rows passed in directly are used without reading the file.
            appOptions = makeAppOptions('Kerbin', '');
            rows = {'Time','','system','custom'; ...
                    'Time','','secondsPerDay','43200'; ...
                    'Time','','secondsPerYear','16459200'};

            ts = getTimeSystemFromConfig(appOptions, rows);

            testCase.verifyEqual(ts.system, 'custom');
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 16459200);
        end

        function testGetCustomTimeSystemUndefined(testCase)
            %No time.ini and no [Time] section: [] is returned so the UI
            %can grey out the custom time menu item.
            oldDir = pwd;

            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.addTeardown(@() cleanupTempDir(oldDir, tmpDir));

            writeIniTextFile(fullfile(tmpDir, 'bodies_stock.ini'), {'[Sun]', 'epoch = 0'});

            appOptions = makeAppOptions('Kerbin', fullfile(tmpDir, 'bodies_stock.ini'));

            cd(tmpDir);

            testCase.verifyEmpty(getCustomTimeSystem(appOptions));
        end

        function testGetCustomTimeSystemDefined(testCase)
            %A [Time] section in the active bodies file is detected.
            oldDir = pwd;

            tmpDir = tempname;
            mkdir(tmpDir);
            testCase.addTeardown(@() cleanupTempDir(oldDir, tmpDir));

            writeIniTextFile(fullfile(tmpDir, 'bodies_custom.ini'), ...
                {'[Time]', 'system = custom', 'secondsPerDay = 43200', 'secondsPerYear = 16459200'});

            appOptions = makeAppOptions('Kerbin', fullfile(tmpDir, 'bodies_custom.ini'));

            cd(tmpDir);

            ts = getCustomTimeSystem(appOptions);
            testCase.verifyNotEmpty(ts);
            testCase.verifyEqual(ts.secondsPerDay, 43200);
            testCase.verifyEqual(ts.secondsPerYear, 16459200);
        end
    end
end

function appOptions = makeAppOptions(timesystem, bodiesIniFile)
%makeAppOptions Builds an appOptions struct shaped like the output of
%processINIBodyInfo(..., 'appOptions').

    appOptions = struct();
    appOptions.ksptot = KSPTOT_AppOptions();
    appOptions.ksptot.timesystem = timesystem;
    appOptions.ksptot.bodiesinifile = bodiesIniFile;
end

function writeIniTextFile(filePath, lines)
%writeIniTextFile Writes simple [section] / key = value text lines to a file.

    fid = fopen(filePath, 'w');
    for(i=1:numel(lines))
        fprintf(fid, '%s\n', lines{i});
    end
    fclose(fid);
end

function cleanupTempDir(oldDir, tmpDir)
%cleanupTempDir Restores the working directory and removes a temp folder.
%The directory removal must happen only after the working directory has
%been moved back out of the temp folder.

    cd(oldDir);
    if(isfolder(tmpDir))
        rmdir(tmpDir, 's');
    end
end