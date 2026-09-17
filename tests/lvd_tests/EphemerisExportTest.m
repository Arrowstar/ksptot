classdef EphemerisExportTest < KsptotTestCase
    %EphemerisExportTest lvd_exportEphemeris (F9) against a propagated mission.
    %
    % Fixture: a two-body coast in a 300 km circular Kerbin orbit, event 1
    % ending with an impulsive 1 km/s delta-v action so the state log holds
    % a genuine velocity discontinuity (two entries at the same epoch with
    % different velocity), followed by event 2.  The export must reproduce
    % the log row for row in raw mode, and must never interpolate across
    % that discontinuity in resampled mode.

    properties(Constant)
        DvKms = 1.0;
    end

    methods(Test)

        function csvRawRowsMatchTheStateLogInTheRequestedFrame(testCase)
            [~, stateLog, tD] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;

            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            numRows = lvd_exportEphemeris(stateLog, frame, filePath, struct('format', 'csv'));

            headerLine = testCase.firstLine(filePath);
            testCase.verifyEqual(headerLine, 'UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms,event_num', ...
                'CSV header line does not match the documented column layout');

            M = readmatrix(filePath);
            testCase.verifyEqual(size(M, 1), numRows, 'Returned row count must equal the rows in the file');
            testCase.verifySize(M, [numRows, 8]);

            %Independent oracle: every log entry converted to the frame,
            %then consecutive rows that share an epoch and agree in state
            %to round-off collapsed (the later one kept).  The state log
            %really does hold such near-duplicates: the initial-state entry
            %is logged twice, and the first entry of event 2 re-states the
            %post-burn entry of event 1 to ~1e-15 relative.
            oracle = testCase.oracleRows(stateLog, frame);
            keep = true(1, size(oracle, 2));
            for i = 2:size(oracle, 2)
                sameEpoch = oracle(1, i) == oracle(1, i-1);
                sameState = norm(oracle(2:7, i) - oracle(2:7, i-1)) <= 1e-9 * max(1, norm(oracle(2:7, i)));
                if(sameEpoch && sameState)
                    keep(i-1) = false;
                end
            end
            oracle = oracle(:, keep);

            testCase.verifyEqual(size(oracle, 2), numRows, ...
                'Raw export must hold exactly the deduplicated state log rows');
            testCase.verifyEqual(M(:, 1:7)', oracle, 'RelTol', 1e-12, 'AbsTol', 1e-12, ...
                'Exported epochs/positions/velocities differ from the state log in the requested frame');

            %The discontinuity survives as two rows at the same epoch: the
            %pre-burn state tagged with event 1 and the post-burn state
            %tagged with event 2 (the later segment owns the boundary).
            dupRows = find(M(:, 1) == tD);
            testCase.verifyNumElements(dupRows, 2, 'The delta-v discontinuity must appear as two rows sharing one epoch');
            testCase.verifyGreaterThan(norm(M(dupRows(2), 5:7) - M(dupRows(1), 5:7)), 0.9 * testCase.DvKms, ...
                'The two rows at the discontinuity epoch must differ by the applied delta-v');
            testCase.verifyEqual(M(dupRows, 8), [1; 2], 'Boundary rows must be tagged pre-burn event 1, post-burn event 2');

            %Event number column follows the owning event.
            testCase.verifyTrue(all(M(M(:, 1) <  tD, 8) == 1), 'Rows before the boundary must be tagged event 1');
            testCase.verifyTrue(all(M(M(:, 1) >  tD, 8) == 2), 'Rows after the boundary must be tagged event 2');
        end

        function csvIncludesTheMassColumnWhenRequested(testCase)
            [~, stateLog] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;

            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            opts = struct('format', 'csv', 'includeMass', true);
            numRows = lvd_exportEphemeris(stateLog, frame, filePath, opts);

            testCase.verifyEqual(testCase.firstLine(filePath), ...
                'UT_sec,x_km,y_km,z_km,vx_kms,vy_kms,vz_kms,mass_mT,event_num');

            M = readmatrix(filePath);
            testCase.verifySize(M, [numRows, 9]);

            entries = stateLog.getAllEntries();
            testCase.verifyEqual(M(1, 8), entries(1).getTotalVehicleMass(), 'RelTol', 1e-12, ...
                'Mass column must be the total vehicle mass of the matching entry');
            testCase.verifyEqual(M(end, 8), entries(end).getTotalVehicleMass(), 'RelTol', 1e-12);
        end

        function resampledGridHasTheExpectedRowsAndDoesNotBridgeTheDiscontinuity(testCase)
            [~, stateLog, tD, vPre, vPost] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;
            step = 10;

            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            numRows = lvd_exportEphemeris(stateLog, frame, filePath, struct('format', 'csv', 'stepSize', step));
            M = readmatrix(filePath);

            [t0, tEnd] = stateLog.getStartAndEndTimes();
            expectedGrid = t0:step:tEnd;
            if(expectedGrid(end) < tEnd)
                expectedGrid(end+1) = tEnd;
            end

            testCase.verifyEqual(numRows, numel(expectedGrid), ...
                'Resampled export must hold one row per grid epoch plus the final epoch');
            testCase.verifyEqual(M(:, 1)', expectedGrid, 'AbsTol', 1e-9, 'Resampled epochs are not the expected grid');
            testCase.verifyFalse(any(isnan(M(:))), 'Resampled rows must not contain NaN');
            testCase.verifyTrue(all(diff(M(:, 1)) > 0), 'Resampled epochs must be strictly increasing (boundary not on grid)');

            %The 1 km/s jump at tD is far larger than the ~0.03 km/s the
            %gravity turn can move velocity in 10 s, so the row before the
            %boundary must look like the pre-burn state and the row after
            %like the post-burn state.  A spline that bridged the two
            %segments would land somewhere in between.
            iBefore = find(M(:, 1) < tD, 1, 'last');
            iAfter  = find(M(:, 1) > tD, 1, 'first');
            testCase.verifyLessThan(norm(M(iBefore, 5:7)' - vPre),  0.1 * testCase.DvKms, ...
                'Row before the discontinuity was contaminated by the post-burn segment');
            testCase.verifyLessThan(norm(M(iAfter, 5:7)'  - vPost), 0.1 * testCase.DvKms, ...
                'Row after the discontinuity was contaminated by the pre-burn segment');

            testCase.verifyTrue(all(M(M(:, 1) < tD, 8) == 1));
            testCase.verifyTrue(all(M(M(:, 1) > tD, 8) == 2));
        end

        function resampledBoundaryEpochTakesTheLaterSegmentAndKeepsTheFinalEpoch(testCase)
            [~, stateLog, tD, ~, vPost] = testCase.propagatedMission(30, 60);
            frame = testCase.kerbinFrame;
            step = 10;

            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            lvd_exportEphemeris(stateLog, frame, filePath, struct('format', 'csv', 'stepSize', step));
            M = readmatrix(filePath);

            iBoundary = find(M(:, 1) == tD);
            testCase.verifyNumElements(iBoundary, 1, 'A grid epoch on the boundary must yield exactly one row');
            testCase.verifyEqual(M(iBoundary, 8), 2, 'The boundary row must belong to the later event');
            testCase.verifyLessThan(norm(M(iBoundary, 5:7)' - vPost), 1e-6, ...
                'The boundary row must carry the post-burn (later segment) state');

            [~, tEnd] = stateLog.getStartAndEndTimes();
            testCase.verifyEqual(M(end, 1), tEnd, 'AbsTol', 1e-9, 'The final epoch must always be written');
        end

        function oemFileHasTheExpectedHeaderAndDataLines(testCase)
            [~, stateLog] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;

            oemPath = [tempname(), '.oem'];
            csvPath = [tempname(), '.csv'];
            cleanup = onCleanup(@() cellfun(@deleteIfExists, {oemPath, csvPath})); %#ok<NASGU>

            opts = struct('format', 'oem', 'objectName', 'TestSat');
            numRows = lvd_exportEphemeris(stateLog, frame, oemPath, opts);
            lvd_exportEphemeris(stateLog, frame, csvPath, struct('format', 'csv'));
            csvM = readmatrix(csvPath);

            txt = fileread(oemPath);
            lines = regexp(txt, '\r\n|\n|\r', 'split');

            testCase.verifyTrue(any(strcmp(lines, 'CCSDS_OEM_VERS = 2.0')), 'Missing CCSDS_OEM_VERS header');
            testCase.verifyTrue(any(strcmp(lines, 'OBJECT_NAME = TestSat')), 'OBJECT_NAME must be the requested object name');
            testCase.verifyTrue(any(strcmp(lines, ['REF_FRAME = ', frame.getNameStr()])), 'REF_FRAME must be the frame name');
            testCase.verifyTrue(any(strcmp(lines, ['CENTER_NAME = ', testCase.kerbin.name])), 'CENTER_NAME must default to the frame origin body');
            testCase.verifyTrue(any(strcmp(lines, 'TIME_SYSTEM = UT')));
            testCase.verifyTrue(any(strcmp(lines, 'META_START')) && any(strcmp(lines, 'META_STOP')));

            startLine = lines{startsWith(lines, 'START_TIME = ')};
            stopLine  = lines{startsWith(lines, 'STOP_TIME = ')};
            testCase.verifyEqual(str2double(extractAfter(startLine, 'START_TIME = ')), csvM(1, 1), 'AbsTol', 1e-9);
            testCase.verifyEqual(str2double(extractAfter(stopLine,  'STOP_TIME = ')),  csvM(end, 1), 'AbsTol', 1e-9);

            metaStop = find(strcmp(lines, 'META_STOP'), 1);
            dataLines = lines(metaStop+1:end);
            dataVals = cellfun(@(s) str2double(strsplit(strtrim(s))), dataLines, 'UniformOutput', false);
            isData = cellfun(@(v) numel(v) == 7 && not(any(isnan(v))), dataVals);
            dataVals = vertcat(dataVals{isData});

            testCase.verifyEqual(size(dataVals, 1), numRows, 'OEM data line count must equal the returned row count');
            testCase.verifyEqual(dataVals, csvM(:, 1:7), 'RelTol', 1e-15, 'AbsTol', 1e-15, ...
                'OEM data lines must carry the same epochs and states as the CSV export');
        end

        function exportInAnotherBodyFrameMatchesConvertToFrame(testCase)
            [~, stateLog] = testCase.propagatedMission(33, 60);
            munFrame = testCase.mun.getBodyCenteredInertialFrame();

            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            lvd_exportEphemeris(stateLog, munFrame, filePath, struct('format', 'csv'));
            M = readmatrix(filePath);

            entries = stateLog.getAllEntries();
            ce = entries(1).getCartesianElementSetRepresentation().convertToFrame(munFrame);

            testCase.verifyEqual(M(1, 2:4)', ce.rVect, 'RelTol', 1e-12, 'Position in the Mun frame differs from convertToFrame');
            testCase.verifyEqual(M(1, 5:7)', ce.vVect, 'RelTol', 1e-12, 'Velocity in the Mun frame differs from convertToFrame');

            %Sanity: the Mun-frame position is not simply the Kerbin-frame one.
            testCase.verifyGreaterThan(norm(M(1, 2:4)' - entries(1).position), 1000, ...
                'Fixture broken: the Mun-centred position should be far from the Kerbin-centred one');
        end

        function exportRejectsBadOptions(testCase)
            [~, stateLog] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;
            filePath = [tempname(), '.csv'];
            cleanup = onCleanup(@() deleteIfExists(filePath)); %#ok<NASGU>

            testCase.verifyError(@() lvd_exportEphemeris(stateLog, frame, filePath, struct('format', 'xyz')), ...
                'lvd_exportEphemeris:badFormat');
            testCase.verifyError(@() lvd_exportEphemeris(stateLog, frame, filePath, struct('stepSize', -1)), ...
                'lvd_exportEphemeris:badStep');
        end
    end

    methods(Access=private)
        function [lvdData, stateLog, tD, vPre, vPost] = propagatedMission(testCase, dur1, dur2)
            bodyInfo = testCase.kerbin;
            frame = testCase.kerbinFrame;

            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            lvdData.initStateModel.orbitModel = KeplerianElementSet(0, bodyInfo.radius + 300, 0, 0.1, 0, 0, 0, frame);

            evt1 = lvdData.script.getEventForInd(1);
            evt1.termCond = EventDurationTermCondition(dur1);
            evt1.propagatorObj = evt1.twoBodyPropagator;
            evt1.addAction(AddDeltaVAction([testCase.DvKms; 0; 0], DeltaVFrameEnum.Inertial, false));

            evt2 = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            evt2.termCond = EventDurationTermCondition(dur2);
            evt2.propagatorObj = evt2.twoBodyPropagator;
            lvdData.script.addEvent(evt2);

            stateLog = lvdData.script.executeScript(false, evt1, false, false, false, false, false);

            tD = dur1;
            evt1Entries = stateLog.getAllStateLogEntriesForEvent(evt1);
            atBoundary = evt1Entries([evt1Entries.time] == tD);
            testCase.assertGreaterThanOrEqual(numel(atBoundary), 2, ...
                'Fixture broken: expected a pre- and post-action entry at the end of event 1.');
            vPre = atBoundary(1).velocity;
            vPost = atBoundary(end).velocity;
            testCase.assertGreaterThan(norm(vPost - vPre), 0.9 * testCase.DvKms, ...
                'Fixture broken: the delta-v action did not produce a velocity discontinuity.');
        end

        function rows = oracleRows(~, stateLog, frame)
            entries = stateLog.getAllEntries();
            rows = zeros(7, numel(entries));
            for i = 1:numel(entries)
                ce = entries(i).getCartesianElementSetRepresentation().convertToFrame(frame);
                rows(:, i) = [ce.time; ce.rVect; ce.vVect];
            end
        end

        function line = firstLine(~, filePath)
            fid = fopen(filePath, 'r');
            line = fgetl(fid);
            fclose(fid);
        end
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
