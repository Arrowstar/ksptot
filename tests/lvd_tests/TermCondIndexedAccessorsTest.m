classdef TermCondIndexedAccessorsTest < KsptotTestCase
    %TermCondIndexedAccessorsTest The two indexed termination-condition
    %setters (setTermCondByInd / setTermCondDirByInd) the event editor's
    %termination condition list relies on.
    %
    % Nothing here propagates a trajectory: these are data-model assertions
    % with hand-computed expectations.  (The main-window menu items that used
    % to be tested alongside these are now real App Designer components and
    % are covered by LvdMainGuiInteractionTest.)

    methods(Test)
        function setTermCondByIndReplacesTheRightConditionInPlace(testCase)
            evt = testCase.buildThreeCondEvent();

            replacement = ApoapsisAltitudeTermCondition(500);
            evt.setTermCondByInd(2, replacement);

            conds = evt.getAllTermConds();
            testCase.verifyEqual(numel(conds), 3, 'Replacing must not change how many conditions there are.');
            testCase.verifySameHandle(conds(2), replacement);
            testCase.verifyClass(conds(1), 'EventDurationTermCondition');
            testCase.verifyClass(conds(3), 'AltitudeTermCondition');
        end

        function setTermCondByIndCanReplaceTheFirstCondition(testCase)
            %Condition 1 lives in the event's own termCond property while
            %2..N live in extraTermConds, so index 1 is its own code path.
            evt = testCase.buildThreeCondEvent();

            replacement = ApoapsisAltitudeTermCondition(500);
            evt.setTermCondByInd(1, replacement);

            testCase.verifySameHandle(evt.termCond, replacement);
            conds = evt.getAllTermConds();
            testCase.verifySameHandle(conds(1), replacement);
        end

        function setTermCondByIndLeavesTheDirectionAlone(testCase)
            evt = testCase.buildThreeCondEvent();
            dirsBefore = evt.getAllTermCondDirs();

            evt.setTermCondByInd(2, ApoapsisAltitudeTermCondition(500));

            testCase.verifyEqual(evt.getAllTermCondDirs(), dirsBefore, ...
                'Swapping what a condition tests must not change which way it has to cross.');
        end

        function setTermCondByIndIgnoresOutOfRangeIndices(testCase)
            evt = testCase.buildThreeCondEvent();
            condsBefore = evt.getAllTermConds();

            evt.setTermCondByInd(0, ApoapsisAltitudeTermCondition(500));
            evt.setTermCondByInd(4, ApoapsisAltitudeTermCondition(500));

            testCase.verifyEqual(evt.getNumTermConds(), 3);
            testCase.verifyEqual(evt.getAllTermConds(), condsBefore, ...
                'An out of range index must be a no-op, not an append or an error.');
        end

        function setTermCondDirByIndSetsOneDirection(testCase)
            evt = testCase.buildThreeCondEvent();

            evt.setTermCondDirByInd(3, EventTermCondDirectionEnum.Decreasing);

            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(dirs(1), EventTermCondDirectionEnum.NoDir);
            testCase.verifyEqual(dirs(2), EventTermCondDirectionEnum.Increasing);
            testCase.verifyEqual(dirs(3), EventTermCondDirectionEnum.Decreasing);
        end

        function setTermCondDirByIndCanSetTheFirstDirection(testCase)
            evt = testCase.buildThreeCondEvent();

            evt.setTermCondDirByInd(1, EventTermCondDirectionEnum.Increasing);

            testCase.verifyEqual(evt.termCondDir, EventTermCondDirectionEnum.Increasing, ...
                'Direction 1 is stored on the event itself, where the old single-condition data lives.');
            testCase.verifyEqual(numel(evt.extraTermCondDirs), 2);
        end

        function setTermCondDirByIndNormalizesAShortDirectionArray(testCase)
            %A mission file written before a condition was added can carry
            %fewer directions than conditions.  Setting any direction must
            %leave the stored arrays the right length rather than silently
            %keeping the gap.
            evt = testCase.buildThreeCondEvent();
            evt.extraTermCondDirs = EventTermCondDirectionEnum.empty(1,0);

            evt.setTermCondDirByInd(2, EventTermCondDirectionEnum.Decreasing);

            dirs = evt.getAllTermCondDirs();
            testCase.verifyEqual(numel(dirs), 3);
            testCase.verifyEqual(dirs(2), EventTermCondDirectionEnum.Decreasing);
            testCase.verifyEqual(numel(evt.extraTermCondDirs), 2);
        end

        function setTermCondDirByIndIgnoresOutOfRangeIndices(testCase)
            evt = testCase.buildThreeCondEvent();
            dirsBefore = evt.getAllTermCondDirs();

            evt.setTermCondDirByInd(0, EventTermCondDirectionEnum.Decreasing);
            evt.setTermCondDirByInd(9, EventTermCondDirectionEnum.Decreasing);

            testCase.verifyEqual(evt.getAllTermCondDirs(), dirsBefore);
        end
    end

    methods(Access=private)
        function evt = buildThreeCondEvent(testCase)
            %A duration, an altitude and a second altitude, with three
            %different crossing directions so index mix-ups are visible.
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);

            evt.termCond = EventDurationTermCondition(100);
            evt.termCondDir = EventTermCondDirectionEnum.NoDir;

            evt.extraTermConds = AbstractEventTerminationCondition.empty(1,0);
            evt.extraTermCondDirs = EventTermCondDirectionEnum.empty(1,0);
            evt.addTermCond(AltitudeTermCondition(70), EventTermCondDirectionEnum.Increasing);
            evt.addTermCond(AltitudeTermCondition(10), EventTermCondDirectionEnum.Decreasing);
        end
    end
end
