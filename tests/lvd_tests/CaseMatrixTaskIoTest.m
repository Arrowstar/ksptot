classdef CaseMatrixTaskIoTest < KsptotTestCase
    %CaseMatrixTaskIoTest How a sweep case reaches its mission file.
    %
    % A case's mission deliberately does not live in memory -- a thousand-case
    % sweep holding a thousand missions at once does not fit -- so it lives in
    % a .mat file and is reached through loadLvdData/saveLvdData.
    %
    % This used to be a DEPENDENT property whose getter was a bare
    % load(obj.lvdFilePath, 'lvdData') and whose setter was a bare save. Every
    % read deserialized an entire mission off disk: once per contributing case
    % inside the loop in LvdCaseMatrix.updateFailedTaskWithFitXVector, and
    % twice to no effect at all in processTaskOutputs, which loaded a mission
    % and immediately saved it back unchanged. It also silently returned an
    % empty result for a case file that did not exist yet.
    %
    % So the tests here are about identity and honesty rather than arithmetic:
    % a second read must come back from the cache (proven by making the file on
    % disk disagree with it, and by deleting the file outright), clearing the
    % cache must really send the next read back to disk, a missing or wrong
    % file must error with its own identifier, and -- because a task is
    % serialized to a parallel worker -- the cached mission must NOT travel
    % with it.

    properties(Constant)
        %Arbitrary distinct markers.  A mission's marker is a plugin variable's
        %value: a plain settable double that nothing in the I/O path touches,
        %so whichever number comes back identifies which copy of the mission
        %the reader got.
        DiskMarker    = 11;
        CacheMarker   = 22;
        MutatedMarker = 33;
    end

    methods(Test)

        function aSecondReadComesFromTheCacheRatherThanFromDisk(testCase)
            [task, path] = testCase.savedCase(testCase.CacheMarker);

            first = task.loadLvdData();
            testCase.assertEqual(testCase.markerOf(first), testCase.CacheMarker);

            %Make the file on disk disagree with what the task already has.  A
            %reader that goes back to disk every time cannot help but notice.
            CaseMatrixTaskIoTest.writeMissionFile(path, testCase.markedMission(testCase.DiskMarker));

            second = task.loadLvdData();

            testCase.verifyEqual(testCase.markerOf(second), testCase.CacheMarker, ...
                'The second read went back to disk instead of using the cached mission');
            testCase.verifyTrue(second == first, ...
                'A cache hit must hand back the same mission handle, not a fresh deserialization');

            %A mutation made through one read must be visible through the next,
            %which is the property the warm-start and retry paths rely on.
            testCase.setMarker(second, testCase.MutatedMarker);
            testCase.verifyEqual(testCase.markerOf(task.loadLvdData()), testCase.MutatedMarker);

            %And the strongest form of the same claim: with the file gone
            %entirely, a cached task still reads.
            delete(path);
            testCase.assertFalse(isfile(path), 'Fixture broken: the case file was not deleted');

            testCase.verifyEqual(testCase.markerOf(task.loadLvdData()), testCase.MutatedMarker, ...
                'A warm cache must survive the case file being removed');
        end

        function savingWritesTheFileAndLeavesTheCacheAgreeingWithIt(testCase)
            %saveLvdData refreshes the cache rather than invalidating it: in
            %Optimize mode the case file is written before consoleOptimize runs
            %and then read straight back by the harvest step.
            [task, path] = testCase.savedCase(testCase.DiskMarker);

            replacement = testCase.markedMission(testCase.CacheMarker);
            task.saveLvdData(replacement);

            testCase.verifyTrue(task.loadLvdData() == replacement, ...
                'Saving a mission must leave the cache holding that same mission');

            %The bytes really went to disk, not just into the cache.  Reading
            %the file with a plain load is an oracle that shares no code with
            %loadLvdData.
            s = load(path, 'lvdData');
            testCase.verifyEqual(testCase.markerOf(s.lvdData), testCase.CacheMarker, ...
                'saveLvdData did not actually write the case file');
        end

        function clearingTheCacheSendsTheNextReadBackToDisk(testCase)
            %The negative control for the cache tests above.  If
            %clearLvdDataCache did not work, a finished sweep would hold every
            %case's mission at once -- and, worse, an unsaved edit would look
            %persisted.
            task = testCase.savedCase(testCase.DiskMarker);

            inMemory = task.loadLvdData();
            testCase.setMarker(inMemory, testCase.MutatedMarker);

            %Deliberately NOT saved.
            task.clearLvdDataCache();

            reread = task.loadLvdData();

            testCase.verifyEqual(testCase.markerOf(reread), testCase.DiskMarker, ...
                'Clearing the cache must discard unsaved edits and reread the file');
            testCase.verifyFalse(reread == inMemory, ...
                'A read after a cache clear must produce a fresh mission, not the dropped one');
        end

        function aMissingOrWrongCaseFileErrorsWithItsOwnIdentifier(testCase)
            %The old dependent getter returned an empty LvdData for a case file
            %that had not been written yet, and the failure then surfaced much
            %later as something unrelated.  Both of these are ordinary run-time
            %situations, so they get identifiers a caller can catch on.
            missing = testCase.taskFor([tempname(), '.mat']);

            testCase.verifyError(@() missing.loadLvdData(), 'LvdCaseMatrixTask:caseFileNotFound');

            junkPath = [tempname(), '.mat'];
            CaseMatrixTaskIoTest.writeJunkMatFile(junkPath);

            junk = testCase.taskFor(junkPath);

            %load() itself warns about the variable it could not find; the
            %error raised in its place is what this test is about.
            testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
                'MATLAB:load:variableNotFound'));

            testCase.verifyError(@() junk.loadLvdData(), 'LvdCaseMatrixTask:notACaseFile');

            %A failed read must not poison the task: once the file appears, the
            %same task reads it.
            CaseMatrixTaskIoTest.writeMissionFile(junkPath, testCase.markedMission(testCase.DiskMarker));
            testCase.verifyEqual(testCase.markerOf(junk.loadLvdData()), testCase.DiskMarker);
        end

        function theCachedMissionDoesNotTravelWithASerializedTask(testCase)
            %A task is dispatched to a worker by byte stream.  If the cache
            %were not Transient, every dispatch would ship a whole mission with
            %it -- exactly what keeping the mission on disk was meant to avoid.
            [task, path] = testCase.savedCase(testCase.DiskMarker);

            %Measured as the MARGINAL cost of warming the cache, not as an
            %absolute size: a byte stream carries the class definitions of
            %everything in it, which for this class is a few hundred KB of
            %fixed overhead that says nothing about the payload.
            coldBytes = numel(getByteStreamFromArray(task));

            mission = task.loadLvdData();
            missionBytes = numel(getByteStreamFromArray(mission));

            warmBytes = numel(getByteStreamFromArray(task));

            testCase.assertGreaterThan(missionBytes, 64 * 1024, ...
                'Fixture broken: the mission is too small for this size comparison to mean anything');
            testCase.verifyEqual(warmBytes, coldBytes, ...
                sprintf('Warming the cache added %i bytes to a serialized task, out of a %u byte mission', ...
                        warmBytes - coldBytes, missionBytes));

            %And behaviourally: with the file gone, the clone has nothing to
            %read, while the original still answers from its cache.
            clone = getArrayFromByteStream(getByteStreamFromArray(task));
            delete(path);

            testCase.verifyError(@() clone.loadLvdData(), 'LvdCaseMatrixTask:caseFileNotFound', ...
                'A deserialized task must not arrive with a mission already cached');
            testCase.verifyEqual(testCase.markerOf(task.loadLvdData()), testCase.DiskMarker);

            %Everything that is not the cache did travel.
            testCase.verifyEqual(clone.id, task.id);
            testCase.verifyEqual(clone.lvdFilePath, task.lvdFilePath);
        end

        function anInjectedMissionNeverTouchesTheFileSystem(testCase)
            %How a propagate-only case gets its copy of the template: the
            %worker clones one broadcast byte stream and injects the result.  A
            %Monte Carlo run with persistCaseFile off must therefore do no file
            %I/O per case at all.
            path = [tempname(), '.mat'];
            task = testCase.taskFor(path);
            task.persistCaseFile = false;

            injected = testCase.markedMission(testCase.CacheMarker);
            task.setCaseLvdData(injected);

            testCase.verifyTrue(task.loadLvdData() == injected, ...
                'An injected mission must be what the case then runs');
            testCase.verifyFalse(isfile(path), ...
                'Injecting a mission must not write the case file');

            %Clearing the cache leaves nothing behind, because nothing was
            %ever persisted.
            task.clearLvdDataCache();
            testCase.verifyError(@() task.loadLvdData(), 'LvdCaseMatrixTask:caseFileNotFound');
        end

        function aDetachedCopyKeepsTheIdDropsTheMatrixAndSharesNoCache(testCase)
            %The caseMatrix back-reference drags every other task and the
            %template mission through the serializer.  An independent
            %propagate-only case is dispatched without it, and its results are
            %matched back onto the client's own task by id.
            [task, path] = testCase.savedCase(testCase.DiskMarker);

            matrix = LvdCaseMatrix(testCase.markedMission(testCase.DiskMarker), tempdir());
            task.caseMatrix = matrix;
            task.prereqTasks = testCase.taskFor([tempname(), '.mat']);
            task.responses = LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), ...
                                              LvdSweepResponseNodeEnum.Maximum, 0);
            task.runMode = LvdCaseMatrixRunModeEnum.PropagateOnly;
            task.writeGaTimeSeries = false;
            task.persistCaseFile = false;
            task.numAttempts = 1;
            task.status = LvdCaseMatrixTaskStatusEnum.Running;

            task.loadLvdData();

            copy = task.makeDetachedCopy();

            testCase.verifyEqual(copy.id, task.id, ...
                'The id is how a worker''s results find their way back to the client''s task');
            testCase.verifyEmpty(copy.caseMatrix, 'A detached copy must not link back to the case matrix');
            testCase.verifyEmpty(copy.prereqTasks, 'A detached copy must not drag the other tasks along');

            %Everything the worker needs to run the case and harvest it.
            testCase.verifyEqual(copy.paramValues, task.paramValues);
            testCase.verifyEqual(numel(copy.params), numel(task.params));
            testCase.verifyEqual([copy.responses.id], [task.responses.id]);
            testCase.verifyEqual(copy.runMode, task.runMode);
            testCase.verifyEqual(copy.writeGaTimeSeries, task.writeGaTimeSeries);
            testCase.verifyEqual(copy.persistCaseFile, task.persistCaseFile);
            testCase.verifyEqual(copy.status, task.status);
            testCase.verifyEqual(copy.numAttempts, task.numAttempts);
            testCase.verifyEqual(copy.lvdFilePath, task.lvdFilePath);

            %The copy is a separate object: writing to it must not write to the
            %client's task, or mergeChunkResults would have nothing to do.
            copy.status = LvdCaseMatrixTaskStatusEnum.Completed;
            testCase.verifyEqual(task.status, LvdCaseMatrixTaskStatusEnum.Running, ...
                'A detached copy must not be an alias for the original task');

            %Nor does it inherit the cache.
            delete(path);
            testCase.verifyError(@() copy.loadLvdData(), 'LvdCaseMatrixTask:caseFileNotFound');
        end

        function clearingTheCacheWorksOnAWholeArrayOfTasks(testCase)
            %runAllTasks calls obj.tasks.clearLvdDataCache() on the whole array
            %at once, so the loop inside has to be over obj, not a no-op on
            %obj(1).
            tasks = LvdCaseMatrixTask.empty(1,0);
            paths = {};

            for(i = 1:3) %#ok<*NO4LP>
                [tasks(i), paths{i}] = testCase.savedCase(i); %#ok<AGROW>
                testCase.assertEqual(testCase.markerOf(tasks(i).loadLvdData()), i);
            end

            tasks.clearLvdDataCache();

            for(i = 1:3)
                delete(paths{i});
                testCase.verifyError(@() tasks(i).loadLvdData(), 'LvdCaseMatrixTask:caseFileNotFound', ...
                    sprintf('Task %u kept its cached mission', i));
            end
        end

        function aTaskSavedBeforeParametersWereGeneralizedMigratesOnLoad(testCase)
            %An old case file holds its values on the parameter objects
            %themselves, as LvdCaseMatrixTaskParameter.newVal.  The definitions
            %carry straight over -- an old parameter IS a sweep parameter now --
            %but the values have to be lifted out into paramValues.
            [lvdData, pluginVar] = testCase.markedMission(testCase.DiskMarker);

            second = LvdPluginOptimVarWrapper();
            second.name = 'Second';
            second.value = 5;
            second.optVar = second.getNewOptVar();
            lvdData.pluginVars.addPluginVar(second);

            legacy = [LvdCaseMatrixTaskParameter(pluginVar, 42), ...
                      LvdCaseMatrixTaskParameter(second, 7)];

            task = testCase.taskFor([tempname(), '.mat']);
            task.params = AbstractLvdSweepParameter.empty(1,0);
            task.paramValues = [];
            task.caseParams = legacy;

            reloaded = getArrayFromByteStream(getByteStreamFromArray(task));

            testCase.verifyEqual(numel(reloaded.params), 2, ...
                'An old task''s parameter definitions must survive as sweep parameters');
            testCase.verifyEqual(reloaded.paramValues, [42, 7], ...
                'An old task''s per-case values must be lifted out of the parameters');

            %The migrated definitions are usable, which is the whole point of
            %keeping the deprecated class as a subclass.
            testCase.verifyTrue(all(isa(reloaded.params, 'AbstractLvdSweepParameter')));
            testCase.verifyEqual(reloaded.params(1).getGroupName(), 'Plugin Variables');

            %A task that already has generalized parameters must be left alone.
            modern = testCase.taskFor([tempname(), '.mat']);
            modern.params = LvdSweepPluginVarParameter(pluginVar);
            modern.paramValues = 99;
            modern.caseParams = legacy;

            reloadedModern = getArrayFromByteStream(getByteStreamFromArray(modern));
            testCase.verifyEqual(reloadedModern.paramValues, 99, ...
                'Migration must not overwrite a task that was already generalized');
        end

        function raggedParamAndResponseValuesPadIntoOneRectangularMatrix(testCase)
            %collectResults builds the results table straight out of these two,
            %so a case that failed before it could harvest anything has to come
            %back as a row of NaNs rather than shortening the matrix or
            %erroring.
            tasks = LvdCaseMatrixTask.empty(1,0);
            for(i = 1:3)
                tasks(i) = testCase.taskFor([tempname(), '.mat']);
                tasks(i).responses = [LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), LvdSweepResponseNodeEnum.Maximum, 0), ...
                                      LvdSweepResponse(GraphicalAnalysisTask('Altitude', testCase.kerbinFrame), LvdSweepResponseNodeEnum.Minimum, 0)];
            end

            tasks(1).paramValues = [1, 2];
            tasks(2).paramValues = [3, 4];
            tasks(3).paramValues = 5;          %a legacy one-parameter task

            tasks(1).responseValues = [10, 20];
            tasks(2).responseValues = [];      %failed before harvesting
            tasks(3).responseValues = 30;      %harvested one of two

            testCase.verifyEqual(tasks.getArrayOfParamValues(), [1 2; 3 4; 5 NaN]);
            testCase.verifyEqual(tasks.getArrayOfResponseValues(), [10 20; NaN NaN; 30 NaN]);

            %A single task is still one row, which is what the warm-start
            %lookup passes to knnsearch as its reference point.
            testCase.verifyEqual(tasks(2).getArrayOfParamValues(), [3, 4]);
            testCase.verifySize(tasks(1).getArrayOfResponseValues(), [1, 2]);
        end
    end

    methods(Access=private)

        function [lvdData, pluginVar] = markedMission(testCase, marker)
            %markedMission A mission whose first plugin variable's value is a
            %caller-chosen number, so a reader can say which copy it got.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            pluginVar = LvdPluginOptimVarWrapper();
            pluginVar.name = 'Marker';
            pluginVar.value = marker;
            pluginVar.optVar = pluginVar.getNewOptVar();

            lvdData.pluginVars.addPluginVar(pluginVar);
        end

        function marker = markerOf(~, lvdData)
            pluginVars = lvdData.pluginVars.getPluginVarsArray();
            marker = pluginVars(1).value;
        end

        function setMarker(~, lvdData, marker)
            pluginVars = lvdData.pluginVars.getPluginVarsArray();
            pluginVars(1).value = marker;
        end

        function task = taskFor(testCase, path)
            task = LvdCaseMatrixTask(LvdCaseMatrix.empty(1,0), ...
                                     AbstractLvdSweepParameter.empty(1,0), [], ...
                                     LvdCaseMatrixTask.empty(1,0), path);

            testCase.addTeardown(@() CaseMatrixTaskIoTest.deleteIfPresent(path));
        end

        function [task, path] = savedCase(testCase, marker)
            %savedCase A task whose case file already exists on disk, written
            %without going through saveLvdData so the tests of saveLvdData have
            %something independent to stand on.
            path = [tempname(), '.mat'];

            CaseMatrixTaskIoTest.writeMissionFile(path, testCase.markedMission(marker));

            task = testCase.taskFor(path);
        end
    end

    methods(Static, Access=private)

        function writeMissionFile(path, mission)
            %writeMissionFile A case file written with a plain save, which is
            %what loadLvdData has to be able to read.
            lvdData = mission; %#ok<NASGU>
            save(path, 'lvdData');
        end

        function writeJunkMatFile(path)
            notAMission = 1; %#ok<NASGU>
            save(path, 'notAMission');
        end

        function deleteIfPresent(path)
            if(isfile(path))
                delete(path);
            end
        end
    end
end
