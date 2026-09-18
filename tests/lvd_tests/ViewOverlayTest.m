classdef ViewOverlayTest < KsptotTestCase
    %ViewOverlayTest The 3-D view data overlay (F8): item formatting, the
    %settings model, evaluation of Graphical Analysis quantities over the
    %state log with per-event interpolation, the text renderer, persistence
    %and frame-deletion clean-up.
    %
    %   Fixture: the two-event two-body mission of EphemerisExportTest, whose
    %   1 km/s delta-v at the end of event 1 puts a genuine discontinuity in
    %   "Velocity Vector Magnitude" at the event boundary.

    properties(Constant)
        DvKms = 1.0;
    end

    methods(Test)

        %% ------------------------------------------------------ formatting

        function itemFormatsNumbersAndUnits(testCase)
            item = LvdViewOverlayItem();
            item.decimals = 3;
            testCase.verifyEqual(item.formatValue(1234.5678, 'km'), '1234.568 km');
            item.format = "Scientific"; item.decimals = 2;
            testCase.verifyEqual(item.formatValue(1234.5678, 'km'), '1.23e+03 km');
            item.format = "Auto"; item.decimals = 3;
            testCase.verifyEqual(item.formatValue(1234.5678, 'km'), '1235 km');
            item.format = "Fixed"; item.decimals = 0;
            testCase.verifyEqual(item.formatValue(99.6, ''), '100');
            item.showUnits = false;
            testCase.verifyEqual(item.formatValue(99.6, 'km'), '100', 'Units can be hidden');
            item.showUnits = true;
            testCase.verifyEqual(item.formatValue(NaN, 'km'), '--', 'Missing values read "--" with no unit');
            testCase.verifyEqual(item.formatValue(50, 'Percent'), '50 %', 'Percent is shown as %');
            testCase.verifyEqual(item.formatValue(50, ' '), '50', 'Blank units are dropped');
            testCase.verifyError(@() set(item, 'decimals', -1), ?MException);
            testCase.verifyError(@() set(item, 'format', "Hex"), ?MException);
        end

        function itemLabelDefaultsToTheQuantityName(testCase)
            frame = testCase.kerbinFrame;
            item = LvdViewOverlayItem(GraphicalAnalysisTask('Altitude', frame));
            testCase.verifyEqual(item.getDisplayLabel(), 'Altitude');
            testCase.verifyEqual(item.getQuantityStr(), 'Altitude');
            testCase.verifyNotEmpty(item.getFrameStr());
            item.showFrame = true;
            testCase.verifySubstring(item.getDisplayLabel(), 'Altitude [');
            item.label = '  Alt  ';
            testCase.verifyEqual(item.getDisplayLabel(), 'Alt', 'A custom label wins (trimmed)');
            testCase.verifyEqual(item.formatLine(12.3456, 'km'), 'Alt: 12.346 km');

            c = item.copy();
            testCase.verifyNotSameHandle(c, item);
            testCase.verifyNotSameHandle(c.task, item.task);
            testCase.verifyEqual(c.task.taskStr, 'Altitude');
            testCase.verifyEqual(c.label, item.label);

            bare = LvdViewOverlayItem();
            testCase.verifyEqual(bare.getDisplayLabel(), '<no quantity>');
        end

        function durationFormatting(testCase)
            testCase.verifyEqual(LaunchVehicleViewProfileOverlayData.formatDuration(3661.5), '+01:01:01.500');
            testCase.verifyEqual(LaunchVehicleViewProfileOverlayData.formatDuration(90061), '+1d 01:01:01.000');
            testCase.verifyEqual(LaunchVehicleViewProfileOverlayData.formatDuration(-5), '-00:00:05.000');
            testCase.verifyEqual(LaunchVehicleViewProfileOverlayData.formatDuration(0), '+00:00:00.000');
        end

        %% -------------------------------------------------------- settings

        function settingsManageItemsAndAnchor(testCase)
            s = LvdViewOverlaySettings();
            testCase.verifyFalse(s.enabled);
            testCase.verifyTrue(s.hasContent(), 'Header lines are on by default');
            testCase.verifyEqual(s.getNumItems(), 0);

            a = s.addQuantity('Altitude', testCase.kerbinFrame);
            b = s.addQuantity('Throttle', testCase.kerbinFrame);
            c = s.addQuantity('Eccentricity', testCase.kerbinFrame);
            testCase.verifyEqual(s.getNumItems(), 3);
            s.moveItemDown(1);
            testCase.verifyEqual(s.items(2), a);
            s.moveItemUp(3);
            testCase.verifyEqual(s.items(2), c);
            s.removeItem(b);
            testCase.verifyEqual(s.getNumItems(), 2);
            s.removeItem(1);
            testCase.verifyEqual(s.items(1), a);

            [x, y, ha, va] = s.getAnchor();
            testCase.verifyEqual([x y], [0.02 0.98], 'AbsTol', 1e-12); testCase.verifyEqual({ha, va}, {'left', 'top'});
            s.corner = "Bottom Right"; s.marginFrac = 0.1;
            [x, y, ha, va] = s.getAnchor();
            testCase.verifyEqual([x y], [0.9 0.1], 'AbsTol', 1e-12); testCase.verifyEqual({ha, va}, {'right', 'bottom'});
            s.corner = "Top Right";
            [x, y, ha, va] = s.getAnchor();
            testCase.verifyEqual([x y], [0.9 0.9], 'AbsTol', 1e-12); testCase.verifyEqual({ha, va}, {'right', 'top'});
            s.corner = "Bottom Left";
            [~, ~, ha, va] = s.getAnchor();
            testCase.verifyEqual({ha, va}, {'left', 'bottom'});

            testCase.verifyEqual(s.getBackgroundColorSpec(), [0 0 0]);
            s.showBackground = false;
            testCase.verifyEqual(s.getBackgroundColorSpec(), 'none');

            s.showEpoch = false; s.showMet = false; s.showEventName = false; s.showUT = false; s.items = LvdViewOverlayItem.empty(1,0);
            testCase.verifyFalse(s.hasContent());
            s.title = 'Hello';
            testCase.verifyTrue(s.hasContent());

            testCase.verifyError(@() set(s, 'corner', "Middle"), ?MException);
            testCase.verifyError(@() set(s, 'fontSize', 200), ?MException);

            s2 = s.copy();
            testCase.verifyNotSameHandle(s2, s);
            testCase.verifyEqual(s2.title, 'Hello');
        end

        function loadobjBackfillsStructs(testCase)
            s = LvdViewOverlaySettings.loadobj(struct('enabled', true, 'corner', "Top Right"));
            testCase.verifyClass(s, 'LvdViewOverlaySettings');
            testCase.verifyTrue(s.enabled);
            testCase.verifyEqual(s.corner, "Top Right");
            testCase.verifyEqual(s.fontSize, 12, 'Missing fields keep defaults');
            it = LvdViewOverlayItem.loadobj(struct('decimals', 5));
            testCase.verifyEqual(it.decimals, 5);
        end

        %% ------------------------------------------------------ evaluation

        function valuesMatchGraphicalAnalysisAndKeepEventDiscontinuities(testCase)
            [lvdData, stateLog, tD] = testCase.propagatedMission(33, 60);
            frame = testCase.kerbinFrame;
            s = LvdViewOverlaySettings();
            s.addQuantity('Velocity Vector Magnitude', frame);   %LVD-native task, jumps at tD
            s.addQuantity('Altitude', frame);                    %Mission-Architect task path

            data = LaunchVehicleViewProfileOverlayData(s, lvdData);
            data.precompute();

            entries = stateLog.getAllEntries();
            maTaskList = ma_getGraphAnalysisTaskList(getLvdGAExcludeList());
            propNames = lvdData.launchVehicle.tankTypes.getFirstThreeTypesCellArr();

            %exact agreement with the Graphical Analysis evaluation at entry times
            for k = [2, 5, numel(entries)-1]
                e = entries(k);
                for j = 1:2
                    expected = s.items(j).task.executeTask(e, maTaskList, 0, [], [], propNames, lvdData.celBodyData);
                    testCase.verifyEqual(data.getItemValueAtTime(j, e.time), expected, 'RelTol', 1e-12, 'AbsTol', 1e-12, ...
                        sprintf('%s at entry %u', s.items(j).task.taskStr, k));
                end
            end

            %linear inside an event: midpoint between two neighbouring entries
            evt1Entries = stateLog.getAllStateLogEntriesForEvent(lvdData.script.getEventForInd(1));
            times = [evt1Entries.time];
            [times, ia] = unique(times);
            evt1Entries = evt1Entries(ia);
            iA = find(times < tD - 1, 1, 'last') - 1;
            tA = times(iA); tB = times(iA+1);
            vA = s.items(2).task.executeTask(evt1Entries(iA), maTaskList, 0, [], [], propNames, lvdData.celBodyData);
            vB = s.items(2).task.executeTask(evt1Entries(iA+1), maTaskList, 0, [], [], propNames, lvdData.celBodyData);
            testCase.verifyEqual(data.getItemValueAtTime(2, (tA+tB)/2), (vA+vB)/2, 'RelTol', 1e-9, 'Linear interpolation inside an event');

            %the delta-v discontinuity survives: just before tD is pre-burn,
            %at tD (owned by event 2) is post-burn
            evt2Entries = stateLog.getAllStateLogEntriesForEvent(lvdData.script.getEventForInd(2));
            vPost = s.items(1).task.executeTask(evt2Entries(1), maTaskList, 0, [], [], propNames, lvdData.celBodyData);
            preEntry = evt1Entries(find([evt1Entries.time] < tD, 1, 'last'));
            vPre = s.items(1).task.executeTask(preEntry, maTaskList, 0, [], [], propNames, lvdData.celBodyData);
            %(1 km/s along +X on a ~2.9 km/s +Y velocity changes the speed by ~0.17 km/s)
            testCase.assertGreaterThan(abs(vPost - vPre), 0.1, 'Fixture: the burn must be visible in speed');
            testCase.verifyEqual(data.getItemValueAtTime(1, tD), vPost, 'RelTol', 1e-9, 'The boundary belongs to the later event');
            testCase.verifyLessThan(abs(data.getItemValueAtTime(1, tD - 1e-6) - vPre), 1e-3, 'Just before the burn is still pre-burn');

            %outside the trajectory there is no value
            testCase.verifyTrue(isnan(data.getItemValueAtTime(1, tD + 1e6)));

            %text lines
            s.title = 'Test Mission'; s.showUT = true;
            lines = data.buildLines(tD);
            testCase.verifyEqual(lines{1}, 'Test Mission');
            testCase.verifyTrue(any(startsWith(lines, 'UT: ')));
            testCase.verifyTrue(any(startsWith(lines, 'MET: +')));
            testCase.verifyTrue(any(startsWith(lines, 'Event: ')));
            testCase.verifyTrue(any(startsWith(lines, 'Velocity Vector Magnitude: ')));
            testCase.verifyTrue(any(startsWith(lines, 'Altitude: ')));
            testCase.verifyEqual(numel(lines), 7, 'title, epoch, UT, MET, event, 2 quantities');
        end

        function unknownQuantityYieldsDashesNotErrors(testCase)
            [lvdData, ~, ~] = testCase.propagatedMission(10, 10);
            s = LvdViewOverlaySettings();
            s.addItem(LvdViewOverlayItem(GraphicalAnalysisTask('Not A Real Quantity', testCase.kerbinFrame)));
            data = LaunchVehicleViewProfileOverlayData(s, lvdData);
            lines = data.buildLines(5);
            testCase.verifyTrue(any(strcmp(lines, 'Not A Real Quantity: --')), strjoin(lines, ' | '));
        end

        %% -------------------------------------------------------- renderer

        function rendererDrawsAnchoredTextAndFollowsSettings(testCase)
            [lvdData, ~, ~] = testCase.propagatedMission(20, 20);
            hFig = figure('Visible', 'off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);
            plot3(hAx, [0 700], [0 700], [0 700]);

            s = LvdViewOverlaySettings();
            s.enabled = true;
            s.addQuantity('Altitude', testCase.kerbinFrame);
            data = LaunchVehicleViewProfileOverlayData(s, lvdData);

            data.plotOverlayAtTime(5, hAx);
            h = findobj(hAx, 'Tag', 'LvdViewOverlayText');
            testCase.assertNumElements(h, 1, 'One text block');
            testCase.verifyEqual(h.Units, 'normalized');
            testCase.verifyEqual(h.Position(1:2), [0.02 0.98], 'AbsTol', 1e-12);
            testCase.verifyEqual(h.HorizontalAlignment, 'left');
            testCase.verifyEqual(h.VerticalAlignment, 'top');
            testCase.verifyEqual(h.Color, [1 1 1]);
            testCase.verifyEqual(h.BackgroundColor, [0 0 0]);
            testCase.verifyEqual(h.FontSize, 12);
            testCase.verifyEqual(h.Interpreter, 'none');
            testCase.verifyEqual(h.HitTest, matlab.lang.OnOffSwitchState.off);
            testCase.verifyTrue(any(startsWith(h.String, 'Altitude: ')));

            %next frame updates the same object with new text
            str5 = h.String;
            data.plotOverlayAtTime(15, hAx);
            testCase.verifyNumElements(findobj(hAx, 'Tag', 'LvdViewOverlayText'), 1);
            testCase.verifyNotEqual(h.String, str5, 'Text follows the time');

            %style/placement changes are pushed by refreshAppearance
            s.corner = "Bottom Right"; s.fontSize = 20; s.fontWeight = "bold"; s.fontColor = [1 1 0]; s.showBackground = false;
            data.refreshAppearance();
            testCase.verifyEqual(h.Position(1:2), [0.98 0.02], 'AbsTol', 1e-12);
            testCase.verifyEqual(h.HorizontalAlignment, 'right');
            testCase.verifyEqual(h.FontSize, 20);
            testCase.verifyEqual(h.FontWeight, 'bold');
            testCase.verifyEqual(h.Color, [1 1 0]);
            testCase.verifyEqual(h.BackgroundColor, 'none');

            %adding a quantity needs a re-evaluation; invalidate + next frame shows it
            s.addQuantity('Eccentricity', testCase.kerbinFrame);
            data.invalidate();
            data.plotOverlayAtTime(15, hAx);
            testCase.verifyTrue(any(startsWith(h.String, 'Eccentricity: ')));

            %disabled hides, re-enabled shows
            s.enabled = false;
            data.plotOverlayAtTime(15, hAx);
            testCase.verifyEqual(h.Visible, matlab.lang.OnOffSwitchState.off);
            s.enabled = true;
            data.plotOverlayAtTime(15, hAx);
            testCase.verifyEqual(h.Visible, matlab.lang.OnOffSwitchState.on);

            %a fresh renderer for a disabled overlay draws nothing
            hAx2 = axes(hFig);
            s.enabled = false;
            data2 = LaunchVehicleViewProfileOverlayData(s, lvdData);
            data2.plotOverlayAtTime(5, hAx2);
            testCase.verifyEmpty(findobj(hAx2, 'Tag', 'LvdViewOverlayText'));
        end

        %% ------------------------------------------------- profile plumbing

        function profileCarriesTheOverlayAndSavesIt(testCase)
            [lvdData, ~, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;
            testCase.verifyClass(profile.overlay, 'LvdViewOverlaySettings');
            p2 = LaunchVehicleViewProfile();
            testCase.verifyNotSameHandle(p2.overlay, profile.overlay, 'Each profile has its own overlay');

            profile.overlay.enabled = true;
            profile.overlay.corner = "Bottom Left";
            profile.overlay.fontSize = 16;
            it = profile.overlay.addQuantity('Altitude', testCase.kerbinFrame);
            it.decimals = 1; it.label = 'Alt'; it.format = "Auto";

            matPath = [tempname(), '.mat'];
            cleanupMat = onCleanup(@() deleteIfExists(matPath)); %#ok<NASGU>
            save(matPath, 'lvdData');
            L = load(matPath, 'lvdData');
            lp = L.lvdData.viewSettings.selViewProfile;
            testCase.verifyTrue(lp.overlay.enabled);
            testCase.verifyEqual(lp.overlay.corner, "Bottom Left");
            testCase.verifyEqual(lp.overlay.fontSize, 16);
            testCase.verifyEqual(lp.overlay.getNumItems(), 1);
            testCase.verifyEqual(lp.overlay.items(1).task.taskStr, 'Altitude');
            testCase.verifyEqual(lp.overlay.items(1).decimals, 1);
            testCase.verifyEqual(lp.overlay.items(1).label, 'Alt');
            testCase.verifyEqual(lp.overlay.items(1).format, "Auto");

            %old struct-style profiles get an overlay
            out = LaunchVehicleViewProfile.loadobj(struct('name', 'old'));
            testCase.verifyClass(out.overlay, 'LvdViewOverlaySettings');
        end

        function deletingAGeometricFrameRemovesItsOverlayItems(testCase)
            [lvdData, ~, ~] = testCase.propagatedMission(20, 20);
            profile = lvdData.viewSettings.selViewProfile;

            %a user-defined geometric frame built on a coordinate system
            geomFrame = testCase.buildGeometricFrame(lvdData);
            testCase.assumeNotEmpty(geomFrame, 'Could not build a user-defined geometric frame in this checkout.');

            profile.overlay.addQuantity('Altitude', testCase.kerbinFrame);
            profile.overlay.addQuantity('Position Vector (X)', geomFrame);
            testCase.verifyEqual(profile.overlay.getNumItems(), 2);
            testCase.verifyTrue(profile.overlay.usesGeometricRefFrame(geomFrame.geometricFrame));

            profile.removeGeoRefFrameFromList(geomFrame.geometricFrame);
            testCase.verifyEqual(profile.overlay.getNumItems(), 1, 'Only the item in the deleted frame is removed');
            testCase.verifyEqual(profile.overlay.items(1).task.taskStr, 'Altitude');
        end

        function activeProfileChangeIsAnnounced(testCase)
            [lvdData, ~, ~] = testCase.propagatedMission(10, 10);
            vs = lvdData.viewSettings;
            calls = CallRecorder();
            addlistener(vs, 'ActiveProfileChanged', @(~,~) calls.record(vs.selViewProfile.name));

            p2 = LaunchVehicleViewProfile(); p2.name = 'Second';
            vs.addViewProfile(p2);
            vs.setProfileAsActive(p2);
            vs.setProfileAsActive(p2);   %no change -> no event
            vs.setProfileAtIndAsActive(1);
            testCase.verifyEqual(calls.firstArgs(), {'Second', vs.viewProfiles(1).name});
        end
    end

    methods(Access = private)
        function [lvdData, stateLog, tD] = propagatedMission(testCase, dur1, dur2)
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
        end

        function frame = buildGeometricFrame(~, lvdData)
            %A UserDefinedGeometricFrame over a coordinate system, if the
            %geometry API in this checkout supports building one directly.
            frame = [];
            try
                baseFrame = lvdData.initStateModel.centralBody.getBodyCenteredInertialFrame();
                o = [300; 400; 500];
                origin = FixedPointInFrame(o, baseFrame, 'origin', lvdData);
                primary = FixedPointInFrame(o + [0; 0; 7], baseFrame, 'primary', lvdData);
                planePt = FixedPointInFrame(o + [0; 2; 1], baseFrame, 'plane', lvdData);
                cs = ThreePointCoordSystem(origin, primary, planePt, 'cs', lvdData);
                rf = CoordSysPointRefFrame(cs, origin, 'rf', lvdData);
                geometry = lvdData.geometry;
                geometry.points.addPoint(origin);
                geometry.points.addPoint(primary);
                geometry.points.addPoint(planePt);
                geometry.coordSyses.addCoordSys(cs);
                geometry.refFrames.addRefFrame(rf);
                frame = UserDefinedGeometricFrame(rf, lvdData);
            catch
                frame = [];
            end
        end
    end
end

function deleteIfExists(filePath)
    if(isfile(filePath))
        delete(filePath);
    end
end
