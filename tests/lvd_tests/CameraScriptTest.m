classdef CameraScriptTest < KsptotTestCase
    %CameraScriptTest LvdCameraKeyframe / LvdCameraScript / chase camera
    %(F8): keyframe time resolution against absolute and event anchors,
    %hold and transition logic, easing, vehicle-relative poses, and the
    %fallback when an anchored event is deleted.
    %
    %   Pure-function cases use a fake time resolver (@(kf) kf.absTime) and
    %   a fake vehicle path (@(t) [t;0;0]).  The event-anchor cases use the
    %   two-event two-body mission from EphemerisExportTest.

    properties(Constant)
        DvKms = 1.0;
    end

    methods(Test)

        %% ------------------------------------------------ pure evaluation

        function emptyScriptEvaluatesToEmpty(testCase)
            s = LvdCameraScript();
            testCase.verifyEmpty(s.evaluate(10, testCase.absResolver(), testCase.linePath()));
            testCase.verifyEqual(s.getNumKeyframes(), 0);
        end

        function singleKeyframeIsConstantEverywhere(testCase)
            s = LvdCameraScript();
            kf = testCase.sceneKf('only', 100, [1 2 3], [0 0 0], [0 0 1], 20);
            s.addKeyframe(kf);
            for t = [-1e6, 0, 100, 1e6]
                p = s.evaluate(t, testCase.absResolver(), testCase.linePath());
                testCase.verifyVectorEqual(p.position, [1 2 3], 1e-12);
                testCase.verifyVectorEqual(p.target, [0 0 0], 1e-12);
                testCase.verifyEqual(p.viewAngle, 20);
            end
        end

        function clampsBeforeFirstAndAfterLastKeyframe(testCase)
            s = testCase.twoSceneKeyframeScript(LvdCameraEasingEnum.Linear);
            pA = s.evaluate(-50, testCase.absResolver(), testCase.linePath());
            pB = s.evaluate(5000, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(pA.position, [0 0 0], 1e-12, 'Before the first keyframe: first pose');
            testCase.verifyVectorEqual(pB.position, [100 0 0], 1e-12, 'After the last keyframe: last pose');
            pAtEnd = s.evaluate(200 + 30, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(pAtEnd.position, [100 0 0], 1e-12, 'End of the last hold is still the last pose');
        end

        function holdsTheKeyframePoseForItsDuration(testCase)
            s = testCase.twoSceneKeyframeScript(LvdCameraEasingEnum.Linear);
            %keyframe 1 at t=100 held 20 s
            for t = [100, 105, 119.999, 120]
                p = s.evaluate(t, testCase.absResolver(), testCase.linePath());
                testCase.verifyVectorEqual(p.position, [0 0 0], 1e-12, sprintf('Held at t=%g', t));
                testCase.verifyEqual(p.viewAngle, 10);
            end
        end

        function linearTransitionMidpointIsTheAverage(testCase)
            s = testCase.twoSceneKeyframeScript(LvdCameraEasingEnum.Linear);
            %transition from 120 (end of hold) to 200
            p = s.evaluate(160, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(p.position, [50 0 0], 1e-12);
            testCase.verifyVectorEqual(p.target, [5 5 0], 1e-12);
            testCase.verifyVectorEqual(p.up, [0 1 1]/sqrt(2), 1e-12, 'Up is slerped');
            testCase.verifyEqual(p.viewAngle, 20, 'AbsTol', 1e-12);

            pQ = s.evaluate(140, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(pQ.position, [25 0 0], 1e-12, 'Quarter point is linear');
        end

        function smoothStepMatchesLinearAtMidpointButNotAtQuarter(testCase)
            sLin = testCase.twoSceneKeyframeScript(LvdCameraEasingEnum.Linear);
            sSmooth = testCase.twoSceneKeyframeScript(LvdCameraEasingEnum.SmoothStep);

            pL = sLin.evaluate(160, testCase.absResolver(), testCase.linePath());
            pS = sSmooth.evaluate(160, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(pS.position, pL.position, 1e-12, 'Midpoints agree');

            qL = sLin.evaluate(140, testCase.absResolver(), testCase.linePath());
            qS = sSmooth.evaluate(140, testCase.absResolver(), testCase.linePath());
            testCase.verifyLessThan(qS.position(1), qL.position(1), 'SmoothStep lags linear early in the transition');
            testCase.verifyEqual(qS.position(1), 100*(3*0.25^2 - 2*0.25^3), 'AbsTol', 1e-12);
        end

        function keyframesAreOrderedByResolvedTimeNotListOrder(testCase)
            s = LvdCameraScript();
            s.addKeyframe(testCase.sceneKf('late', 200, [100 0 0], [0 0 0], [0 0 1], 10));
            s.addKeyframe(testCase.sceneKf('early', 100, [0 0 0], [0 0 0], [0 0 1], 10));

            [tStart, tEnd, order] = s.resolveSchedule(testCase.absResolver());
            testCase.verifyEqual(tStart, [100 200]);
            testCase.verifyEqual(tEnd, [100 200]);
            testCase.verifyEqual(order, [2 1]);

            p = s.evaluate(150, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(p.position, [50 0 0], 1e-12, 'Blend runs early -> late (SmoothStep midpoint == linear midpoint)');
        end

        function overlappingHoldSnapsToTheNextKeyframe(testCase)
            s = LvdCameraScript();
            a = testCase.sceneKf('a', 100, [0 0 0], [0 0 0], [0 0 1], 10);
            a.holdDuration = 500;   %runs past keyframe b
            s.addKeyframe(a);
            s.addKeyframe(testCase.sceneKf('b', 200, [100 0 0], [0 0 0], [0 0 1], 10));

            p = s.evaluate(150, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(p.position, [0 0 0], 1e-12, 'Inside a''s hold: a');
            p = s.evaluate(250, testCase.absResolver(), testCase.linePath());
            testCase.verifyVectorEqual(p.position, [100 0 0], 1e-12, 'Once b starts, b wins even though a is still "held"');
        end

        function editingMethodsMaintainOrderAndCount(testCase)
            s = LvdCameraScript();
            a = testCase.sceneKf('a', 1, [0 0 0], [0 0 0], [0 0 1], 10);
            b = testCase.sceneKf('b', 2, [0 0 0], [0 0 0], [0 0 1], 10);
            c = testCase.sceneKf('c', 3, [0 0 0], [0 0 0], [0 0 1], 10);
            s.addKeyframe(a); s.addKeyframe(c);
            s.insertKeyframe(b, 2);
            testCase.verifyEqual({s.keyframes.name}, {'a','b','c'});

            s.moveKeyframeDown(1);
            testCase.verifyEqual({s.keyframes.name}, {'b','a','c'});
            s.moveKeyframeUp(3);
            testCase.verifyEqual({s.keyframes.name}, {'b','c','a'});
            s.moveKeyframeUp(1);  %no-op
            s.moveKeyframeDown(3); %no-op
            testCase.verifyEqual({s.keyframes.name}, {'b','c','a'});

            s.removeKeyframe(c);
            testCase.verifyEqual({s.keyframes.name}, {'b','a'});
            s.removeKeyframe(1);
            testCase.verifyEqual({s.keyframes.name}, {'a'});
            s.removeKeyframe(99); %ignored
            testCase.verifyEqual(s.getNumKeyframes(), 1);

            strs = s.getListboxStrs();
            testCase.verifyNumElements(strs, 1);
            testCase.verifySubstring(strs{1}, '1. a');
        end

        %% ------------------------------------------ vehicle-relative poses

        function vehicleRelativeKeyframeTracksTheVehicle(testCase)
            s = LvdCameraScript();
            kf = LvdCameraKeyframe();
            kf.absTime = 0;
            kf.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            kf.azDeg = 30; kf.elDeg = 10; kf.rangeKm = 5; kf.viewAngleDeg = 8;
            s.addKeyframe(kf);

            for t = [0, 100, 250]
                p = s.evaluate(t, testCase.absResolver(), testCase.linePath());
                expectedPos = LvdCameraMath.sphericalOffset([t 0 0], 30, 10, 5);
                testCase.verifyVectorEqual(p.target, [t 0 0], 1e-12, 'Target is the vehicle');
                testCase.verifyVectorEqual(p.position, expectedPos, 1e-12);
                testCase.verifyEqual(norm(p.position - p.target), 5, 'AbsTol', 1e-12);
                testCase.verifyEqual(p.viewAngle, 8);
            end
        end

        function vehicleRelativePairBlendsAnglesAroundTheVehicle(testCase)
            s = LvdCameraScript();
            a = LvdCameraKeyframe(); a.absTime = 0;   a.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            a.azDeg = 0;  a.elDeg = 0;  a.rangeKm = 10; a.easing = LvdCameraEasingEnum.Linear; a.viewAngleDeg = 10;
            b = LvdCameraKeyframe(); b.absTime = 100; b.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            b.azDeg = 90; b.elDeg = 40; b.rangeKm = 30; b.viewAngleDeg = 30;
            s.addKeyframe(a); s.addKeyframe(b);

            p = s.evaluate(50, testCase.absResolver(), testCase.linePath());
            expectedPos = LvdCameraMath.sphericalOffset([50 0 0], 45, 20, 20);
            testCase.verifyVectorEqual(p.target, [50 0 0], 1e-12, 'Still looking at the vehicle mid-blend');
            testCase.verifyVectorEqual(p.position, expectedPos, 1e-12, 'az/el/range are blended, not Cartesian positions');
            testCase.verifyEqual(norm(p.position - p.target), 20, 'AbsTol', 1e-12);
            testCase.verifyEqual(p.viewAngle, 20, 'AbsTol', 1e-12);
        end

        function mixedPairBlendsCartesianPoses(testCase)
            s = LvdCameraScript();
            a = testCase.sceneKf('scene', 0, [0 0 0], [0 0 0], [0 0 1], 10);
            a.easing = LvdCameraEasingEnum.Linear;
            b = LvdCameraKeyframe(); b.absTime = 100; b.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            b.azDeg = 0; b.elDeg = 0; b.rangeKm = 10; b.viewAngleDeg = 10;
            s.addKeyframe(a); s.addKeyframe(b);

            p = s.evaluate(50, testCase.absResolver(), testCase.linePath());
            %b's concrete pose at t=50: position [60 0 0], target [50 0 0]
            testCase.verifyVectorEqual(p.position, [30 0 0], 1e-12);
            testCase.verifyVectorEqual(p.target, [25 0 0], 1e-12);
        end

        function vehicleRelativeWithUnknownVehiclePositionIsEmpty(testCase)
            s = LvdCameraScript();
            kf = LvdCameraKeyframe(); kf.refType = LvdCameraKeyframeRefEnum.VehicleRelative;
            s.addKeyframe(kf);
            testCase.verifyEmpty(s.evaluate(10, testCase.absResolver(), @(t) NaN(3,1)));
        end

        function nanViewAngleInheritsTheDefault(testCase)
            s = LvdCameraScript();
            kf = testCase.sceneKf('k', 0, [1 1 1], [0 0 0], [0 0 1], NaN);
            s.addKeyframe(kf);
            p = s.evaluate(0, testCase.absResolver(), testCase.linePath(), 33);
            testCase.verifyEqual(p.viewAngle, 33);
            p = s.evaluate(0, testCase.absResolver(), testCase.linePath());
            testCase.verifyTrue(isnan(p.viewAngle));
        end

        %% ------------------------------------- fixed-anchor tracking poses

        function fixedAnchorKeyframeParksAtAnchorAndTracksVehicle(testCase)
            s = LvdCameraScript();
            s.addKeyframe(testCase.fixedAnchorKf('anchor', 0, [0 0 100], 8));
            frame = testCase.kerbinFrame;
            for t = [0, 100, 250]
                p = s.evaluate(t, testCase.absResolver(), testCase.linePath(), NaN, frame);
                testCase.verifyVectorEqual(p.position, [0 0 100], 1e-9, 'Camera sits at the fixed anchor');
                testCase.verifyVectorEqual(p.target, [t 0 0], 1e-9, 'Target tracks the vehicle');
                testCase.verifyEqual(p.viewAngle, 8);
            end
        end

        function fixedAnchorKeyframeIsEmptyWithoutAViewFrame(testCase)
            s = LvdCameraScript();
            s.addKeyframe(testCase.fixedAnchorKf('anchor', 0, [0 0 100], 8));
            %no view frame threaded through -> the anchor cannot be resolved
            testCase.verifyEmpty(s.evaluate(10, testCase.absResolver(), testCase.linePath()));
            %direct: getPoseAtVehiclePosition with no frame is empty too
            kf = s.keyframes(1);
            testCase.verifyEmpty(kf.getPoseAtVehiclePosition([10; 0; 0], 10, []));
            p = kf.getPoseAtVehiclePosition([10; 0; 0], 10, testCase.kerbinFrame);
            testCase.verifyVectorEqual(p.position, [0 0 100], 1e-9);
            testCase.verifyVectorEqual(p.target, [10 0 0], 1e-9);
        end

        function fixedAnchorBlendsToSceneViaGenericBlendPoses(testCase)
            s = LvdCameraScript();
            a = testCase.fixedAnchorKf('anchor', 0, [0 0 100], 10);
            a.easing = LvdCameraEasingEnum.Linear;
            b = testCase.sceneKf('scene', 100, [100 0 0], [0 0 0], [0 0 1], 10);
            s.addKeyframe(a); s.addKeyframe(b);

            frame = testCase.kerbinFrame;
            p = s.evaluate(50, testCase.absResolver(), testCase.linePath(), NaN, frame);
            %pA at t=50: position [0 0 100], target [50 0 0]; pB: [100 0 0] / [0 0 0]
            testCase.verifyVectorEqual(p.position, [50 0 50], 1e-9, 'Cartesian lerp of the two poses');
            testCase.verifyVectorEqual(p.target, [25 0 0], 1e-9);
            testCase.verifyEqual(p.viewAngle, 10, 'AbsTol', 1e-12);
        end

        function copyDeepCopiesTheKeyframeAnchor(testCase)
            kf = testCase.fixedAnchorKf('anchor', 0, [1 2 3], 10);
            kf2 = kf.copy();
            testCase.verifyNotSameHandle(kf.anchor, kf2.anchor, 'copy() must own a distinct anchor');
            kf2.anchor.fixedPosition = [9 9 9];
            testCase.verifyVectorEqual(kf.anchor.fixedPosition, [1 2 3], 1e-12, 'Editing the copy''s anchor must not touch the original');
            testCase.verifyVectorEqual(kf2.anchor.fixedPosition, [9 9 9], 1e-12);
        end

        %% ---------------------------------------------------- chase camera

        function chaseCameraSettingsProduceTheChasePose(testCase)
            c = LvdChaseCameraSettings();
            c.azDeg = -90; c.elDeg = 0; c.rangeKm = 4; c.viewAngleDeg = 15;
            p = c.getPose([10; 20; 30]);
            testCase.verifyVectorEqual(p.position, [10 16 30], 1e-12);
            testCase.verifyVectorEqual(p.target, [10 20 30], 1e-12);
            testCase.verifyEqual(p.viewAngle, 15);
            testCase.verifyEmpty(c.getPose(NaN(3,1)));

            hFig = figure('Visible','off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);
            hAx.CameraPosition = [10 16 30];
            hAx.CameraViewAngle = 7;
            c2 = LvdChaseCameraSettings();
            c2.setFromCamera(hAx, [10; 20; 30]);
            testCase.verifyEqual(c2.azDeg, -90, 'AbsTol', 1e-9);
            testCase.verifyEqual(c2.elDeg, 0, 'AbsTol', 1e-9);
            testCase.verifyEqual(c2.rangeKm, 4, 'AbsTol', 1e-9);
            testCase.verifyEqual(c2.viewAngleDeg, 7);
        end

        function keyframeCaptureFromAxesRoundTrips(testCase)
            hFig = figure('Visible','off');
            cleanup = onCleanup(@() delete(hFig)); %#ok<NASGU>
            hAx = axes(hFig);
            hAx.CameraPosition = [3 4 5];
            hAx.CameraTarget = [0 0 1];
            hAx.CameraUpVector = [0 1 0];
            hAx.CameraViewAngle = 9;

            kf = LvdCameraKeyframe.fromSceneCamera(hAx, 42);
            testCase.verifyEqual(kf.absTime, 42);
            testCase.verifyEqual(kf.refType, LvdCameraKeyframeRefEnum.SceneFixed);
            p = kf.getPoseAtVehiclePosition(NaN(3,1));
            testCase.verifyVectorEqual(p.position, [3 4 5], 1e-12);
            testCase.verifyVectorEqual(p.target, [0 0 1], 1e-12);
            testCase.verifyVectorEqual(p.up, [0 1 0], 1e-12);
            testCase.verifyEqual(p.viewAngle, 9);

            kf2 = LvdCameraKeyframe.fromCameraRelativeToVehicle(hAx, [0; 0; 1], 7);
            testCase.verifyEqual(kf2.refType, LvdCameraKeyframeRefEnum.VehicleRelative);
            p2 = kf2.getPoseAtVehiclePosition([0; 0; 1]);
            testCase.verifyVectorEqual(p2.position, [3 4 5], 1e-9, 'az/el/range reproduce the camera position');
            testCase.verifyEqual(kf2.absTime, 7);
        end

        %% ------------------------------------------------- event anchors

        function eventAnchorsResolveFromTheStateLog(testCase)
            [lvdData, stateLog, evt1, evt2] = testCase.propagatedMission(33, 60);

            e1 = stateLog.getAllStateLogEntriesForEvent(evt1);
            e2 = stateLog.getAllStateLogEntriesForEvent(evt2);

            kfStart = LvdCameraKeyframe();
            kfStart.anchorType = LvdCameraKeyframeAnchorEnum.EventStart;
            kfStart.event = evt2;
            kfStart.timeOffset = 5;
            [t, resolved] = kfStart.resolveTime(stateLog);
            testCase.verifyTrue(resolved);
            testCase.verifyEqual(t, e2(1).time + 5, 'AbsTol', 1e-12);

            kfEnd = LvdCameraKeyframe();
            kfEnd.anchorType = LvdCameraKeyframeAnchorEnum.EventEnd;
            kfEnd.event = evt1;
            kfEnd.timeOffset = -3;
            [t, resolved] = kfEnd.resolveTime(stateLog);
            testCase.verifyTrue(resolved);
            testCase.verifyEqual(t, e1(end).time - 3, 'AbsTol', 1e-12);
            testCase.verifyEqual(e1(end).time, 33, 'AbsTol', 1e-9, 'Fixture: event 1 ends at its duration');

            %SkipFirstState moves the start anchor to the second entry
            evt2.plotMethod = EventPlottingMethodEnum.SkipFirstState;
            kfStart.timeOffset = 0;
            t = kfStart.resolveTime(stateLog);
            testCase.verifyEqual(t, e2(2).time, 'AbsTol', 1e-12);
            evt2.plotMethod = EventPlottingMethodEnum.PlotContinuous;

            %DoNotPlot cannot be resolved -> falls back
            evt2.plotMethod = EventPlottingMethodEnum.DoNotPlot;
            kfStart.absTime = 999;
            [t, resolved] = kfStart.resolveTime(stateLog);
            testCase.verifyFalse(resolved);
            testCase.verifyEqual(t, 999);
            evt2.plotMethod = EventPlottingMethodEnum.PlotContinuous;

            testCase.verifyTrue(kfStart.usesEvent(evt2));
            testCase.verifyFalse(kfStart.usesEvent(evt1));
            testCase.verifySubstring(kfStart.getAnchorStr(lvdData.script), 'start of Event 2');
            testCase.verifySubstring(kfEnd.getListboxStr(lvdData.script), 'end of Event 1 -3.000 s');
        end

        function danglingEventFallsBackToAbsoluteTime(testCase)
            kf = LvdCameraKeyframe();
            kf.anchorType = LvdCameraKeyframeAnchorEnum.EventStart;
            kf.absTime = 100;
            kf.timeOffset = 7;
            [t, resolved] = kf.resolveTime([]);
            testCase.verifyFalse(resolved);
            testCase.verifyEqual(t, 107);
            testCase.verifyFalse(kf.usesEvent(LaunchVehicleEvent.empty(1,0)));
            testCase.verifySubstring(kf.getAnchorStr(), '<no event>');

            %an event that exists but has no logged states
            [lvdData, stateLog, ~, ~] = testCase.propagatedMission(10, 10);
            orphan = LaunchVehicleEvent.getDefaultEvent(lvdData.script);
            kf.event = orphan;
            [t, resolved] = kf.resolveTime(stateLog);
            testCase.verifyFalse(resolved);
            testCase.verifyEqual(t, 107);
        end

        function deletingAnAnchoredEventConvertsTheKeyframe(testCase)
            [lvdData, stateLog, ~, evt2] = testCase.propagatedMission(33, 60);
            profile = lvdData.viewSettings.selViewProfile;

            kf = LvdCameraKeyframe();
            kf.anchorType = LvdCameraKeyframeAnchorEnum.EventEnd;
            kf.event = evt2;
            kf.timeOffset = -1;
            profile.cameraScript.addKeyframe(kf);
            other = LvdCameraKeyframe();
            other.absTime = 5;
            profile.cameraScript.addKeyframe(other);

            expectedT = kf.resolveTime(stateLog);
            testCase.verifyTrue(profile.usesEvent(evt2));
            testCase.verifyTrue(lvdData.viewSettings.usesEvent(evt2));

            %the main window's delete path calls this before removing the event
            lvdData.viewSettings.removeEventFromListOfPlottedEvents(evt2);

            testCase.verifyEqual(kf.anchorType, LvdCameraKeyframeAnchorEnum.AbsoluteTime);
            testCase.verifyEqual(kf.absTime, expectedT, 'AbsTol', 1e-12, 'Frozen at the last resolved time');
            testCase.verifyEqual(kf.timeOffset, 0);
            testCase.verifyEmpty(kf.event);
            testCase.verifyFalse(kf.usesEvent(evt2));
            testCase.verifyFalse(profile.usesEvent(evt2));
            testCase.verifyEqual(other.absTime, 5, 'Unrelated keyframes are untouched');
            testCase.verifyEqual(profile.cameraScript.getNumKeyframes(), 2);
        end

        function eventDeletionIsNotBlockedByACameraKeyframe(testCase)
            [lvdData, ~, ~, evt2] = testCase.propagatedMission(10, 10);
            kf = LvdCameraKeyframe();
            kf.anchorType = LvdCameraKeyframeAnchorEnum.EventStart;
            kf.event = evt2;
            lvdData.viewSettings.selViewProfile.cameraScript.addKeyframe(kf);

            [tf, reasons] = lvdData.script.getEventUsageReport(evt2);
            testCase.verifyFalse(tf, strjoin(reasons, newline));
        end
    end

    methods(Access = private)
        function f = absResolver(~)
            f = @(kf) kf.absTime;
        end

        function f = linePath(~)
            f = @(t) [t; 0; 0];
        end

        function kf = sceneKf(~, name, t, pos, tgt, up, va)
            kf = LvdCameraKeyframe();
            kf.name = name;
            kf.absTime = t;
            kf.refType = LvdCameraKeyframeRefEnum.SceneFixed;
            kf.camPosition = pos;
            kf.camTarget = tgt;
            kf.camUpVector = up;
            kf.viewAngleDeg = va;
        end

        function kf = fixedAnchorKf(~, name, t, xyz, va)
            %a FixedAnchorTracking keyframe with a fixed XYZ anchor and an
            %empty anchor frame (so the coordinate resolves verbatim in the
            %view frame).
            kf = LvdCameraKeyframe();
            kf.name = name;
            kf.absTime = t;
            kf.refType = LvdCameraKeyframeRefEnum.FixedAnchorTracking;
            kf.anchor.anchorType = LvdCameraAnchorTypeEnum.FixedXYZ;
            kf.anchor.fixedPosition = xyz;
            kf.viewAngleDeg = va;
        end

        function s = twoSceneKeyframeScript(testCase, easing)
            %keyframe 1: t=100, held 20 s, at origin looking at origin, up Z, va 10
            %keyframe 2: t=200, held 30 s, at [100 0 0] looking at [10 10 0], up Y, va 30
            s = LvdCameraScript();
            a = testCase.sceneKf('a', 100, [0 0 0], [0 0 0], [0 0 1], 10);
            a.holdDuration = 20;
            a.easing = easing;
            b = testCase.sceneKf('b', 200, [100 0 0], [10 10 0], [0 1 0], 30);
            b.holdDuration = 30;
            s.addKeyframe(a);
            s.addKeyframe(b);
        end

        function [lvdData, stateLog, evt1, evt2] = propagatedMission(testCase, dur1, dur2)
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
            testCase.assertGreaterThan(stateLog.getNumberOfEntries(), 2, 'Fixture broken: no state log.');
        end
    end
end
