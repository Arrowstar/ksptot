classdef H8ListFilterTest < KsptotTestCase
    methods(Test)
        function sharedMatcherIgnoresCaseAndWhitespace(testCase)
            keep = lvd_filterListboxItems('  aSc ', {'Ascent Burn', 'Coast Phase'});
            testCase.verifyEqual(keep, [true false]);
        end

        function sharedMatcherMatchesSecondaryText(testCase)
            keep = lvd_filterListboxItems('upper', {'Ascent Burn', 'Coast Phase'}, {'upper stage', 'ballistic'});
            testCase.verifyEqual(keep, [true false]);
        end

        function sharedMatcherRestoresEverythingForABlankQuery(testCase)
            keep = lvd_filterListboxItems('   ', {'Ascent Burn', 'Coast Phase'});
            testCase.verifyEqual(keep, [true true]);
            testCase.verifyEqual(size(keep), [1 2]);
        end

        function emptyEventFilterMatchesUnfilteredList(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);

            [expectedStr, expectedEvts] = lvdData.script.getListboxStr();
            [actualStr, actualEvts] = lvdData.script.getFilteredListboxStr('  ');

            testCase.verifyEqual(actualStr, expectedStr);
            testCase.verifyTrue(all(actualEvts == expectedEvts));
            testCase.verifyEqual(lvdData.script.getEventForInd(1).tags, '');
        end

        function eventFilterMatchesNameGroupTagsAndNotes(testCase)
            lvdData = testCase.buildTaggedScript();

            [str, evts] = lvdData.script.getFilteredListboxStr('ballistic');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(evts(1) == lvdData.script.getEventForInd(3));
            testCase.verifyTrue(contains(str{1}, 'Coast Phase'));

            [str, evts] = lvdData.script.getFilteredListboxStr('upper');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(evts(1) == lvdData.script.getEventForInd(1));

            [~, evts] = lvdData.script.getFilteredListboxStr('ascent');
            testCase.verifyEqual(numel(evts), 2);
            testCase.verifyTrue(all(evts == lvdData.script.evts(1:2)));

            [str, ~] = lvdData.script.getFilteredListboxStr('no such event');
            testCase.verifyEmpty(str);
        end

        function eventFilterPreservesCollapsedGroupState(testCase)
            lvdData = testCase.buildTaggedScript();
            lvdData.script.setGroupCollapsed('Ascent', true);

            [str, evts] = lvdData.script.getFilteredListboxStr('upper');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(startsWith(str{1}, '▶ [Ascent]'));
            testCase.verifyTrue(contains(str{1}, '(1 events)'));
            testCase.verifyTrue(evts(1) == lvdData.script.getEventForInd(1));
            testCase.verifyTrue(lvdData.script.isGroupCollapsed('Ascent'));
        end

        function nonSequentialFilterUsesWrappedEventTags(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            innerEvt = LaunchVehicleEvent(lvdData.script);
            innerEvt.name = 'Midcourse Correction';
            innerEvt.tags = 'dispersion check';
            nonSeqEvt = LaunchVehicleNonSeqEvent(innerEvt);
            lvdData.script.nonSeqEvts.addEvent(nonSeqEvt);

            [str, evts] = lvdData.script.nonSeqEvts.getFilteredListboxStr('dispersion');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(evts(1) == nonSeqEvt);
            testCase.verifyTrue(contains(str{1}, '[#dispersion check]'));

            [str, ~] = lvdData.script.nonSeqEvts.getFilteredListboxStr('no such event');
            testCase.verifyEmpty(str);
        end

        function constraintFilterKeepsLabelsObjectsAndTooltipsAligned(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            evt = lvdData.script.getEventForInd(1);
            first = ThrottleConstraint(evt, 10, 90);
            first.tags = 'ascent limit';
            second = ThrottleConstraint(evt, 0, 100);
            second.active = false;
            second.tags = 'coast check';
            lvdData.optimizer.constraints.addConstraint(first);
            lvdData.optimizer.constraints.addConstraint(second);

            [str, consts, tips] = lvdData.optimizer.constraints.getFilteredListboxStr('ascent');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(consts(1) == first);
            testCase.verifyEqual(numel(tips), 1);
            testCase.verifyTrue(contains(str{1}, '[#ascent limit]'));

            [str, consts, tips] = lvdData.optimizer.constraints.getFilteredListboxStr('inactive');
            testCase.verifyEqual(numel(str), 1);
            testCase.verifyTrue(consts(1) == second);
            testCase.verifyEqual(numel(tips), 1);
            testCase.verifyTrue(startsWith(str{1}, '** '));

            [str, consts, tips] = lvdData.optimizer.constraints.getFilteredListboxStr('  ');
            testCase.verifyEqual(numel(str), 2);
            testCase.verifyEqual(numel(consts), 2);
            testCase.verifyEqual(numel(tips), 2);
        end
    end

    methods(Access=private)
        function lvdData = buildTaggedScript(testCase)
            lvdData = LvdData.getDefaultLvdData(testCase.celBodyData);
            script = lvdData.script;

            first = script.getEventForInd(1);
            first.name = 'Ascent Burn';
            first.groupName = 'Ascent';
            first.tags = 'upper stage';
            first.notes = 'first tagged event';

            second = LaunchVehicleEvent(script);
            second.name = 'Ascent Coast';
            second.groupName = 'Ascent';
            second.termCond = EventDurationTermCondition(100);
            script.addEvent(second);

            third = LaunchVehicleEvent(script);
            third.name = 'Coast Phase';
            third.groupName = 'Coast';
            third.tags = 'ballistic';
            third.termCond = EventDurationTermCondition(100);
            script.addEvent(third);
        end
    end
end
